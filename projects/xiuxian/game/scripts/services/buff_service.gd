# =============================================================================
# BuffService.gd · 通用 Buff 系统（autoload，名字 BuffService）
#
# 设计依据：ADR-0005（双表注册 + IBuffable 任意实体挂载）。
#
# 双表：
#   表 A BuffType 定义表（data/buffs/buff_types）→ 大类/小类/字段 schema/handler
#   表 B BuffInstance 模板表（data/buffs/buff_instances）→ 默认数值
# M3 配表未烘焙时优雅降级：apply 走 attributes 直传仍可用；apply_by_id 需要表 B。
#
# 核心纪律：
#   - 各系统不自己造修饰器，统一走 BuffService
#   - fan-out（如 SECT buff 广播到全宗门弟子）由消费方实现，BuffService 不感知
#
# Godot Autoload：名字 BuffService，路径 res://scripts/services/buff_service.gd
#   顺序：在 EventBus 之后（订阅 TimeService.month_advanced 做 tick）
# =============================================================================
extends Node

signal buff_applied(target, buff)
signal buff_removed(target, buff, reason)
signal buff_expired(target, buff)

# 类型注册表（表 A）：subtype → Dictionary(category/applicable/schema/...)
var _buff_types: Dictionary = {}
# 模板表（表 B）：buff_id → Dictionary(type_subtype/default_attributes/duration/...)
var _buff_templates: Dictionary = {}
var _instance_counter: int = 0


func _ready() -> void:
	_load_registry()
	# 月节拍统一 tick（监听 TimeService）
	if TimeService:
		TimeService.month_advanced.connect(_on_month_advanced)
	print("[BuffService] ready (%d types, %d templates)" % [_buff_types.size(), _buff_templates.size()])


# -----------------------------------------------------------------------------
# 启动加载（配表；缺失时降级为空注册表，apply 直传仍可用）
# -----------------------------------------------------------------------------
func _load_registry() -> void:
	# M3 配表未烘焙时 DataRegistry 表为空，这里优雅降级（apply 直传仍可用）。
	# DataRegistry 未加载完（manifest 缺失或时序）时跳过，避免 push_error 噪音。
	if DataRegistry == null or not DataRegistry.is_loaded():
		return
	for row in DataRegistry.get_table("BuffType"):
		var st: String = row.get("subtype", "")
		if st != "":
			_buff_types[st] = row
	for row in DataRegistry.get_table("BuffInstance"):
		var bid: String = row.get("buff_id", "")
		if bid != "":
			_buff_templates[bid] = row


# -----------------------------------------------------------------------------
# 写操作
# -----------------------------------------------------------------------------
## 直传挂 buff（不依赖配表，M3 可用）
func apply(target: IBuffable, category: String, subtype: String, attributes: Dictionary, duration_months: int = -1, source: String = "") -> Buff:
	if target == null:
		push_error("[BuffService] apply: null target")
		return null
	var b := Buff.new(subtype, category, attributes, duration_months, source)
	_instance_counter += 1
	b.instance_id = "%s_%s_%d" % [target.target_id, subtype, _instance_counter]
	target.buffs.append(b)
	buff_applied.emit(target, b)
	return b


## 走模板表 B 挂 buff（需配表）
func apply_by_id(target: IBuffable, buff_id: String, override_attributes: Dictionary = {}) -> Buff:
	var tpl: Dictionary = _buff_templates.get(buff_id, {})
	if tpl.is_empty():
		push_error("[BuffService] apply_by_id: unknown buff_id %s (配表未加载?)" % buff_id)
		return null
	var subtype: String = tpl.get("type_subtype", "")
	var category: String = _buff_types.get(subtype, {}).get("category", "")
	var attrs: Dictionary = (tpl.get("default_attributes", {}) as Dictionary).duplicate(true)
	for k in override_attributes:
		attrs[k] = override_attributes[k]
	var dur: int = tpl.get("default_duration_months", -1)
	return apply(target, category, subtype, attrs, dur, tpl.get("source_tag", ""))


func remove(target: IBuffable, instance_id: String) -> bool:
	for i in range(target.buffs.size()):
		if target.buffs[i].instance_id == instance_id:
			var b = target.buffs[i]
			target.buffs.remove_at(i)
			buff_removed.emit(target, b, "manual")
			return true
	return false


func remove_by_subtype(target: IBuffable, category: String, subtype: String) -> int:
	var removed := 0
	for i in range(target.buffs.size() - 1, -1, -1):
		var b = target.buffs[i]
		if b.category == category and b.subtype == subtype:
			target.buffs.remove_at(i)
			buff_removed.emit(target, b, "manual")
			removed += 1
	return removed


## 按 source 移除（建筑分配解除时清理对应 modifier buff）
func remove_by_source(target: IBuffable, source_tag: String) -> int:
	if target == null:
		return 0
	var removed := 0
	for i in range(target.buffs.size() - 1, -1, -1):
		var b = target.buffs[i]
		if b.source_tag == source_tag:
			target.buffs.remove_at(i)
			buff_removed.emit(target, b, "manual")
			removed += 1
	return removed


# -----------------------------------------------------------------------------
# 查操作
# -----------------------------------------------------------------------------
func get_all(target: IBuffable) -> Array:
	return target.buffs if target else []


func get_by_category(target: IBuffable, category: String) -> Array:
	var out: Array = []
	for b in target.buffs:
		if b.category == category:
			out.append(b)
	return out


func has(target: IBuffable, category: String, subtype: String) -> bool:
	for b in target.buffs:
		if b.category == category and b.subtype == subtype:
			return true
	return false


## 累加某小类 buff 的某数值字段（如所有 qi_acceleration 的 percent 之和）
func sum_attribute(target: IBuffable, category: String, subtype: String, attr_key: String) -> float:
	var total := 0.0
	for b in target.buffs:
		if b.category == category and b.subtype == subtype:
			total += float(b.attributes.get(attr_key, 0))
	return total


## 跨小类累加某大类的某字段（重要：如所有 cultivation 类的 speed_bonus 之和）
func sum_attribute_by_category(target: IBuffable, category: String, attr_key: String) -> float:
	var total := 0.0
	for b in target.buffs:
		if b.category == category:
			total += float(b.attributes.get(attr_key, 0))
	return total


# -----------------------------------------------------------------------------
# 时间推进
# -----------------------------------------------------------------------------
## 对单个 target tick（时长递减 + 到期移除）
func tick_monthly(target: IBuffable) -> void:
	if target == null:
		return
	for i in range(target.buffs.size() - 1, -1, -1):
		var b = target.buffs[i]
		if b.tick():
			target.buffs.remove_at(i)
			buff_expired.emit(target, b)
			buff_removed.emit(target, b, "expired")


# 月节拍：对所有 character tick（M3；未来扩展 sect/map）
func _on_month_advanced(_new_month: int, _year: int, _moy: int) -> void:
	if CharacterService:
		for c in CharacterService.all():
			tick_monthly(c)
