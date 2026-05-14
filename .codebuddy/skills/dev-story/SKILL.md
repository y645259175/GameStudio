---
name: dev-story
description: Heavy-channel development workflow for a single user story, from ready to done with consistency-check gating.
allowed-tools:
disable: false
---

# Dev-Story · 开发主流程（重通道）

## 何时使用

实现一条 user story 的标准开发主流程。是双通道 commit 中的"重通道"入口（v4 §2 / `commit-discipline` rule）。

区别于 `quick-fix`：
- `dev-story` = 重通道，story 驱动，含验收 + 一致性 + commit `[story]` tag
- `quick-fix` = 轻通道，无 story，commit `[quick]` `[fix]` `[refactor]` tag

典型触发：
- "/dev-story <story-id>"
- "开始做 story X"
- `sprint-plan` 后用户选定 story 自动调用

## 输入 / 触发条件

- 当前在项目根
- 目标 story 已 ready（`story-readiness` 通过）
- 当前 sprint 有容量

## 流程步骤

1. **加载 story**：读 story 文件 + GDD 锚点 + 相关引擎参考
2. **占位路由 · 引擎参考**：根据项目引擎（来自 `PROJECT.md`）路由到 `studio/docs/engine-reference/<engine>/` 对应章节
3. **实现交互**：AI 提议代码改动，用户审 / 改 / 接受
4. **配置改动**：如涉及数值，按 `data-driven` rule 落到配置文件而非代码硬编码
5. **写测试**（按 `test-standards` rule）：
   - 单元 / 集成 / 冒烟测试按场景选
6. **consistency-check**：实现完成后**自动调用** `consistency-check`（v4 §4.5 Q5=D 双触发之一）
7. **critical = 0 → 路由 `story-done`**；critical > 0 → 暴露问题 + 修订 + 重扫
8. **commit 建议**：`[story] <story-id>: <短描述>`（重通道）

## 输出

- 代码 / 配置 / 测试改动落盘
- consistency-check 报告
- 终端内本 story 实现摘要

## 引用

- 上游规划：v4 §2 §4.5 §6.1.1（带占位路由 4 之一）
- 相关 skill：`story-readiness` `consistency-check` `story-done` `setup-engine`
- 相关 rule：`commit-discipline` `data-driven` `test-standards` `design-authoring`
- 占位路由：`studio/docs/engine-reference/<engine>/`（Phase 1 仅占位，Phase 2 起填充）

## Known Limitations / Phase 2 Review Points

- [Phase 2 TODO] 引擎参考占位 Phase 1 仅有空文件，路由实质为 noop；Phase 2 后填充才有效
- [Phase 2 TODO] 测试自动化触发条件（哪种场景必跑哪种测试）未在 test-standards 中明确
- [Phase 2 TODO] 与 IDE / 编辑器集成未实现，当前依赖 AI 与用户对话推进
