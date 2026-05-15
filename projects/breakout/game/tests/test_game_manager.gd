extends SceneTree

## GameManager 单元测试（适配 ConfigLoader）

const GM_SCRIPT: GDScript = preload("res://scripts/game_manager.gd")
const CL_SCRIPT: GDScript = preload("res://scripts/config_loader.gd")

var _pass: int = 0
var _fail: int = 0
var GM: Node = null
var CL: Node = null


func _initialize() -> void:
	# 手动创建 ConfigLoader 并注册为全局（模拟 autoload）
	CL = CL_SCRIPT.new()
	CL.name = "ConfigLoader"
	get_root().add_child(CL)

	GM = GM_SCRIPT.new()
	GM.name = "GameManager_Test"
	get_root().add_child(GM)

	_test_initial_state()
	_test_add_score()
	_test_lose_life_decrements()
	_test_lose_life_triggers_game_over()
	_test_add_life_capped()
	_test_register_destroy_brick_clears_level()
	_test_destroy_brick_adds_score()
	_test_next_level()
	_test_is_last_level()
	_test_reset_game()
	_test_get_life_bonus()

	print("==========================================")
	print("GameManager: %d passed, %d failed" % [_pass, _fail])
	print("==========================================")
	GM.queue_free()
	CL.queue_free()
	quit(0 if _fail == 0 else 1)


func _assert(condition: bool, name: String) -> void:
	if condition:
		_pass += 1
		print("PASS: %s" % name)
	else:
		_fail += 1
		printerr("FAIL: %s" % name)


func _test_initial_state() -> void:
	GM.reset_game()
	_assert(GM.lives == 3, "initial lives = 3")
	_assert(GM.score == 0, "initial score = 0")
	_assert(GM.current_level == 1, "initial level = 1")


func _test_add_score() -> void:
	GM.reset_game()
	GM.add_score(50)
	_assert(GM.score == 50, "add_score(50) -> 50")
	GM.add_score(25)
	_assert(GM.score == 75, "add_score cumulative -> 75")


func _test_lose_life_decrements() -> void:
	GM.reset_game()
	GM.lose_life()
	_assert(GM.lives == 2, "lose_life: 3->2")


func _test_lose_life_triggers_game_over() -> void:
	GM.reset_game()
	var captured := {"emitted": false}
	var cb := func() -> void: captured["emitted"] = true
	GM.game_over.connect(cb)
	GM.lose_life()
	GM.lose_life()
	GM.lose_life()
	_assert(GM.lives == 0, "lives reach 0")
	_assert(captured["emitted"] == true, "game_over signal emitted")
	GM.game_over.disconnect(cb)


func _test_add_life_capped() -> void:
	GM.reset_game()
	for i in range(10):
		GM.add_life()
	_assert(GM.lives == GM.max_lives, "add_life caps at max_lives=%d" % GM.max_lives)


func _test_register_destroy_brick_clears_level() -> void:
	GM.reset_game()
	var captured := {"cleared": false}
	var cb := func() -> void: captured["cleared"] = true
	GM.level_cleared.connect(cb)
	GM.register_brick()
	GM.register_brick()
	GM.register_brick()
	GM.destroy_brick(10)
	GM.destroy_brick(10)
	_assert(captured["cleared"] == false, "level not cleared with 1 brick remaining")
	GM.destroy_brick(10)
	_assert(captured["cleared"] == true, "level_cleared emitted on last brick")
	GM.level_cleared.disconnect(cb)


func _test_destroy_brick_adds_score() -> void:
	GM.reset_game()
	GM.register_brick()
	GM.destroy_brick(15)
	var expected: int = 15 + 1 * GM._clear_bonus_per_level
	_assert(GM.score == expected, "destroy adds score+clear bonus (%d)" % expected)


func _test_next_level() -> void:
	GM.reset_game()
	GM.next_level()
	_assert(GM.current_level == 2, "next_level: 1->2")


func _test_is_last_level() -> void:
	GM.reset_game()
	_assert(not GM.is_last_level(), "level 1 not last")
	GM.current_level = GM.max_level
	_assert(GM.is_last_level(), "max_level is last")


func _test_reset_game() -> void:
	GM.score = 999
	GM.lives = 1
	GM.current_level = 4
	GM.reset_game()
	_assert(GM.score == 0, "reset: score=0")
	_assert(GM.lives == 3, "reset: lives=3")
	_assert(GM.current_level == 1, "reset: level=1")


func _test_get_life_bonus() -> void:
	GM.reset_game()
	var bonus: int = GM.get_life_bonus()
	_assert(bonus == 3 * GM._life_bonus_per_life, "life_bonus = lives * per_life (%d)" % bonus)
