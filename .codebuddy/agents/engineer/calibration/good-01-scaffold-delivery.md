# Calibration · engineer · GOOD-01

## 前置场景
- 新项目 M1 起步，story 是"创建 Godot 项目脚手架"
- 无前置代码，从零建 project.godot + main.tscn + main.gd
- engine: Godot 4.6.2

## 条件
- Story acceptance criteria: 5 项（project.godot 含 input mapping / viewport 配置 / main scene 能跑 / headless EXIT 0 / icon 占位）
- 无视觉资产需求（纯脚手架）

## 产出摘要
- files_changed: [{project.godot, created, 42}, {main.tscn, created, 18}, {scripts/main.gd, created, 12}, {icon.svg, created, 5}]
- acceptance_criteria_coverage: 5/5 全 covered，每项有 implementation_location
- engine_check_result: {exit_code: 0, stderr_summary: ""}
- red_lines_checked: [{visual-asset-red-line, N/A, "脚手架无视觉需求"}]
- debt_logged: []
- needs_review: false（4 文件 < 5，总行数 77 < 100）
- verdict: IMPL-COMPLETE
- self_rubric: 6/6 PASS

## 为什么是 GOOD
1. AC 全覆盖且每项有 file:line 定位
2. engine_check 真实执行（不是假设）
3. needs_review 判定正确（未超阈值不强制）
4. 不写测试（符合 dev-story SOP 分工）

## 通用教训
- 脚手架 story 的 red_lines 可以 N/A 但必须显式标注原因
- needs_review 阈值是硬性的（≥100 行或 ≥5 文件），不靠感觉
