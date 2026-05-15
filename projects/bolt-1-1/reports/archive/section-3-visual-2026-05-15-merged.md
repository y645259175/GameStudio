---
section: 3
title: 视觉与美术
owner: art-director
status: drafted
version: 0.5-detail
last_review: 2026-05-15
note: §3.6 VFX 表由 ux-designer 单独产出，本文件留接口
---

> **历史档案 · 2026-05-15 之前命名版本**
>
> 项目已在 2026-05-15 pivot 至 bolt-1-1 完全原创版本。
> 本档案保留旧命名作为审计痕迹，不代表当前项目状态。
> 当前命名见 `docs/naming-map.md`，当前 GDD 见 `gdd/gdd-bolt-1-1.md`。

## 3. 视觉与美术

本章定义 mario-1-1 的视觉方向、色板、精灵规格、tileset 组成、UI 视觉与过场表现。
目标：在保留 NES 原作可识别度的前提下，做到现代显示器上的清晰锐利与 pipeline 上的可批量生产。

### 3.1 整体艺术风格

- **基调**：NES 8-bit 像素 + 现代清晰度（pixel-perfect、关闭双线性过滤、整数缩放）。
- **基础 tile 单元**：`16x16` 像素（与 NES 原作一致，便于对位地图与碰撞）。
- **小尺寸子单元**：`8x8` 像素，用于 HUD 字体、UI 数字、coin 图标与小型装饰。
- **逻辑分辨率**：`256x240`（NES 原生），运行时按窗口大小做整数倍缩放（2x / 3x / 4x），禁止小数缩放。
- **风格关键词**：`retro-pixel` / `flat-shading` / `hard-edge` / `limited-palette` / `readable-silhouette`。
- **现代化处理**：保留像素硬边，但允许使用更宽色域（不限于 NES 的 54 色）以提升可读性；阴影 / 描边按需引入但不破坏像素轮廓。
- **参考对标**：NES Super Mario Bros. (1985) 1-1 关卡截图为主参考；色彩饱和度向 All-Stars 复刻方向略偏。
- **不做**：不做 HD 重绘风、不做 3D、不做手绘水彩风、不做 outline 描边主体（仅 UI 可有描边）。
- **存放路径**：参考图归 `art/reference/`，风格 prompt 归 `art/style-guide.md`，最终资产输出 `assets/`。

### 3.2 色板（Palette）

全局色板表如下，所有美术资产**必须**从此表取色。落地为 `data/palette.json`，字段名见末列，便于后续自动校验。

| 用途 | 颜色 | Hex | palette.json 字段 |
|---|---|---|---|
| 背景天空 | 天蓝 | `#5C94FC` | `bg_sky` |
| 背景天空（地下） | 纯黑 | `#000000` | `bg_underground` |
| 地面（顶层草绿） | 草绿 | `#00A800` | `ground_top` |
| 地面（土棕） | 棕 | `#A04000` | `ground_body` |
| 砖块 | 橙红 | `#D87050` | `brick_main` |
| 砖块阴影 | 深棕 | `#7C2820` | `brick_shadow` |
| 问号块（active） | 金黄 | `#FAC000` | `qblock_active` |
| 问号块（used） | 暗棕 | `#9C5C20` | `qblock_used` |
| 硬砖（灰岩） | 中灰 | `#BCBCBC` | `hard_block` |
| 管道主体 | 鲜绿 | `#00A800` | `pipe_main` |
| 管道高光 | 浅绿 | `#80D010` | `pipe_highlight` |
| 管道阴影 | 深绿 | `#006800` | `pipe_shadow` |
| 马里奥红（帽/衣） | 鲜红 | `#E40058` | `mario_red` |
| 马里奥蓝（背带/裤） | 深蓝 | `#0058F8` | `mario_blue` |
| 马里奥肤色 | 米黄 | `#FCBCB0` | `mario_skin` |
| 马里奥棕（鞋/发） | 深棕 | `#6C2810` | `mario_brown` |
| 火力马里奥（白） | 纯白 | `#FCFCFC` | `mario_fire_white` |
| Goomba 主色 | 棕 | `#A85820` | `goomba_main` |
| Goomba 暗部 | 深棕 | `#5C2C00` | `goomba_dark` |
| Koopa 绿（壳） | 鲜绿 | `#00A800` | `koopa_shell` |
| Koopa 黄（身/脸） | 金黄 | `#FAC000` | `koopa_body` |
| 旗杆（杆） | 中灰 | `#BCBCBC` | `flagpole_pole` |
| 旗杆（旗帜） | 白绿 | `#80D010` | `flagpole_flag` |
| 城堡主体 | 砖灰 | `#A0A0A0` | `castle_main` |
| 云 / 山高光 | 白 | `#FCFCFC` | `cloud_white` |
| 山远景 | 深绿 | `#007000` | `mountain_dark` |
| 树丛 | 中绿 | `#48A810` | `bush_main` |
| 金币 | 金黄 | `#FAC000` | `coin_main` |
| HUD 文字 | 白 | `#FCFCFC` | `hud_text` |

- 所有 sprite / tile **不得**引入未登记色；若需要新色，必须先回写 `data/palette.json` 并触发 consistency-check。
- 色板表也用于**自动校验工具**：扫描 `assets/*.png` 像素颜色是否全部命中 palette。
- Phase 2 TODO：补一份 `palette-grayscale.json` 用于色弱模式。

### 3.3 角色精灵（Mario · 三态）

马里奥三态共用同一动画状态机，但精灵尺寸与帧数不同。所有 sprite 居中对齐底部（脚底锚点）。

| 状态 | 尺寸（W×H） | 备注 |
|---|---|---|
| 小马里奥 (small) | `16x16` | 出生态，被击中即死 |
| 大马里奥 (big) | `16x32` | 吃蘑菇变身，受击降级为 small |
| 火力马里奥 (fire) | `16x32` | 吃花变身，受击降级为 small |

**每态需要的动画状态**（共 8 项，VFX 时序由 ux-designer 在 §3.6 定义）：

| 动画 ID | 状态名 | 帧数（建议） | 说明 |
|---|---|---|---|
| A-01 | idle | 1 | 站立 |
| A-02 | walk | 3 | 走路循环（左右脚 + 中间过渡） |
| A-03 | run | 3 | 跑步循环（与 walk 共用骨架，速度倍率不同） |
| A-04 | jump | 1 | 起跳上升 |
| A-05 | fall | 1 | 下落（big/fire 可与 jump 共用） |
| A-06 | duck | 1 | 蹲下（仅 big/fire 可用，small 隐藏此态） |
| A-07 | death | 1 | 死亡姿势（仅 small 用，big/fire 受击直接降级） |
| A-08 | transform | 3 | 变身闪烁过渡（small↔big↔fire 共用，由材质替换） |

**总帧数估算**：
- small：`1+3+3+1+1+0+1+3 = 13 帧`
- big：`1+3+3+1+1+1+0+3 = 13 帧`
- fire：`1+3+3+1+1+1+0+3 = 13 帧`（fire 额外需要发射火球的 throw 姿势 × 1 = +1 帧 → 14 帧）
- **合计**：约 40 帧，单图 atlas 推荐 `128x128`（64 格 × 16px）。

**朝向**：sprite 仅画右朝向，左朝向由引擎水平翻转生成。

### 3.4 敌人精灵（Enemies）

1-1 出现的敌人共 3 种 + 1 占位：

| 敌人 | 尺寸 | 动画分解 | 总帧数 |
|---|---|---|---|
| Goomba | `16x16` | walk × 2（左右脚） + flat × 1（被踩扁） | 3 |
| Koopa Troopa Green | `16x24` | walk × 2 + shell-static × 1 + shell-spin × 4 | 7 |
| Piranha Plant（占位） | `16x24` | bite × 2（张/合） | 2（Phase 2 TODO） |

**说明**：
- Goomba 仅有走路与被踩扁两态；被踩后留 0.5 秒 flat 然后消失（具体时序由 §3.6 定）。
- Koopa Troopa 的 `shell-spin` 4 帧用于被踢出后的旋转视觉；静止龟壳为单帧。
- Piranha Plant 在 1-1 中实际只在 1 根管道出现（设计可选），先占位 2 帧 + sprite 资源 Phase 2 补。
- 所有敌人 sprite 锚点同 Mario：底部居中。
- Sprite atlas 推荐独立打包：`assets/enemies-atlas.png`（约 `128x64`）。

### 3.5 关卡 Tileset

地图 tile 全部基于 `16x16` 单元。Tileset 总览（每行给出变体数量）：

| Tile 名 | 尺寸 | 变体数 | 说明 |
|---|---|---|---|
| `ground` 地面 | `16x16` | 1 | 顶层带草绿，下层纯土棕；地面整列由同一 tile 重复 |
| `brick` 砖块 | `16x16` | 1（+碎片 4 帧） | 可被大马里奥砸碎，碎片 4 块独立 sprite |
| `qblock_active` 问号块 | `16x16` | 4（闪烁循环） | 含 `?` 字样 + 金黄底色循环亮度变化 |
| `qblock_used` 问号块（已用） | `16x16` | 1 | 暗棕硬块，不可再触发 |
| `hard_block` 硬砖 | `16x16` | 1 | 灰色岩石，不可破坏 |
| `pipe` 管道 | 见下 | 4 种长度 | 短/中/长/超长 |
| `flagpole` 旗杆 | `16x176` | 1 杆 + 1 顶球 + 1 旗帜 sprite | 杆为 `16x16` × 11 段堆叠 |
| `castle` 城堡 | `80x80` | 1 | 5×5 tile 组合，含门洞与塔顶 |
| `cloud` 云 | `32x16` 或 `48x16` | 2 | 小云 / 大云（背景层） |
| `mountain` 山 | `48x32` | 2 | 大山（深绿） / 小山（带白顶） |
| `bush` 树丛 | `32x16` 或 `48x16` | 2 | 小丛 / 大丛（前景装饰，不可踩） |
| `coin` 金币（关卡内） | `16x16` | 4（旋转循环） | 静态金币 sprite，与 HUD coin 图标区分 |

**管道 4 种长度**：
| 名 | 高 (tile) | 像素 | 用途 |
|---|---|---|---|
| `pipe_xs` | 2 | `32x32` | 起始低管 |
| `pipe_s` | 3 | `32x48` | 标准管 |
| `pipe_m` | 4 | `32x64` | 中管 |
| `pipe_l` | 5 | `32x80` | 终段高管（接近旗杆） |

- 管道宽度统一 2 tile（`32px`），由 `pipe_top_left / pipe_top_right / pipe_body_left / pipe_body_right` 四片 tile 组成。
- Tileset 总图打包路径：`assets/tileset-overworld.png`（建议 `256x256`）。
- 背景元素（cloud / mountain / bush）单独打包到 `assets/tileset-bg.png`，以便视差层管理。
- Tileset 字段名约定与 Godot TileSet 资源对齐，便于导入。

### 3.7 UI 视觉

- **字体**：等宽像素体 `8x8`（自制 bitmap font 或使用现成 NES 字体如 `Press Start 2P` 的 8x8 子集），字符集仅限 `A-Z / 0-9 / 空格 / × / -`。
- **HUD 元素与位置**（基于 256x240 逻辑分辨率，距上边 16px）：
  - 左上：`MARIO` + 6 位分数（如 `000000`）
  - 中左：金币图标 `×` + 2 位金币数（如 `×00`）
  - 中右：`WORLD` + `1-1`
  - 右上：`TIME` + 3 位倒计时（如 `400`）
- **数字样式**：纯白色 `hud_text` (#FCFCFC)，无描边、无阴影；闪烁仅在 TIME 倒计时 ≤100 时启用（每秒闪 2 次）。
- **Coin 图标**：`8x8` 简化版金币（与关卡内 16x16 金币区分），单帧静态，色值 `coin_main` (#FAC000)。
- **颜色规范**：HUD 一律使用 `hud_text` (#FCFCFC) 白；不允许出现彩色文本（Phase 2 可加入 1UP 飘字的绿色）。
- **暂停界面**：黑色半透明蒙层（`#000000` α=0.5）+ 居中 `PAUSE` 文字（白色 8x8 字体放大 2 倍）。
- **死亡 / 通关浮字**：复用 HUD 字体，居中显示。

### 3.8 过场与转场（Transitions）

所有过场以"短而清脆"为准，避免打断 NES 风的紧凑节奏。具体帧数由 §3.6 VFX 表敲定，本节仅给方向与时长档位。

| 过场 | 触发 | 视觉表现 | 时长档位 |
|---|---|---|---|
| **开场** | 关卡载入完成 | **不**做"走出管道"动画；直接淡入（黑→正常）+ HUD 同时亮起 + Mario 站在出生点 idle | 短（约 0.5s 黑屏淡入） |
| **死亡** | Mario 触敌 / 落坑 / TIME=0 | 死亡音效 + Mario 死亡 sprite + 短暂悬停 → 抛物线下落出屏 → 黑屏 | 中（约 2.5s 总流程） |
| **降级**（big/fire→small） | Mario 受击 | 闪烁 transform 动画 + 短暂无敌（约 1.5s） + sprite 缩小 | 短（约 1.5s） |
| **变身**（small→big / →fire） | 吃蘑菇 / 吃花 | 闪烁 transform 动画 + sprite 替换 + 游戏暂停约 0.5s | 短（约 0.5s 暂停） |
| **通关 - 旗杆** | Mario 触旗 | 抓杆 + 旗帜下滑 + Mario 同步下滑 + 落地后向右走 | 中（约 3s 旗杆段） |
| **通关 - 城堡** | Mario 走入城堡门 | Mario 进门消失 + 城堡顶升起小旗 + 烟花 ×3（连续白色像素粒子） | 中长（约 4s 含烟花） |
| **结算** | 烟花结束 | TIME 倒计时换算为分数（每剩 1s = 50 分，加分音效逐位累计） + 短暂停顿 → 进入下一关或回主菜单 | 中（约 3s 结算） |

- **黑屏过渡统一规范**：使用纯黑 `#000000` 全屏覆盖，淡入淡出 0.3s（不使用马赛克 / 圆圈缩放等花式过渡，保持 NES 风）。
- **烟花视觉**：3 发烟花在城堡上空依次绽放，每发 8 颗白色像素粒子向外扩散（具体粒子时序由 ux-designer 在 §3.6 VFX 表登记）。
- **不做**：不做 cutscene 动画 CG、不做角色对话、不做镜头特写。

---

**对接说明**：
- §3.6 动画规格表（VFX）由 **ux-designer** 单独产出，本节列出的所有 sprite / 过场需要 ux-designer 在 VFX 表中以 `VFX-XX` 编号登记每帧时长（ms）与触发条件。
- §3 提供的所有色板、尺寸、帧数为**美术规格上限**，VFX 表不应突破这些约束（如增加帧数需回流 §3.3/3.4 调整）。
