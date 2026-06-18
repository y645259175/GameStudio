# =============================================================================
# Sect.gd · 宗门统一数据结构（ADR-0006，extends IBuffable）
#
# 宗门是有状态/属性/buff 的实体——玩家身份的"主世界容器"。
# 纪律：SectService 是唯一入口，子领域服务通过 SectService 读写字段。
# =============================================================================
class_name Sect
extends IBuffable

var sect_name: String = "无名宗"
var founded_at_month: int = 1
var description: String = ""

# 派系/地位（M3 占位 / M5 用）
var faction: String = "neutral"
var reputation: float = 0.0
var relations: Dictionary = {}

# 资源（数值）
var resources: Dictionary = {}     # {"spirit_stone": 1000, "herb_common": 50, ...}

# 建设
var buildings: Array = []          # Array[BuildingInstance]（dict 形式存）

# 人员引用（只存 id）
var member_ids: Array = []

# 大事记
var milestones: Array = []


func _init(p_id: String = "player_sect_main") -> void:
	target_id = p_id
	target_type = TargetType.SECT


func to_dict() -> Dictionary:
	var buff_dicts: Array = []
	for b in buffs:
		buff_dicts.append(b.to_dict())
	return {
		"target_id": target_id,
		"sect_name": sect_name,
		"founded_at_month": founded_at_month,
		"description": description,
		"faction": faction,
		"reputation": reputation,
		"relations": relations,
		"resources": resources,
		"buildings": buildings,
		"member_ids": member_ids,
		"milestones": milestones,
		"buffs": buff_dicts,
	}


static func from_dict(d: Dictionary) -> Sect:
	var s := Sect.new(d.get("target_id", "player_sect_main"))
	s.sect_name = d.get("sect_name", "无名宗")
	s.founded_at_month = d.get("founded_at_month", 1)
	s.description = d.get("description", "")
	s.faction = d.get("faction", "neutral")
	s.reputation = d.get("reputation", 0.0)
	s.relations = d.get("relations", {})
	s.resources = d.get("resources", {})
	s.buildings = d.get("buildings", [])
	s.member_ids = d.get("member_ids", [])
	s.milestones = d.get("milestones", [])
	s.buffs = []
	for bd in d.get("buffs", []):
		s.buffs.append(Buff.from_dict(bd))
	return s
