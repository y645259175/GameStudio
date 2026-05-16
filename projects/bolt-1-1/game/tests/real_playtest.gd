extends SceneTree

## real_playtest · 真实玩家路径测试（无 cheat）
##
## 红线（per studio/docs/autonomous-mode-charter.md 底线 2 + test-standards rule "真实玩家路径测试"）：
##   - 只能用 Input.action_press / Input.action_release 操作玩家
##   - 禁止直接修改 _player.velocity / _player.position / _player.current_state
##   - 禁止调用 _player.set_cheat_invincible 等 cheat 接口
##
## 策略：基于关卡数据 (data/levels/1-1.json) 的预知地图，做"前瞻式"输入决策。
##   1. 默认按住 right + run 推进
##   2. 前方有 pit（x_range[0]） → 提前 80px 触发 jump
##   3. 前方 60px 内有 enemy（mossroll/shellpod） → 跳起来踩
##   4. 卡住（连续 N 帧 x 不变）且在地面 → 触发 jump
##   5. 检测到 GameManager.current_state == "clear" → PASS
##   6. 检测到 "gameover" → FAIL
##
## EXIT 0 = PASS, EXIT 2 = FAIL（含超时）, EXIT 1 = setup 错误

var _player: Node = null
var _main: Node = null
var _level_loader: Node = null
var _frame: int = 0
var _last_x: float = -1.0
var _stuck_frames: int = 0

var _enemies: Array = []
var _pits: Array = []
var _level_width: float = 3200.0

var _jump_release_pending_frames: int = 0  # 控制 jump 键松开时机（实现可变跳高）


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
		push_error("[REAL] setup failed: player=%s level_loader=%s" % [_player, _level_loader])
		quit(1)
		return

	# 提前抽取关卡数据用于决策（只读，不修改）
	var level_data: Dictionary = _level_loader.level_data if _level_loader.has_method("get_level_width") else {}
	_level_width = float(level_data.get("width", 3200.0))
	var entities_arr: Array = level_data.get("entities", [])
	for e in entities_arr:
		var t: String = String(e.get("type", ""))
		if t in ["mossroll", "goomba", "shellpod", "koopaGreen"]:
			_enemies.append(e)
	var tilemap: Dictionary = level_data.get("tilemap", {})
	_pits = tilemap.get("pits", [])

	print("[REAL] start. level_width=%.0f, enemies=%d, pits=%d" % [_level_width, _enemies.size(), _pits.size()])
	print("[REAL] discipline: only Input.action_press / action_release, no velocity / position / state mutation")

	var max_frames: int = 60 * 200  # 200s
	var won: bool = false

	while _frame < max_frames:
		_frame += 1

		var x: float = _player.global_position.x
		var py: float = _player.global_position.y

		# 推进 + 跑步（持续按）
		if not Input.is_action_pressed("move_right"):
			Input.action_press("move_right")
		if not Input.is_action_pressed("run"):
			Input.action_press("run")

		# 决策：是否触发跳跃
		var should_jump: bool = false
		var hold_jump_max_frames: int = 14  # 默认中等跳

		if _player.is_on_floor():
			# 实时查询场景中的敌人 / 障碍位置（而非用初始 json）
			# extends SceneTree, self 即 SceneTree, 直接用 get_nodes_in_group
			var live_enemies := get_nodes_in_group("enemy")

			# 检测前方坑（pit 是静态的，可用 json）
			# 越接近 pit 起跳越好（水平距离不浪费），但要在能成功的范围内起跳
			# 跑步跳水平距离 ~165px，pit 64 宽，所以 60-90px 处起跳是最稳的
			for p in _pits:
				var range_arr: Array = p.get("x_range", [0, 0])
				var pit_left: float = float(range_arr[0])
				var pit_right: float = float(range_arr[1])
				var pit_w: float = pit_right - pit_left
				# 越宽的坑越早跳
				var early: float = 90.0 if pit_w < 60.0 else 80.0
				if x > pit_left - early and x < pit_left - 4.0:
					should_jump = true
					hold_jump_max_frames = 24  # 永远持满，最大跳高 + 跳远
					break

			# 检测前方近距离敌人（用实时位置）
			if not should_jump:
				for e in live_enemies:
					if not is_instance_valid(e):
						continue
					var ex: float = e.global_position.x
					var ey: float = e.global_position.y
					var dx: float = ex - x
					# 只跳"已经在前方且接近"的敌人，不要在敌人身边时跳（会撞侧面）
					# 触发距离：玩家跑步速度 150，跑步跳水平 ~180，所以前方 30-80px 是黄金踩点
					if dx > 30.0 and dx < 70.0 and absf(ey - py) < 80.0:
						should_jump = true
						hold_jump_max_frames = 12
						break

			# 卡住兜底跳（开局 1.5s 内不触发，避免 spawn falling 期被误判）
			# 只在"玩家在地面 + velocity.x 远低于跑步速度（被墙挡）"持续多帧才算真卡住
			# 阈值 30：跑步速度 150 的 20%，足够区分"被挡在墙边" vs "正常加速中"
			if _frame > 90 and absf(_player.velocity.x) < 30.0:
				_stuck_frames += 1
			else:
				_stuck_frames = 0
			_last_x = x
			if _stuck_frames > 12:
				should_jump = true
				hold_jump_max_frames = 18
				_stuck_frames = 0

			if should_jump:
				# 真实输入：按下 jump，记录持续帧数
				Input.action_press("jump")
				_jump_release_pending_frames = hold_jump_max_frames

		# 控制 jump 键松开时机（实现可变跳高）
		if _jump_release_pending_frames > 0:
			_jump_release_pending_frames -= 1
			if _jump_release_pending_frames == 0 and Input.is_action_pressed("jump"):
				Input.action_release("jump")

		await physics_frame

		if not is_instance_valid(_player):
			break

		var gm := get_root().get_node_or_null("GameManager")
		var cur_state: String = String(gm.get("current_state")) if gm else ""

		if cur_state == "clear":
			won = true
			print("[REAL] CLEARED at frame %d (%.1fs), score=%d, lives=%d" % [_frame, _frame / 60.0, gm.get("score"), gm.get("lives")])
			break
		if cur_state == "gameover":
			print("[REAL] GAME OVER at frame %d, last_x=%.1f, lives=%d" % [_frame, _last_x, gm.get("lives")])
			break

		if _frame % 60 == 0:
			print("[REAL] f=%d t=%.1fs x=%.0f y=%.0f vel=%s on_floor=%s state=%s lives=%d score=%d" % [
				_frame, _frame / 60.0, _player.global_position.x, _player.global_position.y,
				_player.velocity, _player.is_on_floor(), _player.current_state, gm.get("lives") if gm else -1, gm.get("score") if gm else -1
			])

	# 清理输入状态
	for a in ["move_right", "run", "jump"]:
		if Input.is_action_pressed(a):
			Input.action_release(a)

	if won:
		print("[REAL] PASS in %.1fs" % (_frame / 60.0))
		quit(0)
	else:
		print("[REAL] FAIL at frame %d, last_x=%.0f / level_width=%.0f (%.1f%%)" % [
			_frame, _last_x, _level_width, (_last_x / _level_width) * 100.0
		])
		quit(2)
