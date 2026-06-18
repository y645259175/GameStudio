# =============================================================================
# BattleService.gd · 战斗服务入口（autoload，ADR-0002）
#
# 持有当前 resolver 实例（M3=StatSimulator）。5 接入点统一调 resolve(ctx)。
# M5 升级：换 _resolver 实例即可，调用方零改动。
# =============================================================================
extends Node

var _resolver: BattleResolver = null


func _ready() -> void:
	_resolver = StatSimulator.new()
	print("[BattleService] ready (resolver=StatSimulator)")


## 设置 resolver（M5 切换 TacticalSimulator 用）
func set_resolver(resolver: BattleResolver) -> void:
	_resolver = resolver


## 统一战斗入口（GDD-03 §7 五接入点）
func resolve(ctx: BattleContext) -> BattleResult:
	if _resolver == null:
		push_error("[BattleService] no resolver set")
		return null
	var result := _resolver.resolve(ctx)
	if result != null:
		EventBus.battle_resolved.emit({"winner": result.winner, "hp_changes": result.hp_changes})
	return result
