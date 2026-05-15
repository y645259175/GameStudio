---
name: smoke-check
type: skill
status: active
description: Sprint-end smoke test that runs consistency-check, integration spot-checks, and velocity 5-number summary.
---

# Smoke-Check · Sprint 末冒烟检查

## 何时使用

每个 sprint 末（1-2 周一次）手动调用，比 daily-check 更深入，含集成 / 冒烟 / velocity 五数统计。对应 v4 §4.5 流程 C。

典型触发：
- "/smoke-check"
- "sprint 结束了，跑一下冒烟"
- "/validate-sprint"（同义触发）

## 输入 / 触发条件

- 当前项目根
- 本 sprint 的 sprint-plan.md
- 本 sprint 范围内的 stories / commits / daily-reports

## 流程步骤

1. **范围确定**：从 sprint-plan.md 读起止时间，圈出 sprint 内的产出
2. **consistency-check**：跨 GDD ↔ stories ↔ 代码全量扫
3. **集成检查**：列出本 sprint 新增 / 改动的功能边界，标注是否做过端到端测试
4. **冒烟测试 checklist**：按项目 README 中的 smoke checklist 逐项跑（如未定义则提示用户补）
5. **velocity 5 数**：统计本 sprint 的 planned / done / carry-over / blocked / abandoned
6. **报告落盘**：`projects/<name>/sprint-reports/sprint-N-smoke.md`
7. **postmortem 触发**：如有 abandoned ≥ 1 或 blocked ≥ 2，提示调用 `retrospective` skill

## 输出

- `projects/<name>/sprint-reports/sprint-N-smoke.md`
- 终端内 velocity 5 数表 + 风险提示

## 引用

- 上游规划：v4 §4.5 流程 C、§6.1.1
- 相关 skill：`consistency-check` `retrospective` `daily-check`
- 相关 template：`templates/consistency-report.md.tpl`

## Known Limitations / Phase 2 Review Points

- [Phase 2 TODO] velocity 5 数定义需要在工作室宪法 `studio-handbook.md` 中正式定义
- [Phase 2 TODO] 集成测试自动化未接入（当前依赖人工跑 smoke checklist）
- [Phase 2 TODO] sprint-reports/ 目录命名规范未在 §6.1.1 锁定，待项目实战后定型
