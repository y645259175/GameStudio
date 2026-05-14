---
name: retrospective
description: Sprint retrospective facilitator that produces a postmortem capturing what went well, what hurt, and action items.
allowed-tools:
disable: false
---

# Retrospective · Sprint 复盘

## 何时使用

sprint 结束后或重大事故后，用于沉淀经验、回写工作室级 postmortem。对应 v4 §6.1.1 工作室级 8。

典型触发：
- sprint 末（紧跟 `smoke-check` 之后）
- 出现严重 bug / 阻塞 / 返工后
- 用户主动调用："做个复盘"

## 输入 / 触发条件

- 当前项目根
- sprint 范围（如 sprint 末）或事故时间窗
- 相关 commits / stories / daily-reports / smoke-check 报告

## 流程步骤

1. **触发判断**：是 sprint retro 还是事故 retro？两类模板不同
2. **数据收集**：拉相关 commits / stories / 报告，AI 列出"事实清单"
3. **三问引导**（中文交互）：
   - 哪些做得好？
   - 哪些卡住了 / 痛？
   - 下一阶段要改什么（≤ 3 条 action items）
4. **回填模板**：按 `templates/retro.md.tpl` 填空
5. **双层落盘**：
   - 项目级：`projects/<name>/retros/sprint-N-retro.md`
   - 工作室级：如经验跨项目复用，**用户确认后**抽提到 `studio/postmortems/YYYY-MM-DD-<topic>.md`
6. **action items 路由**：每条 action 路由到具体 skill / rule 修订计划

## 输出

- 项目级 retro 报告
- 可选：工作室级 postmortem
- action items 清单（带责任 skill / rule）

## 引用

- 上游规划：v4 §6.1.1、`studio/postmortems/`
- 相关 skill：`smoke-check` `consistency-check`
- 相关 template：`templates/retro.md.tpl`

## Known Limitations / Phase 2 Review Points

- [Phase 2 TODO] "经验是否跨项目复用"的判据靠用户拍板，未来可总结判定规则
- [Phase 2 TODO] action items 与 `.codebuddy/plans/` 的衔接未定义（是否要建 plan 跟踪）
- [Phase 2 TODO] 事故 retro 模板（区别于 sprint retro）未在 9 template 清单中，待 §9.4 兜底审计
