---
gdd_id: platformer2-3-mechanics
status: draft
last_review: 2026-05-18
sections_complete: [1, 2, 3, 4, 5, 6, 7, 8]
---

# GDD §3 · Mechanics · 玩法机制与数值规格

> 本章是 platformer-2 玩法的"规格说明书"。engineer agent 拿到本章应该可以直接落 `data/*.json` 和 GDScript 状态机骨架，不需要再问 designer。

---

## 概述

### 本章解决什么问题

§1 定义了 platformer-2 是什么、§2 定义了凭什么坚持。本章定义**玩家具体怎么玩、塔具体怎么响应、数值具体取多少**。

### 本章覆盖的三大机制簇

| 簇 | 章节 | 核心问题 |
|---|---|---|
| **移动簇** | §2.玩法循环 / §4.系统设计 (player FSM) | 玩家如何控制 Vex Pell 在塔内移动 |
| **解谜簇** | §4.系统设计 (puzzle / node) | 管道拼图怎么玩、什么是"解" |
| **计时簇** | §4.系统设计 (timer / world FSM) | 节点激活后的压力如何制造、如何重置 |

### 一句话总结

> Vex Pell 用经典平台手感（Move + Jump + WallCling）在塔内向上攀爬，到达节点后旋转拼接管段使信号流通，激活后必须在 10 秒内攀到下一层入口，否则节点锁死需重置。

---

## 玩法循环

### 玩家移动核心循环（按帧粒度）

```
[Idle] → 按方向键 → [Move] → 接地按 Space → [Jump]（可变跳高）
                                ↓ 接墙按方向键朝墙
                         [WallCling] 0.6s 后 → [Fall]
                                ↓
                              落地 → [Idle]
```

### 解谜核心循环（节点段）

```
进入节点交互范围 → 显示提示
  ↓ 按 E
[Carrying]（拾起场景预设管段）
  ↓ 走到 socket 上方按 E
[Placing]（放置 + 滚轮旋转 4 朝向）
  ↓ 所有 socket 填满 + 信号路径连通
[Solved] → 自动激活 → 触发 World.Timed
  ↓
玩家攀爬到下一层入口（10s 窗口）
  ├─ 成功 → 节点 [Permanent]，继续
  └─ 失败 → 节点 [Locked]，长按 R 0.8s → [Reset] → 回 [Idle]
```

### 计时核心循环

```
[Node.Activated] → 启动 10s 倒计时（受字段 timer_window_sec 控制）
  ↓ 每帧
HUD 计时条收缩 + 塔呼吸节律加速 (4s/cycle → 2s/cycle 渐变)
  ↓
玩家到达 next_layer.entry → 计时停止 → 节点 [Permanent]
  OR
计时归零 → 节点 [Locked] → 提示重置
```

---

## 视觉与美术

### 移动机制的视觉规格

| 状态 | 帧数（指引）| 视觉关键点 |
|---|---|---|
| Idle | 4 帧 / loop 1.2s | 呼吸起伏 1px，护目镜偶尔反光 |
| Move | 6 帧 / loop 0.5s | 工装裙摆飘动，扳手挂腰 |
| Jump 上升 | 2 帧 | 身体伸展，护目镜下垂 |
| Jump 顶点 | 1 帧 | 短暂悬停（apex hangtime 0.08s）|
| Jump 下落 | 2 帧 | 身体微收，准备 squash |
| Land | 1 帧 squash | 接地瞬间纵向压缩 60%，0.1s 恢复 |
| WallCling | 2 帧 / loop 0.4s | 双手抠墙，墙面有 1 帧抓痕生成 |

### 解谜机制的视觉规格

| 元素 | 视觉关键点 |
|---|---|
| 未激活管段 | 黄铜色 #C8995A，无光流 |
| 已拼接但路径不通 | 黄铜色，节点入口有 1px 红光闪烁（提示路径错）|
| 已拼接且路径通 | 蒸汽白光流沿管道流动，速度 60 px/s |
| 节点未激活 | 中央水晶冷锈红 #8B4A2B |
| 节点激活瞬间 | 0.5-0.8s 信号青 #5FB8B0 辉光从中心扩散到屏幕边缘（柔光，不爆炸）|
| 节点 Locked | 中央水晶变深灰，周围管道光流回退 |

### 计时机制的视觉规格

| 元素 | 视觉关键点 |
|---|---|
| 计时条 | 屏幕顶部蒸汽白光柱，从两端向中央收缩 |
| 塔呼吸加速 | 背景塔骨架的环境光从 4s/cycle 渐变到 2s/cycle |
| 最后 2s | 塔骨架色温从暖琥珀转向冷青，提示"塔在屏息"|
| 计时归零 | 全屏 0.3s 灰度叠加 + 节点变深灰 |

> 具体像素 / 缓动曲线 / 配色精确值由 ux-designer + art-director 在 ux-spec / art-bible 中定。

---

## 系统设计

### 玩家状态机（Player FSM）

```
                  ┌─────────┐
                  │  Idle   │◄──────────────┐
                  └────┬────┘               │
                  方向键 │                   │
                  ┌────▼────┐           落地│
                  │  Move   │               │
                  └────┬────┘               │
                  Space│                    │
                  ┌────▼────┐           ┌───┴────┐
                  │  Jump   │──顶点─────►  Fall  │
                  └─────────┘           └────────┘
                                            ▲
                                            │ 0.6s 超时
                                       ┌────┴──────┐
                                       │ WallCling │
                                       └───────────┘
                                            ▲
                                       接墙 + 方向朝墙
```

### 状态详细定义

| 状态 | 触发条件 | 退出条件 | 关键数值字段 |
|---|---|---|---|
| **Idle** | 接地 + 无输入 | 输入方向 / 跳跃 / 离地 | — |
| **Move** | 接地 + 方向输入 | 松开方向 / 跳跃 / 离地 | `player.move.max_speed` `accel` `decel` |
| **Jump** | Space 按下（接地或 coyote 内）| 速度 ≤ 0（转 Fall） | `player.jump.initial_velocity` `min_height_tiles` `max_height_tiles` |
| **Fall** | Jump 顶点过 / 走出平台 | 接地（转 Idle/Move）/ 接墙（转 WallCling） | `player.fall.max_speed` `gravity` |
| **WallCling** | Fall 中接墙 + 方向键朝墙 | 0.6s 超时 / 松方向 / 跳跃 | `player.wallcling.duration_sec` |

### 节点状态机（Node FSM）

```
[Idle (未激活)]
   │ 玩家进入交互范围
   ▼
[Solving]
   │ 所有 socket 填满 + 路径连通
   ▼
[Activated] ──触发 World.Timed
   │
   ├─ 玩家在 timer_window_sec 内到达 next_entry → [Permanent]
   └─ 计时归零 → [Locked]
                  │ 玩家长按 R 0.8s
                  ▼
              [Resetting] (0.3s 动画)
                  ▼
              [Idle] (管段散回原位)
```

### 世界状态机（World FSM）

| 状态 | 描述 | 视觉/音频影响 |
|---|---|---|
| **Calm** | 默认状态，无活跃节点 | 塔呼吸 4s/cycle，环境音柔和 |
| **Timed** | 有节点处于 Activated | 塔呼吸加速到 2s/cycle，计时条显示 |
| **Locked** | 当前节点 Locked | 塔灯由暖转冷，等待玩家重置 |
| **Ascending** | 玩家通过最终节点 | 全塔点亮过场，禁用所有玩家输入 5s |

### 管道拼图机制（Puzzle）

#### 管段类型（M2 范围）

| 类型 | 形状 | 朝向数 | 出现时机 |
|---|---|---|---|
| **Straight** | 直管 ─ | 2（横/竖） | 节点 A 起 |
| **Bend** | 弯管 90° ┐ | 4（4 个角） | 节点 B 起 |
| **TJunction** | T 形分叉 ┬ | 4（4 个朝向） | 节点 B 起（仅 1 个）/ 节点 C（多个）|

#### Socket 与连通规则

- 每个节点是一个 N×N 网格（N 见 `data/nodes.json`，节点 A=2×2，B=3×3，C=4×4）
- 每个网格有 0-4 个 socket（朝向 4 个相邻格）
- 节点有 1 个**入口 socket**（信号源，固定位置）和 1-3 个**出口 socket**（节点 C 有 1 出口但 3 入口）
- "解"的定义：从入口 socket 出发，沿管段（朝向必须吻合）能到达**所有**出口 socket

#### 旋转规则

- Carrying 状态下按滚轮（或手柄 RB）旋转管段 90°
- Placing 时如果朝向不吻合相邻已放置管段，仍可放置但路径不连通（视觉红光闪烁提示）
- 玩家可以拿起已放置的管段重新调整（按 E 在 socket 上）

### Hazard 机制（M2 仅 1 种）

#### 蒸汽喷孔（SteamVent）

| 字段 | 基准值 | 说明 |
|---|---|---|
| period_sec | 2.5 | 每 2.5s 喷射 1 次 |
| active_sec | 1.0 | 每次喷射持续 1.0s |
| damage | 0 | **不掉血**（无血量系统），但触碰将玩家推回 1 tile + 0.3s 失控 |
| visual_warning_sec | 0.4 | 喷射前 0.4s 喷孔预热（红光）|
| placement | 攀爬段 B 起 | 每个攀爬段最多 2 个 |

> 蒸汽喷孔不杀死玩家（违反 P1 手感），仅打断攀爬节奏 → 计时段失败 → 节点 Locked → 重置。

---

## 数值与平衡

### 玩家移动数值（`data/player.json`）

| 字段路径 | 基准值 | 单位 | 来源 / 说明 |
|---|---|---|---|
| `move.max_speed` | 180 | px/s | 经典平台手感参考，不能更慢（违反 P1）|
| `move.accel` | 1200 | px/s² | 0.15s 内达到 max_speed |
| `move.decel` | 1500 | px/s² | 比 accel 略快，落点可控 |
| `jump.initial_velocity` | 480 | px/s | 决定最大跳高 |
| `jump.gravity_up` | 1600 | px/s² | 上升期重力 |
| `jump.gravity_down` | 2200 | px/s² | 下落期重力（更快，避免 floaty）|
| `jump.min_height_tiles` | 1.8 | tile | 短按跳高（≈ 58 px）|
| `jump.max_height_tiles` | 4.5 | tile | 长按跳高（≈ 144 px）|
| `jump.apex_hangtime_sec` | 0.08 | s | 顶点悬停（手感润色）|
| `jump.coyote_time_sec` | 0.10 | s | 离地后还能跳的宽容期 |
| `jump.input_buffer_sec` | 0.12 | s | 落地前提前按跳的缓冲 |
| `fall.max_speed` | 600 | px/s | 终端速度 |
| `wallcling.duration_sec` | 0.6 | s | 自动脱落 |
| `wallcling.slide_speed` | 60 | px/s | 抓墙时缓慢下滑 |

### 节点 / 拼图数值（`data/nodes.json`）

| 字段路径 | 基准值 | 单位 | 说明 |
|---|---|---|---|
| `default.timer_window_sec` | 10.0 | s | 激活后到下一层入口的窗口 |
| `default.solve_median_target_sec` | 60 | s | 拼图中位时长目标（设计假设）|
| `default.reset_hold_sec` | 0.8 | s | 长按 R 重置时长 |
| `default.reset_animation_sec` | 0.3 | s | 重置动画时长 |
| `nodes.A.grid_size` | 2 | tile | 2×2 网格 |
| `nodes.A.required_pieces` | ["straight", "straight"] | enum[] | 仅直管 2 段 |
| `nodes.A.timer_window_sec` | 12.0 | s | 节点 A 宽松（教学）|
| `nodes.B.grid_size` | 3 | tile | 3×3 |
| `nodes.B.required_pieces` | ["straight", "bend", "bend", "tjunction"] | enum[] | 弯管首次出现 |
| `nodes.B.timer_window_sec` | 10.0 | s | 标准 |
| `nodes.C.grid_size` | 4 | tile | 4×4 |
| `nodes.C.required_pieces` | ["straight"x3, "bend"x3, "tjunction"x2] | enum[] | 三段汇流 |
| `nodes.C.timer_window_sec` | 10.0 | s | 标准（拼图本身已最难，不再压计时）|

### Hazard 数值（`data/hazards.json`）

| 字段路径 | 基准值 | 单位 | 说明 |
|---|---|---|---|
| `steam_vent.period_sec` | 2.5 | s | 喷射周期 |
| `steam_vent.active_sec` | 1.0 | s | 喷射持续 |
| `steam_vent.warning_sec` | 0.4 | s | 预热时长 |
| `steam_vent.knockback_tiles` | 1 | tile | 击退距离 |
| `steam_vent.stun_sec` | 0.3 | s | 失控时间 |

### 项目级 / 世界数值（`data/project.json` / `data/world.json`）

| 字段路径 | 基准值 | 单位 | 说明 |
|---|---|---|---|
| `pacing.death_to_respawn_sec` | 1.5 | s | 摔落 / 失败到复活 |
| `pacing.respawn_invincible_sec` | 0.5 | s | 复活短暂无敌（防 hazard 连环触发）|
| `tower.breath_cycle_sec` | 4.0 | s | 默认呼吸 |
| `tower.breath_timed_cycle_sec` | 2.0 | s | 计时段加速呼吸 |

### 平衡公式

#### 跳跃高度公式（验证用）

```
max_height = jump.initial_velocity² / (2 × jump.gravity_up)
           = 480² / (2 × 1600)
           = 230400 / 3200
           = 72 px
```

⚠️ 与字段 `jump.max_height_tiles = 4.5 tile = 144 px` 不一致 → engineer agent 实现时**以 4.5 tile 为目标**反推 initial_velocity 与 gravity，本表的 480/1600 仅为初始猜测，M1 调参时需校准。

#### 关卡总时长估算

```
target_level_sec = teaching(30) + nodeA_solve(60) + climb_A(8) 
                 + nodeB_solve(90) + climb_B(10) 
                 + nodeC_solve(120) + final(60)
                 ≈ 378s ≈ 6.3 min（中位玩家） 
                 上界含失败重试 ≈ 600s（10 min）符合 §1 假设
```

---

## 内容与节奏

### M2 vertical slice 关卡示意（ASCII）

```
         ╔═══════════════════╗
         ║   顶端激活腔       ║   ← 玩家激活后过场
         ║  ★ Final Node    ║
         ╠═══════════════════╣
         ║                   ║
         ║   攀爬段 B        ║   ← 蒸汽喷孔 ×2
         ║   ╳ ╳             ║
         ║                   ║
         ╠═══════════════════╣
         ║                   ║
         ║   节点 C (4×4)    ║   ← 3 输入 1 输出
         ║   [pipe puzzle]   ║
         ║                   ║
         ╠═══════════════════╣
         ║   攀爬段 A        ║   ← 直上型，无 hazard
         ╠═══════════════════╣
         ║                   ║
         ║   节点 B (3×3)    ║   ← 弯管首次出现
         ║   [pipe puzzle]   ║
         ║                   ║
         ╠═══════════════════╣
         ║   节点 A (2×2)    ║   ← 教学拼图
         ║   [pipe puzzle]   ║
         ╠═══════════════════╣
         ║                   ║
         ║   入塔教学腔       ║   ← 跳跃 + WallCling
         ║   [小跳 + 抓墙]   ║
         ║                   ║
         ║   ▼ 入口          ║
         ╚═══════════════════╝
```

### 难度曲线

| 节点 | 拼图复杂度 | 计时压力 | 攀爬压力 | 综合 |
|---|---|---|---|---|
| A | 1（直管 2 段，2 朝向）| 低（12s 窗口）| 无 hazard | ★ |
| B | 3（4 段 + T 形）| 中（10s）| 无 hazard | ★★ |
| 段 B | — | — | 蒸汽喷孔 ×2 | ★★★（攀爬段单独峰值）|
| C | 5（8 段 + 3 输入 1 输出）| 中（10s）| — | ★★★★（拼图峰值）|

### 教学节奏

| 学习点 | 出现位置 | 教学方式 |
|---|---|---|
| Move | 入塔（0-5s）| 强制必走 |
| Jump 短跳 | 入塔（5-15s）| 1 tile 高的台阶 |
| Jump 长跳 | 入塔（15-25s）| 必须长按才能上的台阶 |
| WallCling | 入塔（25-30s）| 必须抓墙才能上的窄井 |
| Pickup pipe | 节点 A | 节点入口处管段会发光指引 |
| Place pipe | 节点 A | socket 高亮 + 朝向预览（半透明）|
| Rotate | 节点 A | Carrying 时滚轮提示 0.5s 浮现一次 |
| Timer | 节点 A 激活 | 计时条出现 + 第一次伴随塔呼吸加速 |
| Reset | 故意让玩家失败一次 | 超时后中央显示"按住 R" |

### 内容预算（M2 完整列表）

| 类别 | 数量 |
|---|---|
| 关卡 | 1 |
| 节点 | 3（A/B/C）|
| 管段类型 | 3（直 / 弯 / T）|
| Hazard 类型 | 1（蒸汽喷孔）|
| Player 状态 | 5（Idle/Move/Jump/Fall/WallCling）|
| World 状态 | 4（Calm/Timed/Locked/Ascending）|
| Node 状态 | 5（Idle/Solving/Activated/Permanent/Locked + Resetting 中间态）|

---

## UX 与 HUD

### 输入映射（M2 范围）

| 动作 | 键盘 | 手柄 |
|---|---|---|
| 左右移动 | A / D 或 ← / → | 左摇杆 / 十字键 |
| 跳跃（可变跳高）| Space（短按低跳，长按高跳）| A |
| 抓墙 | 方向键朝墙（自动）| 方向键朝墙 |
| 拾取管段 | E | X |
| 放置管段 | E（在 socket 上）| X |
| 旋转管段 | 滚轮 / Q-E | RB |
| 重置节点 | 长按 R（0.8s）| 长按 Y |
| 暂停 / 退出 | ESC | Start |

### HUD 元素（详见 §1.UX，本章补充触发逻辑）

| 元素 | 触发显示 | 触发隐藏 |
|---|---|---|
| 计时条 | World 进入 Timed | World 退出 Timed |
| 节点完成度 | 玩家进入节点交互范围 | 离开范围 / 节点 Permanent |
| 重置提示 | 节点 Locked + 玩家在节点范围 | 节点不再 Locked |
| 拼接提示 | Carrying 状态 + socket 在视野内 | 离开 Carrying |

### 反馈通道（输入 → 反馈 ≤ 100ms 是 P1 红线）

| 输入 | 反馈 | 时延上限 |
|---|---|---|
| 跳跃按下 | 角色立即起跳 + 1 帧 squash | 1 帧（16.6ms @60fps）|
| 拾取按下 | 管段被吸到角色头顶 | 80ms |
| 放置按下 | socket 被填 + 朝向闭合检测 | 100ms |
| 旋转 | 管段 90° 旋转动画 | 50ms |
| 节点激活 | 0.5s 辉光扩散 + 计时条出现 | 200ms（含动画启动）|

### 边界 / 失败处理（UX 视角）

| 边界 | 处理 |
|---|---|
| 玩家摔出关卡边界 | 1.5s 后从最近节点起点复活 |
| 玩家在 Carrying 中摔落 | 管段回到原位置（非随机散落）|
| 玩家在 Placing 中按 ESC | 退到主菜单（M2 不做"暂停"），管段回原位 |
| 节点路径连不通但所有 socket 已填 | 不阻塞，但视觉红光闪烁 + 计时器不启动 |
| 蒸汽喷孔触发期间玩家被击退到关卡外 | 1.5s 后从最近节点起点复活，节点状态保持 |
| 玩家在 World.Locked 中尝试激活其他节点 | 当前节点未重置则**禁用**其他节点交互 |

---

## 交付与验收

### 性能 / 平台约束（Godot 4.6.2 预算）

| 指标 | 上限 | 来源 |
|---|---|---|
| 平均帧时间 | 16.6ms（60 FPS）| viewport 1280×720，目标 60 FPS |
| 输入到上屏延迟 | ≤ 50ms | P1 手感红线 |
| 单关内存峰值 | ≤ 256 MB | Godot 4 PC build 预算 |
| 单关磁盘大小 | ≤ 50 MB | M2 占位美术阶段宽松上限 |
| 同屏 sprite 数 | ≤ 80 | 含管段 + hazard + 玩家 + 背景元素 |
| 物理对象数 | ≤ 30 | 接地检测 + 管段碰撞盒 + hazard |

### 与其他系统接口

| 本章字段 | 被谁引用 |
|---|---|
| `player.json` 全部字段 | engineer 实现 player FSM；ux-designer 出动效规格 |
| `nodes.json` 全部字段 | engineer 实现 puzzle 系统；level-designer 配置具体关卡 |
| `hazards.json` 全部字段 | engineer 实现 hazard 系统 |
| Player FSM 状态名 | art-director 出 spritesheet 命名规范 |
| Node FSM 状态名 | ux-designer 出节点视觉状态切换规格 |
| 输入映射 | input-system 实现（M1 内联在 player controller）|

### 本章交付物清单

- ✅ 玩家移动机制 + 5 状态 FSM + 13 个数值字段
- ✅ 解谜机制 + 节点 FSM + 5 节点状态 + 3 节点配置
- ✅ 计时机制 + 世界 FSM + 4 世界状态 + 计时窗口字段
- ✅ Hazard 机制（蒸汽喷孔）+ 5 个数值字段
- ✅ 关卡示意（ASCII）+ 难度曲线表 + 教学节奏表
- ✅ 输入映射（键盘 + 手柄）
- ✅ 反馈通道时延上限
- ✅ 边界 / 失败处理 7 条
- ✅ 性能预算 6 条

### M1 验收标准（本章承诺）

- ✅ engineer 可基于本章 + `data/*.json` 落 player FSM，**不需要再问 designer**
- ✅ player 五状态在测试关卡中可触发并切换正确
- ✅ 1 个 dummy 节点（A 配置）能完成 pickup → place → rotate → activate → timer 全链路
- ✅ 1 个蒸汽喷孔可正常 warning → active → idle 循环
- ✅ 输入到上屏延迟实测 ≤ 50ms

### M2 验收标准（vertical slice）

- ✅ 节点 A/B/C 全部按 `data/nodes.json` 配置可解 + 可重置
- ✅ 攀爬段 B 蒸汽喷孔不会卡死玩家（边界处理 7 条全 PASS）
- ✅ 一次完整通关时间在 8-12 分钟（中位玩家测试，n ≥ 3）
- ✅ 计时段首次通过率 ≥ 50%（playtest 数据）
- ✅ 性能预算 6 条全部达标

### 风险登记

| 风险 | 影响 | 缓解 |
|---|---|---|
| 跳跃公式（initial_velocity / gravity）与 max_height_tiles 不自洽 | 调参成本 | M1 prototype 期 engineer 反推校准；本章字段以 4.5 tile 为最终锚点 |
| 节点 C 拼图过难（4×4 + 3 输入）→ 中位时长 > 90s | 违反 P2 + P1 边界 | M1 playtest 必须验证节点 C 中位时长，超标则削减为 3×4 |
| 蒸汽喷孔 + 计时段叠加 → 段 B 通过率 < 30% | 违反 P3 红线 | 段 B 蒸汽喷孔 ≤ 2 个 + 计时窗口预留 +20% 容差 |
| WallCling 0.6s 过短被玩家诟病 | UX 反馈差 | M1 playtest 评估，必要时升至 0.8s（不能更长，否则玩家用墙偷懒解谜，违反 P1）|

### 已知限制

- 本章未定义"玩家死亡"（实际 M2 范围内**没有死亡**，只有"摔落 → 复活"和"节点锁死 → 重置"）
- 本章不覆盖音效设计（音效与状态机的映射由 audio-director 在 M3+ 起草独立章节）
- 节点 C 的具体管段排布 / socket 位置交由 level-designer 在 M2 配置（本章只定义网格大小 + 必备管段类型）
- 本章未给出 UI 动效缓动曲线（由 ux-designer 在 ux-spec 出，本章只给时长上限）
