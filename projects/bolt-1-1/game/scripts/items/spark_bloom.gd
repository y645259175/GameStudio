extends CharacterBody2D
class_name SparkBloom

## SparkBloom · 白蓝电花（原 FireFlower）
## 原地不动，被拾取 → 任意态 → 火力态

const SIZE := Vector2(28, 28)

var _gravity: float = 800.0
var _emerging: bool = true
var _emerge_t: float = 0.0
const EMERGE_DURATION: float = 0.4

var _sprite: ColorRect


func _ready() -> void:
	collision_layer = 16
	collision_mask = 1
	add_to_group("item")

	_sprite = ColorRect.new()
	_sprite.color = Color("#FFFFFF")  # 白色花瓣（电弧由 sprite 表现）
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
	velocity.x = 0
	velocity.y += _gravity * delta
	move_and_slide()


func _on_picked_up(body: Node) -> void:
	if _emerging:
		return
	if body.has_method("transform_to"):
		body.transform_to(2)  # State.FIRE
	GameManager.add_score(1000)
	queue_free()
