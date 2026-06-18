# =============================================================================
# EventBus.gd · 全局信号总线（autoload，名字 EventBus）
#
# 设计依据：GDD-01 §6.9 系统解耦三原则之一（EventBus signal 异步广播）。
#
# 工程纪律（不可破）：
#   1. 跨系统通信优先走 EventBus signal（异步、广播、发送方不关心订阅方）
#   2. 同步单向调用走 Service 接口；只读数据走 DataRegistry
#   3. 所有"全局级"signal 在此集中声明，便于检索"谁发谁收"
#   4. 领域内部 signal（如某 Service 私有）不放这里，放各自 Service
#   5. 主线钩子（WorldEventTrigger，GDD-10）的钩子在此注册，M3 钩子可空但接口齐
#
# Godot Project Settings → Autoload → 注册：
#   名字: EventBus
#   路径: res://game/scripts/core/event_bus.gd
#   顺序: 在 DataRegistry 之后、TimeService 之前
# =============================================================================
extends Node


# -----------------------------------------------------------------------------
# 时间域 signal（由 TimeService 转发广播；订阅方监听这里或直接监听 TimeService）
# 说明：TimeService 是时间的权威源，EventBus 转发是为了让"不想依赖 TimeService
#       具体类型"的系统有一个统一订阅点。M2 起步阶段两者都可订阅。
# -----------------------------------------------------------------------------
signal month_advanced(new_month: int, year: int, month_of_year: int)
signal year_advanced(new_year: int)
signal expedition_started(map_id: String, max_months: int)
signal expedition_progress_changed(remaining_percent: int, just_consumed: int)
signal expedition_ended(reason: String, months_consumed: int)
signal expedition_time_warning(threshold: String)  # "warning"(30%) / "critical"(10%)


# -----------------------------------------------------------------------------
# 角色域 signal（CharacterService / CultivationSystem 广播；GDD-02/04）
# M2 起步先声明，发射方在各 Service 实装时接上
# -----------------------------------------------------------------------------
signal character_state_changed(character_id: String, old_state: String, new_state: String)
signal character_died(character_id: String, cause: String)
signal sub_realm_advanced(character_id: String, new_realm: String, new_sub_level: int)
signal breakthrough_succeeded(character_id: String, new_realm: String)
signal breakthrough_failed(character_id: String, penalty: Dictionary)
signal lifespan_warning(character_id: String, remaining_months: int)


# -----------------------------------------------------------------------------
# 宗门域 signal（SectService / BuildingService / ProductionService；GDD-05）
# -----------------------------------------------------------------------------
signal building_level_up(slot_id: String, building_id: String, new_level: int)
signal building_construction_started(slot_id: String, building_id: String, target_level: int)
signal alchemy_task_completed(task_id: String, result: Dictionary)
signal recruit_offer_arrived(offer: Dictionary)
signal sect_resource_changed(resource_id: String, new_amount: int, delta: int)


# -----------------------------------------------------------------------------
# 战斗 / 历练域 signal（BattleService / EventEngine；GDD-03）
# -----------------------------------------------------------------------------
signal battle_resolved(result: Dictionary)
signal expedition_node_entered(node_id: String)
signal expedition_event_triggered(event_id: String)


# -----------------------------------------------------------------------------
# 游戏流程 signal
# -----------------------------------------------------------------------------
signal game_over(reason: String)
signal game_saved(slot: int)
signal game_loaded(slot: int)


# -----------------------------------------------------------------------------
# 主线钩子（WorldEventTrigger，GDD-10 §5）
# M3 钩子可空但接口齐。子系统在 _ready 期注册关心的 hook，
# WorldEventTrigger 检测条件满足时 trigger(hook_id) → 这里广播。
# -----------------------------------------------------------------------------
signal world_event_triggered(hook_id: String, payload: Dictionary)

# 已注册的主线钩子 id 集合（M3 仅登记，无监听者时仅 debug log）
var _registered_hooks: Dictionary = {}


func _ready() -> void:
	print("[EventBus] ready")


## 注册主线钩子（GDD-10 §5 / GDD-11 WorldEventTrigger）
## M3：钩子登记后可被 trigger，但若无监听者仅输出 debug log。
func register_world_hook(hook_id: String) -> void:
	_registered_hooks[hook_id] = true


## 触发主线钩子（WorldEventTrigger 内部条件满足时调用）
func trigger_world_hook(hook_id: String, payload: Dictionary = {}) -> void:
	if not _registered_hooks.has(hook_id):
		push_warning("[EventBus] trigger unregistered hook: %s" % hook_id)
	if world_event_triggered.get_connections().is_empty():
		print("[EventBus] hook '%s' triggered (no listener, M3 expected)" % hook_id)
	world_event_triggered.emit(hook_id, payload)


## 调试：列出已注册钩子
func registered_hooks() -> Array:
	return _registered_hooks.keys()
