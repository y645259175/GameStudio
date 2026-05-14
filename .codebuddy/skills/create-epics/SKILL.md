---
name: create-epics
description: Break GDD chapters into epics. Use when user says "拆 epic / 切大块 / 把 GDD 拆成开发任务 / create epics / 立项". Each epic is a coherent feature area deliverable in 1-3 sprints. Calls pm agent.
allowed-tools: read_file, write_to_file, list_dir
disable: false
---

# create-epics · GDD → Epic 拆分

## 何时加载

- GDD 已起草至少 3 节
- 项目从 design 进入 plan 阶段
- 用户说"开始拆任务" / "做开发计划"

**不加载场景**：项目尚未有 GDD（先走 `design-review`）；单 story 拆解（走 `create-stories`）。

## 输入契约

| 输入 | 来源 | 必需 |
|---|---|---|
| GDD 全部章节 | `projects/<name>/gdd/*.md` | ✅ |
| 团队规模 / 周期 | `PROJECT.md` | 推荐 |
| 引擎能力清单 | `studio/docs/engine-reference/<engine>/` | 推荐 |

## 流程

### Step 1 · 委托 pm 拆分

调用 `pm` agent（opus），让它读 GDD 后产出 epic 草稿：
- epic 数量推荐 4-7 个（少于 4 太粗，多于 7 太碎）
- 每个 epic 对应 1 个 GDD 章节或跨 2 章
- 每个 epic 估计 1-3 sprint（不是天数）
- 每个 epic 必须包含：目标 / 验收 / 依赖（前置 epic）/ 风险

### Step 2 · 优先级排序

按 MVP 思路：
- P0 - 核心循环（不做项目跑不起来）
- P1 - 重要内容（影响留存）
- P2 - 加分项（polish / 内容扩展）

### Step 3 · 依赖图校验

确保：
- P0 中无环依赖
- 每个 P1/P2 都能在某个 P0 epic 完成后启动
- 没有 epic 没有任何前置（除了第一个）

### Step 4 · 落盘

每个 epic 一个文件：
```
projects/<name>/epics/E<N>-<slug>.md
```

包含：
```
# E<N>: <title>
- priority: P0/P1/P2
- depends-on: [E1, E2]
- estimated-sprints: 1-3
- gdd-anchor: gdd/<chapter>.md#<section>

## 目标
## 验收标准
## 拆分预估
（5-10 个 story 的草拟标题）
## 风险
```

### Step 5 · pm 自审 + reviewer 复核

- pm 检查：估算合理 / 依赖闭合 / 验收可衡量
- reviewer 检查：与 GDD 是否覆盖完整（无 GDD 系统未被任何 epic 覆盖）

### Step 6 · 输出 epic 索引

`projects/<name>/epics/README.md`：

```
# Epic 索引
| ID | 标题 | 优先级 | 预估 | 状态 | 依赖 |
|---|---|---|---|---|---|
```

## 输出契约

| 字段 | 内容 |
|---|---|
| `verdict` | `EPICS_READY` / `EPICS_INCOMPLETE:<reason>` |
| `epic_count` | 数量 |
| `epic_ids` | [E1, E2, ...] |
| `next_skill` | `create-stories`（针对 P0 epics）|

## 调用的 agent

- `pm`（opus，主笔）
- `reviewer`（sonnet，复核）
- `producer`（opus，仅在范围争议时仲裁）

## 加载的 rule

- `design-authoring`（验收标准格式）
- `project-structure`（落盘位置）

## 失败 / 降级

| 异常 | 策略 |
|---|---|
| GDD 不足 | 反向调 `design-review` 补全 |
| epic 数量 > 10 | 强制压缩或拆成多次拆分 |
| 依赖成环 | 重新排序 + pm 必须给依赖打破方案 |

## 验收标准

- 4-7 个 epic
- 全部 P0/P1/P2 标记
- 0 环依赖 + 0 GDD 章节遗漏覆盖
- 每个 epic 验收 ≥ 3 条

## Known Limitations

- 估算"1-3 sprint"是直觉，需实战校准
- 依赖图未持久化为机器可读格式（Phase 2 评估 yaml 元数据）
