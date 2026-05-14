---
name: art-asset-pipeline
description: Art asset production pipeline. Use when user says "出图 / 生成资产 / generate art / sprite / 概念图 / 风格". Calls timiai-image skill for generation, art-director agent for review, manages naming and placement under projects/<name>/assets and projects/<name>/art.
allowed-tools: read_file, write_to_file, list_dir, execute_command
disable: false
---

# art-asset-pipeline · 美术资产生产流水线

## 何时加载

- 项目需要新美术资产（背景 / 角色 / UI / 道具图）
- 用户说"出图 / 生成贴图 / 找参考"
- `dev-story` 中遇到资产缺失

**不加载场景**：纯设计 → `design-review`；调代码 → `dev-story`。

## 输入契约

| 输入 | 来源 | 必需 |
|---|---|---|
| 资产用途（"游戏背景"/"角色立绘"等） | 用户 | ✅ |
| 风格参考（已有 art bible 或参考图） | `projects/<name>/art/` | 推荐 |
| 尺寸要求 | 项目 / 用户 | ✅ |
| 落盘类型（game asset / 参考图） | 用户 | ✅ |

## 流程

### Step 1 · art-director 介入

调用 `art-director` agent (opus)：
- 确认风格（color palette / 画风 / 时代感）
- 是否复用已有资产
- 是否需要 art bible 更新

### Step 2 · prompt 起草

art-director 协助起草英文 prompt（timiai-image 偏好英文）：
- 主体 + 风格 + 色调 + 排除项（no watermark / no text 等）
- 落到 `projects/<name>/art/<slug>-prompt.txt`

### Step 3 · 调用 timiai-image

按 `timiai-image` skill 流程：
- 默认不抽卡（first round）
- 用 `text2image.py`（无参考）或 `image_edit.py`（有参考）
- 模型：gpt-image-2 / 自动 fallback

### Step 4 · 落盘命名

按约定：`<category>_<desc>_<timestamp>.png`

| 用途 | 落盘位置 | 进交付包 |
|---|---|---|
| 游戏运行时资产 | `projects/<name>/game/assets/` | ✅ |
| 概念图 / 参考 | `projects/<name>/art/` | ❌ |
| 推广素材 | `projects/<name>/art/promo/` | ❌ |

### Step 5 · art-director 验收

art-director 按 verdict：
- `APPROVED`：直接接入
- `ITERATE`：再调用 timiai-image 启用抽卡 / 微调 prompt
- `REJECTED`：换思路 / 换风格

### Step 6 · 引擎接入（如游戏资产）

如落到 `game/assets/`：
- 提示用户在 Godot/Unity/Unreal 中导入
- 可选：自动 update 场景文件（仅 godot 简单情况）

### Step 7 · 元信息记录

在 `projects/<name>/art/index.md` 追加一行：
```
- <slug>: <用途> / <尺寸> / <风格> / <date> / <commit>
```

## 输出契约

| 字段 | 内容 |
|---|---|
| `verdict` | `APPROVED` / `ITERATE` / `REJECTED` |
| `asset_path` | 落盘路径 |
| `prompt_path` | art/<slug>-prompt.txt |
| `iterations` | 抽卡 / 重试次数 |

## 调用的 agent / skill

- `art-director` (opus)（风格 + 验收）
- `timiai-image` skill（生成）
- 必要时 `designer` (opus)（如设计意图不清）

## 加载的 rule

- `language-policy`（prompt 英文 / 描述中文）
- `project-structure`（assets/ vs art/ 分流）

## 失败 / 降级

| 异常 | 策略 |
|---|---|
| timiai-image 限流 | 自动 fallback 到备用模型 |
| art-director REJECTED 多次 | 升级 `designer` 或回到 GDD §3 |
| 风格漂移 | art-director 必须同步更新 art bible |

## 验收标准

- 资产落盘 + 命名规范
- art-director APPROVED
- index.md 同步

## Known Limitations

- 资产元信息 JSON schema 未标准化（Phase 2）
- 版本管理（v1/v2/v3 同资产）规则未定
- 项目美术风格库（多张参考打包）引用规范未设计
