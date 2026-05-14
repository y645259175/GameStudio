---
id: S2-04
epic: E5
priority: P1
estimate: 2
status: done
gdd-anchor: gdd/gdd-breakout.md#§7-UX
completed-at: 2026-05-14
---

# S2-04 · 主菜单

## 用户故事
作为玩家，启动游戏时看到一个介绍游戏的主菜单，按 SPACE 进游戏。

## 验收标准

1. 标题 BREAKOUT 大字号居中 ✅
2. 副标题/操作说明可见 ✅
3. 按 SPACE 或 ENTER 进游戏 ✅
4. 按 ESC 退出 ✅
5. 背景沿用星空图，氛围一致 ✅

## 实现
- `scripts/main_menu.gd`
- `scenes/main_menu.tscn`
- `project.godot.run/main_scene` 改为 main_menu.tscn

## DoD
- [x] godot --check-only PASS

## Final Commit
`af96d08`
