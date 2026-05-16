---
name: timiai-image
description: Studio image generation & editing via TimiAI Hub. Use when any agent or user needs to generate, edit, or iterate on images - game assets (backgrounds, sprites, UI), concept art, promotional materials, style transfer, or multi-round visual refinement. Supports text-to-image (text2image.py), multi-reference image editing (image_edit.py), and chat-based iterative generation (chat_image.py). Called by art-asset-pipeline skill and art-director agent.
allowed-tools:
disable: false
---

# TimiAI 图像能力

> **工作室集成说明**：本 skill 是 GameStudio 的核心图像生成能力，被以下组件引用：
> - `art-asset-pipeline` skill → 调用本 skill 生成/编辑美术资产
> - `art-director` agent → 通过本 skill 审核和迭代视觉风格
> - `designer` agent → 概念图 / 参考图生成
> - 任何需要图像输出的 agent 均可通过 `art-asset-pipeline` 间接调用
>
> **资产落盘约定**：
> - 游戏内资产 → `projects/<name>/game/assets/` （进交付包）
> - 参考图 / 概念图 → `projects/<name>/art/`（不进交付包）
> - 输出文件名：`<category>_<desc>_<timestamp>.png`

调用腾讯天美 AI Hub（`api.timiai.woa.com`）的图像类 API，统一 `Authorization: <apikey>` 鉴权。

提供三个生图脚本（文生图 / 图像编辑 / 多轮对话）+ 抽卡 + 自动 fallback + 模型探测，详见下文。

## 一、主动触发条件（重要）

**只要用户提到以下任意一类需求，都应主动使用本 skill，不要让用户去写代码：**

- 生成/制作图片、画图、出图、做海报/插画/宣传图/Key Visual/视觉稿
- 图像编辑、改图、把图A的风格套到图B、图生图、多图风格迁移
- 基于参考图做 UI 视觉稿、把交互稿变视觉稿
- 用 TimiAI / 天美AI / gpt-image-2 / Nano Banana / Gemini image preview 等关键词画图
- 多轮迭代调整图片（逐步修改细节）

## 二、标准工作流（五步）

**核心原则：先对齐意图，再按键生图。不要拿到一句模糊描述就直接跑脚本——图像模型对模糊输入出图极不稳定，白烧 1-3 分钟还可能偏题。**

```
Step 1  意图识别       → 判断属于哪一类能力（文生图 / 图像编辑 / 多轮对话）
Step 2  信息检查       → 对照"三、必要信息检查清单"找出缺失项
Step 3  主动澄清       → 一次性把所有缺失项（尺寸/用途/风格/文字/参考图/质量...）问清楚
Step 4  Prompt 扩写 + 用户确认
                       → 按"五、Prompt 扩写模板"把用户语言翻译为模型友好的完整指令
                       → 回显给用户："我将按以下 Prompt 生成：{扩写后prompt}，尺寸 {size}，质量 {quality}，确认请回复"确认"或调整"
Step 5  生图 + 复盘     → 调脚本出图；出图后主动询问"是否满意？需要在哪里继续调整？"
```

### 什么时候可以跳过 Step 2-4

仅在**所有**以下条件都满足时，可以直接跳到 Step 5：

- 用户已明确给出：主题 + 风格 + 尺寸（或明确说"不挑尺寸"）+ 用途
- 或者用户是在**同一会话里的迭代轮次**（比如"上一张再把披风改成蓝色"），此时沿用上轮设定即可，只澄清改动点
- 或者用户明确说"你随意发挥"/"先出一版试试"——此时仍要在 Step 4 回显你打算用的 prompt，用户可中途叫停

**任何一条不满足就必须走完 Step 2-4。**

## 三、能力与选型

| 用户场景 | 脚本 | 推荐模型 | 端点 |
|---|---|---|---|
| 纯文字描述 → 图（无参考图） | `scripts/text2image.py` | `gpt-image-2`（英文）/ `gemini-3-pro-image-preview`（中文多） | `/llmproxy/images/generations` |
| 中文/国风/国潮/王者荣耀同人图 | `scripts/text2image.py` | **`hunyuan-image-v3.0-v1.0.4`** | `/hunyuan/images/generations`（独立端点，脚本自动路由）|
| 有 1-4 张参考图；需要精确像素尺寸（如 2160x3840）；需要 `quality` 控制 | **`scripts/image_edit.py`** | **`gpt-image-2`**（实测 `gemini-*-stb` 也可用，但常规推荐 gpt-image-2） | `/llmproxy/images/edits`（multipart） |
| 多模态对话式生图；需要多轮迭代 | **`scripts/chat_image.py`** | **`gemini-3-pro-image-preview`**（gpt-image 在此端点被 Azure 拒） | `/llmproxy/chat/completions` |
| 查询当前 key 实际可用的模型 | `scripts/list_models.py` | — | 探测式（支持 `--json` 输出机器可读格式） |
| **批量并发生图（一次跑 N 张）** | **`scripts/batch_generate.py --tasks tasks.json`** | 各 task 独立指定 | 自动分发到对应端点 |
| **生图 → PIL 后处理 → 落 game/assets 一站式** | **`scripts/pipeline.py --config pipe.json`** | 各 task 独立 | 自动 |
| **离线后处理（不调 API）** | `scripts/postprocess.py {shrink\|atlas\|crop\|quantize\|remove-bg}` | — | 本地 PIL |
| **查 / 清缓存** | `scripts/_cache.py [clear]` | — | 本地 |

选型速查：
- 需要**精确像素尺寸**或**quality 控制** → `image_edit.py`（唯一支持）
- 有**参考图做风格迁移 / UI 视觉稿** → `image_edit.py` + `gpt-image-2`
- **中文 prompt / 国风内容** → `text2image.py` + `hunyuan-image-v3.0-v1.0.4`（走独立 hunyuan 端点）
- **多轮对话式迭代** → `chat_image.py` + `gemini-3-pro-image-preview`
- 纯文本 prompt 出图 → `text2image.py`（英文用 gpt-image-2，中文通用用 gemini）
- **不知道 key 有哪些权限 / 新模型** → `list_models.py --json`
- **传平台新增的模型参数** → 用 `--param key=value`（三个生图脚本均支持，数字/bool 自动解析）
- **自动 fallback**：`text2image.py` / `image_edit.py` 默认开启（`--fallback auto`），主模型限流时自动切备用模型；对画风一致性敏感的任务用 `--fallback off`
- **要生 ≥ 3 张资产** → 不要 N 次手跑 text2image，**直接 batch_generate**（并发 + 缓存命中跳过 + 失败重试），节省 5-10 分钟空转
- **要生 sprite atlas 接入游戏** → 直接 `pipeline.py`（生图 + atlas 切片 + 降采样 + 落到 game/assets/ 一站式）

> 脚本 stdout 输出 JSON，stderr 输出进度日志，两者完全分离。AI 直接解析 stdout 即可，不受 PowerShell 干扰。

### 三·补 · 批量 / 缓存 / pipeline 详解（工作室新增）

#### 缓存（`_cache.py`）

所有调 API 的脚本（text2image / image_edit / chat_image / batch_generate / pipeline）都通过 `_cache.cache_key(prompt, model, size, quality, extra)` 计算 hash key（16 字符），自动落到 `.codebuddy/skills/timiai-image/.cache/<hash>.png`。

- **同一 prompt 永远不重复生成**：第二次调用 = 0 秒命中
- **断点续传**：batch / pipeline 跑到一半挂掉，重启后已生成的会全部跳过
- **手动清理**：`python scripts/_cache.py clear`，或 `cache_clear()`
- **已加 `.gitignore`**：缓存不进 git

#### 批量（`batch_generate.py`）

输入一份 JSON（`tasks` 数组 + `defaults` 默认值 + `concurrency` 并发数），用 ThreadPoolExecutor 并发跑。每个任务先查 cache，未命中才调 API；失败用 fallback 链 + exponential backoff 重试。

最佳并发：**3**（gpt-image-2 限流容忍度，并发太高会触发 Azure 429）。

#### 一站式 pipeline（`pipeline.py`）

`batch_generate` + `postprocess` 拼起来。每个任务带 `post: [...]` 链式后处理：

```json
{
  "post": [
    {"op": "remove_bg", "threshold": 200},     // 去 checkered 假透明
    {"op": "atlas", "grid": "4x2", "frame": "16x16"},   // N×M 网格切 + 降采样 + 拼 strip
    {"op": "shrink", "size": "32x32"},          // 单图降采样
    {"op": "quantize", "colors": 16},           // palette 量化
    {"op": "crop", "alpha_threshold": 8}        // auto-crop 透明边
  ],
  "final_out": "projects/.../game/assets/foo.png"
}
```

中间产物落到 `stage_dir`（配置中指定，默认 `_pipeline_stage`），方便 debug。

#### 后处理单跑（`postprocess.py`）

模型已经出过图但效果不对，可以单跑后处理：

```bash
python scripts/postprocess.py atlas --src raw.png --out strip.png --grid 4x2 --frame 16x16
python scripts/postprocess.py shrink --src raw.png --out small.png --size 32x32
python scripts/postprocess.py remove-bg --src raw.png --out clean.png
```

#### 工作室常用 pipeline 配置示范

参见 `references/pipeline-bolt-1-1.json`（如果不存在则按需创建）。

#### 异步后台（`daemon.py`）—— 提交后立即返回，agent 干别的事

为什么需要：单张图 60-120s，整批 8-30 分钟，agent 同步等会完全空转。

```bash
# 提交（立即返回 job_id，子进程后台跑）
python scripts/daemon.py submit --tasks tasks.json --kind batch
→ {"job_id": "batch-abc123", "pid": 12345, "state": "running"}

# Agent 去做别的工作 ...
# （改代码 / 写文档 / 跑测试 / spawn 其他 agent）

# 想看进度时 poll status（毫秒返回）
python scripts/daemon.py status batch-abc123
→ {"state": "running" | "done" | "fail",
   "progress": {"ok": 3, "fail": 0, "total": 8},
   "log_tail": [...最近 15 行 stderr...]}

# 完成后取完整报告
python scripts/daemon.py report batch-abc123

# 列出所有历史 job
python scripts/daemon.py list

# 清理已完成的（保留 running）
python scripts/daemon.py clean

# 杀掉跑飞的
python scripts/daemon.py kill <job_id>
```

子进程是真正脱离的（Windows 用 CREATE_NEW_PROCESS_GROUP），父 agent 会话结束也不影响子进程继续跑。

**典型工作流（agent 视角）**：
```
1. 提交 8 张资产的 pipeline 任务 → 拿 job_id
2. 立即转去修 P1 backlog 的代码
3. 5-10 分钟后调 status → 看 ok/fail
4. 大部分 OK + 少数 fail → 单独对 fail 的重跑（cache 命中其余成功的）
```



## 四、必要信息检查清单（Step 2 用）

生图前，对照下面 6 项扫一遍；**任何一项用户没说清楚，都必须在 Step 3 澄清**。

| # | 信息点 | 必问场景 | 没说清楚时的默认判断 |
|---|---|---|---|
| 1 | **用途 / 使用场景** | 任何时候 | 没说就问："这张图要用在哪？（如：游戏启动页 / 买量素材 / PPT 配图 / Banner / 头像 / 壁纸 / 朋友圈分享）"——用途决定尺寸和构图 |
| 2 | **尺寸或比例** | 任何时候 | 用 `image_edit.py` 时**必须**精确像素（2160×3840 / 1080×1920 / 1024×1024…）；`text2image.py` 至少确认 `1:1 / 9:16 / 16:9 / 竖版 / 横版` |
| 3 | **风格 / 画风** | 任何时候 | 问："想要什么风格？（如：写实电影感 / 3D 渲染 / 像素风 / 国风水墨 / 二次元 / 卡通 / 赛博朋克 / 吉卜力 / 参考XX游戏）" |
| 4 | **主体与构图细节** | 描述过于笼统（"一张游戏海报"/"一个英雄"）时 | 问："主角是谁？在做什么？场景在哪里？有哪些元素必须出现？视角/构图（特写/中景/远景/俯视/仰视）？" |
| 5 | **文字 / Logo / 数字** | 图上要出现任何文字时 | **必须**逐字列出："要出现的文字 / 游戏名 / 数字 / UI 标签请完整写给我，包括是否保留原语言"——图像模型对中文/复杂文字易出错，宁可预先限定 |
| 6 | **参考图** | 用户说"像XX游戏那样"/"这种风格"/"帮我把这张改成..." | 问："能给我参考图吗？有的话用 image_edit.py 精准度更高；没有的话我按文字描述出，但风格还原度会弱一些" |

额外可选项（用户没提就按推荐默认，但在 Step 4 要在确认信息里明示）：

| 参数 | 默认建议 | 何时问用户 |
|---|---|---|
| 质量 quality | `image_edit.py` 默认 `high` | 用户明确说"快速出一版" → 降到 `low` |
| 模型 | `image_edit.py` 用 `gpt-image-2`；`chat_image.py` 用 `gemini-3-pro-image-preview`；`text2image.py` 英文 prompt 用 `gpt-image-2`，中文强描述用 `gemini-3-pro-image-preview` | 用户显式指定模型则完全服从 |
| 输出路径 | `./timiai_*_{ts}_d{draw}_{i}.png` | 用户希望放到特定目录时 |
| 张数 n | 1 | 用户说"多出几版对比" → 2-4 |
| **抽卡 draw** | **1（不抽卡）** | **任何单次生图任务**都建议主动问一次："图像生成有随机性，需要开启抽卡模式吗？推荐 3-5 次。开启后默认使用**随机抽卡**（AI 为每次 draw 生成不同 prompt 变体，多样性更大）；如果你已有满意的 prompt 想固定使用，可以选定向抽卡。" |
| **fallback** | **`auto`（默认开启）** | 高品质需求（高质量海报/立绘/客户交付件）建议主动询问："是否允许在主模型限流时自动切到备用模型？开启可大幅提高出图成功率，但备用模型画风可能略有差异。"——若用户对画风一致性敏感 → 加 `--fallback off` |

## 五、主动澄清的提问示范（Step 3 用）

**原则：一次性把所有缺失项合并成一条消息问完，不要挤牙膏式逐条问**（用户会烦）。**每个问题都给 2-4 个"候选选项 + 推荐默认"**，降低用户回答成本。

### 示范 A：用户说"帮我画一张游戏海报"

不要直接跑。回复：

> 我来帮你画。为了出图一次到位，先对齐 4 件事（回答推荐选项的编号或直接说也行）：
>
> 1. **用途**：① 买量素材 ② 游戏启动页 ③ 官网 Key Visual ④ 其他（请说）
> 2. **尺寸/比例**：① 竖版 9:16（手机买量，推荐 1080×1920 或 2160×3840） ② 横版 16:9（PC/官网 banner） ③ 1:1（社交） ④ 其他具体像素
> 3. **主题**：游戏名/类型是什么？主角是谁？场景在哪？核心视觉元素（城堡/军队/魔法/飞龙…）有哪些？
> 4. **风格**：① 电影级写实 3D 渲染 ② 像素风 ③ 国风水墨 ④ 二次元 ⑤ 参考某款游戏（给我名字或参考图更好）
>
> 如果图上要出现文字/Logo，请把**要出现的完整文字**告诉我。

### 示范 B：用户说"把这张交互稿变成视觉稿" + 给了 1 张图

> 收到。基于这张交互稿，还需要确认 3 件事：
>
> 1. **视觉风格**：① 跟随交互稿自身风格只做精修 ② 我有另一张风格参考图（请发给我） ③ 指定风格（写实/像素/国风/二次元…）
> 2. **输出尺寸**（注：gpt-image-2 要求宽高都是 16 倍数）：① 保持和交互稿同比例放大（推荐 **2160×3840** 4K） ② **1088×1920**（相当于 1080×1920 合法版） ③ 其他具体像素
> 3. **文字保留**：交互稿里的文字（标题/标签/数字）是否**一字不改**全部保留？还是我可以按风格重排？
> 4. **抽卡模式（可选）**：图像生成有随机性，同一 prompt 结果会有差异；要不要开启抽卡？（推荐 3-5 次，上限建议 10 次）
>
> 确认后我用 `image_edit.py + gpt-image-2 + quality=high` 出图，单次高质量约 3 分钟。

### 示范 C：用户说"上一张把披风改成蓝色"（迭代轮次）

不需要大篇幅澄清。用 Step 4 的简短回显即可：

> 好的，我基于上一张 `[文件名]`，把披风从红色改成蓝色，其他保持不变，用 chat_image.py 迭代。Prompt: "Change the cape color from red to deep royal blue, keep everything else identical to the previous image." 确认吗？

## 六、Prompt 扩写模板（Step 4 用）

用户给的描述通常是中文口语化的（"做个酷炫的游戏海报"）。**直接把这种话塞给 gpt-image-2/Nano Banana 出图极不稳定**。必须按下面模板把它扩写为结构化、模型友好的 prompt，然后**回显给用户确认后再调脚本**。

### 扩写七要素（缺一不可）

```
[画面主体]    谁/什么 + 数量 + 姿态/动作
[场景/环境]   在哪里 + 光线 + 天气/时段 + 背景元素
[视角/构图]   特写/中景/远景 + 机位高度（平视/俯视/仰视） + 画面重心
[风格]        艺术风格 + 参考（艺术家/游戏/电影名） + 细节程度
[色调]        主色调 + 对比 + 氛围词（温暖/冷峻/史诗/梦幻）
[画质约束]    分辨率/渲染引擎暗示（Unreal Engine / octane render / cinematic / ultra detailed）
[负向约束]    no text / no watermark / no extra limbs / no blurry / 以及要禁止的干扰元素
```

### 语言选择

- **默认英文 prompt**（gpt-image-2 / Nano Banana 对英文语义更稳定）
- **中文仅用于：图上要出现的原文文字**（包在引号里如 `"胜利！"`、`"领主大人用兵如神"`）——让模型明确把这些字**渲染为视觉元素**而非理解成指令
- 用户如果明确要求"全中文 prompt"则尊重用户

### 模板示例

#### 示例 1：游戏买量海报（文生图）

用户说："画一张《重返帝国》的游戏海报，史诗感"

扩写为：

```
Epic medieval fantasy mobile game promotional poster for "Return to Empire" (Chinese SLG).
Subject: a heroic young emperor in ornate golden armor with a flowing crimson cape,
standing on a high castle rampart, sword raised to the sky.
Scene: sunset battlefield, massed knight armies and siege catapults advancing across
rolling green plains toward distant stone fortresses; dragons and banners in dramatic
cloudy sky with golden godrays.
Composition: cinematic wide shot, low-angle heroic framing, subject at golden-ratio right.
Style: photorealistic 3D render, Unreal Engine 5 quality, movie poster composition,
inspired by Game of Thrones / Lord of the Rings key art.
Color: warm amber and deep crimson palette, high contrast, epic atmospheric lighting.
Quality: ultra detailed, 8K, sharp focus, dramatic depth of field.
Negative: no text, no watermark, no modern elements, no extra limbs.
```

#### 示例 2：UI 视觉稿（图像编辑，双参考图）

用户说："把第1张交互稿按第2张的像素风重绘"

扩写为（要精确列出所有要保留的文字 + 明确指出两张图的角色）：

```
You receive TWO reference images.
IMAGE 1 = layout reference: a battle-report "Victory" result screen. Use it ONLY for
information hierarchy, layout, and all text content. Do NOT copy its flat dark UI style.
IMAGE 2 = visual style guide: pixel-art UI. This IS the target art style —
pure pixel art, crisp block edges, thick black outlines, saturated colors,
beige parchment/wood panels, pixelated fonts and icons, chunky shadows.

Task: Redraw IMAGE 1's content in IMAGE 2's pixel-art style.

Preserve ALL text from IMAGE 1 exactly:
"胜利！", "领主大人用兵如神，横扫敌军。", "(245,831)",
"[RST] Peter", "(120,340)", "战力: 25,320", "损失: -2,100",
"1:10+",
"[ABC] Lord_007", "(245,831)", "战力: 18,100", "损失: -16,300",
"12,000 / 部队 / 8,000", "2,100 / 损失 / 6,300", ...
"恭喜您成功击败 Lord_007!",
"x100", "x80", "x2000", "x50",
"删除", "收藏", "分享".

Rewards row: 4 pixel-art item icons (wood logs, stone pile, gold coin stack, money bag)
in wooden frames with quantity badges.

Output: single full-screen 9:16 mobile UI image, 2160×3840, pixel art only,
NO blur, NO 3D, NO realistic rendering, NO watermark.
```

对应脚本调用：

```
python scripts/image_edit.py \
  --prompt "<上面这段>" \
  --image ./原型1.png --image ./SFK.png \
  --size 2160x3840 --quality high \
  --out ./result.png
```

### 回显确认话术（Step 4 结尾必说）

扩写完毕**先不要调脚本**。用下面格式回给用户：

> 我将按以下设置生成，请确认：
>
> - **脚本**：`image_edit.py`（图像编辑，多参考图）
> - **模型**：gpt-image-2
> - **尺寸**：2160×3840（9:16 竖版 4K）
> - **质量**：high（预计耗时 150-200 秒）
> - **参考图**：原型1.png（布局参考）、SFK.png（风格参考）
> - **Prompt**：
>   ```
>   <完整扩写后 prompt>
>   ```
>
> 回复"确认"我就开始生成；要改任何一项直接说（如"改成横版"/"风格换成写实"/"标题字体改大"）。

## 七、生图后的复盘（Step 5 用）

脚本成功出图后，**严格按以下顺序**主动做四件事：

### 1. 逐张独立查看（抽卡模式必须）

⚠️ **关键陷阱**：抽卡产出多张图时，**绝对不要**靠"一次性并行 read 多张图 + 事后凭记忆对应文件名"。这会产生严重的图文错位幻觉（AI 会把某张图的内容错配到另一个文件名上，然后基于错误对应下结论"d1 飘了 d4 也飘了"，误导用户）。

**正确做法**：
- 一次调用只 read 一张图 + 当场在表格里写下该图的**客观描述**（主体/姿态/颜色/背景）和**命中判定**（✅ 切题 / ❌ 飘题）
- 描述写完再 read 下一张，绝不提前下结论
- 所有图都看完后再汇总

**汇总表格模板**：

| 文件名 | 主体 | 姿态/构图 | 背景/色调 | 命中 | 备注 |
|---|---|---|---|---|---|
| `xxx_d1_1.png` | (一句客观描述) | … | … | ✅/❌ | (推荐/备选/建议删) |
| `xxx_d2_1.png` | … | … | … | … | … |
| … | | | | | |

### 2. 展示图片并告知用户

⚠️ **必须做，且顺序固定：**

1. **从 stdout JSON 的 `files` 字段取路径**（不要用 stderr 日志里的路径，日志里可能是旧格式）。
   `files` 里的路径已经是正斜杠 `/`，格式形如 `pic/test/result_d1.png`，直接展示即可在 IDE 点击。

2. **以可点击格式列给用户**：
   ```
   生成完成，共 2 张：
   - pic/test/pixel_cat_20260513_d1_1.png
   - pic/test/pixel_cat_20260513_d2_1.png
   ```
   注意：**必须用正斜杠 `/`**。路径来自 stdout JSON `files` 字段，已经是正确格式，不要替换或修改。

3. **然后用 `read_file` 把每张图展示出来**（如果环境支持图片预览），让用户直接看效果。

4. **明确告诉用户**：总耗时、命中率（✅/❌）、推荐哪几张。如果 stdout JSON 的 `fallbacks` 字段非空，**必须额外告知**："其中 draw X 因主模型限流自动降级到 `[fallback 模型名]` 出图，画风可能略有差异。"

**禁止**：从 stderr 日志里截取路径展示给用户（stderr 里是运行日志，可能包含反斜杠，IDE 无法点击）。

### 3. 主动询问满意度

> 这版效果你觉得怎么样？需要在哪里调整？比如：
> - 构图/角度/机位
> - 风格化程度（更卡通/更写实）
> - 颜色/光线
> - 某个元素替换或移除
> - 文字/数字的位置或字体
> - 尺寸/比例

### 4. 根据反馈走迭代路径

- **小改动**（颜色/局部元素）→ 用 `chat_image.py` 多轮对话，把刚出的最佳那张作为 `--image` 参考传入
- **大改动**（整体风格/构图）→ 回到 Step 4，重新扩写 prompt，调 `image_edit.py` 再跑一版
- **想出多个方案对比** → 用抽卡模式 `--draw 3-5`
- **抽卡命中率低（≤ 50%）** → 在 prompt 里加强负向约束（如 `Only generate a raven. NO humans, NO dogs, NO knights, NO armor.`），然后重抽

## 八、API Key 管理（首次使用）

**key 加载优先级**：环境变量 `TIMIAI_API_KEY` → skill 目录下 `.timiai_key` 文件。

### 首次使用时如果脚本返回 `[NEED_API_KEY]`：

1. 向用户说明："我需要调用天美 AI Hub（api.timiai.woa.com）生图，但没有找到你的 API Key。请把你的 TimiAI 个人 API Key 发给我，我会永久保存到 skill 本地，下次自动使用。Key 获取方法：https://timiai.woa.com 个人 API Key 页面（iWiki 文档 4016366698）"
2. 拿到 key 后，用下面的命令保存（**永久**，下次不用再问）：

```
python "<skill根>/scripts/save_key.py" <用户提供的API_KEY>
```

例如本项目内：

```
python "d:\Files\PeterAI\.codebuddy\skills\timiai-image\scripts\save_key.py" <KEY>
```

3. 保存成功后，**立即重试**原本的生图/编辑调用即可。

### 注意事项

- **绝不**把 api key 写入任何代码文件、提交到 git、或在对话里回显给用户（只在保存成功后告知"key 已保存"即可）。
- 保存位置是 skill 目录下的 `.timiai_key`，建议用户把它加入项目 `.gitignore`（或者不提交 `.codebuddy/skills/timiai-image/.timiai_key`）。
- 如果 key 泄漏或需要更换：直接重新调 `save_key.py` 覆盖即可。
- 测试服 / 正式服的 key **不通用**，此 skill 默认连正式服 `api.timiai.woa.com`。

## 九、脚本调用示例（Step 5 参考）

前置条件：Python 3.8+，已安装 `requests`（没装就 `pip install requests`）。

### 1. 文生图

```
# gpt-image-2（默认，英文 prompt 最稳）
python scripts/text2image.py \
  --prompt "epic medieval fantasy poster, knight raising sword, sunset" \
  --model gpt-image-2 --size 1024x1024 --quality high \
  --out ./out.png

# Nano Banana，出 4K 9:16 竖版（gemini 用 --param 传 aspect_ratio/imageSize）
python scripts/text2image.py \
  --prompt-file ./p.txt \
  --model gemini-3-pro-image-preview \
  --param aspect_ratio=9:16 --param imageSize=4K \
  --out ./out.png

# 混元（走独立端点 /hunyuan/，擅长中文/国风；直接传中文 prompt）
python scripts/text2image.py \
  --prompt "古风仙境，云雾缭绕，玉宇琼楼" \
  --model hunyuan-image-v3.0-v1.0.4 \
  --out ./out.png
```

**结果读取**：脚本 stdout 输出 JSON，stderr 是进度日志。AI 可直接解析 stdout：
```
# stdout: {"success":true,"model":"gpt-image-2","files":["D:\\xxx.png"],"count":1,...}
```

### 2. 图像编辑（推荐用于 UI 视觉稿 / 多参考图风格迁移）

```
python scripts/image_edit.py \
  --prompt-file ./my_prompt.txt \
  --image ./layout.png \
  --image ./style_ref.png \
  --size 2160x3840 \
  --quality high \
  --out ./result_d{draw}.png
```



关键参数：
- `--prompt-file` 读多行/长 prompt（推荐）；也可以用 `--prompt "单行文本"`
- `--image` 可重复最多 **4 次**（OpenAI images/edits 上限）
- `--size` 支持任意像素，**宽高必须都是 16 的倍数**（`1024x1024 / 1088x1920 / 2048x2048 / 2160x3840 / 3840x2160` 等）
- `--quality` 可选 `low | medium | high | auto`（本端点独有）
- 模型默认 `gpt-image-2`，**不要**换成 gemini（Azure 会返回 `unsupported`）

### 3. 多模态聊天式生图 / 多轮迭代

```
# 单轮 + 参考图
python scripts/chat_image.py \
  --prompt "把这只狗变成水彩画风格" \
  --image ./dog.jpg \
  --aspect-ratio 1:1 --image-size 4K \
  --out ./out.png

# 多轮（自动维护历史）
python scripts/chat_image.py \
  --prompts "画一只柴犬" "给它戴上红帽子" "换成樱花树下背景" "水彩画风" \
  --image-size 4K --out-prefix ./round
```

### 4. 抽卡模式（应对生成随机性）

抽卡模式有两种，**随机抽卡是默认模式**：

| 模式 | 参数 | 每次 draw 用的 prompt | 适用场景 |
|---|---|---|---|
| **随机抽卡（默认）** | `--variants-file variants.json` | 每次 draw 用不同变体，多样性最大 | 关键产出（海报/立绘/视觉稿），想看多种诠释 |
| **定向抽卡** | `--prompt / --prompt-file`（不传 variants） | N 次都用同一个 prompt，靠模型随机性取胜 | 已经有满意的 prompt，只想多跑几次挑最稳的一版 |

---

#### 随机抽卡完整流程（AI 执行）

**Step 1：根据用户需求生成 N 个 prompt 变体，写入 JSON 文件**

变体之间要有真实差异（视角/构图/风格侧重/光线/细节描述），而不是只改几个形容词。每个变体都必须满足用户的核心需求，不能跑偏主题。

```python
# AI 生成变体后写入文件（Python 示例）
import json, pathlib
variants = [
    "variant 1: ...",
    "variant 2: ...",
    "variant 3: ...",
]
pathlib.Path("./variants.json").write_text(
    json.dumps(variants, ensure_ascii=False, indent=2), encoding="utf-8"
)
```

**Step 2：调脚本，每次 draw 按序取一个变体**

```bash
# 文生图 随机抽卡 3 次
python scripts/text2image.py \
  --variants-file ./variants.json \
  --model gpt-image-2 --size 1024x1024 --quality high \
  --draw 3 --out ./result_d{draw}.png

# 图像编辑 随机抽卡（变体 prompt 描述不同的风格转换侧重点）
python scripts/image_edit.py \
  --variants-file ./variants.json \
  --image ./ref.png --size 2048x2048 --quality high \
  --draw 3 --out ./result_d{draw}.png
```

**Step 3：读取 stdout JSON，`mode` 字段确认为 `"random"`，`variants` 字段记录每次实际用的 prompt**

```json
{
  "success": true,
  "mode": "random",
  "variants": ["variant 1 used for draw 1", "variant 2 used for draw 2", ...],
  "files": ["result_d1.png", "result_d2.png", "result_d3.png"],
  ...
}
```

---

#### 定向抽卡（用户明确说"用固定 prompt"）

```bash
# 定向抽卡：同一 prompt 跑 5 次，靠模型随机性
python scripts/text2image.py \
  --prompt-file ./my_prompt.txt \
  --draw 5 --out ./result_d{draw}.png
```

stdout JSON 的 `mode` 字段为 `"fixed"`，`variants` 数组里每项都相同。

---

#### 变体生成规范（随机抽卡时 AI 的 prompt 变体写法）

每个变体必须：
1. **保留用户核心需求**（主体、风格类型、用途不变）
2. **至少一处有实质差异**——以下维度任选：
   - **构图/视角**：正面 → 四分之三侧身 → 俯瞰 → 仰望
   - **光线/时段**：日出金光 → 正午强光 → 黄昏暖色 → 月光冷色
   - **细节侧重**：武器特写 → 服装纹理 → 表情情绪 → 环境氛围
   - **风格变体**：写实 → 插画感 → 简约 → 精致细腻
   - **配色调性**：暖色系 → 冷色系 → 高对比 → 柔和低饱和
3. 每个变体单独都是**完整的高质量 prompt**（不能只写差异部分，要写完整）

**变体数量建议**：等于 `--draw` 的值（1 变体 1 次 draw），如果变体不够，脚本会循环复用。

---

关键要点：
- `--draw N`：重复 N 次；**建议 N ≤ 10**
- `--draw-sleep S`：每次请求间隔 S 秒（默认 0，限流时加）
- 文件名 `{draw}` 占位符区分序号（`_d1 _d2 ...`）
- 抽卡全程**无人值守**，结束后打印汇总 + JSON
- `chat_image.py --prompts` 多轮模式下 `--draw` 被忽略（多轮是链式，语义冲突）

### 4.5 自动 fallback（限流自救）

**默认开启**。`text2image.py` / `image_edit.py` 在主模型遇到限流（429）/上游异常时，自动按 `models.json` 中配置的 `fallback` 链顺序切到备用模型重试，对调用方完全透明。

#### 触发条件（命中以下任一即 fallback）

- HTTP 429 / 503 / 500 / 网络超时
- 业务错误 message 含 `RateLimitError` / `quota` / `overloaded` / `AzureException` / `upstream`
- HTTP 200 但 `data` 为空且含上游异常描述

#### 不触发（直接失败更省时间）

- 401 / 403 / `unauthorized`：换模型也救不了
- `invalid_value` / `divisible by 16`：参数错误
- `content_policy` / `moderation`：合规拒绝
- `unsupported`：端点不支持当前模型

#### 控制方式

| 取值 | 行为 |
|---|---|
| `--fallback auto`（**默认**） | 读 `models.json` 里该模型的 `fallback` 链 |
| `--fallback off` | **禁用**。任何错误立即计为失败。**画风敏感场景必选** |
| `--fallback gemini-3-pro-image-preview,gpt-image-1` | 显式覆盖 |

#### fallback 链配置（`scripts/models.json`）

每个模型可声明自己的备胎顺序：

```json
"gpt-image-2": {
  "fallback": ["gemini-3-pro-image-preview", "gpt-image-1"]
}
```

注意：
- `image_edit.py` 仅支持 gpt-image-* 系，脚本会自动**过滤掉非 gpt-image** 的 fallback 项
- `hunyuan-image-v3.0-v1.0.4` 默认 `fallback=[]`（国风调性独特，降级会破坏）

#### stdout JSON 的 fallback 追溯

抽卡 3 次中 2 次主模型限流被救活的真实输出：

```json
{
  "success": true,
  "model": "gpt-image-2",
  "files": ["pic/test/d1_1.png", "pic/test/d2_1.png", "pic/test/d3_1.png"],
  "fallbacks": [
    {
      "draw": 1,
      "primary": "gpt-image-2",
      "actual": "gemini-3-pro-image-preview",
      "attempts": [
        {"model": "gpt-image-2", "ok": false, "error": "RateLimitError 429..."},
        {"model": "gemini-3-pro-image-preview", "ok": true, "error": ""}
      ]
    },
    {
      "draw": 2,
      "primary": "gpt-image-2",
      "actual": "gemini-3-pro-image-preview",
      "attempts": [...]
    }
  ],
  ...
}
```

**生图后 AI 必看 `fallbacks` 字段**：若非空，应在向用户汇报时主动告知"draw X 因主模型限流降级到 [模型名]，画风可能略有差异"，让用户知晓哪些是降级品。

#### AI 决策建议

| 场景 | 推荐配置 |
|---|---|
| 日常出图、快速尝试、抽卡 | `--fallback auto`（默认即可） |
| 客户交付的 KV / 海报 / 立绘 | **询问用户**："要保证画风全部来自主模型吗？" → 是 → `--fallback off` |
| 商务紧急出图（宁要画风差也要出来） | `--fallback auto` |
| `hunyuan` 国风作品 | 保持默认（配置里已 `fallback=[]`） |
| 用户明确指定单一模型 | 询问用户是否需要 fallback；用户没说就保持默认 |



### 5. 列模型可用性 list_models.py（无配额消耗的探测工具）

TimiAI 平台没有暴露标准的 `/v1/models` 接口。本工具通过**发送故意非法的请求**（缺 prompt / `max_tokens=-1`）观察平台返回的错误类型来判定每个模型是否对当前 key 可用。**不会消耗图像生成配额**（都是 400 错误）。

```
# 探测全部已知候选模型（OpenAI / Gemini / FLUX / Midjourney / 混元）在 3 个端点的可用性
python scripts/list_models.py

# 只测含某关键字的模型
python scripts/list_models.py --filter gemini
python scripts/list_models.py --filter gpt

# 只测某个端点
python scripts/list_models.py --endpoint generations
python scripts/list_models.py --endpoint edits
python scripts/list_models.py --endpoint chat

# 探测自定义模型（比如 iWiki 新公告的模型名）
python scripts/list_models.py --models gemini-4-image-preview claude-image-1

# 加大请求间隔避免限流
python scripts/list_models.py --sleep 1.0
```

输出示例（实测）：
```
[ OpenAI 系 ]
  gpt-image-2                ✅ OK         ✅ OK         · WRONG_ENDPOINT
  gpt-image-1                ✅ OK         ✅ OK         · WRONG_ENDPOINT
  dall-e-3                   ❌ NOT_FOUND  ❌ NOT_FOUND  ❌ NOT_FOUND

[ Google Gemini / Nano Banana 系 ]
  gemini-3-pro-image-preview      ✅ OK   ? UNKNOWN  ✅ OK
  gemini-3-pro-image-preview-stb  ✅ OK   ✅ OK      ✅ OK
  ...
```

适用场景：
- **首次拿到新 key** 时跑一次，了解自己有哪些模型权限
- **平台公告新模型上线** 时跑一次确认新模型 ID
- 用户问"能用 X 模型吗"且 X 不在常见列表里 → `--models X` 实测一次比查文档准
- `?` UNKNOWN 是判据未匹配，不代表不可用，需要人工看响应内容做判断

## 十、避坑要点（第一次使用前必读）

1. **Authorization 是裸 key，不加 `Bearer` 前缀**。
2. **gpt-image-\* 不能走 `/chat/completions`**：会返回 `AzureException: The requested operation is unsupported.`，应改用 `/images/edits`（本 skill 的 `image_edit.py` 已做对）。
3. **gemini 系不能走 `/images/edits`**：应用 `/chat/completions`（`chat_image.py` 已做对）。
4. **gpt-image-\* 的 `size` 宽高必须都是 16 的倍数**：否则 Azure 返回 `invalid_value: Width and height must both be divisible by 16.`。合法值如 `1024×1024 / 1088×1088 / 1088×1920 / 1536×1024 / 2048×2048 / 2160×3840 / 3840×2160`；**不合法**的常见错配：`1080×1080`、`1080×1920`（这两个要改成 `1088×1088`/`1088×1920`）。gemini 系走 `aspect_ratio + imageSize` 档位无此问题。脚本已做启动前预警 + 错误提示自动建议对齐值。
5. **超时**：4K 质量 `high` 的图像编辑常需 **150-300 秒**，脚本默认 `timeout=600`，不要调低。
6. **长 prompt 别直接塞命令行**：PowerShell/cmd 的参数解析会把换行和引号拆散（报 `unrecognized arguments`）。所有 >2 行或含引号的 prompt 都应写进文件，然后用 `--prompt-file path.txt`（三个脚本都支持）。
7. **多参考图时，必须在 prompt 里显式命名"Reference 1 / Reference 2"并说明各自角色**（内容参考？风格参考？布局参考？）。否则模型经常把"风格参考图"当成"要复刻的内容"来画，偏题率极高。
8. **stdout/stderr 已分离**（学习 timiai.js 设计）：进度日志走 stderr，最终结果走 stdout（JSON）。AI 解析 stdout 即可，不受 PowerShell CLIXML 污染。仍需看进度时用 `2>&1` 或重定向到文件 `2>log.txt` 后 `type log.txt`。
9. **请求体过大**：给 `/chat/completions` 塞多张 base64 图片时总大小建议 < 4MB；否则给 `chat_image.py` 加 `--use-url-conversion`，脚本会先把图上传到 COS 再用 URL 引用。
10. **抽卡模式（draw）上限**：`--draw` 建议 ≤ 10，超过会大幅消耗 token 配额和时间（N × 单次耗时）。脚本会超限警告但仍会执行。
11. **合规**：不要把机密内部代码/数据送给非自部署模型（海外模型）。用户需遵守 IEG AIGC 合规政策。

## 十一、完整 API 参考

详细字段定义、模型目录、错误码、COS `url_conversion` 流程、iWiki 官方文档 docid 索引见 `references/api.md`。

以下情况读 `references/api.md`：
- 用户要求使用本 SKILL.md 没列出的模型（FLUX.2-pro / Midjourney / 可灵 / 即梦 / Veo / 混元 / MiniMax / Seedance 等）
- 脚本返回了不认识的业务错误码
- 需要使用 `-stb` 稳定版变体或 `-bft` 备用账户变体
- 需要多轮链式生成并主动上传 COS 以控制请求体大小
