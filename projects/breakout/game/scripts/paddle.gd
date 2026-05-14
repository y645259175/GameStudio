extends CharacterBody2D

## 挡板控制脚本
## GDD §4 S1 · §5 挡板参数 · §7 操控

const SPEED: float = 500.0
const DEFAULT_WIDTH: float = 120.0

@onready var collision: CollisionShape2D = $CollisionShape2D
@onready var sprite: ColorRect = $ColorRect

var current_width: float = DEFAULT_WIDTH


func _ready() -> void:
	_update_size(DEFAULT_WIDTH)


func _physics_process(delta: float) -> void:
	var direction := Input.get_axis("move_left", "move_right")
	velocity.x = direction * SPEED
	move_and_slide()
	# 边界限制
	position.x = clampf(position.x, current_width / 2.0, 1280.0 - current_width / 2.0)


func set_width(new_width: float) -> void:
	current_width = new_width
	_update_size(new_width)


func reset_width() -> void:
	set_width(DEFAULT_WIDTH)


func _update_size(w: float) -> void:
	if collision and collision.shape:
		collision.shape.size = Vector2(w, 16)
	if sprite:
		sprite.size = Vector2(w, 16)
		sprite.position = Vector2(-w / 2.0, -8.0)
