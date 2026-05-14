---
id: S1-05
epic: E1
priority: P0
estimate: 2
status: done
gdd-anchor: gdd/gdd-breakout.md#§4-生命与状态
completed-at: 2026-05-14
---

# S1-05 · GameManager（生命 + 通关 + Game Over）

**Epic**：E1 · 核心玩法原型
**GDD 锚点**：§4 S4 生命与 Game Over · §2 玩法循环
**点数**：2

## User Story

作为玩家，我有 3 条命；球掉落扣命，命归零显示 Game Over；消灭所有砖块显示通关。

## 验收标准

- [ ] 初始生命 3，最大 5
- [ ] 球掉落 → 生命 -1 → 重新发球（球回到挡板上）
- [ ] 生命 = 0 → 切换到 Game Over 场景（简单文字即可，M4 再打磨）
- [ ] 所有可破坏砖块清零 → 切换到通关场景（简单文字）
- [ ] GameManager 作为 Autoload 全局单例

## 技术备注

- 脚本：`game_manager.gd`（Autoload）
- 信号监听：`ball_lost` `brick_destroyed`
- 状态：`lives` `score` `current_level` `bricks_remaining`

