---
project_name: breakout
engine: godot
engine_version: 4.6.2
phase: dev
status: playable
created_at: 2026-05-14
last_updated: 2026-05-14
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
| M1 · 核心玩法原型（挡板 + 球 + 砖块） | 2026-05-14 | `[x]` ✅ |
| M2 · 完整单关（道具 + 分数 + 生命） | 2026-05-14 | `[x]` ✅ |
| M3 · 多关卡 + 难度递增 | 2026-05-14 | `[x]` ✅ |
| M4 · 打磨（主菜单 + 暂停 + UX）| 2026-05-14 | `[x]` ✅ |
| M5 · 音效 + 完整 polish | — | `[ ]` |

## 当前状态

- **Phase**：dev → 接近 test
- **可玩**：✅（启动 → 主菜单 → 5 关 → Win/Game Over → 重启 / 回菜单）
- **测试**：52/52 自动化用例 PASS
- **代码**：godot --check-only EXIT 0

## 已知缺口（Phase 2+）

1. 无音效 SFX/BGM
2. multi_ball 简化为"清除一行"（详见 .codebuddy/plans/autorun-2026-05-14.md Issue #1）
3. 道具数值未做 playtest 校准
4. 无设置菜单

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
