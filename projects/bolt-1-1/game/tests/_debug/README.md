# tests/_debug · 仅调试用（违反 test-standards 红线，不可计入 milestone gate）

> **警告**：本目录下的测试**直接修改 player 内部状态**（velocity / is_jumping），违反 `test-standards` rule 与 `studio/docs/autonomous-mode-charter.md` 底线 2 的"真实玩家路径测试"要求。
>
> 这些测试**只能**用于：
> - 早期开发期的快速 smoke（验证脚本结构没坏）
> - 调试卡点时定位是关卡数值问题还是 AI 决策问题
>
> milestone gate / qa-gate 评审**不允许**把本目录下任一测试 PASS 计为通过证据。
> 真实测试见 `tests/real_playtest.gd`（仅用 InputMap action_press 操作玩家）。

## 文件清单

| 文件 | 说明 |
|---|---|
| `auto_play_test_DEBUG_ONLY.gd` | 旧 auto_play_test，使用 `set_cheat_invincible(true)` + 直改 velocity |
| `real_play_test_LEGACY_DEBUG.gd` | 看似真实但仍用 `_force_jump()` 直改 velocity.y，violates 红线 |

## Backlog 关联

- BL-011（cheat 模式违反 test-standards 红线）→ 状态：本目录 = 半修复（隔离了路径）。完整闭合需要 `tests/real_playtest.gd` PASS 才算 done。
