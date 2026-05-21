# Calibration · art-director · BAD-01

## 前置场景
- 一批 6 张环境资产（ground / brick / background 等）提交评审
- 5 维视觉评审全 PASS
- 但 .import 文件缺失（资产直接放入 game/assets/ 未经 godot import）

## 条件
- import_metadata 检查应为 false（.import 不存在）
- 按 schema：import_metadata=false → verdict 不能为 APPROVE

## 产出摘要（错误的）
- dimensions: 5 维全 PASS
- import_metadata: true（错误标注——实际 .import 文件不存在）
- verdict: AD-APPROVE（错误）

## 为什么是 BAD
1. **import_metadata 判定错误**：没有真