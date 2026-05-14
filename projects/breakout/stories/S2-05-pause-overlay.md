---
id: S2-05
epic: E5
priority: P1
estimate: 1
status: done
gdd-anchor: gdd/gdd-breakout.md#§7-UX
completed-at: 2026-05-14
---

# S2-05 · 暂停遮罩

## 用户故事
作为玩家，我希望按 ESC 暂停游戏，再按 ESC 恢复。

## 验收标准

1. 按 ESC 切换暂停 ✅
2. 暂停时半透明黑色遮罩 + "PAUSED" + 提示文字 ✅
3. 暂停时物理冻结（球不动）✅
4. Game Over / Win 时按 ESC 回主菜单（不进暂停）✅

## 实现
- main.tscn 增加 PauseOverlay (CanvasLayer, process_mode=PROCESS_MODE_WHEN_PAUSED, layer=100)
- main.gd._toggle_pause / _unhandled_input 分支

## DoD
- [x] godot --check-only PASS

## Final Commit
`af96d08`
