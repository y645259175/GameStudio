extends Node

## 道具管理器 · 数值从 ConfigLoader 读取

const POWERUP_SCENE: PackedScene = preload("res://scenes/powerup.tscn")

var powerups_dropped_this_run: int = 0
var active_timers: Dictionary = {}

var _max_per_run: int = 6
var _weights: Dictionary = {}
var _durations: Dictionary = {}
var _speed_multiplier: float = 1.3
var _drop_rates: Dictionary = {}
var _default_paddle_width: float = 120.0
var _wide_multiplier: float = 1.5
var _narrow_multiplier: float = 0.7


func _ready() -> void:
	_max_per_run = int(ConfigLoader.get_value("powerup.max_per_run", 6))
	_weights = ConfigLoader.get_value("powerup.weights", {"wide_paddle":25,"narrow_paddle":15,"speed_ball":20,"multi_ball":20,"extra_life":20}) as Dictionary
	_durations = ConfigLoader.get_value("powerup.durations", {"wide_paddle":10,"narrow_paddle":10,"speed_ball":8}) as Dictionary
	_speed_multiplier = float(ConfigLoader.get_value("powerup.speed_multiplier", 1.3))
	_drop_rates = ConfigLoader.get_value("powerup.drop_rates", {"1":0.10,"2":0.18,"3":0.25,"-1":0.0}) as Dictionary
	_default_paddle_width = float(ConfigLoader.get_value("paddle.default_width", 120))
	_wide_multiplier = float(ConfigLoader.get_value("paddle.wide_multiplier", 1.5))
	_narrow_multiplier = float(ConfigLoader.get_value("paddle.narrow_multiplier", 0.7))


func reset_run() -> void:
	powerups_dropped_this_run = 0
	for t in active_timers.values():
		if is_instance_valid(t):
			t.queue_free()
	active_timers.clear()


func should_drop(brick_type_key: String) -> bool:
	if powerups_dropped_this_run >= _max_per_run:
		return false
	var rate: float = float(_drop_rates.get(brick_type_key, 0.0))
	return randf() < rate


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
	for w in _weights.values():
		total += int(w)
	var r := randi_range(1, total)
	var acc := 0
	for k in _weights.keys():
		acc += int(_weights[k])
		if r <= acc:
			return str(k)
	return "wide_paddle"


func apply(powerup_type: String, paddle: Node, ball: Node, main: Node = null) -> void:
	match powerup_type:
		"wide_paddle":
			_apply_paddle_size(paddle, _wide_multiplier, "wide_paddle")
		"narrow_paddle":
			_apply_paddle_size(paddle, _narrow_multiplier, "narrow_paddle")
		"speed_ball":
			_apply_speed_ball(ball, _speed_multiplier)
		"multi_ball":
			if main and main.has_method("powerup_clear_row"):
				main.powerup_clear_row()
		"extra_life":
			var tree := Engine.get_main_loop() as SceneTree
			if tree and tree.root.has_node("GameManager"):
				tree.root.get_node("GameManager").add_life()
		_:
			push_warning("Unknown powerup: %s" % powerup_type)


func _apply_paddle_size(paddle: Node, multiplier: float, key: String) -> void:
	if not paddle or not paddle.has_method("set_width"):
		return
	_cancel_timer("wide_paddle")
	_cancel_timer("narrow_paddle")

	var base_w: float = _default_paddle_width
	if paddle.has_method("get_default_width"):
		base_w = paddle.get_default_width()
	paddle.set_width(base_w * multiplier)

	var dur: float = float(_durations.get(key, 10.0))
	var t := Timer.new()
	t.one_shot = true
	t.wait_time = dur
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
	var dur: float = float(_durations.get("speed_ball", 8.0))
	var t := Timer.new()
	t.one_shot = true
	t.wait_time = dur
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
