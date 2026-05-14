# sprint-plan · Sprint 计划模板

> 本模板由 `sprint-plan` skill 调用。落盘到 `projects/<name>/sprints/sprint-<N>.md`。

---

```markdown
---
sprint: ${SPRINT_NUMBER}
sprint_dates: ${START_DATE} → ${END_DATE}
sprint_goal: ${SPRINT_GOAL}
velocity_previous: ${PREV_VELOCITY}
velocity_planned: ${PLANNED_VELOCITY}
status: planning            # planning / active / review / closed
---

# Sprint ${SPRINT_NUMBER} 计划

## Sprint Goal

${SPRINT_GOAL}

## Story 清单

| # | Story ID | 标题 | 点数 | 优先级 | 负责 | 状态 |
|---|---|---|---|---|---|---|
| 1 | — | — | — | P0 | — | `[ ]` |

## 容量

| 角色 | 可用人天 | 已分配 | 剩余 |
|---|---|---|---|
| — | — | — | — |

## 风险与依赖

| 风险 / 依赖 | 影响 | 缓解 |
|---|---|---|
| — | — | — |

## Definition of Done

- [ ] 所有 story 验收标准通过
- [ ] 单元测试覆盖 ≥ 80%
- [ ] consistency-check 通过
- [ ] GDD 引用闭合
- [ ] commit message 合规

## 回顾安排

- Sprint Review：${REVIEW_DATE}
- Sprint Retro：${RETRO_DATE}
```
