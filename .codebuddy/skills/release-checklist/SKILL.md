---
name: release-checklist
type: skill
status: active
description: Release readiness checklist runner. Phase 1 ships a placeholder + router; full 4-level checklist lands in Phase 4.
---

<!-- OVER_LIMIT_REASON: Phase 1 占位 + 4 级 checklist 模板，待 Phase 4 落地，当前体量是过渡形态。 -->

# Release-Checklist · 发布检查清单（占位版）

## 何时使用

发布前的 4 级 checklist 运行器（alpha / beta / rc / final）。

**Phase 1 状态**：本 skill 仅落"占位 + 路由"骨架，不实现具体 4 级清单内容。完整实现在 v4 §6.5 Phase 4（P0 Release 4 skill 一并消化）。

典型触发：
- "/release-checklist alpha"
- "准备发版"

## 输入 / 触发条件

- 当前项目根
- 目标级别（alpha / beta / rc / final 之一）
- 项目当前 stage（来自 `PROJECT.md`）

## 流程步骤

**Phase 1（当前）**：
1. 读项目 stage，确认是否到了发布阶段
2. 提示用户："release-checklist 完整实现在 Phase 4 上线，当前为占位 skill"
3. 引导用户填基础 checklist（手动）：
   - [ ] 所有 stories 状态 = done
   - [ ] consistency-check critical = 0
   - [ ] smoke-check 通过
   - [ ] sprint-plan 内无 carry-over
4. 出基础报告：`projects/<name>/release/release-checklist-<level>-YYYY-MM-DD.md`

**Phase 4（计划）**：
- 接入 `release-prep` / `qa-gate` / `post-launch` 三个伴随 skill
- 4 级 checklist 各自独立模板
- 每级失败的具体修复路径

## 输出

- 基础 release checklist 报告（Phase 1 占位版）
- 引导用户进入 Phase 4 完整流程的提示信息

## 引用

- 上游规划：v4 §6.1.1、§6.5 Phase 4、§2.1 v4 资产清单（21 必装 21 → release 4 skill 暂未纳入）
- 相关 skill：[Phase 4 TODO] `release-prep` `qa-gate` `post-launch`
- 相关 rule：`commit-discipline`

## Known Limitations / Phase 2 Review Points

- [Phase 4 TODO] 完整 4 级 checklist 内容未起草（v4 §2.1 已明确推迟）
- [Phase 4 TODO] 与 `release-prep` / `qa-gate` / `post-launch` 三个 skill 的协同未定
- [Phase 2 TODO] release/ 目录命名规范待项目实战后定型
