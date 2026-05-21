---
name: retrospective
description: Sprint retrospective facilitator that produces a postmortem capturing what went well, what hurt, and action items.
---

# retrospective · CORE

## 何时触发

- sprint 末 / milestone gate 后
- 用户说"复盘 / retro / postmortem"
- 重大事故 / 翻车后

## 红线（AP-06 修法）

- **[1]** 每次 retro 必须问"是否需要新增 AP-XX？"（防 AP-06 用户反馈循环没有自动学习）
- **[2]** action items 必须路由到具体 skill / rule 修订计划，不能只挂在 retro 文档里
- **[3]** 触发 5 核心 agent 的 playbook 知识总结（§7 知识总结流程）

## 流程概要（7 步）

1. 数据采集（commit / spawn 次数 / 反馈轮次 / verdict 分布）
2. What went well / What hurt 五问法
3. action items 路由到具体修订计划
4. 是否升级 anti-patterns（AP-XX 触发判断）
5. agent playbook 知识总结（5 核心 agent）
6. 落盘 retro 文档
7. 更新 backlog（标 P0/P1）

## 何时升级到 PLAYBOOK

- 完整 7 步详解 / 数据采集字段 → §流程
- agent 知识总结 SOP（playbook → AGENT.md 并入 → 清理）→ §knowledge-summary
- 触发新增 AP-XX 的判断标准 → §ap-trigger
- retro 文档模板 → §template

详见 `PLAYBOOK.md`。

## 历史教训

- 2026-05-19 platformer-2 实玩崩 → retro 触发 AP-10 + 5 条 BL-S 修法
- 详细判例 → `ARCHIVE.md`（待建，当前判例集中在 anti-patterns-archive.md）
