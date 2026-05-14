---
name: dev-story
description: Heavy-channel development workflow for a single user story (ready to done). Use when user says "做 S1-02 / 实现这个 story / develop story / 开发这个任务". Drives engineer + tester + reviewer through code → test → review → commit, with consistency-check gating before done.
allowed-tools: read_file, write_to_file, list_dir, execute_command, search_content, replace_in_file
disable: false
---

# dev-story · Story 开发主流程（重通道）

## 何时加载

- 一个 ready 的 story 进入 in-progress
- 用户明确说"开发 S<N>-<NN>"
- `sprint-plan` 选定本 story 后由用户主动启动

**不加载场景**：< 30 分钟的小修 → `quick-fix`；架构决策 → `architecture-decision`。

## 输入契约

| 输入 | 来源 | 必需 |
|---|---|---|
| story 文件 | `projects/<name>/stories/S<N>-<NN>-*.md` | ✅ |
| GDD 锚定章节 | story 中 gdd-anchor | ✅ |
| 引擎 | `PROJECT.md` | ✅ |
| 相关 ADR（如有） | story.adr-refs | 推荐 |
| commit-discipline rule | 强制 | ✅ |

## 流程

### Step 1 · 任务展开

读 story + GDD + ADR，让 engineer agent 给出最小实现计划：
- 文件变更清单（新增 / 修改）
- 单元测试计划
- 风险点

### Step 2 · 编码（engineer / 引擎 specialist）

按 story 的引擎选择：
- godot → `godot-gdscript` (Haiku) + `godot-scene` (Haiku) 协同
- unity → `unity-csharp` + `unity-scene`
- unreal → `unreal-cpp` 或 `unreal-blueprint`

通用逻辑由 `engineer` (sonnet)。

每次写完代码：
```
godot --headless --check-only --path projects/<name>/game --quit
```
验证语法，有错自己修。

### Step 3 · 单元测试（tester）

调用 `tester` agent (sonnet) 写覆盖关键 AC 的单元测试。框架：
- godot → GUT
- unity → NUnit / Unity Test Framework
- unreal → AutomationTest

跑测试，全绿才进 Step 4。

### Step 4 · code review（reviewer）

调用 `reviewer` agent (sonnet) 给 verdict：
- `APPROVED`
- `CHANGES_REQUESTED`（具体条目）
- `BLOCKED`（架构问题，升级 architect）

如 CHANGES_REQUESTED → 回 Step 2。

### Step 5 · consistency-check（gating）

调用 `consistency-check` skill：
- GDD 锚定章节 vs 实际代码行为 是否一致
- 数值表 vs 代码常量 是否一致
- ADR 决策 vs 代码模式 是否一致

verdict：
- `CLEAN` → 进 Step 6
- 有冲突 → 修代码或更新 GDD（决策权 designer/architect）

### Step 6 · commit

按 `commit-discipline` rule：
```
[story] <project>/<story-id>: <80 字内描述>

- 关键变更
- 验收覆盖：AC1, AC2, ...

Story: <path>
```

如 hooks 启用，validate-commit + pre-commit-lite 会自动跑。

### Step 7 · story 状态推进

调用 `story-done` skill 完成最终签收（更新 status / 归档）。

## 输出契约

| 字段 | 内容 |
|---|---|
| `verdict` | `DONE` / `IN_PROGRESS:<step>` / `BLOCKED:<reason>` |
| `commit_sha` | commit hash |
| `files_changed` | 文件列表 |
| `tests_passed` | bool |
| `consistency` | CLEAN / DIRTY |

## 调用的 agent

- `engineer` (sonnet) 或引擎 specialist (haiku)
- `tester` (sonnet)
- `reviewer` (sonnet)
- 出问题升级 `architect` (opus) / `qa-lead` (opus)

## 加载的 rule

- `commit-discipline`（强制 [story] tag）
- `test-standards`（测试金字塔）
- `language-policy`
- `project-structure`

## 失败 / 降级

| 异常 | 策略 |
|---|---|
| Godot 校验报错 | engineer 自修 → 再校验，3 次失败升级 architect |
| 单元测试失败 | debugger agent 介入 |
| reviewer BLOCKED | 调 `architecture-decision` 起新 ADR |
| consistency-check DIRTY | 决策：改代码 or 改 GDD（designer 仲裁） |
| commit hook 失败 | 修 commit message 或排查 hook |

## 验收标准

- AC 全部覆盖（单元测试或人工验证）
- code review APPROVED
- consistency-check CLEAN
- commit 通过 hook
- story.status = `done` （由 `story-done` 落定）

## Known Limitations

- 单元测试覆盖率无强制阈值（test-standards 建议 ≥ 60%）
- 跨 story 联调依赖人工 smoke
