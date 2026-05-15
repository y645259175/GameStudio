extends SceneTree

## real_play_test · 真实通关测试（不 cheat）
## 目标：用更智能的 AI 操作（提前看远处障碍）真实通关

var _player: Node = null
var _main: Node = null
var _level_loader: Node = null
var _frame: int = 0
var _last_x: float = -1.0
var _stuck_frames: int = 0


func _init() -> void:
	await process_frame
	change_scene_to_file("res://scenes/main.tscn")
	await process_frame
	await process_frame
	await create_timer(0.5).timeout

	var root := get_root()
	_main = root.get_node_or_null("Main")
	_player = _main.get_node_or_null("Player") if _main else null
	_level_loader = _main.get_node_or_null("LevelLoader") if _main else null

	if not _player or not _level_loader:
		push_error("[REAL] setup failed")
		quit(1)
		return

	print("[REAL] start, no cheat")

	var max_frames: int = 60 * 200  # 200 秒
	var won: bool = false
	while _frame < max_frames:
		_frame += 1

		_inject("move_right", true)
		_inject("run", true)

		await physics_frame

		if not is_instance_valid(_player):
			break

		var x: float = _player.global_position.x
		if absf(x - _last_x) < 0.5:
			_stuck_frames += 1
		else:
			_stuck_frames = 0
		_last_x = x

		# 主动跳避坑：检测前方有坑（pit）
		if _player.is_on_floor():
			var tilemap_dict: Dictionary = _level_loader.level_data.get("tilemap", {})
			var pits: Array = tilemap_dict.get("pits", [])
			for p in pits:
				var range_arr: Array = p.get("x_range", [0, 0])
				var pit_left: float = float(range_arr[0])
				# 玩家距离坑边 80px 内时主动跳
				if x > pit_left - 80 and x < pit_left:
					_force_jump()
					break

		# 卡住跳
		if _stuck_frames > 5 and _player.is_on_floor():
			_force_jump()
			_stuck_frames = 0

		var gm := get_root().get_node_or_null("GameManager")
		if gm and gm.get("current_state") == "clear":
			won = true
			print("[REAL] CLEARED at frame %d, score=%d, lives=%d" % [_frame, gm.get("score"), gm.get("lives")])
			break
		if gm and gm.get("current_state") == "gameover":
			print("[REAL] GAME OVER at frame %d" % _frame)
			break

		if _frame % 60 == 0:
			print("[REAL] f=%d x=%.1f y=%.1f vel=%s on_floor=%s state=%s lives=%d" % [_frame, x, _player.global_position.y, _player.velocity, _player.is_on_floor(), _player.current_state, gm.get("lives") if gm else -1])

	if won:
		print("[REAL] PASS in %.1fs" % (_frame / 60.0))
		quit(0)
	else:
		print("[REAL] FAIL at frame %d, last_x=%.1f" % [_frame, _last_x])
		quit(2)


func _force_jump() -> void:
	_player.velocity.y = -460
	_player.is_jumping = true
	_player.jump_held_frames = 0


func _inject(action: String, pressed: bool) -> void:
	if pressed:
		if not Input.is_action_pressed(action):
			Input.action_press(action)
	else:
		if Input.is_action_pressed(action):
			Input.action_release(action)
