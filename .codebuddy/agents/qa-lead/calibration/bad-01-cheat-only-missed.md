# Calibration · qa-lead · BAD-01

## 前置场景
- milestone gate 评估
- 项目有 run-tests.ps1，3 个测试文件全 PASS
- 但所有测试都直接修改 player.velocity / player.state 而非用 Input.action_press

## 条件
- test_pass_rate = 100%（3/3 PASS）
- real_playtest 指标：agent 没深入检查测试代码是否含 action_press

## 产出摘要（错误的）
- **Verdict: QA-PASS**（错误）
- evidence: "3/3 测试 PASS，覆盖率达标"
- real_playtest: "PASS"（错误标注——实际是 cheat-only 测试假装 PASS）

## 为什么是 BAD
1. **real_playtest 指标判定错误**：测试代码里没有 action_press/action_release，只有直接修改 velocity/state = cheat-only 测试
2. **evidence 不具体**：只说"3/3 PASS"没给行号，无法验证是否含真实输入路径
3. **违反 schema validation**：real_playtest 字段要求"必须有 action_press/action_release 的测试存在才能 PASS"

## 正确做法
- grep 测试代码是否含 "action_press" / "action_release" / "InputEvent"
- 如果无 → real_playtest = FAIL → verdict 降为 QA-BLOCK
- evidence 必须引用具体测试文件的具体行

## 通用教训
- **real_playtest 不能只看测试是否 PASS**——必须验证测试手段是否为真实输入路径
- 这是 AP-04（cheat-only 静默假 PASS）的 qa-lead 维度表现
