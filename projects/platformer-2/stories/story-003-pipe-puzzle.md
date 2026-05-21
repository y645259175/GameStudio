---
id: story-003-pipe-puzzle
status: done
priority: P0
milestone: M1
gdd_anchor: gdd-3-mechanics.md §4.3
---
# Story-003 · 管道解谜机制

## 描述

实现信号塔中的管道解谜系统：玩家与 PipeNode 交互旋转管道方向，所有管道正确连接后信号传导完成、门打开。这是 platformer-2 的核心差异化机制（区别于纯跳跃）。

## Acceptance Criteria

- [ ] AC-1: PipeNode 场景（pipe_node.tscn）含 4 方向旋转状态（0/90/180/270度）
- [ ] AC-2: 玩家站在 PipeNode 附近按 interact（E 键）可旋转 90 度
- [ ] AC-3: SignalNetwork 脚本检测所有 PipeNode 是否形成连通路径（BFS/DFS）
- [ ] AC-4: 连通完成时发出 signal "puzzle_solved"
- [ ] AC-5: 至少 1 个 puzzle_door.tscn 监听 puzzle_solved 后播放开门动画（placeholder）
- [ ] AC-6: godot --headless --check-only EXIT 0

## 涉及文件

- `game/scripts/puzzle/pipe_node.gd`（新建）
- `game/scripts/puzzle/signal_network.gd`（新建）
- `game/scripts/puzzle/puzzle_door.gd`（新建）
- `game/scenes/puzzle/pipe_node.tscn`（新建）
- `game/scenes/puzzle/puzzle_door.tscn`（新建）

## 数值来源

gdd-3-mechanics.md §4.3:
- rotation_step: 90 degrees
- interact_range: 48 px（玩家中心到 PipeNode 中心距离）
- signal_propagation_delay: 0.0s（即时）

## 测试红线

涉及玩家交互行为 → tester 必须含 action_press("interact") 真实输入路径测试。
