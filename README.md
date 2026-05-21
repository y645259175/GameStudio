# GameStudio · AI 游戏工作室孵化器

> AI-driven game development studio powered by CodeBuddy + Godot

## 架构

```
GameStudio/
├── .codebuddy/           ← 能力层（21 agent / 23 skill / 6 rule / 11 template / 5 hook）
├── studio/               ← 工作室层（docs / engine-reference / reference）
├── engine/               ← 引擎层（Godot 4.6.2，进 git）
└── projects/             ← 项目层（每个项目独立自包含）
    └── breakout/         ← 验证项目（打砖块，5 关可玩）
```

## 快速开始

1. **克隆仓库**：`git clone <url>`
2. **打开 Godot**：运行 `engine/Godot/Godot_v4.6.2-stable_win64.exe`
3. **导入项目**：Import → `projects/breakout/game/project.godot`
4. **按 F5 运行**

## 核心能力

| 类别 | 数量 | 说明 |
|---|---|---|
| Agent | 21 | 制作人/PM/设计师/工程师/QA + Godot 专家 5 + 美术/UX/文档/发版 |
| Skill | 23 | 全流程：创建项目 → GDD → 拆 epic/story → 开发 → 测试 → 发版 |
| Rule | 6 | 项目结构 / 提交规范 / 设计精度 / 语言策略 / 数据驱动 / 测试标准 |
| Template | 11 | GDD / story / epic / sprint / retro / ADR / consistency 等 |

## 文档入口

| 文档 | 路径 | 说明 |
|---|---|---|
| 工作室手册 | `studio/docs/studio-handbook.md` | 全貌速查 + Common Pitfalls |
| 设计精度规范 | `.codebuddy/rules/design-authoring/RULE.mdc` | GDD 三原则 |
| 协作协议 | `studio/docs/collaboration-protocol.md` | agent 间协作规则 |
| 工作流指南 | `studio/docs/workflow-guide.md` | 7 阶段开发流程 |
| 语言策略 | `studio/docs/language-policy.md` | 中英文分工 |

## 开发约定

- **数据驱动**：数值在 `data/*.json`，代码通过 ConfigLoader 读取，不硬编码
- **提交规范**：`[story]` / `[fix]` / `[refactor]` / `[chore]` 前缀
- **测试**：每次改完跑 `godot --headless --check-only` + `qa/run-tests.ps1`
- **GDD 精度**：描述触发+表现（策划）；具体数值指向数据表（程序读表）

## 引擎

- Godot 4.6.2（`engine/Godot/Godot_v4.6.2-stable_win64.exe`）
- 纳入 git 追踪，确保协作者版本一致

## 项目

| 项目 | 状态 | 说明 |
|---|---|---|
| breakout | ✅ 可玩 | 5 关打砖块 / 5 种道具 / 49 自动化测试 / AI 生成背景 |

## 环境配置（换机器/换磁盘必读）

本项目中有少量**必须使用绝对路径**的运行时配置文件。克隆到新环境后需要修改以下位置：

| 文件 | 需改内容 | 说明 |
|---|---|---|
| `.codebuddy/settings.json` | hook command 里的 `python <绝对路径>/.codebuddy/hooks/pre-tool-bash.py` | PreToolUse hook 脚本路径，CodeBuddy 不展开环境变量 |
| `.codebuddy/rules/agent-spawn-contract/RULE.mdc` | `<PROJECT_PATH>: d:/AI/GameStudio/projects/<name>/game` | TPL-01
