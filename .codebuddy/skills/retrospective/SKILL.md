---
name: retrospective
description: Sprint retrospective facilitator. Use when user says "复盘 / retro / sprint 总结 / 反思一下". Produces a postmortem capturing went well / hurt / action items. Calls postmortem-keeper for archival.
allowed-tools: read_file, write_to_file, list_dir, search_content
disable: false
---

# retrospective · Sprint 回顾

## 何时加载

- sprint 结束 + smoke-check 已 PASS
- 用户说"复盘 / retro"
- 项目里程碑后

**不加载场景**：单事件复盘（如线上事故）→ 写 incident 报告（无独立 skill，写到 reports/）；尚未 smoke → 先走 `smoke-check`。

## 输入契约

| 输入 | 来源 | 必需 |
|---|---|---|
| sprint smoke 报告 | `sprints/sprint-N-smoke.md` | ✅ |
| sprint plan | `sprints/sprint-N-plan.md` | ✅ |
| 当 sprint commits | git log | ✅ |
| 历史 retro | `sprints/sprint-*-retro.md` | 推荐 |

## 流程

### Step 1 · 收集事实

并行：
- 读 smoke 报告
- 读 plan
- `git log <range>`
- 列出本 sprint 完成 / 未完成 stories

### Step 2 · 三栏结构（中性提问）

按 `templates/retro.md`：

| Went Well | Hurt | Try Next |
|---|---|---|
| 哪些做得好 | 哪些痛 | 下个 sprint 改进 |

每栏 ≥ 2 条，避免空。

### Step 3 · action items

每条"Try Next"必须可落实：
- owner（哪个 agent / 角色）
- 截止 sprint
- 验收方式

### Step 4 · 历史 action 跟踪

读上 N 个 retro，看哪些 action 还未落地。如多次未落 → 重新评估或废弃。

### Step 5 · 落盘

`projects/<name>/sprints/sprint-N-retro.md`，调用 `postmortem-keeper` agent (sonnet) 把 retro 索引加到：
`projects/<name>/retros/index.md`（如不存在则建）。

### Step 6 · 输出摘要

简短摘要给用户：
- 3-5 行 highlights
- 1-3 条 action items 关键
- 是否有需立即升级 producer 的事项

## 输出契约

| 字段 | 内容 |
|---|---|
| `verdict` | `RETRO_FILED` |
| `retro_path` | sprint-N-retro.md |
| `action_count` | int |
| `escalations` | [...] |

## 调用的 agent

- `postmortem-keeper` (sonnet)（归档）
- `pm` (opus)（事实核对 + action 合理性）
- 如有跨 sprint 趋势 → `producer` (opus)

## 加载的 rule

- `language-policy`
- `project-structure`

## 失败 / 降级

| 异常 | 策略 |
|---|---|
| smoke 未跑 | 强制先 `smoke-check` |
| 三栏其中一栏空 | 引导补，不可全空 |
| 历史 action 大量未落 | 升级 producer |

## 验收标准

- 三栏齐 + 每栏 ≥ 2 条
- ≥ 1 条可落地 action
- 历史 action 状态更新（已落 / 推迟 / 废弃）

## Known Limitations

- 自动总结依赖 commits 文本，识别"为什么慢"靠人脑
- 跨 sprint 趋势分析仅看历史 retro 表面
