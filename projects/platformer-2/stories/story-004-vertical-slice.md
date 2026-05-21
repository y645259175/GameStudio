---
id: story-004-vertical-slice
status: playtest_pending
priority: P0
milestone: M2
gdd_anchor: gdd-3-mechanics.md §4.5
---
# Story-004 · Vertical Slice 关卡

## 描述

组合 player 移动 + pipe puzzle 机制，构成 1 个完整可玩关卡：玩家从起点移动、跳跃到达谜题区域，解开管道谜题后门打开，到达终点触发关卡完成。

## Acceptance Criteria

- [ ] AC-1: level_01.tscn 场景包含 Player 实例 + 地面 TileMap + 3 个 PipeNode + 1 个 PuzzleDoor + 终点 Area2D
- [ ] AC-2: 玩家能在地面上移动和跳跃（复用 story-002 player.gd）
- [ ] AC-3: 3 个 PipeNode 组成需旋转才能连通的谜题（初始不连通）
- [ ] AC-4: 谜题解开后 PuzzleDoor 移除碰撞，玩家可通过
- [ ] AC-5: 玩家到达终点 Area2D 时 emit "level_completed" signal + print 提示
- [ ] AC-6: godot --headless --check-only EXIT 0

## 涉及文件

- `game/scenes/levels/level_01.tscn`（新建）
- `game/scripts/level/level_manager.gd`（新建：管理关卡完成逻辑）
- `game/main.tscn`（修改：加载 level_01 而非空场景）

## 测试红线

涉及玩家全路径体验 → tester 必须含完整通关路径的真实输入测试。
