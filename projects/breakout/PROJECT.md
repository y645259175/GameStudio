---
project_name: breakout
engine: godot
engine_version: 4.x LTS
status: draft
created_at: 2026-05-14
lead: ZStodio
---

# Breakout

## 一句话概述

经典打砖块复刻——挡板接球、消灭砖块、通关得分。用于验证 GameStudio 全流程。

## 目标玩家

休闲玩家 / GameStudio 流程验证用途

## 类型定位

2D Arcade / Breakout Clone

## 里程碑

| 里程碑 | 目标日期 | 状态 |
|---|---|---|
| M1 · 核心玩法原型（挡板 + 球 + 砖块） | — | `[ ]` |
| M2 · 完整单关（道具 + 分数 + 生命） | — | `[ ]` |
| M3 · 多关卡 + 难度递增 | — | `[ ]` |
| M4 · 打磨（音效 + 特效 + 主菜单） | — | `[ ]` |

## 引擎配置

- 引擎：Godot 4.x LTS
- 渲染管线：Forward+
- 目标平台：PC（Windows）
- 分辨率基准：1280x720

## 团队角色

| 角色 | 成员 | agent 代理 |
|---|---|---|
| 制作人 | ZStodio | `producer` |
| 项目经理 | — | `pm` |
| 设计师 | — | `designer` |
| 工程师 | — | `engineer` / `godot-*` |
| QA | — | `qa` / `qa-lead` |
| 美术 | — | `art-director` |
| 文档 | — | `docs-writer` |

## 目录结构

```
projects/breakout/
├── PROJECT.md          ← 本文件
├── README.md           ← 项目 README + smoke checklist
├── gdd/                ← GDD 文档（8 节结构）
├── stories/            ← User stories
├── epics/              ← Epics
├── adr/                ← Architecture Decision Records
├── sprints/            ← Sprint plan / smoke / retro
├── data/               ← 数值表（JSON）
├── reports/            ← 一致性检查报告
├── retros/             ← Sprint retro 归档
├── releases/           ← Release notes
├── qa/                 ← 测试策略 / 回归矩阵
├── art/                ← 美术参考 / style guide
├── assets/             ← 美术资产
└── docs/               ← 项目级文档
```

## 关联文档

- GDD：`projects/breakout/gdd/`
- ADR 索引：`projects/breakout/adr/0000-index.md`
- 测试策略：`projects/breakout/qa/test-strategy.md`
