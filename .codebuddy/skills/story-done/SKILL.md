---
name: story-done
description: Story closure flow. Use when user says "story 做完了 / mark done / 关 story / S1-02 完成". Verifies AC coverage, updates status, runs consistency-check, and archives.
allowed-tools: read_file, write_to_file, list_dir, search_content
disable: false
---

# story-done · Story 收尾签收

## 何时加载

- `dev-story` 完成最后一步要正式关
- 用户说"标 done" / "S1-02 收尾"

**不加载场景**：story 还在开发中 → `dev-story` 继续；草稿 → `create-stories`。

## 输入契约

| 输入 | 来源 |
|---|---|
| story 文件 | `projects/<name>/stories/S<N>-<NN>-*.md` |
| 关联 commits | git log |
| 测试结果 | 测试输出 |

## 流程

### Step 1 · DoD 校验

逐条对 story 的 Definition of Done：
- [ ] 所有 AC 覆盖（单测或人工验收）
- [ ] reviewer APPROVED
- [ ] commit 已 push（或本地已落）
- [ ] 文档更新（如需）

任一未满足 → 不能 done。

### Step 2 · 调用 consistency-check

跑 `consistency-check` skill 在本 story 范围内：
- GDD 锚定 ↔ 实际代码
- 数值 ↔ 代码常量
- ADR ↔ 代码模式

verdict 为 CLEAN 才进 Step 3。

### Step 3 · 更新 story 状态

修改 story 文件 frontmatter：
```yaml
status: done
completed-at: <ISO date>
final-commit: <sha>
```

### Step 4 · 更新 epic 进度

读 epic，更新"已完成 stories"段：
```
- [x] S1-02 (commit abc123)
```

如 epic 全部 done → 标 epic.status = done。

### Step 5 · 更新 sprint 进度

在 sprint plan 中勾选本 story。

### Step 6 · 输出 done 报告

简短一段：
- story 标题
- 完成的 AC
- commit hash
- 总耗时（如可估）

可选：附加 sprint 速览（剩余 pts / 已完成 pts）。

## 输出契约

| 字段 | 内容 |
|---|---|
| `verdict` | `DONE` / `BLOCKED:<reason>` |
| `story_id` | S<N>-<NN> |
| `epic_progress` | x/y stories done |
| `sprint_progress` | x/y pts done |

## 调用的 agent

- `qa` (sonnet)（DoD 复核）
- 必要时 `qa-lead` (opus)（如有疑义）

## 加载的 rule

- `commit-discipline`

## 失败 / 降级

| 异常 | 策略 |
|---|---|
| AC 未全覆盖 | 退回 `dev-story` 补 |
| consistency-check DIRTY | 必修，不能 done |
| commit 缺失 | 强制让用户先 commit |

## 验收标准

- DoD 全勾
- consistency-check CLEAN
- story / epic / sprint 三级状态同步

## Known Limitations

- "总耗时"靠 git 第一 commit 到最后 commit 时间差，粗
- 跨人协作的 attribution 缺
