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
	"wide_paddle": "W",
	"narrow_paddle": "N",
	"speed_ball": "S",
	"multi_ball": "M",
	"extra_life": "+",
}

var powerup_type: String = "wide_paddle"

@onready var color_rect: ColorRect = $ColorRect
@onready var label: Label = $Label


func setup(p_type: String) -> void:
	powerup_type = p_type
	if color_rect:
		color_rect.color = COLORS.get(p_type, Color.WHITE)
	if label:
		label.text = ICONS.get(p_type, "?")


func _physics_process(delta: float) -> void:
	position.y += FALL_SPEED * delta
	# 落出底部自销毁
	if position.y > 740:
		queue_free()


func get_rect() -> Rect2:
	return Rect2(position - Vector2(14, 14), Vector2(28, 28))
