# Calibration · engineer · GOOD-03

## 前置场景
- 用户报告"跳跃后偶尔卡在墙里"
- player.gd 现有 move_and_slide() 逻辑
- 回归风险：改碰撞逻辑可能影响其他移动行为

## 条件
- 轻通道 quick-fix（不走完整 dev-story 状态机）
- 需要定位根因 + 最小修复

## 产出摘要（quickfix-delivery）
- files_changed: [{scripts/player.gd, modified, 3}]（仅改 3 行）
- root_cause: "move_and_slide 后 is_on_wall() 判定时序问题：先检测 wall 再应用 snap_to_floor → 物理帧内残留 penetration"
- regression_risk: medium（改碰撞逻辑影响