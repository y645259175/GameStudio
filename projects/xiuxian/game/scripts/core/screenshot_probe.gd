# =============================================================================
# screenshot_probe.gd · 实机截图工具
# 加载指定场景，渲染若干帧，把 viewport 截图保存为 PNG，供 AI read_file 查看实际画面。
# 用法：把 main_scene 临时设为本场景，或 --path 直接跑。
# 通过环境/常量切换截哪个场景。
# =============================================================================
extends Node

const SHOT_DIR := "res://_shots"
const TARGET_SCENE := "res://scenes/main_screen.tscn"


func _ready() -> void:
	print("=== screenshot probe ===")
	# 初始化世界数据
	GameManager._init_world_data()
	# 实例化目标场景
	var packed: PackedScene = load(TARGET_SCENE)
	if packed == null:
		print("[SHOT] cannot load %s" % TARGET_SCENE)
		get_tree().quit(1)
		return
	var scene = packed.instantiate()
	get_tree().root.add_child.call_deferred(scene)
	# 等待多帧确保 UI 布局 + 纹理加载完成
	for i in range(20):
		await get_tree().process_frame
	# 截图
	var dir := DirAccess.open("res://")
	if not DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(SHOT_DIR)):
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(SHOT_DIR))
	var img := get_viewport().get_texture().get_image()
	var path := "%s/main_screen.png" % SHOT_DIR
	var err := img.save_png(path)
	print("[SHOT] saved %s (err=%d) size=%dx%d" % [path, err, img.get_width(), img.get_height()])
	await get_tree().process_frame
	get_tree().quit(0)
