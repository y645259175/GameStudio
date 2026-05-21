extends Node
class_name LevelManager

## LevelManager — 关卡完成检测
## story-004-vertical-slice · AC-5
## 连接终点 Area2D，玩家进入后 emit level_completed

# --- Configuration ---
@export var goal_area: Area2D  ## 终点区域引用

# --- Signals ---
signal level_completed


func _ready() -> void:
	if goal_area:
		goal_area.body_entered.connect(_on_goal_body_entered)
	else:
		push_warning("[LevelManager] goal_area not assigned!")


func _on_goal_body_entered(body: Node2D) -> void:
	if body is CharacterBody2D and body.name == "Player":
		print("[level] COMPLETED!")
		level_completed.emit()
