# =============================================================================
# Buff.gd · 运行时 buff 实例（ADR-0005）
#
# 一个挂在 IBuffable 上的具体 buff。由 BuffService 创建 / 管理 / tick。
# 区别于"BuffType 定义"（数据驱动表 A）和"BuffInstance 模板"（表 B）：
#   - BuffType  = 大类/小类/字段 schema（设计）
#   - 模板      = 默认数值（设计）
#   - Buff（本类）= 实际挂载的运行态（含剩余时长 / 当前数值）
# =============================================================================
class_name Buff
extends RefCounted

var instance_id: String = ""          # 本次挂载的唯一 id（运行时生成）
var category: String = ""             # 大类（"cultivation" / "injury" / ...）
var subtype: String = ""              # 小类（"qi_acceleration" / "poison" / ...）
var attributes: Dictionary = {}       # 当前数值（如 {level: 30}）
var duration_months: int = -1         # 剩余时长（月），-1 = 永久
var source: String = ""               # 来源标签（debug / 定向清除用）


func _init(p_subtype: String = "", p_category: String = "", p_attributes: Dictionary = {}, p_duration: int = -1, p_source: String = "") -> void:
	subtype = p_subtype
	category = p_category
	attributes = p_attributes.duplicate(true)
	duration_months = p_duration
	source = p_source


## 是否永久
func is_permanent() -> bool:
	return duration_months < 0


## 月节拍递减时长，返回是否已到期
func tick() -> bool:
	if is_permanent():
		return false
	duration_months -= 1
	return duration_months <= 0


func to_dict() -> Dictionary:
	return {
		"instance_id": instance_id,
		"category": category,
		"subtype": subtype,
		"attributes": attributes,
		"duration_months": duration_months,
		"source": source,
	}


static func from_dict(d: Dictionary) -> Buff:
	var b := Buff.new(
		d.get("subtype", ""),
		d.get("category", ""),
		d.get("attributes", {}),
		d.get("duration_months", -1),
		d.get("source", "")
	)
	b.instance_id = d.get("instance_id", "")
	return b
