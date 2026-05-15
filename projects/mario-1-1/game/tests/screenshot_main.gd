extends SceneTree

func _initialize() -> void:
	var scene: PackedScene = load("res://scenes/main.tscn")
	if not scene:
		printerr("FAIL: cannot load main.tscn")
		quit(1)
		return
	var instance: Node = scene.instantiate()
	get_root().add_child(instance)
	for i in range(8):
		await process_frame
	var img: Image = get_root().get_viewport().get_texture().get_image()
	var err := img.save_png("user://screenshot_main.png")
	if err == OK:
		print("PASS: saved (%dx%d)" % [img.get_width(), img.get_height()])
	quit(0)
