# =============================================================================
# GameManager.gd · 游戏流程总控（autoload）
#
# 职责：新游戏初始化 / 读档 / 游戏结束判定（GDD-02 §2.7 全员陨落）。
# 让主菜单与主界面共用同一套流程入口，不各写一份。
#
# 场景切换：主菜单 ↔ 主界面 由本管理器统一 change_scene。
# =============================================================================
extends Node

const SCENE_MAIN_MENU := "res://scenes/main_menu.tscn"
const SCENE_MAIN := "res://scenes/main_screen.tscn"
const SCENE_GAME_OVER := "res://scenes/game_over.tscn"

# 起始数据（GDD-05 开局配置）
const START_SPIRIT_STONE := 2000
const START_SPIRIT_HERB := 50

var _game_over_emitted := false


func _ready() -> void:
	if EventBus:
		EventBus.character_died.connect(_on_character_died)
	print("[GameManager] ready")


# -----------------------------------------------------------------------------
# 新游戏：重置所有 service 状态 + 初始化世界
# -----------------------------------------------------------------------------
func start_new_game() -> void:
	_reset_all_services()
	_init_world()
	_game_over_emitted = false
	get_tree().change_scene_to_file(SCENE_MAIN)


func continue_game() -> bool:
	# 读最近存档（slot 0）
	if not SaveService.load_from_slot(0):
		return false
	_game_over_emitted = false
	get_tree().change_scene_to_file(SCENE_MAIN)
	return true


func has_save() -> bool:
	return FileAccess.file_exists("%s/save_0.json" % SaveService.SAVE_DIR)


func to_main_menu() -> void:
	get_tree().change_scene_to_file(SCENE_MAIN_MENU)


func quit_game() -> void:
	get_tree().quit()


# -----------------------------------------------------------------------------
# 重置所有 service（重开新档时清空内存态）
# -----------------------------------------------------------------------------
func _reset_all_services() -> void:
	# CharacterService 清角色
	CharacterService.from_dict({})
	# SectService 重置
	SectService.init_new_sect("青云宗", 1)
	# TimeService 归零
	TimeService.from_dict({"current_month": 1})


# -----------------------------------------------------------------------------
# 世界初始化（GDD-05 开局：预建建筑 + 门主 + 起始弟子）
# -----------------------------------------------------------------------------
func _init_world() -> void:
	InventoryService.add("spirit_stone", START_SPIRIT_STONE)
	InventoryService.add("spirit_herb", START_SPIRIT_HERB)
	# 预建建筑（GDD-05 §3.2 is_predefined + 修炼塔开局可玩）
	BuildingService.predefine_building("slot_main_hall", "main_hall", 1)
	BuildingService.predefine_building("slot_disciple_dorm", "disciple_dorm", 1)
	BuildingService.predefine_building("slot_cultivation_tower", "cultivation_tower", 1)

	# 门主
	var master := CharacterService.create("char_master")
	master.character_name = "云一道人"
	master.identity = Character.Identity.MASTER_CURRENT
	master.realm = "golden_3"
	master.sub_level = 3
	master.portrait_id = "res://art/m3/portraits/master_portrait.png"
	master.spirit_root = {"fire": 7, "metal": 5}
	master.attributes = {"insight": 130, "physique": 80, "shenshi": 90, "experience": 0.0}
	master.lifespan_total_months = 1200
	master.lifespan_remaining_months = 800
	SectService.add_member("char_master")

	# 起始 2 弟子
	var disciple_data := [
		{"name": "林清雪", "realm": "qi_1", "sub": 1, "roots": {"water": 6, "wood": 4}, "insight": 110,
			"portrait": "res://art/m3/portraits/disciple_female.png"},
		{"name": "苏长风", "realm": "qi_2", "sub": 2, "roots": {"fire": 5, "metal": 3}, "insight": 105,
			"portrait": "res://art/m3/portraits/disciple_male.png"},
	]
	for i in range(disciple_data.size()):
		var did := "char_disciple_%d" % (i + 1)
		var d := CharacterService.create(did)
		var data: Dictionary = disciple_data[i]
		d.identity = Character.Identity.DISCIPLE
		d.character_name = data["name"]
		d.realm = data["realm"]
		d.sub_level = data["sub"]
		d.portrait_id = data["portrait"]
		d.spirit_root = data["roots"]
		d.attributes = {"insight": data["insight"], "physique": 50, "shenshi": 60, "experience": 0.0}
		d.lifespan_total_months = 720
		d.lifespan_remaining_months = 720
		SectService.add_member(did)


# -----------------------------------------------------------------------------
# 游戏结束判定（GDD-02 §2.7：宗门所有成员陨落 → GameOver）
# -----------------------------------------------------------------------------
func _on_character_died(_cid: String, _cause: String) -> void:
	if _game_over_emitted:
		return
	if _is_all_members_dead():
		_game_over_emitted = true
		EventBus.game_over.emit("all_members_dead")


func _is_all_members_dead() -> bool:
	var ids: Array = SectService.get_member_ids()
	if ids.is_empty():
		return false
	for cid in ids:
		var c: Character = CharacterService.get_character(cid)
		if c != null and c.action_state != Character.ActionState.DEAD:
			return false
	return true
