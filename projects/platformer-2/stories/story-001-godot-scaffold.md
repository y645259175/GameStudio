---
id: story-001-godot-scaffold
status: done
priority: P0
estimate: 2
gdd_anchor: gdd/gdd-3-mechanics.md
milestone: M1
---
# Story · story-001 · Godot 项目脚手架

## 目标
为 platformer-2 创建最小 Godot 4.6.2 项目结构，让 `godot --headless --check-only` 能跑通。**本 story 不实现玩法**，只建脚手架。

## Acceptance Criteria

1. `projects/platformer-2/game/project.godot` 存在且配置正确（display size 1280x720 / pixel snap）
2. `projects/platformer-2/game/main.tscn` 是默认场景，包含一个 Node2D 根节点 + Label "platformer-2 M1 prototype"
3. `projects/platformer-2/game/scripts/main.gd` 存在，extends Node2D，_ready 中 print 启动信息
4. 跑 `godot --headless --check-only --path projects/platformer-2/game --quit` EXIT 0
5. 项目能用 `godot --path projects/platformer-2/game` 打开（无 editor 错误）

## 关联 GDD
- `gdd/gdd-3-mechanics.md` § 性能预算（Godot 4 项目配置）
- `gdd/gdd-1-overview.md` § 玩家角色 Vex Pell（仅命名约定，本 story 不实现）

## 涉及文件（待 engineer 创建）
- `projects/platformer-2/game/project.godot`
- `projects/platformer-2/game/main.tscn`
- `projects/platformer-2/game/scripts/main.gd`
- `projects/platformer-2/game/icon.svg`（可选，使用 Godot 默认）

## 验收方式
- engineer 落盘 → 跑 headless check EXIT 0 → 截图（可选）
