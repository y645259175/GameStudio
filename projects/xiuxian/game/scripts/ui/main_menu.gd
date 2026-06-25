# =============================================================================
# main_menu.gd · 主菜单（M3-2 五件基本功能入口）
# 开始新游戏 / 继续（读档）/ 退出
# =============================================================================
extends Control

@onready var continue_btn: Button = %ContinueBtn


func _ready() -> void:
	# 无存档时"继续"置灰
	continue_btn.disabled = not GameManager.has_save()


func _on_new_game_pressed() -> void:
	GameManager.start_new_game()


func _on_continue_pressed() -> void:
	if not GameManager.continue_game():
		continue_btn.text = "继续（读档失败）"
		continue_btn.disabled = true


func _on_quit_pressed() -> void:
	GameManager.quit_game()
