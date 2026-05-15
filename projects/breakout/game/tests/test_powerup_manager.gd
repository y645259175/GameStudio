extends SceneTree

## PowerupManager 单元测试（适配 ConfigLoader）

const PM_SCRIPT: GDScript = preload("res://scripts/powerup_manager.gd")
const CL_SCRIPT: GDScript = preload("res://scripts/config_loader.gd")

var _pass: int = 0
var _fail: int = 0


func _initialize() -> void:
	var cl: Node = CL_SCRIPT.new()
	cl.name = "ConfigLoader"
	get_root().add_child(cl)

	var pm: Node = PM_SCRIPT.new()
	get_root().add_child(pm)

	_test_initial_state(pm)
	_test_should_drop_zero(pm)
	_test_should_drop_full(pm)
	_test_max_cap(pm)
	_test_reset_run(pm)
	_test_roll_type(pm)
	_test_config_loaded(pm)

	pm.queue_free()
	cl.queue_free()
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
	_assert(pm.powerups_dropped_this_run == 0, "initial dropped=0")


func _test_should_drop_zero(pm: Node) -> void:
	pm.reset_run()
	_assert(not pm.should_drop("-1"), "should_drop(-1 indestructible) false")


func _test_should_drop_full(pm: Node) -> void:
	pm.reset_run()
	# 用一个不存在的高掉率 key 模拟 → 走 default 0.0 → false
	# 用真实 key "3"（drop_rate 0.25），跑 100 次至少有 1 次 true
	var any_true := false
	for i in range(100):
		pm.reset_run()
		if pm.should_drop("3"):
			any_true = true
			break
	_assert(any_true, "should_drop('3') returns true at least once in 100 tries (rate=0.25)")


func _test_max_cap(pm: Node) -> void:
	pm.reset_run()
	pm.powerups_dropped_this_run = pm._max_per_run
	_assert(not pm.should_drop("3"), "should_drop false at cap")


func _test_reset_run(pm: Node) -> void:
	pm.powerups_dropped_this_run = 5
	pm.reset_run()
	_assert(pm.powerups_dropped_this_run == 0, "reset zeros counter")


func _test_roll_type(pm: Node) -> void:
	var known := ["wide_paddle", "narrow_paddle", "speed_ball", "clear_row", "extra_life"]
	for i in range(20):
		var t: String = pm._roll_type()
		if not (t in known):
			_fail += 1
			printerr("FAIL: _roll_type returned unknown: %s" % t)
			return
	_assert(true, "_roll_type returns known type (20 samples)")


func _test_config_loaded(pm: Node) -> void:
	_assert(pm._max_per_run > 0, "config loaded: max_per_run=%d" % pm._max_per_run)
	_assert(pm._weights.size() > 0, "config loaded: weights has %d entries" % pm._weights.size())
	_assert(pm._drop_rates.size() > 0, "config loaded: drop_rates has %d entries" % pm._drop_rates.size())
