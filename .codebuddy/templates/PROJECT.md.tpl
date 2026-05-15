# PROJECT.md · 项目元数据

> 本模板由 `new-project` skill 调用生成。替换 `${...}` 占位符后落盘到 `projects/<name>/PROJECT.md`。

---

```markdown
---
project_name: ${PROJECT_NAME}
engine: ${ENGINE}           # godot / unity / unreal
engine_version: ${ENGINE_VERSION}
status: draft               # draft / active / archived
created_at: ${DATE}
lead: ${LEAD}
---

# ${PROJECT_NAME}

## 一句话概述

${ONE_LINE_SUMMARY}

## 目标玩家

${TARGET_PLAYER}

## 类型定位

${GENRE}

## 里程碑

| 里程碑 | 目标日期 | 状态 |
|---|---|---|
| M1 · 核心玩法原型 | — | `[ ]` |
| M2 · 垂直切片 | — | `[ ]` |
| M3 · Alpha | — | `[ ]` |
| M4 · Beta | — | `[ ]` |
| M5 · Release | — | `[ ]` |

## 引擎配置

- 引擎：${ENGINE} ${ENGINE_VERSION}
- 渲染管线：${RENDER_PIPELINE}   # Godot: Forward+ / Mobile; Unity: URP / HDRP; Unreal: 默认
- 目标平台：${TARGET_PLATFORMS}   # PC / Mobile / Console
- 分辨率基准：${BASE_RESOLUTION}  # 如 1920x1080

## 团队角色

| 角色 | 成员 | agent 代理 |
|---|---|---|
| 制作人 | — | `producer` |
| 项目经理 | — | `pm` |
| 设计师 | — | `designer` |
| 工程师 | — | `engineer` / `${ENGINE}-*` |
| QA | — | `qa` / `qa-lead` |
| 美术 | — | `art-director` |
| 文档 | — | `docs-writer` |

## 目录结构

\`\`\`
projects/${PROJECT_NAME}/
├── PROJECT.md          ← 本文件
├── gdd/                ← GDD 文档（最小 5 维度 + 项目专属章节，由概念对话产出）
├── stories/            ← User stories
├── adr/                ← Architecture Decision Records
├── data/               ← 数值表（JSON / TOML / CSV）
├── releases/           ← Release notes
├── retros/             ← Sprint retro 归档
├── qa/                 ← 测试策略 / 回归矩阵
└── art/                ← 美术参考 / style guide
\`\`\`

## 关联文档

- GDD：`projects/${PROJECT_NAME}/gdd/`
- ADR 索引：`projects/${PROJECT_NAME}/adr/0000-index.md`
- 测试策略：`projects/${PROJECT_NAME}/qa/test-strategy.md`
```
