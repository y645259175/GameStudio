# retro · Sprint 回顾模板

> 本模板由 `retrospective` skill 调用。替换 `${...}` 占位符后落盘到 `projects/<name>/retros/sprint-<N>.md`。

---

```markdown
---
sprint: ${SPRINT_NUMBER}
sprint_dates: ${START_DATE} → ${END_DATE}
facilitator: ${FACILITATOR}
participants: [${PARTICIPANTS}]
status: draft              # draft / finalized
created_at: ${DATE}
---

# Sprint ${SPRINT_NUMBER} 回顾

## Sprint 目标回顾

| Sprint Goal | 达成？ | 偏差说明 |
|---|---|---|
| — | ✅ / ❌ / 🔄 | — |

## 关键数据

| 指标 | 值 | 说明 |
|---|---|---|
| Story 点承诺 | — | — |
| Story 点完成 | — | — |
| 完成率 | —% | — |
| Bug 新增 / 关闭 | — / — | — |
| 重通道 commit | — | — |
| 轻通道 commit | — | — |

## 🟢 做得好的（继续做）

1.
2.
3.

## 🔴 做得不好的（停止做 / 改进）

1.
2.
3.

## 🔵 新尝试（开始做）

1.
2.
3.

## Action Items

| # | Action | Owner | Due | 状态 |
|---|---|---|---|---|
| 1 | — | — | — | `[ ]` |

## 趋势对比

| 指标 | Sprint ${PREV} | Sprint ${CURRENT} | 变化 |
|---|---|---|---|
| 完成率 | —% | —% | — |
| Bug 积压 | — | — | — |

## 归档说明

本 retro 由 `postmortem-keeper` agent 归档，action items 跨 sprint 跟踪直到闭环。
```
