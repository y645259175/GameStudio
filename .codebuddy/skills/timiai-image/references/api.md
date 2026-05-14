# TimiAI 图像 API 详细规范

`api.timiai.woa.com` 上三个图像端点的完整字段、模型目录、错误码与辅助工具。
当 `SKILL.md` 的速查表不够用时（更多模型、冷门错误、更大文件流转）再来读本文件。

## 目录

1. 鉴权与环境
2. 端点 1 — `/images/generations`（文生图）
3. 端点 2 — `/images/edits`（图像编辑，multipart）
4. 端点 3 — `/chat/completions`（多模态聊天式生图）
5. 辅助 — `/file/url_conversion`（把本地图上传到 COS）
6. 模型目录
7. 错误分类与排查
8. 官方 iWiki 文档 docid 索引

---

## 1. 鉴权与环境

| 项 | 值 |
|---|---|
| 正式服 base URL | `http://api.timiai.woa.com` |
| 鉴权头 | `Authorization: <apikey>`（**裸 key，不加 `Bearer`**） |
| Key 申请 | https://timiai.woa.com 个人 API Key 页（iWiki 文档 4016366698） |
| 测试服 vs 正式服 | Key **不通用** |
| 合规 | 受 IEG AIGC 政策约束；涉敏数据不要送海外托管模型 |

Key 加载优先级（本 skill 脚本统一从 `_auth.py` 读取）：
1. 环境变量 `TIMIAI_API_KEY`
2. skill 根目录下 `.timiai_key` 文件（通过 `scripts/save_key.py <KEY>` 写入）

可选环境变量：`TIMIAI_BASE_URL`（覆盖默认地址，很少用）。

---

## 2. 端点 1 — 文生图

```
POST {base}/ai_api_manage/llmproxy/images/generations
Content-Type: application/json
Authorization: <apikey>
```

### 2.1 gpt-image-\* 请求体

```json
{
  "model": "gpt-image-2",
  "prompt": "epic medieval fantasy poster",
  "size": "1024x1024",
  "quality": "high",
  "n": 1
}
```

- `size` 支持：`1024x1024` / `1024x1536` / `1536x1024` / `auto`
- `quality` 支持：`low | medium | high | auto`

### 2.2 Gemini / Nano Banana 请求体

```json
{
  "model": "gemini-3-pro-image-preview",
  "prompt": "一只可爱的海獭宝宝在清澈的水中游泳",
  "aspect_ratio": "16:9",
  "imageSize": "2K",
  "n": 1
}
```

- `aspect_ratio` 支持：`1:1 | 4:3 | 16:9 | 21:9 | 9:16 | 4:5`
- `imageSize` 支持：`1K | 2K | 4K`

### 2.3 响应结构

```json
{
  "created": 1765182120,
  "background": null,
  "data": [
    {
      "b64_json": "iVBORw0KGgo...",
      "revised_prompt": null,
      "url": null
    }
  ],
  "usage": { "total_tokens": 0, "input_tokens": 0, "output_tokens": 0 }
}
```

图像字节在 `data[i].b64_json`（默认 base64 回传，不走 URL）。

---

## 3. 端点 2 — 图像编辑（multipart）

```
POST {base}/ai_api_manage/llmproxy/images/edits
Content-Type: multipart/form-data
Authorization: <apikey>
```

### 3.1 表单字段

| 字段 | 类型 | 说明 |
|---|---|---|
| `model` | string | **必须是 `gpt-image-2` 或 `gpt-image-1`**，gemini 系在此端点会被拒 |
| `prompt` | string | 编辑指令 |
| `image[]` | file | 可重复最多 4 张；部分代理只认重复 `image`（非 `image[]`），`image_edit.py` 有 `--field-name` 开关 |
| `mask` | file（可选） | 局部重绘掩膜（透明区域 = 待替换区） |
| `size` | string | 任意像素：`2160x3840` / `3840x2160` / …，或 `auto`。⚠️ **宽、高都必须是 16 的倍数**（Azure 硬性约束）。合法值示例：`1024 / 1088 / 1536 / 1920 / 2048 / 2160 / 2560 / 3072 / 3840`。不合法：`1080`、`1920×1080`（应改 `1920×1088` 或 `1088×1920`）|
| `quality` | string | `low | medium | high | auto` |
| `n` | int | 默认 1 |

### 3.2 响应

和 `/images/generations` 一样：`data[i].b64_json`。

### 3.3 耗时参考

- `quality=low`：约 20-40 秒
- `quality=medium`：约 60-90 秒
- `quality=high` + 2160×3840：约 150-200 秒；`timeout` ≥ 300

### 3.4 为什么只支持 gpt-image-\*

网关把 gpt-image-\* 代理到 Azure OpenAI。Azure 图像模型**只暴露 `images/edits` 的 multipart 接口**，不接受 `chat.completions` 的多模态消息结构。错配时返回：

```json
{"error": {"message": "API调用失败: litellm.BadRequestError: AzureException - The requested operation is unsupported.", "code": 304}}
```

---

## 4. 端点 3 — 多模态聊天式生图

```
POST {base}/ai_api_manage/llmproxy/chat/completions
Content-Type: application/json
Authorization: <apikey>
```

### 4.1 Preview 变体请求体（默认）

```json
{
  "model": "gemini-3-pro-image-preview",
  "messages": [{
    "role": "user",
    "content": [
      {"type": "text", "text": "将第一张图的风格应用到第二张图上"},
      {"type": "image_url", "image_url": {"url": "https://example.com/style.jpg"}},
      {"type": "image_url", "image_url": {"url": "data:image/png;base64,iVBORw..."}}
    ]
  }],
  "image_config": {"aspect_ratio": "16:9", "image_size": "4K"},
  "response_modalities": ["IMAGE", "TEXT"]
}
```

### 4.2 稳定版变体（-stb 后缀）

```json
{
  "model": "gemini-3-pro-image-preview-stb",
  "messages": [...],
  "generation_config": {
    "imageConfig": {
      "aspectRatio": "1:1",
      "imageSize": "1K",
      "imageOutputOptions": {"mimeType": "image/png"}
    }
  },
  "response_modalities": ["IMAGE"]
}
```

**唯一区别**：图像配置从 `image_config`（下划线命名）移到 `generation_config.imageConfig`（嵌套驼峰）。`chat_image.py` 已自动判断。

### 4.3 图像输入形式

- URL 形式（推荐，节省请求体）：`{"url": "https://..."}` —— 外网 HTTPS URL，或 `url_conversion` 返回的 COS 预签名 URL
- Base64 形式（单张 ≤ 1 MB，总请求体控制在几 MB 内）：`{"url": "data:image/png;base64,..."}`

### 4.4 响应结构

```json
{
  "id": "...",
  "choices": [{
    "message": {
      "images": [
        {"image_url": {"url": "data:image/png;base64,..."}}
      ],
      "content": "根据您的要求，我为图中的动物添加了一顶帽子"
    }
  }],
  "usage": {
    "total_tokens": 1851,
    "completion_tokens_details": {"image_tokens": 1120}
  }
}
```

- 图像字节：`choices[0].message.images[0].image_url.url`（去掉 `data:image/png;base64,` 前缀后 base64 解码）
- 文字回复：`choices[0].message.content`

### 4.5 多轮迭代模式

流程：
1. 第 N 轮 user 消息 → 请求 → 保存输出 → 把输出上传 COS（`url_conversion`）换成 URL
2. 历史 push 两条：`{role:"user", content:[...]}` 和 `{role:"assistant", content:[{type:"text",text:reply},{type:"image_url",image_url:{url:cos_url}}]}`
3. 第 N+1 轮发送 `历史 + 新 user 消息`

`chat_image.py --prompts` 已自动实现这套链路。

---

## 5. 辅助端点 — `/file/url_conversion`

把 base64 图上传到 TimiAI 托管的对象存储（gemini 模型走 Google GCS external bucket，其他走内部 COS），返回可用于 `image_url` 字段的预签名 URL。

```
POST {base}/ai_api_manage/file/url_conversion
Content-Type: application/json
Authorization: <apikey>

{
  "file_base64": "iVBORw0KGgo...",
  "file_type": ".png",
  "model": "gemini-3-pro-image-preview"
}
```

响应：

```json
{
  "cos_file_path": "dev/api_temp/20260425/xxx.png",
  "presigned_url": "https://storage.googleapis.com/...",
  "model": "gemini-3-pro-image-preview",
  "file_type": ".png",
  "storage_type": "external"
}
```

URL 默认 TTL ≈ 1 小时。

适用场景：
- 请求体（含 base64 图片）即将超过 ~4 MB
- 多轮链式生图（避免 base64 累积）
- 同一张输入图要在多次请求间复用

---

## 6. 模型目录

### 6.1 OpenAI 系（仅走 `/images/generations` 和 `/images/edits`）

| 模型 id | 支持端点 | 说明 |
|---|---|---|
| `gpt-image-2` | generations / **edits** | 最佳：精确 UI 改造、精确像素、多参考图 |
| `gpt-image-1` | generations / edits | 老版本；gpt-image-2 不可用时可 fallback |
| `dall-e-3` | generations | 只文生图 |

### 6.2 Google Gemini / Nano Banana 系（仅走 `/chat/completions`）

| 模型 id | 说明 |
|---|---|
| `gemini-3-pro-image-preview` | Nano Banana preview，chat 生图默认 |
| `gemini-3-pro-image-preview-bft` | 备用 Google 账号（会被 Google 审计日志，敏感数据避免） |
| `gemini-3-pro-image-preview-stb` | 稳定版；配置字段走 `generation_config.imageConfig` |
| `gemini-3.1-flash-image-preview` | Nano Banana 2（Flash 变体） |
| `gemini-3.1-flash-image-preview-bft` / `-stb` | 同上变体 |

### 6.3 其他图像类模型（备案登记，本 skill 暂未封装独立脚本）

下面这些模型 TimiAI 网关都支持，但因为各自的请求体 schema 与本 skill 的三个核心脚本不兼容，没有独立封装。如需使用，参考对应 iWiki 文档自行实装；要纳入 skill 时建议新增 `scripts/<vendor>_*.py` 而不是塞进现有脚本。

| 模型 | 类型 | 与 skill 现有脚本的差异 | 启用路径 | iWiki docid |
|---|---|---|---|---|
| **FLUX.2-pro** / `flux.2-pro` / `FLUX.2-pro` | 文生图 | 实测可走 `/images/generations` 端点（litellm 网关已适配 OpenAI schema），可以**直接用** `text2image.py --model flux.2-pro` 试，无需新脚本。但其原生 API 字段（`raw / aspect_ratio / prompt_upsampling`）走的不是这条路 | 优先：直接 `text2image.py`；如需原生字段 → 自写 | 4018899128 |
| **Midjourney** | 文生图 | **异步任务制**：先 POST `/imagine` 拿 task_id → 轮询 `/task/{id}` 拿结果。schema 完全不同，不能塞进现有同步脚本 | 必须新写 `scripts/mj.py`，含轮询逻辑 | 4016942330 |
| **混元 hunyuan-image** | 文生图 | OpenAI 兼容 schema 但字段名差异（`Prompt` 大写、`Style` 等） | 当前 key 没权限 → 需先找应用组管理员加白；之后可尝试 `text2image.py --model hunyuan-image` | 4017283378 |
| **DALL-E 3 / DALL-E 2** | 文生图 | 标准 OpenAI 协议，`text2image.py` 直接支持 | 当前 key 没权限 → 需先找应用组管理员加白 | — |

未封装但**仍可通过 `list_models.py` 探测可用性**——它会扫描这些模型名并标记 ✅/❌。如果发现某个候选模型当前 key 显示 ✅，可以先尝试用最相近的现有脚本（如 `text2image.py --model X`），不行再决定是否值得为它新写脚本。

### 6.4 视频类模型（不在本 skill 范围）

可灵 (Kling) / Vidu / Google veo-3.1 / MiniMax / 即梦 / Seedance 2.0 / 混元视频 等都可通过同一个 key 调用，但属于"视频生成"能力，应另起 `timiai-video` skill，复用本 skill 的 `_auth.py` 鉴权模块即可。

| 模型 | iWiki docid |
|---|---|
| 可灵 (Kling) | 4017181066 |
| Vidu | 4017182332 |
| Google veo-3.1 | 4017706469 |
| MiniMax | 4017949349 |
| 即梦 | 4019522385 |
| Seedance 2.0 | 4019549714 |

---

## 7. 错误分类与排查

| 状态码 / 业务码 | 报错信息 | 处理 |
|---|---|---|
| HTTP 401 | 鉴权失败 | 检查 `TIMIAI_API_KEY` 是否正确、是否有该模型权限，找应用组管理员开通 |
| HTTP 200 + `error.code=304` + `AzureException: The requested operation is unsupported.` | 把 gpt-image-\* 送去 `/chat/completions` 了 | 改走 `/images/edits`（multipart） |
| HTTP 200 + `error.code=304` + `Invalid size 'WxH'. Width and height must both be divisible by 16.` | gpt-image-\* 的 `size` 宽或高不是 16 的倍数 | 改成 16 整除的尺寸：`1024x1024 / 1088x1088 / 1088x1920 / 1536x1024 / 2048x2048 / 2160x3840 / 3840x2160` 等。脚本已在启动前预警 + 错误响应自动建议对齐值 |
| HTTP 400 缺 `model` / `prompt` | 字段缺失 | 检查请求 schema |
| HTTP 400（`/images/edits`）且字段名是 `image[]` | 某些代理版本不接受数组字段名 | 改用 `--field-name image` |
| HTTP 400 / argparse `unrecognized arguments` | 长 prompt 直接塞命令行时被 shell 空格/换行切碎 | 改用 `--prompt-file path.txt` 从文件读取 |
| HTTP 413 | 请求体过大 | 先用 `/file/url_conversion` 上传，换 URL 传 |
| HTTP 429 | 限流 | 退避重试，降低并发；抽卡时用 `--draw-sleep` 加间隔 |
| 网络超时 | 模型慢（4K high 常见） | `timeout` 提到 600 |
| `CUSTOMIZATION` 业务码 | key 没有该模型权限 | 找应用组管理员加白 |

---

## 8. 官方 iWiki 文档 docid（配合 iwiki-doc MCP 深挖）

根空间：`timiai`（https://iwiki.woa.com/space/timiai）

| docid | 标题 |
|---|---|
| 4016128648 | 空间根 |
| 4016346288 | 「2. 模型 API 调用」主索引 |
| 4016729761 | 模型 API 调用环境（base URL、合规、鉴权） |
| 4016366698 | 用户个人 API Key（获取方式） |
| 4016989125 | COS 对象存储 API 接入文档 |
| 4018251456 | AIGC 索引（Nano Banana / MJ / 可灵 / FLUX / 混元 / veo / MiniMax / 即梦 / Seedance） |
| 4016800856 | **Nano Banana（gemini-3-pro-image-preview）API** —— `/images/generations` 与 `/chat/completions` 的权威 schema 来源 |
| 4018899128 | Black Forest Labs FLUX.2-pro API |
| 4016942330 | Midjourney API |
| 4017154397 | 「7. 非 TiMi AI Hub 平台或应用使用 API」（Cherry Studio / Codex / OpenClaw / Workbuddy 接入指南） |
| 4019991710 | 错误诊断知识库 |
| 4018779962 | TiMi AI 接入常见问题 FAQ |

> 备注：`/images/edits` 在 iWiki 上尚无独立文档，本文的 schema 是通过观察 TimiAI Web 后台「图像编辑」面板（其走标准 OpenAI multipart `images/edits`）并实测得出。若之后官方发布了独立文档，以官方为准。
