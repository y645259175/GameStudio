---
name: design-review
description: GDD authoring & review facilitator. Use when user says "写 GDD / 起草设计 / design review / 评审设计 / 8 sections / 概念到设计". Owns the 8-section GDD structure, ensures internal consistency, and gates phase-1→phase-2 advancement. Calls designer agent for content, reviewer for cross-check.
allowed-tools: read_file, write_to_file, list_dir, search_content
disable: false
---

# design-review · GDD 评审与起草

## 何时加载

- 项目从 concept 进入 design 阶段
- 用户说"写 GDD" / "评审设计" / "概念定下来了"
- 单章重写 / 新增 GDD 章节
- gate 决策："这个设计能不能进开发？"

**不加载场景**：小设计点用 `quick-design`；架构类决策用 `architecture-decision`。

## 输入契约

| 输入 | 来源 | 必需 |
|---|---|---|
| 项目 concept（一句话）| `PROJECT.md` 或用户 | ✅ |
| 设计材料（参考图 / 类似游戏 / 玩法概述）| 用户 | 推荐 |
| `templates/gdd-8-sections.md` | 模板 | ✅ |
| `studio/docs/workflow-guide.md` | 流程参考 | 推荐 |
| `rules/design-authoring/RULE.mdc` | 强制 | ✅ |

## 流程

### Step 1 · 范围确认

确定本次：
- **A 起草**：从零写 GDD（8 节全部）
- **B 单章重写**：替换某一节
- **C 评审**：审已存在的 GDD，输出 verdict
- **D 增补**：在已有 GDD 上加新章节（如 Boss / 经济系统）

### Step 2 · 加载 8 节模板

读 `templates/gdd-8-sections.md`，确认 8 节固定结构：

1. 概述（Concept）
2. 玩法循环（Core Loop）
3. 视觉与美术（Visual & Art）
4. 系统设计（Systems）
5. 数值平衡（Numbers & Balance）
6. 关卡内容（Content）
7. UX/HUD/无障碍（UX）
8. 交付与验收（Acceptance）

### Step 3 · 委托 designer agent 起草

调用 `designer` agent（model: opus），传入：
- concept
- 类似游戏参考
- 平台 / 团队规模约束

designer 产出 8 节内容的草稿。

### Step 4 · 一致性自审

按 `design-authoring` rule 的检查项：
- 8 节标题完整？
- 玩法循环 ↔ 系统设计 ↔ 数值 之间无矛盾？
- 验收标准可衡量（不是"很好玩"）？
- 风险列表 + 缓解 ≥ 3 条？

### Step 5 · 委托 reviewer agent 交叉核对（仅评审模式）

调用 `reviewer` agent 给 verdict：
- `APPROVED`：8 节齐 + 内部一致 + 可进入开发
- `CONDITIONAL`：有 1-3 处需补强，列具体条目
- `BLOCKED`：核心矛盾（如核心循环与平台矛盾），需重写

### Step 6 · 落盘

按 `design-authoring` rule：
- 起草 → `projects/<name>/gdd/gdd-<chapter>.md`，按 `templates/gdd-8-sections.md` 填充
- 单章 → `projects/<name>/gdd/gdd-<chapter>.md`
- 评审报告 → `projects/<name>/reports/gdd-review-<date>.md`

### Step 7 · gate 输出

如果是 phase gate：明确告诉 producer 是否可以进入开发阶段。

## 输出契约

| 字段 | 内容 |
|---|---|
| `verdict` | `APPROVED` / `CONDITIONAL` / `BLOCKED` |
| `gdd_path` | 落盘路径 |
| `findings` | 不通过项清单（含位置 + 建议） |
| `next_action` | 进开发 / 修后再审 / 重做 |

## 调用的 agent

- `designer`（opus，起草）
- `reviewer`（sonnet，交叉核对）
- 必要时 `architect`（若涉及技术可行性）

## 加载的 rule

- `design-authoring`（强制 8 节）
- `language-policy`
- `project-structure`

## 失败 / 降级

| 异常 | 策略 |
|---|---|
| concept 不清晰 | 反问 3 个问题（核心动词 / 目标玩家 / 1 句卖点） |
| 8 节有 < 5 节内容稀薄 | 强制 `BLOCKED`，让 designer 补 |
| designer 与 architect 给出矛盾建议 | 升级 producer 仲裁 |

## 验收标准

- 8 节齐全 + 每节 ≥ 1 段实质内容
- 验收清单 ≥ 5 条 + 全部可衡量
- 风险 ≥ 3 条 + 缓解措施

## Known Limitations

- 评审依赖 reviewer agent 的语义判断，缺自动化指标
- 跨章节冲突需人工 review（依赖 `consistency-check` 后续覆盖）
