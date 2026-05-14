---
name: story-readiness
description: Definition-of-Ready (DoR) check. Use when user says "story 准备好了吗 / DoR check / 入 sprint 前审 / ready check". Verifies a story has acceptance criteria, GDD anchor, estimate, and no blocking deps before entering a sprint.
allowed-tools: read_file, list_dir, search_content
disable: false
---

# story-readiness · DoR 入站校验

## 何时加载

- sprint 计划之前对候选 story 做最后审
- 用户说"这些 story 能进 sprint 吗"
- `sprint-plan` skill 调用本 skill

**不加载场景**：story 已在 sprint 中（走 `dev-story`）；story 尚未拆（走 `create-stories`）。

## 输入契约

| 输入 | 来源 |
|---|---|
| story 文件列表 | `projects/<name>/stories/*.md` |
| 候选 story IDs | sprint plan 草稿 |

## 流程

### Step 1 · 加载所有候选 story

```
read_file projects/<name>/stories/S<N>-<NN>-*.md
```

### Step 2 · 7 项 DoR 检查

每个 story 跑：

| # | 检查项 | 期望 |
|---|---|---|
| 1 | frontmatter 完整 | id / epic / priority / estimate / gdd-anchor 字段都在 |
| 2 | 用户故事 | "作为 X，我想 Y，以便 Z" 完整 |
| 3 | AC 数量 | ≥ 3 条 |
| 4 | AC 可衡量 | 不含"很好玩 / 流畅"等主观词 |
| 5 | GDD 锚有效 | gdd-anchor 指向的章节存在 |
| 6 | 估值合理 | 1-5 pts |
| 7 | 阻塞依赖 | depends-on 中的前置 story 全 done |

### Step 3 · 输出每条 story verdict

| Story | DoR | 缺项 |
|---|---|---|
| S1-01 | ✅ | — |
| S1-02 | ❌ | AC < 3 / GDD 锚悬空 |

### Step 4 · 升级或修复

- 缺项 ≤ 1 → 建议立即修
- 缺项 ≥ 2 → 退回 `create-stories` 补
- 阻塞依赖未完成 → 排到下个 sprint

### Step 5 · 输出 ready set

返回可进 sprint 的 story IDs 集合。

## 输出契约

| 字段 | 内容 |
|---|---|
| `verdict` | `ALL_READY` / `PARTIAL_READY:<n>/<total>` / `BLOCKED` |
| `ready_ids` | [S1-01, S1-03] |
| `not_ready_ids` | [{id, missing_items}] |

## 调用的 agent

- `pm`（sonnet，复核估值与依赖）
- `reviewer`（sonnet，AC 可衡量性判断）

## 加载的 rule

- `design-authoring`

## 失败 / 降级

| 异常 | 策略 |
|---|---|
| GDD 锚悬空 | 必须修，否则不能 ready |
| 估值缺失 | pm 立即补 |
| 阻塞依赖在另一 sprint | 标 `defer` |

## 验收标准

- 100% story 跑过 7 项检查
- ready_ids 中无 1 个有缺项
- 输出可被 sprint-plan 直接消费

## Known Limitations

- "AC 可衡量"靠语义判断（reviewer 主观）
- 依赖追溯仅 1 层（Phase 2 评估深度依赖图）
