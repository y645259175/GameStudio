# 工作室手册 (Studio Handbook)

> **定位**：工作室级导航文档，让新人（人或 AI）快速了解"这个工作室是什么、有什么、怎么用"。
>
> **最后更新**：2026-05-14

---

## 1. 工作室是什么

GameStudio 是一个 **AI 辅助游戏开发工作室**，使用 CodeBuddy 作为 AI 协作平台。工作室本身不是一个游戏项目，而是一套**能力基础设施**，可以孵化多个游戏项目。

## 2. 三层架构

```
<workspace-root>/
├── .codebuddy/       ← 能力层（AI 的技能、规则、工具）
│   ├── skills/       22 个 skill（工作流程定义）
│   ├── agents/       30 个 agent（角色定义）
│   ├── rules/        6 个 rule（强制规范）
│   ├── hooks/        5 个 hook（git 自动化脚本）
│   ├── templates/    9 个 template（文档模板）
│   └── plans/        迁移规划 + 日志
├── studio/           ← 工作室层（共享文档和参考）
│   ├── docs/         工作室级文档
│   └── reference/    只读参考区（上游 CCGS 归档）
└── projects/         ← 项目层（每个游戏一个子目录）
    └── <name>/       PROJECT.md + gdd/ + stories/ + adr/ + ...
```

## 3. 快速开始

### 创建新项目

说 "新建一个项目" 或 `/start`，AI 会调用 `new-project` skill 在 `projects/` 下创建骨架。

### 设计游戏

说 "评审一下 GDD" 或 `/design-review`，AI 会用 8 节结构引导你完成 GDD。

### 开发功能

说 "开始开发这个 story" 或调用 `dev-story`，AI 会从 story → 实现 → 测试 → commit 全流程。

### 日常检查

说 "今天做了什么" 或 `/daily-check`，AI 会跑一致性检查 + 生成日报。

## 4. 可用 Skill 索引

| 类别 | Skill | 一句话 |
|---|---|---|
| **入口** | `start` | 识别意图，路由到对应 skill |
| **项目** | `new-project` | 创建项目骨架 |
| **设计** | `design-review` `review-all-gdds` `quick-design` | GDD 起草 / 跨章审 / 小设计 |
| **规划** | `create-epics` `create-stories` `sprint-plan` `story-readiness` | 拆 epic / 拆 story / sprint 规划 / 就绪检查 |
| **开发** | `dev-story` `quick-fix` `architecture-decision` | story 开发 / 快速修复 / ADR |
| **引擎** | `setup-engine` | 引擎初始化路由 |
| **质量** | `consistency-check` `smoke-check` `release-checklist` | 一致性 / 冒烟 / 发版清单 |
| **回顾** | `daily-check` `retrospective` `milestone-review` | 日报 / sprint retro / 里程碑 |
| **美术** | `art-asset-pipeline` | 美术资产生成（调用 timiai-image）|
| **导航** | `help` `story-done` | 帮助 / story 闭环 |

## 5. 可用 Agent 索引

| 类别 | Agent | 职责 |
|---|---|---|
| **管理** | `producer` `pm` | 制作人 / 项目经理 |
| **设计** | `designer` `art-director` | 游戏设计 / 艺术总监 |
| **工程** | `engineer` `architect` `debugger` `reviewer` `refactorer` `tester` | 实现 / 架构 / 调试 / 审查 / 重构 / 测试 |
| **QA** | `qa` `qa-lead` | 执行 / 策略 |
| **引擎** | `godot-*` (5) `unity-*` (5) `unreal-*` (5) | 三引擎各 5 专家 |
| **支持** | `release-manager` `postmortem-keeper` `docs-writer` | 发版 / 复盘归档 / 文档 |

## 6. 规则速查

| Rule | 类型 | 核心 |
|---|---|---|
| `project-structure` | alwaysApply | 三层架构 + 路径约束 |
| `commit-discipline` | 按需 | 双通道 commit（`[story]` / `[fix]`） |
| `design-authoring` | 按需 | GDD 8 节强制结构 |
| `language-policy` | 按需 | 中文叙述 + 英文代码/路径（7 条规则） |
| `data-driven` | 按需 | 数值外置，不硬编码 |
| `test-standards` | 按需 | 单元 80% / 集成 15% / 冒烟 5% |

## 7. 参考区

`studio/reference/` 存放迁移前的历史资产（只读）：
- `analysis-report/`：CCGS 框架原始分析
- `my-game/`：CCGS v1.0 上游模板

详见 [`studio/reference/README.md`](../reference/README.md)
