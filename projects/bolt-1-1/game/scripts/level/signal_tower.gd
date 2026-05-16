extends Node2D
class_name SignalTower

## SignalTower · 原 Flagpole
## 玩家触杆即触发通关流程，按高度 5 段计分
## 修复 BL-003: 改用 _physics_process 距离检测（Area2D 在自动化场景偶发不触发）

const POLE_HEIGHT: float = 176.0
const POLE_WIDTH: float = 16.0
const TRIGGER_RADIUS: float = 24.0

var _triggered: bool = false


func _ready() -> void:
	# M6 BL-015：用真实贴图（一张完整 signal tower），fallback 三段 ColorRect
	if ResourceLoader.exists("res://assets/signal_tower.png"):
		var tex := load("res://assets/signal_tower.png") as Texture2D
		if tex:
			var sprite := Sprite2D.new()
			sprite.texture = tex
			sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			# 资产是 48×192，目标显示尺寸：宽 48、高 POLE_HEIGHT+16=192（含杆 + 顶球 + 旗）
			var display_w: float = 48.0
			var display_h: float = POLE_HEIGHT + 16.0
			var src := tex.get_size()
			if src.x > 0 and src.y > 0:
				sprite.scale = Vector2(display_w / src.x, display_h / src.y)
			# 锚点：贴图中心 = sprite 中心 → 放到杆中央（origin 是杆底，向上偏 display_h/2）
			sprite.position = Vector2(0, -display_h / 2.0)
			sprite.name = "Sprite"
			add_child(sprite)
			return
	# fallback 三段 ColorRect 占位
	var pole := ColorRect.new()
	pole.color = Color("#A0A0A8")
	pole.size = Vector2(POLE_WIDTH, POLE_HEIGHT)
	pole.position = Vector2(-POLE_WIDTH / 2.0, -POLE_HEIGHT)
	pole.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pole.name = "_PLACEHOLDER_Pole"
	add_child(pole)

	var ball := ColorRect.new()
	ball.color = Color("#D04030")
	ball.size = Vector2(16, 16)
	ball.position = Vector2(-8, -POLE_HEIGHT - 16)
	ball.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ball.name = "_PLACEHOLDER_Ball"
	add_child(ball)

	var flag := ColorRect.new()
	flag.color = Color("#D04030")
	flag.size = Vector2(16, 12)
	flag.position = Vector2(POLE_WIDTH / 2.0, -POLE_HEIGHT + 8)
	flag.mouse_filter = Control.MOUSE_FILTER_IGNORE
	flag.name = "_PLACEHOLDER_Flag"
	add_child(flag)


func _physics_process(_delta: float) -> void:
	if _triggered:
		return
	var players := get_tree().get_nodes_in_group("player")
	if players.size() == 0:
		return
	var player := players[0] as Node2D
	if absf(player.global_position.x - global_position.x) < TRIGGER_RADIUS:
		var pole_top: float = global_position.y - POLE_HEIGHT
		var pole_bottom: float = global_position.y
		if player.global_position.y > pole_top - 16 and player.global_position.y < pole_bottom + 16:
			_trigger(player)


func _trigger(player: Node2D) -> void:
	if _triggered:
		return
	_triggered = true
	var pole_top: float = global_position.y - POLE_HEIGHT
	var pole_bottom: float = global_position.y
	var p_y: float = player.global_position.y
	var t: float = clamp((pole_bottom - p_y) / POLE_HEIGHT, 0.0, 1.0)
	var score: int
	if t >= 1.0:
		score = 5000
	elif t >= 0.7:
		score = 4000
	elif t >= 0.4:
		score = 2000
	elif t >= 0.1:
		score = 800
	else:
		score = 100
	GameManager.add_score(score)
	GameManager.current_state = "clear"
	print("[SignalTower] activated at height %f, score=%d" % [t, score])
	var main := get_tree().get_root().get_node_or_null("Main")
	if main and main.has_method("on_signal_tower_touched"):
		main.on_signal_tower_touched(player, self, t)
