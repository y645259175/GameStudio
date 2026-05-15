# mario-1-1 · Backlog

> 项目所有未排期 issue / 视觉债 / 绕过项 / 风险点的唯一登记处。
> 格式见 `rules/project-structure/RULE.mdc § backlog 格式约定`。

## 未排期

| ID | 类型 | 标题 | priority | due milestone | 来源 | 状态 |
|---|---|---|---|---|---|---|
| BL-001 | bug | Stomp 判定阈值 4 太小：玩家从地面正常走过去会被判侧面伤害（应 ≥ 8） | P0 | M5 修复 | retro 2026-05-15 #9 | open |
| BL-002 | bug | Goomba/Koopa 的 Hitbox Area2D collision_layer/mask 配置导致 stomp 判定失效 | P0 | M5 修复 | retro 2026-05-15 #11 | open |
| BL-003 | bug | Flagpole 的 Area2D 触发不工作，已绕过为 _physics_process 距离检测；需要查根因 | P1 | M5 修复 | retro 2026-05-15 #12 | open |
| BL-004 | bug | json 实体 y 坐标系（NES 比例 256x240）与渲染分辨率（1280x720）不一致；flagpole/castle 已 force 对齐，其他实体需统一处理 | P0 | M5 修复 | retro 2026-05-15 #13 | open |
| BL-005 | bug | 关卡场景退出时 ObjectDB 内存泄漏（参见 godot stderr WARNING） | P1 | M6 修复 | retro 2026-05-15 #10 | open |
| BL-006 | bug | _show_game_over 之前会 reload_current_scene 导致死循环，已暂时关掉自动 reload | P1 | M6 修复 | retro 2026-05-15 #14 | open |
| BL-007 | bug | GameOver 后 retry 路径未真测；clear_overlay 中"按 SPACE 重试"无回归测试 | P1 | M6 修复 | retro 2026-05-15 | open |
| BL-008 | bug | TIME=0 死亡触发未做单元测试 | P1 | M6 修复 | retro 2026-05-15 DoD #3 | open |
| BL-009 | bug | 真实玩家无法通关（cheat 关闭后 real_play_test 在第二个坑死掉）—— 关卡数值需调 / AI 不智能 | P0 | M5 修复 | retro 2026-05-15 P3 | open |
| BL-010 | bug | `class_name` 时序问题：相互引用脚本可能"Identifier not declared"，已用 preload 绕过；需要建立工作室 GDScript 引用规范 | P2 | M6 修复 | retro 2026-05-15 #1 | open |
| BL-011 | bypass | autoplay 测试用 `_player.set_cheat_invincible(true)` + 直改 velocity；违反 test-standards 真实路径红线 | P0 | M5 修复 | retro 2026-05-15 P3 | open |
| BL-012 | VISUAL_DEBT | Mario 三态精灵（small / big / fire）目前是 ColorRect 色块，需用 timiai-image 生成像素图 | P0 | M6 修复 | retro 2026-05-15 P1 | open |
| BL-013 | VISUAL_DEBT | Goomba / Koopa 精灵目前是 ColorRect，需生成像素图 | P0 | M6 修复 | retro 2026-05-15 P1 | open |
| BL-014 | VISUAL_DEBT | Tile（地面 / 砖块 / 问号块 / 硬砖 / 管道）目前是 ColorRect，需生成像素图 | P0 | M6 修复 | retro 2026-05-15 P1 | open |
| BL-015 | VISUAL_DEBT | 旗杆 / 城堡 / 云 / 山 / 树丛背景目前是 ColorRect，需生成像素图 | P0 | M6 修复 | retro 2026-05-15 P1 | open |
| BL-016 | VISUAL_DEBT | HUD 字体目前用 Godot 默认 Label 字体，应使用 Press Start 2P 等像素 bitmap 字体 | P1 | M6 修复 | retro 2026-05-15 P1 | open |
| BL-017 | VISUAL_DEBT | Coin 图标 / coin 关卡内 sprite 缺失 | P1 | M6 修复 | retro 2026-05-15 P1 | open |
| BL-018 | improvement | Stomp 判定算法应统一在 player vs enemy 双向重写为"玩家底部 vs 敌人顶部"几何判定，而非中心 Y 比较 | P1 | M6 修复 | analysis | open |
| BL-019 | bypass | LevelLoader 里 movingPlatform / Piranha Plant 被 noop 跳过（自主模式简化）—— 完整 1-1 需要补 | P2 | post-M6 | retro 2026-05-15 | open |
| BL-020 | risk | Star（无敌）道具未实现 | P2 | post-M6 | retro 2026-05-15 | open |
| BL-021 | improvement | 工作室无 prompt-injection sanity check 机制；自主模式下读取大量文件可能被注入影响行为 | P2 | studio-level | analysis 2026-05-15 | open |

## 已完成

（暂无）

## 备注

- P0 = 必须在指定 milestone 修，否则 milestone gate 不通过
- P1 = 强烈建议在指定 milestone 修，可带条件推进
- P2 = 可推迟
- P3 = nice-to-have

每条 backlog 有变化（修复 / reprioritize / cancel）时更新本文件。所有 retro 的 action items 必须对应这里的 BL-XXX id（postmortem-keeper 把关）。
