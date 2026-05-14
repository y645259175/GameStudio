extends Line2D

## 球拖尾效果（跟随球位置画线）

const MAX_POINTS: int = 12
const TRAIL_WIDTH: float = 6.0

var ball: Node2D = null


func _ready() -> void:
	width = TRAIL_WIDTH
	default_color = Color(1.0, 1.0, 1.0, 0.4)
	# 宽度渐变：头粗尾细
	var curve := Curve.new()
	curve.add_point(Vector2(0.0, 1.0))
	curve.add_point(Vector2(1.0, 0.0))
	width_curve = curve


func _process(_delta: float) -> void:
	if ball and ball is Node2D:
		add_point(ball.global_position)
		if get_point_count() > MAX_POINTS:
			remove_point(0)
	else:
		clear_points()
