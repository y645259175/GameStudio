extends StaticBody2D
class_name QuestionBlock

## QuestionBlock · 问号块
## 状态：active（金黄闪烁）/ used（暗棕）
## 顶撞后从 contains_type 产出对应物品

const SIZE := Vector2(32, 32)

var contains_type: String = "coin"  # coin / mushroom / fireFlower / star / oneUp
var _used: bool = false

var _sprite: ColorRect
var _flicker_t: float = 0.0


func _ready() -> void:
	collision_layer = 1
	collision_mask = 0

	_sprite = ColorRect.new()
	_sprite.color = Color("#FAC000")
	_sprite.size = SIZE
	_sprite.position = -SIZE / 2.0
	_sprite.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_sprite)

	var col := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = SIZE
	col.shape = shape
	add_child(col)

	var trigger := Area2D.new()
	trigger.name = "BumpTrigger"
	trigger.collision_layer = 16
	trigger.collision_mask = 2
	var t_col := CollisionShape2D.new()
	var t_shape := RectangleShape2D.new()
	t_shape.size = Vector2(SIZE.x - 4, 4)
	t_col.shape = t_shape
	t_col.position = Vector2(0, SIZE.y / 2.0 + 2)
	trigger.add_child(t_col)
	trigger.body_entered.connect(_on_bumped)
	add_child(trigger)


func _process(delta: float) -> void:
	if _used:
		return
	_flicker_t += delta
	# 简易闪烁：金黄 → 浅黄 0.4s 周期
	var phase: float = fmod(_flicker_t, 0.4) / 0.4
	if phase < 0.5:
		_sprite.color = Color("#FAC000")
	else:
		_sprite.color = Color("#FFE060")


func _on_bumped(body: Node) -> void:
	if _used:
		return
	if "velocity" in body and body.velocity.y > 0:
		return
	_used = true
	_sprite.color = Color("#9C5C20")
	_spawn_content(body)


func _spawn_content(player: Node) -> void:
	var spawn_pos: Vector2 = position + Vector2(0, -SIZE.y)
	match contains_type:
		"coin":
			GameManager.add_coin()
			_spawn_coin_anim()
		"mushroom":
			# 大态/火力态 → 出 fireFlower（按原作）
			var is_big: bool = false
			if "current_state" in player:
				is_big = (player.current_state != 0)
			if is_big:
				_spawn_item("res://scripts/items/fire_flower.gd", spawn_pos)
			else:
				_spawn_item("res://scripts/items/super_mushroom.gd", spawn_pos)
		"fireFlower":
			_spawn_item("res://scripts/items/fire_flower.gd", spawn_pos)
		"oneUp":
			_spawn_item("res://scripts/items/oneup_mushroom.gd", spawn_pos)
		"star":
			# 自主模式：跳过 star（无敌道具）
			GameManager.add_coin()
		_:
			GameManager.add_coin()


func _spawn_item(script_path: String, spawn_pos: Vector2) -> void:
	var script: GDScript = load(script_path) as GDScript
	if not script:
		return
	var item: Node2D = script.new()
	item.position = spawn_pos
	get_parent().add_child(item)


func _spawn_coin_anim() -> void:
	# 简易金币飘字（视觉占位）
	var coin := ColorRect.new()
	coin.color = Color("#FAC000")
	coin.size = Vector2(8, 12)
	coin.position = Vector2(-4, -SIZE.y - 4)
	coin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(coin)
	var tween := create_tween()
	tween.tween_property(coin, "position:y", -SIZE.y - 28, 0.3)
	tween.tween_callback(coin.queue_free)
