extends CharacterBody2D
class_name Player

## Player Movement Controller — story-002-player-movement
## 5-state FSM: IDLE / RUN / JUMP / FALL / WALL_CLING

# --- State Machine (AC-4) ---
enum State { IDLE, RUN, JUMP, FALL, WALL_CLING }
var current_state: State = State.IDLE

# --- Movement (AC-1) ---
@export var move_speed: float = 300.0  ## px/s
@export var acceleration: float = 1800.0  ## px/s²
@export var deceleration: float = 2400.0  ## px/s²

# --- Jump (AC-2) ---
@export var jump_height: float = 200.0  ## px
@export var gravity: float = 980.0  ## px/s²
@export var variable_jump_cut: float = 0.4  ## 松开跳跃键时速度乘数

# --- Wall Cling (AC-3) ---
@export var wall_slide_speed: float = 50.0  ## px/s
@export var wall_cling_duration: float = 0.6  ## s

# --- Coyote & Buffer ---
@export var coyote_time: float = 0.12  ## s
@export var input_buffer_time: float = 0.12  ## s

# --- Runtime ---
var _jump_velocity: float
var _coyote_timer: float = 0.0
var _input_buffer_timer: float = 0.0
var _wall_cling_timer: float = 0.0
var _was_on_floor: bool = false


func _ready() -> void:
	_jump_velocity = -sqrt(2.0 * gravity * jump_height)
	print("[player] jump_velocity = ", _jump_velocity)


func _physics_process(delta: float) -> void:
	_update_timers(delta)
	_handle_state(delta)
	move_and_slide()


func _update_timers(delta: float) -> void:
	if is_on_floor():
		_coyote_timer = coyote_time
		_was_on_floor = true
	else:
		if _was_on_floor:
			_was_on_floor = false
		_coyote_timer = maxf(_coyote_timer - delta, 0.0)
	if Input.is_action_just_pressed("jump"):
		_input_buffer_timer = input_buffer_time
	else:
		_input_buffer_timer = maxf(_input_buffer_timer - delta, 0.0)


func _handle_state(delta: float) -> void:
	match current_state:
		State.IDLE:
			_state_idle(delta)
		State.RUN:
			_state_run(delta)
		State.JUMP:
			_state_jump(delta)
		State.FALL:
			_state_fall(delta)
		State.WALL_CLING:
			_state_wall_cling(delta)


func _state_idle(delta: float) -> void:
	_apply_gravity(delta)
	velocity.x = move_toward(velocity.x, 0.0, deceleration * delta)
	if _can_jump():
		_do_jump()
	elif not is_on_floor():
		_transition(State.FALL)
	elif _get_input_direction() != 0.0:
		_transition(State.RUN)


func _state_run(delta: float) -> void:
	_apply_gravity(delta)
	var dir := _get_input_direction()
	if dir != 0.0:
		velocity.x = move_toward(velocity.x, dir * move_speed, acceleration * delta)
	else:
		velocity.x = move_toward(velocity.x, 0.0, deceleration * delta)
		_transition(State.IDLE)
		return
	if _can_jump():
		_do_jump()
	elif not is_on_floor():
		_transition(State.FALL)


func _state_jump(delta: float) -> void:
	_apply_gravity(delta)
	_apply_horizontal_movement(delta)
	# Variable jump: release early → cut velocity
	if Input.is_action_just_released("jump") and velocity.y < 0.0:
		velocity.y *= variable_jump_cut
	if velocity.y >= 0.0:
		_transition(State.FALL)
	elif _is_on_wall_and_holding():
		_transition(State.WALL_CLING)


func _state_fall(delta: float) -> void:
	_apply_gravity(delta)
	_apply_horizontal_movement(delta)
	if is_on_floor():
		if _get_input_direction() != 0.0:
			_transition(State.RUN)
		else:
			_transition(State.IDLE)
	elif _is_on_wall_and_holding():
		_transition(State.WALL_CLING)
	elif _can_jump():
		_do_jump()


func _state_wall_cling(delta: float) -> void:
	velocity.y = wall_slide_speed
	_wall_cling_timer -= delta
	if _wall_cling_timer <= 0.0:
		_transition(State.FALL)
	elif is_on_floor():
		_transition(State.IDLE)
	elif Input.is_action_just_pressed("jump"):
		_do_jump()
	elif not is_on_wall():
		_transition(State.FALL)


# --- Helper Functions ---

func _apply_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity.y += gravity * delta


func _apply_horizontal_movement(delta: float) -> void:
	var dir := _get_input_direction()
	if dir != 0.0:
		velocity.x = move_toward(velocity.x, dir * move_speed, acceleration * delta)
	else:
		velocity.x = move_toward(velocity.x, 0.0, deceleration * delta)


func _get_input_direction() -> float:
	return Input.get_axis("move_left", "move_right")


func _can_jump() -> bool:
	return _input_buffer_timer > 0.0 and _coyote_timer > 0.0


func _do_jump() -> void:
	velocity.y = _jump_velocity
	_coyote_timer = 0.0
	_input_buffer_timer = 0.0
	_transition(State.JUMP)


func _is_on_wall_and_holding() -> bool:
	if not is_on_wall():
		return false
	var dir := _get_input_direction()
	# 检测是否朝墙壁方向按住
	var wall_normal := get_wall_normal()
	return dir != 0.0 and sign(dir) != sign(wall_normal.x)


func _transition(new_state: State) -> void:
	current_state = new_state
	match new_state:
		State.WALL_CLING:
			_wall_cling_timer = wall_cling_duration