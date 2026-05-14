extends SceneTree

## 统一测试运行器
## 注意：godot CLI 的 `-s` 一次只接受一个脚本，本运行器只是文档锚（实际跑脚本通过 powershell 循环或 Makefile）
## 实际使用方式见 projects/breakout/qa/run-tests.ps1

func _initialize() -> void:
	print("This runner is a placeholder.")
	print("Run individual test scripts via:")
	print("  godot --headless --path <project> -s res://tests/test_<name>.gd --quit")
	print("Available tests:")
	print("  - test_levels.gd       (data driven, 21 cases)")
	print("  - test_game_manager.gd (24 cases)")
	print("  - test_powerup_manager.gd (7 cases)")
	quit(0)
