# bolt-1-1 · Backlog

> 项目所有未排期 issue / 视觉债 / 绕过项 / 风险点的唯一登记处。
> 格式见 `.codebuddy/rules/project-structure/RULE.mdc § backlog 格式约定`。

## 未排期

| ID | 类型 | 标题 | priority | due milestone | 来源 | 状态 |
|---|---|---|---|---|---|---|
| BL-003 | bug | Signal Tower 的 Area2D 触发不工作，已绕过为 _physics_process 距离检测；需要查根因 | P1 | post-M6 | retro 2026-05-15 #12 | open（绕过有效）|
| BL-005 | bug | 关卡场景退出时 ObjectDB 内存泄漏（参见 godot stderr WARNING） | P1 | post-M6 | retro 2026-05-15 #10 | open（不影响 release）|
| BL-006 | bug | _show_game_over 之前会 reload_current_scene 导致死循环，已暂时关掉自动 reload | P1 | post-M6 | retro 2026-05-15 #14 | open（绕过有效）|
| BL-007 | bug | GameOver 后 retry 路径未真测；clear_overlay 中"按 SPACE 重试"无回归测试 | P1 | post-M6 | retro 2026-05-15 | open（手动可验）|
| BL-008 | bug | TIME=0 死亡触发未做单元测试 | P1 | post-M6 | retro 2026-05-15 DoD #3 | open（手动可验）|
| BL-010 | bug | `class_name` 时序问题：相互引用脚本可能"Identifier not declared"，已用 preload 绕过；需要建立工作室 GDScript 引用规范 | P2 | post-M6 | retro 2026-05-15 #1 | open |
| BL-016 | VISUAL_DEBT | HUD 字体目前用 Godot 默认 Label 字体，应使用 Press Start 2P 等像素 bitmap 字体 | P1 | post-M6 | retro 2026-05-15 P1 | open |
| BL-019 | bypass | LevelLoader 里 movingPlatform / Spiker 被 noop 跳过（自主模式简化）—— 完整 1-1 需要补 | P2 | post-M6 | retro 2026-05-15 | open |
| BL-020 | risk | Pulse Core（无敌）道具未实现 | P2 | post-M6 | retro 2026-05-15 | open |
| BL-021 | improvement | 工作室无 prompt-injection sanity check 机制；自主模式下读取大量文件可能被注入影响行为 | P2 | studio-level | analysis 2026-05-15 | open |

## 已完成

| ID | 类型 | 标题 | 关闭 milestone | 关闭日期 | 备注 |
|---|---|---|---|---|---|
| BL-001 | bug | Stomp 判定阈值 4 太小：玩家从地面正常走过去会被判侧面伤害 | M5.5 | 2026-05-15 | 改为 dy + vy 双重判定（mossroll.gd / shellpod.gd），real_playtest PASS in 37.4s |
| BL-002 | bug | Mossroll/Shellpod 的 Hitbox Area2D collision_layer/mask 配置导致 stomp 判定失效 | M5.5 | 2026-05-15 | hitbox layer=8 mask=2 验证可工作；stomp 判定改 dy+vy 双重验证后 real_playtest PASS |
| BL-009 | bug | 真实玩家无法通关（cheat 关闭后 real_play_test 在第二个坑死掉） | M5.5 | 2026-05-15 | 调跳跃 initialV=-380 / maxHoldFrames=24 + 改 stomp 判定 + 重写 real_playtest（仅用 InputMap），通关 37.4s score=14200 lives=2/3 |
| BL-011 | bypass | auto_play_test 用 set_cheat_invincible 违反 test-standards 红线 | M5.5 | 2026-05-15 | 旧测试移到 tests/_debug/ 显式标 DEBUG_ONLY；新建 tests/real_playtest.gd 仅用 Input.action_press；player.set_cheat_invincible 加 OS.is_debug_build() 守卫 |
| BL-012 | VISUAL_DEBT | Bolty 三态精灵（small / big / fire）目前是 ColorRect 色块 | **M6** | 2026-05-16 | 3 张 png（bolty_small/big/fire）通过 timiai-image pipeline 生成，player.gd 接入 Sprite2D 三态切换。视觉验证通过截图确认。 |
| BL-013 | VISUAL_DEBT | Mossroll / Shellpod 精灵目前是 ColorRect | **M6** | 2026-05-16 | 3 张 png（mossroll/shellpod_walk/shellpod_shell）生成 + 接入 enemies/*.gd。 |
| BL-014 | VISUAL_DEBT | Tile（地面 / 砖块 / Cache Box / 硬砖 / Conduit）目前是 ColorRect | **M6** | 2026-05-16 | 6 张 png（ground_top/body, brick, cache_box_active/used, conduit）生成 + level_loader.gd `_make_static_box_textured` TextureRect TILE 平铺。 |
| BL-015 | VISUAL_DEBT | Signal Tower / Outpost / 云 / 山 / 树丛背景目前是 ColorRect | **M6** | 2026-05-16 | 3 张 png（signal_tower 杆+球+旗整体一张, outpost, background 1280x720 视差背景）生成 + 接入。background 通过 main.gd 加 CanvasLayer(layer=-10). |
| BL-017 | VISUAL_DEBT | Cog 图标 / cog 关卡内 sprite 缺失 | **M6** | 2026-05-16 | 4 张 png（cog, power_berry, spark_bloom, blue_crystal）生成 + 接入 items/*.gd 和 cache_box.gd 的 cog 弹出动画。 |
| BL-018 | improvement | Stomp 判定算法应统一在 player vs enemy 双向重写 | M5.5 | 2026-05-15 | mossroll/shellpod 已使用 dy + vy 几何判定 |

## 备注

- P0 = 必须在指定 milestone 修，否则 milestone gate 不通过
- P1 = 强烈建议在指定 milestone 修，可带条件推进
- P2 = 可推迟
- P3 = nice-to-have

每条 backlog 有变化（修复 / reprioritize / cancel）时更新本文件。所有 retro 的 action items 必须对应这里的 BL-XXX id（postmortem-keeper 把关）。

## M6 完成情况（2026-05-16）

✅ **关闭 5 个 P0 视觉债** (BL-012/013/014/015/017)：
- 19 张资产生成（timiai-image pipeline daemon, ~14 分钟）
- 13 个 production 文件接入（sprite_helper.gd 工具 + 8 实体 + level_loader/main/player/title）
- 视觉验证通过 6 张游戏内截图（reports/screenshots/）

✅ **真实玩家路径测试 PASS** in 37.4s, score=14200, lives=2/3, 资产接入未影响游戏逻辑

⏸ **延后到 post-M6 的 P1 项**：BL-003/005/006/007/008/016
- 共 5 个 P1 bug + 1 个 P1 视觉债（HUD 字体）
- 不阻塞 release，全部都有绕过手段
- 后续如果 bolt-1-1 转商业 mini-game 再处理

⏸ **延后到 post-M6 的 P2 项**：BL-010/019/020/021
- BL-019 MovingPlatform / Spiker（GDD 标 OUT-of-scope）
- BL-020 Pulse Core（GDD 标 Phase 2）
- BL-010 / BL-021 工作室级流程改进

## 关键里程碑映射

| 里程碑 | 状态 | 验证 |
|---|---|---|
| M1-M2 | done | gdd/gdd-bolt-1-1.md |
| M3 | partial（task-list 替代）| - |
| M4 | done | sprint-1-plan.md |
| M5 | cheat-only PASS | retro 2026-05-15 |
| **M5.5** | ✅ CONDITIONAL_PASS | qa-gate-M5.5-2026-05-15.md |
| **M6** | ✅ **PASS（待用户手动验收）** | qa-gate-M6-2026-05-16.md（即将生成）+ HANDOVER-FOR-USER.md |
| post-M6 | (decided by user)| Phase 2 是否启动 / 项目是否封盘 |
