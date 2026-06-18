# =============================================================================
# BuildingService.gd · 建筑系统（autoload，GDD-05 §3-4）
#
# 职责：建造/升级建筑（月节拍推进 progress）+ 把建筑 modifier 通过 BuffService
#       挂到分配的弟子（character 级 buff）—— GDD-01 §6.12 哲学落地：
#       BuildingService 挂 buff，CultivationSystem 闭关公式自动读，零直接耦合。
#
# 数据来源：DataRegistry.BuildingLevel 表（building_config.tres）
# 行格式：row_id / building_id / level / name_cn / icon_path / build_months /
#         cost_spirit_stone / modifier_kind / modifier_value / capacity / desc_cn
#
# 建筑实例状态机（GDD-05 §3.6）：empty→constructing→built→upgrading→maxed
# =============================================================================
extends Node


func _ready() -> void:
	if TimeService:
		TimeService.month_advanced.connect(_on_month_advanced)
	print("[BuildingService] ready")


# -----------------------------------------------------------------------------
# 配表查询
# -----------------------------------------------------------------------------
func get_level_config(building_id: String, level: int) -> Dictionary:
	var row_id := "%s_lv%d" % [building_id, level]
	for row in DataRegistry.get_table("BuildingLevel"):
		if row.get("row_id") == row_id:
			return row
	return {}


func get_all_building_ids() -> Array:
	var ids: Array = []
	for row in DataRegistry.get_table("BuildingLevel"):
		var bid: String = row.get("building_id", "")
		if bid != "" and not ids.has(bid):
			ids.append(bid)
	return ids


# -----------------------------------------------------------------------------
# 建造 / 升级（写入 Sect.buildings，dict 形式）
# -----------------------------------------------------------------------------
func start_build(slot_id: String, building_id: String, cost: Dictionary = {}) -> bool:
	# 配表 cost 优先，参数 cost 留作覆盖（test 用）
	var cfg := get_level_config(building_id, 1)
	var actual_cost: Dictionary = cost
	if actual_cost.is_empty() and not cfg.is_empty():
		var cs: int = cfg.get("cost_spirit_stone", 0)
		if cs > 0:
			actual_cost = {"spirit_stone": cs}
	if not actual_cost.is_empty() and not InventoryService.consume_all(actual_cost):
		return false
	var b := {
		"slot_id": slot_id,
		"building_id": building_id,
		"current_level": 0,
		"target_level": 1,
		"progress_months": 0,
		"assigned_character_ids": [],
	}
	SectService.get_sect().buildings.append(b)
	EventBus.building_construction_started.emit(slot_id, building_id, 1)
	return true


func start_upgrade(slot_id: String, cost: Dictionary = {}) -> bool:
	var b: Dictionary = _find_building(slot_id)
	if b.is_empty() or b.get("current_level", 0) >= 3:
		return false
	var bid: String = b.get("building_id", "")
	var next_lv: int = b.get("current_level", 0) + 1
	var cfg := get_level_config(bid, next_lv)
	var actual_cost: Dictionary = cost
	if actual_cost.is_empty() and not cfg.is_empty():
		var cs: int = cfg.get("cost_spirit_stone", 0)
		if cs > 0:
			actual_cost = {"spirit_stone": cs}
	if not actual_cost.is_empty() and not InventoryService.consume_all(actual_cost):
		return false
	b["target_level"] = next_lv
	b["progress_months"] = 0
	return true


## 预建：开局直接建好到指定等级（GDD-05 §3.2 is_predefined，不走月节拍/不扣资源）
func predefine_building(slot_id: String, building_id: String, level: int = 1) -> void:
	if not _find_building(slot_id).is_empty():
		return
	var b := {
		"slot_id": slot_id,
		"building_id": building_id,
		"current_level": level,
		"target_level": level,
		"progress_months": 0,
		"assigned_character_ids": [],
	}
	SectService.get_sect().buildings.append(b)
	EventBus.building_level_up.emit(slot_id, building_id, level)


func _find_building(slot_id: String) -> Dictionary:
	for b in SectService.get_sect().buildings:
		if b.get("slot_id") == slot_id:
			return b
	return {}


## 建筑剩余容量（GDD-05 §3.2.3 capacity 限制同时分配人数）
func get_capacity(building_id: String) -> int:
	var lv := get_building_level(building_id)
	if lv < 1:
		return 0
	var cfg := get_level_config(building_id, lv)
	return cfg.get("capacity", 0)


func get_assigned_count(slot_id: String) -> int:
	var b := _find_building(slot_id)
	return b.get("assigned_character_ids", []).size() if not b.is_empty() else 0


## 宗门居住容量（所有 disciple_dorm 的 housing_capacity 之和，GDD-05 §3.2.2）
func get_housing_capacity() -> int:
	var total := 0
	for b in SectService.get_sect().buildings:
		if b.get("building_id") == "disciple_dorm":
			var cfg := get_level_config("disciple_dorm", b.get("current_level", 0))
			if not cfg.is_empty() and cfg.get("modifier_kind", "") == "housing_capacity":
				total += int(cfg.get("modifier_value", 0))
	return total


func get_building_level(building_id: String) -> int:
	for b in SectService.get_sect().buildings:
		if b.get("building_id") == building_id:
			return b.get("current_level", 0)
	return 0


func get_all_buildings() -> Array:
	return SectService.get_sect().buildings


# -----------------------------------------------------------------------------
# 弟子分配（挂 modifier buff → CultivationSystem 自动读）
# -----------------------------------------------------------------------------
## 分配结果码：0=成功 / 1=建筑无效 / 2=角色无效 / 3=容量已满
func assign_character(slot_id: String, character_id: String) -> bool:
	return assign_character_ex(slot_id, character_id) == 0


func assign_character_ex(slot_id: String, character_id: String) -> int:
	var b: Dictionary = _find_building(slot_id)
	if b.is_empty() or b.get("current_level", 0) < 1:
		return 1
	var c: Character = CharacterService.get_character(character_id)
	if c == null:
		return 2
	# 容量检查（GDD-05 §3.2.3）：已在本建筑的不占新名额
	var bid_check: String = b["building_id"]
	var cap := get_capacity(bid_check)
	var already_here: bool = b["assigned_character_ids"].has(character_id)
	if cap > 0 and not already_here and b["assigned_character_ids"].size() >= cap:
		return 3
	# 先解除该角色之前在其它建筑的分配（避免双挂 buff）
	_unassign_from_others(character_id, slot_id)
	if not b["assigned_character_ids"].has(character_id):
		b["assigned_character_ids"].append(character_id)

	# 配表读 modifier_kind / modifier_value 挂 buff
	var bid: String = b["building_id"]
	var lv: int = b["current_level"]
	var cfg := get_level_config(bid, lv)
	if not cfg.is_empty():
		var mk: String = cfg.get("modifier_kind", "")
		var mv: float = cfg.get("modifier_value", 0.0)
		if mk == "qi_acceleration" and mv > 0:
			BuffService.apply(c, "cultivation", "qi_acceleration",
				{"percent": mv}, -1, "building/" + bid)
			CharacterService.set_action_state(character_id, Character.ActionState.IN_CULTIVATION, {"mode": "normal"})
		elif mk == "insight_per_month" and mv > 0:
			# 藏经阁：每月加悟性（GDD-05 §3.2.4）。挂 insight_gain buff，
			# CultivationSystem 月节拍读 attributes["per_month"] 累加到 insight。
			BuffService.apply(c, "cultivation", "insight_gain",
				{"per_month": mv}, -1, "building/" + bid)
			CharacterService.set_action_state(character_id, Character.ActionState.IN_CULTIVATION, {"mode": "study"})
		elif mk == "forge_speed" and mv > 0:
			BuffService.apply(c, "production", "forge_speed",
				{"percent": mv}, -1, "building/" + bid)
	return 0


func _unassign_from_others(character_id: String, except_slot: String) -> void:
	for b in SectService.get_sect().buildings:
		if b.get("slot_id") == except_slot:
			continue
		var ids: Array = b.get("assigned_character_ids", [])
		if ids.has(character_id):
			ids.erase(character_id)
			# 移除对应建筑 buff
			var c: Character = CharacterService.get_character(character_id)
			if c != null:
				BuffService.remove_by_source(c, "building/" + b.get("building_id", ""))


func unassign_character(slot_id: String, character_id: String) -> void:
	var b: Dictionary = _find_building(slot_id)
	if b.is_empty():
		return
	b["assigned_character_ids"].erase(character_id)
	var c: Character = CharacterService.get_character(character_id)
	if c != null:
		BuffService.remove_by_source(c, "building/" + b.get("building_id", ""))


# -----------------------------------------------------------------------------
# 月节拍：推进建造/升级进度
# -----------------------------------------------------------------------------
func _on_month_advanced(_m: int, _y: int, _moy: int) -> void:
	for b in SectService.get_sect().buildings:
		if b.get("current_level", 0) < b.get("target_level", 0):
			b["progress_months"] = b.get("progress_months", 0) + 1
			var bid: String = b.get("building_id", "")
			var target_lv: int = b.get("target_level", 1)
			var cfg := get_level_config(bid, target_lv)
			var needed: int = cfg.get("build_months", 1) if not cfg.is_empty() else 1
			if b["progress_months"] >= needed:
				b["current_level"] = b["target_level"]
				b["progress_months"] = 0
				EventBus.building_level_up.emit(b["slot_id"], b["building_id"], b["current_level"])
