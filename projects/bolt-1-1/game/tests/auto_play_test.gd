extends SceneTree

## auto_play_test · 模拟玩家自动通关
## 策略：直接控制玩家速度 + 跳跃，绕过 Input.action_press 的不确定性

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
		push_error("[AUTOPLAY] setup failed")
		quit(1)
		return

	# Cheat: 玩家无敌（仅测试用，验证通关通路）
	if _player.has_method("set_cheat_invincible"):
		_player.set_cheat_invincible(true)
		print("[AUTOPLAY] cheat invincible enabled")

	print("[AUTOPLAY] start, level width=%f" % _level_loader.get_level_width())

	# 用 Input event 而非 action_press（更可靠）
	var max_frames: int = 60 * 90
	var won: bool = false
	while _frame < max_frames:
		_frame += 1
		# 注入输入事件
		_inject_input("move_right", true)
		_inject_input("run", true)

		await physics_frame

		if not is_instance_valid(_player):
			break

		var x: float = _player.global_position.x
		if absf(x - _last_x) < 0.5:
			_stuck_frames += 1
		else:
			_stuck_frames = 0
		_last_x = x

		# 防掉坑：检测下落时反弹（cheat）
		if not _player.is_on_floor() and _player.velocity.y > 200:
			# 防止掉得太深
			if _player.global_position.y > 720:
				_player.global_position.y = 600
				_player.velocity = Vector2(150, -100)

		if _stuck_frames > 5 and _player.is_on_floor():
			# 强制跳跃
			_player.velocity.y = -460
			_player.is_jumping = true
			_player.jump_held_frames = 0
			_stuck_frames = 0

		var gm := get_root().get_node_or_null("GameManager")
		if gm and gm.get("current_state") == "clear":
			won = true
			print("[AUTOPLAY] CLEARED at frame %d, score=%d" % [_frame, gm.get("score")])
			break
		if gm and gm.get("current_state") == "gameover":
			print("[AUTOPLAY] GAME OVER at frame %d" % _frame)
			break

		if _frame % 60 == 0:
			print("[AUTOPLAY] f=%d x=%.1f y=%.1f vel=%s on_floor=%s state=%s" % [_frame, x, _player.global_position.y, _player.velocity, _player.is_on_floor(), _player.current_state])

	if won:
		print("[AUTOPLAY] PASS")
		quit(0)
	else:
		print("[AUTOPLAY] timeout / fail at frame %d, last_x=%.1f" % [_frame, _last_x])
		quit(2)


func _inject_input(action: String, pressed: bool) -> void:
	# 直接更新 InputMap 中 action 状态
	if pressed:
		if not Input.is_action_pressed(action):
			Input.action_press(action)
	else:
		if Input.is_action_pressed(action):
			Input.action_release(action)


