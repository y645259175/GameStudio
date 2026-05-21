# Calibration · art-director · BAD-02

## 前置场景
- 一批敌人立绘提交评审
- 色彩有偏差但不严重

## 条件
- 需要给具体的 hex 偏差数值
- 需要给 reject_remediation（如果 REJECT）

## 产出摘要（错误的）
- dimensions:
  - color: FAIL（reason: "颜色不太对"）（无 hex_violations）
  - 其余 4 维: PASS
- verdict: AD-REJECT
- reject_remediation: ["重做"]

## 为什么是 BAD
1. **color FAIL 但没给 hex_violations**：违反 schema "score=FAIL/MINOR 时 hex_violations 必须非空"
2. **"颜色不太对" = 泛泛之谈**：违反 AGENT.md "理由必须具体，不能是'风格不对'这种泛泛而谈"
3. **reject_remediation = "重做"**：不可执行——pipeline 不知道改什么
4. self_rubric 应该报 FAIL（"hex_violations 是否具体到文件名 + expected vs actual hex"）

## 正确做法
- hex_violations: ["enemy_slime_01.png 主体色 #4A90D9 偏离 style-guide 敌人色 #8B4513 Δhue=210°"]
- reject_remediation: ["调整 prompt 中颜色描述为 'warm brown #8B4513'", "或使用 image_edit 传入正确色板参考图"]

## 通用教训
- **art-director 的核心价值在"精确到 hex"**——泛泛说"颜色不对"等于没审
- reject_remediation 必须让 pipeline 知道"怎么改"而非"改不改"
