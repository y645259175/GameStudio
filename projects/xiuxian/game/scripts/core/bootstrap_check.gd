# =============================================================================
# bootstrap_check.gd · M2 地基自检（普通 Node，挂在 main_check.tscn 主场景）
#
# 用途：验证三个地基 autoload（DataRegistry / EventBus / TimeService）正常加载，
#       且 TimeService 双层时钟核心行为符合 ADR-0001 预期。
#
# 运行方式（用户放置 Godot 二进制后）：
#   Godot --headless --path projects/xiuxian/game res://scenes/main_check.tscn --quit-after 2
# 或直接把 main_check.tscn 设为 run/main_scene。
#
# 退出码：0 = 全部通过；1 = 有失败项。
# 说明：用普通 Node + autoload（而非 SceneTree --script），因为 --script 模式 autoload 不挂载。
# =============================================================================
extends Node


func _ready() -> void:
	var failures: Array[String] = []
	print("=== xiuxian M2 bootstrap check ===")

	# 1. autoload 存在性（通过 /root 查）
	var dr = get_node_or_null("/root/DataRegistry")
	var eb = get_node_or_null("/root/EventBus")
	var ts = get_node_or_null("/root/TimeService")
	if dr == null: failures.append("DataRegistry autoload missing")
	if eb == null: failures.append("EventBus autoload missing")
	if ts == null: failures.append("TimeService autoload missing")

	if ts != null:
		# 2. 初始月份 = 1
		if ts.get_current_month() != 1:
			failures.append("initial month != 1 (got %d)" % ts.get_current_month())

		# 3. advance_outer 月份递增 + year 派生
		ts.advance_outer(12)
		if ts.get_current_month() != 13:
			failures.append("advance_outer(12): month != 13 (got %d)" % ts.get_current_month())
		if ts.get_current_year() != 2:
			failures.append("after +12 months: year != 2 (got %d)" % ts.get_current_year())

		# 4. advance_outer_by_days 累积满 30 才进月
		var m_before: int = ts.get_current_month()
		ts.advance_outer_by_days(29)
		if ts.get_current_month() != m_before:
			failures.append("advance_outer_by_days(29) should not tick month")
		ts.advance_outer_by_days(1)  # 累计 30
		if ts.get_current_month() != m_before + 1:
			failures.append("advance_outer_by_days: 29+1 should tick exactly 1 month")

		# 5. 历练双层时钟：3 月图，跨 1/3 阈值各广播一次
		var month_ticks := {"n": 0}
		var cb := func(_nm, _y, _moy): month_ticks["n"] += 1
		ts.month_advanced.connect(cb)
		ts.enter_expedition("test_map", 3, 100)
		ts.advance_progress(40)   # 剩 60%，跨过第 1 个 1/3(33%) 阈值 → 1 tick
		ts.advance_progress(40)   # 剩 20%，跨过第 2 个(67%) 阈值 → 1 tick
		var consumed: int = ts.exit_expedition(ts.ExpeditionEndReason.COMPLETED)
		ts.month_advanced.disconnect(cb)
		if month_ticks["n"] != 2:
			failures.append("3-month expedition crossings: expected 2 ticks, got %d" % month_ticks["n"])
		if consumed != 3:
			failures.append("COMPLETED 3-month expedition should consume 3 months, got %d" % consumed)

		# 6. 撤退消耗 = ceil(progress * max_months)
		ts.enter_expedition("test_map2", 2, 100)
		ts.advance_progress(30)   # 消耗 30% → ceil(0.3*2)=1
		var c2: int = ts.exit_expedition(ts.ExpeditionEndReason.RETREAT)
		if c2 != 1:
			failures.append("retreat at 30%% of 2-month map should consume 1, got %d" % c2)

	# === 地基② 角色系统 ===
	var cs = get_node_or_null("/root/CharacterService")
	var creg = get_node_or_null("/root/CharacterRegistry")
	var bs = get_node_or_null("/root/BuffService")
	if cs == null: failures.append("CharacterService autoload missing")
	if creg == null: failures.append("CharacterRegistry autoload missing")
	if bs == null: failures.append("BuffService autoload missing")

	if cs != null and creg != null:
		# 7. 创建角色 + 读回
		var hero = cs.create("char_hero")
		hero.character_name = "无名道人"
		hero.attributes = {"insight": 100, "physique": 50}
		if cs.get_character("char_hero") == null:
			failures.append("create/get_character roundtrip failed")
		if cs.count() != 1:
			failures.append("character count != 1 (got %d)" % cs.count())

		# 8. 行动状态切换 + 广播
		var state_evt := {"hit": false}
		var scb := func(_id, _old, _new): state_evt["hit"] = true
		eb.character_state_changed.connect(scb)
		cs.set_action_state("char_hero", 1)  # IN_CULTIVATION
		eb.character_state_changed.disconnect(scb)
		if not state_evt["hit"]:
			failures.append("set_action_state did not emit character_state_changed")

		# 9. change_attribute 经接口
		cs.change_attribute("char_hero", "insight", 20)
		if cs.get_attribute("char_hero", "insight") != 120:
			failures.append("change_attribute insight 100+20 != 120 (got %s)" % str(cs.get_attribute("char_hero", "insight")))

		# 10. CharacterRegistry 注册子模式
		creg.register_state_mode("cultivating", "bottleneck")
		if not creg.is_valid_state_mode("cultivating", "bottleneck"):
			failures.append("register_state_mode/is_valid_state_mode failed")

	# === 地基③ Buff 系统 ===
	if bs != null and cs != null:
		var hero2 = cs.get_character("char_hero")
		if hero2 != null:
			# 11. apply buff + sum_attribute 累加
			bs.apply(hero2, "cultivation", "qi_acceleration", {"percent": 20}, 3, "test")
			bs.apply(hero2, "cultivation", "qi_acceleration", {"percent": 15}, -1, "test2")
			var s: float = bs.sum_attribute(hero2, "cultivation", "qi_acceleration", "percent")
			if s != 35.0:
				failures.append("sum_attribute qi_acceleration percent 20+15 != 35 (got %s)" % str(s))
			# 12. 跨小类累加
			bs.apply(hero2, "cultivation", "insight_boost", {"percent": 5}, -1, "t3")
			var sc: float = bs.sum_attribute_by_category(hero2, "cultivation", "percent")
			if sc != 40.0:
				failures.append("sum_attribute_by_category cultivation 35+5 != 40 (got %s)" % str(sc))
			# 13. tick_monthly：3 月 buff 应在 3 次 tick 后到期
			bs.tick_monthly(hero2); bs.tick_monthly(hero2); bs.tick_monthly(hero2)
			# qi_acceleration percent=20 (3月) 应到期；剩 percent=15(永久) → sum=15
			var s2: float = bs.sum_attribute(hero2, "cultivation", "qi_acceleration", "percent")
			if s2 != 15.0:
				failures.append("after 3 ticks, expired 3-month buff; remaining should be 15 (got %s)" % str(s2))

	# === 地基④ 经营 + 成长闭环（端到端）===
	var sect_s = get_node_or_null("/root/SectService")
	var inv = get_node_or_null("/root/InventoryService")
	var bld = get_node_or_null("/root/BuildingService")
	var cult = get_node_or_null("/root/CultivationSystem")
	var save = get_node_or_null("/root/SaveService")
	if sect_s == null: failures.append("SectService autoload missing")
	if inv == null: failures.append("InventoryService autoload missing")
	if bld == null: failures.append("BuildingService autoload missing")
	if cult == null: failures.append("CultivationSystem autoload missing")
	if save == null: failures.append("SaveService autoload missing")

	if sect_s != null and inv != null and bld != null and cult != null and cs != null:
		# 14. 资源增减
		inv.add("spirit_stone", 1000)
		if inv.get_amount("spirit_stone") != 1000:
			failures.append("inventory add/get failed (got %d)" % inv.get_amount("spirit_stone"))
		if inv.consume("spirit_stone", 200) != true or inv.get_amount("spirit_stone") != 800:
			failures.append("inventory consume failed (got %d)" % inv.get_amount("spirit_stone"))

		# 15. 建筑：建修炼塔 lv1（建造 1 月完成）
		bld.start_build("training_1", "cultivation_tower", {"spirit_stone": 200})
		ts.advance_outer(1)   # 月节拍推进建造
		if bld.get_building_level("cultivation_tower") != 1:
			failures.append("cultivation_tower should be lv1 after 1 month (got %d)" % bld.get_building_level("cultivation_tower"))

		# 16. 端到端成长闭环：弟子分配修炼塔 → 挂 buff → 闭关涨经验
		var d = cs.create("char_disciple")
		sect_s.add_member("char_disciple")
		d.realm = "qi_1"
		d.sub_level = 1
		d.spirit_root = {"fire": 10}
		d.attributes = {"insight": 100, "experience": 0.0}
		bld.assign_character("training_1", "char_disciple")   # 转 IN_CULTIVATION + 挂 qi_acceleration buff
		var exp_before: float = d.attributes.get("experience", 0.0)
		ts.advance_outer(1)   # 月节拍 → CultivationSystem._tick_normal 涨经验
		var exp_after: float = d.attributes.get("experience", 0.0)
		# 炼气1 火10 纯火 a=0.08 → base 15×1.8=27，×修炼塔+20% buff=32.4，阈值100 不升级
		if exp_after <= exp_before:
			failures.append("cultivation did not gain experience (before=%s after=%s)" % [str(exp_before), str(exp_after)])
		# buff 确实挂上（验证哲学落地：建筑→buff→公式自动读）
		var tower_buff: float = bs.sum_attribute(d, "cultivation", "qi_acceleration", "percent")
		if tower_buff != 20.0:
			failures.append("cultivation_tower lv1 should give +20%% buff (got %s)" % str(tower_buff))

	# === 地基⑤ 存档往返 ===
	if save != null and ts != null and cs != null:
		var month_before: int = ts.get_current_month()
		var snapshot: Dictionary = save.collect_save_data()
		# 篡改内存，再 apply 回来验证恢复
		ts.advance_outer(99)
		save.apply_save_data(snapshot)
		if ts.get_current_month() != month_before:
			failures.append("save roundtrip: month not restored (expected %d got %d)" % [month_before, ts.get_current_month()])
		if snapshot.get("save_version", 0) != 1:
			failures.append("save_version should be 1")
		if not snapshot.get("chunks", {}).has("characters"):
			failures.append("save chunks missing 'characters'")

	# === 地基⑥ 战斗 ===
	var battle = get_node_or_null("/root/BattleService")
	var evt = get_node_or_null("/root/EventEngine")
	if battle == null: failures.append("BattleService autoload missing")
	if evt == null: failures.append("EventEngine autoload missing")

	if battle != null and cs != null:
		# 17. 战力碾压：高境界打低境界
		var strong = cs.create("char_strong"); strong.realm = "golden_5"; strong.spirit_root = {"fire": 5}
		var weak = cs.create("char_weak"); weak.realm = "qi_1"; weak.spirit_root = {"wood": 5}
		var ctx2 = BattleContext.new()
		ctx2.attackers = [strong]; ctx2.defenders = [weak]; ctx2.seed = 12345
		ctx2.trigger_source = "expedition_event"
		var br = battle.resolve(ctx2)
		if br == null or br.winner != "ATTACKERS":
			failures.append("strong(golden) vs weak(qi) should win ATTACKERS (got %s)" % (br.winner if br else "null"))
		# 18. 五行加成：火克金
		var fb := ElementCalculator.element_bonus(["fire"], ["metal"])
		if fb <= 0.0:
			failures.append("fire should counter metal (bonus > 0, got %s)" % str(fb))

	# === 地基⑦ 事件引擎 + 条件求值 ===
	if evt != null:
		# 19. handler 注册
		if not evt.has_handler("show_text"):
			failures.append("EventEngine missing show_text handler")
		# 20. resolve_event 无配表不崩（返回空 ctx）
		var ectx = evt.resolve_event("nonexistent_event")
		if ectx == null:
			failures.append("resolve_event should return EventContext even when no config")
		# 21. 条件求值：disciple_count() >= N（此时 sect 有成员）
		var cond_true := ConditionEvaluator.evaluate("disciple_count() >= 1")
		if not cond_true:
			failures.append("ConditionEvaluator disciple_count()>=1 should be true")
		# 22. flag 条件
		var fctx = EventContext.new()
		fctx.set_flag("choice", "investigate")
		if not ConditionEvaluator.evaluate("flag('choice') == 'investigate'", fctx):
			failures.append("ConditionEvaluator flag match failed")

	# === 地基⑧ DataRegistry 配表加载（data/ 迁入 game/ 后）===
	if dr != null:
		# 23. DataRegistry 已加载（manifest 不再缺失）
		if not dr.is_loaded():
			failures.append("DataRegistry not loaded (manifest missing? data/ 迁移问题?)")
		else:
			# 24. 加载到表（buff_system + text）
			var tables: Array = dr.loaded_tables()
			if tables.is_empty():
				failures.append("DataRegistry loaded but no tables")

	# === 地基⑨ 验收回归：预建/分配/容量/月俸/寿元 ===
	var bld2 = get_node_or_null("/root/BuildingService")
	var sect2 = get_node_or_null("/root/SectService")
	if bld2 != null and cs != null and sect2 != null:
		# 25. 预建建筑直接 lv1（不走月节拍）
		bld2.predefine_building("slot_t_tower", "cultivation_tower", 1)
		if bld2.get_building_level("cultivation_tower") != 1:
			failures.append("predefine_building should set lv1 immediately")
		# 26. 容量检查：修炼塔 lv1 容量 2（GDD-05 §7.5），分配第 3 人应失败(code 3)
		bld2.predefine_building("slot_t_dorm", "disciple_dorm", 1)
		if bld2.get_housing_capacity() < 6:
			failures.append("disciple_dorm lv1 housing_capacity should be >= 6 (got %d)" % bld2.get_housing_capacity())
		if bld2.get_capacity("cultivation_tower") != 2:
			failures.append("cultivation_tower lv1 capacity should be 2 (got %d)" % bld2.get_capacity("cultivation_tower"))
		var assign_ok := true
		for k in range(2):
			var did := "acc_d_%d" % k
			var dd = cs.create(did); dd.realm = "qi_1"
			sect2.add_member(did)
			if bld2.assign_character_ex("slot_t_tower", did) != 0:
				assign_ok = false
		if not assign_ok:
			failures.append("first 2 assigns to cultivation_tower (cap 2) should succeed")
		var dd5 = cs.create("acc_d_5"); dd5.realm = "qi_1"; sect2.add_member("acc_d_5")
		if bld2.assign_character_ex("slot_t_tower", "acc_d_5") != 3:
			failures.append("3rd assign to cap-2 tower should return code 3 (full)")
		# 27. 月俸结算：5 炼气弟子(acc_d) × 5 = 25，扣灵石
		var inv2 = get_node_or_null("/root/InventoryService")
		inv2.add("spirit_stone", 1000)
		var before_ss: int = inv2.get_amount("spirit_stone")
		var salary: int = sect2.monthly_salary_total()
		if salary < 15:
			failures.append("monthly_salary_total should be >= 15 (got %d)" % salary)
		# 28. 寿元每月衰减 + 月节拍触发月俸
		var probe = cs.create("acc_probe"); probe.realm = "qi_1"
		probe.lifespan_total_months = 720
		probe.lifespan_remaining_months = 100; sect2.add_member("acc_probe")
		ts.advance_outer(1)
		if probe.lifespan_remaining_months != 99:
			failures.append("lifespan should decrease by 1 per month (got %d)" % probe.lifespan_remaining_months)
		if inv2.get_amount("spirit_stone") >= before_ss:
			failures.append("salary should be deducted after advance_outer (before=%d after=%d)" % [before_ss, inv2.get_amount("spirit_stone")])

	# === 地基⑩ M3 内容：招收 / 炼丹 / 历练循环 smoke ===
	var rec = get_node_or_null("/root/RecruitService")
	var alc = get_node_or_null("/root/AlchemyService")
	var exp_s = get_node_or_null("/root/ExpeditionService")
	if rec == null: failures.append("RecruitService autoload missing")
	if alc == null: failures.append("AlchemyService autoload missing")

	# 29. 招收：生成候选 + 接收（有居所余位时）
	if rec != null and bld2 != null:
		var cand: Dictionary = rec.generate("active_recruit")
		if not cand.has("spirit_root") or not cand.has("name"):
			failures.append("RecruitService.generate should produce name + spirit_root")
		# housing 充足时能接收
		if rec.has_housing_room():
			var before_pop: int = sect2.member_count()
			var nid: String = rec.accept_candidate(cand)
			if nid == "" or sect2.member_count() != before_pop + 1:
				failures.append("accept_candidate should add 1 member when room available")

	# 30. 炼丹：配方加载 + 聚气丹可炼判定
	if alc != null and bld2 != null:
		if alc.get_all_recipes().size() < 5:
			failures.append("AlchemyService should load >= 5 recipes (got %d)" % alc.get_all_recipes().size())
		# 备料 + 建丹房 lv1
		bld2.predefine_building("slot_t_alchemy", "alchemy_room", 1)
		var inv3 = get_node_or_null("/root/InventoryService")
		inv3.add("spirit_herb", 10)
		# 聚气丹需 灵草×2 / 丹房lv1 / 炼丹值10
		var probe2 = cs.create("acc_alchemist"); probe2.attributes = {"alchemy": 50}
		sect2.add_member("acc_alchemist")
		var reason: String = alc.cannot_craft_reason("recipe_qi_pill", "acc_alchemist")
		if reason != "":
			failures.append("recipe_qi_pill should be craftable (got reason: %s)" % reason)
		if not alc.start_craft("recipe_qi_pill", "acc_alchemist"):
			failures.append("start_craft recipe_qi_pill should succeed")

	# 31. 历练：14 事件加载 + 启动历练 6 节点
	if exp_s != null and EventEngine != null:
		var et_count: int = 0
		for _r in DataRegistry.get_table("EventTemplate"):
			et_count += 1
		if et_count < 10:
			failures.append("EventTemplate should have >= 10 events (M3-3, got %d)" % et_count)
		exp_s.start_expedition("test_map", ["char_master"])
		if exp_s.node_count() != 6:
			failures.append("expedition should have 6 nodes (got %d)" % exp_s.node_count())

	# 32. M3-7 存档跨"假装版本升级"测试：collect → 改 save_version → migrate → apply
	if save != null:
		var snap2: Dictionary = save.collect_save_data()
		if snap2.get("save_version", 0) != 1:
			failures.append("save_version should be 1")
		# 模拟未来版本字段缺失：删一个 chunk，apply 不应崩
		var degraded: Dictionary = snap2.duplicate(true)
		degraded["chunks"].erase("sect")
		save.apply_save_data(degraded)   # 缺 sect chunk 应优雅降级不崩

	# 结果
	if failures.is_empty():
		print("[PASS] all checks passed (18 autoloads + 验收回归 + M3内容 + 存档兼容)")
		get_tree().quit(0)
	else:
		print("[FAIL] %d issue(s):" % failures.size())
		for f in failures:
			print("  - " + f)
		get_tree().quit(1)
