---
name: milestone-review
type: skill
status: active
description: Milestone-level review aggregating GDD review, sprint outcomes, postmortems, and stage transition checks.
---

<!-- OVER_LIMIT_REASON: 三方综合 + verdict 词汇 + 与 qa-gate / producer 联动，run.py 入口 + SOP 一次说清。 -->

# Milestone-Review · Milestone 节点评审

## 何时使用

milestone 节点（pre-production → production / production → polish / polish → release）做整体评审，决定是否进入下一 stage。

典型触发：
- "/milestone-review"
- "我们到 milestone 了，看看能不能进下一阶段"
- 由 stage 字段切换前自动调用

## 输入 / 触发条件

- 当前在项目根
- `PROJECT.md` 含 stage 字段
- 至少 1 个 sprint 已完成（有 sprint-reports）

## 流程步骤

1. **当前 stage 识别**：读 `PROJECT.md` stage 字段
2. **目标 stage 准入条件**（按 stage 不同有不同 checklist）：
   - **→ production**：8 节 GDD 完整 / 核心玩法 prototype 通过 / 引擎选定
   - **→ polish**：所有 epics done / smoke-check 全过 / 核心 bug = 0
   - **→ release**：release-checklist 通过 / consistency-check critical = 0
3. **聚合扫描**：调用 `review-all-gdds` + 最近 3 个 `smoke-check` 报告 + 全部 `retrospective` action items
4. **风险评估**：列出未完成项 / 阻塞项 / 推迟项
5. **决策建议**：通过 / 推迟 / 拆分（部分功能进下 stage，部分留当前）
6. **落盘**：`projects/<name>/reports/milestone-<from>-to-<to>-YYYY-MM-DD.md`
7. **stage 切换**：用户确认后由 AI 修改 `PROJECT.md` stage 字段

## 输出

- `projects/<name>/reports/milestone-<from>-to-<to>-YYYY-MM-DD.md`
- `PROJECT.md` 的 stage 字段更新（仅在用户拍板"通过"后）

## 引用

- 上游规划：v4 §6.1.1
- 相关 skill：`review-all-gdds` `smoke-check` `retrospective` `release-checklist`
- 相关 rule：`design-authoring` `project-structure`
- 相关 template：`templates/PROJECT.md.tpl`

## Known Limitations / Phase 2 Review Points

- [Phase 2 TODO] 各 stage 准入条件未在工作室宪法中正式定义，当前是本 skill 内的硬编码
- [Phase 2 TODO] "拆分"决策（部分进下 stage）的执行机制未设计
- [Phase 2 TODO] 多次反复 milestone-review 后的趋势分析未实现
