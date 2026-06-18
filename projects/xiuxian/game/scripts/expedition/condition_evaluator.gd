# =============================================================================
# condition_evaluator.gd · 条件表达式求值（GDD-03 §2 / GDD-05 unlock_condition）
#
# 支持事件选项条件门 + 建筑解锁条件。M3 支持谓词：
#   flag('key') == 'value' / building_lv('id') >= N / disciple_count() >= N /
#   realm_max() >= N / resources_at_least('id', N) / max_disciple_skill('id') >= N
#
# M3 用简化解析（非完整表达式引擎）：识别常见谓词模式。复杂表达式 M4 升级。
# =============================================================================
class_name ConditionEvaluator
extends RefCounted


## 求值条件字符串。空 = 永真。ctx 提供 flag 上下文（可空）。
static func evaluate(expr: String, ctx: EventContext = null) -> bool:
	expr = expr.strip_edges()
	if expr == "":
		return true

	# flag('key') == 'value'
	if expr.begins_with("flag("):
		return _eval_flag(expr, ctx)
	# building_lv('id') >= N
	if expr.begins_with("building_lv("):
		return _eval_compare(expr, func(arg): return _building_lv(arg))
	# disciple_count() >= N
	if expr.begins_with("disciple_count()"):
		return _eval_compare_noarg(expr, func(): return _disciple_count())
	# realm_max() >= N
	if expr.begins_with("realm_max()"):
		return _eval_compare_noarg(expr, func(): return _realm_max())
	# resources_at_least('id', N)
	if expr.begins_with("resources_at_least("):
		return _eval_resources(expr)
	# max_disciple_skill('id') >= N
	if expr.begins_with("max_disciple_skill("):
		return _eval_compare(expr, func(arg): return _max_disciple_skill(arg))

	push_warning("[ConditionEvaluator] unrecognized expr: %s" % expr)
	return false


# -----------------------------------------------------------------------------
static func _eval_flag(expr: String, ctx: EventContext) -> bool:
	# flag('choice') == 'investigate'
	var inner := _extract_arg(expr, "flag(")
	var parts := expr.split("==")
	if parts.size() != 2 or ctx == null:
		return false
	var expected := parts[1].strip_edges().trim_prefix("'").trim_suffix("'")
	return str(ctx.flag(inner, "")) == expected


static func _eval_compare(expr: String, getter: Callable) -> bool:
	var arg := _extract_arg(expr, expr.substr(0, expr.find("(") + 1))
	var op_val := _extract_op_value(expr)
	if op_val.is_empty():
		return false
	var lhs: int = getter.call(arg)
	return _apply_op(lhs, op_val["op"], op_val["val"])


static func _eval_compare_noarg(expr: String, getter: Callable) -> bool:
	var op_val := _extract_op_value(expr)
	if op_val.is_empty():
		return false
	var lhs: int = getter.call()
	return _apply_op(lhs, op_val["op"], op_val["val"])


static func _eval_resources(expr: String) -> bool:
	# resources_at_least('spirit_stone', 600)
	var inside := expr.substr(expr.find("(") + 1, expr.rfind(")") - expr.find("(") - 1)
	var parts := inside.split(",")
	if parts.size() != 2:
		return false
	var rid := parts[0].strip_edges().trim_prefix("'").trim_suffix("'")
	var amount := int(parts[1].strip_edges())
	if Engine.get_main_loop().root.get_node_or_null("/root/InventoryService") == null:
		return false
	return InventoryService.has(rid, amount)


# -----------------------------------------------------------------------------
# 谓词实现（查 service）
# -----------------------------------------------------------------------------
static func _building_lv(building_id: String) -> int:
	if Engine.get_main_loop().root.get_node_or_null("/root/BuildingService") == null:
		return 0
	return BuildingService.get_building_level(building_id)


static func _disciple_count() -> int:
	if Engine.get_main_loop().root.get_node_or_null("/root/SectService") == null:
		return 0
	return SectService.member_count()


static func _realm_max() -> int:
	if Engine.get_main_loop().root.get_node_or_null("/root/CharacterService") == null:
		return 0
	var tiers := {"qi": 1, "foundation": 2, "golden": 3, "nascent": 4, "spirit": 5}
	var m := 0
	for c in CharacterService.all():
		var tier: String = c.realm.split("_")[0] if "_" in c.realm else c.realm
		m = max(m, tiers.get(tier, 0))
	return m


static func _max_disciple_skill(skill_id: String) -> int:
	if Engine.get_main_loop().root.get_node_or_null("/root/CharacterService") == null:
		return 0
	var m := 0
	for c in CharacterService.all():
		m = max(m, int(c.attributes.get(skill_id, 0)))
	return m


# -----------------------------------------------------------------------------
# 解析辅助
# -----------------------------------------------------------------------------
static func _extract_arg(expr: String, prefix: String) -> String:
	var start := expr.find("(") + 1
	var end := expr.find(")")
	var arg := expr.substr(start, end - start).strip_edges()
	return arg.trim_prefix("'").trim_suffix("'")


static func _extract_op_value(expr: String) -> Dictionary:
	for op in [">=", "<=", "==", ">", "<"]:
		var idx := expr.find(op)
		if idx != -1:
			return {"op": op, "val": int(expr.substr(idx + op.length()).strip_edges())}
	return {}


static func _apply_op(lhs: int, op: String, rhs: int) -> bool:
	match op:
		">=": return lhs >= rhs
		"<=": return lhs <= rhs
		"==": return lhs == rhs
		">": return lhs > rhs
		"<": return lhs < rhs
		_: return false
