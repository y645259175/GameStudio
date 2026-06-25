# =============================================================================
# main_screen.gd · M3 第一可运行画面（宗门主界面）
#
# 包含：
#   - 顶栏：年/月时间 + 资源（灵石/灵草）+ "推进 1 月"按钮 + "存档/读档"
#   - 左：建筑列表（5 建筑，等级/进度/分配）+ 建造/升级按钮
#   - 右：弟子列表（姓名/境界/状态）+ 分配到建筑选择
#   - 底：事件日志（订阅 EventBus 关键 signal）
#
# 数据：从 service 层拉，从不直接持 character/sect 字段引用。
# UI 风格：宣纸底 + 墨色文字 + 朱砂强调，对应 anchor-ui-panel 基调。
# =============================================================================
extends Control

const COLOR_PAPER := Color("#F5EFE0")
const COLOR_INK := Color("#1A1814")
const COLOR_VERMILION := Color("#A93226")
const COLOR_SHANQING := Color("#4A6670")
const COLOR_BRONZE := Color("#8C6D3F")

@onready var time_label: Label = %TimeLabel
@onready var resource_label: Label = %ResourceLabel
@onready var building_list: VBoxContainer = %BuildingList
@onready var disciple_list: VBoxContainer = %DiscipleList
@onready var log_text: RichTextLabel = %LogText
@onready var expedition_bar: Control = %ExpeditionBar
@onready var expedition_btn: Button = %ExpeditionBtn
@onready var expedition_status: Label = %ExpeditionStatus
@onready var expedition_advance_btn: Button = %ExpeditionAdvanceBtn
@onready var expedition_retreat_btn: Button = %ExpeditionRetreatBtn

const DEFAULT_DISCIPLE_PORTRAITS := [
	"res://art/m3/portraits/disciple_male.png",
	"res://art/m3/portraits/disciple_female.png",
]


func _ready() -> void:
	# 世界已由 GameManager.start_new_game / continue_game 初始化好
	_connect_signals()
	_refresh_all()
	_log("[color=#A93226]%s[/color]——欢迎门主，%s 已立。" % [
		"%d 年 %d 月" % [TimeService.get_current_year(), TimeService.get_month_of_year()],
		SectService.get_sect().sect_name,
	], false)


# -----------------------------------------------------------------------------
# Signal 订阅（事件日志）
# -----------------------------------------------------------------------------
func _connect_signals() -> void:
	EventBus.month_advanced.connect(_on_month_advanced)
	EventBus.building_construction_started.connect(_on_building_started)
	EventBus.building_level_up.connect(_on_building_done)
	EventBus.sub_realm_advanced.connect(_on_sub_realm_advanced)
	EventBus.breakthrough_succeeded.connect(_on_breakthrough_succeeded)
	EventBus.breakthrough_failed.connect(_on_breakthrough_failed)
	ExpeditionService.node_entered.connect(_on_expediton_node_entered)
	ExpeditionService.expedition_started.connect(_on_expedition_started)
	ExpeditionService.expedition_finished.connect(_on_expedition_finished)
	EventBus.world_event_triggered.connect(_on_world_event_triggered)
	SectService.salary_paid.connect(_on_salary_paid)
	EventBus.character_died.connect(_on_character_died)
	EventBus.lifespan_warning.connect(_on_lifespan_warning)
	EventBus.game_over.connect(_on_game_over)
	RecruitService.recruit_candidates_ready.connect(_on_recruit_candidates)
	RecruitService.auto_recruit_arrived.connect(_on_auto_recruit)


# -----------------------------------------------------------------------------
# 招收（GDD-05 §8）
# -----------------------------------------------------------------------------
func _on_recruit_pressed() -> void:
	if RecruitService.is_recruiting():
		_log("[color=#8C6D3F]已在开门收徒中，请等待月末…[/color]")
		return
	if not RecruitService.has_housing_room():
		_log("[color=#A93226]弟子居所已满，无法招收（可升级居所扩容）[/color]")
		return
	if RecruitService.start_active_recruit():
		_log("[color=#A93226]开门收徒，需 %d 灵石，月末有缘者将至…[/color]" % RecruitService.ACTIVE_RECRUIT_COST)
		_refresh_topbar()
	else:
		_log("[color=#A93226]灵石不足，无法开门收徒（需 %d）[/color]" % RecruitService.ACTIVE_RECRUIT_COST)


func _on_recruit_candidates(candidates: Array) -> void:
	_show_recruit_dialog("开门收徒 · 有缘者求收", candidates)


func _on_auto_recruit(candidate: Dictionary) -> void:
	_show_recruit_dialog("有散修前来投奔", [candidate])


func _show_recruit_dialog(title: String, candidates: Array) -> void:
	var dlg := AcceptDialog.new()
	dlg.title = title
	dlg.dialog_hide_on_ok = true
	dlg.ok_button_text = "全部婉拒"
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 10)
	var tip := Label.new()
	tip.text = "选择一位收入门下（居所余位 %d）：" % (BuildingService.get_housing_capacity() - SectService.member_count())
	tip.add_theme_color_override("font_color", COLOR_INK)
	vb.add_child(tip)
	for cand in candidates:
		vb.add_child(_make_candidate_row(cand, dlg))
	dlg.add_child(vb)
	add_child(dlg)
	dlg.popup_centered(Vector2i(460, 120 + candidates.size() * 90))
	dlg.confirmed.connect(func(): dlg.queue_free())


func _make_candidate_row(cand: Dictionary, dlg: AcceptDialog) -> Control:
	var panel := _wrap_card(HBoxContainer.new())
	var hb: HBoxContainer = panel.get_child(0)
	hb.add_theme_constant_override("separation", 10)
	var portrait := TextureRect.new()
	portrait.custom_minimum_size = Vector2(54, 72)
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	var pp: String = cand.get("portrait", "")
	if pp != "" and ResourceLoader.exists(pp):
		portrait.texture = load(pp)
	hb.add_child(portrait)

	var vb := VBoxContainer.new()
	vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var nm := Label.new()
	var gender_cn := "♂" if cand.get("gender") == "male" else "♀"
	nm.text = "%s %s  (%d 岁)" % [cand.get("name", "无名"), gender_cn, cand.get("age_years", 16)]
	nm.add_theme_color_override("font_color", COLOR_INK)
	vb.add_child(nm)
	var roots_str := ""
	for el in cand.get("spirit_root", {}):
		roots_str += "%s%d " % [_element_cn(el), cand["spirit_root"][el]]
	var detail := Label.new()
	detail.text = "灵根：%s(共%d)  悟性 %d" % [roots_str, cand.get("root_total", 0), int(cand.get("attributes", {}).get("insight", 0))]
	detail.add_theme_color_override("font_color", COLOR_SHANQING)
	detail.add_theme_font_size_override("font_size", 11)
	vb.add_child(detail)
	hb.add_child(vb)

	var btn := Button.new()
	btn.text = "收入门下"
	btn.pressed.connect(func():
		var cid := RecruitService.accept_candidate(cand)
		if cid != "":
			_log("[color=#A93226]✦ %s 拜入青云宗 ✦[/color]" % cand.get("name", ""))
			_refresh_all()
		dlg.queue_free()
	)
	hb.add_child(btn)
	return panel


func _element_cn(el: String) -> String:
	return {"fire":"火","water":"水","wood":"木","metal":"金","earth":"土"}.get(el, el)


func _on_game_over(_reason: String) -> void:
	_log("[color=#A93226]☠ 宗门覆灭…[/color]")
	await get_tree().create_timer(1.5).timeout
	get_tree().change_scene_to_file(GameManager.SCENE_GAME_OVER)


func _on_salary_paid(total: int, affordable: bool) -> void:
	if not affordable:
		_log("[color=#A93226]⚠ 灵石不足以支付月俸（需 %d）！弟子暂未离去，但宗门已入不敷出，速去历练！[/color]" % total)
	elif total > 0:
		_log("[color=#8C6D3F]支付弟子月俸 %d 灵石[/color]" % total)


func _on_character_died(cid: String, _cause: String) -> void:
	_log("[color=#A93226]☠ %s 寿元耗尽，溘然长逝。[/color]" % cid)
	_refresh_all()


func _on_lifespan_warning(cid: String, remaining: int) -> void:
	var c := CharacterService.get_character(cid)
	if c != null:
		_log("[color=#A93226]※ %s 寿元将近（剩 %d 月），宜早作打算 ※[/color]" % [c.character_name, remaining])


func _on_month_advanced(month: int, year: int, _moy: int) -> void:
	_refresh_all()
	_log("[color=#4A6670]——岁月流转，已是 %d 年 %d 月——[/color]" % [year, month])


func _on_building_started(slot_id: String, building_id: String, _level: int) -> void:
	_log("开始建造 [color=#A93226]%s[/color]（slot=%s）" % [_building_name(building_id), slot_id])


func _on_building_done(_slot_id: String, building_id: String, level: int) -> void:
	_log("[color=#8C6D3F]✦ %s 建成至 lv%d ✦[/color]" % [_building_name(building_id), level])
	_refresh_buildings()


func _on_sub_realm_advanced(cid: String, realm: String, sub: int) -> void:
	var c := CharacterService.get_character(cid)
	if c != null:
		_log("[color=#4A6670]%s 修为精进，已至 %s %d 层[/color]" % [c.character_name, _realm_cn(realm), sub])
		_refresh_disciples()


func _on_breakthrough_succeeded(cid: String, next_realm: String) -> void:
	var c := CharacterService.get_character(cid)
	if c != null:
		_log("[color=#A93226]★ %s 突破成功，跻身 %s 境 ★[/color]" % [c.character_name, _realm_cn(next_realm)])
		_refresh_disciples()


func _on_breakthrough_failed(cid: String, _info: Dictionary) -> void:
	var c := CharacterService.get_character(cid)
	if c != null:
		_log("[color=#8C6D3F]※ %s 突破失败，跌落一层 ※[/color]" % c.character_name)
		_refresh_disciples()


# -----------------------------------------------------------------------------
# 历练（ExpeditionService signal 回调）
# -----------------------------------------------------------------------------
func _on_expedition_started(map_id: String, _participant_ids: Array) -> void:
	_log("[color=#A93226]✦ 出发历练：%s（共 %d 处秘地）✦[/color]" % [map_id, ExpeditionService.node_count()])
	expedition_btn.visible = false
	expedition_advance_btn.visible = true
	expedition_retreat_btn.visible = true
	expedition_status.text = "准备探索..."


func _on_expediton_node_entered(node_index: int, event_id: String) -> void:
	var title := event_id
	if DataRegistry and DataRegistry.is_loaded():
		for row in DataRegistry.get_table("EventTemplate"):
			if row.get("event_id") == event_id:
				title = row.get("title_cn", event_id)
				break
	expedition_status.text = "第 %d/%d 处 · %s" % [node_index + 1, ExpeditionService.node_count(), title]


func _on_expedition_finished(reason: String) -> void:
	expedition_btn.visible = true
	expedition_advance_btn.visible = false
	expedition_retreat_btn.visible = false
	expedition_status.text = ""
	var msg := {
		"cleared": "✦ 历练圆满，满载而归 ✦",
		"timeout": "✦ 击败守关之敌，凯旋而归 ✦",
		"active": "✦ 主动撤离，平安归宗 ✦",
		"defeat": "☠ 队伍折损，狼狈撤回 ☠",
	}.get(reason, "✦ 历练结束 ✦")
	_log("[color=#A93226]%s[/color]" % msg)
	_refresh_all()


func _on_expedition_retreat_pressed() -> void:
	if ExpeditionService.is_active():
		ExpeditionService.retreat()


func _on_world_event_triggered(hook_id: String, payload: Dictionary) -> void:
	if hook_id == "event_log":
		_log("[color=#4A6670]%s[/color]" % payload.get("msg", ""), false)


func _on_expedition_start_pressed() -> void:
	# 自动选门主 + 所有闲居弟子
	var party: Array[String] = []
	for cid in SectService.get_member_ids():
		var c := CharacterService.get_character(cid)
		if c != null and c.action_state != Character.ActionState.DEAD:
			party.append(cid)
	if party.size() == 0:
		_log("[color=#A93226]无可用弟子[/color]")
		return
	ExpeditionService.start_expedition("青岚秘境", party)


func _on_expedition_advance_pressed() -> void:
	if not ExpeditionService.is_active():
		return
	ExpeditionService.advance_node()


# -----------------------------------------------------------------------------
# 顶栏：推进时间 / 存读档
# -----------------------------------------------------------------------------
func _on_advance_pressed() -> void:
	TimeService.advance_outer(1)


func _on_save_pressed() -> void:
	if SaveService.save_to_slot(0):
		_log("[color=#4A6670]✓ 存档成功[/color]")
	else:
		_log("[color=#A93226]存档失败[/color]")


func _on_load_pressed() -> void:
	if SaveService.load_from_slot(0):
		_refresh_all()
		_log("[color=#4A6670]✓ 读档成功[/color]")
	else:
		_log("[color=#A93226]读档失败：未找到存档[/color]")


# -----------------------------------------------------------------------------
# 刷新（每次状态变更后调用）
# -----------------------------------------------------------------------------
func _refresh_all() -> void:
	_refresh_topbar()
	_refresh_buildings()
	_refresh_disciples()


func _refresh_topbar() -> void:
	var year := TimeService.get_current_year()
	var moy := TimeService.get_month_of_year()
	time_label.text = "%d 年 %d 月" % [year, moy]
	var ss: int = InventoryService.get_amount("spirit_stone")
	var sh: int = InventoryService.get_amount("spirit_herb")
	var salary := SectService.monthly_salary_total()
	var pop := SectService.member_count()
	var cap := BuildingService.get_housing_capacity()
	resource_label.text = "灵石 %d   灵草 %d   月俸 %d/月   弟子 %d/%d" % [ss, sh, salary, pop, cap]
	# 灵石不足支付月俸时整体标红警示
	if ss < salary:
		resource_label.add_theme_color_override("font_color", COLOR_VERMILION)
	else:
		resource_label.add_theme_color_override("font_color", COLOR_BRONZE)


## 把卡片内容包进宣纸风 PanelContainer（提升美观 + 区隔）
func _wrap_card(content: Control) -> PanelContainer:
	var panel := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.99, 0.97, 0.91, 0.72)   # 比背景更亮的宣纸卡片
	sb.border_color = Color(0.55, 0.43, 0.25, 0.55) # 古铜描边
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(4)
	sb.content_margin_left = 10
	sb.content_margin_right = 10
	sb.content_margin_top = 8
	sb.content_margin_bottom = 8
	panel.add_theme_stylebox_override("panel", sb)
	panel.add_child(content)
	return panel


func _refresh_buildings() -> void:
	for child in building_list.get_children():
		child.queue_free()
	# 显示所有可建建筑（从配表读）
	var buildings := BuildingService.get_all_building_ids()
	for bid in buildings:
		var item := _make_building_item(bid)
		building_list.add_child(_wrap_card(item))


func _make_building_item(building_id: String) -> Control:
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 12)

	# 当前等级（如果已建）
	var current_lv := BuildingService.get_building_level(building_id)
	# slot_id 约定：slot_<building_id>（M3 简化为单实例）
	var slot_id := "slot_%s" % building_id

	# 图标
	var cfg_for_icon := BuildingService.get_level_config(building_id, max(current_lv, 1))
	var icon_path: String = cfg_for_icon.get("icon_path", "")
	var icon := TextureRect.new()
	icon.custom_minimum_size = Vector2(72, 72)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	if icon_path != "" and ResourceLoader.exists(icon_path):
		icon.texture = load(icon_path)
	hb.add_child(icon)

	# 中段：名字 + 等级 + 描述 + 进度
	var vb := VBoxContainer.new()
	vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var name_label := Label.new()
	var name_cn: String = cfg_for_icon.get("name_cn", building_id)
	name_label.text = "%s  [lv %d/3]" % [name_cn, current_lv]
	name_label.add_theme_color_override("font_color", COLOR_INK)
	vb.add_child(name_label)

	var desc_label := Label.new()
	desc_label.text = cfg_for_icon.get("desc_cn", "")
	desc_label.add_theme_color_override("font_color", COLOR_SHANQING)
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_label.add_theme_font_size_override("font_size", 11)
	vb.add_child(desc_label)

	# 建造进度（如果在造）
	var b_inst := _find_building_instance(slot_id)
	if not b_inst.is_empty() and b_inst.get("current_level", 0) < b_inst.get("target_level", 0):
		var target_lv: int = b_inst.get("target_level", 1)
		var target_cfg := BuildingService.get_level_config(building_id, target_lv)
		var needed: int = target_cfg.get("build_months", 1)
		var prog: int = b_inst.get("progress_months", 0)
		var progress := ProgressBar.new()
		progress.min_value = 0; progress.max_value = needed; progress.value = prog
		progress.show_percentage = false
		progress.custom_minimum_size = Vector2(0, 8)
		var prog_label := Label.new()
		prog_label.text = "建造中 %d/%d 月" % [prog, needed]
		prog_label.add_theme_color_override("font_color", COLOR_VERMILION)
		prog_label.add_theme_font_size_override("font_size", 11)
		vb.add_child(prog_label)
		vb.add_child(progress)
	# 已分配弟子
	if not b_inst.is_empty():
		var assigned: Array = b_inst.get("assigned_character_ids", [])
		if assigned.size() > 0:
			var alabel := Label.new()
			var names: Array[String] = []
			for cid in assigned:
				var cc := CharacterService.get_character(cid)
				if cc != null: names.append(cc.character_name)
			alabel.text = "驻所：%s" % ", ".join(names)
			alabel.add_theme_color_override("font_color", COLOR_BRONZE)
			alabel.add_theme_font_size_override("font_size", 11)
			vb.add_child(alabel)

	hb.add_child(vb)

	# 右侧按钮区（升级/建造 + 丹房炼丹）
	var btn_box := VBoxContainer.new()
	btn_box.add_theme_constant_override("separation", 4)
	var btn := Button.new()
	if current_lv == 0:
		var cfg1 := BuildingService.get_level_config(building_id, 1)
		var cs: int = cfg1.get("cost_spirit_stone", 0)
		btn.text = "建造 (%d 灵石)" % cs if cs > 0 else "建造"
		btn.pressed.connect(func(): _try_build(slot_id, building_id))
	elif current_lv < 3:
		var cfg_next := BuildingService.get_level_config(building_id, current_lv + 1)
		var cs: int = cfg_next.get("cost_spirit_stone", 0)
		btn.text = "升级 lv%d (%d 灵石)" % [current_lv + 1, cs]
		btn.pressed.connect(func(): _try_upgrade(slot_id))
	else:
		btn.text = "已满级"
		btn.disabled = true
	btn_box.add_child(btn)
	# 丹房：炼丹入口
	if building_id == "alchemy_room" and current_lv >= 1:
		var craft_btn := Button.new()
		craft_btn.text = "炼丹（%d/%d）" % [AlchemyService.active_count(), AlchemyService.max_slots()]
		craft_btn.pressed.connect(_show_alchemy_dialog)
		btn_box.add_child(craft_btn)
	hb.add_child(btn_box)

	return hb


# -----------------------------------------------------------------------------
# 炼丹面板（GDD-05 §5.5）
# -----------------------------------------------------------------------------
func _show_alchemy_dialog() -> void:
	var dlg := AcceptDialog.new()
	dlg.title = "丹房 · 炼丹"
	dlg.ok_button_text = "关闭"
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 8)

	# 进行中任务
	var tasks := AlchemyService.get_active_tasks()
	if tasks.size() > 0:
		var th := Label.new()
		th.text = "— 炼制中 —"
		th.add_theme_color_override("font_color", COLOR_VERMILION)
		vb.add_child(th)
		for t in tasks:
			var tl := Label.new()
			tl.text = "  %s  剩余 %d 月" % [t["recipe_row"].get("name_cn", ""), t["remaining"]]
			tl.add_theme_color_override("font_color", COLOR_BRONZE)
			tl.add_theme_font_size_override("font_size", 12)
			vb.add_child(tl)

	var rh := Label.new()
	rh.text = "— 配方 —"
	rh.add_theme_color_override("font_color", COLOR_INK)
	vb.add_child(rh)
	# 选炼丹值最高的可用弟子
	var best_disciple := _best_alchemist()
	for r in AlchemyService.get_all_recipes():
		vb.add_child(_make_recipe_row(r, best_disciple, dlg))

	dlg.add_child(vb)
	add_child(dlg)
	dlg.popup_centered(Vector2i(480, 160 + AlchemyService.get_all_recipes().size() * 40))
	dlg.confirmed.connect(func(): dlg.queue_free())


func _make_recipe_row(r: Dictionary, disciple_id: String, dlg: AcceptDialog) -> Control:
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 8)
	var rid: String = r.get("recipe_id", "")
	var info := Label.new()
	var mat := "%s×%d" % [_res_name(r.get("material1_id","")), int(r.get("material1_count",0))]
	if r.get("material2_id", "") != "":
		mat += " %s×%d" % [_res_name(r.get("material2_id","")), int(r.get("material2_count",0))]
	info.text = "%s  [%s]  %d月 %d%%" % [r.get("name_cn",""), mat, int(r.get("duration_months",1)), int(float(r.get("success_rate",0))*100)]
	info.add_theme_color_override("font_color", COLOR_INK)
	info.add_theme_font_size_override("font_size", 12)
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hb.add_child(info)

	var reason := AlchemyService.cannot_craft_reason(rid, disciple_id)
	var btn := Button.new()
	if reason == "":
		btn.text = "炼制"
		btn.pressed.connect(func():
			if AlchemyService.start_craft(rid, disciple_id):
				_log("[color=#A93226]开始炼制 %s[/color]" % r.get("name_cn",""))
				_refresh_all()
			dlg.queue_free()
		)
	else:
		btn.text = reason
		btn.disabled = true
	hb.add_child(btn)
	return hb


func _best_alchemist() -> String:
	var best_id := ""
	var best_skill := -1
	for cid in SectService.get_member_ids():
		var c := CharacterService.get_character(cid)
		if c == null or c.action_state == Character.ActionState.DEAD:
			continue
		var sk := int(c.attributes.get("alchemy", 0))
		if sk > best_skill:
			best_skill = sk
			best_id = cid
	return best_id


func _res_name(rid: String) -> String:
	if rid == "" or not DataRegistry.is_loaded(): return rid
	for row in DataRegistry.get_table("Resource"):
		if row.get("resource_id") == rid:
			return row.get("name_cn", rid)
	return rid


func _try_build(slot_id: String, building_id: String) -> void:
	if BuildingService.start_build(slot_id, building_id):
		_refresh_all()
	else:
		_log("[color=#A93226]建造失败：灵石不足？[/color]")


func _try_upgrade(slot_id: String) -> void:
	if BuildingService.start_upgrade(slot_id):
		_refresh_all()
	else:
		_log("[color=#A93226]升级失败：灵石不足或已满级[/color]")


func _find_building_instance(slot_id: String) -> Dictionary:
	for b in BuildingService.get_all_buildings():
		if b.get("slot_id") == slot_id:
			return b
	return {}


# -----------------------------------------------------------------------------
# 弟子列表
# -----------------------------------------------------------------------------
func _refresh_disciples() -> void:
	for child in disciple_list.get_children():
		child.queue_free()
	for cid in SectService.get_member_ids():
		var c := CharacterService.get_character(cid)
		if c == null: continue
		disciple_list.add_child(_wrap_card(_make_disciple_item(c)))


func _make_disciple_item(c: Character) -> Control:
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 10)

	var portrait := TextureRect.new()
	portrait.custom_minimum_size = Vector2(72, 96)
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	if c.portrait_id != "" and ResourceLoader.exists(c.portrait_id):
		portrait.texture = load(c.portrait_id)
	hb.add_child(portrait)

	var vb := VBoxContainer.new()
	vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var name_label := Label.new()
	var ident_cn := "门主" if c.identity == Character.Identity.MASTER_CURRENT else "弟子"
	name_label.text = "%s · %s" % [c.character_name, ident_cn]
	name_label.add_theme_color_override("font_color", COLOR_INK)
	vb.add_child(name_label)

	var realm_label := Label.new()
	realm_label.text = "%s %d 层  ·  悟性 %d  ·  寿元 %d 月" % [
		_realm_cn(c.realm), c.sub_level,
		int(c.attributes.get("insight", 0)),
		c.lifespan_remaining_months,
	]
	realm_label.add_theme_color_override("font_color", COLOR_SHANQING)
	realm_label.add_theme_font_size_override("font_size", 11)
	vb.add_child(realm_label)

	var state_label := Label.new()
	state_label.text = "状态：%s" % _state_cn(c)
	state_label.add_theme_color_override("font_color", COLOR_BRONZE)
	state_label.add_theme_font_size_override("font_size", 11)
	vb.add_child(state_label)

	# 经验进度
	var exp: float = c.attributes.get("experience", 0.0)
	var thresh: int = CultivationSystem.experience_threshold(c.realm, c.sub_level)
	if thresh > 0:
		var exp_bar := ProgressBar.new()
		exp_bar.min_value = 0; exp_bar.max_value = thresh
		exp_bar.value = min(exp, thresh)
		exp_bar.show_percentage = false
		exp_bar.custom_minimum_size = Vector2(0, 6)
		vb.add_child(exp_bar)

	hb.add_child(vb)

	# 分配操作区（门主不参与建筑分配）
	if c.identity != Character.Identity.MASTER_CURRENT:
		var assign_box := VBoxContainer.new()
		assign_box.add_theme_constant_override("separation", 3)
		var cur_slot := _character_current_slot(c.id)
		# 可分配建筑（弟子分配类：修炼塔/藏经阁）的按钮
		for bid in ["cultivation_tower", "library"]:
			if BuildingService.get_building_level(bid) < 1:
				continue
			var slot_id := "slot_%s" % bid
			var is_here := (cur_slot == slot_id)
			var ab := Button.new()
			ab.custom_minimum_size = Vector2(96, 0)
			ab.add_theme_font_size_override("font_size", 12)
			var cap := BuildingService.get_capacity(bid)
			var used := BuildingService.get_assigned_count(slot_id)
			if is_here:
				ab.text = "✓ %s" % _building_name(bid)
				ab.add_theme_color_override("font_color", COLOR_VERMILION)
				ab.pressed.connect(_on_unassign_pressed.bind(slot_id, c.id))
			else:
				ab.text = "入%s %d/%d" % [_building_name(bid), used, cap]
				ab.disabled = (cap > 0 and used >= cap)
				ab.pressed.connect(_on_assign_pressed.bind(slot_id, c.id))
			assign_box.add_child(ab)
		hb.add_child(assign_box)
	return hb


func _character_current_slot(character_id: String) -> String:
	for b in BuildingService.get_all_buildings():
		if b.get("assigned_character_ids", []).has(character_id):
			return b.get("slot_id", "")
	return ""


func _on_assign_pressed(slot_id: String, character_id: String) -> void:
	var code := BuildingService.assign_character_ex(slot_id, character_id)
	var cname: String = CharacterService.get_character(character_id).character_name
	match code:
		0: _log("[color=#A93226]%s 进入 %s[/color]" % [cname, _slot_building_name(slot_id)])
		3: _log("[color=#A93226]%s 已满员，无法分配[/color]" % _slot_building_name(slot_id))
		_: _log("[color=#A93226]分配失败[/color]")
	_refresh_all()


func _on_unassign_pressed(slot_id: String, character_id: String) -> void:
	BuildingService.unassign_character(slot_id, character_id)
	# 解除后转回闲居
	CharacterService.set_action_state(character_id, Character.ActionState.IDLE, {})
	var cname: String = CharacterService.get_character(character_id).character_name
	_log("[color=#4A6670]%s 离开 %s，回归闲居[/color]" % [cname, _slot_building_name(slot_id)])
	_refresh_all()


func _slot_building_name(slot_id: String) -> String:
	for b in BuildingService.get_all_buildings():
		if b.get("slot_id") == slot_id:
			return _building_name(b.get("building_id", ""))
	return slot_id


# -----------------------------------------------------------------------------
# 辅助
# -----------------------------------------------------------------------------
func _building_name(building_id: String) -> String:
	var cfg := BuildingService.get_level_config(building_id, 1)
	return cfg.get("name_cn", building_id) if not cfg.is_empty() else building_id


func _realm_cn(realm: String) -> String:
	var tier := realm.split("_")[0] if "_" in realm else realm
	return {"mortal":"凡人", "qi":"炼气", "foundation":"筑基", "golden":"金丹", "yuanying":"元婴", "huashen":"化神"}.get(tier, tier)


func _state_cn(c: Character) -> String:
	match c.action_state:
		Character.ActionState.IDLE: return "闲居"
		Character.ActionState.IN_CULTIVATION:
			var mode: String = c.action_state_data.get("mode", "normal")
			return "闭关（瓶颈）" if mode == "bottleneck" else "闭关中"
		Character.ActionState.DEAD: return "陨落"
		_: return str(c.action_state)


func _log(msg: String, with_time: bool = true) -> void:
	var prefix := ""
	if with_time:
		var year := TimeService.get_current_year()
		var moy := TimeService.get_month_of_year()
		prefix = "[color=#8C6D3F][%d年%d月][/color] " % [year, moy]
	log_text.append_text(prefix + msg + "\n")
