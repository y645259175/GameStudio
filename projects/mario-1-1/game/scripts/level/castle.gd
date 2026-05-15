extends Node2D
class_name Castle

## 城堡 · 视觉 + 进入触发

const SIZE := Vector2(80, 80)


func _ready() -> void:
	var rect := ColorRect.new()
	rect.color = Color("#A0A0A0")
	rect.size = SIZE
	rect.position = Vector2(-SIZE.x / 2.0, -SIZE.y)
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(rect)

	# 门
	var door := ColorRect.new()
	door.color = Color("#202020")
	door.size = Vector2(20, 32)
	door.position = Vector2(-10, -32)
	door.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(door)
