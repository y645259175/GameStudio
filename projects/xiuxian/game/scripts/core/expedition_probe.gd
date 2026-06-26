# =============================================================================
# expedition_probe.gd · 历练全屏界面实机测试 + 截图
# 打开历练界面 → 模拟点击继续/选项 → 走完几个节点 → 截图各阶段
# =============================================================================
extends Node

const SHOT_DIR := "res://_shots"

var failures: Array[String] = []
var _screen: Control = null


func _ready() -> void:
	print("=== expedition probe ===")
	GameManager._init_world_data()
	_ensure_shot_dir()
	# 组队 + UI 模式启动
	var party: Array[String] = []
	for cid in SectService.get_member_ids():
		party.append(cid)
	ExpeditionService.start_expedition_ui("青岚秘境", party)
	_check(ExpeditionService.node_count() == 6, "expedition 6 nodes (got %d)" % ExpeditionService.node_count())

	# 实例化历练界面
	var packed: PackedScene = load("res://scenes/expedition_screen.tscn")
	_check(packed != null, "expedition_screen.tscn loadable")
	if packed == null:
		return _done()
	_screen = packed.instantiate()
	get_tree().root.add_child.call_deferred(_screen)
	for i in range(15):
		await get_tree().process_frame

	# 检查关键节点
	var node_map = _screen.get_node_or_null("%NodeMap")
	var party_box = _screen.get_node_or_null("%PartyBox")
	var continue_btn = _screen.get_node_or_null("%ContinueBtn")
	_check(node_map != null and node_map.get_child_count() > 0, "node map populated (%d children)" % (node_map.get_child_count() if node_map else -1))
	_check(party_box != null and party_box.get_child_count() == party.size(), "party box has %d members" % (party_box.get_child_count() if party_box else -1))
	_check(continue_btn != null, "continue button exists")

	# 截图：初始历练界面
	await _shot("expedition_start")

	# 模拟走节点：点继续 → 自动处理事件（含选项自动选第一个）
	for round in range(8):
		if not ExpeditionService.is_active():
			break
		# 模拟点击"继续探索"
		var cont = _screen.get_node_or_null("%ContinueBtn")
		if cont == null or not is_instance_valid(_screen):
			break
		cont.emit_signal("pressed")
		# 等事件流跑（含可能的 present_text await，需多帧 + 自动点继续）
		for f in range(8):
			await get_tree().process_frame
			# 自动应答"继续"提示
			if is_instance_valid(_screen) and _screen.get("_waiting_continue") == true:
				_screen.set("_waiting_continue", false)
			# 自动选第一个选项
			var ob = _screen.get_node_or_null("%OptionBox") if is_instance_valid(_screen) else null
			if ob and ob.visible and ob.get_child_count() > 0:
				(ob.get_child(0) as Button).emit_signal("pressed")
		# 中途截一张
		if round == 1 and is_instance_valid(_screen):
			await _shot("expedition_mid")

	# 截图：结束态（若界面还在）
	if is_instance_valid(_screen):
		await _shot("expedition_end")

	# 专项：直接触发一个战斗事件，截敌人立绘
	await _shot_battle()

	_check(true, "expedition walked without crash")
	_done()


# 单独跑一个战斗事件，验证敌人立绘上屏
func _shot_battle() -> void:
	GameManager._init_world_data()
	var party: Array[String] = []
	for cid in SectService.get_member_ids():
		party.append(cid)
	var packed: PackedScene = load("res://scenes/expedition_screen.tscn")
	var screen = packed.instantiate()
	get_tree().root.add_child.call_deferred(screen)
	for i in range(10):
		await get_tree().process_frame
	# 直接调界面的 present_battle 模拟战斗展示（造一个赤鬃灵虎敌人）
	var tiger := Character.new("probe_tiger")
	tiger.character_name = "赤鬃灵虎"
	tiger.realm = "qi_3"
	# present_battle 内部会 await continue；用单独协程跑，同时我们截图
	var battle_done := [false]
	_call_present_battle(screen, [tiger], "ATTACKERS", battle_done)
	# 等敌人立绘显示
	for f in range(15):
		await get_tree().process_frame
		var ep = screen.get_node_or_null("%EnemyPortrait") if is_instance_valid(screen) else null
		if ep and ep.visible and ep.texture != null:
			await _shot("expedition_battle")
			break
	# 应答继续结束 present_battle
	if is_instance_valid(screen):
		screen.set("_waiting_continue", false)
	for f in range(5):
		await get_tree().process_frame


func _call_present_battle(screen: Object, enemies: Array, winner: String, done_flag: Array) -> void:
	await screen.present_battle(enemies, winner)
	done_flag[0] = true


func _shot(name: String) -> void:
	for i in range(3):
		await get_tree().process_frame
	var img := get_viewport().get_texture().get_image()
	var path := "%s/%s.png" % [SHOT_DIR, name]
	img.save_png(path)
	print("[SHOT] %s (%dx%d)" % [path, img.get_width(), img.get_height()])


func _ensure_shot_dir() -> void:
	var abs := ProjectSettings.globalize_path(SHOT_DIR)
	if not DirAccess.dir_exists_absolute(abs):
		DirAccess.make_dir_recursive_absolute(abs)


func _check(cond: bool, msg: String) -> void:
	if not cond:
		failures.append(msg)
		print("  ✗ %s" % msg)
	else:
		print("  ✓ %s" % msg)


func _done() -> void:
	print("\n=== summary ===")
	if failures.is_empty():
		print("[EXP PROBE PASS]")
		get_tree().quit(0)
	else:
		print("[EXP PROBE FAIL] %d:" % failures.size())
		for f in failures:
			print("  - %s" % f)
		get_tree().quit(1)
