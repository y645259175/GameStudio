extends SceneTree

## screenshot_tool · M6 视觉评审用的截图工具
## 启动 main 场景，跑 N 秒，多次按真实输入推进玩家，每隔几秒截屏一张
## 输出到 projects/bolt-1-1/reports/screenshots/sprint-3-screenshot-<timestamp>.png
##
## 注意：headless 模式下 RenderingServer 仍能渲染（Godot 4 会用 Vulkan offscreen），
## 但 `--headless --rendering-driver opengl3` 不行；保险起见我们禁用 headless 启动这个 test。

var _frame: int = 0


func _init() -> void:
	await process_frame
	change_scene_to_file("res://scenes/main.tscn")
	await process_frame
	await create_timer(1.0).timeout

	var screenshots := [
		{"at_frame": 60,   "name": "01_start"},          # 出生
		{"at_frame": 240,  "name": "02_first_mossroll"}, # 第一只 mossroll 附近
		{"at_frame": 600,  "name": "03_cache_box_area"}, # cache box 区
		{"at_frame": 1200, "name": "04_mid_level"},      # 中段
		{"at_frame": 1800, "name": "05_shellpod"},       # shellpod 区
		{"at_frame": 2200, "name": "06_signal_tower"}    # 信号塔
	]
	var idx: int = 0

	# 持续按 right + run 推进
	Input.action_press("move_right")
	Input.action_press("run")

	while _frame < 2400 and idx < screenshots.size():
		_frame += 1
		# 简单的卡住检测 → 跳
		var root := get_root()
		var main := root.get_node_or_null("Main")
		var player := main.get_node_or_null("Player") if main else null

		if player and player.is_on_floor():
			# 每 60 帧跳一次（保证经过坑/敌人时能跳过）
			if _frame % 90 == 0:
				Input.action_press("jump")
				await create_timer(0.25).timeout
				Input.action_release("jump")

		await physics_frame

		# 到截图时间点
		var entry: Dictionary = screenshots[idx]
		if _frame >= int(entry["at_frame"]):
			# 等一帧 render 再截
			await process_frame
			await process_frame
			var img: Image = root.get_viewport().get_texture().get_image()
			var path: String = "user://screenshots/" + String(entry["name"]) + ".png"
			DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("user://screenshots"))
			var save_err := img.save_png(path)
			print("[shot] saved: %s @ frame %d (err=%s)" % [path, _frame, save_err])
			idx += 1

	for a in ["move_right", "run", "jump"]:
		if Input.is_action_pressed(a):
			Input.action_release(a)
	print("[shot] done. captured %d screenshots" % idx)
	quit(0)
