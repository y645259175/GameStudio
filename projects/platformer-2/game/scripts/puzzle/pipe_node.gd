extends Area2D
class_name PipeNode

## PipeNode — 管道解谜节点
## story-003-pipe-puzzle · AC-1, AC-2
## 管道可被旋转（0/90/180/270度），玩家按 interact 旋转 90 度

# --- Direction Enum ---
enum Direction { NORTH = 0, EAST = 1, SOUTH = 2, WEST = 3 }

# --- Connections (data-driven) ---
## 标记该管道在哪些方向有管道口 (true = 有口)
@export var connections: Array[bool] = [false, false, false, false]  ## [N, E, S, W]

# --- Grid Position ---
@export var grid_x: int = 0
@export var grid_y: int = 0

# --- Interact Range ---
@export var interact_range: float = 48.0  ## px, 玩家中心到此节点中心距离

# --- Rotation State ---
## 当前旋转步数 (0=0°, 1=90°, 2=180°, 3=270°)
@export var rotation_steps: int = 0

# --- Signals ---
signal rotated(pipe_node: PipeNode)


func _ready() -> void:
	# AP-10 修法 BL-P2-015：scene 设置的 rotation_steps 必须同步到 rotation_degrees
	rotation_degrees = rotation_steps * 90.0
	# 确保有 CollisionShape2D 子节点用于 Area2D 检测
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


# --- 当前有效连接方向（考虑旋转后） ---
func get_active_connections() -> Array[bool]:
	var result: Array[bool] = [false, false, false, false]
	for i in range(4):
		if connections[i]:
			var rotated_index: int = (i + rotation_steps) % 4
			result[rotated_index] = true
	return result


## 检测某个方向是否有连接口（考虑旋转）
func has_connection(direction: Direction) -> bool:
	var active := get_active_connections()
	return active[direction]


## 旋转管道 90 度（顺时针）
func rotate_pipe() -> void:
	rotation_steps = (rotation_steps + 1) % 4
	rotation_degrees = rotation_steps * 90.0
	rotated.emit(self)


# --- Player Interaction ---
var _player_in_range: bool = false
var _player_ref: Node2D = null


func _on_body_entered(body: Node2D) -> void:
	if body is CharacterBody2D and body.name == "Player":
		_player_in_range = true
		_player_ref = body


func _on_body_exited(body: Node2D) -> void:
	if body is CharacterBody2D and body.name == "Player":
		_player_in_range = false
		_player_ref = null


func _unhandled_input(event: InputEvent) -> void:
	if not _player_in_range:
		return
	if event.is_action_pressed("interact"):
		# 验证距离（双保险）
		if _player_ref and _is_within_interact_range(_player_ref):
			rotate_pipe()
			get_viewport().set_input_as_handled()


func _is_within_interact_range(player: Node2D) -> bool:
	var distance := global_position.distance_to(player.global_position)
	return distance <= interact_range
