extends Node2D

## Bolt: Sector 1-1 主场景
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


func _ready() -> void:
	GameManager.reset_game()
	GameManager.current_state = "playing"

	level_loader = LevelLoaderScript.new()
	level_loader.name = "LevelLoader"
	level_loader.set("level_id", "1-1")
	add_child(level_loader)
	await get_tree().process_frame
	if level_loader.has_method("get_spawn_position"):
		player.global_position = level_loader.get_spawn_position()
	var old_ground := get_node_or_null("Ground")
	if old_ground:
		old_ground.queue_free()


func _physics_process(delta: float) -> void:
	if _is_dead:
		_handle_death(delta)
		return
	if _is_clear:
		return

	if level_loader and player.global_position.y > level_loader.get_death_y():
		_trigger_death()
		return

	if level_loader:
		var spawn_x: float = level_loader.get_spawn_position().x - 32.0
		if player.global_position.x < spawn_x:
			player.global_position.x = spawn_x
			player.velocity.x = 0

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
	player.velocity = Vector2(0, -320)
	if "current_state" in player:
		player.current_state = player.State.DEAD
	GameManager.lose_life()


func on_player_died() -> void:
	_trigger_death()


func _handle_death(delta: float) -> void:
	_respawn_timer += delta
	player.collision_mask = 0
	player.velocity.y += 800.0 * delta
	player.move_and_slide()
	if _respawn_timer >= RESPAWN_DELAY + 1.5:
		_respawn()


func _respawn() -> void:
	if GameManager.lives <= 0:
		_show_game_over()
		return
	_is_dead = false
	_respawn_timer = 0.0
	player.collision_mask = 1
	player.velocity = Vector2.ZERO
	player.transform_to(0)
	if level_loader:
		player.global_position = level_loader.get_spawn_position()
	GameManager.time_left = 300
	GameManager.current_state = "playing"


func _show_game_over() -> void:
	GameManager.current_state = "gameover"
	print("[Main] SYSTEM FAILURE")
	var overlay_script := preload("res://scripts/clear_overlay.gd")
	var overlay = overlay_script.new()
	overlay.overlay_type = "gameover"
	overlay.final_score = GameManager.score
	add_child(overlay)


func on_signal_tower_touched(p: Node, _tower: Node, _height_t: float) -> void:
	if _is_clear or _is_dead:
		return
	_is_clear = true
	var t_left: int = GameManager.time_left
	var bonus: int = t_left * 50
	GameManager.add_score(bonus)
	print("[Main] SECTOR CLEAR! Final score: %d" % GameManager.score)
	if "velocity" in p:
		p.velocity = Vector2.ZERO
	await get_tree().create_timer(1.5).timeout
	var overlay_script := preload("res://scripts/clear_overlay.gd")
	var overlay = overlay_script.new()
	overlay.overlay_type = "clear"
	overlay.final_score = GameManager.score
	overlay.time_left = t_left
	add_child(overlay)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if GameManager.current_state == "playing":
			get_tree().paused = true
			GameManager.current_state = "paused"
		elif GameManager.current_state == "paused":
			get_tree().paused = false
			GameManager.current_state = "playing"
