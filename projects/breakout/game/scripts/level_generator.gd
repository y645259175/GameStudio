extends Node

## 关卡生成器 · 布局数值从 ConfigLoader 读取

var brick_scene: PackedScene = preload("res://scenes/brick.tscn")
var level_data: Dictionary = {}

var _brick_width: float = 80.0
var _brick_height: float = 24.0
var _brick_gap: float = 4.0
var _start_y: float = 80.0


func _ready() -> void:
	_brick_width = float(ConfigLoader.get_value("brick.width", 80))
	_brick_height = float(ConfigLoader.get_value("brick.height", 24))
	_brick_gap = float(ConfigLoader.get_value("brick.gap", 4))
	_start_y = float(ConfigLoader.get_value("brick.start_y", 80))
	_load_level_data()


func _load_level_data() -> void:
	var file := FileAccess.open("res://data/levels.json", FileAccess.READ)
	if file:
		var json := JSON.new()
		var err := json.parse(file.get_as_text())
		if err == OK:
			level_data = json.data
		file.close()


func generate_level(level_num: int, parent: Node) -> void:
	for child in parent.get_children():
		if child.is_in_group("bricks"):
			child.queue_free()

	var level_key := str(level_num)
	if level_key not in level_data.get("levels", {}):
		push_warning("Level %s not found" % level_key)
		return

	var level := level_data["levels"][level_key] as Dictionary
	var layout: Array = level.get("layout", [])
	var brick_types: Dictionary = level_data.get("brick_types", {})

	var cols: int = 12
	if layout.size() > 0:
		cols = layout[0].size()
	var total_width := cols * _brick_width + (cols - 1) * _brick_gap
	var start_x := (1280.0 - total_width) / 2.0 + _brick_width / 2.0

	for row_idx in layout.size():
		var row: Array = layout[row_idx]
		for col_idx in row.size():
			var type_key := str(int(row[col_idx]))
			if type_key == "0":
				continue

			var brick_info: Dictionary = brick_types.get(type_key, {})
			if brick_info.is_empty():
				continue

			var brick := brick_scene.instantiate()
			var x := start_x + col_idx * (_brick_width + _brick_gap)
			var y := _start_y + row_idx * (_brick_height + _brick_gap)
			brick.position = Vector2(x, y)

			var is_indestructible: bool = brick_info.get("indestructible", false)
			var score: int = int(brick_info.get("score", 0))

			parent.add_child(brick)
			brick.add_to_group("bricks")
			brick.setup(int(row[col_idx]), score, is_indestructible)

			if not is_indestructible:
				GameManager.register_brick()

			brick.brick_destroyed.connect(_on_brick_destroyed)
			var main_node := get_tree().current_scene
			if main_node and main_node.has_method("_on_brick_destroyed_visual"):
				brick.brick_destroyed.connect(main_node._on_brick_destroyed_visual)


func _on_brick_destroyed(_pos: Vector2, _brick_color: Color, score: int, _brick_type: int) -> void:
	GameManager.destroy_brick(score)


func get_ball_speed(level_num: int) -> float:
	var level_key := str(level_num)
	var level: Dictionary = level_data.get("levels", {}).get(level_key, {})
	return float(level.get("ball_speed", 300))
