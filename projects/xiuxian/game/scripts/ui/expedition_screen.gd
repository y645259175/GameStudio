# =============================================================================
# expedition_screen.gd · 全屏历练界面（GDD-03）
#
# 实现 ctx.ui_delegate 协议，让 EventEngine 把事件文本/选项/战斗委托给本界面，
# 玩家逐节点探索：节点地图 + 事件叙述 + 选项按钮 + 战斗结算 + 奖励展示。
#
# 由主界面"出发历练"打开（add_child 叠加层），历练结束后 emit closed 让主界面刷新。
# =============================================================================
extends Control

signal closed

const COLOR_INK := Color(0.103, 0.094, 0.078)
const COLOR_VERMILION := Color(0.66, 0.196, 0.149)
const COLOR_BRONZE := Color(0.549, 0.427, 0.247)
const COLOR_SHANQING := Color(0.29, 0.40, 0.44)
const COLOR_PAPER := Color(0.96, 0.93, 0.85)

const NODE_ICON := {
	"battle": "res://art/m3/expedition/node_battle.png",
	"treasure": "res://art/m3/expedition/node_treasure.png",
	"story": "res://art/m3/expedition/node_story.png",
	"encounter": "res://art/m3/expedition/node_story.png",
	"trial": "res://art/m3/expedition/node_treasure.png",
	"boss": "res://art/m3/expedition/node_boss.png",
}

@onready var node_map: HBoxContainer = %NodeMap
@onready var event_title: Label = %EventTitle
@onready var event_text: RichTextLabel = %EventText
@onready var enemy_portrait: TextureRect = %EnemyPortrait
@onready var option_box: VBoxContainer = %OptionBox
@onready var continue_btn: Button = %ContinueBtn
@onready var retreat_btn: Button = %RetreatBtn
@onready var party_box: VBoxContainer = %PartyBox
@onready var map_title: Label = %MapTitle

var _option_chosen := ""
var _waiting_continue := false


func _ready() -> void:
	_build_node_map()
	_build_party()
	map_title.text = "✦ %s ✦" % ExpeditionService.get_map_id()
	event_title.text = ""
	event_text.text = "[center][color=#8C6D3F]整装待发，点击「继续探索」踏入秘境……[/color][/center]"
	enemy_portrait.visible = false
	option_box.visible = false
	continue_btn.text = "继续探索 ▶"
	continue_btn.pressed.connect(_on_continue_pressed)
	retreat_btn.pressed.connect(_on_retreat_pressed)
	ExpeditionService.node_entered.connect(_on_node_entered)
	ExpeditionService.expedition_finished.connect(_on_expedition_finished)


# -----------------------------------------------------------------------------
# 节点地图（顶部进度）
# -----------------------------------------------------------------------------
func _build_node_map() -> void:
	for child in node_map.get_children():
		child.queue_free()
	var count := ExpeditionService.node_count()
	for i in range(count):
		var vb := VBoxContainer.new()
		vb.alignment = BoxContainer.ALIGNMENT_CENTER
		vb.add_theme_constant_override("separation", 2)
		var icon := TextureRect.new()
		icon.custom_minimum_size = Vector2(56, 56)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		var etype := ExpeditionService.node_event_type(i)
		var icon_path: String = NODE_ICON.get(etype, NODE_ICON["story"])
		if ResourceLoader.exists(icon_path):
			icon.texture = load(icon_path)
		icon.modulate = Color(1, 1, 1, 0.4)  # 未到达暗
		vb.add_child(icon)
		var lbl := Label.new()
		lbl.text = "%d" % (i + 1)
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.add_theme_font_size_override("font_size", 11)
		lbl.add_theme_color_override("font_color", COLOR_BRONZE)
		vb.add_child(lbl)
		node_map.add_child(vb)
		# 节点间连线
		if i < count - 1:
			var arrow := Label.new()
			arrow.text = "···"
			arrow.add_theme_color_override("font_color", COLOR_BRONZE)
			node_map.add_child(arrow)


func _highlight_node(index: int) -> void:
	var visual_idx := index * 2  # 每节点后跟一个箭头
	var children := node_map.get_children()
	if visual_idx < children.size():
		var vb := children[visual_idx]
		if vb.get_child_count() > 0:
			var icon: TextureRect = vb.get_child(0)
			icon.modulate = Color(1, 1, 1, 1.0)  # 当前节点高亮
			# 已过节点半亮
	# 已过节点设中等亮度
	for i in range(index):
		var vi := i * 2
		if vi < children.size() and children[vi].get_child_count() > 0:
			(children[vi].get_child(0) as TextureRect).modulate = Color(0.8, 0.8, 0.8, 0.85)


# -----------------------------------------------------------------------------
# 队伍侧栏
# -----------------------------------------------------------------------------
func _build_party() -> void:
	for child in party_box.get_children():
		child.queue_free()
	for cid in ExpeditionService.get_participants():
		var c: Character = CharacterService.get_character(cid)
		if c == null: continue
		var hb := HBoxContainer.new()
		hb.add_theme_constant_override("separation", 6)
		var portrait := TextureRect.new()
		portrait.custom_minimum_size = Vector2(40, 54)
		portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		if c.portrait_id != "" and ResourceLoader.exists(c.portrait_id):
			portrait.texture = load(c.portrait_id)
		hb.add_child(portrait)
		var vb := VBoxContainer.new()
		var nm := Label.new()
		nm.text = c.character_name
		nm.add_theme_color_override("font_color", COLOR_INK)
		nm.add_theme_font_size_override("font_size", 13)
		vb.add_child(nm)
		var realm_lbl := Label.new()
		realm_lbl.text = _realm_cn(c.realm)
		realm_lbl.add_theme_color_override("font_color", COLOR_SHANQING)
		realm_lbl.add_theme_font_size_override("font_size", 11)
		vb.add_child(realm_lbl)
		hb.add_child(vb)
		party_box.add_child(hb)


# -----------------------------------------------------------------------------
# 继续探索：推进下一节点
# -----------------------------------------------------------------------------
func _on_continue_pressed() -> void:
	if _waiting_continue:
		# 当前正在等待"继续"以关闭文本，恢复推进
		_waiting_continue = false
		return
	continue_btn.disabled = true
	var eid := await ExpeditionService.advance_node_ui(self)
	continue_btn.disabled = false
	if eid == "":
		# 已结束（finished 信号会处理）
		pass


func _on_retreat_pressed() -> void:
	ExpeditionService.retreat()


func _on_node_entered(node_index: int, event_id: String) -> void:
	_highlight_node(node_index)
	var title := event_id
	if DataRegistry and DataRegistry.is_loaded():
		for row in DataRegistry.get_table("EventTemplate"):
			if row.get("event_id") == event_id:
				title = row.get("title_cn", event_id)
				break
	event_title.text = "第 %d/%d 处 · %s" % [node_index + 1, ExpeditionService.node_count(), title]
	enemy_portrait.visible = false
	option_box.visible = false


# -----------------------------------------------------------------------------
# ui_delegate 协议实现（被 EventEngine await 调用）
# -----------------------------------------------------------------------------
func present_text(text: String) -> void:
	event_text.text = "[color=#1a1814]%s[/color]" % text
	# 等玩家点"继续"
	continue_btn.text = "继续 ▶"
	await _await_continue()


func present_options(option_ids: Array) -> String:
	option_box.visible = true
	for child in option_box.get_children():
		child.queue_free()
	_option_chosen = ""
	for oid in option_ids:
		var btn := Button.new()
		btn.text = _option_text(oid)
		btn.custom_minimum_size = Vector2(0, 40)
		btn.add_theme_font_size_override("font_size", 16)
		btn.pressed.connect(func(): _option_chosen = oid)
		option_box.add_child(btn)
	# 等玩家选
	while _option_chosen == "":
		await get_tree().process_frame
	option_box.visible = false
	return _option_chosen


func present_battle(enemies: Array, winner: String) -> void:
	# 显示敌人立绘
	if enemies.size() > 0:
		var e: Character = enemies[0]
		var portrait_path := _enemy_portrait(e)
		if portrait_path != "" and ResourceLoader.exists(portrait_path):
			enemy_portrait.texture = load(portrait_path)
			enemy_portrait.visible = true
	var ename: String = enemies[0].character_name if enemies.size() > 0 else "妖兽"
	var result_txt := "[color=#A93226]⚔ 与 %s 交战……[/color]\n\n" % ename
	if winner == "ATTACKERS":
		result_txt += "[color=#2d6a2d]✦ 战斗胜利！众弟子斩敌而归。[/color]"
	else:
		result_txt += "[color=#A93226]✦ 不敌强敌，负伤撤退……[/color]"
	event_text.text = result_txt
	continue_btn.text = "继续 ▶"
	await _await_continue()
	enemy_portrait.visible = false


func present_reward(resource_id: String, amount: int) -> void:
	var rname := _res_name(resource_id)
	var sign_str := "+" if amount >= 0 else ""
	var color := "#b8860b" if amount >= 0 else "#A93226"
	event_text.text += "\n[color=%s]获得 %s %s%d[/color]" % [color, rname, sign_str, amount]


func _await_continue() -> void:
	_waiting_continue = true
	while _waiting_continue:
		await get_tree().process_frame


# -----------------------------------------------------------------------------
# 历练结束
# -----------------------------------------------------------------------------
func _on_expedition_finished(reason: String) -> void:
	var msg_map := {
		"cleared": "✦ 历练圆满，满载而归 ✦",
		"timeout": "✦ 击败守关之敌，凯旋而归 ✦",
		"active": "✦ 主动撤离，平安归宗 ✦",
		"defeat": "☠ 队伍折损，狼狈撤回 ☠",
	}
	var msg: String = msg_map.get(reason, "✦ 历练结束 ✦")
	event_title.text = ""
	event_text.text = "[center][color=#A93226]%s[/color][/center]" % msg
	option_box.visible = false
	enemy_portrait.visible = false
	continue_btn.text = "返回宗门"
	# 复用 continue_btn 关闭界面
	for c in continue_btn.pressed.get_connections():
		continue_btn.pressed.disconnect(c.callable)
	continue_btn.pressed.connect(_close)
	retreat_btn.disabled = true


func _close() -> void:
	closed.emit()
	queue_free()


# -----------------------------------------------------------------------------
# 辅助
# -----------------------------------------------------------------------------
func _option_text(option_id: String) -> String:
	if DataRegistry and DataRegistry.is_loaded():
		for row in DataRegistry.get_table("EventOption"):
			if row.get("option_id") == option_id:
				return row.get("text_cn", option_id)
	return option_id


func _res_name(rid: String) -> String:
	if DataRegistry and DataRegistry.is_loaded():
		for row in DataRegistry.get_table("Resource"):
			if row.get("resource_id") == rid:
				return row.get("name_cn", rid)
	return rid


func _enemy_portrait(e: Character) -> String:
	var nm: String = e.character_name
	if "虎" in nm: return "res://art/m3/enemies/beast_tiger.png"
	if "蟾" in nm: return "res://art/m3/enemies/beast_toad.png"
	if "豹" in nm: return "res://art/m3/enemies/demon_leopard.png"
	return "res://art/m3/enemies/beast_tiger.png"


func _realm_cn(realm: String) -> String:
	var parts := realm.split("_")
	var tier: String = parts[0] if parts.size() > 0 else realm
	var lv: String = parts[1] if parts.size() > 1 else "1"
	var tier_map := {"qi": "炼气", "foundation": "筑基", "golden": "金丹", "nascent": "元婴", "spirit": "化神"}
	var tier_cn: String = tier_map.get(tier, tier)
	return "%s %s 层" % [tier_cn, lv]
