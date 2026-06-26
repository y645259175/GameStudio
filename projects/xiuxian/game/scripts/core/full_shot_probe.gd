# =============================================================================
# full_shot_probe.gd · 全界面截图诊断工具
# 一次性截：主菜单 / 主界面 / 招收弹窗 / 炼丹弹窗 / 游戏结束
# 供 AI 读图做品质诊断。窗口模式运行（非 headless）。
# =============================================================================
extends Node

const SHOT_DIR := "res://_shots"


func _ready() -> void:
	print("=== full shot probe ===")
	_ensure_dir()
	await _shot_main_menu()
	await _shot_main_screen()
	await _shot_recruit_dialog()
	await _shot_alchemy_dialog()
	await _shot_game_over()
	print("[FULL SHOT DONE]")
	get_tree().quit(0)


func _shot_main_menu() -> void:
	var packed: PackedScene = load("res://scenes/main_menu.tscn")
	var s = packed.instantiate()
	get_tree().root.add_child.call_deferred(s)
	for i in range(15): await get_tree().process_frame
	await _shot("01_main_menu")
	s.queue_free()
	await get_tree().process_frame


func _shot_main_screen() -> void:
	GameManager._init_world_data()
	var packed: PackedScene = load("res://scenes/main_screen.tscn")
	var s = packed.instantiate()
	get_tree().root.add_child.call_deferred(s)
	for i in range(15): await get_tree().process_frame
	await _shot("02_main_screen")
	# 留着 main_screen 给后续弹窗用
	_main = s


var _main: Node = null


func _shot_recruit_dialog() -> void:
	if _main == null: return
	# 触发招收弹窗
	if _main.has_method("_on_recruit_pressed"):
		_main._on_recruit_pressed()
		for i in range(12): await get_tree().process_frame
		await _shot("03_recruit_dialog")
		# 关闭弹窗
		for child in _main.get_children():
			if child is AcceptDialog:
				child.queue_free()
		await get_tree().process_frame


func _shot_alchemy_dialog() -> void:
	if _main == null: return
	# 先预建丹房让炼丹按钮可用
	BuildingService.predefine_building("slot_alchemy_shot", "alchemy_room", 1)
	if _main.has_method("_show_alchemy_dialog"):
		_main._show_alchemy_dialog()
		for i in range(12): await get_tree().process_frame
		await _shot("04_alchemy_dialog")
		for child in _main.get_children():
			if child is AcceptDialog:
				child.queue_free()
		await get_tree().process_frame
	if is_instance_valid(_main):
		_main.queue_free()
		await get_tree().process_frame


func _shot_game_over() -> void:
	var packed: PackedScene = load("res://scenes/game_over.tscn")
	if packed == null: return
	var s = packed.instantiate()
	get_tree().root.add_child.call_deferred(s)
	for i in range(15): await get_tree().process_frame
	await _shot("05_game_over")
	s.queue_free()
	await get_tree().process_frame


func _shot(name: String) -> void:
	for i in range(3): await get_tree().process_frame
	var img := get_viewport().get_texture().get_image()
	img.save_png("%s/%s.png" % [SHOT_DIR, name])
	print("[SHOT] %s" % name)


func _ensure_dir() -> void:
	var abs := ProjectSettings.globalize_path(SHOT_DIR)
	if not DirAccess.dir_exists_absolute(abs):
		DirAccess.make_dir_recursive_absolute(abs)
