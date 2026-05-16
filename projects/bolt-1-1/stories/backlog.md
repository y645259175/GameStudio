# bolt-1-1 · Backlog

> 项目所有未排期 issue / 视觉债 / 绕过项 / 风险点的唯一登记处。
> 格式见 `.codebuddy/rules/project-structure/RULE.mdc § backlog 格式约定`。
>
> 命名 pivot 注：旧条目中 mario / goomba / koopa / coin / mushroom / fireFlower / oneUp / flagpole / castle / pipe 已在 2026-05-15 重命名（见 `docs/naming-map.md`）。本表中保留 BL id 不变以维持审计链。

## 未排期

| ID | 类型 | 标题 | priority | due milestone | 来源 | 状态 |
|---|---|---|---|---|---|---|
| BL-002 | bug | Mossroll/Shellpod 的 Hitbox Area2D collision_layer/mask 配置导致 stomp 判定失效 | P0 | M5 修复 | retro 2026-05-15 #11 | **done**（hitbox layer=8 mask=2 验证可工作；stomp 判定改 dy+vy 双重验证后 real_playtest PASS）|
| BL-003 | bug | Signal Tower 的 Area2D 触发不工作，已绕过为 _physics_process 距离检测；需要查根因 | P1 | M6 修复 | retro 2026-05-15 #12 | open |
| BL-004 | bug | json 实体 y 坐标系（NES 比例 256x240）与渲染分辨率（1280x720）不一致；signal_tower/outpost 已 force 对齐，其他实体需统一处理 | P0 | M5 修复 | retro 2026-05-15 #13 | partial（force-align 已经支撑 real_playtest PASS；统一坐标变换推迟）|
| BL-005 | bug | 关卡场景退出时 ObjectDB 内存泄漏（参见 godot stderr WARNING） | P1 | M6 修复 | retro 2026-05-15 #10 | open |
| BL-006 | bug | _show_game_over 之前会 reload_current_scene 导致死循环，已暂时关掉自动 reload | P1 | M6 修复 | retro 2026-05-15 #14 | open |
| BL-007 | bug | GameOver 后 retry 路径未真测；clear_overlay 中"按 SPACE 重试"无回归测试 | P1 | M6 修复 | retro 2026-05-15 | open |
| BL-008 | bug | TIME=0 死亡触发未做单元测试 | P1 | M6 修复 | retro 2026-05-15 DoD #3 | open |
| BL-010 | bug | `class_name` 时序问题：相互引用脚本可能"Identifier not declared"，已用 preload 绕过；需要建立工作室 GDScript 引用规范 | P2 | M6 修复 | retro 2026-05-15 #1 | open |
| BL-012 | VISUAL_DEBT | Bolty 三态精灵（small / big / fire）目前是 ColorRect 色块，需用 timiai-image 生成像素图 | P0 | M6 修复 | retro 2026-05-15 P1 | open |
| BL-013 | VISUAL_DEBT | Mossroll / Shellpod 精灵目前是 ColorRect，需生成像素图 | P0 | M6 修复 | retro 2026-05-15 P1 | open |
| BL-014 | VISUAL_DEBT | Tile（地面 / 砖块 / Cache Box / 硬砖 / Conduit）目前是 ColorRect，需生成像素图 | P0 | M6 修复 | retro 2026-05-15 P1 | open |
| BL-015 | VISUAL_DEBT | Signal Tower / Outpost / 云 / 山 / 树丛背景目前是 ColorRect，需生成像素图 | P0 | M6 修复 | retro 2026-05-15 P1 | open |
| BL-016 | VISUAL_DEBT | HUD 字体目前用 Godot 默认 Label 字体，应使用 Press Start 2P 等像素 bitmap 字体 | P1 | M6 修复 | retro 2026-05-15 P1 | open |
| BL-017 | VISUAL_DEBT | Cog 图标 / cog 关卡内 sprite 缺失 | P1 | M6 修复 | retro 2026-05-15 P1 | open |
| BL-018 | improvement | Stomp 判定算法应统一在 player vs enemy 双向重写为"玩家底部 vs 敌人顶部"几何判定，而非中心 Y 比较 | P1 | M6 修复 | analysis | **done**（mossroll/shellpod 已使用 dy + vy 几何判定，real_playtest PASS）|
| BL-019 | bypass | LevelLoader 里 movingPlatform / Spiker 被 noop 跳过（自主模式简化）—— 完整 1-1 需要补 | P2 | post-M6 | retro 2026-05-15 | open |
| BL-020 | risk | Pulse Core（无敌）道具未实现 | P2 | post-M6 | retro 2026-05-15 | open |
| BL-021 | improvement | 工作室无 prompt-injection sanity check 机制；自主模式下读取大量文件可能被注入影响行为 | P2 | studio-level | analysis 2026-05-15 | open |

## 已完成

| ID | 类型 | 标题 | 关闭 milestone | 关闭日期 | 备注 |
|---|---|---|---|---|---|
| BL-001 | bug | Stomp 判定阈值 4 太小：玩家从地面正常走过去会被判侧面伤害 | M5.5 | 2026-05-15 | 改为 dy + vy 双重判定（mossroll.gd / shellpod.gd），real_playtest PASS in 37.4s |
| BL-009 | bug | 真实玩家无法通关（cheat 关闭后 real_play_test 在第二个坑死掉） | M5.5 | 2026-05-15 | 调跳跃 initialV=-380 / maxHoldFrames=24 + 改 stomp 判定 + 重写 real_playtest（仅用 InputMap），通关 37.4s score=14200 lives=2/3 |
| BL-011 | bypass | auto_play_test 用 set_cheat_invincible 违反 test-standards 红线 | M5.5 | 2026-05-15 | 旧测试移到 tests/_debug/ 显式标 DEBUG_ONLY；新建 tests/real_playtest.gd 仅用 Input.action_press；player.set_cheat_invincible 加 OS.is_debug_build() 守卫 |

## 备注

- P0 = 必须在指定 milestone 修，否则 milestone gate 不通过
- P1 = 强烈建议在指定 milestone 修，可带条件推进
- P2 = 可推迟
- P3 = nice-to-have

每条 backlog 有变化（修复 / reprioritize / cancel）时更新本文件。所有 retro 的 action items 必须对应这里的 BL-XXX id（postmortem-keeper 把关）。

## M5.5 进度（2026-05-15 自主推进）

✅ 已完成：
- A.1 GDD 重写（gdd-bolt-1-1.md，370 行 8 节）
- A.2/A.3 数据 json 全部 bolt 命名
- A.4 遗留文件清理（sprint-1-plan / epics / run-game.bat / 删 task-list）
- A.5 9 个工作室 SOP 脱敏
- A.6 5 个 retro / archive 加 disclaimer
- A.7 godot --check-only EXIT 0
- D 部分修复：BL-001 / BL-002 / BL-009 / BL-011 / BL-018 closed
- E 真实玩家路径测试 PASS in 37.4s

⏸ 暂停（外部依赖）：
- B 阶段美术资产生成（依赖 timiai-image 平台）
- C 阶段资产接入（依赖 B）

🔲 待办：
- BL-003 / BL-005 / BL-006 / BL-007 / BL-008（P1，M6）
- BL-012 ~ BL-017（VISUAL_DEBT，依赖 B 阶段）
- BL-010 / BL-019 / BL-020 / BL-021（P2，post-M6）
