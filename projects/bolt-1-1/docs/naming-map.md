# bolt-1-1 · 命名映射表

> 项目原创化的权威映射表。所有代码 / 数据 / 文档统一按此命名。
> 之前的 mario-1-1 命名仅在 retro / postmortem 等历史档案中保留。

## 项目身份

| 项 | 值 |
|---|---|
| 项目名 | **Bolt 1-1**（代号 / 文件路径）/ **Bolt: Sector 1-1**（展示名） |
| 主角 | **Bolty** ——红色机械豆形态的小机器人 |
| 世界观 | 工业风像素平台跳跃。Bolty 在被废弃的 Sector 1-1 中前进，目标是激活信号塔召唤主基地 |
| 类型 | 2D Side-Scrolling Platformer · 单关教学复刻 |
| 视觉风格 | NES 8-bit 像素 + 现代清晰度（pixel-perfect / 整数缩放）。色调：工业感（橘红 / 金黄 / 蓝灰），与马里奥的童趣鲜亮做明显区分 |

## 角色 · 主角 Bolty

| 维度 | 规格 |
|---|---|
| Silhouette | 圆头 + 短身 + 短腿 + 双手扣式工装；**无胡子、无帽 brim**（与马里奥的胡子大叔造型完全不同）|
| 主色 | 红色金属漆 `#E03030`（Bolty 红，比马里奥红更暗）|
| 副色 | 黄色相机镜头 `#FFC820`（替代马里奥的肤色脸）|
| 大态 | small 尺寸 16x16 + big 尺寸 16x32（Bolty 头部下加一节 chassis 身躯节，机械式延展，不是"长高"）|
| 火力态 | 银白外壳 + 蓝色相机眼，象征能量过载 |
| Death | 短路冒火花后向后倒下消失 |

## 角色 · 敌人

| 原 mario | 新 bolt | 视觉描述 | 行为 |
|---|---|---|---|
| Goomba | **Mossroll** | 圆球苔藓体 + 两条短腿 + 顶部一撮苔藓发；色：苔绿 `#5C8030` + 深绿暗部 | 巡逻、撞墙反向；被踩压扁；侧面碰撞伤害玩家 |
| Koopa Green | **Shellpod** | 圆柱形甲虫，主色金属灰 `#8B9090` + 绿铜色甲壳 `#3C9050`；可缩进甲壳；甲壳像金属胶囊 | 巡逻；被踩缩进甲壳；再踩 / 撞 → 甲壳高速弹射，撞墙反弹，沿途清杀其他敌人 |
| Piranha Plant（占位） | **Spiker**（占位） | 钢钉植物，从管道中升降 | Phase 2 TODO |

## 角色 · 道具

| 原 mario | 新 bolt | 视觉描述 | 效果 |
|---|---|---|---|
| Super Mushroom | **Power Berry** | 红色发光浆果 + 金黄叶冠；表面有纹理光晕 | 小态 → 大态；+1000 |
| Fire Flower | **Spark Bloom** | 白色四瓣电花 + 中心蓝白电弧脉动 | 任意 → 火力态；可发射火球（保留火球机制）；+1000 |
| 1UP Mushroom | **Blue Crystal** | 蓝色棱形水晶 + 白色高光 | +1 命 |
| Coin | **Cog**（齿轮） | 黄色齿轮 sprite，旋转 4 帧动画 | +200 + 计数；100 个 → +1 命 |
| Star（无敌） | **Pulse Core** | 紫色脉动核心（Phase 2，本期不实现）| 无敌 10s |

## 关卡元素

| 原 mario | 新 bolt | 视觉描述 |
|---|---|---|
| Brick | **Brick**（保留通用术语） | 工业风橘红砖块，金属边框；大态可砸碎产生 4 块碎片 |
| Question Block | **Cache Box** | 金黄色金属箱体，正面"?"字符闪烁；触发后变暗棕"used"态 |
| Hard Block | **Hard Block** | 灰色岩石 / 金属平台，不可破坏 |
| Pipe | **Conduit**（管道）| 暗绿色金属管道 + 高光 + 阴影；无头小怪生物可埋伏 |
| Flagpole | **Signal Tower** | 灰色金属杆 + 顶部信号球 + 红色信号旗（替代马里奥旗杆的白绿旗）|
| Castle | **Outpost** | 灰色金属哨站 + 中心门 + 顶部天线 |

## 世界 / 关卡

| 原 mario | 新 bolt |
|---|---|
| World 1-1 | **Sector 1-1** |
| WORLD CLEAR | **SECTOR CLEAR** |
| GAME OVER | **SYSTEM FAILURE** |
| MARIO（HUD 标签）| **BOLTY** |
| TIME（HUD 标签）| **TIME**（保留，通用术语）|

## 配色总则（与马里奥做明显区分）

mario-1-1 用的是 NES 鲜亮儿童色板（天蓝 + 草绿 + 红蓝主角）。bolt-1-1 用工业 + 苔藓色板：

| 类别 | 色 |
|---|---|
| 背景天空 | 工业灰蓝 `#445C78`（比 mario 的 `#5C94FC` 更暗）|
| 地面顶 | 干苔藓黄 `#9C8830`（替代 mario 的草绿 `#00A800`）|
| 地面体 | 锈红土 `#783820`（保留 mario 的暖棕方向）|
| 主角红 | Bolty 红 `#E03030`（比 mario 红 `#E40058` 更橙调，少粉色）|
| 主角辅色 | 金黄相机眼 `#FFC820` |
| 敌人 Mossroll | 苔绿 `#5C8030` |
| 敌人 Shellpod 甲 | 铜绿 `#3C9050` |
| 道具 Power Berry | 浆果红 `#C42040` + 高光黄 |
| 道具 Spark Bloom | 白 + 蓝 `#FFFFFF` / `#3CC0FF` |
| 道具 Blue Crystal | 水晶蓝 `#3878F0` |
| Cog 齿轮 | 黄铜 `#E8A018` |
| Conduit 管道 | 暗绿金属 `#384830` + 高光 `#6C9050` |
| 信号塔 | 灰金属 `#A0A0A8` + 信号红 `#D04030` |

## 代码 class / 文件名映射

实施阶段会把以下 class / 文件路径改名：

| 原 | 新 | 文件 |
|---|---|---|
| `Goomba` | `Mossroll` | `enemies/goomba.gd` → `enemies/mossroll.gd` |
| `Koopa` | `Shellpod` | `enemies/koopa.gd` → `enemies/shellpod.gd` |
| `Brick` | `Brick`（保留）| 不改 |
| `QuestionBlock` | `CacheBox` | `blocks/question_block.gd` → `blocks/cache_box.gd` |
| `SuperMushroom` | `PowerBerry` | `items/super_mushroom.gd` → `items/power_berry.gd` |
| `FireFlower` | `SparkBloom` | `items/fire_flower.gd` → `items/spark_bloom.gd` |
| `OneUpMushroom` | `BlueCrystal` | `items/oneup_mushroom.gd` → `items/blue_crystal.gd` |
| `Flagpole` | `SignalTower` | `level/flagpole.gd` → `level/signal_tower.gd` |
| `Castle` | `Outpost` | `level/castle.gd` → `level/outpost.gd` |

## json type 字段映射

`data/levels/1-1.json` 中实体 `type` 字段：

| 原 | 新 |
|---|---|
| `goomba` | `mossroll` |
| `koopaGreen` | `shellpod` |
| `questionBlock` | `cacheBox` |
| `brick` | `brick`（保留）|
| `pipe` | `conduit` |
| `flagpole` | `signalTower` |
| `castle` | `outpost` |
| `movingPlatform` | 保留（功能名通用）|

## 历史档案保留 mario 名

以下档案不动（保留 IP 风险讨论的真实历史）：
- `retros/2026-05-15-*-postmortem.md` 系列
- `reports/archive/section-3-visual-2026-05-15-merged.md`

它们是审计痕迹，记录 mario→bolt pivot 的原因。
