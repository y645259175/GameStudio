---
name: create-stories
description: Break an epic into actionable user stories. Use when user says "拆 story / 把 epic 切小 / story breakdown / 写任务卡". Each story has acceptance criteria, GDD anchor, estimate (1-5 pts), and is sprint-deliverable.
allowed-tools: read_file, write_to_file, list_dir
disable: false
---

# create-stories · Epic → Story 拆分

## 何时加载

- 某个 epic 即将进入 sprint 计划
- 用户说"把 E1 拆成 stories"
- `sprint-plan` 调用本 skill

**不加载场景**：epic 尚未拆完（走 `create-epics`）；story 已存在仅修改（走 `quick-fix` 或直接编辑）。

## 输入契约

| 输入 | 来源 | 必需 |
|---|---|---|
| Epic 文件 | `projects/<name>/epics/E<N>-*.md` | ✅ |
| GDD 锚定章节 | epic 中 gdd-anchor | ✅ |
| 团队 velocity（pt/sprint）| `PROJECT.md` 或历史 retro | 推荐 |

## 流程

### Step 1 · 读 epic + 锚定章节

并行：
- `read_file projects/<name>/epics/E<N>-*.md`
- `read_file projects/<name>/gdd/<chapter>.md`

### Step 2 · 委托 pm 拆 story

调用 `pm` agent（opus），让它：
- 拆 5-10 个 story
- 每个 1-5 点（5 点为上限，超过要再拆）
- 总点数 ≤ 团队 1 sprint velocity 的 1.5 倍（留缓冲）

### Step 3 · 每个 story 必备字段

```yaml
---
id: S<N>-<NN>-<slug>
epic: E<N>
priority: P0/P1/P2
estimate: 1/2/3/5
status: ready/in-progress/done/blocked
gdd-anchor: gdd/<chapter>.md#<section>
adr-refs: []  # 可选
---

# S<N>-<NN>: <title>

## 用户故事
> 作为 <角色>，我想 <动作>，以便 <价值>

## 验收标准（AC）
1. ...
2. ...
3. ...

## 实现要点
（不是详细设计，是关键节点提示）

## Definition of Done
- [ ] 单元测试通过
- [ ] reviewer 评审通过
- [ ] 文档更新

## 依赖
- 前置 story: [...]
- 阻塞项: [...]
```

### Step 4 · DoR (Definition of Ready) 自检

每个 story 必须满足 DoR 才落盘（用 `story-readiness` skill 思路）：
- 有 ≥ 3 条 AC
- 有 GDD 锚
- 估值确定
- 无未解决的阻塞依赖

不满足 → 标 `status: draft` 或丢回 epic 待补。

### Step 5 · 落盘

每个 story 一个文件：`projects/<name>/stories/S<N>-<NN>-<slug>.md`

更新 `epics/E<N>-*.md` 的"实际 stories"段。

### Step 6 · 输出 story 索引

```
| ID | Story | Epic | Pts | Status |
|---|---|---|---|---|
```

## 输出契约

| 字段 | 内容 |
|---|---|
| `verdict` | `STORIES_READY` / `STORIES_DRAFT:<count>` |
| `story_ids` | [S1-01, S1-02, ...] |
| `total_points` | int |
| `next_skill` | `sprint-plan` |

## 调用的 agent

- `pm`（opus，主笔）
- `designer`（opus，仅在 GDD 锚不清晰时）
- `reviewer`（sonnet，DoR 复核）

## 加载的 rule

- `design-authoring`（AC 格式）
- `project-structure`

## 失败 / 降级

| 异常 | 策略 |
|---|---|
| 单 story > 5 pts | 强制再拆 |
| AC < 3 条 | 标 draft，要求补 |
| 总点数 > 2× velocity | 缩 scope 或分两个 sprint |

## 验收标准

- 5-10 个 story
- 全部 ≤ 5 pts
- 全部满足 DoR 或明确标 draft
- 0 悬空 GDD 锚（每个 story 锚定的章节都存在）

## Known Limitations

- velocity 估算依赖历史数据，新项目首次估为 +-30%
- AC 自然语言化，自动化校验难（依赖 reviewer 语义判断）
