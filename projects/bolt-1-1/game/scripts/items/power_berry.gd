extends CharacterBody2D
class_name PowerBerry

## PowerBerry · 红色发光浆果（原 SuperMushroom）
## 水平移动，碰墙反向，被玩家拾取 → small → big

const _SpriteHelper = preload("res://scripts/sprite_helper.gd")

const SIZE := Vector2(28, 28)

var _walk_speed: float = 60.0
var _gravity: float = 800.0
var _direction: int = 1
var _emerging: bool = true
var _emerge_t: float = 0.0
const EMERGE_DURATION: float = 0.4

var _sprite: Node


func _ready() -> void:
	collision_layer = 16
	collision_mask = 1
	add_to_group("item")

	# M6 BL-017：真实 sprite + fallback
	_sprite = _SpriteHelper.create_sprite(
		"res://assets/power_berry.png", SIZE,
		Color("#C42040"), "Sprite"
	)
	add_child(_sprite)

	var col := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = SIZE
	col.shape = shape
	add_child(col)

	var pickup := Area2D.new()
	pickup.collision_layer = 32
	pickup.collision_mask = 2
	var p_col := CollisionShape2D.new()
	var p_shape := RectangleShape2D.new()
	p_shape.size = SIZE
	p_col.shape = p_shape
	pickup.add_child(p_col)
	pickup.body_entered.connect(_on_picked_up)
	add_child(pickup)

	var cl := _get_cl()
	if cl:
		_walk_speed = float(cl.get_value("items.powerBerry.walkSpeed", 60))
		_gravity = float(cl.get_value("physics.gravity.default", 800))


func _get_cl() -> Node:
	var tree := Engine.get_main_loop() as SceneTree
	if tree and tree.root.has_node("ConfigLoader"):
		return tree.root.get_node("ConfigLoader")
	return null


func _physics_process(delta: float) -> void:
	if _emerging:
		_emerge_t += delta
		position.y -= 32 * delta / EMERGE_DURATION
		if _emerge_t >= EMERGE_DURATION:
			_emerging = false
		return
	velocity.x = _direction * _walk_speed
	velocity.y += _gravity * delta
	move_and_slide()
	for i in range(get_slide_collision_count()):
		var col := get_slide_collision(i)
		if col == null:
			continue
		var n := col.get_normal()
		if absf(n.x) > 0.5:
			_direction *= -1
			break


func _on_picked_up(body: Node) -> void:
	if _emerging:
		return
	if body.has_method("transform_to") and "current_state" in body:
		if body.current_state == 0:  # State.SMALL
			body.transform_to(1)  # State.BIG
	GameManager.add_score(1000)
	queue_free()
