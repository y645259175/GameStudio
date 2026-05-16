extends Node2D
class_name LevelLoader

## LevelLoader · 读取 data/levels/<id>.json 程序化生成关卡
## 包含：地面 / 砖块 / Cache Box / Conduit / Mossroll / Shellpod / 道具 / Signal Tower / Outpost
##
## 注意：spawn 各类实体时用运行时 load() 而不是 const preload()，
## 避免编译期循环 preload 链：main → level_loader → 各实体 → sprite_helper
## (Godot 4.6 在 -s 模式下偶发 "Could not preload" parse error)

const TILE_SIZE: int = 32

const _MossrollScript: String = "res://scripts/enemies/mossroll.gd"
const _ShellpodScript: String = "res://scripts/enemies/shellpod.gd"
const _CacheBoxScript: String = "res://scripts/blocks/cache_box.gd"
const _BrickScript: String = "res://scripts/blocks/brick.gd"
const _SignalTowerScript: String = "res://scripts/level/signal_tower.gd"
const _OutpostScript: String = "res://scripts/level/outpost.gd"

# 占位颜色（M6 替换为真实贴图，bolt 工业风配色）
const COLOR_GROUND_TOP := Color("#9C8830")    # 干苔黄
const COLOR_GROUND_BODY := Color("#783820")   # 锈红土
const COLOR_BRICK := Color("#D87050")
const COLOR_QBLOCK_ACTIVE := Color("#FAC000")
const COLOR_QBLOCK_USED := Color("#9C5C20")
const COLOR_HARDBLOCK := Color("#BCBCBC")
const COLOR_CONDUIT := Color("#384830")        # 暗绿金属
const COLOR_CONDUIT_HIGHLIGHT := Color("#6C9050")
const COLOR_MOSSROLL := Color("#5C8030")
const COLOR_SHELLPOD_BODY := Color("#8B9090")
const COLOR_SHELLPOD_SHELL := Color("#3C9050")
const COLOR_POWERBERRY := Color("#C42040")
const COLOR_BLUECRYSTAL := Color("#3878F0")
const COLOR_SPARKBLOOM := Color("#FFFFFF")
const COLOR_COG := Color("#E8A018")
const COLOR_SIGNAL_TOWER := Color("#A0A0A8")
const COLOR_FLAG := Color("#D04030")
const COLOR_OUTPOST := Color("#A0A0A8")

@export var level_id: String = "1-1"

var level_data: Dictionary = {}
var entities_root: Node2D
var ground_root: Node2D
var enemies_root: Node2D
var items_root: Node2D
var blocks_root: Node2D
var triggers_root: Node2D


func _ready() -> void:
	entities_root = Node2D.new()
	entities_root.name = "Entities"
	add_child(entities_root)

	ground_root = Node2D.new()
	ground_root.name = "Ground"
	entities_root.add_child(ground_root)

	blocks_root = Node2D.new()
	blocks_root.name = "Blocks"
	entities_root.add_child(blocks_root)

	enemies_root = Node2D.new()
	enemies_root.name = "Enemies"
	entities_root.add_child(enemies_root)

	items_root = Node2D.new()
	items_root.name = "Items"
	entities_root.add_child(items_root)

	triggers_root = Node2D.new()
	triggers_root.name = "Triggers"
	entities_root.add_child(triggers_root)

	_load_level_data()
	_build_ground()
	_build_entities()


func _load_level_data() -> void:
	var path := "res://data/levels/%s.json" % level_id
	var f := FileAccess.open(path, FileAccess.READ)
	if not f:
		push_error("LevelLoader: %s not found" % path)
		return
	var json := JSON.new()
	var err := json.parse(f.get_as_text())
	f.close()
	if err == OK:
		level_data = json.data
	else:
		push_error("LevelLoader: parse error %s" % path)


func get_spawn_position() -> Vector2:
	if level_data.has("spawn"):
		var s = level_data["spawn"]
		return Vector2(float(s.get("x", 64)), float(s.get("y", 528)))
	return Vector2(64, 528)


func get_level_width() -> float:
	return float(level_data.get("width", 3200))


func get_death_y() -> float:
	return float(level_data.get("death_y", 740))


func _build_ground() -> void:
	var tilemap = level_data.get("tilemap", {})
	var grounds: Array = tilemap.get("ground", [])
	for g in grounds:
		var x: float = float(g.get("x", 0))
		var y: float = float(g.get("y", 672))
		var w: float = float(g.get("w", 32))
		var h: float = 64
		# 地面分两段：顶部 32px 用 ground_top（苔黄草），下方 32px 用 ground_body（锈红土）
		var center := Vector2(x + w / 2.0, y + h / 2.0)
		_make_static_box_textured(
			ground_root, center, Vector2(w, h),
			"res://assets/ground_top.png", "res://assets/ground_body.png",
			COLOR_GROUND_BODY, "GroundSeg"
		)


func _build_entities() -> void:
	var entities: Array = level_data.get("entities", [])
	for e in entities:
		# 兼容旧 type 名（mario 命名）和新 type 名（bolt 命名）
		var t: String = String(e.get("type", ""))
		match t:
			"mossroll", "goomba":
				_spawn_mossroll(e)
			"shellpod", "koopaGreen":
				_spawn_shellpod(e)
			"cacheBox", "questionBlock":
				_spawn_cache_box(e)
			"brick":
				_spawn_brick(e)
			"conduit", "pipe":
				_spawn_conduit(e)
			"signalTower", "flagpole":
				_spawn_signal_tower(e)
			"outpost", "castle":
				_spawn_outpost(e)
			"movingPlatform":
				# Phase 2 TODO
				pass
			_:
				push_warning("Unknown entity type: %s" % t)


func _spawn_mossroll(e: Dictionary) -> void:
	var node = (load(_MossrollScript) as GDScript).new()
	node.position = Vector2(float(e.x), float(e.y))
	enemies_root.add_child(node)


func _spawn_shellpod(e: Dictionary) -> void:
	var node = (load(_ShellpodScript) as GDScript).new()
	node.position = Vector2(float(e.x), float(e.y))
	enemies_root.add_child(node)


func _spawn_cache_box(e: Dictionary) -> void:
	var node = (load(_CacheBoxScript) as GDScript).new()
	node.position = Vector2(float(e.x), float(e.y))
	# 兼容旧字段 contains: coin/mushroom/fireFlower/oneUp -> 新字段 cog/powerBerry/sparkBloom/blueCrystal
	var raw: String = String(e.get("contains", "cog"))
	var mapped: String = raw
	match raw:
		"coin": mapped = "cog"
		"mushroom": mapped = "powerBerry"
		"fireFlower": mapped = "sparkBloom"
		"oneUp": mapped = "blueCrystal"
	node.contains_type = mapped
	blocks_root.add_child(node)


func _spawn_brick(e: Dictionary) -> void:
	var node = (load(_BrickScript) as GDScript).new()
	node.position = Vector2(float(e.x), float(e.y))
	node.hidden_oneup = bool(e.get("hidden_oneup", false))
	blocks_root.add_child(node)


func _spawn_conduit(e: Dictionary) -> void:
	var length_str: String = String(e.get("length", "short"))
	var conduit_h: float = 64.0
	# 优先从 ConfigLoader 读 level-elements.conduit.lengths（数据驱动，与 GDD 对齐）
	var cl := _get_cl()
	if cl:
		var key := "level-elements.conduit.lengths." + length_str
		var v = cl.get_value(key, null)
		if v != null:
			conduit_h = float(v)
		else:
			# fallback 默认值（与 GDD §3.5 一致：short=32 / medium=48 / long=64 / extraLong=80）
			match length_str:
				"short": conduit_h = 32.0
				"medium": conduit_h = 48.0
				"long": conduit_h = 64.0
				"extraLong": conduit_h = 80.0
				_: conduit_h = 48.0
	else:
		match length_str:
			"short": conduit_h = 32.0
			"medium": conduit_h = 48.0
			"long": conduit_h = 64.0
			"extraLong": conduit_h = 80.0
			_: conduit_h = 48.0
	var conduit_w: float = 64.0
	var x: float = float(e.x)
	var y: float = float(e.y)
	var center := Vector2(x + conduit_w / 2.0, y + conduit_h / 2.0)
	# json y 是顶部 Y，底部对齐地面 y=672（修复 BL-004 的局部应用）
	var actual_h: float = 672.0 - y
	if actual_h < 32.0:
		actual_h = 32.0
	# 用 conduit_h 作为参考但不强制（json 已用 y 表达高度差）
	center.y = y + actual_h / 2.0
	# M6 BL-014 + M6.1：用真实 conduit 贴图，专用渲染（顶部凸起 + 身体竖直 stretch）
	_make_conduit(ground_root, center, Vector2(conduit_w, actual_h), "Conduit")


## Conduit 专用渲染：把 conduit.png 整张拉伸到目标高度（不平铺），保留顶部凸起
## conduit.png 是 64×64 单图，包含顶部凸起 + 直筒身体
func _make_conduit(parent: Node2D, center: Vector2, size: Vector2, label: String) -> StaticBody2D:
	var body := StaticBody2D.new()
	body.name = label
	body.position = center
	body.collision_layer = 1
	body.collision_mask = 0
	parent.add_child(body)

	if ResourceLoader.exists("res://assets/conduit.png"):
		var tex := load("res://assets/conduit.png") as Texture2D
		if tex:
			# 用 Sprite2D 整张拉伸（避免平铺造成顶部凸起重复 = 断层）
			var s := Sprite2D.new()
			s.texture = tex
			s.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			var src := tex.get_size()
			if src.x > 0 and src.y > 0:
				s.scale = Vector2(size.x / src.x, size.y / src.y)
			s.position = Vector2.ZERO  # body 中心 = sprite 中心
			body.add_child(s)
		else:
			_add_fallback_rect(body, size, COLOR_CONDUIT)
	else:
		_add_fallback_rect(body, size, COLOR_CONDUIT)

	var col := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = size
	col.shape = shape
	body.add_child(col)
	return body


func _add_fallback_rect(body: StaticBody2D, size: Vector2, color: Color) -> void:
	var rect := ColorRect.new()
	rect.color = color
	rect.size = size
	rect.position = -size / 2.0
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rect.name = "_PLACEHOLDER_Sprite"
	body.add_child(rect)


func _get_cl() -> Node:
	var tree := Engine.get_main_loop() as SceneTree
	if tree and tree.root.has_node("ConfigLoader"):
		return tree.root.get_node("ConfigLoader")
	return null


func _spawn_signal_tower(e: Dictionary) -> void:
	var node = (load(_SignalTowerScript) as GDScript).new()
	# y 强制对齐到地面（修复 BL-004 局部）
	node.position = Vector2(float(e.x), 672.0)
	triggers_root.add_child(node)


func _spawn_outpost(e: Dictionary) -> void:
	var node = (load(_OutpostScript) as GDScript).new()
	node.position = Vector2(float(e.x), 672.0)
	triggers_root.add_child(node)


## M6 升级版：支持真实贴图。top_tex 用于上半段（如 ground_top），body_tex 用于下半段（ground_body）
## 如果 top_tex == ""：整个区域用 body_tex 平铺
## 如果 body_tex == ""：整个区域用 top_tex 平铺
## 找不到贴图 → fallback 到 fallback_color 的 ColorRect
func _make_static_box_textured(parent: Node2D, center: Vector2, size: Vector2,
		top_tex: String, body_tex: String, fallback_color: Color, label: String) -> StaticBody2D:
	var body := StaticBody2D.new()
	body.name = label
	body.position = center
	body.collision_layer = 1
	body.collision_mask = 0
	parent.add_child(body)

	var top_loaded: bool = top_tex != "" and ResourceLoader.exists(top_tex)
	var body_loaded: bool = body_tex != "" and ResourceLoader.exists(body_tex)

	if top_loaded or body_loaded:
		# 用 TextureRect tile 模式平铺
		if top_loaded and body_loaded and size.y >= 64.0:
			# 双层：上 32px 用 top，下面用 body
			var top_h: float = 32.0
			var top_rect := TextureRect.new()
			top_rect.texture = load(top_tex) as Texture2D
			top_rect.stretch_mode = TextureRect.STRETCH_TILE
			top_rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			top_rect.size = Vector2(size.x, top_h)
			top_rect.position = -size / 2.0
			top_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
			top_rect.name = "TopTile"
			body.add_child(top_rect)

			var body_rect := TextureRect.new()
			body_rect.texture = load(body_tex) as Texture2D
			body_rect.stretch_mode = TextureRect.STRETCH_TILE
			body_rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			body_rect.size = Vector2(size.x, size.y - top_h)
			body_rect.position = Vector2(-size.x / 2.0, -size.y / 2.0 + top_h)
			body_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
			body_rect.name = "BodyTile"
			body.add_child(body_rect)
		else:
			# 单层：用可用的那张图整片平铺
			var tex_path := top_tex if top_loaded else body_tex
			var tr := TextureRect.new()
			tr.texture = load(tex_path) as Texture2D
			tr.stretch_mode = TextureRect.STRETCH_TILE
			tr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			tr.size = size
			tr.position = -size / 2.0
			tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
			tr.name = "Tile"
			body.add_child(tr)
	else:
		# fallback：纯色块
		var rect := ColorRect.new()
		rect.color = fallback_color
		rect.size = size
		rect.position = -size / 2.0
		rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		rect.name = "_PLACEHOLDER_Sprite"
		body.add_child(rect)

	var col := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = size
	col.shape = shape
	body.add_child(col)
	return body

