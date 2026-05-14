extends Node2D

## 主菜单
## 显示标题 + 操作提示，按 SPACE/ENTER 开始游戏

const GAME_SCENE: String = "res://scenes/main.tscn"


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("launch_ball") or event.is_action_pressed("ui_accept"):
		get_tree().change_scene_to_file(GAME_SCENE)
	elif event.is_action_pressed("ui_cancel"):
		get_tree().quit()
