---
name: art-asset-pipeline
description: Art asset production pipeline. Calls timiai-image skill for generation/editing, art-director agent for review. Use when generating game-ready visual assets (sprites, UI, backgrounds, characters).
---

# art-asset-pipeline · CORE

## 何时触发

- 用户或 agent 需要新美术资产入游戏（sprite / UI / 背景 / 角色 / icon）
- art-director / engineer 发起资产请求
- VISUAL_DEBT backlog 项处理时

## 一键入口

无独立 run.py。本 skill 是**协调者**，按场景调用：

```bash
python .codebuddy/skills/timiai-image/scripts/_check_key.py        # 必跑
python .codebuddy/skills/timiai-image/scripts/pipeline.py --config <pipe.json>  # 推荐入口
```

## 红线

- **[1]** 多帧动画 / 同一角色多状态 → 必须 reference-based（image_edit）+ key sprite 先 art-director 评审通过（AP-03）
- **[2]** 资产入库前必走 art-director TPL-05 v2 in-context 渲染评审（AP-10 / AP-11）
- **[3]** key 不可用时按 timiai-image §5 fallback 路径（标 [VISUAL_DEBT downgrade]，不允许 main agent 自己说"看上去合理"就过）
- **[4]** 资产落盘约定：游戏内进 `projects/<name>/game/assets/`；参考图进 `projects/<name>/art/`

## 流程概要

1. 意图识别 + 信息检查（委托 timiai-image §1 五步工作流）
2. key sprite 先出 → art-director 评审 → 用户确认
3. 派生 / 批量产出（image_edit 链式）
4. art-director TPL-05 v2 in-context 评审
5. 入库 commit（[story] / [VISUAL_DEBT downgrade] / [feat]）

## 何时升级到 PLAYBOOK

- 完整 7 步流程 / 命名约定 / 落盘规范 → §详细流程
- art-director 评审 6 维 → §review-rubric
- 资产生命周期 / 弃用流程 → §lifecycle

详见 `PLAYBOOK.md`。

## 关联

- 调用：`timiai-image` skill / `art-director` agent
- 引用：anti-patterns AP-03 / AP-04 / AP-10 / AP-11
- 模板：TPL-05 v2（agent-spawn-contract MANUAL）
