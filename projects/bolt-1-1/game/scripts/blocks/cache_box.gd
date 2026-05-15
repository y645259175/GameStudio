extends StaticBody2D
class_name CacheBox

## CacheBox · 原 ?-block，金黄金属箱体，正面 ? 字符闪烁
## 顶撞后产出对应物品（cog / power_berry / spark_bloom / blue_crystal / pulse_core）

const SIZE := Vector2(32, 32)

var contains_type: String = "cog"  # cog / powerBerry / sparkBloom / blueCrystal / pulseCore
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
	_sprite.name = "_PLACEHOLDER_Sprite"
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
		"cog":
			GameManager.add_coin()
			_spawn_cog_anim()
		"powerBerry":
			# 大态/火力态 → 出 spark_bloom（保留原作"已大态时出火花"机制）
			var is_big: bool = false
			if "current_state" in player:
				is_big = (player.current_state != 0)
			if is_big:
				_spawn_item("res://scripts/items/spark_bloom.gd", spawn_pos)
			else:
				_spawn_item("res://scripts/items/power_berry.gd", spawn_pos)
		"sparkBloom":
			_spawn_item("res://scripts/items/spark_bloom.gd", spawn_pos)
		"blueCrystal":
			_spawn_item("res://scripts/items/blue_crystal.gd", spawn_pos)
		"pulseCore":
			# Phase 2 TODO（无敌道具暂不实现）
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


func _spawn_cog_anim() -> void:
	var coin := ColorRect.new()
	coin.color = Color("#E8A018")  # 黄铜齿轮色
	coin.size = Vector2(8, 12)
	coin.position = Vector2(-4, -SIZE.y - 4)
	coin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	coin.name = "_PLACEHOLDER_CogAnim"
	add_child(coin)
	var tween := create_tween()
	tween.tween_property(coin, "position:y", -SIZE.y - 28, 0.3)
	tween.tween_callback(coin.queue_free)
