---
name: architecture-decision
type: skill
status: active
description: Architecture Decision Record (ADR) authoring flow for significant technical decisions with context, options, and consequences.
---

<!-- OVER_LIMIT_REASON: ADR 模板 + 触发场景 + 与 retro 边界是 architect 写 ADR 时一次性参考。 -->

# Architecture-Decision · ADR 起草

## 何时使用

记录重大技术决策（引擎选型 / 网络架构 / 数据库选型 / 框架升级 / 跨项目通用方案）。每个 ADR 是一份独立文档，结构标准化。

典型触发：
- "/architecture-decision"
- "记录一下这个技术决策"
- "我要选引擎"
- 由 `setup-engine` 或 `dev-story` 遇到重大选型时引导

## 输入 / 触发条件

- 当前在项目根（项目级 ADR）或工作室根（工作室级 ADR）
- 决策主题明确

## 流程步骤

1. **范围判断**：是项目级还是工作室级？
   - 项目级 → 落 `projects/<name>/adr/`
   - 工作室级 → 落 `studio/docs/adr/`（**注**：当前 §6.1.1 仅列 studio/docs 3 件，无 adr/，§9.4 兜底审计时评估）
2. **占位路由 · 引擎 / 工具参考**：如涉及引擎选型，路由到 `studio/docs/engine-reference/`
3. **ADR 五段式**（按 `templates/adr.md.tpl`）：
   - **Status**: proposed / accepted / deprecated / superseded
   - **Context**: 为什么要做这个决策（中文）
   - **Options**: 候选方案对比（≥ 2 个）
   - **Decision**: 选哪个 + 理由（中文）
   - **Consequences**: 正面 / 负面影响 + 撤销成本
4. **关联 GDD / story**：在 ADR 末尾列受影响的 GDD 章节 / stories
5. **落盘**：`<scope>/adr/YYYY-MM-DD-<topic>.md`
6. **commit 建议**：`[story] adr: <topic>`（重通道，因为 ADR 影响深远）
7. **回溯链**：如本 ADR superseded 旧 ADR，旧 ADR status 改 superseded + 加链接

## 输出

- ADR 文档落盘
- 受影响 GDD / story 的反向链接

## 引用

- 上游规划：v4 §6.1.1（带占位路由 4 之一）
- 相关 skill：`setup-engine` `dev-story` `quick-design`
- 相关 rule：`commit-discipline` `project-structure`
- 相关 template：`templates/adr.md.tpl`
- 占位路由：`studio/docs/engine-reference/<engine>/`（Phase 1 占位）

## Known Limitations / Phase 2 Review Points

- [Phase 2 TODO] 工作室级 `studio/docs/adr/` 目录未在 §6.1.1 列出，§9.4 兜底审计批量决议
- [Phase 2 TODO] superseded 旧 ADR 的批量更新未自动化
- [Phase 2 TODO] ADR 数量增多后的索引 / 检索机制未设计（≥ 30 ADR 时需要）
