extends CharacterBody2D

## Player · Bolty 角色控制
## 实现 walk/run/jump/turnaround/可变高度跳/状态机
## 数值全部从 ConfigLoader 读取

signal did_bump

# 状态枚举
enum State { SMALL, BIG, FIRE, INVINCIBLE, DEAD }

# 数值（_ready 时从 ConfigLoader 加载）
var _walk_max: float = 90.0
var _walk_accel: float = 200.0
var _run_max: float = 150.0
var _run_accel: float = 300.0
var _turn_decel: float = 400.0
var _jump_initial_v: float = -340.0
var _jump_hold_gravity: float = 600.0
var _jump_release_gravity: float = 1500.0
var _jump_min_hold_frames: int = 4
var _jump_max_hold_frames: int = 18
var _air_accel_mult: float = 0.6
var _gravity_default: float = 800.0
var _max_fall_speed: float = 600.0
var _ground_friction: float = 0.15

# 运行时状态
var current_state: State = State.SMALL
var facing_right: bool = true
var is_jumping: bool = false
var jump_held_frames: int = 0
var iframes_remaining: int = 0

@onready var sprite: ColorRect = $Sprite
@onready var collision: CollisionShape2D = $CollisionShape2D

# M6 BL-012：真实贴图 sprite。如果资产存在，新建 Sprite2D 覆盖 ColorRect 占位。
var _tex_sprite: Sprite2D = null


var _cheat_invincible: bool = false


func _ready() -> void:
	collision_layer = 2  # player layer
	collision_mask = 1   # collide with world
	add_to_group("player")
	_load_config()
	_init_texture_sprite()
	_apply_state_size()


## 在场景 ColorRect 之上额外创建一个 Sprite2D 用于贴图。
## 如果贴图不存在，留空，依赖 ColorRect 占位。
func _init_texture_sprite() -> void:
	if not ResourceLoader.exists("res://assets/bolty_small.png"):
		return  # 没有贴图 → 用 ColorRect 占位
	_tex_sprite = Sprite2D.new()
	_tex_sprite.name = "TexSprite"
	_tex_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(_tex_sprite)
	# 占位 ColorRect 隐藏（保留作为 debug 备用）
	if sprite:
		sprite.visible = false


## DEBUG-only cheat. In release builds (OS.is_debug_build() == false) this is a no-op.
## Tests that rely on this are forbidden by test-standards red line; real_playtest must use
## Input.action_press() only. See studio/docs/autonomous-mode-charter.md discipline 2.
func set_cheat_invincible(v: bool) -> void:
	if not OS.is_debug_build():
		push_warning("[Player] set_cheat_invincible ignored in release build")
		return
	_cheat_invincible = v


func on_stomp_enemy() -> void:
	# 玩家踩敌后弹起
	velocity.y = -240.0
	is_jumping = true
	jump_held_frames = 0


func _load_config() -> void:
	var cl := _get_cl()
	if not cl:
		return
	_walk_max = float(cl.get_value("player.walk.maxSpeed", 90))
	_walk_accel = float(cl.get_value("player.walk.accel", 200))
	_run_max = float(cl.get_value("player.run.maxSpeed", 150))
	_run_accel = float(cl.get_value("player.run.accel", 300))
	_turn_decel = float(cl.get_value("player.turnAround.decel", 400))
	_jump_initial_v = float(cl.get_value("player.jump.initialV", -340))
	_jump_hold_gravity = float(cl.get_value("player.jump.holdGravity", 600))
	_jump_release_gravity = float(cl.get_value("player.jump.releaseGravity", 1500))
	_jump_min_hold_frames = int(cl.get_value("player.jump.minHoldFrames", 4))
	_jump_max_hold_frames = int(cl.get_value("player.jump.maxHoldFrames", 18))
	_air_accel_mult = float(cl.get_value("player.air.accelMultiplier", 0.6))
	_gravity_default = float(cl.get_value("physics.gravity.default", 800))
	_max_fall_speed = float(cl.get_value("physics.maxFallSpeed", 600))
	_ground_friction = float(cl.get_value("physics.friction.ground", 0.15))


func _get_cl() -> Node:
	var tree := Engine.get_main_loop() as SceneTree
	if tree and tree.root.has_node("ConfigLoader"):
		return tree.root.get_node("ConfigLoader")
	return null


func _physics_process(delta: float) -> void:
	if current_state == State.DEAD:
		return

	_handle_horizontal(delta)
	_handle_jump(delta)
	_apply_gravity(delta)

	move_and_slide()
	_update_facing()


func _handle_horizontal(delta: float) -> void:
	var dir := Input.get_axis("move_left", "move_right")
	var is_running: bool = Input.is_action_pressed("run")
	var max_speed: float = _run_max if is_running else _walk_max
	var accel: float = _run_accel if is_running else _walk_accel
	if not is_on_floor():
		accel *= _air_accel_mult

	if dir != 0.0:
		# 检测转身（当前速度方向与按键反向）
		if signf(velocity.x) != 0.0 and signf(velocity.x) != signf(dir):
			# 用 turnAround.decel 减速
			velocity.x = move_toward(velocity.x, 0.0, _turn_decel * delta)
		else:
			# 正常加速
			velocity.x = move_toward(velocity.x, dir * max_speed, accel * delta)
	else:
		# 无输入时摩擦
		if is_on_floor():
			velocity.x *= (1.0 - _ground_friction)
			if absf(velocity.x) < 5.0:
				velocity.x = 0.0


func _handle_jump(_delta: float) -> void:
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = _jump_initial_v
		is_jumping = true
		jump_held_frames = 0

	if is_jumping:
		jump_held_frames += 1
		if not Input.is_action_pressed("jump") and jump_held_frames >= _jump_min_hold_frames:
			# 提前松开，切换到高重力
			is_jumping = false
		elif jump_held_frames >= _jump_max_hold_frames:
			# 到达最大持跳帧数
			is_jumping = false


func _apply_gravity(delta: float) -> void:
	var g: float = _jump_hold_gravity if (is_jumping and velocity.y < 0.0) else _gravity_default
	if velocity.y < 0.0 and not is_jumping:
		g = _jump_release_gravity
	velocity.y += g * delta
	if velocity.y > _max_fall_speed:
		velocity.y = _max_fall_speed
	# 落地后重置 is_jumping
	if is_on_floor() and velocity.y >= 0.0:
		is_jumping = false


func _update_facing() -> void:
	if velocity.x > 1.0:
		facing_right = true
	elif velocity.x < -1.0:
		facing_right = false
	# sprite 暂未做朝向（占位 ColorRect），Sprint 3 接入精灵时处理


func _apply_state_size() -> void:
	# 占位视觉（ColorRect / [VISUAL_DEBT BL-012]，待 sprite atlas 接入后替换）
	# small=Bolty 红 16x16；big=Bolty 红+银金属饰带 16x32；fire=银白 16x32（火力态）
	if not sprite or not collision:
		return
	var target_size: Vector2 = Vector2(16, 16)
	var tex_path: String = ""
	match current_state:
		State.SMALL:
			sprite.color = Color("#E03030")  # Bolty 红（bolt 配色）
			sprite.size = Vector2(16, 16)
			sprite.position = Vector2(-8, -16)
			if collision.shape:
				(collision.shape as RectangleShape2D).size = Vector2(14, 16)
				collision.position = Vector2(0, -8)
			target_size = Vector2(16, 16)
			tex_path = "res://assets/bolty_small.png"
		State.BIG:
			sprite.color = Color("#E03030")  # 大态保持 Bolty 红（视觉差异由身高表达）
			sprite.size = Vector2(16, 32)
			sprite.position = Vector2(-8, -32)
			if collision.shape:
				(collision.shape as RectangleShape2D).size = Vector2(14, 30)
				collision.position = Vector2(0, -16)
			target_size = Vector2(16, 32)
			tex_path = "res://assets/bolty_big.png"
		State.FIRE:
			sprite.color = Color("#D8E0F0")  # 火力态：银白外壳 + 偏蓝调
			sprite.size = Vector2(16, 32)
			sprite.position = Vector2(-8, -32)
			if collision.shape:
				(collision.shape as RectangleShape2D).size = Vector2(14, 30)
				collision.position = Vector2(0, -16)
			target_size = Vector2(16, 32)
			tex_path = "res://assets/bolty_fire.png"
		State.DEAD:
			sprite.color = Color("#404040")
			# 死亡时贴图保留最后状态，不切换

	# 同步真实 sprite（如果存在）
	if _tex_sprite and tex_path != "" and ResourceLoader.exists(tex_path):
		var tex := load(tex_path) as Texture2D
		if tex:
			_tex_sprite.texture = tex
			var src := tex.get_size()
			if src.x > 0 and src.y > 0:
				_tex_sprite.scale = Vector2(target_size.x / src.x, target_size.y / src.y)
			# 锚点对齐：collision 中心在 (0, -target_size.y/2)，sprite center 也放这
			_tex_sprite.position = Vector2(0, -target_size.y / 2.0)


func transform_to(new_state: State) -> void:
	current_state = new_state
	_apply_state_size()


func take_damage() -> void:
	if iframes_remaining > 0:
		return
	if _cheat_invincible:
		return
	match current_state:
		State.FIRE:
			transform_to(State.BIG)
			iframes_remaining = 180
		State.BIG:
			transform_to(State.SMALL)
			iframes_remaining = 180
		State.SMALL:
			transform_to(State.DEAD)
			# 通知主场景触发死亡流程
			var main := get_tree().get_root().get_node_or_null("Main")
			if main and main.has_method("on_player_died"):
				main.on_player_died()
		_:
			pass
