---
name: qa-gate
description: Quality gate check before sprint/release/phase advance. Use when user says "能不能发版 / quality gate / 通过质量门 / 进下一阶段". Aggregates test pass rate, consistency, code review status, manual smoke into a binary gate verdict (PASS / CONDITIONAL_PASS / FAIL). Centralizes what was scattered across qa-lead/smoke-check.
allowed-tools: read_file, list_dir, search_content, execute_command
disable: false
---

# qa-gate · 质量门检查

## 何时加载

- sprint 即将关闭，需要"能不能进下一 sprint"的明确判断
- milestone 评审 / phase gate 前
- release 前置关卡
- 用户问"现在质量怎么样"

**不加载场景**：sprint 内单 story 验收（走 `story-done`）；详细回归测试报告（走 `smoke-check`）。本 skill 是**汇总判断**而非执行测试。

## 输入契约

| 输入 | 来源 | 必需 |
|---|---|---|
| sprint smoke 报告 | `projects/<name>/sprints/sprint-N-smoke.md` | ✅ |
| 测试结果 | `qa/run-tests.ps1` 输出 | ✅ |
| consistency-check 最近报告 | `projects/<name>/reports/consistency-*.md` | 推荐 |
| 已知 bug / 阻塞项 | `projects/<name>/qa/regression-matrix.md` | 推荐 |
| GDD 验收标准 | `gdd/gdd-*.md §交付与验收` | 推荐 |

## 流程

### Step 1 · 收集 5 项 quality 指标

| 指标 | 数据来源 | 阈值（P0 release）|
|---|---|---|
| 1. 测试通过率 | run-tests.ps1 | ≥ 95% |
| 2. 引擎校验 | godot --check-only | EXIT 0 必须 |
| 3. consistency-check verdict | reports/consistency-*.md | CLEAN 或 MINOR |
| 4. 已知 P0 bug 数 | qa/regression-matrix.md | = 0 |
| 5. GDD 验收 P0 标准覆盖 | GDD §8 vs 实际功能 | 100% |

阈值按场景分级：

| 场景 | 测试 | 引擎 | consistency | P0 bug | GDD P0 |
|---|---|---|---|---|---|
| sprint 收尾 | ≥ 80% | EXIT 0 | CLEAN/MINOR | ≤ 1 | ≥ 80% |
| milestone gate | ≥ 90% | EXIT 0 | CLEAN | = 0 | 100% |
| release gate | ≥ 95% | EXIT 0 | CLEAN | = 0 | 100% |

### Step 2 · 委托 qa-lead 综合判断

调用 `qa-lead` agent (opus)，传入 5 项指标 + 场景：

- 全部达标 → `GATE_PASSED`
- 1 项轻微未达（如测试 87% 而非 90%）→ `CONDITIONAL_PASS` + 列条件
- 多项未达或关键项未达（引擎校验失败 / P0 bug 存在）→ `GATE_FAILED`

### Step 3 · 输出门控报告

`projects/<name>/reports/qa-gate-<scope>-<date>.md`：

```
# QA Gate Report - <scope>
## 综合 verdict: GATE_PASSED / CONDITIONAL_PASS / GATE_FAILED

## 5 项指标
| 指标 | 实际值 | 阈值 | 状态 |
|---|---|---|---|
| 测试通过率 | 95% | ≥ 90% | ✅ |
| ...

## 未达项详情（如有）
- 测试通过率 87% < 90%（差 3%）
  - 失败用例: ...
  - 建议: ...

## 阻塞项（CONDITIONAL_PASS 情况下）
- 必须在 N 天内修复

## 建议下一步
- ADVANCE: 进入下一 phase
- HOLD: 修阻塞项后复审
- RETREAT: 当前 phase 还不成熟
```

### Step 4 · 触发 / 路由

按 verdict：
- `GATE_PASSED` → 通知 producer 可推进 phase
- `CONDITIONAL_PASS` → pm 决定是否带条件推进
- `GATE_FAILED` → debugger / engineer 处理阻塞项

## 输出契约

| 字段 | 内容 |
|---|---|
| `verdict` | `GATE_PASSED` / `CONDITIONAL_PASS` / `GATE_FAILED` |
| `report_path` | reports/qa-gate-*.md |
| `metrics` | 5 项指标值 |
| `blockers` | 必须修复的 P0 项列表 |
| `next_action` | 推荐下一动作 |

## 调用的 agent

- `qa-lead` (opus, 主判断)
- `qa` (sonnet, 数据采集)
- 必要时 `producer` (opus, 仲裁 CONDITIONAL_PASS)

## 加载的 rule

- `test-standards`（阈值定义）
- `commit-discipline`

## 失败 / 降级

| 异常 | 策略 |
|---|---|
| 缺测试套件 | 该项标 N/A，verdict 不为 PASS |
| 引擎不可用 | 标 SKIP + warning |
| qa-lead 与 pm 意见冲突 | 升级 producer |

## 验收标准

- 5 项指标齐全（或显式 N/A）
- verdict 明确无歧义
- 报告落盘

## Known Limitations

- 阈值固定，不同项目类型可能需要调整（Phase 2 评估配置化）
- 主观项（如"GDD 验收"覆盖率）需 reviewer 二次判断
