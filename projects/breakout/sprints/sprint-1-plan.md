---
sprint: 1
sprint_dates: 2026-05-14 → 2026-05-21
sprint_goal: Core gameplay playable - paddle, ball, bricks, lives, game over
velocity_previous: 0
velocity_planned: 10
status: active
---

# Sprint 1 计划

## Sprint Goal

**核心玩法可玩**：挡板移动、球弹射反弹、砖块消灭、生命扣减、Game Over / 通关。

## Story 清单

| # | Story ID | 标题 | 点数 | 优先级 | 状态 |
|---|---|---|---|---|---|
| 1 | S1-01 | Godot 项目初始化 | 1 | P0 | `[ ]` |
| 2 | S1-02 | 挡板移动 | 2 | P0 | `[ ]` |
| 3 | S1-03 | 球弹射与反弹 | 3 | P0 | `[ ]` |
| 4 | S1-04 | 砖块阵列 | 2 | P0 | `[ ]` |
| 5 | S1-05 | GameManager | 2 | P0 | `[ ]` |

**总计**：10 points · 5 stories · 全部 P0

## 依赖关系

```
S1-01 → S1-02 → S1-03 → S1-04 → S1-05
  ↑ 工程基础   ↑ 需要挡板   ↑ 需要球   ↑ 需要砖块   ↑ 整合全部
```

## Definition of Done

- [ ] 所有 story 验收标准通过
- [ ] 游戏可从主场景启动并完整运行一局
- [ ] L1 关卡可通关 / 可 Game Over
- [ ] commit message 合规
