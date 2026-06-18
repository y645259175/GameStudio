# =============================================================================
# IBuffable.gd · 可挂 buff 的实体基类（ADR-0005 §1）
#
# Godot 4 GDScript 无 interface 关键字，用基类 + duck-typing 约定。
# 实现者：Character（ADR-0003）/ Sect（ADR-0006）/ ExpeditionMapInstance（GDD-03）。
#
# 约定字段（实现者必须有）：
#   var target_type: TargetType
#   var target_id: String
#   var buffs: Array          # Array[Buff]
# =============================================================================
class_name IBuffable
extends RefCounted

# target 实体类型（用于序列化和 ID 命名空间）
enum TargetType {
	CHARACTER,    # 角色（门主 / 弟子 / 长老 / NonSect）
	SECT,         # 宗门
	MAP,          # 历练地图实例
	REGION,       # 大地图区域（未来扩展）
}

var target_type: int = TargetType.CHARACTER
var target_id: String = ""
var buffs: Array = []   # Array[Buff]
