extends CharacterBody2D
class_name Mossroll

## Mossroll · 长腿苔藓滚子，巡逻敌人
## 行为：恒定速度行走，碰墙反向；被踩压扁；从侧面伤害玩家

const _SpriteHelper = preload("res://scripts/sprite_helper.gd")

const SIZE := Vector2(28, 28)
const FLAT_DURATION_FRAMES: int = 30

var _walk_speed: float = 30.0
var _gravity: float = 800.0
var _max_fall: float = 600.0
var _direction: int = -1
var _is_flat: bool = false
var _flat_timer: int = 0
var _is_dead: bool = false
var _score: int = 100

var _sprite: Node
var _collision: CollisionShape2D


func _ready() -> void:
	collision_layer = 4
	collision_mask = 1
	add_to_group("enemy")

	# 升级到真实 sprite（M6 BL-013 closed），fallback 到 ColorRect 占位
	_sprite = _SpriteHelper.create_sprite(
		"res://assets/mossroll.png", SIZE,
		Color("#5C8030"), "Sprite"
	)
	add_child(_sprite)

	_collision = CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = SIZE
	_collision.shape = shape
	add_child(_collision)

	# Hitbox
	var hitbox := Area2D.new()
	hitbox.name = "Hitbox"
	hitbox.collision_layer = 8
	hitbox.collision_mask = 2
	var hb_col := CollisionShape2D.new()
	var hb_shape := RectangleShape2D.new()
	hb_shape.size = SIZE
	hb_col.shape = hb_shape
	hitbox.add_child(hb_col)
	hitbox.body_entered.connect(_on_hit_player)
	add_child(hitbox)

	_load_config()


func _load_config() -> void:
	var cl := _get_cl()
	if cl:
		# data 字段保留 mossroll 命名（json 已同步重命名）
		_walk_speed = float(cl.get_value("enemies.mossroll.walkSpeed", 30))
		_gravity = float(cl.get_value("physics.gravity.default", 800))
		_max_fall = float(cl.get_value("physics.maxFallSpeed", 600))
		_score = int(cl.get_value("enemies.mossroll.score", 100))


func _get_cl() -> Node:
	var tree := Engine.get_main_loop() as SceneTree
	if tree and tree.root.has_node("ConfigLoader"):
		return tree.root.get_node("ConfigLoader")
	return null


func _physics_process(delta: float) -> void:
	if _is_dead:
		return
	if _is_flat:
		_flat_timer += 1
		if _flat_timer >= FLAT_DURATION_FRAMES:
			queue_free()
		velocity.x = 0
		velocity.y += _gravity * delta
		move_and_slide()
		return

	velocity.x = _direction * _walk_speed
	velocity.y += _gravity * delta
	if velocity.y > _max_fall:
		velocity.y = _max_fall
	move_and_slide()

	# 碰墙反向
	for i in range(get_slide_collision_count()):
		var col := get_slide_collision(i)
		if col == null:
			continue
		var n := col.get_normal()
		if absf(n.x) > 0.5:
			_direction *= -1
			break


func _on_hit_player(body: Node) -> void:
	if _is_dead or _is_flat:
		return
	if not body.has_method("take_damage"):
		return
	# 修复 BL-001 + BL-002: stomp 判定改为"玩家正在下落 + 玩家底部接近敌人顶部"
	# - dy = 玩家底部 Y - 敌人顶部 Y；玩家在敌人正上方时 dy=0，落进去时 dy>0
	# - 允许 dy ∈ [-4, 20]：负值是"刚接触"，正值是"已落进敌人 hitbox 内"
	# - 配合 vy >= 50（明确在下落）才算 stomp，避免上升中误判
	var player_bottom: float = body.global_position.y
	var enemy_top: float = global_position.y - SIZE.y / 2.0
	var dy: float = player_bottom - enemy_top
	# stomp：玩家正在下落 + 底部已接近或刚穿过敌人顶部
	if body.velocity.y >= 50.0 and dy >= -4.0 and dy <= 20.0:
		stomp(body)
	else:
		body.take_damage()


func stomp(player: Node) -> void:
	_is_flat = true
	_flat_timer = 0
	# 压扁视觉：Sprite2D 用 scale.y / position；ColorRect fallback 用 size / position
	if _sprite is Sprite2D:
		(_sprite as Sprite2D).scale.y *= 0.5
		(_sprite as Sprite2D).position.y = SIZE.y / 4.0  # 沉到底部
	elif _sprite is ColorRect:
		(_sprite as ColorRect).size = Vector2(SIZE.x, SIZE.y / 2.0)
		(_sprite as ColorRect).position = Vector2(-SIZE.x / 2.0, 0)
	if player.has_method("on_stomp_enemy"):
		player.on_stomp_enemy()
	GameManager.add_score(_score)


func kill_by_shell() -> void:
	_is_dead = true
	GameManager.add_score(_score)
	queue_free()
