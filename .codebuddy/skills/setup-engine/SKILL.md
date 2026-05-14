---
name: setup-engine
description: Engine-specific project scaffolding. Called by new-project skill (or directly when user says "init godot project / 初始化引擎 / setup unity"). Reads PROJECT.md.engine field and scaffolds engine-specific files (project.godot / .uproject / ProjectSettings) under projects/<name>/game/.
allowed-tools: read_file, write_to_file, list_dir, execute_command
disable: false
---

# setup-engine · 引擎脚手架路由

## 何时加载

- 由 `new-project` 自动调用
- 用户在已有项目中切换 / 补建引擎骨架（"我要加个 godot 项目结构"）

**不加载场景**：引擎相关代码层面工作（走 `dev-story` + 对应引擎 specialist agent）。

## 输入契约

| 输入 | 来源 |
|---|---|
| `project_name` | 调用方 / 当前 cwd |
| `engine` | `projects/<name>/PROJECT.md` 的 engine 字段 |
| `engine_version` | 同上（可选）|

## 流程

### Step 1 · 读取项目元数据

```
read_file projects/<name>/PROJECT.md
```

提取 `engine` / `engine_version` 字段。

### Step 2 · 路由到对应引擎分支

| engine | 落盘内容 |
|---|---|
| `godot` | `game/project.godot`（最小可启动配置）+ `game/scenes/.gitkeep` + `game/scripts/.gitkeep` + `game/assets/.gitkeep` |
| `unity` | `game/Assets/`、`game/ProjectSettings/`（占位 → Phase 2 完整版）|
| `unreal` | `game/<Name>.uproject`（占位 → Phase 2 完整版）|

### Step 3 · 写入引擎参考链接

在 `projects/<name>/README.md` 末尾追加：
```
## 引擎参考
- studio/docs/engine-reference/<engine>/README.md
```

### Step 4 · 验证（如可用）

如检测到 `engine/<Engine>/` 下有可执行文件，运行最小校验：
- godot：`Godot.exe --headless --check-only --path projects/<name>/game --quit`
- unity / unreal：跳过（Phase 1 占位）

### Step 5 · 输出

明确告诉用户：
- 引擎骨架就位
- 推荐的 specialist agent（如 `godot-architect` / `unity-architect`）
- 下一步：写第一个 story 或调 `dev-story`

## 输出契约

| 字段 | 内容 |
|---|---|
| `verdict` | `SCAFFOLDED` / `PLACEHOLDER_ONLY:<engine>` / `ABORTED:<reason>` |
| `engine` | godot/unity/unreal |
| `recommended_specialist` | `<engine>-architect` |

## 调用的 agent

- `<engine>-architect`（可选，咨询引擎特定的最佳目录结构）

## 加载的 rule

- `project-structure`

## 失败 / 降级

| 异常 | 策略 |
|---|---|
| `PROJECT.md.engine` 字段缺失 | 询问用户 |
| 引擎不在白名单 | 报错 + 列支持引擎 |
| Unity/Unreal 完整脚手架未实现 | 落"占位 + `[Phase 2 TODO]`" 的 README |

## 验收标准

- godot：`game/project.godot` 通过 `--check-only`
- unity/unreal：占位文件就位 + 标注 Phase 2

## Known Limitations

- Unity / Unreal 完整脚手架 Phase 2 完成
- 引擎版本变更不自动迁移（需手动）
