---
name: quick-fix
type: skill
status: active
description: Light-channel quick-fix workflow for bugs, refactors, and small changes that don't justify a full story.
---

<!-- OVER_LIMIT_REASON: 轻通道 vs dev-story 重通道边界 + commit tag 约定，是日常最高频使用的 skill。 -->

# Quick-Fix · 快速修复（轻通道）

## 何时使用

不值得开 story 的小修小补：bug fix / 重构 / typo / 配置微调 / 依赖升级。是双通道 commit 中的"轻通道"入口。

典型触发：
- "/quick-fix"
- "改个 bug"
- "重构一下这个函数"
- "升级 Pillow 版本"

## 输入 / 触发条件

- 当前在项目根 或 工作室根（轻通道允许工作室级改动，如改 skill）
- 改动范围明确、单点、不跨系统

## 流程步骤

1. **范围判断**：AI 评估改动规模——如发现影响 ≥ 1 个 story / 跨 ≥ 2 个文件大改 → 路由到 `dev-story`
2. **tag 选择**（按 `commit-discipline` rule）：
   - bug 修复 → `[fix]`
   - 重构无功能变更 → `[refactor]`
   - 其他小改 → `[quick]`
3. **占位路由 · 引擎参考**：如涉及引擎代码，路由到 `studio/docs/engine-reference/<engine>/`
4. **实现**：AI 提议改动，用户审 / 改 / 接受
5. **测试**（按 `test-standards` rule）：bug fix 必加回归测试；refactor 必跑既有测试
6. **commit 建议**：`[<tag>] <短描述>`（轻通道，无 story-id）
7. **追溯**：如有相关 bug 报告，在 commit body 引用其 ID

## 输出

- 代码 / 配置改动落盘
- commit 建议（轻通道 tag）

## 引用

- 上游规划：v4 §2 §6.1.1（带占位路由 4 之一）
- 相关 skill：`dev-story` `consistency-check`（可选调用）
- 相关 rule：`commit-discipline` `test-standards`
- 占位路由：`studio/docs/engine-reference/<engine>/`（Phase 1 占位）

## Known Limitations / Phase 2 Review Points

- [Phase 2 TODO] 升级范围阈值（≥ 1 story / ≥ 2 文件）需项目实战校准
- [Phase 2 TODO] 与 `consistency-check` 关系：quick-fix 默认**不**强制调用 consistency，但用户可主动触发；判据需明确
- [Phase 2 TODO] 跨项目 quick-fix（同时改两个 project 的相同 bug）的处理流程未设计
