extends Node2D
class_name LevelLoader

## LevelLoader · 读取 data/levels/<id>.json 程序化生成关卡
## 包含：地面 / 砖块 / Cache Box / Conduit / Mossroll / Shellpod / 道具 / Signal Tower / Outpost

const TILE_SIZE: int = 32

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
		_make_static_box(ground_root, Vector2(x + w / 2.0, y + h / 2.0), Vector2(w, h), COLOR_GROUND_BODY, "GroundSeg")


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
	var node := preload("res://scripts/enemies/mossroll.gd").new()
	node.position = Vector2(float(e.x), float(e.y))
	enemies_root.add_child(node)


func _spawn_shellpod(e: Dictionary) -> void:
	var node := preload("res://scripts/enemies/shellpod.gd").new()
	node.position = Vector2(float(e.x), float(e.y))
	enemies_root.add_child(node)


func _spawn_cache_box(e: Dictionary) -> void:
	var node := preload("res://scripts/blocks/cache_box.gd").new()
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
	var node := preload("res://scripts/blocks/brick.gd").new()
	node.position = Vector2(float(e.x), float(e.y))
	node.hidden_oneup = bool(e.get("hidden_oneup", false))
	blocks_root.add_child(node)


func _spawn_conduit(e: Dictionary) -> void:
	var length_str: String = String(e.get("length", "short"))
	var conduit_h: float = 64.0
	match length_str:
		"short": conduit_h = 48.0
		"medium": conduit_h = 64.0
		"long": conduit_h = 96.0
		_: conduit_h = 64.0
	var conduit_w: float = 64.0
	var x: float = float(e.x)
	var y: float = float(e.y)
	var center := Vector2(x + conduit_w / 2.0, y + conduit_h / 2.0)
	# json y 是顶部 Y，底部对齐地面 y=672（修复 BL-004 的局部应用）
	var actual_h: float = 672.0 - y
	if actual_h < 32.0:
		actual_h = 32.0
	center.y = y + actual_h / 2.0
	_make_static_box(ground_root, center, Vector2(conduit_w, actual_h), COLOR_CONDUIT, "Conduit")


func _spawn_signal_tower(e: Dictionary) -> void:
	var node := preload("res://scripts/level/signal_tower.gd").new()
	# y 强制对齐到地面（修复 BL-004 局部）
	node.position = Vector2(float(e.x), 672.0)
	triggers_root.add_child(node)


func _spawn_outpost(e: Dictionary) -> void:
	var node := preload("res://scripts/level/outpost.gd").new()
	node.position = Vector2(float(e.x), 672.0)
	triggers_root.add_child(node)


func _make_static_box(parent: Node2D, center: Vector2, size: Vector2, color: Color, label: String) -> StaticBody2D:
	var body := StaticBody2D.new()
	body.name = label
	body.position = center
	body.collision_layer = 1
	body.collision_mask = 0
	parent.add_child(body)

	var rect := ColorRect.new()
	rect.color = color
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
