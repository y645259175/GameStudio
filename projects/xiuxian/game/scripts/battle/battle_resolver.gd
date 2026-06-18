# =============================================================================
# battle_resolver.gd · 战斗抽象接口（ADR-0002）
#
# M3 实现 = StatSimulator；M5 = TacticalSimulator。调用方只看接口不看实现。
# =============================================================================
class_name BattleResolver
extends RefCounted


func resolve(_ctx: BattleContext) -> BattleResult:
	push_error("BattleResolver.resolve must be overridden")
	return null


# M5 演出层包装（默认调 resolve 不演出）
func resolve_async(ctx: BattleContext) -> BattleResult:
	return resolve(ctx)
