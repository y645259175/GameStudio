extends Node2D

## 主场景脚本
## 整合挡板、球、砖块、HUD、特效、道具、暂停

@onready var paddle: CharacterBody2D = $Paddle
@onready var ball: Area2D = $Ball
@onready var level_gen: Node = $LevelGenerator
@onready var hud: CanvasLayer = $HUD
@onready var brick_container: Node2D = $BrickContainer
@onready var powerup_container: Node2D = $PowerupContainer
@onready var powerup_manager: Node = $PowerupManager
@onready var game_over_label: Label = $GameOverLabel
@onready var win_label: Label = $WinLabel
@onready var launch_hint: Label = $LaunchHint
@onready var pause_overlay: CanvasLayer = $PauseOverlay
@onready var camera: Camera2D = $Camera2D
@onready var ball_trail: Line2D = $BallTrail
@onready var brick_particles: Node2D = $BrickParticles

# 砖块掉率（不依赖关卡数据，简化）
const DROP_RATE_BY_TYPE := {
	1: 0.10,
	2: 0.18,
	3: 0.25,
}


func _ready() -> void:
	GameManager.reset_game()
	game_over_label.visible = false
	win_label.visible = false
	launch_hint.visible = true
	pause_overlay.visible = false

	ball_trail.ball = ball

	ball.ball_lost.connect(_on_ball_lost)
	GameManager.game_over.connect(_on_game_over)
	GameManager.life_lost.connect(_on_life_lost)
	GameManager.level_cleared.connect(_on_level_cleared)

	_start_level()


func _start_level() -> void:
	GameManager.bricks_remaining = 0
	level_gen.generate_level(GameManager.current_level, brick_container)
	ball.speed = level_gen.get_ball_speed(GameManager.current_level)
	ball.reset()
	ball_trail.clear_points()
	hud.update_level(GameManager.current_level)
	launch_hint.visible = true
	# 清掉残留道具
	for c in powerup_container.get_children():
		c.queue_free()
	powerup_manager.reset_run()
	# 重置挡板状态
	if paddle.has_method("reset_width"):
		paddle.reset_width()


func _on_ball_lost() -> void:
	GameManager.lose_life()


func _on_life_lost() -> void:
	ball.reset()
	ball_trail.clear_points()
	launch_hint.visible = true


func _on_game_over() -> void:
	game_over_label.text = "GAME OVER\nScore: %d\n\nSPACE: Restart   ESC: Menu" % GameManager.score
	game_over_label.visible = true
	launch_hint.visible = false
	ball.reset()
	ball_trail.clear_points()


func _on_level_cleared() -> void:
	if GameManager.is_last_level():
		var life_bonus := GameManager.lives * 50
		GameManager.add_score(life_bonus)
		win_label.text = "YOU WIN!\nScore: %d\nLife Bonus: %d\n\nSPACE: Replay   ESC: Menu" % [GameManager.score, life_bonus]
		win_label.visible = true
		launch_hint.visible = false
		ball.reset()
		ball_trail.clear_points()
	else:
		GameManager.next_level()
		_start_level()


func _physics_process(_delta: float) -> void:
	if get_tree().paused:
		return

	if not ball.is_launched:
		if launch_hint and not launch_hint.visible:
			launch_hint.visible = true
		# 仍要检测道具与挡板
		_check_powerup_collisions()
		return

	if launch_hint and launch_hint.visible:
		launch_hint.visible = false

	# 球与挡板碰撞（只有球向下移动时才检测）
	if ball.direction.y > 0:
		if _check_paddle_collision():
			camera.shake(2.0)

	# 球与砖块碰撞
	_check_brick_collisions()

	# 道具与挡板碰撞
	_check_powerup_collisions()


func _check_paddle_collision() -> bool:
	var ball_rect := _get_ball_rect()
	var paddle_rect := Rect2(
		paddle.position - Vector2(paddle.current_width / 2.0, 8),
		Vector2(paddle.current_width, 16)
	)
	if ball_rect.intersects(paddle_rect):
		ball.bounce_off_paddle(paddle.position, paddle.current_width)
		ball.position.y = paddle.position.y - 20
		return true
	return false


func _check_brick_collisions() -> void:
	var ball_rect := _get_ball_rect()
	for brick in get_tree().get_nodes_in_group("bricks"):
		if not is_instance_valid(brick):
			continue
		var brick_rect := Rect2(
			brick.position - Vector2(40, 12),
			Vector2(80, 24)
		)
		if ball_rect.intersects(brick_rect):
			var ball_center: Vector2 = ball.position
			var brick_center: Vector2 = brick.position

			var diff: Vector2 = ball_center - brick_center
			var overlap_x: float = 48.0 - absf(diff.x)
			var overlap_y: float = 20.0 - absf(diff.y)

			if overlap_x < overlap_y:
				ball.direction.x = -ball.direction.x
				if diff.x > 0:
					ball.position.x = brick.position.x + 40.0 + 8.0
				else:
					ball.position.x = brick.position.x - 40.0 - 8.0
			else:
				ball.direction.y = -ball.direction.y
				if diff.y > 0:
					ball.position.y = brick.position.y + 12.0 + 8.0
				else:
					ball.position.y = brick.position.y - 12.0 - 8.0

			brick.hit()
			camera.shake(3.0)
			break


func _check_powerup_collisions() -> void:
	var paddle_rect := Rect2(
		paddle.position - Vector2(paddle.current_width / 2.0, 8),
		Vector2(paddle.current_width, 16)
	)
	for p in powerup_container.get_children():
		if not is_instance_valid(p):
			continue
		if p.has_method("get_rect"):
			var pr: Rect2 = p.get_rect()
			if pr.intersects(paddle_rect):
				var p_type: String = p.powerup_type if "powerup_type" in p else "wide_paddle"
				powerup_manager.apply(p_type, paddle, ball, self)
				p.queue_free()


func _get_ball_rect() -> Rect2:
	return Rect2(ball.position - Vector2(8, 8), Vector2(16, 16))


# 砖块销毁视觉回调（粒子 + 道具掉落判定）
func _on_brick_destroyed_visual(pos: Vector2, brick_color: Color, _score: int, brick_type: int) -> void:
	brick_particles.spawn(pos, brick_color)
	# 道具掉落判定
	var rate: float = float(DROP_RATE_BY_TYPE.get(brick_type, 0.10))
	if powerup_manager.should_drop(rate):
		powerup_manager.spawn_at(pos, powerup_container)


# 道具效果：清除随机一行砖块
func powerup_clear_row() -> void:
	var bricks := get_tree().get_nodes_in_group("bricks")
	if bricks.is_empty():
		return
	# 收集行（按 y 分组），跳过不可破坏
	var rows: Dictionary = {}
	for b in bricks:
		if not is_instance_valid(b):
			continue
		if "indestructible" in b and b.indestructible:
			continue
		var y_key := int(b.position.y)
		if not rows.has(y_key):
			rows[y_key] = []
		(rows[y_key] as Array).append(b)
	if rows.is_empty():
		return
	var keys = rows.keys()
	var picked_y = keys[randi() % keys.size()]
	for b in rows[picked_y]:
		if is_instance_valid(b) and b.has_method("hit"):
			b.hit()
	camera.shake(8.0)


func _unhandled_input(event: InputEvent) -> void:
	# Game Over / Win 状态：SPACE 重启 / ESC 回主菜单
	if game_over_label.visible or win_label.visible:
		if event.is_action_pressed("launch_ball"):
			game_over_label.visible = false
			win_label.visible = false
			GameManager.reset_game()
			_start_level()
			hud.update_all()
		elif event.is_action_pressed("ui_cancel"):
			get_tree().paused = false
			get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
		return
	# 正常游戏中：ESC 切换暂停
	if event.is_action_pressed("ui_cancel"):
		_toggle_pause()


func _toggle_pause() -> void:
	get_tree().paused = not get_tree().paused
	pause_overlay.visible = get_tree().paused
