extends Area2D

## 道具掉落物
## GDD §4 S3 道具系统
##
## 收集逻辑由 main.gd 通过矩形相交检测，避免 collision layer 配置复杂度

const FALL_SPEED: float = 150.0
const COLORS := {
	"wide_paddle": Color("#16c79a"),
	"narrow_paddle": Color("#e74c3c"),
	"speed_ball": Color("#f5a623"),
	"multi_ball": Color("#3498db"),
	"extra_life": Color("#e91e63"),
}
const ICONS := {
	"wide_paddle": "宽",
	"narrow_paddle": "窄",
	"speed_ball": "快",
	"multi_ball": "轰",
	"extra_life": "♥",
}

var powerup_type: String = "wide_paddle"
var _time: float = 0.0
var _origin_x: float = 0.0

@onready var color_rect: ColorRect = $ColorRect
@onready var label: Label = $Label


func setup(p_type: String) -> void:
	powerup_type = p_type
	_origin_x = position.x
	if color_rect:
		color_rect.color = COLORS.get(p_type, Color.WHITE)
	if label:
		label.text = ICONS.get(p_type, "?")


func _physics_process(delta: float) -> void:
	_time += delta
	position.y += FALL_SPEED * delta
	# VFX-10: X 轴微抖（正弦 3Hz ±2px）
	position.x = _origin_x + sin(_time * TAU * 3.0) * 2.0
	# VFX-05: 透明度脉冲 0.6↔1.0（2Hz）
	modulate.a = 0.8 + 0.2 * sin(_time * TAU * 2.0)
	# 落出底部自销毁
	if position.y > 740:
		queue_free()


func get_rect() -> Rect2:
	return Rect2(position - Vector2(14, 14), Vector2(28, 28))
