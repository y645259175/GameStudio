extends Node2D
class_name SignalNetwork

## SignalNetwork — 管道信号网络
## story-003-pipe-puzzle · AC-3, AC-4
## 管理所有 PipeNode 子节点，BFS 检测连通路径
## 连通后 emit puzzle_solved

const PipeNodeScript := preload("res://scripts/puzzle/pipe_node.gd")

# --- Signals ---
signal puzzle_solved

# --- Configuration (data-driven) ---
## 信号源节点的 grid 坐标
@export var source_grid: Vector2i = Vector2i(0, 0)
## 目标出口节点的 grid 坐标列表（所有出口都连通 = 解谜完成）
@export var target_grids: Array[Vector2i] = []

# --- Runtime ---
var _pipe_nodes: Array = []
var _grid_map: Dictionary = {}  # Vector2i -> PipeNode
var _solved: bool = false


func _ready() -> void:
	_collect_pipe_nodes()
	_build_grid_map()
	_connect_rotation_signals()


## 收集所有 PipeNode 子节点
func _collect_pipe_nodes() -> void:
	_pipe_nodes.clear()
	for child in get_children():
		if child.get_script() == PipeNodeScript:
			_pipe_nodes.append(child)


## 建立 grid 坐标到 PipeNode 的映射
func _build_grid_map() -> void:
	_grid_map.clear()
	for pipe in _pipe_nodes:
		var key := Vector2i(pipe.grid_x, pipe.grid_y)
		_grid_map[key] = pipe


## 连接所有 PipeNode 的 rotated 信号，任何旋转都重新检测
func _connect_rotation_signals() -> void:
	for pipe in _pipe_nodes:
		if not pipe.rotated.is_connected(_on_pipe_rotated):
			pipe.rotated.connect(_on_pipe_rotated)


func _on_pipe_rotated(_pipe_node: Variant) -> void:
	_check_connectivity()


## BFS 检测连通性：从 source_grid 出发，沿连通管道口扩展
## 所有 target_grids 可达 → puzzle_solved
func _check_connectivity() -> void:
	if _solved:
		return
	if _pipe_nodes.is_empty():
		return
	if target_grids.is_empty():
		return

	# BFS
	var visited: Dictionary = {}  # Vector2i -> bool
	var queue: Array[Vector2i] = []
	queue.append(source_grid)
	visited[source_grid] = true

	# 方向偏移: N(0,-1), E(1,0), S(0,1), W(-1,0)
	var direction_offsets: Array[Vector2i] = [
		Vector2i(0, -1),  # NORTH
		Vector2i(1, 0),   # EAST
		Vector2i(0, 1),   # SOUTH
		Vector2i(-1, 0),  # WEST
	]
	# 相对方向 (对面)
	var opposite: Array[int] = [2, 3, 0, 1]  # N<->S, E<->W

	while not queue.is_empty():
		var current: Vector2i = queue.pop_front()
		var current_pipe = _grid_map.get(current, null)
		if current_pipe == null:
			continue

		var current_connections: Array[bool] = current_pipe.get_active_connections()

		for dir_index in range(4):
			if not current_connections[dir_index]:
				continue
			var neighbor_pos: Vector2i = current + direction_offsets[dir_index]
			if visited.has(neighbor_pos):
				continue
			var neighbor_pipe = _grid_map.get(neighbor_pos, null)
			if neighbor_pipe == null:
				continue
			# 邻居必须在对面方向也有连接口
			var neighbor_connections: Array[bool] = neighbor_pipe.get_active_connections()
			if not neighbor_connections[opposite[dir_index]]:
				continue
			# 连通！加入队列
			visited[neighbor_pos] = true
			queue.append(neighbor_pos)

	# 检查所有 target 是否可达
	var all_reached: bool = true
	for target in target_grids:
		if not visited.has(target):
			all_reached = false
			break

	if all_reached:
		_solved = true
		puzzle_solved.emit()


## 允许外部重置网络状态（节点 Reset 时调用）
func reset_network() -> void:
	_solved = false


## 运行时刷新节点列表（场景动态添加 PipeNode 后调用）
func refresh() -> void:
	_collect_pipe_nodes()
	_build_grid_map()
	_connect_rotation_signals()
	_solved = false
