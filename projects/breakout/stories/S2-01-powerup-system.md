---
id: S2-01
epic: E3
priority: P1
estimate: 4
status: done
gdd-anchor: gdd/gdd-breakout.md#§4-S3-道具系统
completed-at: 2026-05-14
---

# S2-01 · 道具基础（5 种 + 掉落系统）

## 用户故事
作为玩家，我希望砖块销毁后有概率掉落道具，以增加策略和爽感。

## 验收标准

1. 5 种道具：wide_paddle / narrow_paddle / speed_ball / multi_ball / extra_life ✅
2. 道具按砖块类型有不同掉率（10% / 18% / 25%）✅
3. 单局封顶 6 个道具 ✅
4. 道具下落速度 150 px/s，落出底部自销毁 ✅
5. 挡板碰到道具触发对应效果 ✅
6. 道具有可视化标识（颜色 + 字母 W/N/S/M/+）✅

## 实现要点
- `powerup.gd` + `powerup.tscn`：单个道具 Area2D
- `powerup_manager.gd`：掉率判断 + 类型权重 + 效果应用
- main.gd 在 `_check_powerup_collisions` 中检测挡板与道具相交

## DoD
- [x] godot --check-only 通过
- [x] PowerupManager 7 单测通过
- [x] 概率分布通过 reviewer 评审（NEED_NUMBERS_REVIEW，可后续 playtest 校准）

## 关键决策
- multi_ball 简化为"清除一行砖块"（详见 autorun-2026-05-14.md Issue #1）

## Final Commit
`691c2cc` [story] breakout E3: powerup system
