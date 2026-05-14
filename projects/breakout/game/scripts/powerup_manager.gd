extends Node

## 道具管理器
## 负责道具掉落概率、生成、效果应用、计时回滚

const POWERUP_SCENE: PackedScene = preload("res://scenes/powerup.tscn")
const MAX_POWERUPS_PER_RUN: int = 6
const WEIGHTS: Dictionary = {
	"wide_paddle": 25,
	"narrow_paddle": 15,
	"speed_ball": 20,
	"multi_ball": 20,
	"extra_life": 20,
}

var powerups_dropped_this_run: int = 0
var active_timers: Dictionary = {}  # powerup_type -> Timer (用于持续效果回滚)

# 持续效果默认时长（秒）
const DURATIONS: Dictionary = {
	"wide_paddle": 10.0,
	"narrow_paddle": 10.0,
	"speed_ball": 8.0,
}


func reset_run() -> void:
	powerups_dropped_this_run = 0
	for t in active_timers.values():
		if is_instance_valid(t):
			t.queue_free()
	active_timers.clear()


func should_drop(brick_drop_rate: float) -> bool:
	if powerups_dropped_this_run >= MAX_POWERUPS_PER_RUN:
		return false
	return randf() < brick_drop_rate


func spawn_at(pos: Vector2, parent: Node) -> Node:
	var p_type := _roll_type()
	var powerup := POWERUP_SCENE.instantiate()
	powerup.position = pos
	parent.add_child(powerup)
	powerup.setup(p_type)
	powerups_dropped_this_run += 1
	return powerup


func _roll_type() -> String:
	var total := 0
	for w in WEIGHTS.values():
		total += int(w)
	var r := randi_range(1, total)
	var acc := 0
	for k in WEIGHTS.keys():
		acc += int(WEIGHTS[k])
		if r <= acc:
			return str(k)
	return "wide_paddle"


## 应用道具效果
## paddle: Paddle 节点
## ball: 主球节点
## main: 主场景节点（用于 multi_ball 简化版触发清行）
func apply(powerup_type: String, paddle: Node, ball: Node, main: Node = null) -> void:
	match powerup_type:
		"wide_paddle":
			_apply_paddle_size(paddle, 1.5, "wide_paddle")
		"narrow_paddle":
			_apply_paddle_size(paddle, 0.7, "narrow_paddle")
		"speed_ball":
			_apply_speed_ball(ball, 1.3)
		"multi_ball":
			# 简化版：立即销毁一行砖块（详见 autorun-2026-05-14.md Issue #1）
			if main and main.has_method("powerup_clear_row"):
				main.powerup_clear_row()
		"extra_life":
			# 通过 Engine.get_main_loop() 路径访问 autoload，避免编译期硬依赖
			var tree := Engine.get_main_loop() as SceneTree
			if tree and tree.root.has_node("GameManager"):
				tree.root.get_node("GameManager").add_life()
		_:
			push_warning("Unknown powerup: %s" % powerup_type)


func _apply_paddle_size(paddle: Node, multiplier: float, key: String) -> void:
	if not paddle or not paddle.has_method("set_width"):
		return
	# 取消正在进行的同/反向计时
	_cancel_timer("wide_paddle")
	_cancel_timer("narrow_paddle")

	paddle.set_width(120.0 * multiplier)
	var t := Timer.new()
	t.one_shot = true
	t.wait_time = DURATIONS.get(key, 10.0)
	add_child(t)
	t.timeout.connect(func() -> void:
		if is_instance_valid(paddle) and paddle.has_method("reset_width"):
			paddle.reset_width()
		active_timers.erase(key)
		t.queue_free()
	)
	t.start()
	active_timers[key] = t


func _apply_speed_ball(ball: Node, multiplier: float) -> void:
	if not ball:
		return
	_cancel_timer("speed_ball")
	var original: float = ball.speed if "speed" in ball else 300.0
	ball.speed = original * multiplier
	var t := Timer.new()
	t.one_shot = true
	t.wait_time = DURATIONS.get("speed_ball", 8.0)
	add_child(t)
	t.timeout.connect(func() -> void:
		if is_instance_valid(ball):
			ball.speed = original
		active_timers.erase("speed_ball")
		t.queue_free()
	)
	t.start()
	active_timers["speed_ball"] = t


func _cancel_timer(key: String) -> void:
	if active_timers.has(key):
		var t = active_timers[key]
		if is_instance_valid(t):
			t.queue_free()
		active_timers.erase(key)
