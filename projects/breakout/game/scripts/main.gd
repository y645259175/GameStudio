extends Node2D

## 主场景脚本
## 整合挡板、球、砖块、HUD

@onready var paddle: CharacterBody2D = $Paddle
@onready var ball: Area2D = $Ball
@onready var level_gen: Node = $LevelGenerator
@onready var hud: CanvasLayer = $HUD
@onready var brick_container: Node2D = $BrickContainer
@onready var game_over_label: Label = $GameOverLabel
@onready var win_label: Label = $WinLabel


func _ready() -> void:
	GameManager.reset_game()
	game_over_label.visible = false
	win_label.visible = false

	# 连接信号
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
	hud.update_level(GameManager.current_level)


func _on_ball_lost() -> void:
	GameManager.lose_life()


func _on_life_lost() -> void:
	# 重新发球（球回到挡板上）
	ball.reset()


func _on_game_over() -> void:
	game_over_label.text = "GAME OVER\nScore: %d\n\nPress SPACE to restart" % GameManager.score
	game_over_label.visible = true
	ball.reset()
	set_process(false)
	set_physics_process(false)


func _on_level_cleared() -> void:
	if GameManager.is_last_level():
		# 剩余生命奖励
		var life_bonus := GameManager.lives * 50
		GameManager.add_score(life_bonus)
		win_label.text = "YOU WIN!\nScore: %d\nLife Bonus: %d\n\nPress SPACE to restart" % [GameManager.score, life_bonus]
		win_label.visible = true
		ball.reset()
		set_process(false)
		set_physics_process(false)
	else:
		GameManager.next_level()
		_start_level()


func _process(_delta: float) -> void:
	# 球与挡板碰撞检测
	if ball.is_launched and ball.direction.y > 0:
		var ball_rect := Rect2(ball.position - Vector2(8, 8), Vector2(16, 16))
		var paddle_rect := Rect2(
			paddle.position - Vector2(paddle.current_width / 2.0, 8),
			Vector2(paddle.current_width, 16)
		)
		if ball_rect.intersects(paddle_rect):
			ball.bounce_off_paddle(paddle.position, paddle.current_width)
			ball.position.y = paddle.position.y - 20

	# 球与砖块碰撞检测
	if ball.is_launched:
		for brick in get_tree().get_nodes_in_group("bricks"):
			if not is_instance_valid(brick):
				continue
			var brick_rect := Rect2(
				brick.position - Vector2(40, 12),
				Vector2(80, 24)
			)
			var ball_rect := Rect2(ball.position - Vector2(8, 8), Vector2(16, 16))
			if ball_rect.intersects(brick_rect):
				brick.hit()
				ball.bounce_off_brick()
				break


func _unhandled_input(event: InputEvent) -> void:
	# Game Over / Win 状态下按空格重新开始
	if (game_over_label.visible or win_label.visible) and event.is_action_pressed("launch_ball"):
		game_over_label.visible = false
		win_label.visible = false
		set_process(true)
		set_physics_process(true)
		GameManager.reset_game()
		_start_level()
		hud.update_all()
