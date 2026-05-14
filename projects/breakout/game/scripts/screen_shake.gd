extends Camera2D

## 屏幕震动效果

var shake_amount: float = 0.0
var shake_decay: float = 5.0


func _process(delta: float) -> void:
	if shake_amount > 0.1:
		offset = Vector2(
			randf_range(-shake_amount, shake_amount),
			randf_range(-shake_amount, shake_amount)
		)
		shake_amount = lerpf(shake_amount, 0.0, shake_decay * delta)
	else:
		shake_amount = 0.0
		offset = Vector2.ZERO


func shake(amount: float = 3.0) -> void:
	shake_amount = amount
