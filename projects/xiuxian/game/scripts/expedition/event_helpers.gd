class_name EventHelpers
extends RefCounted
static func option_text(option_id: String) -> String:
	if option_id == "" or not DataRegistry or not DataRegistry.is_loaded(): return option_id
	for row in DataRegistry.get_table("EventOption"):
		if row.get("option_id") == option_id:
			return row.get("text_cn", option_id)
	return option_id


static func enemy_name(realm: String) -> String:
	var tier := realm.split("_")[0] if "_" in realm else realm
	var pool := {
		"qi": ["石魔猿", "赤鬃灵虎", "妖藤精"],
		"foundation": ["碧鳞蟾蜍", "黑风鸦", "岩甲龟"],
		"golden": ["金瞳妖豹", "幽冥蛇", "铁爪巨鹰"],
	}
	var names: Array = pool.get(tier, ["妖兽"])
	return names[randi() % names.size()]


static func emit_log(ctx: EventContext, msg: String) -> void:
	if Engine.get_main_loop():
		EventBus.world_event_triggered.emit("event_log", {"event_id": ctx.event_id, "msg": msg})
