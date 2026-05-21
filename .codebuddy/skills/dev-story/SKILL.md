---
name: dev-story
type: skill
status: active
description: Heavy-channel development workflow for a single user story. ready → implementing → testing → reviewing → playtest_pending → done with consistency-check gating.
---

# dev-story · CORE

## 何时触发

- 实现一条 user story（重通道，区别于 quick-fix 轻通道）
- 触发语：`/dev-story <id>` / "开始做 story X" / sprint-plan 后选定 story

## 一键入口

```bash
python .codebuddy/skills/dev-story/run.py --story <story-md> --action <implement|test|review|playtest|done>
python .codebuddy/skills/dev-story/run.py --story ... --action review --shadow   # combo-B shadow review
```

## 状态机（AP-10 修法 6 状态）

```
ready → implementing → testing → reviewing → playtest_pending → done
```

`playtest_pending → done` 必须真人实玩并 `--playtest-confirmed-by user` 才能转。AI 不允许自跳。

## 红线

- **[1]** 视觉 story 必须先扫 `assets/`，缺资产 → spawn art-asset-pipeline 或开 [VISUAL_DEBT] backlog（不允许默认 ColorRect 占位）
- **[2]** 玩家可见行为必须有"真实玩家路径测试"（Input.action_press 等），禁止 cheat-only PASS
- **[3]** vertical slice / playable level 进 reviewing 时必须跑 TPL-09（5 项清单）
- **[4]** 绕过决策必须开 backlog（带 priority + due milestone），不只是 retro
- **[5]** commit 用 `[story] <id>: <描述>` tag

## 何时升级到 PLAYBOOK

- 完整流程 11 步详解 → §1 详细流程
- 绕过决策 SOP → §2 bypass-policy
- DoD 自检 4 项 → §3 dod-checklist
- 自主模式补充 → §4 autonomous

## 历史教训

- 2026-05-15 项目 A pivot 事故 → 本 skill 加入视觉资产前置 / 真实玩家路径 / 绕过 SOP / DoD 自检
- 详细判例 → `ARCHIVE.md`
