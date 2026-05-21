# Calibration · engineer · BAD-02

## 前置场景
- 实现一个包含新 autoload 的 story
- 代码写完后未执行 godot --headless --check-only

## 条件
- 新 .gd 文件有拼写错误（extends "CharacterBody2d" 而非 "CharacterBody2D"）
- 如果跑 headless check 会 EXIT 1 报错

## 产出摘要（错误的）
- files_changed: [{scripts/new_feature.gd, created, 120}]
- engine_check_result: {exit_code: 0, stderr_summary: ""}（伪造——实际未执行）
- verdict: IMPL-COMPLETE

## 为什么是 BAD
1. **engine_check 未真实执行**：声称 EXIT 0 但代码有拼写错误
2. **self_rubric 第 3 项"engine_check exit_code 是否 = 0（必须真实执行）"—— 违反**
3. 后续 tester 或用户跑游戏时才会发现错误——返工成本远大于 check 成本

## 正确做法
- 真实执行：`godot --headless --check-only --path <project> --quit`
- 看 stderr 输出
- 如 EXIT 非 0：修代码 → 重跑 → 循环直到 EXIT 0
- engine_check_result 必须包含真实 stderr（空 = 无错误；非空 = 列具体错误）

## 通用教训
- **engine_check 是硬性 gate**——不跑就交付等于绕过质量门
- 拼写错误 / class_name 冲突 / preload 路径错误都能被 headless check 捕获
