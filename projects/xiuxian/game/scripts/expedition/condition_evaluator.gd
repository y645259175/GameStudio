# =============================================================================
# condition_evaluator.gd · 事件条件求值 DSL（GDD-03 §2.7）
#
# 支持：
#   字面量    'str' | 123 | true | false
#   比较      == != > < >= <=
#   逻辑      && ||
#   函数      flag('k') / expedition_flag('k') / choice()
#            realm_at_least('foundation') / attribute('fire') / has_resource('spirit_stone', 100)
#            battle_won()
#
# ctx.get_actor() 提供当前角色（境界/灵根/属性）。无 actor 时相关函数返回安全默认。
# =============================================================================
class_name ConditionEvaluator
extends RefCounted

const REALM_RANK := {"qi": 1, "foundation": 2, "golden": 3, "nascent": 4, "spirit": 5}


static func evaluate(expr: String, ctx: EventContext) -> bool:
	expr = expr.strip_edges()
	if expr == "":
		return true
	# 逻辑 OR（最低优先级）
	if "||" in expr:
		for sub in expr.split("||"):
			if evaluate(sub.strip_edges(), ctx):
				return true
		return false
	# 逻辑 AND
	if "&&" in expr:
		for sub in expr.split("&&"):
			if not evaluate(sub.strip_edges(), ctx):
				return false
		return true
	# 比较运算（注意先长后短：>= <= != == 再 > <）
	for op in [">=", "<=", "!=", "==", ">", "<"]:
		var idx: int = expr.find(op)
		if idx > 0:
			var lhs_str: String = expr.substr(0, idx).strip_edges()
			var rhs_str: String = expr.substr(idx + op.length()).strip_edges()
			var lhs: Variant = _resolve(lhs_str, ctx)
			var rhs: Variant = _resolve(rhs_str, ctx)
			return _compare(lhs, rhs, op)
	# 单值（函数/flag 真值判断）
	var single: Variant = _resolve(expr, ctx)
	if single is bool:
		return single
	if single is int or single is float:
		return single != 0
	if single is String:
		return single != ""
	return single != null


static func _compare(lhs: Variant, rhs: Variant, op: String) -> bool:
	# 数值比较：两侧都能转 float 时按数值
	var both_num: bool = (lhs is int or lhs is float) and (rhs is int or rhs is float)
	match op:
		"==":
			return lhs == rhs
		"!=":
			return lhs != rhs
		">":
			return both_num and float(lhs) > float(rhs)
		"<":
			return both_num and float(lhs) < float(rhs)
		">=":
			return both_num and float(lhs) >= float(rhs)
		"<=":
			return both_num and float(lhs) <= float(rhs)
	return false


# 解析一个 token → 值（字面量 / 函数调用 / flag）
static func _resolve(token: String, ctx: EventContext) -> Variant:
	token = token.strip_edges()
	if token == "":
		return null
	# 布尔字面量
	if token == "true":
		return true
	if token == "false":
		return false
	# 字符串字面量 'xxx'
	if token.begins_with("'") and token.ends_with("'") and token.length() >= 2:
		return token.substr(1, token.length() - 2)
	# 整数
	if token.is_valid_int():
		return int(token)
	if token.is_valid_float():
		return float(token)
	# 函数调用 name(args)
	if token.ends_with(")"):
		var paren: int = token.find("(")
		if paren > 0:
			var fname: String = token.substr(0, paren).strip_edges()
			var args_str: String = token.substr(paren + 1, token.length() - paren - 2).strip_edges()
			return _call_func(fname, args_str, ctx)
	# 裸标识符当 flag key
	return ctx.flag(token)


static func _call_func(fname: String, args_str: String, ctx: EventContext) -> Variant:
	var args: Array = _split_args(args_str)
	match fname:
		"flag":
			var k: String = _as_string(args[0]) if args.size() > 0 else ""
			return ctx.flag(k)
		"expedition_flag", "exp_flag":
			var k2: String = _as_string(args[0]) if args.size() > 0 else ""
			return ctx.expedition_flag(k2)
		"choice":
			return ctx.flag("choice")
		"battle_won":
			return ctx.flag("battle_result") == "win"
		"realm_at_least":
			return _realm_at_least(_as_string(args[0]) if args.size() > 0 else "qi", ctx)
		"attribute", "attr":
			return _attribute(_as_string(args[0]) if args.size() > 0 else "", ctx)
		"has_resource":
			var rid: String = _as_string(args[0]) if args.size() > 0 else ""
			var amt: int = int(args[1]) if args.size() > 1 else 1
			return _has_resource(rid, amt)
	return null


static func _split_args(s: String) -> Array:
	var out: Array = []
	if s.strip_edges() == "":
		return out
	for part in s.split(","):
		var p: String = part.strip_edges()
		if p.begins_with("'") and p.ends_with("'") and p.length() >= 2:
			out.append(p.substr(1, p.length() - 2))
		elif p.is_valid_int():
			out.append(int(p))
		else:
			out.append(p)
	return out


static func _as_string(v: Variant) -> String:
	return str(v)


static func _realm_at_least(tier: String, ctx: EventContext) -> bool:
	var actor: Character = ctx.get_actor()
	if actor == null:
		return false
	var actor_tier: String = actor.realm.split("_")[0] if "_" in actor.realm else actor.realm
	var need: int = REALM_RANK.get(tier, 99)
	var have: int = REALM_RANK.get(actor_tier, 0)
	return have >= need


static func _attribute(attr_name: String, ctx: EventContext) -> int:
	var actor: Character = ctx.get_actor()
	if actor == null:
		return 0
	# 灵根：fire/water/wood/metal/earth（支持 'fire' 或 'fire_root'）
	var root_key: String = attr_name.replace("_root", "")
	if actor.spirit_root.has(root_key):
		return int(actor.spirit_root.get(root_key, 0))
	# 五维属性：insight/physique/shenshi/alchemy/...
	if actor.attributes.has(attr_name):
		return int(actor.attributes.get(attr_name, 0))
	return 0


static func _has_resource(rid: String, amount: int) -> bool:
	if rid == "":
		return false
	var inv: Node = Engine.get_main_loop().root.get_node_or_null("/root/InventoryService")
	if inv == null:
		return false
	return inv.has(rid, amount)
