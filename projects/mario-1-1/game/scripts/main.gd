extends Node2D

## Mario 1-1 主场景
## 用 LevelLoader 程序化生成关卡 + 管理 Player + Camera + 死亡 / 重生 / 通关

const LevelLoaderScript := preload("res://scripts/level_loader.gd")

@onready var player: CharacterBody2D = $Player
@onready var camera: Camera2D = $Camera2D

var level_loader: Node2D
var _time_accumulator: float = 0.0
var _is_dead: bool = false
var _is_clear: bool = false
var _respawn_timer: float = 0.0
const RESPAWN_DELAY: float = 1.5
const DEATH_HOVER_DURATION: float = 0.5
var _death_hover_t: float = 0.0


func _ready() -> void:
	GameManager.reset_game()
	GameManager.current_state = "playing"

	# 创建 LevelLoader
	level_loader = LevelLoaderScript.new()
	level_loader.name = "LevelLoader"
	level_loader.set("level_id", "1-1")
	add_child(level_loader)
	# 必须等到下一帧 LevelLoader 内部 _ready 完毕
	await get_tree().process_frame
	# 把 player 移到 spawn
	if level_loader.has_method("get_spawn_position"):
		player.global_position = level_loader.get_spawn_position()
	# 隐藏旧的硬编码 Ground
	var old_ground := get_node_or_null("Ground")
	if old_ground:
		old_ground.queue_free()


func _physics_process(delta: float) -> void:
	if _is_dead:
		_handle_death(delta)
		return
	if _is_clear:
		return

	# 死亡线检测
	if level_loader and player.global_position.y > level_loader.get_death_y():
		_trigger_death()
		return

	# 出生点左墙：玩家 X 不能小于 spawn.x
	if level_loader:
		var spawn_x: float = level_loader.get_spawn_position().x - 32.0
		if player.global_position.x < spawn_x:
			player.global_position.x = spawn_x
			player.velocity.x = 0

	# TIME 倒计时（每秒 -1）
	_time_accumulator += delta
	if _time_accumulator >= 1.0:
		_time_accumulator -= 1.0
		GameManager.tick_time()
		if GameManager.time_left <= 0:
			_trigger_death()


func _trigger_death() -> void:
	if _is_dead or _is_clear:
		return
	_is_dead = true
	_death_hover_t = 0.0
	# 玩家死亡动画：跳起后下落
	player.velocity = Vector2(0, -320)
	if "current_state" in player:
		player.current_state = player.State.DEAD
	GameManager.lose_life()


func on_player_died() -> void:
	# 由 player.take_damage 在 SMALL→DEAD 时调用
	_trigger_death()


func _handle_death(delta: float) -> void:
	_respawn_timer += delta
	# 死亡动画：让玩家继续受重力（但脱离 world 碰撞）
	player.collision_mask = 0
	player.velocity.y += 800.0 * delta
	player.move_and_slide()
	if _respawn_timer >= RESPAWN_DELAY + 1.5:
		_respawn()


func _respawn() -> void:
	if GameManager.lives <= 0:
		# game over
		_show_game_over()
		return
	_is_dead = false
	_respawn_timer = 0.0
	# 重置玩家
	player.collision_mask = 1
	player.velocity = Vector2.ZERO
	player.transform_to(0)  # SMALL
	if level_loader:
		player.global_position = level_loader.get_spawn_position()
	# 重置时间
	GameManager.time_left = 300
	GameManager.current_state = "playing"


func _show_game_over() -> void:
	GameManager.current_state = "gameover"
	# Sprint 3 接入完整 GameOver 界面，自主模式简化为打印
	print("[Main] GAME OVER")
	# 自动重启（演示用）
	await get_tree().create_timer(2.0).timeout
	get_tree().reload_current_scene()


func on_flagpole_touched(p: Node, _flagpole: Node, _height_t: float) -> void:
	if _is_clear or _is_dead:
		return
	_is_clear = true
	# 玩家滑下杆 → 走入城堡 → WORLD CLEAR
	# 自主模式简化版：直接累加 timeBonus + 显示 clear
	var bonus: int = GameManager.time_left * 50
	GameManager.add_score(bonus)
	print("[Main] WORLD CLEAR! Final score: %d" % GameManager.score)
	# 让玩家停下
	if "velocity" in p:
		p.velocity = Vector2.ZERO
	# 等 3 秒后回标题（自主模式简化为 quit）
	await get_tree().create_timer(3.0).timeout
	get_tree().quit()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		# ESC = 暂停 toggle
		if GameManager.current_state == "playing":
			get_tree().paused = true
			GameManager.current_state = "paused"
		elif GameManager.current_state == "paused":
			get_tree().paused = false
			GameManager.current_state = "playing"
