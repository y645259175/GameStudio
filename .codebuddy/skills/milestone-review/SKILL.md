---
name: milestone-review
description: Milestone-level review. Use when user says "里程碑评审 / milestone / 阶段总结 / phase gate". Aggregates GDD review, sprint outcomes, postmortems, and stage-transition checks (concept→design→dev→test→release).
allowed-tools: read_file, write_to_file, list_dir, search_content
disable: false
---

# milestone-review · 里程碑评审

## 何时加载

- 项目需要进入下一 phase（concept → design → dev → test → release）
- 关键 epic 完成
- 用户说"评审里程碑 / phase gate"

**不加载场景**：sprint 结束 → `smoke-check` + `retrospective`；单 GDD 章节 → `design-review`。

## 输入契约

| 输入 | 来源 | 必需 |
|---|---|---|
| 当前 phase | `PROJECT.md` | ✅ |
| GDD 全集 | `gdd/*.md` | ✅ |
| Epic 进度 | `epics/*.md` + index | ✅ |
| Sprint 历史 | `sprints/sprint-*.md` | ✅ |
| Retro 历史 | `sprints/sprint-*-retro.md` | ✅ |
| ADR 全集 | `adr/*.md` | 推荐 |

## 流程

### Step 1 · phase 转换标准

按 `studio/docs/workflow-guide.md`：

| 当前 → 目标 | 必需产物 |
|---|---|
| concept → design | GDD 8 节齐 + design-review APPROVED |
| design → dev | epics 拆完 + sprint 1 plan 就位 |
| dev → test | 核心 P0 epics 全 done + smoke 全 PASS |
| test → release | release-checklist 全过 |

### Step 2 · 子 skill 复用

| 子检查 | skill |
|---|---|
| GDD 评审 | `review-all-gdds` |
| 一致性 | `consistency-check`（full）|
| 当前 sprint 收尾 | `smoke-check` |
| 历史 retro 总结 | `postmortem-keeper` agent |

### Step 3 · 委托 producer 决策

调用 `producer` agent (opus)：
- 综合所有子检查
- 给 phase gate verdict：
  - `ADVANCE`：可进下 phase
  - `HOLD`：还差 N 项，列出
  - `RETREAT`：本 phase 还需大调整

### Step 4 · 输出里程碑报告

`projects/<name>/reports/milestone-<from>-to-<to>-<date>.md`：

```
# Milestone Review: <from> → <to>
## 综合 verdict: ADVANCE / HOLD / RETREAT
## 子检查
- GDD: ...
- 一致性: ...
- Sprint 总结（最近 3 个）: ...
## 风险评估
## Phase 转换决策
- 进 / 不进 + 理由
## 下一步建议
```

### Step 5 · 状态推进

如 ADVANCE：
- 修改 `PROJECT.md.phase` = 新 phase
- 在 `releases/`（如适用）记一笔

## 输出契约

| 字段 | 内容 |
|---|---|
| `verdict` | `ADVANCE` / `HOLD` / `RETREAT` |
| `report_path` | reports/milestone-*.md |
| `gate_passed` | bool |
| `outstanding` | 待办清单（HOLD 时）|

## 调用的 agent

- `producer` (opus)（gate 决策）
- `qa-lead` (opus)（质量验收）
- `postmortem-keeper` (sonnet)（历史复用）
- 必要时 `architect` (opus)（架构成熟度）

## 加载的 rule

- `commit-discipline`
- `project-structure`

## 失败 / 降级

| 异常 | 策略 |
|---|---|
| 子检查未全跑 | 强制补跑 |
| producer / qa-lead 意见冲突 | 用户介入仲裁 |
| 跨 phase 冲突大 | RETREAT + 触发 retro |

## 验收标准

- 里程碑报告齐全
- gate verdict 明确
- 转 phase 后 PROJECT.md 同步更新

## Known Limitations

- 子检查仍需手动触发（无完全自动 pipeline）
- 多项目里程碑联动（如 release 同步）暂无支持
