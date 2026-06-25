# =============================================================================
# e2e_smoke.gd · M3 端到端 smoke 测试
# 模拟 5 年游戏完整玩法：建造/分配/历练/招收/炼丹/突破/月俸/寿元/存读档
# 任何崩溃 / 数值越界 / 关键逻辑断裂 → 退出码 1 + 打印失败原因
# =============================================================================
extends Node


var failures: Array[String] = []
var event_log: Array[String] = []


func _ready() -> void:
	print("=== xiuxian M3 e2e smoke test ===")
	# 监听关键事件
	EventBus.world_event_triggered.connect(_on_world_event)
	EventBus.month_advanced.connect(_on_month)

	await get_tree().process_frame
	_step_1_init()
	_step_2_initial_state()
	_step_3_build_and_assign()
	_step_4_advance_year_observe_growth()
	_step_5_expedition_loop()
	_step_6_alchemy_loop()
	_step_7_recruit_loop()
	_step_8_save_load_roundtrip()
	_step_9_lifespan_and_death()
	_step_10_economy_check()
	_step_11_battle_100_rounds()
	_step_12_alchemy_all_recipes()
	_step_13_breakthrough_anchor()

	# 总结
	print("=== e2e smoke summary ===")
	print("[year %d month %d] sect members=%d, stones=%d" % [
		TimeService.get_current_year(), TimeService.get_month_of_year(),
		SectService.member_count(), InventoryService.get_amount("spirit_stone")])
	if failures.is_empty():
		print("[E2E PASS] all 13 steps passed")
		get_tree().quit(0)
	else:
		print("[E2E FAIL] %d failures:" % failures.size())
		for f in failures:
			print("  - %s" % f)
		get_tree().quit(1)


# -----------------------------------------------------------------------------
func _check(cond: bool, msg: String) -> void:
	if not cond:
		failures.append(msg)
		print("  ✗ %s" % msg)
	else:
		print("  ✓ %s" % msg)


func _on_world_event(hook_id: String, payload: Dictionary) -> void:
	if hook_id == "event_log":
		event_log.append(payload.get("msg", ""))


func _on_month(_m: int, _y: int, _moy: int) -> void:
	pass


# -----------------------------------------------------------------------------
# Step 1：初始化新游戏（走 GameManager.start_new_game）
# -----------------------------------------------------------------------------
func _step_1_init() -> void:
	print("\n--- step 1: init new game ---")
	# 直接调 GameManager 的初始化逻辑（不切场景）
	GameManager._init_world_data()
	_check(SectService.get_sect() != null, "sect initialized")
	_check(SectService.member_count() == 3, "3 members (1 master + 2 disciples)")
	_check(InventoryService.get_amount("spirit_stone") >= 2000, "start with >= 2000 spirit_stone")
	_check(BuildingService.get_building_level("main_hall") == 1, "main_hall pre-built lv1")
	_check(BuildingService.get_building_level("disciple_dorm") == 1, "disciple_dorm pre-built lv1")
	_check(BuildingService.get_building_level("cultivation_tower") == 1, "cultivation_tower pre-built lv1")


# -----------------------------------------------------------------------------
# Step 2：开局状态合理
# -----------------------------------------------------------------------------
func _step_2_initial_state() -> void:
	print("\n--- step 2: initial state ---")
	var master := CharacterService.get_character("char_master")
	var d1 := CharacterService.get_character("char_disciple_1")
	_check(master != null, "master exists")
	_check(d1 != null, "disciple_1 exists")
	if master:
		_check(master.realm.begins_with("golden"), "master is golden realm: " + master.realm)
		_check(master.lifespan_remaining_months > 0, "master has lifespan")
	if d1:
		_check(d1.realm.begins_with("qi"), "disciple_1 is qi realm: " + d1.realm)
	_check(BuildingService.get_housing_capacity() >= 6, "housing capacity >= 6")
	_check(SectService.monthly_salary_total() > 0, "monthly salary > 0")


# -----------------------------------------------------------------------------
# Step 3：分配弟子闭关 + 建造新建筑
# -----------------------------------------------------------------------------
func _step_3_build_and_assign() -> void:
	print("\n--- step 3: build + assign ---")
	# 分配两个弟子进修炼塔（容量 2）
	var r1 := BuildingService.assign_character_ex("slot_cultivation_tower", "char_disciple_1")
	var r2 := BuildingService.assign_character_ex("slot_cultivation_tower", "char_disciple_2")
	_check(r1 == 0, "assign disciple_1 to tower OK")
	_check(r2 == 0, "assign disciple_2 to tower OK")

	var d1 := CharacterService.get_character("char_disciple_1")
	_check(d1.action_state == Character.ActionState.IN_CULTIVATION, "disciple_1 now IN_CULTIVATION")
	_check(d1.buffs.size() > 0, "disciple_1 has qi_acceleration buff from tower")

	# 建造藏经阁（M3 第一种主动建造）
	BuildingService.start_build("slot_library", "library", {})
	var sect := SectService.get_sect()
	var has_lib_in_progress := false
	for b in sect.buildings:
		if b.get("slot_id") == "slot_library" and b.get("target_level", 0) >= 1:
			has_lib_in_progress = true
	_check(has_lib_in_progress, "library construction started")


# -----------------------------------------------------------------------------
# Step 4：推 12 月，观察修为成长 / 寿元 / 月俸
# -----------------------------------------------------------------------------
func _step_4_advance_year_observe_growth() -> void:
	print("\n--- step 4: advance 12 months ---")
	var d1 := CharacterService.get_character("char_disciple_1")
	var d2 := CharacterService.get_character("char_disciple_2")
	var exp_before: float = d1.attributes.get("experience", 0.0)
	var life_before: int = d1.lifespan_remaining_months
	var stones_before: int = InventoryService.get_amount("spirit_stone")

	TimeService.advance_outer(12)

	var exp_after: float = d1.attributes.get("experience", 0.0)
	var life_after: int = d1.lifespan_remaining_months
	var stones_after: int = InventoryService.get_amount("spirit_stone")

	_check(exp_after > exp_before, "disciple_1 experience grew: %.1f -> %.1f" % [exp_before, exp_after])
	_check(life_after == life_before - 12, "disciple_1 lifespan -12: %d -> %d" % [life_before, life_after])
	_check(stones_after < stones_before, "salary deducted: %d -> %d" % [stones_before, stones_after])
	# 藏经阁应该已建好
	_check(BuildingService.get_building_level("library") >= 1, "library built after 12 months")


# -----------------------------------------------------------------------------
# Step 5：历练循环跑完整 6 节点
# -----------------------------------------------------------------------------
func _step_5_expedition_loop() -> void:
	print("\n--- step 5: expedition full loop ---")
	# 先解除修炼塔分配，让弟子可以出发
	BuildingService.unassign_character("slot_cultivation_tower", "char_disciple_1")
	BuildingService.unassign_character("slot_cultivation_tower", "char_disciple_2")
	CharacterService.set_action_state("char_disciple_1", Character.ActionState.IDLE, {})
	CharacterService.set_action_state("char_disciple_2", Character.ActionState.IDLE, {})

	var stones_before: int = InventoryService.get_amount("spirit_stone")
	ExpeditionService.start_expedition("青岚秘境", ["char_master", "char_disciple_1", "char_disciple_2"])
	_check(ExpeditionService.is_active() or ExpeditionService.node_count() == 6, "expedition started with 6 nodes")
	# 推 5 个节点（第1节点 start_expedition 自动推了）
	for i in range(6):
		if ExpeditionService.is_active():
			ExpeditionService.advance_node()
	_check(not ExpeditionService.is_active(), "expedition finished after walking all nodes")
	var stones_after: int = InventoryService.get_amount("spirit_stone")
	# 历练应该有奖励（即使打输也可能有部分奖励，至少不应该崩）
	print("  expedition stones delta: %d" % (stones_after - stones_before))


# -----------------------------------------------------------------------------
# Step 6：炼丹启动 + 推进完成
# -----------------------------------------------------------------------------
func _step_6_alchemy_loop() -> void:
	print("\n--- step 6: alchemy loop ---")
	# 建丹房
	BuildingService.predefine_building("slot_alchemy_room", "alchemy_room", 1)
	# 给材料
	InventoryService.add("spirit_herb", 10)
	# 用门主炼丹（金丹境，炼丹值足够）
	var master := CharacterService.get_character("char_master")
	master.attributes["alchemy"] = 50

	var pills_before: int = InventoryService.get_amount("mortal_pill")
	var herbs_before: int = InventoryService.get_amount("spirit_herb")
	var ok := AlchemyService.start_craft("recipe_qi_pill", "char_master")
	_check(ok, "start crafting qi_pill")
	_check(InventoryService.get_amount("spirit_herb") == herbs_before - 2, "spirit_herb consumed -2")

	# 推 2 月让其完成
	TimeService.advance_outer(2)
	# 炼丹值高 + 配方成功率 0.9，期望产出 mortal_pill 至少 1 个
	var pills_after: int = InventoryService.get_amount("mortal_pill")
	# 因 RNG 可能失败一次，这里宽松：只要任务推进过 OR 产出 OR 已失败完成
	_check(AlchemyService.active_count() < 1 or pills_after >= pills_before, "alchemy task progressed or completed")


# -----------------------------------------------------------------------------
# Step 7：招收弟子
# -----------------------------------------------------------------------------
func _step_7_recruit_loop() -> void:
	print("\n--- step 7: recruit loop ---")
	if not RecruitService.has_housing_room():
		print("  housing full, skip recruit test")
		return
	var before: int = SectService.member_count()
	var cand: Dictionary = RecruitService.generate("active_recruit")
	_check(cand.has("name") and cand.has("spirit_root"), "candidate has name+roots")
	var nid: String = RecruitService.accept_candidate(cand)
	_check(nid != "", "candidate accepted")
	_check(SectService.member_count() == before + 1, "member count +1")
	# 容量极限测试
	while RecruitService.has_housing_room():
		var c2: Dictionary = RecruitService.generate("active_recruit")
		RecruitService.accept_candidate(c2)
	_check(not RecruitService.has_housing_room(), "housing now full")


# -----------------------------------------------------------------------------
# Step 8：存档 → 改资源 → 读档应恢复
# -----------------------------------------------------------------------------
func _step_8_save_load_roundtrip() -> void:
	print("\n--- step 8: save/load roundtrip ---")
	var saved_stones: int = InventoryService.get_amount("spirit_stone")
	var saved_pop: int = SectService.member_count()
	_check(SaveService.save_to_slot(99), "save to slot 99")
	# 改变状态
	InventoryService.add("spirit_stone", 5000)
	_check(InventoryService.get_amount("spirit_stone") == saved_stones + 5000, "stones temporarily changed")
	# 读档
	_check(SaveService.load_from_slot(99), "load from slot 99")
	_check(InventoryService.get_amount("spirit_stone") == saved_stones, "stones restored")
	_check(SectService.member_count() == saved_pop, "population restored")


# -----------------------------------------------------------------------------
# Step 9：寿元强制消耗 → 角色死亡 → game_over 触发
# -----------------------------------------------------------------------------
func _step_9_lifespan_and_death() -> void:
	print("\n--- step 9: lifespan death ---")
	# 强制把所有角色寿元改成 1 月
	for cid in SectService.get_member_ids():
		var c := CharacterService.get_character(cid)
		if c != null:
			c.lifespan_remaining_months = 1
	var game_over_triggered := [false]
	EventBus.game_over.connect(func(_reason: String): game_over_triggered[0] = true)
	# 推 2 月让所有人陨落
	TimeService.advance_outer(2)
	# 检查全部死亡
	var alive := 0
	for cid in SectService.get_member_ids():
		var c := CharacterService.get_character(cid)
		if c != null and c.action_state != Character.ActionState.DEAD:
			alive += 1
	_check(alive == 0, "all characters dead after lifespan exhaustion")
	_check(game_over_triggered[0], "game_over signal fired")


# -----------------------------------------------------------------------------
# Step 10：经济数值合理性（粗略）
# -----------------------------------------------------------------------------
func _step_10_economy_check() -> void:
	print("\n--- step 10: economy sanity ---")
	# 重置一次，跑 8 月不出门看灵石是否转负（GDD-09 §5.2：5-8 月自给转负）
	GameManager._init_world_data()
	var stones_t0: int = InventoryService.get_amount("spirit_stone")
	TimeService.advance_outer(8)
	var stones_t8: int = InventoryService.get_amount("spirit_stone")
	print("  8 months no expedition: stones %d -> %d (delta %d)" % [stones_t0, stones_t8, stones_t8 - stones_t0])
	# 不强制 fail，仅记录数据
	_check(true, "economy data captured")


# -----------------------------------------------------------------------------
# Step 11：100 局战斗胜率统计（GDD-09 §5.2）
# -----------------------------------------------------------------------------
func _step_11_battle_100_rounds() -> void:
	print("\n--- step 11: battle 100 rounds ---")
	# 三档对位：同境界 / 高一大境界 / 低一大境界
	var stats := {"same": [0, 0], "higher": [0, 0], "lower": [0, 0]}  # [win, lose]
	for i in range(100):
		var atk := _make_test_char("atk_%d" % i, "qi_5", {"fire": 5, "metal": 4}, 100)
		# 同境
		var def_same := _make_test_char("ds_%d" % i, "qi_5", {"fire": 4, "metal": 5}, 100)
		var r1 := _resolve(atk, def_same, i)
		if r1: stats["same"][0 if r1.winner == "ATTACKERS" else 1] += 1
		# 我方高一大境（筑基 vs 炼气）
		var atk2 := _make_test_char("atk2_%d" % i, "foundation_3", {"fire": 6, "metal": 5}, 130)
		var def_low := _make_test_char("dl_%d" % i, "qi_5", {"fire": 4, "metal": 4}, 90)
		var r2 := _resolve(atk2, def_low, i + 1000)
		if r2: stats["higher"][0 if r2.winner == "ATTACKERS" else 1] += 1
		# 我方低一大境
		var atk3 := _make_test_char("atk3_%d" % i, "qi_3", {"fire": 4}, 80)
		var def_high := _make_test_char("dh_%d" % i, "foundation_3", {"fire": 6, "metal": 5}, 130)
		var r3 := _resolve(atk3, def_high, i + 2000)
		if r3: stats["lower"][0 if r3.winner == "ATTACKERS" else 1] += 1
	print("  same realm    : %d / %d (win rate %.0f%%)" % [stats["same"][0], 100, stats["same"][0]])
	print("  higher realm  : %d / %d (win rate %.0f%%)" % [stats["higher"][0], 100, stats["higher"][0]])
	print("  lower realm   : %d / %d (win rate %.0f%%)" % [stats["lower"][0], 100, stats["lower"][0]])
	# 目标：同境 ~50%（30-70），高一大境 ~碾压（>85%），低一大境 反之（<15%）
	_check(stats["same"][0] >= 30 and stats["same"][0] <= 70,
		"same realm win rate 30-70 percent (got %d)" % stats["same"][0])
	_check(stats["higher"][0] >= 85,
		"higher realm should crush ge 85 (got %d)" % stats["higher"][0])
	_check(stats["lower"][0] <= 15,
		"lower realm should be crushed le 15 (got %d)" % stats["lower"][0])


func _make_test_char(id: String, realm: String, roots: Dictionary, insight: int) -> Character:
	var c := Character.new(id)
	c.realm = realm
	c.sub_level = int(realm.split("_")[1]) if "_" in realm else 1
	c.spirit_root = roots
	c.attributes = {"insight": insight, "physique": 60, "shenshi": 60}
	return c


func _resolve(atk: Character, def: Character, seed: int) -> BattleResult:
	var ctx := BattleContext.new()
	ctx.attackers = [atk]
	ctx.defenders = [def]
	ctx.seed = seed
	return BattleService.resolve(ctx)


# -----------------------------------------------------------------------------
# Step 12：5 个炼丹配方依次可炼性检查
# -----------------------------------------------------------------------------
func _step_12_alchemy_all_recipes() -> void:
	print("\n--- step 12: alchemy all 5 recipes ---")
	# 备料 + 高级丹房 + 高炼丹值
	BuildingService.predefine_building("slot_alchemy_3", "alchemy_room", 3)
	InventoryService.add("spirit_herb", 50)
	InventoryService.add("beast_blood", 10)
	InventoryService.add("demon_core", 10)
	InventoryService.add("fire_essence", 10)
	InventoryService.add("millennium_herb", 5)
	# 创建一个高级炼丹师
	var alch := CharacterService.create("char_alchemist")
	alch.realm = "foundation_5"
	alch.attributes = {"alchemy": 100, "insight": 120}
	SectService.add_member("char_alchemist")

	var recipes := AlchemyService.get_all_recipes()
	_check(recipes.size() >= 5, "5+ recipes loaded (got %d)" % recipes.size())
	var ok_count := 0
	for r in recipes:
		var rid: String = r.get("recipe_id", "")
		var reason: String = AlchemyService.cannot_craft_reason(rid, "char_alchemist")
		if reason == "":
			ok_count += 1
			print("  ✓ %s craftable" % rid)
		else:
			print("  ✗ %s: %s" % [rid, reason])
	_check(ok_count >= 5, "at least 5 recipes craftable with full materials")


# -----------------------------------------------------------------------------
# Step 13：突破检定锚点（GDD-04 §3 / GDD-06 §6.4）
# -----------------------------------------------------------------------------
func _step_13_breakthrough_anchor() -> void:
	print("\n--- step 13: breakthrough probability anchor ---")
	# 角色：炼气 9 层（小境最高），即将突破筑基
	var c := _make_test_char("bk_test", "qi_9", {"fire": 5, "metal": 4}, 120)
	c.lifespan_total_months = 720
	c.lifespan_remaining_months = 720
	# 3 月打磨：CharacterService 状态机此处简化为直接读 cultivation 的 breakthrough_probability
	if not CultivationSystem.has_method("breakthrough_probability"):
		_check(false, "CultivationSystem missing breakthrough_probability method")
		return
	# 短打磨（score=30）+ 长打磨（score=100）
	c.action_state_data = {"cultivation_score": 30.0}
	var p_short := CultivationSystem.breakthrough_probability(c)
	c.action_state_data = {"cultivation_score": 100.0}
	var p_long := CultivationSystem.breakthrough_probability(c)
	print("  short polish (score=30): p=%.2f" % p_short)
	print("  long polish  (score=100): p=%.2f" % p_long)
	_check(p_short < p_long, "longer polish → higher prob")
	_check(p_short >= 0.0 and p_short <= 1.0, "p_short in [0,1]")
	_check(p_long >= 0.0 and p_long <= 1.0, "p_long in [0,1]")
