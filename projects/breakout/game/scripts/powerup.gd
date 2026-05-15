extends Area2D

## 道具掉落物 · 弱引用 ConfigLoader

const COLORS := {
	"wide_paddle": Color("#16c79a"),
	"narrow_paddle": Color("#e74c3c"),
	"speed_ball": Color("#f5a623"),
	"clear_row": Color("#3498db"),
	"extra_life": Color("#e91e63"),
}
const ICONS := {
	"wide_paddle": "宽",
	"narrow_paddle": "窄",
	"speed_ball": "快",
	"clear_row": "轰",
	"extra_life": "♥",
}

var powerup_type: String = "wide_paddle"
var _time: float = 0.0
var _origin_x: float = 0.0
var _fall_speed: float = 150.0
var _pulse_freq: float = 2.0
var _wobble_freq: float = 3.0
var _wobble_amp: float = 2.0

@onready var color_rect: ColorRect = $ColorRect
@onready var label: Label = $Label


func _get_cl() -> Node:
	var tree := Engine.get_main_loop() as SceneTree
	if tree and tree.root.has_node("ConfigLoader"):
		return tree.root.get_node("ConfigLoader")
	return null


func setup(p_type: String) -> void:
	powerup_type = p_type
	_origin_x = position.x
	var cl := _get_cl()
	if cl:
		_fall_speed = float(cl.get_value("powerup.fall_speed", 150))
		_pulse_freq = float(cl.get_value("vfx.powerup_pulse_frequency", 2.0))
		_wobble_freq = float(cl.get_value("vfx.powerup_wobble_frequency", 3.0))
		_wobble_amp = float(cl.get_value("vfx.powerup_wobble_amplitude", 2.0))
	if color_rect:
		color_rect.color = COLORS.get(p_type, Color.WHITE)
	if label:
		label.text = ICONS.get(p_type, "?")


func _physics_process(delta: float) -> void:
	_time += delta
	position.y += _fall_speed * delta
	position.x = _origin_x + sin(_time * TAU * _wobble_freq) * _wobble_amp
	modulate.a = 0.8 + 0.2 * sin(_time * TAU * _pulse_freq)
	if position.y > 740:
		queue_free()


func get_rect() -> Rect2:
	return Rect2(position - Vector2(14, 14), Vector2(28, 28))
