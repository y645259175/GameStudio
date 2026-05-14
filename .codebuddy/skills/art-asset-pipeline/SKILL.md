---
name: art-asset-pipeline
description: Art asset production pipeline that calls the workshop-level timiai-image skill for image generation and editing.
allowed-tools:
disable: false
---

# Art-Asset-Pipeline · 美术资产生产管线

## 何时使用

项目需要生成 / 编辑美术资产（角色立绘 / UI 视觉 / 海报 / 概念图 / icon / texture）时调用。本 skill 是 `art-director` agent 的工具入口，最终调用工作室级已接入的 `timiai-image` skill。

典型触发：
- "/art-asset-pipeline"
- "生成英雄立绘"
- "做一张主菜单背景图"
- 由 `art-director` agent 自动调用

## 输入 / 触发条件

- 当前在项目根
- 资产需求（用途 / 尺寸 / 风格 / 数量）
- 可选：参考图（1-4 张）

## 流程步骤

1. **意图识别**：分类资产类型（character / ui / poster / icon / concept / texture）
2. **信息检查 · 主动澄清**（按 `timiai-image` skill 的工作流要求）：
   - 尺寸（如 2160x3840 海报 / 512x512 icon）
   - 用途（落地 UI / 概念探索 / 抽卡）
   - 风格（项目美术风格库引用 / 参考图）
   - 文字（是否含中文 / 英文文字）
   - 是否抽卡（随机 N 个变体 / 定向单图）
3. **Prompt 扩写**：把用户口语化描述扩写为多模态模型友好的结构化 prompt
4. **用户确认**：回显扩写后的 prompt（如抽卡则回显 N 个变体）
5. **调用 timiai-image**：路由到 `.codebuddy/skills/timiai-image/`，参数包括：
   - 文生图 → `text2image.py`
   - 多图编辑 → `image_edit.py`（1-4 张参考）
   - 多轮迭代 → `chat_image.py`
6. **资产落盘**：`projects/<name>/assets/<category>/<filename>.png`
7. **元信息落盘**：`projects/<name>/assets/<category>/<filename>.json`（含 prompt / 模型 / 时间 / 变体编号）
8. **commit 建议**：`[story] art: <category> <topic>` 或 `[quick] art: <category> tweak`

## 输出

- 美术资产文件（PNG / JPG）
- 资产元信息 JSON（用于追溯）
- 终端内 fallback 链记录（如有降级）

## 引用

- 上游规划：v4 §6.1.1（美术资产 1 之一）、§9.1（timiai-image 作为 R4 既存事实豁免）
- 上游 skill：`.codebuddy/skills/timiai-image/`（**已存在的工作室级能力，本规划不重建、不改造**）
- 相关 agent：`art-director`（30 agent 之一，由本 skill 协同）
- 相关 rule：`commit-discipline`（双通道）

## Known Limitations / Phase 2 Review Points

- [Phase 2 TODO] 资产元信息 JSON 格式未标准化，需定 schema
- [Phase 2 TODO] 项目美术风格库（多张参考图打包成一个风格）的引用规范未设计
- [Phase 2 TODO] 美术资产版本管理（同一资产迭代 v1/v2/v3）的命名 / 归档规则未定
