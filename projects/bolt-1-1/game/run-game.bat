@echo off
REM 双击此文件运行 Bolt: Sector 1-1
cd /d "%~dp0"
echo ===== 启动 Bolt: Sector 1-1 =====
echo 当前目录: %CD%
echo Godot 路径: d:\AI\GameStudio\engine\Godot\Godot_v4.6.2-stable_win64.exe
echo project.godot 存在? 
if exist project.godot ( echo YES ) else ( echo NO - project.godot 缺失！ )
echo ===== 启动 Godot =====
"d:\AI\GameStudio\engine\Godot\Godot_v4.6.2-stable_win64.exe" --path "%CD%" res://scenes/title.tscn
echo ===== Godot 退出码: %ERRORLEVEL% =====
echo.
echo 按任意键关闭此窗口...
pause >nul
