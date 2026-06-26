# =============================================================================
# event_context.gd · 事件运行时上下文（GDD-03 §2）
#
# 承载一次事件解析期间的 flag（local.choice / local.last_loot 等）+ 参与者引用。
# action handler 读写 flag，条件门用 ConditionEvaluator 求值。
#
# UI 模式：ui_delegate != null 时，show_options 等交互型 handler 会委托给 UI
# 弹真选项并 await 玩家选择（而非 headless 自动选 param1）。
# =============================================================================
class_name EventContext
extends RefCounted

var event_id: String = ""
var participant_ids: Array = []        # 参与此事件的角色 id
var flags: Dictionary = {}             # local flag（choice / last_loot / ...）
var aborted: bool = false              # 事件是否被中断（如战斗失败触发系统事件）

# UI 委托（可空）。UI 模式下由 ExpeditionScreen 设置。
# 必须实现：
#   await present_text(text: String) -> void
#   await present_options(option_ids: Array) -> String   # 返回玩家选的 option_id
#   await present_battle(enemies: Array, result_winner: String) -> void
#   present_reward(resource_id: String, amount: int) -> void
var ui_delegate: Object = null


func set_flag(key: String, value: Variant) -> void:
	flags[key] = value


func flag(key: String, default_value: Variant = null) -> Variant:
	return flags.get(key, default_value)


func has_ui() -> bool:
	return ui_delegate != null and is_instance_valid(ui_delegate)
