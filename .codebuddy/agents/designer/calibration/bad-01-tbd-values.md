# Calibration · designer · BAD-01

## 前置场景
- 新项目 M0，DRAFT 模式起草 GDD §3 mechanics
- 项目有 3 个 pillars + 明确的引擎（Godot 4.x）

## 条件
- 有足够信息给出起始数值
- 但 designer 偷懒用 [TBD] 占位

## 产出摘要（错误的）
- §3 numeric_spec: "jump_height: [TBD], move_speed: [TBD], gravity: 待游戏测试后决定"
- §5 boundary: "N/A — 需要数值确定后再考虑"
- line_count: 120（低于 200 行下限）
- verdict: DESIGN-DRAFT（自我降级，但降级不是借口）

## 为什么是 BAD
1. **[TBD] 违反 output-schema 硬性约束**：§3 要求"≥5 个具体值，不允许 [TBD]"
2. **§5 被