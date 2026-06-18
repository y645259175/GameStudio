# =============================================================================
# event_context.gd · 事件运行时上下文（GDD-03 §2）
#
# 承载一次事件解析期间的 flag（local.choice / local.last_loot 等）+ 参与者引用。
# action handler 读写 flag，条件门用 ConditionEvaluator 求值。
# =============================================================================
class_name EventContext
extends RefCounted

var event_id: String = ""
var participant_ids: Array = []        # 参与此事件的角色 id
var flags: Dictionary = {}             # local flag（choice / last_loot / ...）
var aborted: bool = false              # 事件是否被中断（如战斗失败触发系统事件）


func set_flag(key: String, value: Variant) -> void:
	flags[key] = value


func flag(key: String, default_value: Variant = null) -> Variant:
	return flags.get(key, default_value)
