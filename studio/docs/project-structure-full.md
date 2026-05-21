# 项目结构完整规范

> **精简版**见 `.codebuddy/rules/project-structure/RULE.mdc`（always 加载）
> 本文是创建项目 / 新建目录 / 移动文件时的完整参考。

---

## 四层架构

```
<workspace-root>/
├── .codebuddy/       ← 能力层（skill / agent / hook / rule / template）
├── studio/           ← 工作室层（docs / reference / config）
├── engine/           ← 引擎层（引擎二进制，gitignored，不进版本控制）
│   └── Godot/        ← Godot_v4.6.2-stable_win64.exe
└── projects/         ← 项目层（<project-name>/ gdd/ stories/ adr/ ...）
```

### `.codebuddy/` 能力层

| 子目录 | 内容 |
|---|---|
| `skills/<name>/SKILL.md` | 技能定义 + 资源 |
| `agents/<name>/AGENT.md` | Agent 定义 |
| `hooks/<name>.py` | Hook 脚本（Windows 用 Python） |
| `rules/<name>/RULE.mdc` | 规则定义 |
| `templates/<name>.tpl` | 模板文件 |
| `plans/` | 迁移规划 + 日志 |

### `studio/` 工作室层

| 子目录 | 内容 |