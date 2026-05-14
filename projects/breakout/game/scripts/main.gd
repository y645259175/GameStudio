extends Node2D

## 主场景脚本
## 整合挡板、球、砖块、HUD、特效

@onready var paddle: CharacterBody2D = $Paddle
@onready var ball: Area2D = $Ball
@onready var level_gen: Node = $LevelGenerator
@onready var hud: CanvasLayer = $HUD
@onready var brick_container: Node2D = $BrickContainer
@onready var game_over_label: Label = $GameOverLabel
@onready var win_label: Label = $WinLabel
@onready var launch_hint: Label = $LaunchHint
@onready var camera: Camera2D = $Camera2D
@onready var ball_trail: Line2D = $BallTrail
@onready var brick_particles: Node2D = $BrickParticles


func _ready() -> void:
	GameManager.reset_game()
	game_over_label.visible = false
	win_label.visible = false
	launch_hint.visible = true

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


func _on_ball_lost() -> void:
	GameManager.lose_life()


func _on_life_lost() -> void:
	ball.reset()
	ball_trail.clear_points()
	launch_hint.visible = true


func _on_game_over() -> void:
	game_over_label.text = "GAME OVER\nScore: %d\n\nPress SPACE to restart" % GameManager.score
	game_over_label.visible = true
	launch_hint.visible = false
	ball.reset()
	ball_trail.clear_points()


func _on_level_cleared() -> void:
	if GameManager.is_last_level():
		var life_bonus := GameManager.lives * 50
		GameManager.add_score(life_bonus)
		win_label.text = "YOU WIN!\nScore: %d\nLife Bonus: %d\n\nPress SPACE to restart" % [GameManager.score, life_bonus]
		win_label.visible = true
		launch_hint.visible = false
		ball.reset()
		ball_trail.clear_points()
	else:
		GameManager.next_level()
		_start_level()


func _physics_process(delta: float) -> void:
	if not ball.is_launched:
		if launch_hint and not launch_hint.visible:
			launch_hint.visible = true
		return

	if launch_hint and launch_hint.visible:
		launch_hint.visible = false

	# 球与挡板碰撞（只有球向下移动时才检测）
	if ball.direction.y > 0:
		if _check_paddle_collision():
			camera.shake(2.0)

	# 球与砖块碰撞（检测所有砖块，每帧最多处理一个反弹）
	_check_brick_collisions()


func _check_paddle_collision() -> bool:
	var ball_rect := _get_ball_rect()
	var paddle_rect := Rect2(
		paddle.position - Vector2(paddle.current_width / 2.0, 8),
		Vector2(paddle.current_width, 16)
	)
	if ball_rect.intersects(paddle_rect):
		ball.bounce_off_paddle(paddle.position, paddle.current_width)
		# 把球推到挡板上方，防止卡在里面
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
			# 判断碰撞方向：从哪个方向进入的
			var ball_center := ball.position
			var brick_center := brick.position

			# 计算球心到砖块中心的相对位置
			var diff := ball_center - brick_center
			# 比较水平和垂直穿透深度来决定反弹方向
			var overlap_x := (40.0 + 8.0) - abs(diff.x)
			var overlap_y := (12.0 + 8.0) - abs(diff.y)

			if overlap_x < overlap_y:
				# 水平碰撞（从左或右撞入）
				ball.direction.x = -ball.direction.x
				# 推出
				if diff.x > 0:
					ball.position.x = brick.position.x + 40.0 + 8.0
				else:
					ball.position.x = brick.position.x - 40.0 - 8.0
			else:
				# 垂直碰撞（从上或下撞入）
				ball.direction.y = -ball.direction.y
				# 推出
				if diff.y > 0:
					ball.position.y = brick.position.y + 12.0 + 8.0
				else:
					ball.position.y = brick.position.y - 12.0 - 8.0

			brick.hit()
			camera.shake(3.0)
			# 每帧只处理一次反弹，防止穿透多个砖块后方向混乱
			break


func _get_ball_rect() -> Rect2:
	return Rect2(ball.position - Vector2(8, 8), Vector2(16, 16))


func _on_brick_destroyed_visual(pos: Vector2, brick_color: Color, _score: int) -> void:
	brick_particles.spawn(pos, brick_color)


func _unhandled_input(event: InputEvent) -> void:
	if (game_over_label.visible or win_label.visible) and event.is_action_pressed("launch_ball"):
		game_over_label.visible = false
		win_label.visible = false
		GameManager.reset_game()
		_start_level()
		hud.update_all()
