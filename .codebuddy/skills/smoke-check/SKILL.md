---
name: smoke-check
description: Sprint-end smoke test. Use when user says "sprint 收工 / smoke check / 冒烟测试 / 跑一遍". Runs consistency-check, integration spot-checks, velocity 5-number summary. Heavier than daily-check, lighter than milestone-review.
allowed-tools: read_file, write_to_file, list_dir, search_content, execute_command
disable: false
---

# smoke-check · Sprint 收尾冒烟

## 何时加载

- sprint 结束当天
- 用户说"sprint 跑完了 / smoke check / 验一遍"
- `retrospective` 之前必跑

**不加载场景**：日常 → `daily-check`；项目里程碑 → `milestone-review`。

## 输入契约

| 输入 | 来源 | 必需 |
|---|---|---|
| sprint plan | `projects/<name>/sprints/sprint-<N>-plan.md` | ✅ |
| sprint 内全部 stories | `stories/` | ✅ |
| 全部 commits（sprint 起止）| git log | ✅ |
| 引擎可执行 | `engine/<Engine>/` | 推荐（跑校验）|

## 流程

### Step 1 · sprint 完成度

| 类目 | 计算 |
|---|---|
| 计划点数 | sprint plan 总点数 |
| 实际完成点数 | done stories 总点数 |
| 完成率 | done/plan |
| 滚到下 sprint | not-done 数量 |

### Step 2 · 全量 consistency-check

调 `consistency-check` skill：
- GDD ↔ 代码 ↔ 数值 ↔ ADR

任何 DIRTY → 列出，决策修或 defer。

### Step 3 · 引擎冒烟（如可用）

godot：
```
godot --headless --check-only --path projects/<name>/game --quit
```
EXIT 0 即过。

### Step 4 · 单元测试全跑

按引擎跑既有测试套件，记 pass/fail。

### Step 5 · 5 数字摘要（velocity）

| # | 指标 |
|---|---|
| 1 | 计划点数 |
| 2 | 完成点数 |
| 3 | 完成率 |
| 4 | 平均 story 周期（commit 起止）|
| 5 | 阻塞次数（in-progress 中断 > 1 天的 story 数）|

### Step 6 · 输出 smoke 报告

`projects/<name>/sprints/sprint-N-smoke.md`：

```
# Sprint N Smoke Check - <date>
## 完成度
- 计划: X pts / 完成: Y pts / 完成率: Z%

## consistency
- GDD ↔ code: CLEAN / 列冲突
- 数值: CLEAN / 列冲突

## 引擎校验
- godot --check-only: PASS / FAIL

## 测试
- 单测 X/Y pass

## 5 数字
| 指标 | 值 |
|---|---|

## 风险 / 滚动
- 滚到下 sprint 的 story
```

### Step 7 · gate 决策

verdict：
- `READY_FOR_RETRO`：可以走 `retrospective`
- `BLOCKED`：有 critical 问题先修

## 输出契约

| 字段 | 内容 |
|---|---|
| `verdict` | `READY_FOR_RETRO` / `BLOCKED:<reason>` |
| `report_path` | sprint-N-smoke.md |
| `completion_rate` | float |
| `consistency` | CLEAN / DIRTY |
| `engine_check` | PASS / FAIL / SKIP |

## 调用的 agent

- `qa-lead` (opus)（gate 决策）
- `qa` (sonnet)（执行测试）
- `consistency-check` skill

## 加载的 rule

- `test-standards`
- `commit-discipline`

## 失败 / 降级

| 异常 | 策略 |
|---|---|
| 引擎未装 | 跳过 Step 3，标 SKIP |
| 单测套件缺 | 标 N/A，提醒 tester 补 |
| consistency DIRTY | 列冲突，让 reviewer/designer 决策 |

## 验收标准

- 报告落盘
- 5 数字齐全
- gate verdict 明确

## Known Limitations

- "阻塞次数"靠 commit 时间间隔启发式
- 多项目冒烟需多次跑（无聚合视图）
