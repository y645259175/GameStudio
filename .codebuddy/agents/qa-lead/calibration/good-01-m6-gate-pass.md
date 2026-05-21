# Calibration · qa-lead · GOOD-01

## 前置场景
- 2D 平台跳跃项目，milestone M6（production → polish 阶段转换）
- 已有 run-tests.ps1 + real_playtest.gd（含 action_press 真实输入路径）
- 19 张真实资产已接入 + .import 元数据已 commit
- engine check EXIT 0 通过

## 条件
- qa-gate run.py 已跑出 7 项指标，其中 consistency-check = N/A（未跑）
- P0 bug = 0，VISUAL_DEBT = 0
- 真实玩家路径测试 PASS（37.4s 完成 score=14200）

## 产出摘要（verdict）
- **Verdict: QA-CONDITIONAL**（不是 QA-PASS，