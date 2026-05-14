extends SceneTree

## 加载主游戏场景，发球，渲染几帧后截图
## 输出：user://screenshot_game.png

func _initialize() -> void:
	var scene: PackedScene = load("res://scenes/main.tscn")
	if not scene:
		printerr("FAIL: cannot load main.tscn")
		quit(1)
		return
	var instance: Node = scene.instantiate()
	get_root().add_child(instance)

	# 等几帧让 _ready / 砖块生成完成
	for i in range(5):
		await process_frame

	var img: Image = get_root().get_viewport().get_texture().get_image()
	var save_err := img.save_png("user://screenshot_game.png")
	if save_err == OK:
		print("PASS: saved to user://screenshot_game.png (%dx%d)" % [img.get_width(), img.get_height()])
	else:
		printerr("FAIL: save_png error %d" % save_err)
		quit(1)
		return
	quit(0)
