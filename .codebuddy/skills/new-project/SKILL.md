---
name: new-project
description: New project initialization wizard. Use when user says "新项目 / 建项目 / 创建项目 / new project / start a project / let's make X". Scaffolds projects/<name>/ with PROJECT.md, 14 subdirectories, README, and routes to setup-engine for engine-specific scaffolding.
allowed-tools: read_file, write_to_file, list_dir, execute_command
disable: false
---

# new-project · 新建项目向导

## 何时加载

- 用户明确表达"建项目 / 新项目 / start a new game"
- 工作室根目录下，`projects/` 为空或需要再开一个新项目
- `start` skill 路由到本 skill

**不加载场景**：项目已存在（走 `dev-story`）；只是想要个原型脚本（走 `quick-fix`）。

## 输入契约（必需）

| 输入 | 默认值 / 来源 | 必需 |
|---|---|---|
| `project_name`（kebab-case）| 用户提供 | ✅ |
| 一句话游戏概念 | 用户提供 | ✅ |
| `engine`（godot / unity / unreal）| 用户提供 | ✅ |
| 类型 / 平台 / 团队规模 | 用户或 default | 推荐 |

如缺失任意必需项，必须先问清楚再继续。

## 流程

### Step 1 · 输入校验

- 项目名 kebab-case 检查（`^[a-z][a-z0-9-]+$`）
- 检查 `projects/<name>/` 是否已存在 → 存在则报错
- 引擎名 ∈ {godot, unity, unreal}

### Step 2 · 目录骨架建立

```
projects/<name>/
├── PROJECT.md          ← 用 templates/PROJECT.md.tpl 填充
├── README.md           ← 项目级 README（含 smoke checklist）
├── gdd/                ← 8 节 GDD（design-review 起草）
├── stories/
├── epics/
├── adr/
├── sprints/            ← plan / smoke / retro 统一目录
├── data/               ← 数值表（JSON / TOML / CSV）
├── reports/
├── retros/
├── releases/
├── qa/
├── art/                ← style guide / 参考图
├── assets/             ← 美术资产（art-asset-pipeline 产出）
└── docs/
```

每个子目录建 `.gitkeep`。

### Step 3 · 元数据填充

读 `templates/PROJECT.md.tpl`，替换占位符：
- `${PROJECT_NAME}` `${ENGINE}` `${CONCEPT}` `${CREATED_AT}`
- `${PHASE}` 默认 `concept`

落盘 `projects/<name>/PROJECT.md`。

### Step 4 · README 生成

模板包含：
- 项目概述（一句话）
- 引擎与版本
- 快速开始（如何打开 / 运行）
- Smoke Checklist 占位
- 目录索引

### Step 5 · 引擎相关脚手架（路由）

调用 `setup-engine` skill，传入 `engine` 参数，由它建：
- godot：`game/project.godot`
- unity：`game/Assets/` `game/ProjectSettings/`
- unreal：`game/<Name>.uproject`

### Step 6 · 验证

- `list_dir projects/<name>/` 确认 14 子目录就位
- `read_file projects/<name>/PROJECT.md` 确认元数据正确

### Step 7 · 输出与下一步建议

明确告诉用户：
- 项目骨架已建在 `projects/<name>/`
- 下一步：调用 `design-review` skill 起草 GDD

## 输出契约

| 字段 | 内容 |
|---|---|
| `verdict` | `CREATED` / `ABORTED:<reason>` |
| `project_path` | `projects/<name>/` |
| `next_skill` | `design-review` |

## 调用的 agent

- `producer`（确认项目目标 / 范围合理性，可选）
- `setup-engine` skill（必选）

## 加载的 rule

- `project-structure`（强制四层架构 + 14 子目录约束）
- `language-policy`（README 中英文规范）

## 失败 / 降级

| 异常 | 策略 |
|---|---|
| 项目名冲突 | 报错 + 建议改名或归档旧项目 |
| 引擎不在白名单 | 拒绝 + 列出支持的引擎 |
| `setup-engine` 失败 | 保留主骨架，引擎部分标 `[Phase 2 TODO]` |

## 验收标准

- 14 子目录 + 2 文件全部就位
- PROJECT.md 占位符全部替换
- 不引入 placeholder 路径污染

## Known Limitations

- 模板 `${VAR}` 当前手动替换，未做自动化 fill
- `setup-engine` 对 unity/unreal 仅占位（Phase 1）
