extends CharacterBody2D
class_name Koopa

## Koopa Green · 被踩缩壳，再踩弹射
## States: WALK / SHELL_STATIC / SHELL_SPIN

enum KState { WALK, SHELL_STATIC, SHELL_SPIN }

const SIZE_WALK := Vector2(28, 40)
const SIZE_SHELL := Vector2(28, 28)

var _walk_speed: float = 30.0
var _shell_speed: float = 200.0
var _gravity: float = 800.0
var _max_fall: float = 600.0
var _direction: int = -1
var _state: KState = KState.WALK
var _shell_timer: int = 0
var _shell_static_max_frames: int = 300
var _score: int = 100

var _sprite: ColorRect
var _collision: CollisionShape2D


func _ready() -> void:
	collision_layer = 4
	collision_mask = 1
	add_to_group("enemy")

	_sprite = ColorRect.new()
	_sprite.color = Color("#FAC000")
	_sprite.size = SIZE_WALK
	_sprite.position = -SIZE_WALK / 2.0
	_sprite.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_sprite)

	_collision = CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = SIZE_WALK
	_collision.shape = shape
	add_child(_collision)

	var hitbox := Area2D.new()
	hitbox.name = "Hitbox"
	hitbox.collision_layer = 8
	hitbox.collision_mask = 2
	var hb_col := CollisionShape2D.new()
	var hb_shape := RectangleShape2D.new()
	hb_shape.size = SIZE_WALK
	hb_col.shape = hb_shape
	hitbox.add_child(hb_col)
	hitbox.body_entered.connect(_on_hit_player)
	add_child(hitbox)

	_load_config()


func _load_config() -> void:
	var cl := _get_cl()
	if cl:
		_walk_speed = float(cl.get_value("enemies.koopaGreen.walkSpeed", 30))
		_shell_speed = float(cl.get_value("enemies.koopaGreen.shellSpeed", 200))
		_shell_static_max_frames = int(cl.get_value("enemies.koopaGreen.shellWaitFrames", 300))
		_gravity = float(cl.get_value("physics.gravity.default", 800))
		_max_fall = float(cl.get_value("physics.maxFallSpeed", 600))
		_score = int(cl.get_value("enemies.koopaGreen.score", 100))


func _get_cl() -> Node:
	var tree := Engine.get_main_loop() as SceneTree
	if tree and tree.root.has_node("ConfigLoader"):
		return tree.root.get_node("ConfigLoader")
	return null


func _physics_process(delta: float) -> void:
	match _state:
		KState.WALK:
			velocity.x = _direction * _walk_speed
		KState.SHELL_STATIC:
			velocity.x = 0
			_shell_timer += 1
			if _shell_timer >= _shell_static_max_frames:
				_to_walk()
		KState.SHELL_SPIN:
			velocity.x = _direction * _shell_speed

	velocity.y += _gravity * delta
	if velocity.y > _max_fall:
		velocity.y = _max_fall
	move_and_slide()

	# 撞墙反向（任何状态）
	for i in range(get_slide_collision_count()):
		var col := get_slide_collision(i)
		if col == null:
			continue
		var n := col.get_normal()
		if absf(n.x) > 0.5:
			_direction *= -1
			break

	# SHELL_SPIN 状态撞到敌人 → 杀敌
	if _state == KState.SHELL_SPIN:
		_check_kill_enemies_in_path()


func _check_kill_enemies_in_path() -> void:
	var enemies := get_tree().get_nodes_in_group("enemy")
	for e in enemies:
		if e == self:
			continue
		if not is_instance_valid(e):
			continue
		var d: float = global_position.distance_to(e.global_position)
		if d < 24.0:
			if e.has_method("kill_by_shell"):
				e.kill_by_shell()


func _on_hit_player(body: Node) -> void:
	if not body.has_method("take_damage"):
		return
	var player_y: float = body.global_position.y
	match _state:
		KState.WALK:
			if player_y < global_position.y - 4:
				_to_shell_static()
				if body.has_method("on_stomp_enemy"):
					body.on_stomp_enemy()
				GameManager.add_score(_score)
			else:
				body.take_damage()
		KState.SHELL_STATIC:
			# 玩家踢壳
			if player_y < global_position.y - 4:
				# 踩到壳 → 也算踢
				_kick_shell(1)  # 默认右
				if body.has_method("on_stomp_enemy"):
					body.on_stomp_enemy()
			else:
				# 侧面碰壳 → 踢出
				var dir: int = 1 if body.global_position.x < global_position.x else -1
				_kick_shell(dir)
		KState.SHELL_SPIN:
			# 玩家被快速壳撞 → 受击
			body.take_damage()


func _to_shell_static() -> void:
	_state = KState.SHELL_STATIC
	_shell_timer = 0
	_sprite.color = Color("#00A800")
	_sprite.size = SIZE_SHELL
	_sprite.position = -SIZE_SHELL / 2.0
	if _collision.shape is RectangleShape2D:
		(_collision.shape as RectangleShape2D).size = SIZE_SHELL
	# 同步 hitbox 大小
	var hb := get_node_or_null("Hitbox") as Area2D
	if hb:
		var hb_col := hb.get_child(0) as CollisionShape2D
		if hb_col and hb_col.shape is RectangleShape2D:
			(hb_col.shape as RectangleShape2D).size = SIZE_SHELL


func _to_walk() -> void:
	_state = KState.WALK
	_sprite.color = Color("#FAC000")
	_sprite.size = SIZE_WALK
	_sprite.position = -SIZE_WALK / 2.0
	if _collision.shape is RectangleShape2D:
		(_collision.shape as RectangleShape2D).size = SIZE_WALK


func _kick_shell(dir: int) -> void:
	_state = KState.SHELL_SPIN
	_direction = dir


func kill_by_shell() -> void:
	GameManager.add_score(_score)
	queue_free()
