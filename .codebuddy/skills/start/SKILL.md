---
name: start
description: Entry point and intent router for new sessions. Use when the user says "begin / start / what should I do / 开始 / 接下来做什么 / 不知道从哪开始" or whenever the request is ambiguous and a routing decision is needed before any other skill loads.
allowed-tools: read_file, list_dir, search_content
disable: false
---

# start · 工作室入口路由 skill

## 何时加载

- 新会话第一句意图模糊（"开始吧" / "继续" / "今天做什么"）
- 用户在工作室根目录但未指定 project / story
- 需要"先确定上下文，再选 skill"的场景

**不要加载本 skill 的场景**：用户已经明确说"我要写 GDD"（直接走 `design-review`）/ "我要建项目"（直接走 `new-project`）/ 已经在某个 story 上下文里继续工作。

## 输入契约

| 输入 | 来源 | 必需 |
|---|---|---|
| 用户原始意图（自然语言） | 当前消息 | ✅ |
| 当前工作目录 | 系统 | ✅ |
| `studio/docs/studio-handbook.md` | 文件读取 | 推荐 |
| `projects/*/PROJECT.md` 列表 | 目录扫描 | 推荐 |

## 流程

### Step 1 · 环境侦察（30 秒内）

并行读取：
- `list_dir projects/`
- `read_file studio/docs/studio-handbook.md`（如存在）
- 当前 cwd 是否在某个 `projects/<name>/` 下

### Step 2 · 意图分类（输出 verdict）

按优先级匹配：

| 触发关键词 | 路由 verdict |
|---|---|
| "新项目 / new project / 建项目" | `ROUTE: new-project` |
| "story / 任务 / 开发" + 已有项目 | `ROUTE: dev-story` 或 `ROUTE: story-readiness` |
| "bug / 修一下 / fix" | `ROUTE: quick-fix` |
| "GDD / 设计 / 玩法" | `ROUTE: design-review` 或 `ROUTE: quick-design` |
| "架构 / 技术选型 / ADR" | `ROUTE: architecture-decision` |
| "美术 / 资产 / 出图" | `ROUTE: art-asset-pipeline` |
| "测一下 / smoke / 检查" | `ROUTE: smoke-check` 或 `ROUTE: consistency-check` |
| "今天 / 日报 / daily" | `ROUTE: daily-check` |
| "sprint / 计划 / 排期" | `ROUTE: sprint-plan` |
| "复盘 / retro" | `ROUTE: retrospective` |
| "发版 / release" | `ROUTE: release-checklist` |
| 模糊 / 多个匹配 | `CLARIFY: 列 2-3 个候选 skill 让用户选` |

### Step 3 · 路由 / 澄清

- **明确**：输出一句中文路由说明 + 加载目标 skill
  - 例："识别为新建项目意图，加载 `new-project` skill。"
- **模糊**：列 2-3 个候选，问用户选哪个，**不要**自动猜

### Step 4 · 兜底

如完全无法分类：建议用户运行 `help` skill 查看能力索引。

## 输出契约

| 字段 | 内容 |
|---|---|
| `verdict` | `ROUTE: <skill-name>` / `CLARIFY` / `FALLBACK_HELP` |
| `rationale` | 一句中文判断依据 |
| `loaded_skill` | 实际加载的 skill 名（仅 ROUTE 时） |

## 调用的 agent

无（路由本身不需要 agent）。后续 skill 会按需调用。

## 加载的 rule

`project-structure`（确定当前在哪一层）

## 失败 / 降级

| 异常 | 降级策略 |
|---|---|
| `studio/docs/studio-handbook.md` 不存在 | 跳过该文件，仅依据 `projects/` 与用户语义判断 |
| 工作区为空（无 `.codebuddy` 也无 `studio`） | 输出 `FALLBACK: 这不是工作室仓库`，建议用户 `cd` 到工作室根 |
| 用户连续 2 次指令模糊 | 强制加载 `help` skill |

## 验收标准

- AI 在 ≤ 3 个工具调用内完成路由判断
- 路由 verdict 与用户实际意图一致率 ≥ 90%（实战记录）
- 不产生越级行为（不直接执行目标 skill 的工作，仅做路由）

## Known Limitations

- 意图分类靠语义匹配，无统计模型；歧义高的输入需人工澄清
- 与 `help` 边界：`start` = 路由，`help` = 能力索引说明书
