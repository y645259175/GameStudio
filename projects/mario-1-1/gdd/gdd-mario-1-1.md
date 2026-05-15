---
gdd_id: mario-1-1
status: review
sections_complete: [1, 2, 3, 4, 5, 6, 7, 8]
owner: designer
version: 1.0-detail-complete
last_review: 2026-05-15
---

# GDD · Mario 1-1 复刻

> 渐进式策划。当前 0.5-detail：§1/§2/§4/§6/§8 由 designer 完成，§3/§5/§7 由 art-director 和 ux-designer 后续填。

---

## 1. 概述

### 1.1 项目定位

**Mario 1-1 教学性复刻**：以《Super Mario Bros.》(1985, NES) 的 World 1-1 为唯一关卡范围，复刻其核心操作手感、关卡节奏与教学设计。

- **类型**：2D 横版平台跳跃
- **范围**：单关卡（World 1-1），单人
- **目的**：团队内训 / 工程内训，验证工作室对复杂度更高项目的处理能力
- **目标平台**：PC / Windows 1280×720 60FPS
- **预期工期**：3-4 个 sprint

### 1.2 设计支柱

#### Pillar 1: 手感至上（Feel First）
- 跳跃曲线可调，输入到位移 ≤ 1 帧
- 移动有惯性、滑步、转身减速
- 反例：不接受为动画好看锁定输入帧

#### Pillar 2: 关卡即教学（Level as Teacher）
- 没有任何文字教程
- 学习路径完全嵌入关卡布局
- 反例：不接受 "Press A to Jump" 提示

#### Pillar 3: 复刻精度优先于现代化（Fidelity over Modernization）
- 数值以原作为基线，偏离必须标 `[DEVIATION]`
- 不加现代化功能（双段跳/dash/墙跳/空中转向加成）

### 1.3 核心体验（60 秒情绪曲线）

| 时间 | 玩家行为 | 情绪 | 教学意图 |
|---|---|---|---|
| 0-5s | 出生站立、试探左右 | 好奇 | 学走 |
| 5-10s | 第一次跳、第一次顶砖 | 惊喜 | 学跳+顶砖有奖励 |
| 10-20s | 第一只 Goomba | 紧张→成就 | 学踩敌 |
| 20-35s | 蘑菇变大、砖块山 | 强力感 | 学道具+连续跳 |
| 35-50s | 大坑+Koopa | 高度紧张 | 学风险跳+踩龟壳 |
| 50-60s | 升降台+旗杆 | 紧张→释放 | 关底高潮 |

### 1.4 范围声明

**做**：1-1 完整复刻 / 5 状态马里奥 / 3 敌人（Goomba/Koopa/Piranha）/ 4 道具（蘑菇/火花/星星/1UP）/ 关卡元素全套 / HUD / 死亡重生 / 通关结算

**不做**：其他关卡 / 多人 / 存档 / 移动端 / 音乐自制 / 水下关卡 / Boss / 自定义键位

### 1.5 参考与对标

| 维度 | 参考 |
|---|---|
| 手感基线 | NES Super Mario Bros. (1985) World 1-1 |
| 工程范式 | Celeste (2018) 状态机 + data-driven |
| 教学设计 | Egoraptor 关卡即教学论 |
| 节奏方法 | Mark Brown Game Maker's Toolkit |
| 数值考据 | TASVideos / SMB Disassembly 社区文档 |

---

## 2. 玩法循环

### 2.1 Core Loop（秒级）

```
       ┌──────────────────────────────────┐
       ▼                                  │
  [观察前方] ─→ [决策走/跑/跳/顶/踩]      │
       │                                  │
       ▼                                  │
  [输入] ─→ [角色响应+物理]               │
       │                                  │
       ├→ 成功（金币/敌死/前进）→ [快感]  │
       └→ 失败（受击/掉坑）→ [惩罚→重生]──┘
```

循环时长 < 1.5 秒。反馈三通道：视觉 + 音效 + 镜头。

### 2.2 Mid Loop（关卡级）

| 阶段 | 时长参考 | 核心活动 | 教学含义 |
|---|---|---|---|
| 出生 | 0-2s | 落地，镜头静止 | 熟悉视野 |
| 教学段 | 2-10s | 第一 Goomba + 第一组问号块 | 同时教威胁与奖励 |
| 第一敌人 | 10-15s | 处理 Goomba | 学踩头消灭 |
| 蘑菇变大 | 15-25s | 拿第一颗超级蘑菇 | 学道具升级 |
| 砖块山 | 25-45s | 多层砖+多问号 | 学跳跃高度+探索 |
| 大坑挑战 | 45-60s | 第一个空坑 | 学远跳+失败惩罚 |
| 升降台 | 60-90s | 移动平台段 | 学动态平台落点 |
| 旗杆通关 | 90-100s | 抓杆+城堡 | 终结反馈+分数奖励 |

### 2.3 失败重试循环

死亡判定（任一）：
- 掉坑（Y < `data/levels/1-1.json → death_y`）
- 小马里奥与敌人碰撞箱接触（非踩头）
- 计时器归零

重生流程：死亡动画 → 剩余生命 -1 → 关卡从出生点重启 / 0 命 → Game Over。

重试节奏目标：从死亡触发到玩家可再输入 ≤ 5 秒。

### 2.4 奖励循环

| 奖励 | 触发 | 反馈 | 情绪 |
|---|---|---|---|
| 金币 | 接触/顶问号 | 短促音+计数跳 | 微小满足（高频） |
| 击杀 +100 | 踩头 | 踩扁音+飘字 | 操作确认（中频） |
| 蘑菇 | 接触 | 变大动画+升级音 | 能力提升 |
| 火花 | 大马里奥接触 | 换色+升级音 | 能力进阶 |
| 星星 | 接触 | 变色循环+专属 BGM | 短期狂欢 |
| 1UP | 隐藏触发 | 1UP 音+生命+1 | 稀有发现 |
| 旗杆顶分 | 跳到旗杆顶 | 烟花+高分+城堡音乐 | 终结成就 |

奖励间隔 ≤ 8 秒。具体数值见 `data/scoring.json`。

### 2.5 学习曲线（前 10 秒教学节拍）

```
[出生点]                                                          
  M ───→  [Goomba 走来]   [? 块×3 悬空]                       
═══════════════════════════════════════════════════════════════
   ①出生即看右       ②威胁主动靠近     ③视觉锚点诱导抬头    
```

**1. 出生位置 + 镜头**
- 出生点屏幕左 1/4，留右 3/4 视野
- 第一眼即看到 Goomba 与问号块
- 镜头不滚动直到玩家右移

**2. 第一 Goomba**
- 距出生约 8 tile（`data/levels/1-1.json → first_enemy_x`）
- Goomba 主动向左走 → 玩家必然接触
- 接触前有 3-4 秒观察时间

**3. 第一组问号块**
- 三个悬挂 Goomba 上方略偏右
- 高度恰好普通跳可达
- 中间是蘑菇块，蘑菇向右滚撞墙反弹回马里奥 → "被动"吃到

**4. 视觉优先原则**

| 教学内容 | 视觉信号 | 玩家行为 |
|---|---|---|
| 敌人威胁 | Goomba 朝自己走 | 跳起或反应 |
| 问号块奖励 | 闪烁动画 | 顶撞 |
| 蘑菇是好东西 | 主动滚向玩家 | 被动验证 |

不允许任何文字 / UI 提示介入教学。

---

## 3. 视觉与美术

### 3.1 整体艺术风格

**关键词**：NES 像素风 · 16x16 tile · 高饱和度 · 简洁几何 · 现代清晰度

**约束**：
- 不直接复制原作 sprite（避免 IP 风险）；自制风格要素接近原作但不抄
- tile 基础尺寸 16×16（角色 / 敌人 / 物件）；大马里奥 16×32
- 背景与前景必须有明显色差区分（玩家可玩区始终最显眼）
- 不使用任何抗锯齿（pixel-perfect render）
- 调色板限制在 32 色以内（NES 风格约束）

### 3.2 色板（Palette）

字段：`data/palette.json`

| 类别 | 字段 | 基准 hex | 说明 |
|---|---|---|---|
| 天空 | `sky.day` | `#5C94FC` | 蓝天 |
| 山远景 | `mountain.far` | `#FFC0FC` | 粉色（原作风）|
| 树丛 | `bush.green` | `#00A800` | 草绿 |
| 云 | `cloud.white` | `#FFFFFF` | 纯白 |
| 地面 | `ground.brown` | `#E45C10` | 棕橙 |
| 砖块 | `brick.brown` | `#FC8800` | 亮橙 |
| 问号块 active | `question.gold` | `#FCBC3C` | 金黄 |
| 问号块 used | `question.brown` | `#A04500` | 暗棕 |
| 硬砖 | `hardblock.gray` | `#A4A4A4` | 灰 |
| 管道 | `pipe.green` | `#00A800` | 翠绿 |
| 旗杆 | `flag.silver` | `#BCBCBC` | 银 |
| 城堡 | `castle.gray` | `#787878` | 深灰 |
| Mario 红 | `mario.red` | `#FC0000` | 帽子+衣服 |
| Mario 蓝 | `mario.blue` | `#0058FC` | 工装裤 |
| Mario 肤色 | `mario.skin` | `#FCBC8C` | 脸 |
| Goomba 棕 | `goomba.brown` | `#8B4513` | 蘑菇身 |
| Koopa 绿 | `koopa.green` | `#00C800` | 龟壳 |
| Koopa 黄 | `koopa.yellow` | `#FCFC00` | 腹部 |
| 金币黄 | `coin.gold` | `#FCBC3C` | 金币 |
| HUD 白 | `hud.white` | `#FFFFFF` | 文字 |
| 警告红 | `hud.warning` | `#FC0000` | TIME 警告闪烁 |

### 3.3 角色精灵

字段：`data/sprites/mario.json`

**马里奥三态**（每态独立 sprite sheet）：

| 态 | 尺寸 | 动画状态 | 帧数 |
|---|---|---|---|
| Small | 16×16 | idle / walk / run / jump / fall / skid / dead | 1+3+3+1+1+1+1 = 11 |
| Big | 16×32 | idle / walk / run / jump / fall / skid / duck / transform | 1+3+3+1+1+1+1+3 = 14 |
| Fire | 16×32 | 同 Big + shoot | 同 Big + 2 = 16 |

总精灵数：~41 个 sprite cell。

### 3.4 敌人精灵

字段：`data/sprites/enemies.json`

| 敌人 | 尺寸 | 动画 | 帧数 |
|---|---|---|---|
| Goomba | 16×16 | walk(2) / flat(1) | 3 |
| Koopa Green | 16×24 | walk(2) / shell(1) / shell-spin(4) | 7 |
| Piranha Plant | 16×24 | bite(2) / hide(1) | 3 |

### 3.5 关卡 Tileset

字段：`data/sprites/tiles.json`

| 类型 | 尺寸 | 变体 | 说明 |
|---|---|---|---|
| 地面 | 16×16 | 1 | 草+泥 |
| 普通砖 | 16×16 | 1 | 可破坏 |
| 砖块碎片 | 8×8 | 1 | 4 个碎片粒子 |
| 问号块 | 16×16 | 4 (active 3 帧动画 + used 1) | 闪烁 |
| 硬砖 | 16×16 | 1 | 不可破坏 |
| 管道 | 16×16 tile | 4 长度（短/中/长/超长）+ 顶部口/身体两 tile | 拼接 |
| 金币（场景内）| 16×16 | 4（旋转）| 关卡内金币 |
| 旗杆 | 16×16 tile × 12 高 | 杆+顶球 | 终点 |
| 城堡 | 80×80 (5×5 tile) | 1 | 通关 |
| 云 | 32×16 (2×1 tile) | 3 形状 | 背景 |
| 山 | 48×32 (3×2 tile) | 2 形状 | 背景 |
| 树丛 | 32×16 (2×1 tile) | 2 形状 | 装饰 |

### 3.6 动画规格表（VFX）

> 由 designer 代为起草（ux-designer subagent 暂未注册）。每条 VFX 描述触发与方向，具体像素值由 art-director 在实施时确定。

| # | 名称 | 触发 | 表现描述 | 反馈通道 | 优先级 |
|---|---|---|---|---|---|
| VFX-01 | Idle 呼吸 | 玩家静止 | sprite 微小垂直 1px 起伏循环 | 视觉 | P1 |
| VFX-02 | Walk 循环 | 走路速度 > 0 | 3 帧步进循环，频率与速度成正比 | 视觉 | P0 |
| VFX-03 | Run 循环 | 跑步速度 > 0 | 3 帧步进循环（更快频率）+ 角色稍前倾 | 视觉 | P0 |
| VFX-04 | Skid 转身 | 当前速度反向于按键 | 单帧滑步姿态 + 短促 skid 音 + 摩擦尘土粒子 | 视觉+音效 | P0 |
| VFX-05 | Jump 起跳 | 触发跳跃瞬间 | 起跳精灵帧 + jump 音效 + 微小尘土爆发 | 视觉+音效 | P0 |
| VFX-06 | Fall 下落 | 垂直速度 > 0 且未着地 | 下落精灵帧持续 | 视觉 | P0 |
| VFX-07 | Land 落地 | 着地瞬间 | 单帧落地姿态（0.1s）+ 尘土 + 轻微 thud 音 | 视觉+音效 | P0 |
| VFX-08 | Duck 蹲下 | Big/Fire 按下蹲键 | 角色压扁姿态切换（瞬时）| 视觉 | P1 |
| VFX-09 | 变大 transform | 吃蘑菇 | 全局冻结约 0.5s + Mario 在 small/big 帧间快速闪烁 6 次 + 升级音 | 视觉+音效+冻结 | P0 |
| VFX-10 | 变火力 | 吃火花 | 类似 VFX-09 但闪烁色为白/红交替 + 升级音 | 视觉+音效+冻结 | P0 |
| VFX-11 | 受伤缩小 | 大马里奥/火力受击 | 全局冻结 0.3s + 闪烁缩小 + iframes 3s 期间 sprite 半透明闪烁 | 视觉+音效 | P0 |
| VFX-12 | 死亡 | 小马里奥死/掉坑/超时 | 角色向上跳一下（initialV ≈ -300）后纯下落出屏 + 死亡音 + 镜头停止跟随 | 视觉+音效+镜头 | P0 |
| VFX-13 | 无敌闪烁 | 星星生效中 | sprite 颜色循环（红/橙/黄/白 4 色 0.1s/帧），结束前 2s 闪烁加速作预警 | 视觉+音效 BGM 切换 | P1 |
| VFX-14 | 踩 Goomba | 玩家从上方踩到 | Goomba 立即变扁形态停留 0.5s 后消失 + 踩扁音 + 飘字 +100 | 视觉+音效 | P0 |
| VFX-15 | 踩 Koopa | 玩家从上方踩到 | Koopa 缩壳静止 + 缩壳音；连续踩 → 壳被踢飞（横向极速） | 视觉+音效 | P0 |
| VFX-16 | 火球击爆 | 火球击中敌人 | 敌人翻身 + 闪光爆 + 爆破音 + 飘分 | 视觉+音效 | P1 |
| VFX-17 | 壳连锁飞行 | 壳撞其他敌人 | 每只敌人翻身 + 累计加分（200/400/.../1UP）+ 短促叠加音 | 视觉+音效 | P1 |
| VFX-18 | 顶砖块（小马）| 小马里奥从下顶撞砖块 | 砖块短暂上抖 0.2s 回位 + 闷声音；不破坏 | 视觉+音效 | P0 |
| VFX-19 | 砖块爆碎（大马）| 大/火力顶砖 | 4 块砖块碎片向四周抛物线飞散 + 爆碎音 | 视觉+音效 | P0 |
| VFX-20 | 问号块顶 | 任意状态顶问号 | 问号闪烁 → 变 used 棕色 + 道具/金币从顶部弹出 + 升起音 | 视觉+音效 | P0 |
| VFX-21 | 收集金币 | 接触金币 | 金币原地向上飘 0.3s 旋转 + 飘字 +200 + 金币音；HUD coin +1 | 视觉+音效 | P0 |
| VFX-22 | 进管道 | 玩家在可进管道顶按下 | 角色缩入管道（向下平移 + 缩小）0.8s + 管道进入音 + 黑屏切换 | 视觉+音效+过场 | P1 |
| VFX-23 | 屏幕微抖（敌死）| 任意敌人死亡 | 摄像机随机 ±2px 抖动 0.2s | 视觉 | P2 |
| VFX-24 | 火球击中震动 | 火球击中敌人 | 摄像机 ±3px 抖动 0.25s | 视觉 | P2 |
| VFX-25 | 时间警告 HUD 闪 | TIME ≤ 100 | TIME 数字 + 标签红白闪烁 0.5s 周期 + BGM 加速 | 视觉+音效 | P0 |
| VFX-26 | 100 coin 高亮 | coin 从 99→100 那帧 | coin 图标强闪一次 + HUD 短暂金光 + 1UP 音 | 视觉+音效 | P0 |
| VFX-27 | 开场展开 | Loading→Ready | 屏幕从全黑淡入 0.5s + Ready 1.5s + BGM 启动 | 视觉+音效 | P0 |
| VFX-28 | 死亡黑屏 | 死亡动画结束 | 全屏淡入纯黑 0.5s → 显示剩余生命 1.5s → 重生/Game Over | 视觉 | P0 |
| VFX-29 | 旗杆下滑 | 玩家碰旗杆 | 角色抓杆 → 沿杆下滑（线性，约 1.0s）→ 落地挥旗 0.5s + 旗下降音 + 计分加成 | 视觉+音效 | P0 |
| VFX-30 | 城堡进入 | 旗杆挥旗结束 | 角色自动右走入城堡门（1.5s）+ 城堡旗升起 + 通关音乐 + WORLD CLEAR 字幕淡入 | 视觉+音效+过场 | P0 |

### 3.7 UI 视觉

字段：`data/hud.json`

- **字体**：NES 风像素等宽字体（8×8 字符），大字号 16×16
- **数字样式**：等宽数字，前导 0 补齐（score 6 位 / coin 2 位 / time 3 位）
- **颜色**：默认白色 `#FFFFFF` / 警告红 `#FC0000` / 庆祝金 `#FCBC3C`
- **边距**：HUD 顶部留 16px padding，左右各 16px
- **对齐**：MARIO/Score 左对齐 / coin 居左中 / WORLD 居右中 / TIME 右对齐

### 3.8 过场与转场

- **开场**：Title → Press SPACE → 淡黑 0.5s → Loading → Ready 1.5s → Playing
- **死亡**：死亡动画 3s → 黑屏淡入 0.5s → 剩余生命展示 1.5s → 重生/Game Over
- **通关**：旗杆下滑 1.0s → 挥旗 0.5s → 自动走入城堡 1.5s → 城堡旗升起 1.5s → WORLD CLEAR 字幕 + timeBonus 结算 3s → 标题
- **暂停**：黑色遮罩淡入 0.2s → 显示 PAUSE → ESC 触发淡出 0.2s

---

## 4. 系统设计

每个子系统遵循统一结构：职责 / 数值表锚 / 玩家感知 / 核心规则 / 接口 / 边界。

### S1 · 角色控制（Player Control）

**职责**：将玩家输入翻译成马里奥的速度、朝向、姿态。

**数值表锚**：`data/player.json` →
- `walk.maxSpeed` / `walk.accel`
- `run.maxSpeed` / `run.accel`
- `turnAround.decel`
- `jump.initialV` / `jump.holdGravity` / `jump.releaseGravity` / `jump.minHoldFrames` / `jump.maxHoldFrames`
- `air.accelMultiplier`
- `crouch.enabled`

**玩家感知**：
- 看到：水平位移 / 朝向反转 / 起跳/落地姿态切换
- 触发：按下方向 / 跳跃 / 跑 / 蹲键瞬间
- 生效中：按住方向持续加速；按住跳吃低重力；按住跑提升 max
- 结束：松开方向→摩擦减速；松开跳→切高重力（短跳）

**核心规则**：
- 加速分两档：walk / run，由是否按住跑键决定
- **可变高度跳跃**：起跳后 N 帧内按住跳应用 holdGravity，松开切 releaseGravity
- **转身减速**：当前速度方向与按键反向时应用 turnAround.decel（大于普通 accel）
- **空中控制**：空中 accel × air.accelMultiplier
- **下蹲**：仅大/火力可蹲，蹲下禁奔跑、降低碰撞盒
- 输入采样每帧一次，无输入缓冲（复刻基准）

**接口**：依赖 S2 物理 / S3 状态机；影响 S2 / S7 摄像机 / S6 关卡元素

**边界**：
- 不做 jump buffer / coyote time
- 不做二段跳 / 蹬墙跳

---

### S2 · 物理（Physics）

**职责**：基于速度、重力、碰撞分类裁决位移结果。

**数值表锚**：`data/physics.json` →
- `gravity.default` / `gravity.airResistance`
- `friction.ground`
- `maxFallSpeed`
- `collisionLayers` / `collisionMatrix`
- `hitboxes.player.small` / `player.big` / `player.crouch`

**玩家感知**：
- 看到：物体下落 / 撞墙停下 / 踩地 / 掉坑消失
- 触发：运动体进入新格 / 与碰撞体重叠瞬间
- 生效中：每帧 v += g·dt; pos += v·dt; resolve
- 结束：碰撞解算后速度按法线分量归零

**核心规则**：
- **碰撞分类**（5 类）：Ground / Enemy / Item / PitBottom / Player
- **layer matrix**：Ground 阻挡所有；Enemy↔Player 触发伤害（S3 仲裁）；Item↔Player 触发拾取；PitBottom 触发死亡
- **重力**：每帧累加 gravity.default，封顶 maxFallSpeed
- **摩擦**：地面无输入时水平 v × (1 - friction.ground)
- **解算顺序**：先垂直、后水平（与 SMB 一致）
- **踩踏判定**：玩家垂直 v > 0 且接触点在敌人头部 hitbox 上沿 → 触发踩踏（S4 处理）

**接口**：依赖 S1 / S4 / S5；影响 S3 / S4 / S6

**边界**：
- 不做 CCD，高速用步进扫描
- 不做斜坡（1-1 全平台）
- 不做物理材质（除冰面字段预留）

---

### S3 · 玩家状态机

**职责**：管理 5 形态（Small / Big / Fire / Invincible / Dead）转移、转移期冻结、无敌帧。

**数值表锚**：`data/player.json` →
- `states[].id` / `canShoot` / `canCrouch`
- `transitions[].from/to/trigger/freezeFrames/iframes`
- `invincible.duration` / `invincible.warningFrames`
- `damage.iframesAfterHit`

**玩家感知**：
- 看到：变大 / 变红 / 闪烁 / 倒地
- 触发：吃蘑菇 / 吃花 / 吃星星 / 被命中 / 落坑
- 生效中：转移期全局短暂冻结；无敌期忽略敌人伤害（不忽略坑底）
- 结束：冻结结束 → 状态切换完成；无敌期结束 → 闪烁停止

**核心规则**（状态图）：
- Small ─(蘑菇)→ Big
- Big ─(花)→ Fire
- Small ─(花)→ Fire（经典规则）
- Fire ─(受伤)→ Big；Big ─(受伤)→ Small；Small ─(受伤)→ Dead
- 任意非 Dead ─(星星)→ Invincible（叠加层，结束回底层）
- 任意 ─(落坑/超时)→ Dead

转移冻结期内全局逻辑暂停（S9 协调）。受伤后 iframesAfterHit 期间无敌但不无视坑底。

**接口**：依赖 S5 道具 / S2 物理（坑底）；影响 S1（canCrouch）/ S6（火球指令）

**边界**：
- 状态机扁平（无嵌套）
- Invincible 与基础形态独立（不污染基础状态机）

---

### S4 · 敌人系统

**职责**：管理 Goomba / Koopa Troopa / Piranha Plant 的 AI 行为。

**数值表锚**：`data/enemies.json` →
- `goomba.walkSpeed` / `goomba.score` / `goomba.flatDuration`
- `koopa.walkSpeed` / `koopa.shellSpeed` / `koopa.shellWaitFrames` / `koopa.score`
- `piranha.riseHeight` / `piranha.cycleFrames` / `piranha.hideOnPlayerNear`

**玩家感知**：
- 看到：敌人巡逻、被踩压扁、被火球击爆、缩壳/出壳/飞速壳
- 触发：进入屏幕（`data/enemies.json → spawnDistance`）/ 被踩 / 被火球击中
- 生效中：按 AI 行为更新位置；缩壳后被踢飞水平移动直到撞墙反弹或撞死其他敌人
- 结束：死亡播放销毁动画 + 飘分

**核心规则**：

#### Goomba
- 出场后向左恒速走（`walkSpeed`）
- 撞墙转向
- 与悬崖：可掉落（不主动停下）
- 被踩：变扁形态，停留 `flatDuration` 帧后消失
- 被火球：上下翻转 + 下落 + 销毁
- 与玩家小马里奥侧面接触：玩家受伤

#### Koopa Troopa Green
- 出场后向左恒速走，撞墙转向
- 与悬崖：**会停下**（向后转，不掉落）
- 被踩：缩壳静止 `shellWaitFrames` 帧
- 缩壳期间被再踩：壳被踢飞，水平 `shellSpeed` 速度
- 飞行壳撞其他敌人：连锁击杀（每只 +200 累加）
- 飞行壳撞墙：反弹方向
- 静止壳被站立：不会受伤（玩家可站在壳上）

#### Piranha Plant
- 在管道内周期升降：升起 `cycleFrames` 帧 → 停留 → 下降 → 隐藏 → 循环
- **玩家在管道附近时不升起**（`hideOnPlayerNear`，避免不公平）
- 完全升起时与玩家接触造成伤害
- 不可被踩（顶部有刺）
- 可被火球击中销毁

**接口**：依赖 S2 物理 / S3 状态机（玩家受伤判定）；影响 S8 计分

**边界**：
- 1-1 不出现 Red Koopa / Bowser / Lakitu / Bullet Bill
- AI 完全数据驱动，不写死循环

---

### S5 · 道具系统

**职责**：管理蘑菇 / 火花 / 星星 / 1UP 的产生、移动、拾取效果。

**数值表锚**：`data/items.json` →
- `mushroom.spawnAnimFrames` / `mushroom.walkSpeed`
- `firePower.spawnAnimFrames`（火花原地不动）
- `star.bounceVelocity` / `star.walkSpeed` / `star.duration`
- `oneUp.walkSpeed`

**玩家感知**：
- 看到：道具从砖块顶部缓缓升起（spawnAnim） → 滚出
- 触发：玩家顶问号块 / 隐藏砖；玩家接触道具
- 生效中：道具按各自 AI 移动
- 结束：被拾取 → 状态变更（S3）/ 离屏销毁

**核心规则**：

#### 超级蘑菇（Super Mushroom）
- 从问号块顶部升起，到达高度后向右滚动
- 与地面碰撞：保持水平速度
- 与墙碰撞：反向
- 拾取：Small → Big（S3）

#### 火之花（Fire Flower）
- 升起后**原地不动**（不滚动）
- 拾取：Big → Fire / Small → Fire

#### 无敌星星（Star）
- 升起后向右滚动 + 持续小弹跳
- 拾取：触发 Invincible 状态（S3）

#### 1UP 蘑菇（1-Up Mushroom）
- 仅从隐藏砖块产生
- 滚动行为同超级蘑菇
- 拾取：剩余生命 +1

**接口**：依赖 S2 物理 / S6 关卡元素（产生源）；影响 S3 / S8

**边界**：
- 不做 starman 之外的特殊形态（不做青蛙服 / 浣熊尾 等）
- 不做共享池（每个产生源独立产物）

---

### S6 · 关卡元素

**职责**：管理可交互关卡元素的触发与产出。

**数值表锚**：`data/level-elements.json` →
- `brick.breakable` / `brick.bumpFrames`
- `questionBlock.itemType` / `questionBlock.usedSpriteId`
- `pipe.length` / `pipe.enterable` / `pipe.destination`
- `coin.spawnHeight` / `coin.value`
- `flagpole.segments[]`（高度→分数）
- `castle.enterAnim`

**玩家感知**：
- 看到：砖块抖动 / 问号变色 / 金币飞旋 / 旗杆下滑
- 触发：玩家从下方撞顶 / 玩家接触 / 玩家进入管道
- 生效中：各元素自身动画
- 结束：砖块碎裂或恢复 / 问号变 used / 金币消失加分

**核心规则**：

#### 普通砖块（Brick）
- 小马里奥顶撞：砖块短暂上抖（bumpFrames）后回位，不破坏
- 大马里奥/火力顶撞：砖块爆裂消失（粒子由 ux-designer 定）
- 破坏时若上方站有敌人：敌人翻身死亡

#### 问号块（? Block）
- 顶撞：变色（active → used），产出 `itemType`（金币 / 蘑菇 / 火花，由关卡数据指定）
- used 状态后不可再触发

#### 硬砖（Hard Block）
- 永远不可破坏，仅作为地形

#### 管道（Pipe）
- 4 种长度（短/中/长/超长）由 `pipe.length`
- 部分管道 `enterable=true`：玩家在顶部按下→进入对应 destination
- 1-1 隐藏房：左侧第二根管道→金币地下房（destination 由关卡数据指定）

#### 金币（Coin）
- 接触：`coin.value` 加分 / coin counter +1
- 100 coin → 1UP（S8 触发）

#### 旗杆（Flagpole）
- 玩家碰旗杆：触发抓杆下滑动画
- 抓住高度决定分数（`flagpole.segments`：1-杆顶/2/3/4/5-杆底，越高分越多）
- 下滑结束→挥旗→城堡过场

#### 城堡（Castle）
- 旗杆触发后玩家自动走入城堡门
- 触发关卡完成（S9）

**接口**：依赖 S1 / S2；影响 S3 / S5 / S8 / S9

**边界**：
- 1-1 不含跳板砖（POW Block）/ 弹簧 / 蹦床
- 隐藏 1UP 砖位置见关卡数据，不做随机生成

---

### S7 · 摄像机系统

**职责**：横向跟随玩家，限制不可回退，边界夹取。

**数值表锚**：`data/camera.json` →
- `followDeadzone.x` / `followDeadzone.y`（死区半径）
- `lookahead.run` / `lookahead.walk`（前瞻距离，跑步时更大）
- `bounds.left` / `bounds.right` / `bounds.top` / `bounds.bottom`
- `noScrollBack`（true）

**玩家感知**：
- 看到：屏幕跟随玩家右移；左移到一定距离时屏幕不再向左
- 触发：玩家位置离开 deadzone
- 生效中：屏幕匀速跟随
- 结束：玩家死亡时停止跟随；通关后切城堡过场

**核心规则**：
- **死区**：玩家在 deadzone 内移动时屏幕不动，超出后开始跟随
- **不可回退**：屏幕已滚动到的最右位置成为新的 left bound（noScrollBack）
- **边界夹取**：屏幕中心位置被 `bounds.left/right/top/bottom` 夹取
- **关卡 X 上限**：到旗杆位置时屏幕停止滚动

**接口**：依赖 S1（玩家位置）；影响 S4（敌人激活基于屏幕位置）

**边界**：
- 不做平滑跟随（与原作一致，硬性跟随）
- 不做镜头特效（缩放/震动 minimal，详见 ux-designer VFX 表）

---

### S8 · 计分与生命系统

**职责**：管理分数、金币、生命、时间倒计时。

**数值表锚**：`data/scoring.json` →
- `score.coin` (200) / `score.goomba` (100) / `score.koopa` (100) / `score.shellChain[]`
- `score.flagpole.byHeight[]`
- `score.timeBonus` (50/秒)
- `lives.initial` (3) / `lives.gainPer100Coins` (1)
- `time.initial` (300) / `time.warningAt` (100)

**玩家感知**：
- 看到：HUD 分数+金币+生命+时间实时更新；得分时飘字
- 触发：金币 / 击杀 / 旗杆 / 时间结束
- 生效中：分数累加 / 时间每秒 -1
- 结束：通关时计算 timeBonus；100 coin 触发 1UP

**核心规则**：
- 分数来源 5 类：金币 / 击杀（含连锁加成）/ 旗杆高度 / time bonus / 隐藏房
- **连锁击杀**：壳连续撞敌人，依次 100/200/400/800/1000/2000/4000/8000/1UP
- **时间倒计时**：从 time.initial 开始 -1/秒；到 100 触发警告（HUD 闪烁）；到 0 触发死亡
- **100 coin 1UP**：每攒满 100 coin → 生命 +1，counter 归零

**接口**：依赖 S4 / S5 / S6；影响 S3（time=0 触发 Dead）/ HUD

**边界**：
- 不做存档（生命/分数关闭即失）
- 不做联机记分

---

### S9 · 关卡流程状态机

**职责**：管理关卡级状态（预备/游戏中/暂停/死亡/重生/通关/GameOver）。

**数值表锚**：`data/level-flow.json` →
- `transitions.deathDelay` / `respawnDelay` / `clearDelay`
- `gameOverDelay`

**玩家感知**：
- 看到：开始画面 / 暂停遮罩 / 死亡黑屏 / 通关字幕 / Game Over
- 触发：关卡加载 / ESC / 玩家死亡 / 旗杆触发 / 0 命
- 生效中：各阶段独立逻辑（暂停时全局冻结）
- 结束：阶段切换到下一状态

**核心规则**：

```
[Loading] → [Ready 1.5s] → [Playing] ──→ [Paused (ESC toggle)]
                              │   ↑          │
                              │   └──────────┘
                              ↓
                    ┌───[Death (3s)] ──→ [Respawn] → [Playing]
                    │      │
                    │  (lives=0)
                    │      ↓
                    │   [GameOver (3s)] → [Title Screen]
                    │
                    └───[FlagTouch] → [Slide+Castle (5s)] → [WorldClear (3s)] → [Title]
```

**接口**：依赖 S3（玩家死亡触发）/ S6（旗杆触发）；影响所有运行时系统（暂停冻结）

**边界**：
- 不做存档点
- 不做关卡选择菜单（直接进 1-1）

---

## 5. 数值与平衡

> 所有数值在 data/*.json 中，本节列字段表 + 基准值。

### 5.1 角色运动数值表

字段：`data/player.json` →

| 参数 | 字段 | 基准值 | 说明 |
|---|---|---|---|
| 走路最大速度 | walk.maxSpeed | 90 px/s | 普通行走 |
| 跑步最大速度 | run.maxSpeed | 150 px/s | 按跑键 |
| 加速度 | walk.accel / run.accel | 200 / 300 | 平滑过渡 |
| 转身减速度 | turnAround.decel | 400 | 反向按键 |
| 跳跃初速 | jump.initialV | -340 px/s | 向上 |
| 持跳低重力 | jump.holdGravity | 600 | 按住时 |
| 释跳高重力 | jump.releaseGravity | 1500 | 松开后 |
| 持跳最大帧数 | jump.maxHoldFrames | 18 | ~0.3s |
| 终端速度 | physics.maxFallSpeed | 600 | 下落上限 |
| 空中加速倍率 | air.accelMultiplier | 0.6 | 空中控制弱 |

### 5.2 敌人数值表

字段：`data/enemies.json`

| 敌人 | walkSpeed | score | 备注 |
|---|---|---|---|
| Goomba | 30 | 100 | 撞墙转向 |
| Koopa Green | 30 | 100 | 悬崖会停 |
| Koopa shell | 200 | — | 飞速壳 |
| Piranha | 0（升降）| 200 | 不可踩 |

连锁击杀：100/200/400/800/1000/2000/4000/8000/1UP

### 5.3 道具数值表

字段：`data/items.json`

| 道具 | walkSpeed | duration | score |
|---|---|---|---|
| Mushroom | 60 | — | 1000 |
| Fire Flower | 0 | — | 1000 |
| Star | 60 | 10s | 1000 |
| 1UP | 60 | — | 生命+1 |

### 5.4 关卡时间与节奏

字段：`data/levels/1-1.json`

| 参数 | 值 | 说明 |
|---|---|---|
| 总时长 | 300（游戏时） | NES 原作 400，1280×720 适配缩短 |
| 警告阈值 | 100 | HUD 开始闪烁 |
| 时间扣减 | 1/秒 | 实时减 |
| 通关 timeBonus | 50/秒 × 剩余时间 | 加分 |

### 5.5 难度曲线

```
紧张度 ↑
   高 │              ╱──────╲      ╱──╲
   中 │     ╱──╲    ╱        ╲    ╱    ╲
   低 │ ───╱    ╲──╱          ╲──╱      ╲───
       └────────────────────────────────────→ 关卡进度
       出生 教学 蘑菇 砖块山 大坑 升降台 旗杆
```

### 5.6 平衡校验目标

- 新手通关率 ≥ 30%（5 次内）
- 平均死亡次数 ≤ 4
- 平均通关时长 80-120 秒

---

## 6. 内容与节奏

### 6.1 关卡分段（Beat Map）

1-1 关卡分 6 个 beat，详见 `data/levels/1-1.json → beats[]`：

#### Beat 1: 教学开场（0-200px）
- **目的**：让玩家熟悉控制
- **元素**：空地，无敌人无障碍
- **教学**：移动键

#### Beat 2: 第一只 Goomba + 第一组管道（200-700px）
- **目的**：教踩敌 + 跳过管道
- **元素**：1 Goomba + 2 矮管道（高 2/3 tile）+ 头顶 4 问号块
- **教学**：跳跃 + 顶砖 + 踩头
- **隐藏**：第一根管道顶部的"隐形砖"含 1UP（往上跳触发）

#### Beat 3: 砖块山 + 多 Goomba（700-1500px）
- **目的**：教连续跳 + 高度选择
- **元素**：阶梯式砖块 + 2 Goomba + 3 问号块（含 1 蘑菇）
- **教学**：节奏跳 + 探索

#### Beat 4: 大坑 + Koopa（1500-2300px）
- **目的**：教远跳 + 龟壳战术
- **元素**：1 长管道 + 1 Koopa Green + 1 大坑（>3 tile 宽）
- **教学**：远跳风险 + 踩龟壳
- **隐藏**：管道下方水管房（金币雨）

#### Beat 5: 升降台段（2300-2900px）
- **目的**：教动态平台
- **元素**：2 个移动平台 + 大坑下面
- **教学**：落点预判
- **隐藏**：平台路径上方的金币串

#### Beat 6: 旗杆收尾（2900-3200px）
- **目的**：高潮收束
- **元素**：阶梯地形 → 旗杆 → 城堡
- **教学**：高度奖励

### 6.2 教学节拍

每个 beat 都有"无文字"教学要素（详见各 beat 描述）。前 10 秒最关键（§2.5）。

### 6.3 隐藏内容

| 类型 | 位置 | 触发 | 奖励 |
|---|---|---|---|
| 隐形砖（1UP）| Beat 2 上方 | 小马里奥跳起顶到 | 1UP 蘑菇 |
| 金币雨房 | Beat 4 管道下 | 进入管道 | 大量金币 |
| 隐形金币 | Beat 5 平台上方 | 跳起触发 | 金币串 |

### 6.4 节奏强度曲线

紧张-放松交替设计：
- Beat 1（缓）→ Beat 2（中）→ Beat 3（中高）→ Beat 4（高）→ Beat 5（高）→ Beat 6（高潮释放）

### 6.5 关底高潮（旗杆段）

旗杆分 5 段（从顶到底分数递减）：
- 杆顶：5000
- 第 2 段：4000
- 第 3 段：2000
- 第 4 段：800
- 杆底：100

抓住后下滑 → 挥旗 → 走入城堡 → WORLD CLEAR + timeBonus 结算

---

## 7. UX 与 HUD

### 7.1 主菜单（Title Screen）

**触发**：游戏启动 / Game Over 后 3s / 通关后 3s

**布局**（屏幕分区）：
- 上 1/3：主标题 `SUPER MARIO BROS.` 大字居中
- 主标题下：副标题 `World 1-1` 中字
- 下 1/3 上沿：闪烁文字 `Press SPACE to Start`（1.0s on/off）
- 底部 4 行控制说明：
  ```
  MOVE     ← →   or   A D
  JUMP     SPACE  or   Z
  RUN      SHIFT  or   X     (hold while moving)
  PAUSE    ESC
  ```
- 最底：版权 `© 2026 Studio · Tribute Build`

**背景**（`data/hud.json#title.background`）：深蓝夜空渐变 + 剪影山脉（2-3 层视差）+ 月亮（右上）

**字段**：`data/hud.json#title` → `title.text` / `subtitle.text` / `cta.text` / `cta.blinkPeriod` / `controls[]` / `background.*`

### 7.2 游戏内 HUD

**布局**：单行顶部条，4 区水平等分

| 区位 | 模块 | 显示 |
|---|---|---|
| 左 | MARIO + 分数 | `MARIO` 标签 + 6 位数字（前导 0）|
| 中左 | 金币 | 旋转金币图标 + `×` + 2 位数字 |
| 中右 | WORLD | `WORLD` 标签 + `1-1` |
| 右 | TIME | `TIME` 标签 + 3 位数字 |

**HUD 元素 → 玩家感知映射**：

| 元素 | 触发更新 | 视觉反馈 |
|---|---|---|
| 分数 | 任何 score 事件 | 数字立即跳变（无 tween）|
| 金币 +1 | 拾取/顶问号 | 数字 +1，图标 pop（VFX-21）|
| 金币 ≥ 90 | 接近 100 | 图标轻微高亮（VFX-26 提示）|
| 金币 = 100 | 触发 1UP | 图标强闪 + 数字归零 + HUD 短暂金光 |
| TIME | 每秒 -1 | 数字跳变 |
| TIME ≤ 100 | 警告阈值 | 数字+标签红白闪烁（VFX-25）+ BGM 加速 |
| TIME = 0 | 触发死亡 | 闪烁停止，进入死亡流程 |

**字段**：`data/hud.json#ingame` → `layout.regions[]` / `score.{digits,padZero}` / `coin.{iconSprite,highlightAt,celebrateAt}` / `world.text` / `time.{warningThreshold,blinkPeriod}` / `colors.{normal,warning,celebrate}`

**核心规则**：
- HUD 永不被关卡内容遮挡
- HUD 不响应输入
- 暂停时 HUD 显示但不更新（time 不流逝）
- 死亡/通关流程中 HUD 仍可见

### 7.3 暂停界面

**触发**：Playing 状态按 ESC

**结构**：
- 半透明黑色遮罩（不透明度 60%，覆盖游戏区，不覆盖 HUD）
- 屏幕中央：大字 `PAUSE`（白）
- 下方：`Press ESC to Resume`

**规则**：
- 全局时间冻结（物理/动画/计时/音频）
- 再按 ESC → 遮罩淡出 0.2s → Playing
- 暂停态不接受其他输入
- 可无限保持

### 7.4 死亡反馈

| 阶段 | 时长 | 玩家可见 |
|---|---|---|
| 死亡瞬间 | 即时 | 角色暂停一瞬（VFX-12 第 1 段）|
| 死亡动画 | ~3.0s | 向上跳一下后坠落出屏 + 死亡曲 + 时间停止 |
| 黑屏过场 | ~0.5s | 全黑淡入 |
| 剩余生命展示 | ~1.5s | "MARIO × N" 居中 |
| 分支 | — | 生命≥1 → 重生 / 生命=0 → Game Over |

字段：`data/level-flow.json` → `transitions.deathDelay`(3s) / `respawnDelay`(0.5s)

### 7.5 通关界面

**流程**：

| 阶段 | 时长 | 内容 |
|---|---|---|
| 抓旗杆 | 即时 | 角色抓杆姿态切换 + 旗下降音 |
| 旗杆下滑 | ~1.0s | 角色沿杆下滑（线性）+ 计算分段得分 |
| 落地挥旗 | ~0.5s | 挥旗 sprite + 高度奖励飘字（5000/4000/2000/800/100）|
| 走入城堡 | ~1.5s | 角色自动右走 + 城堡门进入 |
| 城堡旗升 | ~1.5s | 城堡顶旗子升起 + 通关音乐起 |
| WORLD CLEAR + 结算 | ~3.0s | 字幕 + timeBonus（50 × 剩余时间）累加动画 |
| 回标题 | — | 淡黑 → 标题 |

**旗杆分段得分**（`data/scoring.json → flagpole.byHeight[]`）：

| 段位 | 高度（从顶到底）| 分数 |
|---|---|---|
| 1（杆顶）| 100% | 5000 |
| 2 | 70-100% | 4000 |
| 3 | 40-70% | 2000 |
| 4 | 10-40% | 800 |
| 5（杆底）| 0-10% | 100 |

### 7.6 输入提示与可达性

**默认键位**：

| 输入 | 动作 |
|---|---|
| ← → / A D | 左右移动 |
| Z / Space | 跳跃（按住更高）|
| X / Shift | 跑（按住）|
| ↓ / S | 下蹲（仅大/火力）|
| ↑ / W | 进入管道（特定位置）|
| ESC | 暂停 / Title 退出 |

**手柄占位**（Phase 2+）：
- 左摇杆/D-pad → 移动
- A/B → 跳跃
- X/Y → 跑步

**可达性占位**（Phase 2+）：
- 色盲模式：HUD 警告通过形状变化辅助（如 TIME 警告时数字旁加 ⚠ 图标）
- 屏幕阅读器支持：暂时无

---

## 8. 交付与验收

### 8.1 交付目标平台

- PC / Windows
- 1280×720 viewport
- 60 FPS 锁帧
- Godot 4.6.2 build

### 8.2 验收标准（DoD）

| # | 标准 | 优先级 | 验证方式 |
|---|---|---|---|
| 1 | 关卡可通关（旗杆+城堡）| P0 | 手动 |
| 2 | 死亡可重生 | P0 | 手动 |
| 3 | 5 状态完整可达 | P0 | 单测 + 手动 |
| 4 | 3 敌人 AI 正确 | P0 | 单测 + 手动 |
| 5 | 4 道具效果正确 | P0 | 单测 + 手动 |
| 6 | 关卡元素全套 | P0 | 手动 |
| 7 | HUD 实时正确 | P0 | 单测 + 手动 |
| 8 | 60 FPS 稳定 | P0 | godot --print-fps |
| 9 | 隐藏内容可发现 | P1 | 手动 |
| 10 | 旗杆高度奖励正确 | P1 | 单测 |
| 11 | 100 coin → 1UP | P1 | 单测 |
| 12 | 时间倒计时 + 警告 | P1 | 手动 |

### 8.3 性能预算

- 帧率：60 FPS（最低 55）
- 内存：< 200MB
- 加载时间：< 3 秒（关卡 1-1）
- 编辑器启动：< 5 秒

### 8.4 测试用例

| # | 用例 | 类型 |
|---|---|---|
| 1 | levels.json 数据完整性 | 单元 |
| 2 | player 状态机转移 | 单元 |
| 3 | 敌人各 AI 分支 | 单元 |
| 4 | 道具效果应用 | 单元 |
| 5 | 计分系统（连锁/旗杆/timeBonus）| 单元 |
| 6 | 100 coin → 1UP | 单元 |
| 7 | 完整通关流程 | 集成 |
| 8 | 死亡重生流程 | 集成 |
| 9 | 暂停/恢复 | 集成 |
| 10 | 隐藏内容触发 | 手动 |
| 11 | 帧率稳定性 | 性能 |
| 12 | UI 截图回归 | 视觉 |

### 8.5 风险

| 风险 | 概率 | 影响 | 缓解 |
|---|---|---|---|
| 跳跃手感与原作偏差 | 高 | 玩家体验受损 | data-driven 调参 + 反复 playtest |
| 摄像机不可回退导致玩家卡死 | 中 | 玩家无法前进 | bounds 严格夹取 + 测试覆盖边界 |
| 状态机转移期物理 bug | 中 | 漂移 / 卡墙 | freezeFrames 期间冻结所有物理 |
| 火球穿过砖块 | 中 | 玩法异常 | 火球独立碰撞层 + 单测 |
| 性能：屏幕内敌人/道具过多 | 低 | 帧率下降 | 屏幕外不激活 + 对象池 |

### 8.6 已知限制

- 只复刻 1-1，不含其他关卡
- 音效用免版权占位，与原作不同
- 美术从零做，与原作精灵不完全像（避免 IP 风险）
