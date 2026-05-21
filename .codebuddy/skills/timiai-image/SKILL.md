---
name: timiai-image
description: Studio image generation & editing via TimiAI Hub. Use when any agent or user needs to generate, edit, or iterate on images - game assets, concept art, UI, promotional materials, style transfer, or multi-round visual refinement. Called by art-asset-pipeline skill and art-director agent.
allowed-tools:
disable: false
---

<!-- OVER_LIMIT_REASON: 本 skill 是首选资产生成入口，必须强提醒"先跑 _check_key.py 自检"+
列出 5 个核心脚本入口（text2image/image_edit/chat_image/pipeline/list_models）+ 触发条件 + 五步工作流概要。
任一项缺失会触发 AP-10 自嗨循环（platformer-2 事故）或 AP-03 一致性失败。
PLAYBOOK 已剥离详细 SOP / Prompt 七要素 / 复盘流程；ARCHIVE 剥离完整 API + daemon。 -->

# timiai-image · CORE

## 零、首次使用前必做（强制自检）

```bash
python .codebuddy/skills/timiai-image/scripts/_check_key.py
```

输出 `OK` = key 就绪可直接生图；输出 `NEED_API_KEY` = 才向用户索取。

**绝对禁止**：看到 `.gitignore` 排除 `.timiai_key` 就假设文件不存在；不调 `_check_key.py` 就降级到 `image_gen` 工具。

## 主动触发条件

- 用户说"画/生成/制作 + 图片/视觉稿/海报/icon/插画/UI"
- art-asset-pipeline / art-director 需要新资产或迭代

## 标准工作流（五步）

1. **意图识别** — 单图 / 多帧 / 多变体 / 一致性派生
2. **信息检查 6 项** — 用途 / 尺寸 / 风格 / 主体 / 文字 / 参考图
3. **主动澄清** — 缺信息合并问完，给候选选项
4. **Prompt 扩写七要素 + 用户确认**
5. **调脚本生图**（路由 text2image / image_edit / chat_image）+ 后处理 + 落盘

多帧动画必须先出 key sprite → 用户评审 → image_edit 派生（AP-03）。

## 入口脚本

```bash
python .codebuddy/skills/timiai-image/scripts/text2image.py    # 文生图
python .codebuddy/skills/timiai-image/scripts/image_edit.py    # 多参考图编辑
python .codebuddy/skills/timiai-image/scripts/chat_image.py    # 多轮迭代
python .codebuddy/skills/timiai-image/scripts/pipeline.py      # 批量 + 后处理（推荐）
python .codebuddy/skills/timiai-image/scripts/list_models.py   # 探测可用模型
```

## 红线

- **[1]** key 不可用且用户提供不了 → 暂停资产任务或走降级 SOP（[VISUAL_DEBT downgrade] tag）
- **[2]** 多帧资产先 AD-CHAR-KEY 评审通过再派生（AP-03）
- **[3]** 资产入库前必走 art-director TPL-05 v2 in-context 渲染评审（AP-10）

## 何时升级到 PLAYBOOK

- 信息检查清单详细 / Prompt 扩写七要素 / 提问示范 → §1 详细 SOP
- 脚本调用示例（文生图 / 编辑 / 聊天迭代 / 抽卡 / fallback）→ §2 脚本调用
- 模型选型对比（gpt-image-2 / hunyuan / dalle-3 等 6 个）→ §3 选型
- 复盘 / 满意度询问 / 迭代路径 → §4 复盘
- 工作室 fallback 路径（key 真没有时）→ §5 fallback

详见 `PLAYBOOK.md`。

## 历史

完整 API 参考 / 避坑要点 / batch / cache 详解 → `ARCHIVE.md`
