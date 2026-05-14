---
name: sprint-plan
description: Sprint planning facilitator that selects stories from backlog into the upcoming sprint based on velocity and priority.
allowed-tools:
disable: false
---

# Sprint-Plan · Sprint 规划

## 何时使用

新 sprint 起步时调用，从 backlog 中选 stories 进入本 sprint，产出 `sprint-plan.md`。

典型触发：
- "/sprint-plan"
- "开始新 sprint"
- 上一 sprint `smoke-check` 完成后路由

## 输入 / 触发条件

- 当前在项目根
- backlog 已有 ready-to-dev 的 stories（通过 `story-readiness`）
- 上一 sprint 的 velocity 数据（如有）
- 本 sprint 时长（默认 1 周，可配）

## 流程步骤

1. **容量评估**：基于上 1-3 sprint velocity 平均值定本 sprint 容量
2. **候选筛选**：从 backlog 选 ready-to-dev 的 stories（`story-readiness` 通过）
3. **优先级排序**：按 epic 优先级 + 依赖前置 + 用户偏好
4. **装载**：填充到本 sprint 容量上限，留 10-20% buffer
5. **风险标注**：标注高风险 / 强依赖外部资产的 stories
6. **交互修订**：用户拍板"换 / 加 / 减 / 拆"
7. **落盘**：`projects/<name>/sprints/sprint-<N>-plan.md`，按 `templates/sprint-plan.md` 填充
8. **carry-over 处理**：如上 sprint 有 carry-over，自动占位入本 sprint
9. **commit 建议**：`[story] sprint <N> plan`

## 输出

- `projects/<name>/sprints/sprint-<N>-plan.md`
- 终端内 sprint 装载摘要（容量 / 装载 / buffer / 风险数）

## 引用

- 上游规划：v4 §6.1.1
- 相关 skill：`story-readiness` `create-stories` `dev-story` `smoke-check`
- 相关 rule：`project-structure`
- 相关 template：`templates/sprint-plan.md.tpl`

## Known Limitations / Phase 2 Review Points

- [Phase 2 TODO] velocity 数据来源在 Phase 1 期间不准（无 git log），需手动估
- [Phase 2 TODO] buffer 比例（10-20%）的依据需要项目实战数据校准
- [Phase 2 TODO] 与 `daily-check` / `smoke-check` 的容量回算闭环未实现
