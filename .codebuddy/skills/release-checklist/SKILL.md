---
name: release-checklist
description: Release readiness checklist runner. Use when user says "发版 / release / 准备发布 / ship it". Phase 1 ships a placeholder + router; full 4-level checklist (pre / RC / live / post) lands in Phase 4.
allowed-tools: read_file, write_to_file, list_dir
disable: false
---

# release-checklist · 发版检查清单

## 何时加载

- 项目接近发布
- 用户说"发版 / release / RC"

**不加载场景**：未到 test phase（先走 `milestone-review`）。

## 输入契约

| 输入 | 来源 | 必需 |
|---|---|---|
| 项目 phase | `PROJECT.md` | ✅ |
| 全部 epics 状态 | `epics/index` | ✅ |
| 最近 smoke 报告 | `sprints/sprint-*-smoke.md` | ✅ |

## 流程（Phase 1 占位）

### Step 1 · phase 校验

如 `PROJECT.md.phase` 不在 {test, release} → `BLOCKED`，提示先走 `milestone-review`。

### Step 2 · 占位 4 级 checklist 框架

输出**结构占位**：

```
### Level 1 · Pre-release（代码冻结）
- [ ] 全部 P0 epic done
- [ ] 全部测试通过
- [ ] consistency-check CLEAN
- [ ] [Phase 4 TODO] 详细项

### Level 2 · RC（候选发布版）
- [ ] [Phase 4 TODO]

### Level 3 · Live（发布日）
- [ ] [Phase 4 TODO]

### Level 4 · Post-release（发布后 24-72h）
- [ ] [Phase 4 TODO]
```

### Step 3 · 委托 release-manager

调用 `release-manager` agent (opus)：
- 评估当前是否满足 Level 1
- 给出版本号建议
- 起草 release notes 骨架

### Step 4 · 落盘

`projects/<name>/releases/v<version>-checklist.md`

### Step 5 · 输出

verdict：
- `READY_FOR_RC`：Level 1 全过
- `BLOCKED:<items>`：Level 1 未全过
- `PHASE_4_TODO`：Level 2-4 仍占位（Phase 4 完整版）

## 输出契约

| 字段 | 内容 |
|---|---|
| `verdict` | `READY_FOR_RC` / `BLOCKED:<n>` / `PHASE_4_TODO` |
| `checklist_path` | releases/v*-checklist.md |
| `version` | 建议版本号 |

## 调用的 agent

- `release-manager` (opus)（主笔）
- `qa-lead` (opus)（质量复核）

## 加载的 rule

- `commit-discipline`（tag 命名）

## 失败 / 降级

| 异常 | 策略 |
|---|---|
| phase 未到 | 拒绝 + 路由 `milestone-review` |
| release-manager 缺数据 | 列出缺项 |

## 验收标准

- checklist 落盘
- Level 1 项目至少明确每项状态
- 版本号建议有理由

## Known Limitations

- Level 2-4 详细 checklist 在 Phase 4 完成
- tag 命名规范 / hotfix 分支策略 Phase 2 决议
- release notes 模板未建（按需）
