# qa-gate · PLAYBOOK

> CORE 见 `SKILL.md`。本文是详细 SOP。

## §1 metrics · 7 项指标 + 阈值

### 数据来源

| 指标 | 数据来源 |
|---|---|
| 1. 测试通过率 | `qa/run-tests.ps1` 输出 |
| 2. 引擎校验 | `godot --check-only` |
| 3. consistency-check verdict | `projects/<name>/reports/consistency-*.md` |
| 4. 已知 P0 bug 数 | `qa/regression-matrix.md` + backlog |
| 5. GDD 验收 P0 标准覆盖 | `gdd/gdd-*.md §交付与验收` vs 实际功能 |
| 6. 视觉债务（[VISUAL_DEBT]）| `stories/backlog.md` 中的 VISUAL_DEBT 数 |
| 7. 真实玩家路径测试（非 cheat-only）| `tests/` 下含 InputMap action_press 的测试 |

### 阈值（按 scope）

| scope | 测试 | 引擎 | consistency | P0 bug | GDD P0 | 视觉债 | 真路径测试 |
|---|---|---|---|---|---|---|---|
| sprint | ≥ 80% | EXIT 0 | CLEAN/MINOR | ≤ 1 | ≥ 80% | ≤ 5 | 推荐 |
| milestone | ≥ 90% | EXIT 0 | CLEAN | = 0 | 100% | ≤ 2 | **必须 ≥ 1** |
| release | ≥ 95% | EXIT 0 | CLEAN | = 0 | 100% | = 0 | **必须 ≥ 1 PASS** |

## §2 flow · 4 步流程

### Step 1 · 收集 7 项指标
按 §1 数据来源采集 + 对照 scope 阈值标 PASS / FAIL / N/A。

### Step 2 · 委托 qa-lead 综合判断
spawn `qa-lead` (opus)，传入 7 项指标 + scope：

- 全部达标 → `GATE_PASSED_MECHANISM`
- 1 项轻微未达（如测试 87% 而非 90%）→ `CONDITIONAL_PASS_MECHANISM` + 列条件
- 多项未达或关键项未达（引擎校验 fail / P0 bug 存在）→ `GATE_FAILED`

**禁止自宣 QUALITY_PROVEN / READY_FOR_RELEASE**（AP-10 修法）。

### Step 3 · 输出门控报告

落盘到 `projects/<name>/reports/qa-gate-<scope>-<date>.md`：

```markdown
# QA Gate Report - <scope>
## verdict: GATE_PASSED_MECHANISM / CONDITIONAL_PASS_MECHANISM / GATE_FAILED

## 7 项指标
| 指标 | 实际值 | 阈值 | 状态 |
|---|---|---|---|
| 测试通过率 | 95% | ≥ 90% | ✅ |
| ...

## 未达项详情
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

- `GATE_PASSED_MECHANISM` → 通知 producer 可推进 phase（仍需用户实玩验证才算 QUALITY_PROVEN）
- `CONDITIONAL_PASS_MECHANISM` → pm 决定是否带条件推进
- `GATE_FAILED` → debugger / engineer 处理阻塞项

## §3 output · 输出契约

| 字段 | 内容 |
|---|---|
| `verdict` | `GATE_PASSED_MECHANISM` / `CONDITIONAL_PASS_MECHANISM` / `GATE_FAILED` |
| `report_path` | `reports/qa-gate-*.md` |
| `metrics` | 7 项指标值 |
| `blockers` | 必须修复的 P0 项列表 |
| `next_action` | 推荐下一动作（ADVANCE / HOLD / RETREAT）|

## §4 fallback · 失败 / 降级

| 异常 | 策略 |
|---|---|
| 缺测试套件 | 该项标 N/A，verdict 不为 PASS |
| 引擎不可用 | 标 SKIP + warning |
| qa-lead 与 pm 意见冲突 | 升级 producer |

## §5 自主模式强制门

main agent 在自主模式推进 milestone：
- **必须**调本 skill，不允许"我自己判断 milestone PASS"
- 阈值按 milestone 列严格执行（不允许放宽）
- `GATE_FAILED` 时不允许进下一 milestone
- `CONDITIONAL_PASS_MECHANISM` 必须 spawn `producer` agent 仲裁

详见 `studio/docs/autonomous-mode-charter.md`。

## §6 调用的 agent / rule

- spawn：`qa-lead` (opus, 主判断) / `qa` (sonnet, 数据采集) / `producer` (仲裁)
- rule：`test-standards`（阈值定义）/ `commit-discipline`

## §7 验收

- 7 项指标齐全（或显式 N/A）
- verdict 明确无歧义（带 _MECHANISM 后缀）
- 报告落盘

## §Known Limitations

- 阈值固定，不同项目类型可能需要调整（Phase 2 评估配置化）
- 主观项（如 GDD 验收覆盖率）需 reviewer 二次判断
