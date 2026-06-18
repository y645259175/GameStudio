# =============================================================================
# ExpeditionService.gd · 历练管理 autoload（GDD-03 §1）
# M3 简版：固定 3 节点 DAG → 出发→探索→boss → 回宗门
# =============================================================================
extends Node

signal expedition_started(map_id: String, participant_ids: Array)
signal node_entered(node_index: int, event_id: String)
signal all_nodes_completed(rewards: Dictionary)
signal expedition_finished

var _active: bool = false
var _current_node: int = -1
var _map_id: String = ""
var _participants: Array[String] = []
var _node_events: Array[String] = []   # 每节点的 event_id
var _total_rewards: Dictionary = {}    # {resource_id: amount}


func _ready() -> void:
	print("[ExpeditionService] ready")


func is_active() -> bool: return _active
func get_current_node() -> int: return _current_node


# -----------------------------------------------------------------------------
# 启动历练
# -----------------------------------------------------------------------------
func start_expedition(map_id: String, participant_ids: Array) -> void:
	_active = true
	_map_id = map_id
	_participants = participant_ids
	_current_node = -1
	_total_rewards.clear()
	_node_events.clear()

	# 简版 3 节点：按 participant 的 avg realm tier 决定节点深度的事件池
	var events := _pick_node_events(participant_ids)
	_node_events = events
	expedition_started.emit(map_id, participant_ids)
	# 自动推进第 1 个节点
	advance_node()


# -----------------------------------------------------------------------------
# 节点事件池（按玩家平均境界决定难易度）
# -----------------------------------------------------------------------------
func _pick_node_events(participant_ids: Array) -> Array:
	# 浅层池：simple events
	var shallow := ["exp_forest_stroll", "exp_ancient_stele"]
	# 中层池：choice + battle
	var middle := ["exp_cave_discover", "exp_spirit_beast"]
	# 深层池：boss
	var deep := ["exp_boss_guardian"]
	# 随机选（M3 简版：每个池随机抽 1 个）。保证每节点至少 1 事件
	var e1: String = shallow[randi() % shallow.size()]
	var e2: String = middle[randi() % middle.size()]
	var e3: String = deep[randi() % deep.size()]
	return [e1, e2, e3]


# -----------------------------------------------------------------------------
# 推进到下一节点
# -----------------------------------------------------------------------------
func advance_node() -> String:
	if not _active: return ""
	_current_node += 1
	if _current_node >= _node_events.size():
		_finish_expedition()
		return ""
	var event_id := _node_events[_current_node]
	node_entered.emit(_current_node, event_id)
	# 调用 EventEngine 解析事件
	var ctx := EventEngine.resolve_event(event_id, _participants)
	# 检查是否 extraction
	if ctx.flag("expedition_complete", false):
		_finish_expedition()
		return event_id
	return event_id


# -----------------------------------------------------------------------------
# 结束历练 → 回宗门
# -----------------------------------------------------------------------------
func _finish_expedition() -> void:
	var rewards := _collect_rewards()
	_total_rewards = rewards
	_active = false
	_current_node = _node_events.size()
	all_nodes_completed.emit(rewards)
	expedition_finished.emit()
	print("[ExpeditionService] expedition finished, rewards=", rewards)


# -----------------------------------------------------------------------------
# 奖励收集（派发前记录）
# -----------------------------------------------------------------------------
func _collect_rewards() -> Dictionary:
	return _total_rewards
