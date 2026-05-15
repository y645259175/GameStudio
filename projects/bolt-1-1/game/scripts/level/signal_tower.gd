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
	# 杆视觉
	var pole := ColorRect.new()
	pole.color = Color("#A0A0A8")  # bolt 信号塔灰金属
	pole.size = Vector2(POLE_WIDTH, POLE_HEIGHT)
	pole.position = Vector2(-POLE_WIDTH / 2.0, -POLE_HEIGHT)
	pole.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pole.name = "_PLACEHOLDER_Pole"
	add_child(pole)

	# 顶部信号球
	var ball := ColorRect.new()
	ball.color = Color("#D04030")  # 信号红
	ball.size = Vector2(16, 16)
	ball.position = Vector2(-8, -POLE_HEIGHT - 16)
	ball.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ball.name = "_PLACEHOLDER_Ball"
	add_child(ball)

	# 信号旗
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
