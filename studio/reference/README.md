# studio/reference/ · 只读参考区

## 定位

本目录是工作室的**只读参考资料区**。存放迁移到 v4 架构之前已有的、未来需要查阅但**不被运行时依赖**的资产。

## 内容（Phase 1.5 归位后填充）

| 子目录 | 来源 | 用途 |
|---|---|---|
| `analysis-report/` | 工作区根目录 `analysis-report/`（v4 迁移前位置）| CCGS 框架原始分析（22 份 md，v1 → v2 已修订），追溯 v4 设计依据 |
| `my-game/` | 工作区根目录 `my-game/`（v4 迁移前位置）| CCGS v1.0 上游模板（独立 git 仓，origin = Donchitos/Claude-Code-Game-Studios），抄改源头 |

## 边界规则

### ✅ 可以做的

- 人查阅：想知道当初某个决策为什么这么做时，进来翻
- AI 查阅：用户**显式要求**参考某份历史资料时，AI 在此目录下读
- 上游同步：`my-game/` 仍可 `git pull` CCGS 上游更新（它是独立仓）

### ❌ 不允许的

- **不被任何 skill / agent / rule 在运行时自动加载**
- **不作为 frontmatter 引用源**（skill / agent 的 description / dependencies 等字段不指向此处）
- **不出现在产物的"必读上下文"清单**里
- **不被 hook 脚本扫描**（validate-commit / pre-commit 等不读这里）

## 归位时机

Phase 1.5 由用户手动 `Move-Item` 完成归位。归位指令详见 `.codebuddy/plans/studio-incubator-migration-v4_*.md` 的 §6.1.4。

归位后 `.codebuddy/plans/v4-migration-log.md` 会追加一条 Phase 1.5 完成记录。

## 何时清理

- `analysis-report/`：长期保留，作为 v4 设计依据的历史档案
- `my-game/`：当工作室不再需要从 CCGS 上游同步、且所有抄改任务完成后，可考虑归档到 `_archived/` 或删除（需用户拍板）
