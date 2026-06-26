# =============================================================================
# EventEngine.gd · 历练事件引擎（autoload，GDD-03 §2 §3）
#
# 数据驱动：事件 = action 序列（order 排序 + condition 门 = 三幕语义）。
# 选项 DSL：选项含成本(灵石/时间/血)/显示条件/启用条件/后果，详见 §3。
#
# 双入口共享同一批辅助函数（_build_options / _apply_cost / _do_battle）：
#   resolve_event()     —— SYNC，headless/测试/派遣拟合用（选项自动选第一个可选）
#   resolve_event_ui()  —— ASYNC，玩家亲历用（阻塞型 action 委托 UI 并 await）
# =============================================================================
extends Node

var _handlers: Dictionary = {}


func _ready() -> void:
	_register_builtin_handlers()
	print("[EventEngine] ready (%d action handlers)" % _handlers.size())


func register_handler(action_type: String, handler: ActionHandler) -> void:
	_handlers[action_type] = handler


func has_handler(action_type: String) -> bool:
	return _handlers.has(action_type)


func registered_action_types() -> Array:
	return _handlers.keys()


# -----------------------------------------------------------------------------
# SYNC 入口（headless / 测试 / 派遣拟合）：选项自动选第一个可选项
# -----------------------------------------------------------------------------
func resolve_event(event_id: String, participant_ids: Array = []) -> EventContext:
	var ctx := EventContext.new()
	ctx.event_id = event_id
	ctx.participant_ids = participant_ids
	var actions := _load_event_actions(event_id)
	for action in actions:
		if ctx.aborted: break
		if not ConditionEvaluator.evaluate(action.get("condition", ""), ctx): continue
		_exec_sync(action, ctx)
	return ctx


func _exec_sync(action: Dictionary, ctx: EventContext) -> void:
	var atype: String = action.get("action_type", "")
	match atype:
		"show_options":
			var opts := _build_options(action, ctx)
			var chosen: String = ""
			for o in opts:
				if o.get("enabled", false):
					chosen = o.get("id", "")
					break
			if chosen == "" and opts.size() > 0:
				chosen = opts[0].get("id", "")
			if chosen != "":
				_apply_option_cost(chosen, ctx)
				ctx.set_flag("choice", chosen)
		"start_battle":
			_do_battle(action, ctx)
		_:
			var handler: ActionHandler = _handlers.get(atype, null)
			if handler != null:
				handler.execute(action, ctx)


# -----------------------------------------------------------------------------
# ASYNC 入口（玩家亲历 UI 模式）
# -----------------------------------------------------------------------------
func resolve_event_ui(event_id: String, participant_ids: Array, ui_delegate: Object) -> EventContext:
	var ctx := EventContext.new()
	ctx.event_id = event_id
	ctx.participant_ids = participant_ids
	ctx.ui_delegate = ui_delegate

	var actions := _load_event_actions(event_id)
	for action in actions:
		if ctx.aborted: break
		if not ConditionEvaluator.evaluate(action.get("condition", ""), ctx): continue
		var atype: String = action.get("action_type", "")
		match atype:
			"show_text":
				await _ui_show_text(action, ctx)
			"show_options":
				await _ui_show_options(action, ctx)
			"start_battle":
				await _ui_start_battle(action, ctx)
			"give_resource":
				_ui_give_resource(action, ctx)
			_:
				var handler: ActionHandler = _handlers.get(atype, null)
				if handler != null:
					handler.execute(action, ctx)
	return ctx


func _ui_show_text(action: Dictionary, ctx: EventContext) -> void:
	var txt: String = action.get("param1", "")
	ctx.set_flag("last_text", txt)
	if ctx.has_ui() and ctx.ui_delegate.has_method("present_text"):
		await ctx.ui_delegate.present_text(txt)


func _ui_show_options(action: Dictionary, ctx: EventContext) -> void:
	var opts := _build_options(action, ctx)
	if opts.is_empty():
		return
	var chosen: String = ""
	if ctx.has_ui() and ctx.ui_delegate.has_method("present_options"):
		chosen = await ctx.ui_delegate.present_options(opts)
	if chosen == "":
		# 兜底：第一个可选
		for o in opts:
			if o.get("enabled", false):
				chosen = o.get("id", "")
				break
	if chosen != "":
		_apply_option_cost(chosen, ctx)
		ctx.set_flag("choice", chosen)


func _ui_give_resource(action: Dictionary, ctx: EventContext) -> void:
	var rid: String = action.get("param1", "")
	var amount: int = int(action.get("param2", 0))
	if rid != "":
		InventoryService.add(rid, amount)
		if ctx.has_ui() and ctx.ui_delegate.has_method("present_reward"):
			ctx.ui_delegate.present_reward(rid, amount)


func _ui_start_battle(action: Dictionary, ctx: EventContext) -> void:
	var enemies := _do_battle(action, ctx)
	var winner: String = "ATTACKERS" if ctx.flag("battle_result", "") == "win" else "DEFENDERS"
	if ctx.has_ui() and ctx.ui_delegate.has_method("present_battle"):
		await ctx.ui_delegate.present_battle(enemies, winner)


# -----------------------------------------------------------------------------
# 共享辅助：选项构建（含 cond_show 过滤 + enabled 计算 + 成本文案）
# 返回 Array[Dictionary]：{id,text,desc,enabled,reason,cost_text}
# -----------------------------------------------------------------------------
func _build_options(action: Dictionary, ctx: EventContext) -> Array:
	var opt_ids: Array = []
	for i in [1, 2, 3, 4]:
		var oid: String = action.get("param%d" % i, "")
		if oid != "": opt_ids.append(oid)
	var out: Array = []
	for oid in opt_ids:
		var row := _option_row(oid)
		if row.is_empty():
			out.append({"id": oid, "text": oid, "desc": "", "enabled": true, "reason": "", "cost_text": ""})
			continue
		# 显示条件
		var cond_show: String = str(row.get("cond_show", ""))
		if cond_show != "" and not ConditionEvaluator.evaluate(cond_show, ctx):
			continue
		# 启用条件 + 成本可负担
		var enabled := true
		var reason := ""
		var cond_enable: String = str(row.get("cond_enable", ""))
		if cond_enable != "" and not ConditionEvaluator.evaluate(cond_enable, ctx):
			enabled = false
			reason = str(row.get("cond_enable_hint", "条件不足"))
		var cost_stone: int = int(row.get("cost_stone", 0))
		if cost_stone > 0 and not InventoryService.has("spirit_stone", cost_stone):
			enabled = false
			if reason == "": reason = "灵石不足"
		out.append({
			"id": oid,
			"text": str(row.get("text_cn", oid)),
			"desc": str(row.get("desc_cn", "")),
			"enabled": enabled,
			"reason": reason,
			"cost_text": _cost_text(row),
		})
	return out


func _cost_text(row: Dictionary) -> String:
	var parts: Array = []
	var cs: int = int(row.get("cost_stone", 0))
	if cs > 0: parts.append("灵石-%d" % cs)
	var ct: int = int(row.get("cost_time", 0))
	if ct > 0: parts.append("耗时%d%%" % ct)
	var ch: int = int(row.get("cost_hp", 0))
	if ch > 0: parts.append("气血-%d" % ch)
	return "  （%s）" % "、".join(parts) if parts.size() > 0 else ""


func _apply_option_cost(option_id: String, ctx: EventContext) -> void:
	var row := _option_row(option_id)
	if row.is_empty(): return
	var cs: int = int(row.get("cost_stone", 0))
	if cs > 0: InventoryService.consume("spirit_stone", cs)
	# 时间/气血成本 M3 记录到 flag（内层时钟/受伤系统接入后生效）
	var ct: int = int(row.get("cost_time", 0))
	if ct > 0: ctx.set_flag("time_spent", int(ctx.flag("time_spent", 0)) + ct)
	# 选项后果 flag
	var of: String = str(row.get("outcome_flag", ""))
	if of != "":
		ctx.set_flag(of, str(row.get("outcome_value", "1")))


func _option_row(option_id: String) -> Dictionary:
	if DataRegistry == null or not DataRegistry.is_loaded(): return {}
	for row in DataRegistry.get_table("EventOption"):
		if row.get("option_id") == option_id:
			return row
	return {}


# -----------------------------------------------------------------------------
# 共享辅助：战斗（构造敌人 + resolve + 写 battle_result flag）。返回 enemies
# -----------------------------------------------------------------------------
func _do_battle(action: Dictionary, ctx: EventContext) -> Array:
	var chosen: String = ctx.flag("choice", "")
	var enemy_realm := "qi"
	var enemy_count := 1
	if chosen != "":
		var orow := _option_row(chosen)
		if not orow.is_empty():
			if orow.get("battle_enemy_realm", "") != "": enemy_realm = orow.get("battle_enemy_realm")
			if int(orow.get("battle_enemy_count", 0)) > 0: enemy_count = int(orow.get("battle_enemy_count"))
	if str(action.get("param1", "")) != "": enemy_realm = str(action.get("param1"))
	if str(action.get("param2", "")) != "": enemy_count = int(action.get("param2"))
	var enemies: Array = []
	for i in range(enemy_count):
		var e := Character.new("exp_enemy_%d_%d" % [Time.get_ticks_msec(), i])
		e.identity = Character.Identity.NON_SECT
		e.character_name = EventHelpers.enemy_name(enemy_realm)
		e.realm = "%s_3" % enemy_realm
		e.sub_level = 3
		e.spirit_root = {"fire": 3 + randi() % 4}
		e.attributes = {"insight": 80}
		enemies.append(e)
	var attackers: Array[Character] = []
	for cid in ctx.participant_ids:
		var c: Character = CharacterService.get_character(cid)
		if c != null: attackers.append(c)
	if attackers.is_empty():
		ctx.set_flag("battle_result", "lose")
		return enemies
	var bctx := BattleContext.new()
	bctx.attackers = attackers
	bctx.defenders = enemies
	bctx.trigger_source = "expedition_event"
	bctx.seed = randi()
	var result := BattleService.resolve(bctx)
	ctx.set_flag("battle_result", "win" if result.winner == "ATTACKERS" else "lose")
	return enemies


func _load_event_actions(event_id: String) -> Array:
	if DataRegistry == null or not DataRegistry.is_loaded(): return []
	var out: Array = []
	for row in DataRegistry.get_table("EventAction"):
		if row.get("event_id") == event_id: out.append(row)
	out.sort_custom(func(a, b): return a.get("order", 0) < b.get("order", 0))
	return out


# -----------------------------------------------------------------------------
# 内置 handler（非阻塞型 action）
# -----------------------------------------------------------------------------
func _register_builtin_handlers() -> void:
	register_handler("show_text", ShowTextHandler.new())
	register_handler("give_loot", GiveLootHandler.new())
	register_handler("give_resource", GiveResourceHandler.new())
	register_handler("set_flag", SetFlagHandler.new())
	register_handler("show_options", ShowOptionsHandler.new())
	register_handler("start_battle", StartBattleHandler.new())
	register_handler("random_branch", RandomBranchHandler.new())
	register_handler("extraction", ExtractionHandler.new())


class ShowTextHandler extends ActionHandler:
	func execute(action: Dictionary, ctx: EventContext) -> void:
		ctx.set_flag("last_text", action.get("param1", ""))
		EventHelpers.emit_log(ctx, action.get("param1", ""))


class GiveLootHandler extends ActionHandler:
	func execute(action: Dictionary, ctx: EventContext) -> void:
		ctx.set_flag("last_loot", {action.get("param1", ""): 1})


class GiveResourceHandler extends ActionHandler:
	func execute(action: Dictionary, _ctx: EventContext) -> void:
		var rid: String = action.get("param1", "")
		var amount: int = int(action.get("param2", 0))
		if rid != "" and Engine.get_main_loop().root.get_node_or_null("/root/InventoryService"):
			InventoryService.add(rid, amount)


class SetFlagHandler extends ActionHandler:
	func execute(action: Dictionary, ctx: EventContext) -> void:
		ctx.set_flag(action.get("param1", ""), action.get("param2", ""))


class ShowOptionsHandler extends ActionHandler:
	func execute(action: Dictionary, ctx: EventContext) -> void:
		# sync 兜底（仅在被 handler 表直接调用时；正常走 _exec_sync）
		var chosen: String = action.get("param1", "")
		ctx.set_flag("choice", chosen)


class RandomBranchHandler extends ActionHandler:
	func execute(action: Dictionary, ctx: EventContext) -> void:
		var opts: Array = []
		for i in [1, 2, 3, 4]:
			var oid: String = action.get("param%d" % i, "")
			if oid != "": opts.append(oid)
		if opts.size() == 0: return
		var chosen: String = opts[randi() % opts.size()]
		ctx.set_flag("choice", chosen)


class StartBattleHandler extends ActionHandler:
	func execute(_action: Dictionary, ctx: EventContext) -> void:
		# sync 兜底；正常走 _exec_sync 的 _do_battle
		ctx.set_flag("battle_result", "win")


class ExtractionHandler extends ActionHandler:
	func execute(_action: Dictionary, ctx: EventContext) -> void:
		ctx.set_flag("expedition_complete", true)
		EventHelpers.emit_log(ctx, "✦ 历练结束 ✦")
