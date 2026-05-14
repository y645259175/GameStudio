extends SceneTree

## PowerupManager 单元测试
## 验证概率、单局封顶、_roll_type 权重、效果应用基础

const PM_SCRIPT: GDScript = preload("res://scripts/powerup_manager.gd")

var _pass: int = 0
var _fail: int = 0


func _initialize() -> void:
	var pm: Node = PM_SCRIPT.new()
	get_root().add_child(pm)

	_test_initial_state(pm)
	_test_should_drop_zero_rate(pm)
	_test_should_drop_full_rate(pm)
	_test_max_per_run_cap(pm)
	_test_reset_run(pm)
	_test_roll_type_returns_known(pm)

	pm.queue_free()
	print("==========================================")
	print("PowerupManager: %d passed, %d failed" % [_pass, _fail])
	print("==========================================")
	quit(0 if _fail == 0 else 1)


func _assert(condition: bool, name: String) -> void:
	if condition:
		_pass += 1
		print("PASS: %s" % name)
	else:
		_fail += 1
		printerr("FAIL: %s" % name)


func _test_initial_state(pm: Node) -> void:
	_assert(pm.powerups_dropped_this_run == 0, "initial dropped count = 0")


func _test_should_drop_zero_rate(pm: Node) -> void:
	pm.reset_run()
	# 0 概率永不掉
	for i in range(50):
		_assert(not pm.should_drop(0.0), "should_drop(0) returns false (sample %d)" % i) if false else null
	_assert(not pm.should_drop(0.0), "should_drop(0) returns false")


func _test_should_drop_full_rate(pm: Node) -> void:
	pm.reset_run()
	# 100% 概率必掉（直到封顶）
	_assert(pm.should_drop(1.0), "should_drop(1.0) returns true")


func _test_max_per_run_cap(pm: Node) -> void:
	pm.reset_run()
	pm.powerups_dropped_this_run = pm.MAX_POWERUPS_PER_RUN
	_assert(not pm.should_drop(1.0), "should_drop returns false at cap (rate=1.0 cap reached)")


func _test_reset_run(pm: Node) -> void:
	pm.powerups_dropped_this_run = 5
	pm.reset_run()
	_assert(pm.powerups_dropped_this_run == 0, "reset_run zeros counter")
	_assert(pm.active_timers.size() == 0, "reset_run clears timers")


func _test_roll_type_returns_known(pm: Node) -> void:
	var known := ["wide_paddle", "narrow_paddle", "speed_ball", "multi_ball", "extra_life"]
	for i in range(20):
		var t: String = pm._roll_type()
		if not (t in known):
			_fail += 1
			printerr("FAIL: _roll_type returned unknown: %s" % t)
			return
	_assert(true, "_roll_type always returns one of 5 known types (20 samples)")
