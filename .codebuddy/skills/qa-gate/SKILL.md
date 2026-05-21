---
name: qa-gate
description: Quality gate check before sprint/release/phase advance. Aggregates 7 quality metrics into a binary gate verdict (GATE_PASSED_MECHANISM / CONDITIONAL_PASS_MECHANISM / GATE_FAILED). Use when user says "能不能发版 / quality gate / 进下一阶段".
allowed-tools: read_file, list_dir, search_content, execute_command
disable: false
---

# qa-gate · CORE

## 何时触发

- sprint 关闭 / milestone gate / release 前
- 用户问"现在质量怎么样" / "能不能发版" / "通过质量门"

**不触发**：单 story 验收（→ `story-done`）/ 详细回归测试（→ `smoke-check`）。本 skill 是**汇总判断**而非执行测试。

## 一键入口

```bash
python .codebuddy/skills/qa-gate/run.py --project <name> --scope <sprint|milestone|release>
```

## 红线（AP-10 修法）

- **[1]** AI 给的 verdict 必须带 `_MECHANISM` 后缀（GATE_PASSED_MECHANISM / CONDITIONAL_PASS_MECHANISM）—— 表明只是机制层判定，不等同用户实玩验证质量
- **[2]** 禁止自宣 `QUALITY_PROVEN` / `READY_FOR_RELEASE`（这类需用户实玩反馈触发）
- **[3]** 自主模式下推进 milestone **必须**调本 skill，不允许"我自己判断"
- **[4]** GATE_FAILED 不允许覆盖进下一 milestone

## 7 项指标（详见 PLAYBOOK §1）

测试通过率 / 引擎校验 / consistency-check / P0 bug 数 / GDD 验收覆盖 / 视觉债务 / 真实玩家路径测试

阈值按 sprint / milestone / release 三级（详见 PLAYBOOK §1 阈值表）。

## 何时升级到 PLAYBOOK

- 7 项指标的数据来源 + 阈值表 → §1 metrics
- 4 步流程（收集 → qa-lead 判断 → 报告 → 路由）→ §2 flow
- 输出契约 / 报告模板 → §3 output
- 失败 / 降级处理 → §4 fallback

## 历史

- AP-10 修法（2026-05-19）→ verdict 加 `_MECHANISM` 后缀
- 完整演化 → `ARCHIVE.md`
