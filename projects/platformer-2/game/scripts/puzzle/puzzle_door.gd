extends StaticBody2D
class_name PuzzleDoor

## PuzzleDoor — 解谜门
## story-003-pipe-puzzle · AC-5
## 监听 SignalNetwork 的 puzzle_solved 信号
## 收到后 set_collision_layer(0) + 可选开门动画

const SignalNetworkScript := preload("res://scripts/puzzle/signal_network.gd")

# --- Configuration (data-driven) ---
## 指向场景中的 SignalNetwork 节点
@export var signal_network_path: NodePath = NodePath("")

## 开门动画时长
@export var open_duration: float = 0.5  ## s

## 开门后是否隐藏（可选）
@export var hide_on_open: bool = false

# --- Runtime ---
var _is_open: bool = false
var _signal_network: Node = null
var _tween: Tween = null


func _ready() -> void:
	if signal_network_path != NodePath(""):
		_signal_network = get_node_or_null(signal_network_path)
		if _signal_network:
			_signal_network.puzzle_solved.connect(_on_puzzle_solved)


func _on_puzzle_solved() -> void:
	if _is_open:
		return
	open_door()


## 开门：移除碰撞 + 播放动画
func open_door() -> void:
	_is_open = true

	# 移除碰撞层，玩家可以通过
	collision_layer = 0
	collision_mask = 0

	# 可选动画：淡出 + 向上滑动
	_play_open_animation()


func _play_open_animation() -> void:
	if _tween and _tween.is_running():
		_tween.kill()

	_tween = create_tween()
	_tween.set_ease(Tween.EASE_OUT)
	_tween.set_trans(Tween.TRANS_QUAD)

	# 淡出 + 上移（占位动画，后续替换为正式美术动画）
	_tween.tween_property(self, "modulate:a", 0.0, open_duration)
	_tween.parallel().tween_property(self, "position:y", position.y - 32.0, open_duration)

	if hide_on_open:
		_tween.tween_callback(_hide_door)


func _hide_door() -> void:
	visible = false


## 允许外部重置门状态（配合网络重置）
func reset_door() -> void:
	if not _is_open:
		return
	_is_open = false
	collision_layer = 1
	collision_mask = 1
	modulate.a = 1.0
	visible = true
	# 恢复位置（如果动画移动了）
	# 注意：实际应用中建议用 _initial_position 记录
