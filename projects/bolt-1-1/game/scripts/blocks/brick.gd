extends StaticBody2D
class_name Brick

## Brick · 普通砖块
## 小态顶 → 颠动；大态/火力顶 → 碎裂
## hidden_oneup=true → 顶撞后产出 1UP 蘑菇

const SIZE := Vector2(32, 32)

var hidden_oneup: bool = false
var _used: bool = false
var _bumping: bool = false
var _bump_timer: float = 0.0
const BUMP_DURATION: float = 0.2
const BUMP_AMP: float = 6.0
var _origin_y: float = 0.0

var _sprite: ColorRect


func _ready() -> void:
	collision_layer = 1
	collision_mask = 0
	_sprite = ColorRect.new()
	_sprite.color = Color("#D87050") if not hidden_oneup else Color("#5C94FC")
	# 隐藏砖块用天蓝色（与背景同），玩家看不见
	if hidden_oneup:
		_sprite.color = Color(0.361, 0.580, 0.988, 0.0)  # 透明
	_sprite.size = SIZE
	_sprite.position = -SIZE / 2.0
	_sprite.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_sprite)

	var col := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = SIZE
	col.shape = shape
	add_child(col)

	# 触发 area（player 头顶撞）
	var trigger := Area2D.new()
	trigger.name = "BumpTrigger"
	trigger.collision_layer = 16
	trigger.collision_mask = 2
	var t_col := CollisionShape2D.new()
	var t_shape := RectangleShape2D.new()
	t_shape.size = Vector2(SIZE.x - 4, 4)
	t_col.shape = t_shape
	t_col.position = Vector2(0, SIZE.y / 2.0 + 2)  # 砖底
	trigger.add_child(t_col)
	trigger.body_entered.connect(_on_bumped)
	add_child(trigger)

	_origin_y = position.y


func _on_bumped(body: Node) -> void:
	if _used:
		return
	if not body.has_method("get") or not body.has_signal("did_bump"):
		# 简化：只要是玩家就触发
		pass
	# 必须玩家从下方上跳 - 检查玩家速度向上
	if body.has_method("get") and "velocity" in body:
		if body.velocity.y > 0:
			return  # 玩家向下 → 不算撞
	_bump()
	# 如果是隐藏 1UP，必须大态/火力态才能触发
	var is_big: bool = false
	if "current_state" in body:
		is_big = (body.current_state != 0)  # SMALL=0
	if hidden_oneup:
		_used = true
		_spawn_oneup()
		_to_used_visual()
	else:
		# 普通砖：大态砸碎
		if is_big:
			_break()
		# 小态只是颠动，不破坏


func _bump() -> void:
	_bumping = true
	_bump_timer = 0.0


func _break() -> void:
	_used = true
	GameManager.add_score(50)
	queue_free()


func _to_used_visual() -> void:
	_sprite.color = Color("#9C5C20")
	_sprite.modulate = Color(1, 1, 1, 1)


func _spawn_oneup() -> void:
	# bolt-1-1: oneup_mushroom -> blue_crystal
	var item = preload("res://scripts/items/blue_crystal.gd").new()
	item.position = position + Vector2(0, -SIZE.y)
	get_parent().add_child(item)


func _physics_process(delta: float) -> void:
	if _bumping:
		_bump_timer += delta
		var t: float = _bump_timer / BUMP_DURATION
		if t >= 1.0:
			position.y = _origin_y
			_bumping = false
		else:
			# 上下抛物线
			var offset: float = -BUMP_AMP * sin(t * PI)
			position.y = _origin_y + offset
