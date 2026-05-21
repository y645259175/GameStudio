# Calibration · reviewer · GOOD-02

## 前置场景
- engineer 实现了关卡加载器（~150 行，涉及核心系统 level_loader.gd）
- tester 写了 3 个测试，但全部直接 set position 而非用 InputMap

## 条件
- 改动 ≥ 100 行 → needs_review: true（engineer 正确标注）
- 测试无 action_press / action_release

## 产出摘要
- dimensions:
  - correctness: PASS（"AC-1~3 全 covered; level_loader.gd:22 load_level() 正确解析 JSON"）
  - risk: PASS（"使用 ResourceLoader.load 非 preload，避免编译期绑定"）
  - style: PASS
  - commit_discipline: PASS
- critical_issues: [{qa/tests/test_level.gd, 15, "测试直接 set player.position 模拟移动，违反 test-standards 真实输入路径要求", "改用 Input.action_press('move_right') + await 物理帧"}]
- suggestions: []
- verdict: REQUEST_CHANGES
- self_rubric: 6/6 PASS

## 为什么是 GOOD
1. 即使 4 维代码本身全 PASS，**测试质量维发现 cheat-only 问题 → 正确给 REQUEST_CHANGES**
2. critical_issue 精确到行号 + 具体修改方案
3. 不因为"代码写得好"就忽视测试质量

## 通用教训
- **review 的第 4 维（测试质量）和前 3 维（代码本身）独立判定**
- 测试中的 cheat-only 模式是隐蔽的质量风险——reviewer 必须检查测试手段
