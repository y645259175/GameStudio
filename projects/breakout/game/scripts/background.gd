extends Node2D

## 程序化星空背景

var stars: Array[Dictionary] = []
var time_elapsed: float = 0.0


func _ready() -> void:
	# 生成 80 颗随机星星
	for i in 80:
		stars.append({
			"pos": Vector2(randf_range(0, 1280), randf_range(0, 720)),
			"size": randf_range(1.0, 3.0),
			"brightness": randf_range(0.3, 1.0),
			"twinkle_speed": randf_range(1.0, 4.0),
			"twinkle_offset": randf_range(0, TAU),
		})


func _process(delta: float) -> void:
	time_elapsed += delta
	queue_redraw()


func _draw() -> void:
	# 深蓝渐变背景
	var top_color := Color("#0d0d1a")
	var bottom_color := Color("#1a1a3e")
	for y in 72:
		var t := float(y) / 72.0
		var c := top_color.lerp(bottom_color, t)
		draw_rect(Rect2(0, y * 10, 1280, 10), c)

	# 星星
	for star in stars:
		var twinkle := (sin(time_elapsed * star["twinkle_speed"] + star["twinkle_offset"]) + 1.0) / 2.0
		var alpha: float = star["brightness"] * lerpf(0.3, 1.0, twinkle)
		var color := Color(1.0, 1.0, 0.95, alpha)
		var s: float = star["size"]
		draw_circle(star["pos"], s, color)
