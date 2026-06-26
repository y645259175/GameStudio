# =============================================================================
# EventEngine.gd · 历练事件引擎（autoload，GDD-03 §2）
#
# 数据驱动：事件 = action 序列；引擎按 action_type 查 handler 表分发。
# 辅助函数在 event_helpers.gd（内部类 extends ActionHandler 无法直接调父脚本 static func）。
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
# resolve_event —— 核心入口（headless / 测试：一次跑完，show_options 自动选 param1）
# -----------------------------------------------------------------------------
func resolve_event(event_id: String, participant_ids: Array = []) -> EventContext:
	var ctx := EventContext.new()
	ctx.event_id = event_id
	ctx.participant_ids = participant_ids
	_run_actions_sync(ctx)
	return ctx


func _run_actions_sync(ctx: EventContext) -> void:
	var actions := _load_event_actions(ctx.event_id)
	for action in actions:
		if ctx.aborted: break
		var cond: String = action.get("condition", "")
		if not ConditionEvaluator.evaluate(cond, ctx): continue
		var atype: String = action.get("action_type", "")
		var handler: ActionHandler = _handlers.get(atype, null)
		if handler == null:
			push_warning("[EventEngine] no handler for '%s' (event %s)" % [atype, ctx.event_id])
			continue
		handler.execute(action, ctx)


# -----------------------------------------------------------------------------
# resolve_event_ui —— UI 模式（分步执行，show_options / show_text / start_battle
# 委托给 ctx.ui_delegate 并 await 玩家交互）。返回 EventContext。
# -----------------------------------------------------------------------------
func resolve_event_ui(event_id: String, participant_ids: Array, ui_delegate: Object) -> EventContext:
	var ctx := EventContext.new()
	ctx.event_id = event_id
	ctx.participant_ids = participant_ids
	ctx.ui_delegate = ui_delegate

	var actions := _load_event_actions(event_id)
	for action in actions:
		if ctx.aborted: break
		var cond: String = action.get("condition", "")
		if not ConditionEvaluator.evaluate(cond, ctx): continue
		var atype: String = action.get("action_type", "")
		var handler: ActionHandler = _handlers.get(atype, null)
		if handler == null:
			continue
		# 交互型 action 走 await 分支
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
				handler.execute(action, ctx)
	return ctx


func _ui_show_text(action: Dictionary, ctx: EventContext) -> void:
	var txt: String = action.get("param1", "")
	ctx.set_flag("last_text", txt)
	if ctx.has_ui() and ctx.ui_delegate.has_method("present_text"):
		await ctx.ui_delegate.present_text(txt)


func _ui_show_options(action: Dictionary, ctx: EventContext) -> void:
	# 收集选项 id（param1..4 是 option_id）
	var opt_ids: Array = []
	for i in [1, 2, 3, 4]:
		var oid: String = action.get("param%d" % i, "")
		if oid != "": opt_ids.append(oid)
	if opt_ids.is_empty():
		return
	var chosen: String = opt_ids[0]
	if ctx.has_ui() and ctx.ui_delegate.has_method("present_options"):
		chosen = await ctx.ui_delegate.present_options(opt_ids)
	ctx.set_flag("choice", chosen)


func _ui_give_resource(action: Dictionary, ctx: EventContext) -> void:
	var rid: String = action.get("param1", "")
	var amount: int = int(action.get("param2", 0))
	if rid != "":
		InventoryService.add(rid, amount)
		if ctx.has_ui() and ctx.ui_delegate.has_method("present_reward"):
			ctx.ui_delegate.present_reward(rid, amount)


func _ui_start_battle(action: Dictionary, ctx: EventContext) -> void:
	var chosen: String = ctx.flag("choice", "")
	var enemy_realm := "qi"
	var enemy_count := 1
	if chosen != "" and DataRegistry and DataRegistry.is_loaded():
		for row in DataRegistry.get_table("EventOption"):
			if row.get("option_id") == chosen:
				enemy_realm = row.get("battle_enemy_realm", "qi")
				enemy_count = max(1, int(row.get("battle_enemy_count", 1)))
				break
	if action.get("param1", "") != "": enemy_realm = action["param1"]
	if action.get("param2", "") != "": enemy_count = int(action["param2"])
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
	if attackers.is_empty(): return
	var bctx := BattleContext.new()
	bctx.attackers = attackers; bctx.defenders = enemies
	bctx.trigger_source = "expedition_event"; bctx.seed = randi()
	var result := BattleService.resolve(bctx)
	var winner: String = result.winner
	ctx.set_flag("battle_result", "win" if winner == "ATTACKERS" else "lose")
	if ctx.has_ui() and ctx.ui_delegate.has_method("present_battle"):
		await ctx.ui_delegate.present_battle(enemies, winner)


func _load_event_actions(event_id: String) -> Array:
	if DataRegistry == null or not DataRegistry.is_loaded(): return []
	var out: Array = []
	for row in DataRegistry.get_table("EventAction"):
		if row.get("event_id") == event_id: out.append(row)
	out.sort_custom(func(a, b): return a.get("order", 0) < b.get("order", 0))
	return out


# -----------------------------------------------------------------------------
# 内置 handler 注册
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


# -----------------------------------------------------------------------------
# 内置 handler 实现（全部通过 EventHelpers 调辅助）
# -----------------------------------------------------------------------------
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


# --- show_options：headless 自动取 param1 ---
class ShowOptionsHandler extends ActionHandler:
	func execute(action: Dictionary, ctx: EventContext) -> void:
		var chosen: String = action.get("param1", "")
		ctx.set_flag("choice", chosen)
		EventHelpers.emit_log(ctx, ">>> 选择：%s" % EventHelpers.option_text(chosen))


class RandomBranchHandler extends ActionHandler:
	func execute(action: Dictionary, ctx: EventContext) -> void:
		var opts: Array = []
		for i in [1, 2, 3, 4]:
			var oid: String = action.get("param%d" % i, "")
			if oid != "": opts.append(oid)
		if opts.size() == 0: return
		var chosen: String = opts[randi() % opts.size()]
		ctx.set_flag("choice", chosen)
		EventHelpers.emit_log(ctx, ">>> 随机：%s" % EventHelpers.option_text(chosen))


# --- start_battle ---
class StartBattleHandler extends ActionHandler:
	func execute(_action: Dictionary, ctx: EventContext) -> void:
		var chosen: String = ctx.flag("choice", "")
		var enemy_realm := "qi"
		var enemy_count := 1
		if chosen != "" and DataRegistry and DataRegistry.is_loaded():
			for row in DataRegistry.get_table("EventOption"):
				if row.get("option_id") == chosen:
					enemy_realm = row.get("battle_enemy_realm", "qi")
					enemy_count = max(1, int(row.get("battle_enemy_count", 1)))
					break
		if _action.get("param1", "") != "": enemy_realm = _action["param1"]
		if _action.get("param2", "") != "": enemy_count = int(_action["param2"])
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
		if attackers.size() == 0: return
		var bctx := BattleContext.new()
		bctx.attackers = attackers; bctx.defenders = enemies
		bctx.trigger_source = "expedition_event"; bctx.seed = randi()
		var result := BattleService.resolve(bctx)
		ctx.set_flag("battle_result", "win" if result.winner == "ATTACKERS" else "lose")
		EventHelpers.emit_log(ctx, "⚔ 战斗胜利！" if result.winner == "ATTACKERS" else "⚔ 败退...")


# --- extraction ---
class ExtractionHandler extends ActionHandler:
	func execute(_action: Dictionary, ctx: EventContext) -> void:
		ctx.set_flag("expedition_complete", true)
		EventHelpers.emit_log(ctx, "✦ 历练结束 ✦")
