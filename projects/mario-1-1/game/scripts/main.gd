extends Node2D

## Sprint 1 主场景脚本
## Sprint 2 会扩展为完整关卡管理器

@onready var player: CharacterBody2D = $Player
@onready var camera: Camera2D = $Camera2D


func _ready() -> void:
	GameManager.reset_game()
	# Sprint 1：玩家从 spawn 位置开始
	var cl := _get_cl()
	if cl:
		var spawn_x: float = float(cl.get_value("levels.1-1.spawn.x", 64))  # 暂未挂 levels（S2 做）
		# 简化：直接用场景中节点位置


func _get_cl() -> Node:
	var tree := Engine.get_main_loop() as SceneTree
	if tree and tree.root.has_node("ConfigLoader"):
		return tree.root.get_node("ConfigLoader")
	return null


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		# Sprint 1 简版：ESC 退出
		get_tree().quit()
