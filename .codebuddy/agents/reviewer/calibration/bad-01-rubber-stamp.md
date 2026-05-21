# Calibration · reviewer · BAD-01

## 前置场景
- engineer 提交 ~200 行代码改动涉及 player + level_loader + game_manager
- tester 写了测试

## 条件
- 大改动，多系统涉及

## 产出摘要（错误的）
- dimensions:
  - correctness: PASS（"代码看起来正确"）
  - risk: PASS（"应该没有回归风险"）
  - style: PASS（"风格一致"）
  - commit_discipline: PASS
- critical_issues: []
- suggestions: []
- verdict: APPROVE

## 为什么是 BAD
1. **evidence 全部是空话**："看起来正确" / "应该没有" / "风格一致"——没有一条具体 file:line
2. **200 行改动 0 个 suggestion = 不可信**——reviewer 没有认真看
3. **violates self_rubric**: "evidence_lines ≥ 1 条" + "不允许'看起来没问题'"

## 正确做法
- 每维至少 1 条 file:line evidence
- 200 行改动至少给 2-3 个 suggestions（即使是 nits）
- 如真的完美无瑕（极少见），也要说"重点检查了 X/Y/Z，均未发现问题"

## 通用教训
- **橡皮图章 review 比不 review 更危险**——它给了虚假的安全感
- evidence 字段是 reviewer schema 的核心——空 evidence 的 APPROVE 视同未审
