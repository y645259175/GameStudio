# =============================================================================
# CultivationSystem.gd · 成长系统（autoload，GDD-04 + GDD-06 系数）
#
# 职责：闭关 monthly_gain / 经验阈值 / 小境界推进 / 瓶颈修为分 / 突破检定。
# 纪律（GDD-01 §6.12）：通过 BuffService 聚合 cultivation_multiplier，不直接读建筑。
#                      通过 CharacterService 接口改字段，不直接写 character。
#
# M3 数值系数内置（来自 GDD-06）；配表化在 M2 后期接 DataRegistry。
# =============================================================================
extends Node

# === GDD-06 §6.1-6.4 系数 fallback（DataRegistry RealmCurve 缺失时降级用）===
const BASE_MONTHLY_SCORE := 8.0
const FALLBACK_THRESHOLD := 100.0
const FALLBACK_SPEED := 5.0
const FALLBACK_BREAK_BASE := 20.0
const FALLBACK_BREAK_DIFF := 100.0


func _ready() -> void:
	# 注册 cultivating 子模式到 CharacterRegistry（ADR-0003 v3.3 哲学落地）
	if CharacterRegistry:
		CharacterRegistry.register_state_mode("cultivating", "normal")
		CharacterRegistry.register_state_mode("cultivating", "bottleneck")
		CharacterRegistry.register_state_mode("cultivating", "deep_retreat")  # M5
		CharacterRegistry.register_attribute_modifier_source(
			"cultivation_system", ["experience", "cultivation_score", "lifespan_remaining_months"])
	# 月节拍推进闭关
	if TimeService:
		TimeService.month_advanced.connect(_on_month_advanced)
	print("[CultivationSystem] ready")


func _realm_tier(realm: String) -> String:
	# realm id 形如 "qi_1"；取前缀
	return realm.split("_")[0] if "_" in realm else realm


# DataRegistry 配表查询：realm_id + sub_level → RealmCurve 行
func _curve_row(realm: String, sub_level: int) -> Dictionary:
	var tier := _realm_tier(realm)
	var key := "%s_%d" % [tier, sub_level]
	for row in DataRegistry.get_table("RealmCurve"):
		if row.get("realm_sub") == key:
			return row
	return {}


# -----------------------------------------------------------------------------
# 公式（GDD-04 §2.2 / §6.2）
# -----------------------------------------------------------------------------
func experience_threshold(realm: String, sub_level: int) -> int:
	var row := _curve_row(realm, sub_level)
	if row.is_empty():
		return int(FALLBACK_THRESHOLD * pow(float(sub_level), 1.3))
	return int(row.get("exp_threshold", FALLBACK_THRESHOLD))


func diminishing_factor(continuous_months: int) -> float:
	return pow(0.5, max(0, continuous_months - 12) / 12.0)


func monthly_gain(c: Character) -> float:
	var row := _curve_row(c.realm, c.sub_level)
	var base: float = row.get("base_speed", FALLBACK_SPEED) if not row.is_empty() else FALLBACK_SPEED
	# 灵根加成 Σ aᵢ·root（M3 简化：用主灵根总点数 × 0.08 占位，功法系数化在 M2 后期）
	var root_sum := 0.0
	for v in c.spirit_root.values():
		root_sum += float(v)
	var root_factor := 1.0 + 0.08 * root_sum
	# cultivation_multiplier：BuffService 聚合所有 cultivation 类 speed bonus（百分比）
	var mult := 1.0
	if BuffService:
		mult += BuffService.sum_attribute_by_category(c, "cultivation", "percent") / 100.0
	# 边际递减
	var cont: int = c.action_state_data.get("continuous_months", 0)
	var dim := diminishing_factor(cont)
	return base * root_factor * mult * dim


# -----------------------------------------------------------------------------
# 月节拍：推进所有 cultivating 角色
# -----------------------------------------------------------------------------
func _on_month_advanced(_m: int, _y: int, _moy: int) -> void:
	if CharacterService == null:
		return
	for c in CharacterService.all():
		if c.action_state == Character.ActionState.DEAD:
			continue
		# 1) 寿元每月衰减（GDD-02 §2.6）—— 走 CharacterService 接口（含濒死/死亡广播）
		CharacterService.decrease_lifespan(c.id, 1)
		if c.action_state == Character.ActionState.DEAD:
			continue
		# 2) 藏经阁每月加悟性（insight_gain buff 的 per_month 聚合）
		var insight_gain := 0.0
		if BuffService:
			insight_gain = BuffService.sum_attribute(c, "cultivation", "insight_gain", "per_month")
		if insight_gain > 0.0:
			CharacterService.change_attribute(c.id, "insight", insight_gain)
		# 3) 闭关推进（修炼 / 研读都涨修为；study 模式只加悟性不涨修为则跳过修炼）
		if c.action_state == Character.ActionState.IN_CULTIVATION:
			var mode: String = c.action_state_data.get("mode", "normal")
			if mode != "study":
				_tick_cultivation(c)


func _tick_cultivation(c: Character) -> void:
	c.action_state_data["continuous_months"] = c.action_state_data.get("continuous_months", 0) + 1
	var mode: String = c.action_state_data.get("mode", "normal")
	if mode == "bottleneck":
		_tick_bottleneck(c)
	else:
		_tick_normal(c)


func _tick_normal(c: Character) -> void:
	var gain := monthly_gain(c)
	var exp: float = c.attributes.get("experience", 0.0) + gain
	var threshold := experience_threshold(c.realm, c.sub_level)
	while exp >= threshold and c.sub_level < 9:
		exp -= threshold
		c.sub_level += 1
		EventBus.sub_realm_advanced.emit(c.id, c.realm, c.sub_level)
		threshold = experience_threshold(c.realm, c.sub_level)
	# 9 层满 → 进瓶颈
	if c.sub_level >= 9 and exp >= threshold:
		c.action_state_data["mode"] = "bottleneck"
		c.action_state_data["cultivation_score"] = 0.0
		c.action_state_data["months_in_bottleneck"] = 0
	c.attributes["experience"] = exp


func _tick_bottleneck(c: Character) -> void:
	var mib: int = c.action_state_data.get("months_in_bottleneck", 0) + 1
	c.action_state_data["months_in_bottleneck"] = mib
	var insight: float = c.attributes.get("insight", 100)
	var dim := 1.0
	if mib > 36: dim = 0.4
	elif mib > 12: dim = 0.7
	var score_gain := BASE_MONTHLY_SCORE * (insight / 100.0) * dim
	c.action_state_data["cultivation_score"] = c.action_state_data.get("cultivation_score", 0.0) + score_gain


# -----------------------------------------------------------------------------
# 突破检定（GDD-04 §4 / GDD-06 §6.4）
# -----------------------------------------------------------------------------
func breakthrough_probability(c: Character) -> float:
	var score: float = c.action_state_data.get("cultivation_score", 0.0)
	var root_score := 0.0
	for v in c.spirit_root.values():
		root_score += float(v)
	var insight: float = c.attributes.get("insight", 100)
	var insight_score := (insight - 100.0) / 10.0
	# buff 增益（突破丹等）
	var buff_bonus := 0.0
	if BuffService:
		buff_bonus = BuffService.sum_attribute_by_category(c, "cultivation", "breakthrough_bonus") / 100.0
	# 大境最后一层（sub_level 9）取 RealmCurve 的突破系数
	var row := _curve_row(c.realm, c.sub_level)
	var bb: float = row.get("breakthrough_base_score", FALLBACK_BREAK_BASE) if not row.is_empty() else FALLBACK_BREAK_BASE
	var bd: float = row.get("breakthrough_difficulty", FALLBACK_BREAK_DIFF) if not row.is_empty() else FALLBACK_BREAK_DIFF
	if bb <= 0.0: bb = FALLBACK_BREAK_BASE
	if bd <= 0.0: bd = FALLBACK_BREAK_DIFF
	var base_prob: float = (bb + max(score, 10.0) + root_score + insight_score) / bd
	return clampf(base_prob + buff_bonus, 0.0, 1.0)


## 尝试突破（玩家主动）。realm_order 给出下一大境界 id。
func try_breakthrough(character_id: String, next_realm: String) -> bool:
	var c: Character = CharacterService.get_character(character_id)
	if c == null:
		return false
	var prob := breakthrough_probability(c)
	var roll := randf()
	if roll < prob:
		c.realm = next_realm
		c.sub_level = 1
		c.attributes["experience"] = 0.0
		c.action_state_data["mode"] = "normal"
		c.action_state_data["cultivation_score"] = 0.0
		c.action_state_data["months_in_bottleneck"] = 0
		EventBus.breakthrough_succeeded.emit(character_id, next_realm)
		return true
	else:
		# 失败惩罚（GDD-04 §4.6）：跌 1 小境 + 修为分清零
		c.sub_level = max(1, c.sub_level - 1)
		c.action_state_data["cultivation_score"] = 0.0
		c.action_state_data["months_in_bottleneck"] = 0
		EventBus.breakthrough_failed.emit(character_id, {"dropped_to": c.sub_level})
		return false
