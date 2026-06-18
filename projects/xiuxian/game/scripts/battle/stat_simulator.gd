# =============================================================================
# stat_simulator.gd · M3 战斗实现（GDD-03 §6.3 战力对拼 + 五行）
#
# 战力公式：final_power = base_power × (1 + Σbuff_mod) × (1 + element_bonus)
# 胜负：碾压（power_ratio_dominate=1.2）或势均力敌 RNG。
# base_power 系数 GDD-06 §7.1（炼气=100 / 筑基=600 / ...）。
# =============================================================================
class_name StatSimulator
extends BattleResolver

const POWER_RATIO_DOMINATE := 1.2
const BASE_POWER := {"qi": 100, "foundation": 600, "golden": 4000, "nascent": 25000, "spirit": 150000}


func _realm_tier(realm: String) -> String:
	return realm.split("_")[0] if "_" in realm else realm


func _base_power(c) -> float:
	var tier := _realm_tier(c.realm)
	var bp: float = BASE_POWER.get(tier, 100)
	# 小境界微调：每层 +10%
	return bp * (1.0 + 0.1 * (c.sub_level - 1))


func _final_power(actor, opponents: Array) -> float:
	var bp := _base_power(actor)
	# buff 加成（battle 类 power 百分比）
	var buff_mod := 0.0
	if BuffService:
		buff_mod = BuffService.sum_attribute_by_category(actor, "battle", "power_percent") / 100.0
	# 五行加成（取对方第一个作代表；M3 简化）
	var elem_bonus := 0.0
	if not opponents.is_empty():
		elem_bonus = ElementCalculator.element_bonus(
			ElementCalculator.elements_of(actor),
			ElementCalculator.elements_of(opponents[0]))
	return bp * (1.0 + buff_mod) * (1.0 + elem_bonus)


func _team_power(team: Array, opponents: Array) -> float:
	var total := 0.0
	for a in team:
		total += _final_power(a, opponents)
	return total


func resolve(ctx: BattleContext) -> BattleResult:
	var r := BattleResult.new()
	r.narrative_seed = ctx.seed
	var atk := _team_power(ctx.attackers, ctx.defenders)
	var def := _team_power(ctx.defenders, ctx.attackers)
	var rng := RandomNumberGenerator.new()
	rng.seed = ctx.seed

	if atk > def * POWER_RATIO_DOMINATE:
		r.winner = "ATTACKERS"
		_apply_hp(r, ctx.defenders, -50)
		_apply_hp(r, ctx.attackers, -5)
	elif def > atk * POWER_RATIO_DOMINATE:
		if ctx.escape_allowed and rng.randf() < 0.4:
			r.winner = "ESCAPED"
		else:
			r.winner = "DEFENDERS"
			_apply_hp(r, ctx.attackers, -50)
	else:
		# 势均力敌：按 power 比例滚 RNG
		var p_atk := atk / (atk + def)
		if rng.randf() < p_atk:
			r.winner = "ATTACKERS"
		else:
			r.winner = "DEFENDERS"
		_apply_hp(r, ctx.attackers, -25)
		_apply_hp(r, ctx.defenders, -25)

	r.log_entries.append("atk_power=%.0f def_power=%.0f → %s" % [atk, def, r.winner])
	return r


func _apply_hp(r: BattleResult, team: Array, delta: int) -> void:
	for c in team:
		r.hp_changes[c.id] = delta
