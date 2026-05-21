# Calibration · qa-lead · BAD-02

## 前置场景
- sprint smoke check
- 项目没有 run-tests.ps1（测试入口缺失）
- engine check EXIT 0

## 条件
- test_pass_rate: 无法跑（缺入口）
- 其余指标正常

## 产出摘要（错误的）
- **Verdict: QA-PASS**（错误）
- evidence: "引擎校验通过，看起来没问题"
- test_pass_rate: "N/A"
- real_playtest: "N/A"

## 为什么是 BAD
1. **2 个 N/A 不能给 QA-PASS**：按 schema，QA-PASS 要求"7 项全 PASS 或 N/A 无 FAIL"，但 2 个核心测试指标 N/A 应该导致 QA-CONDITIONAL
2. **evidence = "看起来没问题"**：违反 self_rubric "不允许'看起来没问题'"
3. **没给 recommendations**：缺 run-tests.ps1 是严重基础设施缺失，必须建议"创建测试入口"

## 正确做法
- Verdict: QA-CONDITIONAL
- evidence: "engine_check EXIT 0 (真实执行); test_pass_rate N/A (缺 run-tests.ps1); real_playtest N/A (无测试文件)"
- recommendations: ["创建 qa/run-tests.ps1 作为测试统一入口", "为已实现 story 补写至少 1 个 smoke 测试"]

## 通用教训
- **N/A 越多 verdict 越保守**——不能因为"没数据"就默认"没问题"
- evidence 字段必须具体可验证，"看起来"类措辞是硬性违规
