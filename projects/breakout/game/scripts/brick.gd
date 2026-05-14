extends StaticBody2D

## 砖块（带边框 + 高光效果）
## GDD §4 S2 砖块系统

signal brick_destroyed(pos: Vector2, brick_color: Color, score: int)

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
var current_color: Color = Color.WHITE

@onready var color_rect: ColorRect = $ColorRect
@onready var highlight: ColorRect = $Highlight
@onready var border: ColorRect = $Border


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
		# 闪白反馈
		_flash_white()
		return
	hp -= 1
	if hp <= 0:
		brick_destroyed.emit(global_position, current_color, score_value)
		queue_free()
	else:
		_update_color()
		_flash_white()


func _update_color() -> void:
	if indestructible:
		current_color = COLORS.get(-1, Color.GRAY)
	else:
		current_color = COLORS.get(hp, Color.WHITE)

	if color_rect:
		color_rect.color = current_color
	if highlight:
		highlight.color = current_color.lightened(0.3)
		highlight.color.a = 0.5
	if border:
		border.color = current_color.darkened(0.4)


func _flash_white() -> void:
	if color_rect:
		var original := color_rect.color
		color_rect.color = Color.WHITE
		var tween := create_tween()
		tween.tween_property(color_rect, "color", original, 0.15)
