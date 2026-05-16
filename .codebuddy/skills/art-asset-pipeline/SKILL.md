---
name: art-asset-pipeline
type: skill
status: active
description: Art asset production pipeline that calls the workshop-level timiai-image skill for image generation and editing.
---

# Art-Asset-Pipeline · 美术资产生产管线

## 何时使用

项目需要生成 / 编辑美术资产（角色立绘 / UI 视觉 / 海报 / 概念图 / icon / texture / **多帧动画 sprite**）时调用。本 skill 是 `art-director` agent 的工具入口，最终调用工作室级已接入的 `timiai-image` skill。

典型触发：
- "/art-asset-pipeline"
- "生成英雄立绘"
- "做一张主菜单背景图"
- "**生成主角四帧走路动画 / 多状态精灵图**"
- 由 `art-director` agent 自动调用

## 输入 / 触发条件

- 当前在项目根
- 资产需求（用途 / 尺寸 / 风格 / 数量）
- 可选：参考图（1-4 张）

## 流程步骤

1. **意图识别**：分类资产类型
   - 单图：character_concept / ui / poster / icon / concept / texture / background
   - **多帧动画**：character_anim_strip（同一角色不同姿态）
   - **多状态变体**：character_state_variants（同一角色不同形态，如 small/big/fire）
2. **信息检查 · 主动澄清**（按 `timiai-image` skill 的工作流要求）
3. **Prompt 扩写**：把用户口语化描述扩写为多模态模型友好的结构化 prompt
4. **用户确认**：回显扩写后的 prompt（如抽卡则回显 N 个变体）
5. **调用 timiai-image**（按下面"路由决策"选择脚本）
6. **资产落盘**：`projects/<name>/game/assets/<filename>.png` + `.import`
7. **元信息落盘**：`projects/<name>/art/<filename>.meta.json`（含 prompt / 模型 / 时间 / 一致性参考图）
8. **commit 建议**：`[story] art: <category> <topic>` 或 `[quick] art: <category> tweak`

## 路由决策（哪种场景用哪个脚本）

| 场景 | 脚本 | 关键差异 |
|---|---|---|
| 单张独立图（key visual / 单状态 sprite / UI 元素 / tile）| `text2image.py` | 纯 prompt 出图 |
| **多帧动画 / 多状态变体（必须保持角色一致）** | **`image_edit.py` + 1 张参考图** | **传 idle 作为锚点，让其他帧编辑而非重生** |
| 多轮迭代调整（用户反复说"再蓝一点"） | `chat_image.py` | 多轮上下文 |
| 批量出图（≥3 张）| `pipeline.py --kind pipeline` 或 `daemon.py submit` | 并发 + cache + 后处理链 |

## 角色多帧动画 SOP（强制 reference-based）

> ⚠️ **这个段落是强制约束，不是建议。**
>
> 历史教训（2026-05-16 bolt-1-1 M6）：用 `text2image.py` 4 个独立 prompt 生成 idle / walk1 / walk2 / jump，**4 帧角色完全不一致**——一帧像戴帽子的人、一帧像红蜘蛛、一帧像双色机器人。AI 即使 prompt 写"same character"也无法跨调用保持一致。

### 标准流程（必须按顺序执行）

**Step A · 出 1 张 key sprite（idle 帧）**
- 用 `text2image.py` 生成最权威的"角色基准帧"（通常是 idle / 标准站立姿态）
- prompt 必须包含完整的角色 spec：身体比例、配色 hex、特征细节、风格
- 落盘到 `projects/<name>/art/<character>_key.png`（不是 game/assets/，这是参考图）
- **由用户或 art-director 视觉评审通过后才能进 Step B**

**Step B · 用 image_edit 派生其他帧**
- 用 `image_edit.py --image <character>_key.png --prompt "同一角色，改成 <新姿态>"`
- prompt 模板：
  ```
  Same character as the reference image. Identical body proportions,
  identical color palette, identical art style, identical outline.
  ONLY change the pose to: <new pose description>.
  Keep the character size and silhouette consistent with the reference.
  ```
- 每帧独立调用，但都用同一张 key 作为参考
- **不要一次提交多帧**（gpt-image-2 单次只输出 1 张）

**Step C · 多状态变体（small → big → fire）也用同一 key 作锚点**
- big_idle 用 small_idle 作为参考 + prompt "same character but taller proportion with extended chassis"
- fire_idle 用 small_idle 作为参考 + prompt "same character but silver-white shell instead of red, blue eye instead of yellow"
- 这样所有 12 帧（3 状态 × 4 动作）都共享同一血统

### 不允许的反模式

❌ 4 个独立 prompt 同时跑（gpt-image-2 不知道前一帧长什么样）
❌ prompt 里写"same character"但不传参考图（无效）
❌ 用 chat_image 跨多个文件迭代（chat 是单会话上下文）

### 推荐 pipeline 配置（多帧动画专用）

```json
{
  "_anim_pipeline": "Step A 单独跑 text2image 出 key, 评审后跑这个 pipeline 出 Step B",
  "tasks": [
    {
      "id": "char-walk1",
      "type": "image_edit",
      "reference_image": "projects/<name>/art/<char>_key.png",
      "prompt": "Same character as reference. ONLY change pose: ...",
      "size": "1024x1024",
      "post": [{"op": "remove_bg"}, {"op": "crop"}, {"op": "shrink", "size": "32x32"}],
      "final_out": "projects/<name>/game/assets/<char>_walk1.png"
    }
  ]
}
```

> 注意：当前 `pipeline.py` 默认走 `text2image.py`。**多帧动画场景 daemon 提交前要确认 task 配置选用了 image_edit 模式**（如果 pipeline 还不支持需扩 `image_edit` 类型，[Phase 2 TODO]）。

## 角色尺寸规范（建议默认值）

不同游戏需求不同，但本工作室建议的"易看清 + NES 风格"折中值：

| 资产类型 | 推荐 sprite 尺寸 | 屏幕显示比例（1280×720 viewport, camera zoom 1.5x）|
|---|---|---|
| 主角 small | **24×24** | 占屏 2.5%，可清楚分辨四肢 |
| 主角 big / 高态 | **24×40** | 高度 1.6× small，比例对 |
| 普通敌人 | **24×24** ~ **28×32** | 与主角 small 同高或略高 |
| BOSS / 大敌人 | 48×48+ | 视觉震撼 |
| 道具 / icon | **20×20** | 不抢戏，能识别 |
| Tile（地面 / 砖块）| 32×32 | 标准 NES tile |
| Cache Box / 互动方块 | 32×32 | 与 tile 对齐 |

**生成时的源尺寸**永远 **1024×1024**（gpt-image-2 限制），后处理 `shrink` 降采样到目标尺寸。

## 输出

- 美术资产文件（PNG / JPG）
- 资产元信息 JSON（用于追溯，schema 见下）
- 终端内 fallback 链记录（如有降级）

### 元信息 JSON schema

```json
{
  "asset_id": "bolty_small_idle",
  "category": "character_anim",
  "generated_at": "2026-05-16T17:00:00",
  "model": "gpt-image-2",
  "method": "text2image | image_edit",
  "reference_images": ["bolty_small_key.png"],
  "prompt": "...",
  "post_ops": [{"op": "shrink", "size": "24x24"}],
  "key_visual_anchor": "bolty_small_key.png",
  "consistency_with": ["bolty_small_walk1", "bolty_small_walk2", "bolty_small_jump"]
}
```

## 引用

- 上游规划：v4 §6.1.1（美术资产 1 之一）、§9.1（timiai-image 作为 R4 既存事实豁免）
- 上游 skill：`.codebuddy/skills/timiai-image/`（**已存在的工作室级能力，本规划不重建、不改造**）
- 相关 agent：`art-director`（30 agent 之一，由本 skill 协同）
- 相关 rule：`commit-discipline`（双通道）

## Known Limitations / Phase 2 Review Points

- [Phase 2 TODO] `pipeline.py` 增加 `type: image_edit` 任务支持，原生支持 reference-based pipeline
- [Phase 2 TODO] 资产版本管理（同一资产迭代 v1/v2/v3）的命名 / 归档规则未定
- [Phase 2 TODO] 项目美术风格库（多张参考图打包成一个风格）的引用规范未设计
