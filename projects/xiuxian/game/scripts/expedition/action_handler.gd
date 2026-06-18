# =============================================================================
# action_handler.gd · ActionHandler 抽象基类（GDD-03 §2.3）
#
# 每个 action_type 一个 handler，实现 execute(action, ctx)。
# 阻塞型（show_options/start_battle）handler 内部 await；其它同步。
# review 红线：每个 handler 只能调其文档声明的 service（不越权）。
# =============================================================================
class_name ActionHandler
extends RefCounted


## 执行一个 action。action = Dictionary（含 param1-3 等）；ctx = EventContext。
func execute(_action: Dictionary, _ctx: EventContext) -> void:
	push_error("ActionHandler.execute must be overridden")
