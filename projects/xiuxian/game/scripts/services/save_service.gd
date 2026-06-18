# =============================================================================
# SaveService.gd · 存档架构（autoload，ADR-0004 五点决策）
#
# 5 点：① 版本号 save_version ② 数据分区 chunk ③ get+default 兼容
#       ④ 未知字段保留 ⑤ 模板 vs 实例分离（模板在 DataRegistry，实例在此）
#
# chunk 分区（ADR-0004 §2）：world / sect / characters / cultivation / production / settings ...
# 加新系统 = 加新 chunk key，不动现有 chunk schema。
#
# 用户特别强调（GDD-01 §6.7）：M2 必做，存档结构一次性敲定避免 M4-M5 加内容崩。
# =============================================================================
extends Node

const CURRENT_SAVE_VERSION := 1
const SAVE_DIR := "user://saves"
const GAME_VERSION := "0.2.0-m2"

signal save_completed(slot: int)
signal load_completed(slot: int)


func _ready() -> void:
	print("[SaveService] ready (save_version=%d)" % CURRENT_SAVE_VERSION)


# -----------------------------------------------------------------------------
# 收集各 service 的 chunk（模板 vs 实例分离：这里只存实例态）
# -----------------------------------------------------------------------------
func collect_save_data() -> Dictionary:
	var chunks: Dictionary = {}
	# 各 service 只贡献自己的 chunk（解耦）
	if TimeService:        chunks["world"] = TimeService.to_dict()
	if SectService:        chunks["sect"] = SectService.to_dict()
	if CharacterService:   chunks["characters"] = CharacterService.to_dict()
	# 未来：cultivation / production / expedition / main_line chunk 由各 service 贡献
	return {
		"save_version": CURRENT_SAVE_VERSION,
		"game_version": GAME_VERSION,
		"saved_at": Time.get_datetime_string_from_system(),
		"chunks": chunks,
	}


# -----------------------------------------------------------------------------
# 应用存档到各 service（5 点③ get+default：缺 chunk = 空）
# -----------------------------------------------------------------------------
func apply_save_data(data: Dictionary) -> void:
	var chunks: Dictionary = data.get("chunks", {})
	if TimeService and chunks.has("world"):
		TimeService.from_dict(chunks.get("world", {}))
	if SectService and chunks.has("sect"):
		SectService.from_dict(chunks.get("sect", {}))
	if CharacterService and chunks.has("characters"):
		CharacterService.from_dict(chunks.get("characters", {}))
	# 缺的 chunk 不报错（5 点③④）：service 各自 from_dict 用 get+default


# -----------------------------------------------------------------------------
# migration 链（5 点①）：老版本串行升级到当前版本
# -----------------------------------------------------------------------------
func _migrate(data: Dictionary) -> Dictionary:
	var v: int = data.get("save_version", 1)
	if v > CURRENT_SAVE_VERSION:
		push_error("[SaveService] 存档来自更新版本 v%d > 当前 v%d，无法加载" % [v, CURRENT_SAVE_VERSION])
		return {}
	# 未来：while v < CURRENT_SAVE_VERSION: data = MigrationVx.apply(data); v += 1
	# M2 仅 v1，无 migration
	return data


# -----------------------------------------------------------------------------
# 磁盘 IO
# -----------------------------------------------------------------------------
func save_to_slot(slot: int) -> bool:
	DirAccess.make_dir_recursive_absolute(SAVE_DIR)
	var path := "%s/save_%d.json" % [SAVE_DIR, slot]
	var data := collect_save_data()
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		push_error("[SaveService] cannot write %s" % path)
		return false
	f.store_string(JSON.stringify(data, "\t"))
	f.close()
	save_completed.emit(slot)
	EventBus.game_saved.emit(slot)
	return true


func load_from_slot(slot: int) -> bool:
	var path := "%s/save_%d.json" % [SAVE_DIR, slot]
	if not FileAccess.file_exists(path):
		push_warning("[SaveService] save slot %d not found" % slot)
		return false
	var f := FileAccess.open(path, FileAccess.READ)
	var txt := f.get_as_text()
	f.close()
	var json := JSON.new()
	if json.parse(txt) != OK:
		push_error("[SaveService] save slot %d corrupted" % slot)
		return false
	var data: Dictionary = json.data
	data = _migrate(data)
	if data.is_empty():
		return false
	apply_save_data(data)
	load_completed.emit(slot)
	EventBus.game_loaded.emit(slot)
	return true


## 内存往返测试用（不落盘）：collect → apply
func roundtrip_in_memory() -> Dictionary:
	return collect_save_data()
