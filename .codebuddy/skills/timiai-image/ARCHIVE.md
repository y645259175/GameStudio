# timiai-image · ARCHIVE

> 完整 API 参考 + 进阶能力 + 历史教训。仅 RCA / 调试新模型 / 排查 daemon 问题时查。

## §A1 · API 端点参考

调用腾讯天美 AI Hub（`api.timiai.woa.com`），统一 `Authorization: <apikey>` 鉴权。

| 端点 | 用途 | 脚本 |
|---|---|---|
| `/llmproxy/images/generations` | 文生图 | `text2image.py` |
| `/hunyuan/images/generations` | 国风文生图（hunyuan 独立端点）| `text2image.py`（自动路由）|
| `/llmproxy/images/edits` | 多参考图编辑（multipart） | `image_edit.py` |
| `/llmproxy/chat/completions` | 多模态对话式 | `chat_image.py` |

> stdout 输出 JSON，stderr 输出进度日志，完全分离。AI 直接解析 stdout 不受 PowerShell 干扰。

### 平台新增模型参数

三个生图脚本均支持 `--param key=value`，数字 / bool 自动解析。

## §A2 · 缓存机制（`_cache.py`）

所有调 API 脚本通过 `_cache.cache_key(prompt, model, size, quality, extra)` 计算 hash key（16 字符），自动落到 `.codebuddy/skills/timiai-image/.cache/<hash>.png`。

- 同一 prompt 永不重复生成（第二次 0 秒命中）
- 断点续传：batch / pipeline 跑到一半挂掉，重启后已生成的全部跳过
- 手动清理：`python scripts/_cache.py clear`，或 `cache_clear()`
- 已加 `.gitignore`

## §A3 · 批量（`batch_generate.py`）

输入 JSON（`tasks` 数组 + `defaults` + `concurrency`），ThreadPoolExecutor 并发跑。每 task 先查 cache，未命中才调 API；失败用 fallback 链 + exponential backoff 重试。

**最佳并发：3**（gpt-image-2 限流容忍度，更高触发 Azure 429）。

## §A4 · 一站式 pipeline（`pipeline.py`）

`batch_generate` + `postprocess` 拼起来。每个任务带 `post: [...]` 链式后处理：

```json
{
  "post": [
    {"op": "remove_bg", "threshold": 200},
    {"op": "atlas", "grid": "4x2", "frame": "16x16"},
    {"op": "shrink", "size": "32x32"},
    {"op": "quantize", "colors": 16},
    {"op": "crop", "alpha_threshold": 8}
  ],
  "final_out": "projects/.../game/assets/foo.png"
}
```

中间产物落到 `stage_dir`（默认 `_pipeline_stage`），便于 debug。

### 后处理单跑

```bash
python scripts/postprocess.py atlas --src raw.png --out strip.png --grid 4x2 --frame 16x16
python scripts/postprocess.py shrink --src raw.png --out small.png --size 32x32
python scripts/postprocess.py remove-bg --src raw.png --out clean.png
```

## §A5 · 异步后台（`daemon.py`）

单张图 60-120s，整批 8-30 分钟，agent 同步等会完全空转。daemon 提交后立即返回 job_id，子进程后台跑。

```bash
# 提交（立即返回）
python scripts/daemon.py submit --tasks tasks.json --kind batch
→ {"job_id": "batch-abc123", "pid": 12345, "state": "running"}

# poll status（毫秒返回）
python scripts/daemon.py status batch-abc123
→ {"state": "running|done|fail", "progress": {"ok":3,"fail":0,"total":8}, "log_tail":[...]}

# 完整报告
python scripts/daemon.py report batch-abc123

# 历史 / 清理 / 杀掉
python scripts/daemon.py list
python scripts/daemon.py clean
python scripts/daemon.py kill <job_id>
```

子进程是真正脱离的（Windows 用 CREATE_NEW_PROCESS_GROUP），父 agent 会话结束不影响子进程。

**典型工作流（agent 视角）**：
1. 提交 8 张资产 pipeline → 拿 job_id
2. 立即转去修 P1 backlog 代码
3. 5-10 分钟后 poll status
4. 大部分 OK + 少数 fail → 单独对 fail 重跑（cache 命中其余成功的）

## §A6 · 工作室集成约定

被以下组件引用：
- `art-asset-pipeline` skill → 调本 skill 生成/编辑美术资产
- `art-director` agent → 通过本 skill 审核和迭代视觉风格
- `designer` agent → 概念图 / 参考图生成
- 任何需要图像输出的 agent 均可通过 `art-asset-pipeline` 间接调用

### 资产落盘约定

- 游戏内资产 → `projects/<name>/game/assets/`（进交付包）
- 参考图 / 概念图 → `projects/<name>/art/`（不进交付包）
- 输出文件名：`<category>_<desc>_<timestamp>.png`

## §A7 · Prompt 扩写完整示例

### 示例 1：游戏买量海报（文生图）

用户："画一张《重返帝国》的游戏海报，史诗感"

扩写：
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

### 示例 2：UI 视觉稿（图像编辑，双参考图）

用户："把第1张交互稿按第2张的像素风重绘"

扩写（要精确列出所有保留文字 + 明确两张图的角色）：
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
...

Output: single full-screen 9:16 mobile UI image, 2160×3840, pixel art only,
NO blur, NO 3D, NO realistic rendering, NO watermark.
```

对应调用：
```bash
python scripts/image_edit.py \
  --prompt "<上面这段>" \
  --image ./原型1.png --image ./SFK.png \
  --size 2160x3840 --quality high \
  --out ./result.png
```

## §A8 · 演化历史

- v1.0：仅 text2image / image_edit / chat_image 三脚本
- v1.5：加 `_check_key.py` + 工作室 fallback 路径（platformer-2 资产事故触发，2026-05-19）
- v2.0：加 batch_generate / pipeline / daemon / cache（2026-05-18 combo-A）
- v3.0：加 hunyuan 独立端点路由 + automatic fallback chain（限流自救）
- 2026-05-20 渐进披露重构：拆 CORE / PLAYBOOK / ARCHIVE
