extends Node2D
class_name LevelLoader

## LevelLoader · 读取 data/levels/<id>.json 程序化生成关卡
## 包含：地面 / 砖块 / 问号块 / 管道 / 敌人 / 道具 / 旗杆 / 城堡

const TILE_SIZE: int = 32

# 颜色占位（M6 替换为真实贴图）
const COLOR_GROUND_TOP := Color("#00A800")
const COLOR_GROUND_BODY := Color("#A04000")
const COLOR_BRICK := Color("#D87050")
const COLOR_QBLOCK_ACTIVE := Color("#FAC000")
const COLOR_QBLOCK_USED := Color("#9C5C20")
const COLOR_HARDBLOCK := Color("#BCBCBC")
const COLOR_PIPE := Color("#00A800")
const COLOR_PIPE_HIGHLIGHT := Color("#80D010")
const COLOR_GOOMBA := Color("#A85820")
const COLOR_KOOPA_BODY := Color("#FAC000")
const COLOR_KOOPA_SHELL := Color("#00A800")
const COLOR_MUSHROOM := Color("#E40058")
const COLOR_ONEUP := Color("#00C800")
const COLOR_FIREFLOWER := Color("#FCFCFC")
const COLOR_COIN := Color("#FAC000")
const COLOR_FLAGPOLE := Color("#BCBCBC")
const COLOR_FLAG := Color("#FCFCFC")
const COLOR_CASTLE := Color("#A0A0A0")

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
	_build_pit_triggers()


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


func _build_pit_triggers() -> void:
	# 死亡线：玩家 Y 超过 death_y 即死
	# 在 main.gd 的 _physics_process 中检测，无需单独 trigger
	pass


func _build_entities() -> void:
	var entities: Array = level_data.get("entities", [])
	for e in entities:
		var t: String = String(e.get("type", ""))
		match t:
			"goomba":
				_spawn_goomba(e)
			"koopaGreen":
				_spawn_koopa(e)
			"questionBlock":
				_spawn_qblock(e)
			"brick":
				_spawn_brick(e)
			"pipe":
				_spawn_pipe(e)
			"flagpole":
				_spawn_flagpole(e)
			"castle":
				_spawn_castle(e)
			"movingPlatform":
				# 自主模式简化：跳过
				pass
			_:
				push_warning("Unknown entity type: %s" % t)


func _spawn_goomba(e: Dictionary) -> void:
	var node := preload("res://scripts/enemies/goomba.gd").new()
	node.position = Vector2(float(e.x), float(e.y))
	enemies_root.add_child(node)


func _spawn_koopa(e: Dictionary) -> void:
	var node := preload("res://scripts/enemies/koopa.gd").new()
	node.position = Vector2(float(e.x), float(e.y))
	enemies_root.add_child(node)


func _spawn_qblock(e: Dictionary) -> void:
	var node := preload("res://scripts/blocks/question_block.gd").new()
	node.position = Vector2(float(e.x), float(e.y))
	node.contains_type = String(e.get("contains", "coin"))
	blocks_root.add_child(node)


func _spawn_brick(e: Dictionary) -> void:
	var node := preload("res://scripts/blocks/brick.gd").new()
	node.position = Vector2(float(e.x), float(e.y))
	node.hidden_oneup = bool(e.get("hidden_oneup", false))
	blocks_root.add_child(node)


func _spawn_pipe(e: Dictionary) -> void:
	var length_str: String = String(e.get("length", "short"))
	var pipe_h: float = 64.0
	match length_str:
		"short": pipe_h = 48.0
		"medium": pipe_h = 64.0
		"long": pipe_h = 96.0
		_: pipe_h = 64.0
	var pipe_w: float = 64.0
	var x: float = float(e.x)
	var y: float = float(e.y)
	# 管道顶在 y - pipe_h/2，底在 y + pipe_h/2 ... 但 1-1.json 的 y 是 top
	# 修正：管道 y 是顶部 Y，底部到 ground=672
	var center := Vector2(x + pipe_w / 2.0, y + pipe_h / 2.0)
	# 实际把管道画到地面之上（top 在 y）
	var actual_h: float = 672.0 - y
	if actual_h < 32.0:
		actual_h = 32.0
	center.y = y + actual_h / 2.0
	_make_static_box(ground_root, center, Vector2(pipe_w, actual_h), COLOR_PIPE, "Pipe")


func _spawn_flagpole(e: Dictionary) -> void:
	var node := preload("res://scripts/level/flagpole.gd").new()
	# 旗杆 y 强制对齐到地面（json y 是 NES 比例参考值）
	node.position = Vector2(float(e.x), 672.0)
	triggers_root.add_child(node)


func _spawn_castle(e: Dictionary) -> void:
	# 城堡视觉占位 + 进入触发
	var node := preload("res://scripts/level/castle.gd").new()
	node.position = Vector2(float(e.x), 672.0)
	triggers_root.add_child(node)


# 通用：生成一个 StaticBody2D + ColorRect + CollisionShape2D
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
	body.add_child(rect)

	var col := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = size
	col.shape = shape
	body.add_child(col)
	return body
