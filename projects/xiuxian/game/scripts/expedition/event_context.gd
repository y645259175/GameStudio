# =============================================================================
# event_context.gd · 事件运行时上下文（GDD-03 §2.6）
#
# 承载一次事件解析的 local flag + 参与者。
# - flag(): 事件内 local flag（choice / battle_result / ...）
# - expedition_flag(): 历练内 flag（跨事件，存 ExpeditionService）
# - get_actor(): 当前在场主角（境界/灵根/属性，供 condition DSL 读）
#
# UI 模式：ui_delegate != null 时阻塞型 action 委托 UI 并 await 玩家。
# =============================================================================
class_name EventContext
extends RefCounted

var event_id: String = ""
var participant_ids: Array = []
var flags: Dictionary = {}             # local flag
var aborted: bool = false
var ui_delegate: Object = null


func set_flag(key: String, value: Variant) -> void:
	flags[key] = value


func flag(key: String, default_value: Variant = null) -> Variant:
	return flags.get(key, default_value)


# 历练级 flag（跨事件，存 ExpeditionService）
func set_expedition_flag(key: String, value: Variant) -> void:
	var es: Node = Engine.get_main_loop().root.get_node_or_null("/root/ExpeditionService")
	if es and es.has_method("set_exp_flag"):
		es.set_exp_flag(key, value)


func expedition_flag(key: String, default_value: Variant = null) -> Variant:
	var es: Node = Engine.get_main_loop().root.get_node_or_null("/root/ExpeditionService")
	if es and es.has_method("get_exp_flag"):
		return es.get_exp_flag(key, default_value)
	return default_value


# 当前在场主角（M3 = participant_ids[0]）
func get_actor() -> Character:
	if participant_ids.is_empty():
		return null
	var cs: Node = Engine.get_main_loop().root.get_node_or_null("/root/CharacterService")
	if cs == null:
		return null
	return cs.get_character(str(participant_ids[0]))


func has_ui() -> bool:
	return ui_delegate != null and is_instance_valid(ui_delegate)
