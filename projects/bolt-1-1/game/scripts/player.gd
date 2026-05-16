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

# M6.1 动画系统
# 每个状态 4 张贴图: idle / walk1 / walk2 / jump（fire 复用 fire 单图）
var _anim_textures: Dictionary = {}    # state -> {"idle":Texture2D, "walk1":..., "walk2":..., "jump":...}
var _anim_frame_t: float = 0.0
const WALK_FRAME_DURATION: float = 0.12  # 每帧 0.12s（速度感）


var _cheat_invincible: bool = false


func _ready() -> void:
	collision_layer = 2  # player layer
	collision_mask = 1   # collide with world
	add_to_group("player")
	_load_config()
	_init_texture_sprite()
	_load_anim_textures()
	_apply_state_size()


## 在场景 ColorRect 之上额外创建一个 Sprite2D 用于贴图。
## 如果贴图不存在，留空，依赖 ColorRect 占位。
func _init_texture_sprite() -> void:
	if not ResourceLoader.exists("res://assets/bolty_small.png") and not ResourceLoader.exists("res://assets/bolty_small_idle.png"):
		return  # 没有贴图 → 用 ColorRect 占位
	_tex_sprite = Sprite2D.new()
	_tex_sprite.name = "TexSprite"
	_tex_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(_tex_sprite)
	# 占位 ColorRect 隐藏（保留作为 debug 备用）
	if sprite:
		sprite.visible = false


## 预加载所有动画帧贴图
func _load_anim_textures() -> void:
	var states := {
		State.SMALL: "small",
		State.BIG: "big",
		State.FIRE: "fire",
	}
	for state in states.keys():
		var prefix: String = states[state]
		var t: Dictionary = {}
		# 优先用 _idle/_walk1/_walk2/_jump 多帧；fallback 单图 _<state>.png
		var fallback_path := "res://assets/bolty_%s.png" % prefix
		var fallback_tex: Texture2D = null
		if ResourceLoader.exists(fallback_path):
			fallback_tex = load(fallback_path) as Texture2D
		for frame_name in ["idle", "walk1", "walk2", "jump"]:
			var p := "res://assets/bolty_%s_%s.png" % [prefix, frame_name]
			if ResourceLoader.exists(p):
				t[frame_name] = load(p) as Texture2D
			else:
				t[frame_name] = fallback_tex  # 缺帧用 fallback
		_anim_textures[state] = t


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

	# iframes 倒计时（受伤后无敌帧）
	if iframes_remaining > 0:
		iframes_remaining -= 1

	_handle_horizontal(delta)
	_handle_jump(delta)
	_apply_gravity(delta)

	move_and_slide()
	_update_facing()
	_update_animation(delta)


## M6.1 动画系统：根据当前运动状态选择 idle / walk1 / walk2 / jump 帧
func _update_animation(delta: float) -> void:
	if not _tex_sprite or current_state == State.DEAD:
		return
	var state_textures: Dictionary = _anim_textures.get(current_state, {})
	if state_textures.is_empty():
		return

	var frame_name: String
	if not is_on_floor():
		# 跳跃 / 下落
		frame_name = "jump"
	elif absf(velocity.x) > 5.0:
		# 走 / 跑：交替 walk1 walk2
		_anim_frame_t += delta
		# 跑步状态下动画播得快一点
		var dur: float = WALK_FRAME_DURATION * 0.6 if absf(velocity.x) > _walk_max + 5 else WALK_FRAME_DURATION
		if fmod(_anim_frame_t, dur * 2) < dur:
			frame_name = "walk1"
		else:
			frame_name = "walk2"
	else:
		# 待机
		frame_name = "idle"
		_anim_frame_t = 0.0

	var tex: Texture2D = state_textures.get(frame_name, null)
	if tex == null:
		# 选不到帧时用 idle 兜底
		tex = state_textures.get("idle", null)
	if tex and _tex_sprite.texture != tex:
		_tex_sprite.texture = tex
		# 切贴图后重新计算 scale（贴图可能尺寸不同）
		_apply_tex_sprite_size()

	# 朝向翻转：facing_left 时镜像
	_tex_sprite.flip_h = not facing_right

	# iframes 闪烁（视觉表达 — 倒计时已在 _physics_process 处理）
	if iframes_remaining > 0:
		_tex_sprite.modulate.a = 0.5 if (iframes_remaining / 4) % 2 == 0 else 1.0
	else:
		_tex_sprite.modulate.a = 1.0


## 设置 _tex_sprite 的 scale 和 position 基于当前 state 的目标显示尺寸
## M6.2 尺寸：small=32×32, big/fire=32×56（与 _apply_state_size 一致）
func _apply_tex_sprite_size() -> void:
	if not _tex_sprite or not _tex_sprite.texture:
		return
	var target_size: Vector2
	match current_state:
		State.SMALL: target_size = Vector2(32, 32)
		State.BIG, State.FIRE: target_size = Vector2(32, 56)
		_: target_size = Vector2(32, 32)
	var src := _tex_sprite.texture.get_size()
	if src.x > 0 and src.y > 0:
		_tex_sprite.scale = Vector2(target_size.x / src.x, target_size.y / src.y)
	# 锚点：character body 中心放在 collision 中心位置，
	# 即 (0, -target_size.y/2)，让 sprite 底部对齐物体 origin（脚立地面）
	_tex_sprite.position = Vector2(0, -target_size.y / 2.0)


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
	# M6.2 角色尺寸放大：small=32×32, big/fire=32×56（约 1.75x 高），与 art-asset-pipeline SOP 对齐
	# 注意：collision shape 保持原物理尺寸（14×16, 14×30），只是视觉显示更大
	if not sprite or not collision:
		return
	match current_state:
		State.SMALL:
			sprite.color = Color("#E03030")  # Bolty 红（bolt 配色）
			sprite.size = Vector2(32, 32)
			sprite.position = Vector2(-16, -32)
			if collision.shape:
				(collision.shape as RectangleShape2D).size = Vector2(14, 28)  # 物理 hitbox 跟视觉同高一点
				collision.position = Vector2(0, -14)
		State.BIG:
			sprite.color = Color("#E03030")
			sprite.size = Vector2(32, 56)
			sprite.position = Vector2(-16, -56)
			if collision.shape:
				(collision.shape as RectangleShape2D).size = Vector2(14, 50)
				collision.position = Vector2(0, -25)
		State.FIRE:
			sprite.color = Color("#D8E0F0")
			sprite.size = Vector2(32, 56)
			sprite.position = Vector2(-16, -56)
			if collision.shape:
				(collision.shape as RectangleShape2D).size = Vector2(14, 50)
				collision.position = Vector2(0, -25)
		State.DEAD:
			sprite.color = Color("#404040")

	# 状态切换时给 _tex_sprite 设置初始贴图（idle 帧）
	if _tex_sprite:
		var state_tex: Dictionary = _anim_textures.get(current_state, {})
		var idle_tex: Texture2D = state_tex.get("idle", null)
		if idle_tex:
			_tex_sprite.texture = idle_tex
			_apply_tex_sprite_size()


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
