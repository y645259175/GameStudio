---
id: S2-07
epic: tech-debt
priority: P1
estimate: 1
status: done
gdd-anchor: gdd/gdd-breakout.md#§8-交付与验收
completed-at: 2026-05-14
---

# S2-07 · GameManager 单元测试套件

## 用户故事
作为开发者，需要 GameManager 这个全局单例的单测，保证 Sprint 2+ 不会被无意中破坏。

## 验收标准

1. 测试覆盖 reset_game / add_score / lose_life / add_life / register/destroy_brick / next_level / is_last_level ✅
2. 信号 emit 验证（game_over / level_cleared）✅
3. 不依赖 autoload（headless `-s` 模式可独立运行）✅
4. 24 个测试用例全绿 ✅

## 实现
- `tests/test_game_manager.gd`：通过 `preload` + `.new()` 实例化 GameManager 脚本

## DoD
- [x] 24/24 PASS

## Final Commit
`ce12f52`
