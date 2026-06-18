@echo off
chcp 65001 > nul
title 青云宗 · 修仙模拟经营 - 启动器
cd /d "%~dp0"

set "GODOT=..\..\engine\Godot\Godot_v4.6.2-stable_win64.exe"
set "GAME=game"

echo ============================================
echo    青云宗 · 修仙模拟经营
echo    正在启动游戏...
echo ============================================
echo.

if not exist "%GODOT%" (
    echo [错误] 未找到 Godot 引擎：
    echo   %GODOT%
    echo.
    echo 请确认 Godot 已放置在 engine\Godot\ 目录下。
    echo.
    pause
    exit /b 1
)

if not exist "%GAME%\project.godot" (
    echo [错误] 未找到游戏工程 %GAME%\project.godot
    echo.
    pause
    exit /b 1
)

start "" "%GODOT%" --path "%GAME%"
exit /b 0
