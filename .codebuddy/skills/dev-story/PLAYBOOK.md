# dev-story · PLAYBOOK

> CORE 见 `SKILL.md`。本文是详细 SOP。

## §1 完整流程（11 步）

1. **加载 story**：读 story 文件 + GDD 锚点 + 相关引擎参考
2. **占位路由 · 引擎参考**：根据 PROJECT.md `engine` 路由到 `studio/docs/engine-reference/<engine>/`
3. **视觉资产前置检查**（强制）：
   - story 涉及视觉表现 → 先扫 `assets/`
   - 缺资产 → 调 `art-asset-pipeline` 或开 `[VISUAL_DEBT]` backlog
   - 不允许默认 ColorRect（详见 engineer agent §视觉资产红线）
4. **实现交互**：AI 提议代码改动，用户审 / 改 / 接受
5. **配置改动**：数值按 `data-driven` rule 落到配置文件而非硬编码
6. **写测试**（按 `test-standards` rule）：
   - 单元 / 集成 / 冒烟按场景选
   - **真实玩家路径测试**：玩家可见行为必须有 ≥1 条用 `Input.action_press` 等真实输入 API 的测试，禁止 cheat-only
7. **绕过决策 SOP**（见 §2）
8. **consistency-check**：实现完成后**自动调用**
9. **DoD 自检**（见 §3）
10. **critical = 0 → 路由 `story-done`**；critical > 0 → 暴露 + 修订 + 重扫
11. **commit 建议**：`[story] <story-id>: <短描述>`

## §2 bypass-policy · 绕过决策 SOP

遇到 bug / 障碍时：

| 绕过类型 | 决策 |
|---|---|
| 引入"假数据 / 假测试 / 架构妥协" | **必须修根因**（spawn `debugger` 做 RCA） |
| 仅延迟外部 API 等待 | 可绕过 |
| 任何场景下绕过决定 | **必须开 backlog story**（带 priority + due milestone），不只是 retro |

## §3 dod-checklist · DoD 自检（5 项）

实现完成后 reviewer 检查：
- [ ] 视觉债务清单（`[VISUAL_DEBT]` 占位）已登记
- [ ] **debt_logged 可 grep**：story 中提到的任何 debt/TODO 必须同时出现在 `stories/backlog.md` 中（grep `VISUAL_DEBT` / `TECH_DEBT` / story-id 必须命中 ≥ 1 行）
- [ ] 真实玩家路径测试存在且 PASS
- [ ] 已知 issue 数 ≤ story 容量预算（默认 ≤ 2）
- [ ] consistency-check 结果 critical = 0

任一未过 → reviewer 必须 REQUEST_CHANGES，不进 playtest_pending。

## §4 autonomous · 自主模式补充

main agent 在自主模式（无用户在线）走 dev-story：

- 视觉资产红线**仍然适用**——main agent 自己 spawn art-director 处理或登记 VISUAL_DEBT
- 真实玩家路径测试**仍然必须**——不允许 cheat-only PASS
- producer 至少 spawn 一次做 milestone gate
- 绕过决策仍按 §2，不能为了"赶进度"违反
- **playtest_pending → done 仍需真人实玩**：自主模式下应停在 playtest_pending 等待用户确认（AP-10 修法核心）

详见 `studio/docs/autonomous-mode-charter.md`（待建）。

## §5 输出

- 代码 / 配置 / 测试改动落盘
- consistency-check 报告
- 视觉债务清单 / 绕过决策记录
- 终端 story 实现摘要

## §6 引用

- 上游规划：v4 §2 / §4.5 / §6.1.1
- 相关 skill：`story-readiness` `consistency-check` `story-done` `setup-engine` `art-asset-pipeline`
- 相关 agent：`engineer`（主笔，含视觉资产红线）/ `art-director`（资产）/ `tester`（测试）/ `debugger`（RCA）
- 相关 rule：`commit-discipline` `data-driven` `test-standards` `design-authoring` `agent-spawn-contract`
- 占位路由：`studio/docs/engine-reference/<engine>/`（Phase 2 起填充）

## §Known Limitations

- [Phase 2 TODO] 引擎参考占位 Phase 1 仅空文件，Phase 2 后填充才有效
- [Phase 2 TODO] 测试自动化触发条件未在 test-standards 中明确
- [Phase 2 TODO] autonomous-mode-charter 待写
