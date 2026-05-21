# Calibration · designer · GOOD-03

## 前置场景
- GDD §3 mechanics 已有初版（DRAFT），engineer 实现后发现 jump 公式在高帧率下不稳定
- 需要 REFINE 模式精修 §3 数值

## 条件
- Mode: REFINE（不从零重写，基于现有内容修改）
- engineer 反馈的具体问题：jump_height 在 60fps vs 144fps 下差异 > 15%

## 产出摘要
- 只修改 §3 numeric