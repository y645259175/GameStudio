# =============================================================================
# ExpeditionService.gd · 历练管理 autoload（GDD-03 §1）
# M3 简版：固定 3 节点 DAG → 出发→探索→boss → 回宗门
# =============================================================================
extends Node

signal expedition_started(map_id: String, participant_ids: Array)
signal node_entered(node_index: int, event_id: String)
signal all_nodes_completed(rewards: Dictionary)
signal expedition_finished(reason: String)   # reason: active / timeout / defeat / cleared

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
func get_participants() -> Array: return _participants.duplicate()
func get_node_events() -> Array: return _node_events.duplicate()
func get_map_id() -> String: return _map_id


# 当前节点 event_id（UI 用）
func current_event_id() -> String:
	if _current_node >= 0 and _current_node < _node_events.size():
		return _node_events[_current_node]
	return ""


# 某节点的事件类别（UI 选节点图标用）
func node_event_type(node_index: int) -> String:
	if node_index < 0 or node_index >= _node_events.size():
		return "story"
	var eid: String = _node_events[node_index]
	if DataRegistry and DataRegistry.is_loaded():
		for row in DataRegistry.get_table("EventTemplate"):
			if row.get("event_id") == eid:
				return row.get("event_type", "story")
	return "story"


# -----------------------------------------------------------------------------
# 启动历练
# -----------------------------------------------------------------------------
func start_expedition(map_id: String, participant_ids: Array) -> void:
	_setup(map_id, participant_ids)
	expedition_started.emit(map_id, participant_ids)
	# 自动推进第 1 个节点（headless / 旧 UI 兼容）
	advance_node()


## UI 模式：只准备节点，不自动推进（由 ExpeditionScreen 逐节点驱动）
func start_expedition_ui(map_id: String, participant_ids: Array) -> void:
	_setup(map_id, participant_ids)
	expedition_started.emit(map_id, participant_ids)


func _setup(map_id: String, participant_ids: Array) -> void:
	_active = true
	_map_id = map_id
	_participants.clear()
	for pid in participant_ids:
		_participants.append(str(pid))
	_current_node = -1
	_total_rewards.clear()
	_node_events.clear()
	var events := _pick_node_events(participant_ids)
	for ev in events:
		_node_events.append(str(ev))


## UI 模式逐节点推进：进到下一节点并用 UI delegate 跑事件，返回 event_id（""=已结束）
func advance_node_ui(ui_delegate: Object) -> String:
	if not _active: return ""
	_current_node += 1
	if _current_node >= _node_events.size():
		_finish_expedition("cleared")
		return ""
	var event_id: String = _node_events[_current_node]
	node_entered.emit(_current_node, event_id)
	var ctx: EventContext = await EventEngine.resolve_event_ui(event_id, _participants, ui_delegate)
	if _is_party_wiped():
		_finish_expedition("defeat")
	elif ctx.flag("expedition_complete", false):
		_finish_expedition("timeout")
	return event_id


# -----------------------------------------------------------------------------
# 节点事件池（按玩家平均境界决定难易度）
# -----------------------------------------------------------------------------
func _pick_node_events(_participant_ids: Array) -> Array:
	# 三层事件池（GDD-03 §1 节点深度）
	var shallow := ["exp_forest_stroll", "exp_ancient_stele", "exp_herb_field", "exp_old_hermit", "exp_spirit_spring"]
	var middle := ["exp_cave_discover", "exp_spirit_beast", "exp_ruins_choice", "exp_wandering_cultivator", "exp_poison_swamp"]
	var deep := ["exp_boss_guardian", "exp_demon_ambush", "exp_treasure_vault"]
	# M3：6 节点 DAG（2 浅 + 3 中 + 1 深），每层不重复抽
	var out: Array = []
	out += _sample(shallow, 2)
	out += _sample(middle, 3)
	out += _sample(deep, 1)
	return out


func _sample(pool: Array, n: int) -> Array:
	var p := pool.duplicate()
	p.shuffle()
	return p.slice(0, min(n, p.size()))


# 当前历练总节点数
func node_count() -> int:
	return _node_events.size()


# -----------------------------------------------------------------------------
# 推进到下一节点
# -----------------------------------------------------------------------------
func advance_node() -> String:
	if not _active: return ""
	_current_node += 1
	if _current_node >= _node_events.size():
		# 走完所有节点 = 全清通关
		_finish_expedition("cleared")
		return ""
	var event_id := _node_events[_current_node]
	node_entered.emit(_current_node, event_id)
	# 调用 EventEngine 解析事件
	var ctx := EventEngine.resolve_event(event_id, _participants)
	# 撤离三类之一：defeat（参与者全灭）
	if _is_party_wiped():
		_finish_expedition("defeat")
		return event_id
	# extraction action 触发（事件内 boss 战后撤离）
	if ctx.flag("expedition_complete", false):
		_finish_expedition("timeout")
		return event_id
	return event_id


## 主动撤离（GDD-03 §1 撤离三类之 active）
func retreat() -> void:
	if _active:
		_finish_expedition("active")


func _is_party_wiped() -> bool:
	for cid in _participants:
		var c: Character = CharacterService.get_character(cid)
		if c != null and c.action_state != Character.ActionState.DEAD:
			return false
	return true


# -----------------------------------------------------------------------------
# 结束历练 → 回宗门（reason: active / timeout / defeat / cleared）
# -----------------------------------------------------------------------------
func _finish_expedition(reason: String) -> void:
	_active = false
	_current_node = _node_events.size()
	all_nodes_completed.emit(_total_rewards)
	expedition_finished.emit(reason)
	EventBus.expedition_ended.emit(reason, _current_node)
	print("[ExpeditionService] expedition finished (%s)" % reason)



