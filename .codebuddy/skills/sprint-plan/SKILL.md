---
name: sprint-plan
description: Sprint planning facilitator. Use when user says "排 sprint / 这周做什么 / sprint plan / 下个迭代". Selects stories from backlog into the upcoming sprint based on velocity, priority, and DoR. Calls pm agent.
allowed-tools: read_file, write_to_file, list_dir, search_content
disable: false
---

# sprint-plan · Sprint 计划

## 何时加载

- 上一个 sprint 结束 / 项目首次进入开发
- 用户说"排下一周计划" / "新 sprint"
- 项目 phase 进入 dev / plan

**不加载场景**：单 story 紧急拉起 → 直接 `dev-story`；retro 后再排 → 先走 `retrospective`。

## 输入契约

| 输入 | 来源 | 必需 |
|---|---|---|
| backlog story 列表 | `projects/<name>/stories/*.md` | ✅ |
| velocity 历史 | 上 N 个 sprint 完成点数 | 推荐 |
| 团队可用性 | 用户提供 | 推荐 |
| 上 sprint retro | `projects/<name>/sprints/sprint-N-retro.md` | 推荐 |

## 流程

### Step 1 · 确定 sprint 编号 + 周期

读 `projects/<name>/sprints/`，N+1 即新 sprint 号。默认 1 周 1 sprint，可由用户指定。

### Step 2 · DoR 过滤（调用 story-readiness）

调用 `story-readiness` skill，只取 ready 的 story 进入候选池。

### Step 3 · velocity 计算

- 历史 ≥ 3 sprint：取后 3 个的中位数
- 历史 < 3 sprint：保守按 6-10 pts/sprint

### Step 4 · 委托 pm 选 story

调用 `pm` agent（opus），让它从候选池选：
- 总点数 ≤ velocity × 1.0（不超额）
- 优先 P0 → P1 → P2
- 满足依赖偏序（前置完成才能后置）
- 同 epic 内保持连续性（不跳着做）

### Step 5 · 风险评估

pm 输出 sprint 风险列表：
- 哪个 story 风险高（新技术 / 大估值 / 依赖外部）
- 缓解措施

### Step 6 · 落盘 sprint plan

按 `templates/sprint-plan.md` 填充：

```
projects/<name>/sprints/sprint-<N>-plan.md
```

包含：
- sprint 编号 / 起止日期
- 目标（1-2 句）
- 入选 story 表（id / 标题 / pts / 优先级 / 负责 agent）
- 总点数 / velocity
- 风险 + 缓解
- 排除项（候选但未选 + 理由）

### Step 7 · 同步 story 状态

将入选的 story `status` 改为 `in-progress`（或 `ready` 如未开始）。

## 输出契约

| 字段 | 内容 |
|---|---|
| `verdict` | `SPRINT_PLANNED` / `OVERFLOW:<extra-pts>` / `INSUFFICIENT_READY` |
| `sprint_id` | sprint-N |
| `selected_stories` | [...] |
| `total_points` | int |
| `risk_count` | int |

## 调用的 agent

- `pm`（opus，主笔）
- `producer`（opus，跨项目优先级仲裁）

## 加载的 rule

- `commit-discipline`（sprint-plan commit 用 [story] tag）
- `project-structure`

## 失败 / 降级

| 异常 | 策略 |
|---|---|
| ready story 总点数 < velocity | 提示用户 backlog 不足，调 `create-stories` 补 |
| velocity 无历史 | 默认 6-10 pts，标注"首 sprint 估值高风险" |
| 选出的 story 依赖未在 sprint 内 | 退回选别的或显式包入 |

## 验收标准

- sprint plan 落盘 + story 状态同步
- 总点数 ≤ velocity × 1.0
- 0 依赖错位
- 风险 ≥ 1 条（除非 sprint 全是 ≤ 2pt 安全任务）

## Known Limitations

- velocity 计算粗（不分人）
- 跨 sprint 风险传递（如某 story 跨 2 sprint）支持简单（仅标注）
