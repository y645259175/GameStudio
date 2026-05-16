@echo off
REM 双击此文件运行 Bolt: Sector 1-1
REM 关键：必须传场景文件名作为位置参数，否则 Godot 4 在 Windows 上默认进项目管理器
cd /d "%~dp0"
"d:\AI\GameStudio\engine\Godot\Godot_v4.6.2-stable_win64.exe" --path "%~dp0" res://scenes/title.tscn
