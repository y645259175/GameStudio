# platformer-2 · Backlog

> 项目级 issue 登记。
> 创建：2026-05-18 · 配合 combo-A/B 验证 · 最后更新 2026-05-19

## 未排期

| ID | 类型 | 标题 | priority | due milestone | 来源 | 状态 |
|---|---|---|---|---|---|---|
| BL-P2-006 | improvement | jump 公式自洽性校准（GDD §3 风险登记） | P1 | M3 | designer DRAFT | open |
| BL-P2-008 | risk | gdd-3-mechanics.md 488 行超 22% 上限，考虑拆分到 level-design.md | P2 | M3 | designer 自查 | open |
| BL-P2-014 | improvement | story-005 计时挑战 + 关卡重置（GDD §4.4 World FSM）| P1 | M3 | gdd-3 §4.4 | open |
| BL-P2-015 | improvement | pipe_node.gd `_ready()` 同步 rotation_degrees（reviewer S-1） | P2 | M3 | story-004 reviewer | open |
| BL-P2-016 | improvement | level_manager.gd 用 group("player") 替代 name 检测（reviewer S-2）| P3 | M3 | story-004 reviewer | open |
| BL-P2-020 | improvement | GDD §4/§5/§6 未实现项补完（暂停/HUD/音效占位）| P1 | M3 | AP-10 后续 | open |

## 已完成

| ID | 类型 | 标题 | 完成时间 | 关联 |
|---|---|---|---|---|
| BL-P2-001 | improvement | story-002 player FSM 实现 | 2026-05-19 | player.gd 184 行 + reviewer APPROVE |
| BL-P2-002 | improvement | story-003 pipe puzzle 机制 | 2026-05-19 | 3 个文件 301 行 + reviewer APPROVE_WITH_NITS + shadow QA-PASS |
| BL-P2-004 | improvement | story-004 vertical slice 关卡 | 2026-05-19 | level_01.tscn + level_manager.gd |
| BL-P2-005 | improvement | 真实玩家路径测试（dev-story 红线）| 2026-05-19 | 3 测试文件 1543 行均含 action_press |
| BL-P2-007 | improvement | 视觉资产生成（4 张 png + .import 元数据 + 集成到 level_01）| 2026-05-19 | 二次重做：timiai pipeline.py + gpt-image-2 + quantize 16色 |
| BL-P2-010 | VISUAL_DEBT | level_01 ground_tile.png 资产 | 2026-05-19 | 32x32，已集成 |
| BL-P2-011 | VISUAL_DEBT | pipe_straight.png 资产 | 2026-05-19 | 48x48，已集成 |
| BL-P2-012 | VISUAL_DEBT | puzzle_door.png 资产 | 2026-05-19 | 32x96，已集成 |
| BL-P2-013 | VISUAL_DEBT | goal_flag.png 资产 | 2026-05-19 | 64x96，已集成 |
| BL-P2-017 | bug | level_01 无 Camera2D，镜头不跟随 | 2026-05-19 | player.tscn 加 Camera2D + zoom 2x + smoothing + limit |
| BL-P2-018 | bug | 无屏幕边界，玩家可走出 viewport | 2026-05-19 | level_01 加 LeftWall + RightWall + KillZone（重置回起点）|
| BL-P2-019 | VISUAL_DEBT | 资产质量糟糕（image_gen 路径）| 2026-05-19 | 改走 timiai pipeline → 视觉清晰可识别 |

## 备注

- 类型枚举：`bug` / `VISUAL_DEBT` / `bypass` / `risk` / `improvement`
- BL-P2-003 已撤销（合并到 BL-P2-014 计时挑战）
- BL-P2-009 编号跳过
