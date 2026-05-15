extends Node2D

## 标题界面
## 显示标题 + Press SPACE to Start

@onready var label_blink: Label = null


func _ready() -> void:
	var bg := ColorRect.new()
	bg.color = Color("#000020")
	bg.size = Vector2(1280, 720)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	var title := Label.new()
	title.text = "SUPER MARIO BROS."
	title.position = Vector2(640, 200)
	title.add_theme_font_size_override("font_size", 48)
	title.add_theme_color_override("font_color", Color("#FCFCFC"))
	title.size = Vector2(1, 1)
	# 居中
	title.set_anchors_preset(Control.PRESET_TOP_LEFT)
	title.position = Vector2(360, 200)
	add_child(title)

	var sub := Label.new()
	sub.text = "World 1-1"
	sub.position = Vector2(540, 280)
	sub.add_theme_font_size_override("font_size", 32)
	sub.add_theme_color_override("font_color", Color("#FCFCFC"))
	add_child(sub)

	label_blink = Label.new()
	label_blink.text = "Press SPACE / Z / Enter to Start"
	label_blink.position = Vector2(420, 440)
	label_blink.add_theme_font_size_override("font_size", 24)
	label_blink.add_theme_color_override("font_color", Color("#FFE060"))
	add_child(label_blink)

	var ctrl := Label.new()
	ctrl.text = "MOVE:  ← →   /   A D\nJUMP:  Z / SPACE  (hold for higher)\nRUN:   X / SHIFT  (hold)\nPAUSE: ESC"
	ctrl.position = Vector2(440, 540)
	ctrl.add_theme_font_size_override("font_size", 18)
	ctrl.add_theme_color_override("font_color", Color("#A0A0A0"))
	add_child(ctrl)


func _process(delta: float) -> void:
	# 闪烁
	if label_blink:
		var phase: float = fmod(Time.get_ticks_msec() / 1000.0, 1.0)
		label_blink.modulate.a = 0.3 if phase < 0.5 else 1.0


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("jump") or (event is InputEventKey and event.pressed and event.keycode == KEY_ENTER):
		get_tree().change_scene_to_file("res://scenes/main.tscn")
