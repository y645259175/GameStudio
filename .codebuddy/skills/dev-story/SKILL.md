---
name: dev-story
type: skill
status: active
description: Heavy-channel development workflow for a single user story, from ready to done with consistency-check gating.
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
3. **视觉资产前置检查**（新增，强制）：
   - 若 story 涉及视觉表现，先扫 `assets/` 是否齐
   - 缺资产 → 先调 `art-asset-pipeline`，或开 `[VISUAL_DEBT]` backlog story
   - 不允许直接默认 ColorRect 占位 → 详见 `engineer` agent 的"视觉资产红线"
4. **实现交互**：AI 提议代码改动，用户审 / 改 / 接受
5. **配置改动**：如涉及数值，按 `data-driven` rule 落到配置文件而非代码硬编码
6. **写测试**（按 `test-standards` rule）：
   - 单元 / 集成 / 冒烟按场景选
   - **真实玩家路径测试**：若 story 涉及玩家可见行为，必须有一条用 `Input.action_press` 等真实输入 API 的测试，不允许只通过直改内部状态（velocity / state）的 cheat 测试
7. **绕过决策 SOP**（新增）：遇到 bug / 障碍：
   - 绕过引入"假数据 / 假测试 / 架构妥协" → 必须修根因（spawn `debugger` 做 RCA）
   - 绕过仅延迟外部 API 等待 → 可绕过
   - 决定绕过时**必须**开 backlog story（带 priority + due milestone），不只是 retro
8. **consistency-check**：实现完成后**自动调用** `consistency-check`（v4 §4.5 Q5=D 双触发之一）
9. **DoD 自检**（新增）：
   - 视觉债务清单（`[VISUAL_DEBT]` 占位）已登记
   - 真实玩家路径测试存在且 PASS
   - 已知 issue 数 ≤ story 容量预算（默认 ≤ 2）
   - 否则路由 `story-done` 时会被 reviewer 拦下
10. **critical = 0 → 路由 `story-done`**；critical > 0 → 暴露问题 + 修订 + 重扫
11. **commit 建议**：`[story] <story-id>: <短描述>`（重通道）

## 自主模式补充

当 main agent 在自主模式下走 dev-story（无用户在线）：

- 视觉资产红线**仍然适用**——main agent 自己 spawn art-director 处理或登记 VISUAL_DEBT
- 真实玩家路径测试**仍然必须**——不允许 cheat-only PASS
- producer 至少 spawn 一次做 milestone gate
- 绕过决策仍按 SOP，不能为了"赶进度"违反

详见 `studio/docs/autonomous-mode-charter.md`（待建）。

## 输出

- 代码 / 配置 / 测试改动落盘
- consistency-check 报告
- 视觉债务清单 / 绕过决策记录
- 终端内本 story 实现摘要

## 引用

- 上游规划：v4 §2 §4.5 §6.1.1（带占位路由 4 之一）
- 相关 skill：`story-readiness` `consistency-check` `story-done` `setup-engine` `art-asset-pipeline`
- 相关 agent：`engineer`（主笔，含视觉资产红线）/ `art-director`（资产）/ `tester`（测试）/ `debugger`（RCA）
- 相关 rule：`commit-discipline` `data-driven` `test-standards` `design-authoring` `agent-spawn-contract`
- 占位路由：`studio/docs/engine-reference/<engine>/`（Phase 1 仅占位，Phase 2 起填充）

## 历史教训

- **2026-05-15 mario-1-1 自主运行**：engineer 全场用 ColorRect 占位 + 14 个 issue 全部以"记 retro"绕过 + cheat-only 测试 PASS。修复：本 skill 加入"视觉资产前置检查"、"真实玩家路径测试"、"绕过决策 SOP"、"DoD 自检" 四段。

## Known Limitations / Phase 2 Review Points

- [Phase 2 TODO] 引擎参考占位 Phase 1 仅有空文件，路由实质为 noop；Phase 2 后填充才有效
- [Phase 2 TODO] 测试自动化触发条件（哪种场景必跑哪种测试）未在 test-standards 中明确
- [Phase 2 TODO] autonomous-mode-charter 待写
