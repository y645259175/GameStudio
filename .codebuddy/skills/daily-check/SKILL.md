---
name: daily-check
type: skill
status: active
description: End-of-day acceptance flow that runs consistency-check, summarizes progress, and produces a daily report.
---

# Daily-Check · 日终验收

## 何时使用

每天结束前手动调用，由 AI 主持完成"今日产出验收 + 明日计划"。对应 v4 §4.5 流程 E（每天 1 次，分钟级）。

典型触发：
- "/daily-check"
- "今天结束了，做个收尾"
- "帮我检查今天的产出"

## 输入 / 触发条件

- 当前项目根（必须在某个 `projects/<name>/` 下）
- 今日 git commit / 文件变更（如已 init git）/ 今日新建 stories
- 当前 sprint 计划（`sprint-plan.md`）

## 流程步骤

1. **范围扫描**：列出今天动了的文件、commit subject、新建 / 完成的 stories
2. **一致性检查**：调用 `consistency-check` skill（GDD ↔ stories ↔ 代码 ↔ 配置）
3. **进度汇总**：对照 sprint-plan.md，标记已完成 / 进行中 / 阻塞
4. **风险扫**：检查是否有 [Phase 2 TODO] 新增、Known Limitations 漏标
5. **日报落盘**：写入 `projects/<name>/daily-reports/YYYY-MM-DD.md`，含三段：
   - 今日完成（中文叙述）
   - 阻塞 / 风险（中文 + 错误信息保留英文）
   - 明日计划（条目）
6. **commit 建议**：如启用 git，建议 `[story] daily report YYYY-MM-DD`

## 输出

- `projects/<name>/daily-reports/YYYY-MM-DD.md`
- 终端内一段中文 summary（5-8 句话）

## 引用

- 上游规划：v4 §4.5 流程 E、§6.1.1 工作室级 8
- 相关 skill：`consistency-check` `smoke-check` `retrospective`
- 相关 template：`templates/daily-report.md.tpl`（**注**：当前 9 template 清单未列此模板，§9.4 兜底审计时评估是否补加）

## Known Limitations / Phase 2 Review Points

- [Phase 2 TODO] daily-report 模板未在 v4 §6.1.1 的 9 template 中，待 §9.4 兜底审计决定是否补
- [Phase 2 TODO] git 未 init 期间（Phase 1）依赖手动列变更，不准确；Phase 2 后可读 git log
- [Phase 2 TODO] 与 `smoke-check` 的边界：daily-check 是日终全量、smoke-check 是 sprint 末，目前流程相似度高，待真实运行后区分
