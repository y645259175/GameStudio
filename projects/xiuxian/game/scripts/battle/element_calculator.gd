# =============================================================================
# element_calculator.gd · 五行相生相克（GDD-03 §6.4）
#
# 金克木 / 木克土 / 土克水 / 水克火 / 火克金；相生反向链。
# element_bonus：攻方元素克制守方 → 加成；被克 → 减成。M3 占位系数（GDD-06 标定）。
# =============================================================================
class_name ElementCalculator
extends RefCounted

const COUNTER := {            # 克制：key 克 value
	"metal": "wood", "wood": "earth", "earth": "water", "water": "fire", "fire": "metal"
}
const COUNTER_BONUS := 0.10   # 每个克制关系 +10%（GDD-06 占位）


## 攻方元素集合 vs 守方元素集合的加成（-N% ~ +N%）
static func element_bonus(attacker_elements: Array, defender_elements: Array) -> float:
	var bonus := 0.0
	for ae in attacker_elements:
		for de in defender_elements:
			if COUNTER.get(ae, "") == de:
				bonus += COUNTER_BONUS          # 攻克守
			elif COUNTER.get(de, "") == ae:
				bonus -= COUNTER_BONUS          # 守克攻
	return bonus


## 从 spirit_root dict 提取"拥有的元素"（点数 > 0 即拥有）
static func elements_of(c) -> Array:
	var out: Array = []
	if c == null:
		return out
	for elem in c.spirit_root:
		if int(c.spirit_root[elem]) > 0:
			out.append(elem)
	return out
