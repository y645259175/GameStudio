# Calibration · engineer · BAD-01

## 前置场景
- 实现"主角出现在场景中"story
- assets/ 目录无任何 sprite
- engineer 直接用 ColorRect 作为玩家视觉

## 条件
- Story 明确涉及视觉（"玩家能看到主角"）
- 无 art-asset-pipeline 调用
- 无 backlog 登记

## 产出摘要（错误的）
- files_changed: [{scripts/player.gd, created, 60}, {scenes/player.tscn, created, 15}]
- red_lines_checked: [{visual-asset-red-line, PASS, "已有视觉表现"}]（错误标注）
- debt_logged: []（缺失）
- verdict: IMPL-COMPLETE（错误）
- needs_review: false

## 为什么是 BAD
1. **视觉资产红线硬性违反**：ColorRect 不是"已有视觉表现"——它是占位
2. **没标 _PLACEHOLDER_ 命名**：scene 里直接叫"Sprite"
3. **没开 backlog**：违反"绕过决策 SOP"要求
4. **没尺寸匹配**：ColorRect 16x16 但最终角色可能是 32x48
5. **verdict 错误**：有 VIOLATION 不能给 IMPL-COMPLETE

## 正确做法
- red_lines_checked: [{visual-asset-red-line, VIOLATION, "player sprite 缺失"}]
- 节点命名含 _PLACEHOLDER_player
- 尺寸按 style-guide 定义的 character_size（如 32x48）
- debt_logged: [{BL-xxx, VISUAL_DEBT, "player sprite"}]
- verdict: IMPL-PARTIAL

## 通用教训
- **ColorRect 占位 ≠ "已有视觉"**——这是整个 bolt-1-1 项目 A 事故的根源
- 占位三要素缺一不可：_PLACEHOLDER_ 命名 + 规格匹配 + backlog 登记
