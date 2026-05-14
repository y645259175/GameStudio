extends SceneTree

## 加载主菜单场景，渲染一帧，截图保存到 user://，然后 quit
## 用于 AI 自动验证 UI 布局是否正确
##
## 输出：user://screenshot_main_menu.png
## Windows 实际路径：%APPDATA%\Godot\app_userdata\Breakout\screenshot_main_menu.png

func _initialize() -> void:
	var menu_scene: PackedScene = load("res://scenes/main_menu.tscn")
	if not menu_scene:
		printerr("FAIL: cannot load main_menu.tscn")
		quit(1)
		return
	var instance: Node = menu_scene.instantiate()
	get_root().add_child(instance)

	# 等待 2 帧让布局稳定
	await process_frame
	await process_frame

	var img: Image = get_root().get_viewport().get_texture().get_image()
	var save_err := img.save_png("user://screenshot_main_menu.png")
	if save_err == OK:
		print("PASS: saved to user://screenshot_main_menu.png (%dx%d)" % [img.get_width(), img.get_height()])
	else:
		printerr("FAIL: save_png error %d" % save_err)
		quit(1)
		return
	quit(0)
