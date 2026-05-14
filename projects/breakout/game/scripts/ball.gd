extends Area2D

## 球弹射与反弹
## GDD §4 S1 球物理系统

signal ball_lost

const MIN_ANGLE_DEG: float = 15.0

var speed: float = 300.0
var direction: Vector2 = Vector2.ZERO
var is_launched: bool = false
var paddle: Node2D = null


func _ready() -> void:
	paddle = get_tree().get_first_node_in_group("paddle")


func _physics_process(delta: float) -> void:
	if not is_launched:
		# 粘在挡板上
		if paddle:
			position = paddle.position + Vector2(0, -20)
		if Input.is_action_just_pressed("launch_ball"):
			launch()
		return

	# 移动
	position += direction * speed * delta

	# 墙壁反弹
	if position.x <= 8:
		position.x = 8
		direction.x = abs(direction.x)
	elif position.x >= 1272:
		position.x = 1272
		direction.x = -abs(direction.x)

	if position.y <= 8:
		position.y = 8
		direction.y = abs(direction.y)

	# 落出底部
	if position.y > 740:
		ball_lost.emit()
		is_launched = false


func launch() -> void:
	# 随机角度 60°-120°（朝上）
	var angle_deg := randf_range(60.0, 120.0)
	var angle_rad := deg_to_rad(angle_deg)
	direction = Vector2(-cos(angle_rad), -sin(angle_rad)).normalized()
	is_launched = true


func bounce_off_paddle(paddle_pos: Vector2, paddle_width: float) -> void:
	# 根据撞击位置决定反射角
	var hit_pos := (position.x - paddle_pos.x) / (paddle_width / 2.0)
	hit_pos = clampf(hit_pos, -1.0, 1.0)
	# 映射到 150°（左）到 30°（右）
	var angle_deg := lerpf(150.0, 30.0, (hit_pos + 1.0) / 2.0)
	var angle_rad := deg_to_rad(angle_deg)
	direction = Vector2(cos(angle_rad), -sin(angle_rad)).normalized()
	_enforce_min_angle()


func bounce_off_brick() -> void:
	direction.y = -direction.y
	_enforce_min_angle()


func _enforce_min_angle() -> void:
	# 防卡死：水平角度 < 15° 时修正
	var angle := abs(rad_to_deg(atan2(direction.y, direction.x)))
	if angle < MIN_ANGLE_DEG or angle > (180.0 - MIN_ANGLE_DEG):
		var sign_y := signf(direction.y)
		if sign_y == 0:
			sign_y = -1.0
		direction.y = sign_y * sin(deg_to_rad(MIN_ANGLE_DEG))
		direction = direction.normalized()


func reset() -> void:
	is_launched = false
	direction = Vector2.ZERO
