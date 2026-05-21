# Calibration · reviewer · GOOD-03

## 前置场景
- milestone gate（production → polish）代码质量维评审
- 本 milestone 有 12 个 commit，涉及 8 个文件

## 条件
- 11 个 commit 有正确 tag（[story]/[fix]/[chore]）
- 1 个 commit 缺 tag（直接写了 "update player.gd"）
- 1 个 ≥100 行改动的 commit 未经 reviewer

## 产出摘要
- commit_discipline_compliance: {total: 12, compliant: 11, non_compliant_examples: ["a1b2c3d update player.gd"]}
- unreviewed_large_changes: ["commit e4f5g6h 修改 level_loader.gd 128 行"]
- code_quality_verdict: MINOR_ISSUES
- milestone_verdict: MILESTONE-CONDITIONAL
- self_rubric: 6/6 PASS

## 为什么是 GOOD
1. 不因为 "91% compliant" 就给 PASS——发现 1 个 non-compliant 并列出具体 commit hash
2. 发现 unreviewed large change 并标注
3. MILESTONE-CONDITIONAL 正确（有 MINOR 但无 MAJOR）

## 通用教训
- milestone gate 不是"大部分好就行"——每个异常都要列出
- unreviewed_large_changes 是 milestone gate 专项检查项，不能跳过
