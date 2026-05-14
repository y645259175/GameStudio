---
id: S1-02
epic: E1
priority: P0
estimate: 2
status: done
gdd-anchor: gdd/gdd-breakout.md#§4-S1-挡板
completed-at: 2026-05-14
---

# S1-02 · 挡板移动

**Epic**：E1 · 核心玩法原型
**GDD 锚点**：§4 S1 · §5 挡板参数 · §7 操控
**点数**：2

## User Story

作为玩家，我可以用 ←→ 或 A/D 键左右移动挡板，以便接住弹回的球。

## 验收标准

- [ ] 挡板在屏幕底部 Y=680（底部上方 40px）
- [ ] 左右移动速度 500 px/s
- [ ] 不越出屏幕左右边界
- [ ] 挡板宽度 120px，高度 16px
- [ ] 颜色 `#e94560`

## 技术备注

- 场景：`paddle.tscn`（CharacterBody2D 或 StaticBody2D + 脚本控制）
- 输入映射：`move_left` `move_right`

