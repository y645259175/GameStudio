---
id: S2-06
epic: E5
priority: P1
estimate: 1
status: done
gdd-anchor: gdd/gdd-breakout.md#§7-UX
completed-at: 2026-05-14
---

# S2-06 · Game Over / Win UX 优化

## 用户故事
作为玩家，结束时我希望能选 SPACE 重玩或 ESC 回菜单，不被强制重启。

## 验收标准

1. Game Over 显示分数 + "SPACE: Restart   ESC: Menu" ✅
2. Win 显示分数 + 生命奖励 + "SPACE: Replay   ESC: Menu" ✅
3. SPACE 重置游戏从第 1 关开始 ✅
4. ESC 切换到主菜单（取消暂停状态）✅

## DoD
- [x] godot --check-only PASS

## Final Commit
`af96d08`
