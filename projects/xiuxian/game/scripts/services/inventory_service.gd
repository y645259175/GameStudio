# =============================================================================
# InventoryService.gd · 资源领域规则（autoload，GDD-06）
#
# 通过 SectService 读写 Sect.resources（不自己持有资源字段，ADR-0006 §6.9）。
# 资源类型由 data/economy/resource_types 定义；M3 配表未到位时按 key 自由增减。
# =============================================================================
extends Node


func _ready() -> void:
	print("[InventoryService] ready")


func get_amount(resource_id: String) -> int:
	return SectService.get_sect().resources.get(resource_id, 0)


func has(resource_id: String, amount: int) -> bool:
	return get_amount(resource_id) >= amount


## 多资源是否都够（cost = {resource_id: amount}）
func has_all(cost: Dictionary) -> bool:
	for rid in cost:
		if get_amount(rid) < int(cost[rid]):
			return false
	return true


func add(resource_id: String, amount: int) -> void:
	var res := SectService.get_sect().resources
	res[resource_id] = res.get(resource_id, 0) + amount
	EventBus.sect_resource_changed.emit(resource_id, res[resource_id], amount)


## 扣除单资源；不足返回 false 不扣
func consume(resource_id: String, amount: int) -> bool:
	if not has(resource_id, amount):
		return false
	add(resource_id, -amount)
	return true


## 批量扣除（原子：全够才扣）
func consume_all(cost: Dictionary) -> bool:
	if not has_all(cost):
		return false
	for rid in cost:
		add(rid, -int(cost[rid]))
	return true
