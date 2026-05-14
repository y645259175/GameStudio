extends TextureRect

## 背景贴图（用 TimiAI 生成的像素风星空图）
## 替换了之前的程序化绘制版本

func _ready() -> void:
	# 拉伸到全屏
	anchor_right = 1.0
	anchor_bottom = 1.0
	stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
