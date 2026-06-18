# =============================================================================
# DataRegistry.gd · 工作室通用配表运行时入口（autoload，名字 DataRegistry）
#
# 工程纪律（不可破）：
#   1. 业务代码绝不直接 load("res://data/baked/*.tres")
#   2. 业务代码绝不读 .xlsx / .csv
#   3. 所有配表查询走 DataRegistry 提供的统一 API
#   4. 启动时一次性加载所有 baked 资源到内存 Dictionary，O(1) 查询
#
# 加载顺序：
#   _ready() → 读 _manifest.json → 列出所有 baked tres → 全部 load → 索引主键
#
# Godot Project Settings → Autoload → 注册：
#   名字: DataRegistry
#   路径: res://scripts/data/data_registry.gd（res:// 根 = game/）
# =============================================================================
extends Node


# 已加载的所有表，按 table_name 索引
# data[table_name] = Array[Dictionary]   按 xlsx 顺序保留
var _tables: Dictionary = {}

# 主键索引：_pk_index[table_name][pk_value] = Dictionary（指向 _tables 中的同一个 dict）
var _pk_index: Dictionary = {}

# 已加载完毕标志
var _loaded: bool = false

# baked 资源目录（项目相对路径）
const BAKED_DIR     := "res://data/baked"
const DEBUG_DIR     := "res://data/debug"
const MANIFEST_PATH := "res://data/baked/_manifest.json"


func _ready() -> void:
	_load_all()


# -----------------------------------------------------------------------------
# 公共 API
# -----------------------------------------------------------------------------

## 取一行：DataRegistry.get_row("BuffInstance", 1) → Dictionary 或 null
func get_row(table_name: String, pkey_value: Variant) -> Variant:
	if not _loaded:
		push_error("[DataRegistry] not loaded yet, call after _ready()")
		return null
	var idx: Dictionary = _pk_index.get(table_name, {})
	# Variant key：Godot Dictionary 用 == 比较，int/string 都能精确命中
	return idx.get(pkey_value, null)


## 取整张表：DataRegistry.get_table("BuffType") → Array[Dictionary]
func get_table(table_name: String) -> Array:
	if not _loaded:
		push_error("[DataRegistry] not loaded yet")
		return []
	return _tables.get(table_name, [])


## 取一行某字段：DataRegistry.get_field("BuffInstance", 1, "buff_param1") → 20
func get_field(table_name: String, pkey_value: Variant, field: String, default: Variant = null) -> Variant:
	var row = get_row(table_name, pkey_value)
	if row == null:
		return default
	return row.get(field, default)


## 多语言文本：DataRegistry.text("Text_buff_injury_main") → "受伤"
func text(tid: String) -> String:
	if tid == "":
		return ""
	var row = get_row("TextTable", tid)
	if row == null:
		push_warning("[DataRegistry] missing tid: %s" % tid)
		return tid
	return row.get("content_cn", tid)


## 是否已加载完成（供其它 service 判断是否可安全查询）
func is_loaded() -> bool:
	return _loaded


## 调试用：列出已加载的表清单
func loaded_tables() -> Array:
	return _tables.keys()


# -----------------------------------------------------------------------------
# 内部加载
# -----------------------------------------------------------------------------

func _load_all() -> void:
	var t0 := Time.get_ticks_usec()
	_tables.clear()
	_pk_index.clear()

	var manifest := _read_manifest()
	if manifest.is_empty():
		push_error("[DataRegistry] manifest 缺失或损坏：%s（先跑 python tools/excel_convert.py）" % MANIFEST_PATH)
		return

	for entry in manifest.get("tables", []):
		var output_name: String = entry.get("output", "")
		if output_name == "":
			continue
		var res_path := "%s/%s" % [BAKED_DIR, output_name]
		var res = load(res_path)
		var data = null
		if res != null:
			data = res.get("data")
		# 回退：无 script Resource 的 data 属性在某些 Godot 版本取不到 →
		# 读同名 debug JSON（writers.py 同步产出，结构一致）
		if typeof(data) != TYPE_DICTIONARY:
			data = _load_debug_json(output_name)
		if typeof(data) != TYPE_DICTIONARY:
			push_error("[DataRegistry] %s 无法获取 data（tres + debug json 均失败）" % res_path)
			continue
		# 合并所有表
		for table_name in data.keys():
			_tables[table_name] = data[table_name]

	# 建主键索引
	# 主键字段名约定：每个表的第一个字段就是主键（与 schema.toml pkey 对齐）
	# 这里采用启发式：找该表第一行的第一个字段名作 pkey
	for table_name in _tables.keys():
		var rows: Array = _tables[table_name]
		if rows.is_empty():
			continue
		var pk_field: String = rows[0].keys()[0]  # schema 保证字段顺序，第一个就是 pkey
		var idx: Dictionary = {}
		for row in rows:
			var pk = row.get(pk_field)
			if pk != null:
				idx[pk] = row
		_pk_index[table_name] = idx

	_loaded = true
	var elapsed_us := Time.get_ticks_usec() - t0
	var total_rows := 0
	for t in _tables.values():
		total_rows += (t as Array).size()
	print("[DataRegistry] loaded %d tables, %d rows, %.2f ms" % [
		_tables.size(), total_rows, elapsed_us / 1000.0
	])


# 回退：读 data/debug/<name>.json（output_name 形如 buff_system.tres → buff_system.json）
func _load_debug_json(output_name: String) -> Variant:
	var json_name := output_name.get_basename() + ".json"
	var path := "%s/%s" % [DEBUG_DIR, json_name]
	if not FileAccess.file_exists(path):
		return null
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return null
	var txt := f.get_as_text()
	f.close()
	var json := JSON.new()
	if json.parse(txt) != OK:
		return null
	return json.data if typeof(json.data) == TYPE_DICTIONARY else null


func _read_manifest() -> Dictionary:
	if not FileAccess.file_exists(MANIFEST_PATH):
		return {}
	var f := FileAccess.open(MANIFEST_PATH, FileAccess.READ)
	if f == null:
		return {}
	var txt := f.get_as_text()
	f.close()
	var json := JSON.new()
	if json.parse(txt) != OK:
		return {}
	var d = json.data
	return d if typeof(d) == TYPE_DICTIONARY else {}
