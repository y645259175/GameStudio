---
id: S2-02
epic: E3
priority: P1
estimate: 2
status: done
gdd-anchor: gdd/gdd-breakout.md#§4-S3-道具系统
completed-at: 2026-05-14
---

# S2-02 · 道具持续效果计时回滚

## 用户故事
作为玩家，wide_paddle / narrow_paddle / speed_ball 应该在 8-10 秒后自动恢复，避免永久叠加。

## 验收标准

1. wide_paddle / narrow_paddle 持续 10 秒 ✅
2. speed_ball 持续 8 秒 ✅
3. 同类型重复拾取 → 重置计时（不叠加强度，刷新时长）✅
4. 反类型互相抵消（如 wide → 拾到 narrow，立刻切换到 narrow，wide 计时清掉）✅
5. multi_ball / extra_life 是一次性效果 ✅

## 实现要点
- `powerup_manager.gd` 用 Timer 节点 + Lambda 回调
- `_cancel_timer(key)` 在拾取新道具时取消同/反向计时

## DoD
- [x] godot --check-only 通过
- [x] PowerupManager.reset_run 清空 timers 测试通过

## Final Commit
`691c2cc`
