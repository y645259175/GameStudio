# Godot Screenshot Template · in-context 渲染评审工具

> 作用：自动跑 godot 场景 + 在多个玩家位置截图，供 art-director 走 TPL-05 v2 in-context 渲染评审使用。
>
> 这是 AP-10 修法的核心工具——本工具不存在前 art-director 只能看 raw 资产，无法发现 transform 链断裂等渲染层 bug。
>
> 沉淀来源：platformer-2 vertical slice 实战（2026-05-19），art-director 用截图找到 SignalNetwork transform 链断裂。

## 安装到新项目

1. 复制 `screenshot_capture.gd` 到 `projects/<name>/game/scripts/level/`
2. 复制 `capture_scene.tscn` 到 `projects/<name>/game/scenes/`
3. 修改 `capture_scene.tscn` 中的 `ext_resource` 指向你项目的目标 level 场景
4. 修改 `screenshot_capture.gd` 中的 `capture_positions` 数组覆盖你想截图的位置

## 跑法

```powershell
# Windows
& d:\AI\GameStudio\engine\Godot\Godot_v4.6.2-stable_win64.exe `
  --path projects/<name>/game res://scenes/capture_scene.tscn

# 截图自动保存到 user://screenshots/，可用以下命令复制到项目内
Copy-Item "$env:APPDATA\Godot\app_userdata\<project>\screenshots\*.png" `
  projects/<name>/reports/screenshots/ -Force
```

## 必须满足条件

- 目标 level 场景里 Player 必须在 `player` group 或名为 `Player`（脚本会按这两种方式查找）
- 玩家是 Node2D 子类（CharacterBody2D / KinematicBody2D 都 OK）

## 与 art-director TPL-05 配合

每次资产入库前，main agent 应：

1. 跑本截图工具生成 ≥ 3 张 in-context 截图
2. spawn art-director 用 TPL-05 v2 模板评审（必须传入截图路径）
3. art-director 用截图作证据给 AD-APPROVE / AD-MINOR-ISSUES / AD-REJECT verdict
4. 若有资产应该出现但截图里没有 → 触发 transform 链 / z_index 诊断（AP-11）

## 文件清单

- `screenshot_capture.gd` — 自动截图逻辑（多位置 + camera smoothing 等待）
- `capture_scene.tscn` — 包装场景（实例化目标 level + 截图节点）
- `README.md` — 本文档
