# =============================================================================
# AlchemyService.gd · 炼丹系统（autoload，GDD-05 §5）
#
# 读 DataRegistry.AlchemyRecipe 配方表；炼丹任务月节拍推进 → 到期滚成功率。
# 丹房月产药材（GDD-05 §5.6）。炼丹位受丹房等级限制（lv1/lv2=1，lv3=2）。
# =============================================================================
extends Node

signal alchemy_started(recipe_id: String, disciple_id: String)
signal alchemy_finished(recipe_id: String, success: bool, output: Dictionary)

# 丹房月产药材（GDD-05 §4.5）：lv → 株
const HERB_YIELD := {1: 2, 2: 4, 3: 6}

var _tasks: Array = []     # [{recipe_id, disciple_id, remaining, recipe_row}]


func _ready() -> void:
	if TimeService:
		TimeService.month_advanced.connect(_on_month_advanced)
	print("[AlchemyService] ready")


# -----------------------------------------------------------------------------
# 配方查询
# -----------------------------------------------------------------------------
func get_all_recipes() -> Array:
	if DataRegistry == null or not DataRegistry.is_loaded():
		return []
	return DataRegistry.get_table("AlchemyRecipe")


func get_recipe(recipe_id: String) -> Dictionary:
	for r in get_all_recipes():
		if r.get("recipe_id") == recipe_id:
			return r
	return {}


# 炼丹位（GDD-05 §5.5）：丹房 lv1/lv2 = 1 位，lv3 = 2 位
func max_slots() -> int:
	var lv := BuildingService.get_building_level("alchemy_room")
	return 2 if lv >= 3 else 1


func active_count() -> int:
	return _tasks.size()


func has_free_slot() -> bool:
	return active_count() < max_slots() and BuildingService.get_building_level("alchemy_room") >= 1


# -----------------------------------------------------------------------------
# 可炼判定（GDD-05 §5.1 校验链）
# 返回："" = 可炼 / 否则返回中文不可炼原因
# -----------------------------------------------------------------------------
func cannot_craft_reason(recipe_id: String, disciple_id: String) -> String:
	var r := get_recipe(recipe_id)
	if r.is_empty():
		return "配方不存在"
	var room_lv := BuildingService.get_building_level("alchemy_room")
	if room_lv < int(r.get("required_room_level", 1)):
		return "需丹房 Lv%d" % int(r.get("required_room_level", 1))
	if not has_free_slot():
		return "炼丹位已满"
	# 材料
	for mkey in [["material1_id", "material1_count"], ["material2_id", "material2_count"]]:
		var mid: String = r.get(mkey[0], "")
		var cnt: int = int(r.get(mkey[1], 0))
		if mid != "" and cnt > 0 and not InventoryService.has(mid, cnt):
			return "材料不足"
	# 炼丹值
	var skill_req := int(r.get("required_alchemy_skill", 0))
	if disciple_id != "":
		var c: Character = CharacterService.get_character(disciple_id)
		if c != null and int(c.attributes.get("alchemy", 0)) < skill_req:
			return "炼丹值不足（需 %d）" % skill_req
	return ""


# -----------------------------------------------------------------------------
# 开始炼丹
# -----------------------------------------------------------------------------
func start_craft(recipe_id: String, disciple_id: String = "") -> bool:
	if cannot_craft_reason(recipe_id, disciple_id) != "":
		return false
	var r := get_recipe(recipe_id)
	# 扣材料
	var cost: Dictionary = {}
	for mkey in [["material1_id", "material1_count"], ["material2_id", "material2_count"]]:
		var mid: String = r.get(mkey[0], "")
		var cnt: int = int(r.get(mkey[1], 0))
		if mid != "" and cnt > 0:
			cost[mid] = cnt
	if not InventoryService.consume_all(cost):
		return false
	_tasks.append({
		"recipe_id": recipe_id,
		"disciple_id": disciple_id,
		"remaining": int(r.get("duration_months", 1)),
		"recipe_row": r,
	})
	alchemy_started.emit(recipe_id, disciple_id)
	return true


func get_active_tasks() -> Array:
	return _tasks


# -----------------------------------------------------------------------------
# 月节拍：推进任务 + 月产药材
# -----------------------------------------------------------------------------
func _on_month_advanced(_m: int, _y: int, _moy: int) -> void:
	# 月产药材（GDD-05 §5.6）
	var lv := BuildingService.get_building_level("alchemy_room")
	if lv >= 1:
		InventoryService.add("spirit_herb", HERB_YIELD.get(lv, 2))
	# 推进炼丹任务
	for i in range(_tasks.size() - 1, -1, -1):
		var t = _tasks[i]
		t["remaining"] -= 1
		if t["remaining"] <= 0:
			_settle(t)
			_tasks.remove_at(i)


func _settle(task: Dictionary) -> void:
	var r: Dictionary = task["recipe_row"]
	var success := randf() < float(r.get("success_rate", 1.0))
	var output: Dictionary = {}
	if success:
		var oid: String = r.get("output_id", "")
		var ocnt: int = int(r.get("output_count", 1))
		if oid != "":
			InventoryService.add(oid, ocnt)
			output[oid] = ocnt
	else:
		# 失败退回半数材料（GDD-05 §5.3 fail_recovery_rate=0.5）
		for mkey in [["material1_id", "material1_count"], ["material2_id", "material2_count"]]:
			var mid: String = r.get(mkey[0], "")
			var cnt: int = int(r.get(mkey[1], 0))
			if mid != "" and cnt > 0:
				InventoryService.add(mid, int(cnt * 0.5))
	alchemy_finished.emit(task["recipe_id"], success, output)
	EventBus.alchemy_task_completed.emit(task["recipe_id"], {"success": success, "output": output})
