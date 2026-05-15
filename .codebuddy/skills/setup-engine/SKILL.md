---
name: setup-engine
type: skill
status: active
description: Engine initialization router that scaffolds engine-specific project files based on PROJECT.md engine field.
---

# Setup-Engine · 引擎初始化路由

## 何时使用

`new-project` 完成后，给项目接上具体引擎（godot / unity / unreal）。是带占位路由 4 之一——本 skill 的核心是**路由到引擎参考**，不实现引擎具体细节。

典型触发：
- "/setup-engine"
- "接 godot 上来"
- `new-project` 末段路由

## 输入 / 触发条件

- 当前在项目根
- `PROJECT.md` engine 字段已填（godot / unity / unreal）
- 项目目录骨架已建好（`new-project` 完成）

## 流程步骤

1. **引擎识别**：读 `PROJECT.md` engine 字段
2. **占位路由 · 引擎参考**：定位到 `studio/docs/engine-reference/<engine>/`
3. **engine-specialist agent 调用**：路由到 `agents/<engine>-specialist-*` 系列 agent（按需）
4. **工程骨架建立**：
   - **godot**：建 `project.godot` + `scenes/` + `scripts/` + `assets/`
   - **unity**：提示用户用 Unity Hub 创建，AI 填 .gitignore + 初始 Assets/
   - **unreal**：提示用户用 Epic Launcher 创建，AI 填 .gitignore + 初始 Source/
5. **基础配置**：
   - .gitignore（按引擎模板）
   - 项目级 README 加引擎启动说明
6. **commit 建议**：`[story] setup engine <engine>`

## 输出

- 引擎工程骨架文件
- 路由提示（接下来调用 `dev-story` 或 `architecture-decision`）

## 引用

- 上游规划：v4 §6.1.1（带占位路由 4 之一）、§3
- 相关 skill：`new-project` `architecture-decision` `dev-story`
- 相关 agent：`godot-specialist-*` / `unity-specialist-*` / `unreal-specialist-*`（30 agent 中的 15 个 engine-specialist）
- 相关 rule：`project-structure`
- 占位路由：`studio/docs/engine-reference/<engine>/`（Phase 1 占位 / Phase 2 填充）

## Known Limitations / Phase 2 Review Points

- [Phase 2 TODO] unity / unreal 必须用各自 launcher 创建，本 skill 仅做"创建后接管"，不能完全 scaffold
- [Phase 2 TODO] engine-specialist agent 系列在 Phase 1 仅占位（批 7-8 起草），路由实质为 noop
- [Phase 2 TODO] 多引擎项目（如 godot 主 + unity 演示）的支持未设计
- [Phase 2 TODO] 引擎版本固定 / 升级流程未包含（建议未来加 ADR 强制）
