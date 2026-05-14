extends Node

## GameManager · 全局单例（Autoload）
## 管理生命、分数、关卡状态

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


func reset_game() -> void:
	lives = 3
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
		# 通关奖励
		add_score(current_level * 100)
		level_cleared.emit()


func next_level() -> void:
	current_level += 1


func is_last_level() -> bool:
	return current_level >= max_level
