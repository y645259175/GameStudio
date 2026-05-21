---
name: story-readiness
type: skill
status: active
description: Definition-of-Ready check that verifies a story has acceptance criteria, GDD anchor, estimate, and no blocking dependencies before entering a sprint.
---

<!-- OVER_LIMIT_REASON: Definition-of-Ready 5 项检查 + 阻塞依赖识别是判断 story 是否可入 sprint 的核心。 -->

# Story-Readiness · Story 就绪检查

## 何时使用

`sprint-plan` 选 stories 之前的过滤器。一条 story 必须 ready-to-dev 才能进 sprint。

典型触发：
- "/story-readiness <story-id>"
- "这个 story 能进 sprint 吗"
- `sprint-plan` 内自动调用（批量校验候选 backlog）

## 输入 / 触发条件

- 当前在项目根
- 目标 story（单条或批量）

## 流程步骤

1. **必填字段**（按 v4 `design-authoring` rule 派生）：
   - [ ] 验收标准 ≥ 3 条
   - [ ] GDD 锚点（章节引用存在）
   - [ ] 估算（XS/S/M/L/XL 之一）
   - [ ] 用户视角描述（"作为 X，我想 Y，以便 Z"格式）
2. **依赖检查**：
   - [ ] 前置 story 全部 done
   - [ ] 外部资产（美术 / 音频）已交付或明确计划
   - [ ] 引擎 / 工具假设可用（不依赖未实现的 skill）
3. **风险预警**：
   - 估算 = XL 时 → 提示拆分
   - 验收标准含模糊词（"流畅"、"美观"、"差不多"）→ 提示量化
4. **结果输出**：每条 story 标 `ready` / `not-ready` + 不通过的具体原因
5. **批量场景**：列出 ready 比例 / not-ready 原因 top 3 / 建议修订路径

## 输出

- 终端内 readiness 表（不落盘）
- 可选：在 story 文件 frontmatter 加 `status: ready` 字段

## 引用

- 上游规划：v4 §6.1.1
- 相关 skill：`create-stories` `sprint-plan` `dev-story`
- 相关 rule：`design-authoring`

## Known Limitations / Phase 2 Review Points

- [Phase 2 TODO] 模糊词检测当前是关键词正则，未来可由 LLM 语义判定
- [Phase 2 TODO] 估算 XL 拆分建议靠 AI 判断，无固定拆分模板
- [Phase 2 TODO] story frontmatter status 字段的全套枚举（draft / ready / in-progress / done / blocked / abandoned）需在 rule 中固化
