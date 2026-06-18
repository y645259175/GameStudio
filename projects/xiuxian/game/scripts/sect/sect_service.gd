# =============================================================================
# SectService.gd · 宗门数据唯一入口（autoload，ADR-0006）
#
# 玩家宗门唯一（player_sect_main）。子领域服务（Inventory/Building/Production）
# 通过本 service 读写 Sect 字段，不直接持有 Sect。
# =============================================================================
extends Node

var _sect: Sect = null

# 月俸（GDD-06 §5.1）：境界 → 灵石/月
const SALARY_BY_REALM := {
	"mortal": 0, "qi": 5, "foundation": 15, "golden": 50, "yuanying": 150, "huashen": 400,
}

signal salary_paid(total: int, affordable: bool)


func _ready() -> void:
	if TimeService:
		TimeService.month_advanced.connect(_on_month_advanced)
	print("[SectService] ready")


# -----------------------------------------------------------------------------
# 月俸结算（GDD-05 §4 / GDD-06 §5.2）：每月扣灵石；M3 不足不流失，仅警告
# -----------------------------------------------------------------------------
func _on_month_advanced(_m: int, _y: int, _moy: int) -> void:
	var total := monthly_salary_total()
	if total <= 0:
		return
	var affordable: bool = InventoryService.has("spirit_stone", total)
	if affordable:
		InventoryService.consume("spirit_stone", total)
	else:
		# M3：欠俸不流失，灵石扣到 0（不转负），UI 红字由监听方处理
		var have: int = InventoryService.get_amount("spirit_stone")
		if have > 0:
			InventoryService.consume("spirit_stone", have)
	salary_paid.emit(total, affordable)


func monthly_salary_total() -> int:
	var total := 0
	for cid in get_member_ids():
		var c: Character = CharacterService.get_character(cid)
		if c == null or c.action_state == Character.ActionState.DEAD:
			continue
		var tier: String = c.realm.split("_")[0] if "_" in c.realm else c.realm
		total += SALARY_BY_REALM.get(tier, 0)
	return total


func get_sect() -> Sect:
	if _sect == null:
		_sect = Sect.new()
	return _sect


func init_new_sect(sect_name: String, founded_month: int = 1) -> Sect:
	_sect = Sect.new()
	_sect.sect_name = sect_name
	_sect.founded_at_month = founded_month
	return _sect


# 成员管理
func add_member(character_id: String) -> void:
	var s := get_sect()
	if not s.member_ids.has(character_id):
		s.member_ids.append(character_id)


func remove_member(character_id: String) -> void:
	get_sect().member_ids.erase(character_id)


func get_member_ids() -> Array:
	return get_sect().member_ids


func member_count() -> int:
	return get_sect().member_ids.size()


# 声望
func change_reputation(delta: float) -> void:
	get_sect().reputation += delta


func get_reputation() -> float:
	return get_sect().reputation


# 序列化
func to_dict() -> Dictionary:
	return get_sect().to_dict()


func from_dict(d: Dictionary) -> void:
	_sect = Sect.from_dict(d)
