---
name: new-project
description: New project initialization wizard that scaffolds a project directory under projects/ with PROJECT.md, gdd/, and stories/.
allowed-tools:
disable: false
---

# New-Project · 新项目初始化向导

## 何时使用

用户要在工作室下新建一个项目时调用，建出符合 v4 §3 项目结构规范的骨架。

典型触发：
- "/new-project"
- "我要做一个新游戏"
- 由 `start` skill 路由进入

## 输入 / 触发条件

- 工作室根目录（必须存在 `studio/` `.codebuddy/`）
- 用户回答的项目元信息：
  - 项目名（kebab-case，符合 R5）
  - 引擎（godot / unity / unreal）
  - 类型（jam / prototype / production）
  - stage（concept / pre-production / production / polish）
  - 一句话定位

## 流程步骤

1. **前置校验**：当前是否在工作室根；`projects/<name>/` 是否已存在（已存在则中止）
2. **元信息采集**：交互式问 5 个字段（中文引导，输入存为英文）
3. **目录骨架建立**：
   ```
   projects/<name>/
   ├── PROJECT.md          ← 用 templates/PROJECT.md.tpl 填充
   ├── README.md           ← 项目级 README（含 smoke checklist 占位）
   ├── gdd/
   │   └── .gitkeep        ← 8 节 GDD 待用 design-review 起草
   ├── stories/
   │   └── .gitkeep
   ├── epics/
   │   └── .gitkeep
   ├── adr/
   │   └── .gitkeep
   ├── sprints/
   │   └── .gitkeep        ← plan / smoke / retro 统一放此目录
   ├── data/
   │   └── .gitkeep        ← 数值表（JSON / TOML / CSV）
   ├── reports/
   │   └── .gitkeep
   ├── retros/
   │   └── .gitkeep
   ├── releases/
   │   └── .gitkeep
   ├── qa/
   │   └── .gitkeep
   ├── art/
   │   └── .gitkeep        ← style guide / 参考图
   ├── assets/
   │   └── .gitkeep        ← 美术资产（art-asset-pipeline 产出）
   └── docs/
       └── .gitkeep        ← 项目级文档（README 之外）
   ```
4. **引擎路由提示**：根据所选引擎，提示用户调用 `setup-engine` skill
5. **下一步路由**：
   - 如 stage=concept → 路由到 `design-review` 起草 GDD
   - 如 stage=pre-production → 路由到 `create-epics`
6. **commit 建议**（如已 init git）：`[story] init project <name>`

## 输出

- 完整的 `projects/<name>/` 骨架
- 终端内一段中文引导（明确告知"接下来调用什么 skill"）

## 引用

- 上游规划：v4 §3、§4 Q7-B、§6.1.1 工作室级 8
- 相关 skill：`setup-engine` `design-review` `create-epics`
- 相关 rule：`project-structure`
- 相关 template：`templates/PROJECT.md.tpl`

## Known Limitations / Phase 2 Review Points

- [Phase 2 TODO] 项目级 README.md 模板未在 9 template 清单中，待 §9.4 兜底审计
- [Phase 2 TODO] 与 `adopt` skill（接管已有项目，v4 可选）的边界待打磨
- [Phase 2 TODO] stage 字段的 4 个枚举值与 `release-checklist` 4 级的映射需对齐
