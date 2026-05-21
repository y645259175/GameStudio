# timiai-image · PLAYBOOK

<!-- OVER_LIMIT_REASON: 本文是 timiai-image 的完整 SOP（5 步工作流 / 选型表 / Prompt 七要素 / 复盘）。
agent 在做生图任务时通常需要一次性串读 §1→§4，拆分会让单次任务跨多文件查阅成本更高。
ARCHIVE 已剥离完整 API 参考 + batch/cache/daemon 详解，PLAYBOOK 专注"用 skill 完成生图任务"路径。 -->

> CORE 见 `SKILL.md`。本文是详细 SOP。完整 API 参考 / 进阶能力（daemon / batch / cache）见 `ARCHIVE.md`。

## §1 五步工作流详细

```
Step 1  意图识别       → 文生图 / 图像编辑 / 多轮对话
Step 2  信息检查 6 项   → 用途/尺寸/风格/主体/文字/参考图
Step 3  主动澄清       → 一次性合并问完，给候选选项
Step 4  Prompt 扩写七要素 + 用户确认（必须回显）
Step 5  生图 + 复盘     → 调脚本 → 主动询问"是否满意？"
```

### 跳过 Step 2-4 的条件（仅同时满足才允许）

- 用户已明确给出：主题 + 风格 + 尺寸 + 用途
- 或同会话迭代轮次（"上一张把披风改成蓝色"）
- 或用户明确说"你随意发挥"——但 Step 4 仍要回显 prompt 让用户能叫停

### 信息检查清单 6 项（Step 2）

| # | 信息点 | 默认判断 |
|---|---|---|
| 1 | **用途/使用场景** | 必问"用在哪？" |
| 2 | **尺寸/比例** | image_edit.py 必须精确像素；text2image.py 至少 1:1/9:16/16:9 |
| 3 | **风格/画风** | 必问（写实/像素风/国风/二次元/参考某游戏…） |
| 4 | **主体与构图** | 笼统时必问（主角是谁/做什么/场景/视角） |
| 5 | **文字/Logo/数字** | 图上要出现文字必须逐字列出 |
| 6 | **参考图** | "像XX那样"必问（有则 image_edit.py 精准度高） |

### 主动澄清范例（Step 3）

**原则**：一次合并问完，每问给 2-4 候选 + 推荐默认。

> 我来帮你画。为了一次到位，先对齐 4 件事（回答推荐编号或直接说也行）：
> 1. 用途：① 买量素材 ② 启动页 ③ 官网 KV ④ 其他
> 2. 尺寸/比例：① 9:16（手机买量，推荐 1080×1920 或 2160×3840） ② 16:9 ③ 1:1 ④ 其他
> 3. 主题：游戏名/类型/主角/场景/核心元素？
> 4. 风格：① 电影写实 ② 像素 ③ 国风 ④ 二次元 ⑤ 参考某游戏
>
> 图上要文字/Logo？请把完整文字告诉我。

迭代轮次只需简短回显（不需要长澄清）：
> 好的，基于上一张 [文件名]，把披风从红改成蓝，其他不变，用 chat_image.py 迭代。
> Prompt: "Change the cape color from red to deep royal blue, keep everything else identical."
> 确认吗？

## §2 脚本调用 / 选型

### 选型表

| 场景 | 脚本 | 推荐模型 | 端点 |
|---|---|---|---|
| 纯文字 → 图（无参考图）| `text2image.py` | `gpt-image-2`（英文）/ `gemini-3-pro-image-preview`（中文）| `/llmproxy/images/generations` |
| 中文/国风/国潮 | `text2image.py` | **`hunyuan-image-v3.0-v1.0.4`** | `/hunyuan/images/generations`（独立端点）|
| 1-4 张参考图 / 精确像素尺寸 / quality 控制 | `image_edit.py` | **`gpt-image-2`** | `/llmproxy/images/edits` (multipart) |
| 多模态对话式生图 / 多轮迭代 | `chat_image.py` | **`gemini-3-pro-image-preview`** | `/llmproxy/chat/completions` |
| 查询当前 key 可用模型 | `list_models.py` | — | 探测式（`--json` 机器可读）|
| 批量并发（多张）| `batch_generate.py --tasks tasks.json` | 各 task 指定 | 自动分发 |
| 生图 + 后处理 + 落 game/assets/ 一站式 | `pipeline.py --config pipe.json` | 各 task 指定 | 自动 |
| 离线后处理（不调 API）| `postprocess.py {shrink|atlas|crop|quantize|remove-bg}` | — | 本地 PIL |
| 查 / 清缓存 | `_cache.py [clear]` | — | 本地 |

### 选型速查

- 精确像素 / quality 控制 → `image_edit.py`（唯一支持）
- 参考图风格迁移 / UI 视觉稿 → `image_edit.py` + `gpt-image-2`
- 中文 prompt / 国风 → `text2image.py` + `hunyuan-image-v3.0-v1.0.4`
- 多轮对话迭代 → `chat_image.py` + `gemini-3-pro-image-preview`
- 不知道权限 / 新模型 → `list_models.py --json`
- 自动 fallback：text2image / image_edit 默认 `--fallback auto`，画风一致性敏感用 `--fallback off`
- ≥3 张资产 → 直接 `batch_generate`（并发 + cache + retry）
- 资产入游戏 → `pipeline.py`（生图 + atlas + 降采样 + 落盘一站式）

### 1. 文生图

```bash
python scripts/text2image.py --prompt "..." --model gpt-image-2 --size 1024x1024 --out result.png
```

### 2. 图像编辑（推荐 UI 视觉稿 / 多参考图）

```bash
python scripts/image_edit.py --prompt "..." --image ref1.png --image ref2.png \
  --size 2160x3840 --quality high --out result.png
```

### 3. 多模态聊天式 / 多轮迭代

```bash
python scripts/chat_image.py --prompt "..." --image prev.png --model gemini-3-pro-image-preview --out result.png
```

### 4. 抽卡（应对生成随机性）

```bash
python scripts/text2image.py --prompt "..." --draw 5 --random-prompt-variation
```

- 默认 `--draw 1`（不抽卡）
- 任何单次生图任务建议主动问："要开抽卡吗？推荐 3-5 次，默认随机抽卡（每次 prompt 变体）"
- prompt 想固定用定向抽卡：`--no-random-prompt-variation`

### 4.5 自动 fallback

主模型限流时自动切备用模型链：
```bash
python scripts/text2image.py --prompt "..." --fallback auto   # 默认
python scripts/text2image.py --prompt "..." --fallback off    # 画风敏感时关
```

stdout JSON 含 `fallbacks` 字段，复盘时如非空必须告知用户："其中 draw X 因主模型限流降级到 [模型名]，画风可能略有差异。"

### 5. 列模型可用性

```bash
python scripts/list_models.py --json   # 机器可读
```

## §3 Prompt 扩写七要素（Step 4）

```
[画面主体]    谁/什么 + 数量 + 姿态/动作
[场景/环境]   在哪里 + 光线 + 天气/时段 + 背景元素
[视角/构图]   特写/中景/远景 + 机位高度 + 画面重心
[风格]        艺术风格 + 参考（艺术家/游戏/电影名） + 细节程度
[色调]        主色调 + 对比 + 氛围词（温暖/冷峻/史诗/梦幻）
[画质约束]    分辨率 / 渲染引擎暗示（Unreal Engine / octane / cinematic / ultra detailed）
[负向约束]    no text / no watermark / no extra limbs / no blurry / 禁止干扰元素
```

### 语言选择

- **默认英文 prompt**（gpt-image-2 / Nano Banana 对英文语义更稳定）
- **中文仅用于：图上要出现的原文文字**（包在引号里如 `"胜利！"`），让模型把字渲染为视觉元素
- 用户明确要求"全中文 prompt"则尊重

### 回显话术（Step 4 结尾必说）

> 我将按以下设置生成，请确认：
> - 脚本：`image_edit.py`
> - 模型：gpt-image-2
> - 尺寸：2160×3840（9:16 4K）
> - 质量：high（预计 150-200 秒）
> - 参考图：原型1.png（布局）、SFK.png（风格）
> - Prompt：
>   ```
>   <完整扩写后 prompt>
>   ```
>
> 回复"确认"即开始；要改任何一项直接说。

## §4 复盘（Step 5）

### 1. 逐张独立查看（抽卡模式必须）

⚠️ **关键陷阱**：抽卡产出多张图时**绝对不要**靠"一次性并行 read 多张图 + 事后凭记忆对应文件名"——会产生严重图文错位幻觉。

**正确做法**：
- 一次调用只 read 一张图 + 当场写下客观描述（主体/姿态/颜色/背景）+ 命中判定（✅/❌）
- 描述写完再 read 下一张
- 全部看完后再汇总

**汇总表格**：

| 文件名 | 主体 | 姿态/构图 | 背景/色调 | 命中 | 备注 |
|---|---|---|---|---|---|
| `xxx_d1_1.png` | (一句客观描述) | … | … | ✅/❌ | (推荐/备选/建议删) |

### 2. 展示图片（顺序固定）

1. **从 stdout JSON 的 `files` 字段取路径**（不要用 stderr 日志）。`files` 已是正斜杠 `/`
2. **以可点击格式列给用户**（必须正斜杠）
3. **用 `read_file` 把每张图展示出来**
4. **告知**：总耗时 / 命中率 / 推荐哪张。如 `fallbacks` 非空必须额外说明

**禁止**：从 stderr 日志截路径展示用户（含反斜杠 IDE 无法点击）。

### 3. 主动询问满意度

> 这版你觉得怎么样？需要调整哪里？比如：
> - 构图/角度/机位
> - 风格化程度
> - 颜色/光线
> - 元素替换或移除
> - 文字/数字位置或字体
> - 尺寸/比例

### 4. 根据反馈走迭代路径

- **小改动**（颜色/局部）→ `chat_image.py` 多轮，把刚出最佳作为 `--image`
- **大改动**（整体风格/构图）→ 回 Step 4 重新扩写，调 `image_edit.py`
- **多方案对比** → 抽卡 `--draw 3-5`
- **抽卡命中率低 ≤ 50%** → 加强负向约束（`Only ... NO ...`）后重抽

## §5 工作室 fallback 路径（key 真没有时）

如果 `_check_key.py` 输出 `NEED_API_KEY` **且**用户当场提供不了 key：

1. **首选**：暂停资产相关 story，转去做其他工作（不要硬上 image_gen 生质量糟糕的资产）
2. **次选（仅紧急）**：使用 IDE `image_gen` 工具，但**必须**：
   - commit message 标 `[VISUAL_DEBT downgrade]`
   - 在 `projects/<name>/stories/backlog.md` 开 VISUAL_DEBT 条目，注明"等待 timiai key 重做"
   - 资产入库前**强制 spawn art-director** 走 in-context 渲染评审
   - 不允许 main agent 自己说"看上去合理"就过

### Key 管理（首次使用）

加载优先级：环境变量 `TIMIAI_API_KEY` → `.codebuddy/skills/timiai-image/.timiai_key`。

`[NEED_API_KEY]` 时的处理：
1. 向用户说明用途 + 索取 key
2. `python <skill>/scripts/save_key.py <KEY>` 保存
3. 立即重试

**注意**：
- 绝不把 api key 写入代码文件 / 提交 git / 在对话回显
- 保存位置 `.codebuddy/skills/timiai-image/.timiai_key`，已在 .gitignore
- 测试服 / 正式服 key 不通用（默认连正式服 `api.timiai.woa.com`）

## §6 避坑要点（第一次使用前必读）

- 模型对模糊输入出图极不稳定，白烧 1-3 分钟还偏题——必须 Step 2-4 走完
- gpt-image-2 尺寸要求宽高都是 16 倍数（2160×3840 ✓ / 1080×1920 ✗ → 1088×1920）
- 中文文字渲染易错，必须逐字列出
- 多帧动画必须 key sprite 先人审，禁止 key 没确认就批量派生（AP-03）
- pipeline 后处理顺序：remove_bg → crop → atlas → shrink → quantize（顺序不对 alpha 会丢）
- 缓存 hash 包含 prompt+model+size+quality+extra → 改任一个都触发新生成
- batch_generate 最佳并发 = 3（gpt-image-2 限流容忍度）
