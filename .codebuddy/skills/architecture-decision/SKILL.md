---
name: architecture-decision
description: Architecture Decision Record (ADR) authoring flow. Use when user says "ADR / 架构决策 / 技术选型 / 重构方案 / refactor proposal / 引擎选择 / 数据库选 / pattern 选". Produces a structured ADR with context / options / decision / consequences. Calls architect agent.
allowed-tools: read_file, write_to_file, list_dir, search_content
disable: false
---

# architecture-decision · ADR 起草

## 何时加载

- 影响 ≥ 2 个模块的技术决策
- 引擎 / 框架 / 关键库选择
- 重构 / 模式切换（如同步 → 异步）
- 用户明确说"做个 ADR"

**不加载场景**：单文件局部改动 → `quick-fix`；纯设计 → `design-review`；story 内技术细节 → `dev-story`。

## 输入契约

| 输入 | 来源 |
|---|---|
| 决策主题 | 用户 |
| 现状（status quo） | 代码 / GDD |
| 候选方案 ≥ 2 | 用户或 architect 提议 |
| 约束（性能 / 团队技能 / 时间） | 用户 |

## 流程

### Step 1 · 委托 architect 收集 context

调用 `architect` agent（opus），让它：
- 用 ≤ 200 字描述现状
- 列 ≥ 2 个候选方案
- 列 trade-off 矩阵（性能 / 复杂度 / 学习成本 / 风险）

### Step 2 · 用户确认选项范围

如 architect 给的方案 < 2 → 反问用户是否还有其他备选。

### Step 3 · 决策推导

按 `templates/adr.md` 结构：

```
# ADR-NNNN: <title>
## 状态
- proposed / accepted / superseded
## 背景（Context）
## 候选方案（Options）
### A. <name>
### B. <name>
## 决策（Decision）
- 选 X 因为 Y
## 后果（Consequences）
- 正面
- 负面
- 风险缓解
## 受影响的代码 / 文档
- file1, file2, ...
```

### Step 4 · reviewer 交叉核对

调用 `reviewer` agent 检查：
- trade-off 是否客观
- "决策"是否能回溯到"背景 + 选项"
- 后果是否包含负面

### Step 5 · 落盘

`projects/<name>/adr/ADR-<NNNN>-<slug>.md`（4 位编号自增）。

如有跨项目共享（架构原则） → 同时落 `studio/docs/adr/` （Phase 2 目录）。

### Step 6 · 影响通知

在受影响代码文件头注释中加：
```
# See: projects/<name>/adr/ADR-NNNN-<slug>.md
```

## 输出契约

| 字段 | 内容 |
|---|---|
| `verdict` | `ACCEPTED` / `PROPOSED` / `REJECTED` |
| `adr_path` | `projects/<name>/adr/ADR-NNNN-*.md` |
| `affected_files` | 文件列表 |
| `next_action` | 实施 / 等用户复核 |

## 调用的 agent

- `architect`（opus，主笔）
- `reviewer`（sonnet，复核）
- 引擎相关时调对应 `<engine>-architect`

## 加载的 rule

- `commit-discipline`（[story] tag 格式）
- `language-policy`

## 失败 / 降级

| 异常 | 策略 |
|---|---|
| 候选方案只有 1 个 | 标 `proposed` 但要求 architect 补 1 个对照方案 |
| trade-off 评估困难 | 留空 + 加 `[Phase 2 evaluate]` 标注 |
| 决策后被推翻 | 旧 ADR 状态改 `superseded`，新 ADR 引用旧 ID |

## 验收标准

- 5 节齐全（背景 / 候选 / 决策 / 后果 / 受影响）
- 候选 ≥ 2 + trade-off 表
- 后果含负面 + 缓解

## Known Limitations

- ADR 编号自增依赖目录扫描（Phase 2 评估元数据 index 文件）
- 跨项目 ADR 与项目 ADR 的归档边界 Phase 2 决议
