extends StaticBody2D

## 砖块
## GDD §4 S2 砖块系统

signal brick_destroyed(pos: Vector2, brick_type: int, score: int)

const COLORS := {
	1: Color("#0f3460"),
	2: Color("#16c79a"),
	3: Color("#f5a623"),
	-1: Color("#888888"),
}

var hp: int = 1
var brick_type: int = 1
var score_value: int = 10
var indestructible: bool = false

@onready var color_rect: ColorRect = $ColorRect


func _ready() -> void:
	_update_color()


func setup(type: int, brick_score: int, is_indestructible: bool = false) -> void:
	brick_type = type
	hp = abs(type) if not is_indestructible else 999
	score_value = brick_score
	indestructible = is_indestructible
	_update_color()


func hit() -> void:
	if indestructible:
		return
	hp -= 1
	if hp <= 0:
		brick_destroyed.emit(global_position, brick_type, score_value)
		queue_free()
	else:
		# 变色提示
		_update_color()


func _update_color() -> void:
	if color_rect:
		if indestructible:
			color_rect.color = COLORS.get(-1, Color.GRAY)
		else:
			color_rect.color = COLORS.get(hp, Color.WHITE)
