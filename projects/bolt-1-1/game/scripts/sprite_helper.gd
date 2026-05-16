extends Node
# 注意：故意不用 class_name，避免 -s 启动模式下 class_name 全局注册时机问题
# （BL-010 已识别的 GDScript class_name 时序坑）
# 各调用方通过 preload("res://scripts/sprite_helper.gd").create_sprite(...) 调用

## SpriteHelper · 静态工具类，为各实体提供「从 ColorRect 占位升级到 Sprite2D 真实贴图」的统一辅助函数
##
## 设计原则：
## - 所有 sprite 在 game/assets/<name>.png 下；找不到资源 → 自动 fallback 回 ColorRect 占位（带 [VISUAL_DEBT] 标记）
## - 统一处理像素艺术正确显示（filter = Nearest，禁止反走样）
## - 节点 anchor 与原 ColorRect 一致：sprite 中心 = node origin（与碰撞 shape 对齐）
##
## 调用方式：
##   var sprite = SpriteHelper.create_sprite("res://assets/bolty_small.png", Vector2(16, 16))
##   add_child(sprite)


## 创建一个 Sprite2D 节点，加载指定贴图，按 target_size 居中缩放（保留像素清晰度）。
## - tex_path: res:// 路径
## - target_size: 实体在游戏内的像素显示尺寸（与碰撞 shape 一致）
## - fallback_color: 资源加载失败时回退的 ColorRect 颜色（保证视觉一致性即使没图）
## - sprite_name: 节点名（默认 "Sprite"，可自定义如 "_PLACEHOLDER_Sprite" 用于 backlog 追溯）
## 返回：Node2D（要么是 Sprite2D，要么是 ColorRect 包在 Node2D 里）
static func create_sprite(tex_path: String, target_size: Vector2,
                           fallback_color: Color = Color.MAGENTA,
                           sprite_name: String = "Sprite") -> Node:
	var tex: Texture2D = null
	if ResourceLoader.exists(tex_path):
		tex = load(tex_path) as Texture2D
	if tex:
		var sprite := Sprite2D.new()
		sprite.name = sprite_name
		sprite.texture = tex
		# 关键：像素艺术必须用 nearest，否则缩放后变模糊
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		# 让贴图按 target_size 显示：scale = target / source
		var src_size: Vector2 = tex.get_size()
		if src_size.x > 0 and src_size.y > 0:
			sprite.scale = Vector2(target_size.x / src_size.x, target_size.y / src_size.y)
		# Sprite2D 默认就是中心 anchor，不需要额外偏移
		return sprite
	# fallback：缺资源时画个色块，明确标记 VISUAL_DEBT
	var rect := ColorRect.new()
	rect.name = "_PLACEHOLDER_" + sprite_name
	rect.color = fallback_color
	rect.size = target_size
	rect.position = -target_size / 2.0
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return rect


## 在 Sprite2D 节点上替换贴图（用于状态切换，如 Bolty small→big→fire）
## 自动重新计算 scale 保持 target_size
static func swap_texture(sprite: Node, tex_path: String, target_size: Vector2) -> bool:
	if not sprite:
		return false
	if sprite is Sprite2D:
		var tex: Texture2D = null
		if ResourceLoader.exists(tex_path):
			tex = load(tex_path) as Texture2D
		if tex:
			(sprite as Sprite2D).texture = tex
			(sprite as Sprite2D).texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			var src_size: Vector2 = tex.get_size()
			if src_size.x > 0 and src_size.y > 0:
				(sprite as Sprite2D).scale = Vector2(target_size.x / src_size.x, target_size.y / src_size.y)
			return true
	return false


## 创建一个用于 tile-fill 的 NinePatchRect 或重复填充。供地面 / 砖块墙等需要平铺的场景。
## src_size_per_tile: 单个 tile 的源尺寸（如 32×32）
## target_total_size: 平铺后总尺寸
static func create_tiled_sprite(tex_path: String, src_size_per_tile: Vector2, target_total_size: Vector2) -> Node:
	if not ResourceLoader.exists(tex_path):
		var rect := ColorRect.new()
		rect.name = "_PLACEHOLDER_TiledFallback"
		rect.color = Color(0.5, 0.3, 0.1)  # 锈红色 fallback
		rect.size = target_total_size
		rect.position = -target_total_size / 2.0
		rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		return rect
	var tex := load(tex_path) as Texture2D
	# 用 TextureRect 的 STRETCH_TILE 模式来平铺
	var tr := TextureRect.new()
	tr.name = "TiledSprite"
	tr.texture = tex
	tr.stretch_mode = TextureRect.STRETCH_TILE
	tr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	tr.size = target_total_size
	tr.position = -target_total_size / 2.0
	tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# 自动按 src tile 尺寸平铺：TextureRect.stretch_mode = TILE 会按贴图原始尺寸平铺
	return tr
