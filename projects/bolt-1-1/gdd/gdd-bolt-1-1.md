---
project: bolt-1-1
title: "Bolt: Sector 1-1 — 游戏设计文档"
version: 2.0-bolt
status: dev
last_updated: 2026-05-15
authors: [designer, art-director, ux-designer]
ip_disclosure: "Original work. No third-party IP, no resemblance to Nintendo Mario or other commercial titles."
---

# Bolt: Sector 1-1 · GDD

> 致敬 NES 时代横版平台跳跃手感（加减速 / 可变跳高 / 踩敌反馈）的工业风原创小品。
> 主角 Bolty，一个圆头红壳机械豆，在被废弃的 Sector 1-1 中前进，目标是激活信号塔召唤主基地。
> 所有视觉、角色、命名完全原创，与任天堂 Super Mario 系列或其他商业作品无关。

## 目录

1. [概述](#1-概述)
2. [玩法循环](#2-玩法循环)
3. [系统设计](#3-系统设计)
4. [数值与平衡](#4-数值与平衡)
5. [关卡内容与节奏](#5-关卡内容与节奏)
6. [UX 与 HUD](#6-ux-与-hud)
7. [视觉与美术](#7-视觉与美术)
8. [交付与验收](#8-交付与验收)

---

## 1. 概述

### 1.1 项目定位

| 项 | 值 |
|---|---|
| 类型 | 2D Side-Scrolling Platformer · 单关原创关卡 · 单人单局 |
| 引擎 | Godot 4.6.2 / GDScript |
| 平台 | Windows PC（主目标）/ Web HTML5（Phase 2） |
| 分辨率 | 1280×720 viewport，60 FPS |
| 时长 | 单局 1.5–4 分钟 |
| 受众 | 怀旧横版玩家 / 像素风爱好者 / 引擎学习者 |

### 1.2 一句话愿景

> "一个红色机械豆在工业废墟里跳过苔藓滚子，吃浆果变大，砸开 Cache Box，最后激活信号塔召唤基地。"

### 1.3 设计支柱（Pillars）

| Pillar | 含义 | 验证标准 |
|---|---|---|
| **手感是核心** | 加减速 / 可变跳高 / 踩敌反馈三件套必须紧实 | 玩家 30 秒内能感受"跳得有重量但听话" |
| **每 5 秒一个新元素** | 关卡 6 个 beat 对应 6 个机制递进 | 通关一次至少经历 6 个 distinct gameplay 时刻 |
| **视觉原创工业风** | 色板与世界观区别于鲜亮儿童风 | art bible 5 维度审 PASS |
| **数据驱动** | 所有数值在 `data/*.json` | 不修代码即可调手感 |
| **可独立运行** | `game/` 复制出来即可跑 | DoD 验证：拷贝 + 启动 < 5s |

### 1.4 IP 声明

本项目原始形态为 mario-1-1（Super Mario Bros 1-1 复刻），2026-05-15 因 IP 风险 pivot 为完全原创的 bolt-1-1：

- 主角换为机械豆 **Bolty**（圆头工业机器人，与马里奥的胡子大叔造型完全不同）
- 敌人 / 道具 / 关底元素全部原创命名 + 重新视觉设计
- 关卡 beat / 玩法机制 / 手感数值保留（这部分是技术学习的核心）
- 详细映射见 `docs/naming-map.md`，pivot 决策见 `retros/2026-05-15-quality-failure-postmortem.md`

---

## 2. 玩法循环

### 2.1 核心循环（每 1–3 秒）

```
观察 → 输入（→/Space/Shift）→ Bolty 反馈（动 / 跳 / 跑）→ 环境反馈（地形 / 敌人 / 道具）→ 计分变化 → 观察
```

读屏判定（前 50–200px）：
- 有坑 → 提前蓄跳
- 有 Mossroll → 跳起踩头
- 有 Cache Box → 跳起顶
- 有 Conduit 高度差 → 蓄力跳

### 2.2 中循环（每 5–15 秒）

每个 Beat 对应一段连续机制压力 + 一次释放：

```
压力升起（敌人 / 坑 / 高度）→ 输入精度要求提高 → 释放（顺利通过 / 拾取奖励 / 计分跳跃）→ 进入下一 beat 的过渡空地
```

### 2.3 大循环（整局 1.5–4 分钟）

```
title screen → 按 SPACE → ready 倒计时 1.5s → 6 个 beat 推进 → 触 Signal Tower → 5 段计分滑下 → 进入 Outpost → SECTOR CLEAR
                                                                                                                       ↓
                                                                                                                  按 SPACE 重玩
```

死亡分支：`pit / hit-while-small / time-out → 死亡动画 → 命数 -1 → 命数>0 重生 / 命数=0 SYSTEM FAILURE → 按 SPACE 回 title`

### 2.4 玩家承诺

| 承诺时刻 | 玩家心理 | 设计触发 |
|---|---|---|
| 0–3s | "我控制着这个小机器人" | 出生即可走，无开场剧情 |
| 3–8s | "他能跳，跳得有重量" | 第一只 Mossroll 在前方，必须跳过 |
| 8–15s | "踩头能赢！" | 第一只 Mossroll 安排在玩家"被迫跳起的落点" |
| 15–25s | "Cache Box 里有东西" | 第一个 Cache Box 给 Cog，第二个给 Power Berry |
| 25–40s | "我变大了！能砸砖块了！" | 吃 Power Berry 后立刻给一段砖块墙感受新能力 |
| 40–60s | "我被挑战了，我赢了！" | 双 Conduit 双 Mossroll 压力段 |
| 60s+ | "我能跳到塔顶！" | Signal Tower 顶端给最高分（5000） |

---

## 3. 系统设计

### 3.1 主角：Bolty

**Silhouette**：圆头 + 短身 + 短腿 + 双手扣式工装；红色金属壳 `#E03030` + 黄色相机镜头眼 `#FFC820`。无胡子、无帽 brim。

**三态**：

| 态 | 尺寸 | 视觉 | 能力 |
|---|---|---|---|
| `small` | 16×16 | 单节红壳豆体 | 跑 / 跳 / 踩；被任何伤害 → dead |
| `big` | 16×32 | 红壳豆 + chassis 身躯节延展 | 跑 / 跳 / 踩 / 蹲（`crouch`）/ 砸碎砖块；被伤 → small + 1.8s 无敌 |
| `fire` | 16×32 | 银白外壳 + 蓝色相机眼 | 同 big + 发射火球；被伤 → big |

**death**：短路冒火花 0.8s → 向后倒下 0.7s → 命数 -1。

### 3.2 输入

| Action | 键 1 | 键 2 |
|---|---|---|
| `move_left` | ← | A |
| `move_right` | → | D |
| `jump` | Space | Z |
| `run` | Shift | X |
| `pause` | Esc | — |

**Buffer**：跳跃落地前 6 帧内按下视为 buffered jump。

### 3.3 敌人

#### 3.3.1 Mossroll（圆球苔藓体）

- 初始向左巡逻；走路速度 30 px/s
- 撞墙 / 撞壁 / 撞 cliff（开启 `fallsOffCliff`）→ 反向
- **被踩头**（玩家 bottom-Y < 敌人 top-Y + 8px）→ 压扁 0.5s 后消失，玩家 +100 分，玩家弹跳 -200 v
- **侧面撞**：small → dead；big/fire → 退一态

#### 3.3.2 Shellpod（金属甲虫）

- 巡逻速度 30，**不会**掉崖
- **第一次被踩**：缩进甲壳，5s 内不动
- **第二次被踩 / 侧撞静止甲壳**：甲壳以 200 px/s 高速弹射，撞墙反弹，沿途接触敌人 → 连击计分 100/200/400/800/1000/2000/4000/8000/1UP
- **侧撞旋转壳**：玩家受伤一档

#### 3.3.3 Spiker（Phase 2 占位，本期不实现）

钢钉植物，从 Conduit 中升降。仅在 backlog 登记，不进 1-1 关卡。

### 3.4 道具

| 道具 | 视觉 | 效果 | 出现 |
|---|---|---|---|
| **Power Berry** | 红色发光浆果 + 金黄叶冠 | small → big；+1000 分 | Cache Box 内 / 砖块隐藏 |
| **Spark Bloom** | 白色四瓣电花 + 中心蓝白电弧 | 任意 → fire；可发射火球；+1000 分 | Cache Box 内（玩家已 big 时） |
| **Blue Crystal** | 蓝色棱晶 + 白色高光 | +1 命 | 隐藏砖块（`hidden_blueCrystal`）|
| **Cog** | 黄铜齿轮 ×4 帧旋转 | +200 分 + 计数；100 → +1 命 | Cache Box 内 / 关卡撒落 |
| **Pulse Core**（Phase 2 不实现） | 紫色脉动核心 | 10s 无敌 | — |

### 3.5 关卡元素

| 元素 | 视觉 | 行为 |
|---|---|---|
| **Brick**（橘红工业砖）| 16×16 砖块 | small 玩家顶 → 抖动 12 帧；big/fire 玩家顶 → 砸碎 4 块碎片 + 50 分 |
| **Cache Box**（金黄方箱 + "?" 闪烁）| 16×16 | 顶后产出（contains 字段）→ 变 used 暗棕色 |
| **Hard Block**（灰色金属）| 16×16 | 不可破坏，硬平台 |
| **Conduit**（暗绿金属管道）| 长度 short/medium/long/extraLong | 物理碰撞实体；可作为高度墙；少数 enterable 进 bonus 区 |
| **Signal Tower**（金属杆 + 信号红旗）| 杆高 144 | 玩家触杆 → 触发 5 段计分滑下：top 5000 / 70%+ 4000 / 40%+ 2000 / 10%+ 800 / 底 100 |
| **Outpost**（金属哨站 + 天线）| 80×80 | Signal Tower 之后玩家走入 → 通关动画 + SECTOR CLEAR |
| **MovingPlatform** | 96×16 | y 轴升降，速度 30，行程 96（**本期 noop 跳过，登记 BL-019**）|

### 3.6 摄像机

- Lookahead：跑步态向前偏移 32px
- Deadzone：80×60，玩家进入 deadzone 才推屏
- **No-scroll-back**：屏幕只向右滚，不允许回头屏（NES 经典）
- 边界：left=0, right=3200, top=0, bottom=720

### 3.7 关卡流程状态机

```
TitleScreen --SPACE--> Ready (1.5s) --> Playing
Playing --pit/hit-while-small--> Death (3s) --命数>0--> Respawn (0.5s) --> Playing
                                              --命数=0--> GameOver (3s) --SPACE--> TitleScreen
Playing --time<=0--> Death
Playing --SignalTower--> Clear (5s) --SPACE--> TitleScreen
Playing --ESC--> Pause --ESC--> Playing
```

---

## 4. 数值与平衡

### 4.1 物理（`physics.json`）

| 项 | 值 | 说明 |
|---|---|---|
| `gravity.default` | 800 px/s² | 地面态默认重力 |
| `maxFallSpeed` | 600 px/s | 终端速度 |
| `friction.ground` | 0.15 | 摩擦系数 |
| `airResistance` | 0.0 | 无空气阻力（NES 风） |

### 4.2 玩家（`player.json`）

| 项 | 值 |
|---|---|
| `walk.maxSpeed` / `accel` | 90 / 200 |
| `run.maxSpeed` / `accel` | 150 / 300 |
| `turnAround.decel` | 400 |
| `jump.initialV` | -340 |
| `jump.holdGravity` | 600（按住跳跃键时较弱重力，增加跳高）|
| `jump.releaseGravity` | 1500（松开后强重力，缩短滞空）|
| `jump.minHoldFrames` | 4 |
| `jump.maxHoldFrames` | 18 |
| `air.accelMultiplier` | 0.6 |
| `damage.iframesAfterHit` | 180 帧（3s）|

**手感校验**：
- 单击跳：高度约 60 px（小态）
- 长按跳：高度约 100 px（小态），约 130 px（big）
- 跑步跳：水平距离约 180 px

### 4.3 敌人（`enemies.json`）

| 项 | 值 |
|---|---|
| `mossroll.walkSpeed` | 30 |
| `mossroll.score` | 100 |
| `mossroll.fallsOffCliff` | true |
| `shellpod.walkSpeed` | 30 |
| `shellpod.shellSpeed` | 200 |
| `shellpod.shellWaitFrames` | 300（5s）|
| `shellpod.fallsOffCliff` | false |
| `shellChainScores` | [100,200,400,800,1000,2000,4000,8000,1UP] |

### 4.4 道具（`items.json`）

| 项 | 值 |
|---|---|
| `powerBerry.walkSpeed` | 60 |
| `powerBerry.score` | 1000 |
| `sparkBloom.score` | 1000 |
| `blueCrystal.scoreText` | "1UP" |

### 4.5 计分（`scoring.json`）

| 来源 | 分 |
|---|---|
| Cog | 200 |
| Mossroll | 100 |
| Shellpod | 100 |
| Brick 砸碎 | 50 |
| Power Berry / Spark Bloom | 1000 |
| Signal Tower 顶 | 5000 |
| Time bonus | 50 / 剩余秒 |

100 个 Cog → +1 命；shell-chain → 最高 1UP。

### 4.6 平衡设计原则

- **不允许 small 状态硬刚 Shellpod**：必须先吃 Power Berry 或绕过
- **第一次 Power Berry 必给在 B2 段尾**：玩家在 B3 段前已变大
- **每个 beat 至少有一个"分支"**：踩敌 vs 跳过、Cache Box 顶 vs 跳过
- **TIME 300s 是宽裕的**：纯走完关卡约 110s，留 190s 给探索 / 重试

---

## 5. 关卡内容与节奏

### 5.1 关卡参数（`data/levels/1-1.json`）

| 项 | 值 |
|---|---|
| `width` | 3200 px |
| `height` | 720 px |
| `spawn` | (64, 528) |
| `death_y` | 740（Bolty y > 740 → 死亡）|
| `time_limit` | 300s |
| `first_enemy_x` | 192 |

### 5.2 Beat Map（6 个 beat）

| Beat | x 范围 | 名称 | 教学目标 | 主要内容 |
|---|---|---|---|---|
| B1 | 0–200 | 教学开场 | 熟悉控制 | 出生 → 平地 → 第一个 Cache Box（含 Cog） |
| B2 | 200–700 | 第一 Mossroll + 第一组 Conduit | 教踩敌 + 跳 | Cache Box 三连（含 Power Berry）+ 隐藏 Cache Box 在上层 + 4 个 Conduit 高度递增 |
| B3 | 700–1500 | Cache Box 山 | 教连续跳 + 探索 | 多个 Cache Box + Brick 群 + 隐藏 Blue Crystal（hidden brick） + Spark Bloom Cache Box |
| B4 | 1500–2300 | 大坑 + Shellpod | 教远跳 + 甲壳 | 第一只 Shellpod + 大坑（64px）+ Mossroll 群 |
| B5 | 2300–2900 | 升降台（本期 noop）| 教动态平台 | MovingPlatform ×2（M5.5 backlog BL-019 推迟）|
| B6 | 2900–3200 | Signal Tower 收尾 | 高潮收束 | Signal Tower（杆高 144）→ Outpost |

### 5.3 实体清单（`entities[]`）

完整 24 个实体配置见 `data/levels/1-1.json`。摘要：

- **5 个 Mossroll**：x ∈ {384, 832, 880, 1296, 1344}
- **1 个 Shellpod**：x = 1664
- **8 个 Cache Box**：含 6 cog + 1 powerBerry + 1 sparkBloom
- **3 个 Brick**（其中 1 个 hidden_blueCrystal）
- **4 个 Conduit**：长度 short/medium/long/long
- **2 个 MovingPlatform**（noop）
- **1 个 Signal Tower** + 1 个 **Outpost**

### 5.4 地面与坑（`tilemap`）

| 段 | x 范围 | 类型 |
|---|---|---|
| 段 1 | 0–640 | ground（出生平地） |
| 坑 1 | 640–704 | small_pit_1（64px） |
| 段 2 | 704–1184 | ground |
| 坑 2 | 1184–1248 | small_pit_2（64px） |
| 段 3 | 1248–2208 | ground（中段长平地） |
| 坑 3 | 2208–2240 | big_pit（32px，但需要跑步跳） |
| 段 4 | 2240–3200 | ground（终末段含 Signal Tower） |

---

## 6. UX 与 HUD

### 6.1 HUD 布局（顶部一行）

```
BOLTY     COG×NN     SECTOR     TIME
000000     ×NN        1-1        300
```

| 字段 | 说明 |
|---|---|
| `BOLTY 000000` | 6 位得分，左 padding 0 |
| `COG ×NN` | 当前 Cog 数；90+ 高亮黄；100 短闪庆祝（变 1UP）|
| `SECTOR 1-1` | 静态文本 |
| `TIME NNN` | 倒计时；≤100 警告红色闪烁（0.5s 周期）|

颜色：normal `#FFFFFF` / warning `#D04030` / celebrate `#FFC820`

### 6.2 Title Screen

- 背景：工业暗蓝渐变 `#0A0E1C → #1C2440`
- 远山 `#283050`
- 标题：**BOLT**（大字）
- 副标题：`Sector 1-1`
- CTA：`Press SPACE to Activate`（1s 周期闪烁）
- 控制说明：MOVE / JUMP / RUN / PAUSE 四行

### 6.3 Pause Overlay

- 黑色 60% 不透明遮罩
- 中心 `PAUSE` 字
- `Press ESC to Resume` 提示

### 6.4 Clear / GameOver Overlay

- **SECTOR CLEAR**：金黄主色 + 时间 bonus 计算 + `Press SPACE to restart`
- **SYSTEM FAILURE**：信号红主色 + `Press SPACE to retry`

### 6.5 反馈密度

- 输入响应：所有输入 ≤ 1 帧延迟（physics tick = 16ms）
- 视觉反馈：踩敌 / 顶箱 / 拾取必有 sprite 切换或位移
- 听觉反馈（Phase 2 TODO）：跳 / 踩 / 拾取 / 顶箱 / 死亡 5 类基础音

---

## 7. 视觉与美术

### 7.1 Art Bible 摘要

详细 art bible 在 `art/style-guide.md`（M5.5 重写中）。本节只列原则。

**风格关键词**：NES 8-bit 像素 + 现代清晰度（pixel-perfect / 整数缩放）+ 工业感（橘红 / 金黄 / 蓝灰）

**与马里奥的区别**：
- 色调：工业暗蓝天空（vs 鲜亮蓝）+ 干苔黄草（vs 鲜绿）+ 橘红主角（vs 红蓝）
- 角色：圆头机械（vs 胡子大叔）
- 世界观：废弃 Sector 工业风（vs 蘑菇王国童趣）

### 7.2 色板（`palette.json`）

| 类别 | 色 |
|---|---|
| 天空 | `#445C78` 工业灰蓝 |
| 远山 | `#6C7888` |
| 地面顶 | `#9C8830` 干苔藓黄 |
| 地面体 | `#783820` 锈红土 |
| Brick | `#D87050` |
| Cache Box（active）| `#FAC000` |
| Hard Block | `#BCBCBC` |
| Conduit | `#384830` + `#6C9050` 高光 |
| Signal Tower | `#A0A0A8` 金属 + `#D04030` 信号红 |
| Outpost | `#787878` |
| **Bolty** | `#E03030` 红 + `#FFC820` 眼 + `#3CC0FF` 火力蓝 |
| **Mossroll** | `#5C8030` 苔绿 |
| **Shellpod** | `#8B9090` 金属 + `#3C9050` 铜绿甲 |
| **Power Berry** | `#C42040` 浆果红 + `#FFC820` 叶 |
| **Spark Bloom** | `#FFFFFF` + `#3CC0FF` |
| **Blue Crystal** | `#3878F0` |
| **Cog** | `#E8A018` 黄铜 |

### 7.3 资产清单（M5.5 生成中）

详见 backlog BL-012 ~ BL-017。本期需生成：

- Bolty 三态精灵 atlas（idle/walk/run/jump/fall/crouch/throw/death）
- Mossroll / Shellpod 精灵
- 4 个道具精灵（Power Berry / Spark Bloom / Blue Crystal / Cog）
- Tile 集（ground / brick / cacheBox / hard / conduit）
- 关底元素（Signal Tower / Outpost）
- 背景（cloud / mountain / bush）
- 8x8 像素 bitmap 字体 + Cog HUD 图标

存到 `projects/bolt-1-1/assets/`。来源：`art-asset-pipeline` skill / timiai-image。

### 7.4 视觉资产红线

按 `studio/docs/autonomous-mode-charter.md` 底线 1：

- production 视觉**必须**使用真实资产
- ColorRect / 纯色 Polygon2D 仅允许测试 / 调试视图 / `_PLACEHOLDER_` 命名的临时占位
- 占位必须登记 `[VISUAL_DEBT]` backlog story，注明 due milestone
- 违反 → milestone 不通过

---

## 8. 交付与验收

### 8.1 Definition of Done（M5.5）

| ID | 项 | 验证方式 |
|---|---|---|
| DoD-01 | 双击 `run-game.bat` 5s 内可控 | 人工 |
| DoD-02 | 不死亡 < 200s 通关 | `tests/real_playtest.gd`（无 cheat）|
| DoD-03 | 3 种死亡触发：pit / hit-while-small / time-out | tests/death_triggers.gd |
| DoD-04 | 死亡 → 重生 < 1.5s | tests |
| DoD-05 | 3 种状态转换：small→big→fire；hit 反向 | tests/state_machine.gd |
| DoD-06 | 关卡 6 个 Beat 出现（与 5.2 节对齐）| 人工玩遍 |
| DoD-07 | HUD 实时正确（分数 / Cog / SECTOR / TIME）| 人工 |
| DoD-08 | 隐藏内容触发：hidden_blueCrystal brick | 人工 |
| DoD-11 | 暂停可用（ESC）| 人工 |
| DoD-12 | 5 分钟无 crash（自主模式简化）| 人工 |
| DoD-13 | 数值表与代码解耦（改 json 立即生效）| 修 player.json walkSpeed 验证 |
| **DoD-14** | **真实玩家路径测试 PASS（不依赖 cheat）** | `tests/real_playtest.gd` |
| **DoD-15** | **所有 production sprite 使用真实资产（非 ColorRect）** | art-director 截图评审 |
| **DoD-16** | **backlog P0 状态 = open 的条目 ≤ 0** | grep backlog.md |

### 8.2 Out of Scope

| 项 | 原因 |
|---|---|
| Sector 1-2 / 1-3 等其他关卡 | 单关教学复刻 |
| 多人 / 世界地图 / 存档 | 范围控制 |
| 水下 / 城堡内部 | 1-1 不需要 |
| 配置选项菜单 | 占位即可 |
| 多语言 | 英文 HUD 占位 |
| 移动端 | Phase 2 |
| 自定义键位 | Phase 2 |
| 自制 BGM / SFX | Phase 2（无版权资源 + 时间预算）|
| Pulse Core / Spiker / MovingPlatform | 推迟到 post-M6 |

### 8.3 里程碑映射

| Milestone | 状态 | 内容 |
|---|---|---|
| M1 | done | GDD 大框架 |
| M2 | done | GDD 细节填充（v1.2-ux-refined） |
| M3 | partial | epic / story 拆分 + 数据表 |
| M4 | done | 核心玩法可玩 |
| M5 | cheat-only PASS | 完整 Sector 1-1 可通关（real PASS pending）|
| **M5.5** | **in progress** | IP pivot + 原创资产 + 14 backlog 修复 |
| M6 | 待启动 | 视觉打磨 + 完整过场 |

### 8.4 质量门（按工作室宪章）

milestone 推进必须经过 `qa-gate` skill：

| 指标 | M5.5 阈值 |
|---|---|
| 测试通过率 | ≥ 90% |
| 引擎校验 | EXIT 0 |
| consistency-check | CLEAN |
| P0 bug 数 | = 0 |
| GDD §8 P0 验收 | 100% |
| 视觉债（VISUAL_DEBT）| ≤ 2 |
| 真实玩家路径测试 | **必须 ≥ 1 PASS** |

任一未达 → milestone gate 不通过。详见 `studio/docs/autonomous-mode-charter.md` 底线 + `qa-gate` SKILL.md。

---

## 关联文档

- 命名映射：[`docs/naming-map.md`](../docs/naming-map.md)
- 关卡数据：[`data/levels/1-1.json`](../data/levels/1-1.json)
- 数值表：[`data/`](../data/)
- 美术参考：[`art/`](../art/)
- Backlog：[`stories/backlog.md`](../stories/backlog.md)
- 项目身份：[`PROJECT.md`](../PROJECT.md)
- 工作室宪章：[`studio/docs/autonomous-mode-charter.md`](../../../studio/docs/autonomous-mode-charter.md)

## 历史档案

pivot 之前的 GDD 版本（mario-1-1 命名）已删除。审计痕迹见 `retros/2026-05-15-quality-failure-postmortem.md` + `reports/archive/`。
