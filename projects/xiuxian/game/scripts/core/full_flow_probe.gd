# =============================================================================
# full_flow_probe.gd · 完整用户启动链路实测
# 模拟：双击启动 → 主菜单 → 点新游戏 → 主界面加载 → 点几个按钮 → 退出
# =============================================================================
extends Node

var failures: Array[String] = []


func _ready() -> void:
	print("=== Full flow probe ===")
	# 1) 加载主菜单（默认 main_scene）
	var menu_packed: PackedScene = load("res://scenes/main_menu.tscn")
	_check(menu_packed != null, "main_menu.tscn loadable")
	if not menu_packed:
		return _done()
	var menu = menu_packed.instantiate()
	get_tree().root.add_child.call_deferred(menu)
	await get_tree().process_frame
	await get_tree().process_frame
	# 找新游戏按钮
	var new_game_btn = menu.get_node_or_null("CenterBox/NewGameBtn")
	_check(new_game_btn != null, "NewGameBtn exists in main_menu")
	if not new_game_btn:
		return _done()

	# 2) 模拟点击"开始新游戏"——这会调 GameManager.start_new_game 并 change_scene
	# 但 change_scene 在测试中会卸载当前节点；为安全起见，我们直接调 _init_world_data + 手动 instantiate
	GameManager._init_world_data()
	_check(SectService.member_count() == 3, "after start_new_game: 3 sect members")
	_check(InventoryService.get_amount("spirit_stone") >= 2000, "start with >= 2000 stones")
	_check(BuildingService.get_building_level("main_hall") == 1, "main_hall pre-built")

	# 3) 加载 main_screen 模拟切场景
	menu.queue_free()
	await get_tree().process_frame
	var main_packed: PackedScene = load("res://scenes/main_screen.tscn")
	_check(main_packed != null, "main_screen.tscn loadable")
	if not main_packed:
		return _done()
	var ms = main_packed.instantiate()
	get_tree().root.add_child.call_deferred(ms)
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame

	# 4) 检查关键节点 + 列表填充（这是用户最关心的"完全玩不了"问题）
	var bl = ms.get_node_or_null("%BuildingList")
	var dl = ms.get_node_or_null("%DiscipleList")
	_check(bl != null and bl.get_child_count() == 5, "building list 5 items (got %d)" % (bl.get_child_count() if bl else -1))
	_check(dl != null and dl.get_child_count() == 3, "disciple list 3 items (got %d)" % (dl.get_child_count() if dl else -1))

	# 5) 推月按钮可用
	var adv = ms.get_node_or_null("Root/VBox/TopBar/AdvanceBtn")
	if adv:
		var m0 := TimeService.get_month_of_year()
		adv.emit_signal("pressed")
		await get_tree().process_frame
		_check(TimeService.get_month_of_year() != m0 or TimeService.get_current_year() > 1, "month advanced via UI button")

	_done()


func _check(cond: bool, msg: String) -> void:
	if not cond:
		failures.append(msg)
		print("  ✗ %s" % msg)
	else:
		print("  ✓ %s" % msg)


func _done() -> void:
	print("\n=== Summary ===")
	if failures.is_empty():
		print("[FULL FLOW PASS]")
		get_tree().quit(0)
	else:
		print("[FULL FLOW FAIL] %d:" % failures.size())
		for f in failures:
			print("  - %s" % f)
		get_tree().quit(1)
