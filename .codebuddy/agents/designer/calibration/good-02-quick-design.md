# Calibration · designer · GOOD-02

## 前置场景
- sprint 中途发现需要决定"双跳是否消耗能量"
- 不值得写完整 GDD 章节，用 quick-design 决策

## 条件
- Mode: quick-design-decision（轻量）
- 需要给 2-3 个选项 + 推荐

## 产出摘要
- question: "双跳是否消耗能量（stamina）？"
- options: [
    {option: "无消耗", pros: ["简单实现", "新手友好"], cons: ["缺乏深度"]},
    {option: "固定消耗 20 stamina", pros: ["加决策层"], cons: ["需要 stamina 系统"]},
    {option: "第二跳高度递减 50%", pros: ["无需新系统", "自然限制"], cons: ["操作感可能不佳"]}
  ]
- recommendation: "选项 3（高度递减），因为与 pillars '轻量操作'一致且无新系统依赖"
- numeric_impact: "jump_height 第二跳从 200px → 100px，air_time 从 0.64s → 0.45s"

## 为什么是 GOOD
1. 每个选项有 pros/cons（不是只推荐一个）
2. recommendation 链接到 pillars（设计决策有据）
3. numeric_impact 具体（让 engineer 直接用数字）

## 通用教训
- quick-design 也要有数值影响评估——设计决策的最终表达是数字
- 推荐理由必须链接 pillars 或 GDD 已定内容
