extends Area2D

## 球弹射与反弹 · 数值从 ConfigLoader 读取

signal ball_lost

var speed: float = 300.0
var direction: Vector2 = Vector2.ZERO
var is_launched: bool = false
var paddle: Node2D = null

var _min_angle_deg: float = 15.0
var _launch_angle_min: float = 60.0
var _launch_angle_max: float = 120.0


func _ready() -> void:
	paddle = get_tree().get_first_node_in_group("paddle")
	_min_angle_deg = float(ConfigLoader.get_value("ball.min_angle_deg", 15))
	_launch_angle_min = float(ConfigLoader.get_value("ball.launch_angle_min", 60))
	_launch_angle_max = float(ConfigLoader.get_value("ball.launch_angle_max", 120))


func _physics_process(delta: float) -> void:
	if not is_launched:
		if paddle:
			position = paddle.position + Vector2(0, -20)
		if Input.is_action_just_pressed("launch_ball"):
			launch()
		return

	position += direction * speed * delta

	if position.x <= 8:
		position.x = 8
		direction.x = abs(direction.x)
	elif position.x >= 1272:
		position.x = 1272
		direction.x = -abs(direction.x)

	if position.y <= 8:
		position.y = 8
		direction.y = abs(direction.y)

	if position.y > 740:
		ball_lost.emit()
		is_launched = false


func launch() -> void:
	var angle_deg := randf_range(_launch_angle_min, _launch_angle_max)
	var angle_rad := deg_to_rad(angle_deg)
	direction = Vector2(-cos(angle_rad), -sin(angle_rad)).normalized()
	is_launched = true


func bounce_off_paddle(paddle_pos: Vector2, paddle_width: float) -> void:
	var hit_pos := (position.x - paddle_pos.x) / (paddle_width / 2.0)
	hit_pos = clampf(hit_pos, -1.0, 1.0)
	var angle_deg := lerpf(150.0, 30.0, (hit_pos + 1.0) / 2.0)
	var angle_rad := deg_to_rad(angle_deg)
	direction = Vector2(cos(angle_rad), -sin(angle_rad)).normalized()
	_enforce_min_angle()


func bounce_off_brick() -> void:
	direction.y = -direction.y
	_enforce_min_angle()


func _enforce_min_angle() -> void:
	var angle: float = abs(rad_to_deg(atan2(direction.y, direction.x)))
	if angle < _min_angle_deg or angle > (180.0 - _min_angle_deg):
		var sign_y := signf(direction.y)
		if sign_y == 0:
			sign_y = -1.0
		direction.y = sign_y * sin(deg_to_rad(_min_angle_deg))
		direction = direction.normalized()


func reset() -> void:
	is_launched = false
	direction = Vector2.ZERO
