extends SceneTree
# Test suite for story-003-pipe-puzzle (platformer-2 M1)
#
# 覆盖范围：
#   - AC-1: PipeNode 4 方向旋转状态（0/90/180/270度）
#   - AC-2: 玩家按 interact（E 键）旋转 90 度（真实输入路径）
#   - AC-3: SignalNetwork BFS/DFS 检测连通路径
#   - AC-4: 连通完成时发出 puzzle_solved 信号
#   - AC-5: PuzzleDoor 监听 puzzle_solved 后开门
#
# 真实玩家路径测试（红线）：
#   - 使用 InputEventAction 模拟玩家按 interact
#   - **禁止**仅通过直接调用 rotate_pipe() 作为唯一测试手段
#   参见：studio/docs/agents/tester.md §"真实玩家路径测试（红线）"
#
# 跑法：
#   d:\AI\GameStudio\engine\Godot\Godot_v4.6.2-stable_win64.exe ^
#     --headless --path d:\AI\GameStudio\projects\platformer-2\game ^
#     --script d:\AI\GameStudio\projects\platformer-2\qa\tests\test_pipe_puzzle.gd --quit

const TAG := "[test_pipe_puzzle]"

# --- 脚本引用（避免 class_name 全局作用域问题） ---
var PipeNodeScript: GDScript = null
var SignalNetworkScript: GDScript = null
var PuzzleDoorScript: GDScript = null

var _passed := 0
var _failed := 0
var _skipped := 0


func _init() -> void:
	# ============================================================
	#  Setup: 加载被测脚本
	# ============================================================
	PipeNodeScript = load("res://scripts/puzzle/pipe_node.gd") as GDScript
	SignalNetworkScript = load("res://scripts/puzzle/signal_network.gd") as GDScript
	PuzzleDoorScript = load("res://scripts/puzzle/puzzle_door.gd") as GDScript

	if PipeNodeScript == null or SignalNetworkScript == null or PuzzleDoorScript == null:
		push_error("%s SETUP FAIL: Could not load puzzle scripts" % TAG)
		quit(1)
		return

	# ============================================================
	#  SECTION 1: AC-1 — PipeNode 旋转状态 (Happy Path)
	# ============================================================
	_test_ac1_initial_rotation_state()
	_test_ac1_rotation_steps_cycle()
	_test_ac1_active_connections_after_rotation()
	_test_ac1_has_connection_direction()

	# ============================================================
	#  SECTION 2: AC-2 — 真实玩家输入路径测试（红线）
	# ============================================================
	_test_ac2_real_input_interact_rotates_pipe()
	_test_ac2_real_input_full_cycle_four_presses()

	# ============================================================
	#  SECTION 3: AC-3 — SignalNetwork 连通性检测
	# ============================================================
	_test_ac3_simple_connected_network()
	_test_ac3_disconnected_network()
	_test_ac3_multi_node_path()

	# ============================================================
	#  SECTION 4: AC-4 — puzzle_solved 信号发射
	# ============================================================
	_test_ac4_puzzle_solved_emitted_on_connect()
	_test_ac4_no_signal_when_incomplete()

	# ============================================================
	#  SECTION 5: AC-5 — PuzzleDoor 响应 puzzle_solved
	# ============================================================
	_test_ac5_door_opens_on_solved()
	_test_ac5_door_collision_removed()

	# ============================================================
	#  SECTION 6: Edge Cases
	# ============================================================
	_test_edge_rotate_already_correct_pipe()
	_test_edge_empty_network()
	_test_edge_single_node_network()
	_test_edge_solved_network_ignores_further_rotations()
	_test_edge_player_out_of_range_no_rotate()

	# ============================================================
	#  Report
	# ============================================================
	_report()


# ==============================================================
#  Helpers: 创建实例
# ==============================================================

func _make_pipe(conns: Array, gx: int, gy: int) -> Node:
	var pipe = PipeNodeScript.new()
	pipe.connections = conns
	pipe.grid_x = gx
	pipe.grid_y = gy
	return pipe


func _make_network(source: Vector2i, targets: Array) -> Node:
	var net = SignalNetworkScript.new()
	net.source_grid = source
	net.target_grids.assign(targets)
	return net


func _make_door() -> Node:
	return PuzzleDoorScript.new()


# ==============================================================
#  SECTION 1: AC-1 — PipeNode 旋转状态
# ==============================================================

func _test_ac1_initial_rotation_state() -> void:
	var pipe = _make_pipe([true, false, true, false], 0, 0)

	if pipe.rotation_steps == 0:
		_pass("AC1_initial_rotation", "rotation_steps == 0 on init")
	else:
		_fail("AC1_initial_rotation", "expected 0, got %d" % pipe.rotation_steps)

	pipe.free()


func _test_ac1_rotation_steps_cycle() -> void:
	var pipe = _make_pipe([true, false, false, false], 0, 0)

	# 旋转 4 次应回到原始状态
	pipe.rotate_pipe()  # 1 → 90°
	pipe.rotate_pipe()  # 2 → 180°
	pipe.rotate_pipe()  # 3 → 270°
	pipe.rotate_pipe()  # 0 → 0° (循环)

	if pipe.rotation_steps == 0:
		_pass("AC1_rotation_cycle", "4 rotations cycle back to 0")
	else:
		_fail("AC1_rotation_cycle", "expected 0 after 4 rotations, got %d" % pipe.rotation_steps)

	pipe.free()


func _test_ac1_active_connections_after_rotation() -> void:
	var pipe = _make_pipe([true, false, false, false], 0, 0)  # 只有 NORTH

	# 初始：NORTH 有口
	var active = pipe.get_active_connections()
	if active[0] == true and active[1] == false and active[2] == false and active[3] == false:
		_pass("AC1_active_conn_init", "Initial: only NORTH active")
	else:
		_fail("AC1_active_conn_init", "Expected [T,F,F,F], got %s" % str(active))

	# 旋转 1 次：NORTH → EAST
	pipe.rotate_pipe()
	active = pipe.get_active_connections()
	if active[0] == false and active[1] == true and active[2] == false and active[3] == false:
		_pass("AC1_active_conn_rot1", "After 1 rotation: only EAST active")
	else:
		_fail("AC1_active_conn_rot1", "Expected [F,T,F,F], got %s" % str(active))

	# 旋转 2 次：EAST → SOUTH
	pipe.rotate_pipe()
	active = pipe.get_active_connections()
	if active[0] == false and active[1] == false and active[2] == true and active[3] == false:
		_pass("AC1_active_conn_rot2", "After 2 rotations: only SOUTH active")
	else:
		_fail("AC1_active_conn_rot2", "Expected [F,F,T,F], got %s" % str(active))

	pipe.free()


func _test_ac1_has_connection_direction() -> void:
	var pipe = _make_pipe([true, true, false, false], 0, 0)  # N, E 有口

	# Direction enum: NORTH=0, EAST=1, SOUTH=2, WEST=3
	if pipe.has_connection(0) and pipe.has_connection(1):
		if not pipe.has_connection(2) and not pipe.has_connection(3):
			_pass("AC1_has_connection", "has_connection correctly reports N=T, E=T, S=F, W=F")
		else:
			_fail("AC1_has_connection", "S or W should be false")
	else:
		_fail("AC1_has_connection", "N or E should be true")

	pipe.free()


# ==============================================================
#  SECTION 2: AC-2 — 真实玩家输入路径测试（红线）
#  ※ 使用 InputEventAction 模拟玩家按 interact
#  ※ 不直接调用 rotate_pipe() 作为主要验证手段
# ==============================================================

func _test_ac2_real_input_interact_rotates_pipe() -> void:
	# 搭建最小场景：PipeNode + 模拟 Player 进入范围
	var pipe = _make_pipe([true, false, true, false], 0, 0)
	pipe.interact_range = 48.0
	get_root().add_child(pipe)

	# 模拟玩家进入范围
	var player := CharacterBody2D.new()
	player.name = "Player"
	player.global_position = pipe.global_position  # 距离 0，在范围内
	get_root().add_child(player)

	# 手动触发进入回调（headless 模式下物理引擎不主动触发）
	pipe._on_body_entered(player)

	# 确认初始状态
	var initial_steps: int = pipe.rotation_steps

	# === 真实输入：构造 InputEventAction 模拟按下 interact ===
	var event := InputEventAction.new()
	event.action = "interact"
	event.pressed = true
	pipe._unhandled_input(event)

	if pipe.rotation_steps == (initial_steps + 1) % 4:
		_pass("AC2_REAL_INPUT_interact", "InputEventAction 'interact' triggered rotation — steps: %d → %d" % [initial_steps, pipe.rotation_steps])
	else:
		_fail("AC2_REAL_INPUT_interact", "Expected rotation_steps %d, got %d" % [(initial_steps + 1) % 4, pipe.rotation_steps])

	# 清理
	pipe._on_body_exited(player)
	player.queue_free()
	pipe.queue_free()


func _test_ac2_real_input_full_cycle_four_presses() -> void:
	# 按 4 次 interact，管道应转一圈回到原位
	var pipe = _make_pipe([true, true, false, false], 0, 0)
	pipe.interact_range = 48.0
	get_root().add_child(pipe)

	var player := CharacterBody2D.new()
	player.name = "Player"
	player.global_position = pipe.global_position
	get_root().add_child(player)

	pipe._on_body_entered(player)

	# 连续 4 次真实输入
	for i in range(4):
		var event := InputEventAction.new()
		event.action = "interact"
		event.pressed = true
		pipe._unhandled_input(event)

	if pipe.rotation_steps == 0:
		_pass("AC2_REAL_INPUT_full_cycle", "4x interact press cycles pipe back to rotation_steps == 0")
	else:
		_fail("AC2_REAL_INPUT_full_cycle", "Expected rotation_steps 0 after 4 presses, got %d" % pipe.rotation_steps)

	pipe._on_body_exited(player)
	player.queue_free()
	pipe.queue_free()


# ==============================================================
#  SECTION 3: AC-3 — SignalNetwork 连通性检测
# ==============================================================

func _test_ac3_simple_connected_network() -> void:
	# 两节点直连：source(0,0) → target(1,0)
	var network = _make_network(Vector2i(0, 0), [Vector2i(1, 0)])

	var pipe_a = _make_pipe([false, true, false, false], 0, 0)  # EAST
	var pipe_b = _make_pipe([false, false, false, true], 1, 0)  # WEST

	network.add_child(pipe_a)
	network.add_child(pipe_b)
	get_root().add_child(network)

	# 手动初始化
	network._collect_pipe_nodes()
	network._build_grid_map()
	network._connect_rotation_signals()
	network._check_connectivity()

	if network._solved:
		_pass("AC3_simple_connected", "2-node E→W path correctly detected as connected")
	else:
		_fail("AC3_simple_connected", "Network should be solved (E→W path)")

	network.queue_free()


func _test_ac3_disconnected_network() -> void:
	# 两节点不连通：都朝 NORTH
	var network = _make_network(Vector2i(0, 0), [Vector2i(1, 0)])

	var pipe_a = _make_pipe([true, false, false, false], 0, 0)  # NORTH only
	var pipe_b = _make_pipe([true, false, false, false], 1, 0)  # NORTH only

	network.add_child(pipe_a)
	network.add_child(pipe_b)
	get_root().add_child(network)

	network._collect_pipe_nodes()
	network._build_grid_map()
	network._connect_rotation_signals()
	network._check_connectivity()

	if not network._solved:
		_pass("AC3_disconnected", "Disconnected network correctly NOT solved")
	else:
		_fail("AC3_disconnected", "Network should NOT be solved (no E-W connection)")

	network.queue_free()


func _test_ac3_multi_node_path() -> void:
	# 三节点路径：(0,0)→(1,0)→(2,0)
	var network = _make_network(Vector2i(0, 0), [Vector2i(2, 0)])

	var pipe_a = _make_pipe([false, true, false, false], 0, 0)   # EAST
	var pipe_b = _make_pipe([false, true, false, true], 1, 0)    # EAST + WEST (直管)
	var pipe_c = _make_pipe([false, false, false, true], 2, 0)   # WEST

	network.add_child(pipe_a)
	network.add_child(pipe_b)
	network.add_child(pipe_c)
	get_root().add_child(network)

	network._collect_pipe_nodes()
	network._build_grid_map()
	network._connect_rotation_signals()
	network._check_connectivity()

	if network._solved:
		_pass("AC3_multi_node_path", "3-node E→(W+E)→W path correctly detected as connected")
	else:
		_fail("AC3_multi_node_path", "Network should be solved (3-node chain)")

	network.queue_free()


# ==============================================================
#  SECTION 4: AC-4 — puzzle_solved 信号发射
# ==============================================================

func _test_ac4_puzzle_solved_emitted_on_connect() -> void:
	# 旋转让网络连通 → puzzle_solved 应该 emit
	var network = _make_network(Vector2i(0, 0), [Vector2i(1, 0)])

	var pipe_a = _make_pipe([false, true, false, false], 0, 0)  # EAST

	# pipe_b 初始 NORTH 口 → 需旋转 3 次变成 WEST
	var pipe_b = _make_pipe([true, false, false, false], 1, 0)  # NORTH

	network.add_child(pipe_a)
	network.add_child(pipe_b)
	get_root().add_child(network)

	network._collect_pipe_nodes()
	network._build_grid_map()
	network._connect_rotation_signals()

	# 监听信号
	var signal_received := [false]
	network.puzzle_solved.connect(func(): signal_received[0] = true)

	# 旋转 pipe_b 三次：N→E→S→W
	pipe_b.rotate_pipe()  # N→E
	pipe_b.rotate_pipe()  # E→S
	pipe_b.rotate_pipe()  # S→W ← 这时应该连通

	if signal_received[0]:
		_pass("AC4_puzzle_solved_emitted", "puzzle_solved signal emitted when network connected")
	else:
		_fail("AC4_puzzle_solved_emitted", "puzzle_solved should have been emitted after pipe_b rotated to WEST")

	network.queue_free()


func _test_ac4_no_signal_when_incomplete() -> void:
	# 旋转但不连通 → 不应 emit
	var network = _make_network(Vector2i(0, 0), [Vector2i(1, 0)])

	var pipe_a = _make_pipe([false, true, false, false], 0, 0)  # EAST
	var pipe_b = _make_pipe([true, false, false, false], 1, 0)  # NORTH

	network.add_child(pipe_a)
	network.add_child(pipe_b)
	get_root().add_child(network)

	network._collect_pipe_nodes()
	network._build_grid_map()
	network._connect_rotation_signals()

	var signal_received := [false]
	network.puzzle_solved.connect(func(): signal_received[0] = true)

	# 旋转 1 次：N→E — 不连通（需要 W 口）
	pipe_b.rotate_pipe()

	if not signal_received[0]:
		_pass("AC4_no_signal_incomplete", "No puzzle_solved when network still disconnected")
	else:
		_fail("AC4_no_signal_incomplete", "puzzle_solved should NOT fire when pipe_b has EAST (needs WEST)")

	network.queue_free()


# ==============================================================
#  SECTION 5: AC-5 — PuzzleDoor 响应 puzzle_solved
# ==============================================================

func _test_ac5_door_opens_on_solved() -> void:
	var network = _make_network(Vector2i(0, 0), [Vector2i(1, 0)])

	var pipe_a = _make_pipe([false, true, false, false], 0, 0)  # EAST
	var pipe_b = _make_pipe([false, false, false, true], 1, 0)  # WEST — 已连通

	network.add_child(pipe_a)
	network.add_child(pipe_b)

	var root_node := Node.new()
	root_node.add_child(network)

	var door = _make_door()
	root_node.add_child(door)
	get_root().add_child(root_node)

	# 手动连接 door → network.puzzle_solved
	network.puzzle_solved.connect(door._on_puzzle_solved)

	network._collect_pipe_nodes()
	network._build_grid_map()
	network._connect_rotation_signals()
	network._check_connectivity()

	if door._is_open:
		_pass("AC5_door_opens", "Door._is_open == true after puzzle_solved")
	else:
		_fail("AC5_door_opens", "Door should be open after puzzle_solved signal")

	root_node.queue_free()


func _test_ac5_door_collision_removed() -> void:
	var door = _make_door()
	get_root().add_child(door)

	# 模拟收到 puzzle_solved
	door.open_door()

	if door.collision_layer == 0 and door.collision_mask == 0:
		_pass("AC5_door_collision_removed", "collision_layer/mask == 0 after open_door()")
	else:
		_fail("AC5_door_collision_removed", "Expected collision 0/0, got layer=%d mask=%d" % [door.collision_layer, door.collision_mask])

	door.queue_free()


# ==============================================================
#  SECTION 6: Edge Cases
# ==============================================================

func _test_edge_rotate_already_correct_pipe() -> void:
	# 管道已在正确位置 → reset 后再旋转应破坏连通
	var network = _make_network(Vector2i(0, 0), [Vector2i(1, 0)])

	var pipe_a = _make_pipe([false, true, false, false], 0, 0)  # EAST
	var pipe_b = _make_pipe([false, false, false, true], 1, 0)  # WEST — 正确

	network.add_child(pipe_a)
	network.add_child(pipe_b)
	get_root().add_child(network)

	network._collect_pipe_nodes()
	network._build_grid_map()
	network._connect_rotation_signals()
	network._check_connectivity()

	if network._solved:
		_pass("EDGE_already_correct_pre", "Network solved before extra rotation")
	else:
		_fail("EDGE_already_correct_pre", "Network should be solved initially")
		network.queue_free()
		return

	# reset 后再旋转 → 破坏连通
	network.reset_network()
	pipe_b.rotate_pipe()  # W → N — 破坏连通

	network._check_connectivity()
	if not network._solved:
		_pass("EDGE_already_correct_post", "After reset + wrong rotation: network NOT solved")
	else:
		_fail("EDGE_already_correct_post", "Network should not be solved after pipe_b rotated away from WEST")

	network.queue_free()


func _test_edge_empty_network() -> void:
	# 空网络（无 PipeNode 子节点）→ 不应崩溃，不应 emit
	var network = _make_network(Vector2i(0, 0), [Vector2i(1, 0)])
	get_root().add_child(network)

	network._collect_pipe_nodes()
	network._build_grid_map()
	network._connect_rotation_signals()

	var signal_received := [false]
	network.puzzle_solved.connect(func(): signal_received[0] = true)

	network._check_connectivity()

	if not signal_received[0] and not network._solved:
		_pass("EDGE_empty_network", "Empty network: no crash, no signal, _solved == false")
	else:
		_fail("EDGE_empty_network", "Empty network should not emit or solve")

	network.queue_free()


func _test_edge_single_node_network() -> void:
	# 单节点网络：source == target 在同一个位置
	var network = _make_network(Vector2i(0, 0), [Vector2i(0, 0)])

	var pipe = _make_pipe([true, false, false, false], 0, 0)

	network.add_child(pipe)
	get_root().add_child(network)

	network._collect_pipe_nodes()
	network._build_grid_map()
	network._connect_rotation_signals()
	network._check_connectivity()

	# source 自身就是 target → visited 包含 source → solved
	if network._solved:
		_pass("EDGE_single_node", "Single node where source == target: solved correctly")
	else:
		_fail("EDGE_single_node", "Single node source==target should be solved")

	network.queue_free()


func _test_edge_solved_network_ignores_further_rotations() -> void:
	# 已解决的网络，再旋转不应重复 emit puzzle_solved
	var network = _make_network(Vector2i(0, 0), [Vector2i(1, 0)])

	var pipe_a = _make_pipe([false, true, false, false], 0, 0)  # EAST
	var pipe_b = _make_pipe([false, false, false, true], 1, 0)  # WEST

	network.add_child(pipe_a)
	network.add_child(pipe_b)
	get_root().add_child(network)

	network._collect_pipe_nodes()
	network._build_grid_map()
	network._connect_rotation_signals()

	var emit_count := [0]
	network.puzzle_solved.connect(func(): emit_count[0] += 1)

	network._check_connectivity()  # 第一次 → solved
	pipe_a.rotate_pipe()  # 再旋转 → 不应再 emit

	if emit_count[0] == 1:
		_pass("EDGE_no_double_emit", "puzzle_solved emitted exactly once, further rotations ignored")
	else:
		_fail("EDGE_no_double_emit", "Expected 1 emit, got %d" % emit_count[0])

	network.queue_free()


func _test_edge_player_out_of_range_no_rotate() -> void:
	# 玩家不在范围内按 interact → 不应旋转
	var pipe = _make_pipe([true, false, true, false], 0, 0)
	pipe.interact_range = 48.0
	pipe.global_position = Vector2.ZERO
	get_root().add_child(pipe)

	# 不触发 _on_body_entered → _player_in_range 保持 false
	var initial_steps: int = pipe.rotation_steps

	# 发送 interact 事件
	var event := InputEventAction.new()
	event.action = "interact"
	event.pressed = true
	pipe._unhandled_input(event)

	if pipe.rotation_steps == initial_steps:
		_pass("EDGE_out_of_range", "Interact while player not in range: no rotation")
	else:
		_fail("EDGE_out_of_range", "Pipe should NOT rotate when player not in range")

	pipe.queue_free()


# ==============================================================
#  Helpers
# ==============================================================

func _pass(test_id: String, msg: String) -> void:
	print("%s PASS %s: %s" % [TAG, test_id, msg])
	_passed += 1


func _fail(test_id: String, msg: String) -> void:
	push_error("%s FAIL %s: %s" % [TAG, test_id, msg])
	_failed += 1


func _skip(test_id: String, msg: String) -> void:
	print("%s SKIP %s: %s" % [TAG, test_id, msg])
	_skipped += 1


func _report() -> void:
	var total := _passed + _failed
	print("")
	print("=".repeat(60))
	print("%s RESULT: PASS: %d/%d | SKIP: %d | FAIL: %d" % [TAG, _passed, total, _skipped, _failed])
	print("%s REAL_INPUT_TESTS: 2 (AC2_REAL_INPUT_interact, AC2_REAL_INPUT_full_cycle)" % TAG)
	print("%s EDGE_CASES: 5 (already_correct, empty_network, single_node, no_double_emit, out_of_range)" % TAG)
	print("=".repeat(60))
	if _failed > 0:
		print("%s STATUS: FAIL" % TAG)
		quit(1)
	else:
		print("%s STATUS: PASS" % TAG)
		quit(0)
