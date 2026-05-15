extends Node

## GameManager · 全局单例（Autoload）
## Sprint 1 简版：仅管理生命/分数/coin（HUD Sprint 2 接入）

signal score_changed(new_score: int)
signal coins_changed(new_coins: int)
signal lives_changed(new_lives: int)
signal time_changed(new_time: int)
signal game_over

var lives: int = 3
var score: int = 0
var coins: int = 0
var time_left: int = 300
var current_state: String = "ready"  # ready / playing / paused / death / clear / gameover


func _ready() -> void:
	var cl := _get_cl()
	if cl:
		lives = int(cl.get_value("scoring.lives.initial", 3))
		time_left = int(cl.get_value("scoring.time.initial", 300))


func _get_cl() -> Node:
	var tree := Engine.get_main_loop() as SceneTree
	if tree and tree.root.has_node("ConfigLoader"):
		return tree.root.get_node("ConfigLoader")
	return null


func reset_game() -> void:
	var cl := _get_cl()
	lives = int(cl.get_value("scoring.lives.initial", 3)) if cl else 3
	score = 0
	coins = 0
	time_left = int(cl.get_value("scoring.time.initial", 300)) if cl else 300
	current_state = "ready"


func add_score(points: int) -> void:
	score += points
	score_changed.emit(score)


func add_coin() -> void:
	# bolt-1-1: coin -> cog (key 重命名)。变量名保持 coin* 以减少改动面，语义已是 cog。
	var cl := _get_cl()
	var coin_value: int = 200
	if cl:
		coin_value = int(cl.get_value("scoring.score.cog", cl.get_value("scoring.score.coin", 200)))
	coins += 1
	add_score(coin_value)
	coins_changed.emit(coins)
	# 100 cog → 1UP（蓝水晶等价 1 命）
	if coins >= 100:
		coins = 0
		add_life()
		coins_changed.emit(coins)


func add_life() -> void:
	lives += 1
	lives_changed.emit(lives)


func lose_life() -> void:
	lives -= 1
	lives_changed.emit(lives)
	if lives <= 0:
		current_state = "gameover"
		game_over.emit()


func tick_time() -> void:
	time_left -= 1
	time_changed.emit(time_left)
	if time_left <= 0:
		# 触发死亡（由 main 处理）
		pass
