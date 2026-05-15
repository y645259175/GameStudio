extends Node

## GameManager · 全局单例（Autoload）
## 弱引用 ConfigLoader，在无 ConfigLoader 时用默认值（便于 headless 测试）

signal life_lost
signal game_over
signal level_cleared
signal score_changed(new_score: int)
signal lives_changed(new_lives: int)

var lives: int = 3
var max_lives: int = 5
var score: int = 0
var current_level: int = 1
var max_level: int = 5
var bricks_remaining: int = 0

var _clear_bonus_per_level: int = 100
var _life_bonus_per_life: int = 50


func _ready() -> void:
	var cl := _get_config_loader()
	if cl:
		lives = int(cl.get_value("lives.initial", 3))
		max_lives = int(cl.get_value("lives.max", 5))
		_clear_bonus_per_level = int(cl.get_value("scoring.clear_bonus_per_level", 100))
		_life_bonus_per_life = int(cl.get_value("scoring.life_bonus_per_life", 50))


func _get_config_loader() -> Node:
	var tree := Engine.get_main_loop() as SceneTree
	if tree and tree.root.has_node("ConfigLoader"):
		return tree.root.get_node("ConfigLoader")
	return null


func reset_game() -> void:
	var cl := _get_config_loader()
	lives = int(cl.get_value("lives.initial", 3)) if cl else 3
	score = 0
	current_level = 1
	bricks_remaining = 0


func add_score(points: int) -> void:
	score += points
	score_changed.emit(score)


func lose_life() -> void:
	lives -= 1
	lives_changed.emit(lives)
	if lives <= 0:
		game_over.emit()
	else:
		life_lost.emit()


func add_life() -> void:
	if lives < max_lives:
		lives += 1
		lives_changed.emit(lives)


func register_brick() -> void:
	bricks_remaining += 1


func destroy_brick(points: int) -> void:
	bricks_remaining -= 1
	add_score(points)
	if bricks_remaining <= 0:
		add_score(current_level * _clear_bonus_per_level)
		level_cleared.emit()


func next_level() -> void:
	current_level += 1


func is_last_level() -> bool:
	return current_level >= max_level


func get_life_bonus() -> int:
	return lives * _life_bonus_per_life
