# v4 工作室孵化器迁移 · 任务面板

> **用途**：12 批进度面板，一眼可见状态。每批完成时勾选并补完成时间 + 链接到 `v4-migration-log.md` 对应 Step。
>
> **关联文档**：
> - 整体规划：[`studio-incubator-migration-v4_4b2c7a91.md`](./studio-incubator-migration-v4_4b2c7a91.md)（决策档案，已定稿）
> - 执行日志：[`v4-migration-log.md`](./v4-migration-log.md)（事后审计档案，按时间追加）
> - 本文件：12 批任务面板（执行进度，每批完成时同步）
>
> **状态图例**：`[x]` 完成 / `[~]` 进行中 / `[ ]` 未开始 / `[!]` 阻塞
>
> **最后更新**：2026-05-14 17:32

---

## Phase 1 · 12 批任务总览

| # | 批次 | 起草产物 | 回写方式 | 状态 | 完成时间 | 日志链接 |
|---|---|---|---|---|---|---|
| 1 | 目录骨架 | 13 目录 + 5 文件（reference/README + log + 3 .gitkeep） | AI 自主 | `[x]` | 2026-05-14 11:05 | Step 1 |
| 2 | language-policy | `studio/docs/language-policy.md` 完整版 | **3 步回写** | `[x]` | 2026-05-14 14:02 | Step 2 |
| 3 | skill 第一轮（工作室级 7 个） | start / daily-check / smoke-check / retrospective / consistency-check / release-checklist / new-project | AI 自主 + 抽查 | `[x]` | 2026-05-14 14:13 | Step 3 |
| 4 | skill 第二轮（7 个） | help + 项目级纯流程 6 个：create-stories / create-epics / sprint-plan / design-review / review-all-gdds / story-readiness | AI 自主 + 抽查 | `[x]` | 2026-05-14 14:48 | Step 4 |
| 5 | skill 第三轮（8 个） | 项目级纯流程 3 个：quick-design / milestone-review / story-done + 带占位路由 4 个：dev-story / quick-fix / architecture-decision / setup-engine + 美术 1 个：art-asset-pipeline | AI 自主 + 抽查 | `[x]` | 2026-05-14 14:58 | Step 5 |
| 6 | hook 实现（5 个） | validate-commit.sh / pre-commit-lite.sh / log-agent.sh / session-start.sh / detect-gaps.sh | **3 步回写** | `[x]` | 2026-05-14 15:50 | Step 6 |
| 7 | agent 第一轮（15 个） | 职务 5（producer / pm / designer / engineer / qa）+ 代码 5（architect / debugger / reviewer / refactorer / tester）+ engine-specialist 5（godot 全 5：architect/gdscript/scene/renderer/perf）| AI 自主 + 抽查 | `[x]` | 2026-05-14 16:18 | Step 7 |
| 8 | agent 第二轮（15 个） | engine-specialist 余 10（unity-5 / unreal-5）+ 其他 5（art-director / qa-lead / release-manager / postmortem-keeper / docs-writer） | AI 自主 + 抽查 | `[x]` | 2026-05-14 16:25 | Step 8 |
| 9 | rule（6 个） | commit-discipline / design-authoring / **language-policy（薄壳）** / project-structure / data-driven / test-standards | **3 步回写** | `[x]` | 2026-05-14 16:42 | Step 9 + frontmatter 修正 |
| 10 | template（9 个） | PROJECT.md.tpl / gdd-8-sections / retro / consistency-report / adr / sprint-plan / ux-spec / hud / accessibility | AI 自主 | `[x]` | 2026-05-14 16:48 | Step 10 |
| 11 | engine-reference 占位（45+3） | 45 个引擎占位文件 + 3 个引擎 README（godot/unity/unreal） | AI 自主 | `[x]` | 2026-05-14 16:55 | Step 11 |
| 12 | 收尾一致性扫 | 引用闭合扫描 + 修复 + Phase 1.5 归位准备 + log 封版 | **3 步回写** | `[x]` | 2026-05-14 17:00 | Step 12 |

**进度**：12 / 12 已完成（100%）🎉 · **Phase 1 全部完成**

---

## Phase 1.5 · 用户手动归位（Phase 1 全部完成后）

| # | 任务 | 操作主体 | 状态 |
|---|---|---|---|
| 1 | 建子目录 `studio/reference/{analysis-report,my-game}/` | 用户 PowerShell | `[x]` |
| 2 | `Move-Item analysis-report studio/reference/` | 用户 PowerShell | `[x]` |
| 3 | `Move-Item my-game studio/reference/` | 用户 PowerShell | `[x]` |
| 4 | 验证：根目录无 analysis-report / my-game / `studio/reference/` 子目录就位 | AI 验证通过 | `[x]` |
| 5 | 进入 Phase 2 | 用户 confirm | `[~]` |

操作手册：见 v4 §6.1.4

---

## Phase 2 · git init（Phase 1.5 完成后）

| # | 任务 | 状态 |
|---|---|---|
| 1 | `git init` 工作区根 | `[x]` |
| 2 | `git add -A && git commit -m "[story] v4 foundation: studio incubator migration phase 1+1.5 complete"` | `[x]` |
| 3 | `git tag v4-foundation` | `[x]` |

之后进入 Phase 2 的 skill 自我消化 / Phase 3 的真实项目落地（详见 v4 §6.5）。

---

## 抽查记录

> 用户在批 3 / 5 / 8 等机械批后抽查产出的反馈记录，便于后续批次参考。

| 批 | 抽查样本 | 反馈 | 修订 |
|---|---|---|---|
| 1 | reference/README.md | 待用户抽查 | — |
| 3 | start / daily-check / release-checklist（建议）| 待用户抽查 | — |

---

## 阻塞 / 决策记录

> 执行过程中临时拍板的关键决策，避免散落在对话历史里找不到。

| 时间 | 上下文 | 决策 | 影响 |
|---|---|---|---|
| 2026-05-14 14:13 | 批 2 后 §6.1.1 目录树发现 language-policy.md 落盘冲突 | **B 方案**：`.codebuddy/rules/language-policy.md` 写薄壳指向 `studio/docs/language-policy.md` | 批 9 起草 rule 时按薄壳模式写 |
| 2026-05-14 14:46 | 批 3 完成后用户提出"plan 模式但已在执行"问题 | **B 方案**：抽出 v4-tasks.md 作为独立任务面板 | 进度可视化，plan 文档保持决策档案纯净 |
