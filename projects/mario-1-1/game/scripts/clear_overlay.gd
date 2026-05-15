extends CanvasLayer

## 通关 / GameOver 全屏覆盖层
## 由 main.gd 在通关 / 死亡完成时实例化


var _bg: ColorRect
var _title: Label
var _detail: Label

const TYPE_CLEAR := "clear"
const TYPE_GAMEOVER := "gameover"

@export var overlay_type: String = TYPE_CLEAR
@export var final_score: int = 0
@export var time_left: int = 0


func _ready() -> void:
	layer = 200

	_bg = ColorRect.new()
	_bg.color = Color(0, 0, 0, 0.8)
	_bg.size = Vector2(1280, 720)
	_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_bg)

	_title = Label.new()
	_title.position = Vector2(420, 240)
	_title.add_theme_font_size_override("font_size", 56)
	add_child(_title)

	_detail = Label.new()
	_detail.position = Vector2(420, 340)
	_detail.add_theme_font_size_override("font_size", 28)
	_detail.add_theme_color_override("font_color", Color("#FCFCFC"))
	add_child(_detail)

	_render()


func _render() -> void:
	if overlay_type == TYPE_CLEAR:
		_title.text = "WORLD CLEAR!"
		_title.add_theme_color_override("font_color", Color("#FFE060"))
		_detail.text = "TIME BONUS: %d × 50 = %d\n\nFINAL SCORE: %d\n\nPress ESC to quit" % [time_left, time_left * 50, final_score]
	else:
		_title.text = "GAME OVER"
		_title.add_theme_color_override("font_color", Color("#FF4040"))
		_detail.text = "FINAL SCORE: %d\n\nPress SPACE to retry, ESC to quit" % final_score


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_tree().change_scene_to_file("res://scenes/title.tscn")
	elif overlay_type == TYPE_GAMEOVER and event.is_action_pressed("jump"):
		get_tree().change_scene_to_file("res://scenes/main.tscn")
