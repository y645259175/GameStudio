extends Node2D

## 砖块碎裂粒子效果
## 调用 spawn(position, color) 在砖块消灭位置生成碎片

func spawn(pos: Vector2, brick_color: Color) -> void:
	# 生成 6 个碎片
	for i in 6:
		var piece := ColorRect.new()
		piece.size = Vector2(randf_range(4, 10), randf_range(4, 10))
		piece.color = brick_color.lightened(randf_range(0.0, 0.3))
		piece.position = pos - piece.size / 2.0
		add_child(piece)

		# 动画：飞散 + 淡出
		var tween := create_tween()
		var target_pos := pos + Vector2(
			randf_range(-80, 80),
			randf_range(-60, 40)
		)
		tween.set_parallel(true)
		tween.tween_property(piece, "position", target_pos, 0.5).set_ease(Tween.EASE_OUT)
		tween.tween_property(piece, "modulate:a", 0.0, 0.5).set_ease(Tween.EASE_IN)
		tween.tween_property(piece, "rotation", randf_range(-3.0, 3.0), 0.5)
		tween.chain().tween_callback(piece.queue_free)
