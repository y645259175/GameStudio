# Bolt 1-1 · Sprint 1 Plan

> Pivot 注：本计划在 mario-1-1 阶段制定并执行；S1 全部 stories 在 pivot 前已完成。bolt-1-1 仅做命名替换，保留原 sprint 框架作为审计痕迹。

**起止**：2026-05-15 ~ TBD（约 1 周）
**目标（DoD）**：核心玩法可玩——Bolty 可移动、跳跃、踩到地面会停、跳跃手感符合 NES 时代横版手感（变高度跳）、有简单地面，**还没有敌人/道具/HUD**。

## velocity

新项目首 sprint 估为 12-15 pts（参考 breakout S1=10 pts，本项目难度更高）

## 入选 Stories

| ID | 标题 | Pts | Epic | 优先级 |
|---|---|---|---|---|
| S1-01 | Godot 项目骨架 + ConfigLoader autoload | 1 | E1 | P0 |
| S1-02 | InputManager + 键位映射（移动/跳/跑/暂停） | 1 | E2 | P0 |
| S1-03 | Player 节点 + 走/跑加减速 | 3 | E2 | P0 |
| S1-04 | Player 跳跃（可变高度 + 重力切换） | 3 | E2 | P0 |
| S1-05 | Player 转身减速 + 朝向反转 | 1 | E2 | P0 |
| S1-06 | 简单关卡（地面 + 1 平台）+ Camera2D follow | 2 | E3 | P0 |
| S1-07 | Player 状态机骨架（small/big/fire/dead 占位） | 2 | E2 | P0 |
| S1-08 | 单元测试（player 数值 / 状态机转移） | 1 | E1 | P0 |

**合计 14 pts**

## 关键决策

- **Player 用 CharacterBody2D**（Godot 内置）做移动，自己实现重力（不用引擎物理）
- **状态机扁平**（不嵌套），用 GDScript enum + match
- **数值全部走 ConfigLoader**（参考 breakout 模式）
- **暂时没有美术**，用 ColorRect 占位（红色方块=Bolty 小，红+蓝=Bolty 大）

## 风险

| 风险 | 概率 | 缓解 |
|---|---|---|
| 跳跃手感反复调参 | 高 | data/player.json 一处调 |
| Camera 不可回退实现复杂 | 中 | Sprint 2 再做完整版，S1 先做简单跟随 |
| Godot 4.6 类型推断 | 中 | 已有 SOP（每次 check-only） |

## verdict: SPRINT_PLANNED（已 done，状态切到 SPRINT_CLOSED）
