extends Node2D

## 标题界面 · Bolt: Sector 1-1

@onready var label_blink: Label = null


func _ready() -> void:
	var bg := ColorRect.new()
	bg.color = Color("#1A1F2E")  # 工业深蓝
	bg.size = Vector2(1280, 720)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	var title := Label.new()
	title.text = "BOLT"
	title.add_theme_font_size_override("font_size", 96)
	title.add_theme_color_override("font_color", Color("#E03030"))
	title.position = Vector2(540, 160)
	add_child(title)

	var sub := Label.new()
	sub.text = "Sector 1-1"
	sub.add_theme_font_size_override("font_size", 36)
	sub.add_theme_color_override("font_color", Color("#A0A0B0"))
	sub.position = Vector2(540, 280)
	add_child(sub)

	label_blink = Label.new()
	label_blink.text = "Press SPACE / Z / Enter to Start"
	label_blink.add_theme_font_size_override("font_size", 24)
	label_blink.add_theme_color_override("font_color", Color("#FFE060"))
	label_blink.position = Vector2(420, 440)
	add_child(label_blink)

	var ctrl := Label.new()
	ctrl.text = "MOVE:  ← →   /   A D\nJUMP:  Z / SPACE  (hold for higher)\nRUN:   X / SHIFT  (hold)\nPAUSE: ESC"
	ctrl.add_theme_font_size_override("font_size", 18)
	ctrl.add_theme_color_override("font_color", Color("#80808C"))
	ctrl.position = Vector2(440, 540)
	add_child(ctrl)


func _process(_delta: float) -> void:
	if label_blink:
		var phase: float = fmod(Time.get_ticks_msec() / 1000.0, 1.0)
		label_blink.modulate.a = 0.3 if phase < 0.5 else 1.0


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("jump") or (event is InputEventKey and event.pressed and event.keycode == KEY_ENTER):
		get_tree().change_scene_to_file("res://scenes/main.tscn")
