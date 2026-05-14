---
id: S1-04
epic: E1
priority: P0
estimate: 2
status: done
gdd-anchor: gdd/gdd-breakout.md#§4-S2-砖块
completed-at: 2026-05-14
---

# S1-04 · 砖块阵列

**Epic**：E1 · 核心玩法原型
**GDD 锚点**：§4 S2 砖块系统 · §5 砖块布局 · §6 L1
**点数**：2

## User Story

作为玩家，我能看到砖块阵列，球击中砖块时砖块消失并得分。

## 验收标准

- [ ] 砖块尺寸 80×24 px，间距 4px
- [ ] L1 布局：5 行 × 12 列全 1HP 蓝色砖块
- [ ] 球碰到砖块 → HP-1 → HP=0 时销毁
- [ ] 销毁时发出 `brick_destroyed(position, brick_type)` 信号
- [ ] 1HP 砖块颜色 `#0f3460`

## 技术备注

- 场景：`brick.tscn`（StaticBody2D + CollisionShape2D）
- 关卡生成器：`level_generator.gd` 读取数据配置砖块矩阵
- 数据：`projects/breakout/data/levels.json`（L1 配置）

