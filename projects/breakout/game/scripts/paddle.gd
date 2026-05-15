extends CharacterBody2D

## 挡板控制脚本 · 数值从 ConfigLoader 读取

@onready var collision: CollisionShape2D = $CollisionShape2D
@onready var sprite: ColorRect = $ColorRect

var current_width: float = 120.0
var _default_width: float = 120.0
var _speed: float = 500.0


func _ready() -> void:
	_default_width = float(ConfigLoader.get_value("paddle.default_width", 120))
	_speed = float(ConfigLoader.get_value("paddle.speed", 500))
	current_width = _default_width
	_update_size(_default_width)


func _physics_process(_delta: float) -> void:
	var direction := Input.get_axis("move_left", "move_right")
	velocity.x = direction * _speed
	move_and_slide()
	position.x = clampf(position.x, current_width / 2.0, 1280.0 - current_width / 2.0)


func set_width(new_width: float) -> void:
	current_width = new_width
	_update_size(new_width)


func reset_width() -> void:
	set_width(_default_width)


func get_default_width() -> float:
	return _default_width


func _update_size(w: float) -> void:
	if collision and collision.shape:
		collision.shape.size = Vector2(w, 16)
	if sprite:
		sprite.size = Vector2(w, 16)
		sprite.position = Vector2(-w / 2.0, -8.0)
