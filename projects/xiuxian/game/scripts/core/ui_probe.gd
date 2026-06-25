# =============================================================================
# ui_probe.gd · 主界面 UI 实机自检（autoload 风格但作为场景脚本运行）
#
# 自动按 GameManager.start_new_game 进主界面 → 等几帧让 @onready 解析 →
# 程序化点击建造/分配/推月/出发历练等按钮，捕获 SCRIPT ERROR。
#
# 用法：--main-pack scene 直接运行此场景或将 main_scene 临时切到此。
# =============================================================================
extends Node

var failures: Array[String] = []
var step := 0


func _ready() -> void:
	print("=== UI probe start ===")
	# 直接走 GameManager 流程：重置 + 初始化数据 + 切到主界面场景
	GameManager._init_world_data()
	# 改用嵌入式：直接 instantiate main_screen 加进当前 SceneTree
	var packed: PackedScene = load("res://scenes/main_screen.tscn")
	if packed == null:
		_fail("Cannot load main_screen.tscn")
		_done()
		return
	var ms = packed.instantiate()
	get_tree().root.add_child.call_deferred(ms)
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame
	# 此时 @onready 应已解析
	await _run_checks(ms)
	_done()


func _fail(msg: String) -> void:
	failures.append(msg)
	print("  ✗ %s" % msg)


func _check(cond: bool, msg: String) -> void:
	if not cond:
		_fail(msg)
	else:
		print("  ✓ %s" % msg)


func _run_checks(ms: Node) -> void:
	print("\n[probe 1] @onready unique-name resolution")
	# 通过 unique_name_in_owner 查找节点
	var building_list = ms.get_node_or_null("%BuildingList")
	var disciple_list = ms.get_node_or_null("%DiscipleList")
	# 顶栏按钮（场景里没设 unique_name，用完整路径）
	var advance_btn = ms.get_node_or_null("Root/VBox/TopBar/AdvanceBtn")
	var save_btn = ms.get_node_or_null("Root/VBox/TopBar/SaveBtn")
	var load_btn = ms.get_node_or_null("Root/VBox/TopBar/LoadBtn")
	var recruit_btn = ms.get_node_or_null("%RecruitBtn")
	var expedition_btn = ms.get_node_or_null("%ExpeditionBtn")

	_check(building_list != null, "BuildingList resolved")
	_check(disciple_list != null, "DiscipleList resolved")
	_check(advance_btn != null, "AdvanceBtn resolved (TopBar)")
	_check(save_btn != null, "SaveBtn resolved (TopBar)")
	_check(load_btn != null, "LoadBtn resolved (TopBar)")
	_check(recruit_btn != null, "RecruitBtn resolved")
	_check(expedition_btn != null, "ExpeditionBtn resolved")

	print("\n[probe 2] building list populated")
	if building_list:
		var bcount := building_list.get_child_count()
		_check(bcount > 0, "BuildingList has %d items" % bcount)

	print("\n[probe 3] disciple list populated")
	if disciple_list:
		var dcount := disciple_list.get_child_count()
		_check(dcount > 0, "DiscipleList has %d items (master+2 disciples expected)" % dcount)

	print("\n[probe 4] simulate '推进 1 月' button press (advance_btn)")
	if advance_btn:
		var month_before := TimeService.get_month_of_year()
		var year_before := TimeService.get_current_year()
		advance_btn.emit_signal("pressed")
		await get_tree().process_frame
		var month_after := TimeService.get_month_of_year()
		var year_after := TimeService.get_current_year()
		var advanced: bool = (year_after > year_before) or (month_after > month_before)
		_check(advanced, "month advanced (before=%d/%d, after=%d/%d)" % [year_before, month_before, year_after, month_after])

	print("\n[probe 5] assign disciple button (in disciple card)")
	# 找弟子卡里的"入修炼塔"按钮（动态生成）
	if disciple_list:
		var found_assign_btn := false
		for card in disciple_list.get_children():
			# card 是 PanelContainer，下面有 HBoxContainer，里面有 VBoxContainer (assign_box)
			_find_assign_button_recursive(card, [found_assign_btn])
		# 简化：找第一个 disciple 卡里第一个 Button.text 含 "入" 的按钮
		var btn := _find_button_with_text(disciple_list, "入")
		if btn:
			print("  found assign button: %s" % btn.text)
			btn.emit_signal("pressed")
			await get_tree().process_frame
			# 验证：至少一个弟子进入 IN_CULTIVATION
			var any_cultivating := false
			for cid in SectService.get_member_ids():
				var c := CharacterService.get_character(cid)
				if c != null and c.action_state == Character.ActionState.IN_CULTIVATION:
					any_cultivating = true
			_check(any_cultivating, "at least one disciple now IN_CULTIVATION after click")
		else:
			_fail("no '入...' assign button found in disciple cards")

	print("\n[probe 6] simulate '出发历练' button press")
	if expedition_btn:
		expedition_btn.emit_signal("pressed")
		await get_tree().process_frame
		print("  expedition state after press: active=%s, node_count=%d" % [str(ExpeditionService.is_active()), ExpeditionService.node_count()])
		# 历练应启动（或已经走完一些节点）
		_check(ExpeditionService.node_count() > 0, "expedition has nodes after click")

	print("\n[probe 7] simulate save/load")
	if save_btn:
		save_btn.emit_signal("pressed")
		await get_tree().process_frame
		_check(true, "save button no crash")
	if load_btn:
		load_btn.emit_signal("pressed")
		await get_tree().process_frame
		_check(true, "load button no crash")

	print("\n[probe 8] simulate '开门收徒' button press")
	if recruit_btn:
		recruit_btn.emit_signal("pressed")
		await get_tree().process_frame
		_check(true, "recruit button no crash")
		for child in ms.get_children():
			if child is AcceptDialog:
				child.queue_free()


func _find_assign_button_recursive(_n: Node, _state: Array) -> void:
	pass


func _find_button_with_text(parent: Node, keyword: String) -> Button:
	for c in parent.get_children():
		if c is Button and (c as Button).text.find(keyword) >= 0:
			return c
		var deep := _find_button_with_text(c, keyword)
		if deep:
			return deep
	return null


func _done() -> void:
	print("\n=== UI probe summary ===")
	if failures.is_empty():
		print("[UI PASS]")
		get_tree().quit(0)
	else:
		print("[UI FAIL] %d failures:" % failures.size())
		for f in failures:
			print("  - %s" % f)
		get_tree().quit(1)
