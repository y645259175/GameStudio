# =============================================================================
# game_over.gd · 游戏结束画面（GDD-02 §2.7 全员陨落）
# =============================================================================
extends Control

@onready var summary_label: Label = %SummaryLabel


func _ready() -> void:
	var year := TimeService.get_current_year() if TimeService else 1
	summary_label.text = "宗门历经 %d 载春秋，终归沉寂。\n青云之志，化作一缕青烟。" % year


func _on_restart_pressed() -> void:
	GameManager.start_new_game()


func _on_menu_pressed() -> void:
	GameManager.to_main_menu()


func _on_quit_pressed() -> void:
	GameManager.quit_game()
