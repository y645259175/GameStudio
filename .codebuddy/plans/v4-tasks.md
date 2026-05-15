# v4 工作室孵化器 · 总进度面板

> **用途**：工作室建设和首个验证项目（breakout）的全周期进度面板。
>
> **状态图例**：`[x]` 完成 / `[~]` 进行中 / `[ ]` 未开始 / `[!]` 阻塞
>
> **最后更新**：2026-05-15 14:51

---

## 总览

| 阶段 | 状态 | 备注 |
|---|---|---|
| Phase 1 · 工作室基础设施（12 批） | ✅ 完成 | 21 agent / 22 skill / 6 rule / 11 template / 5 hook |
| Phase 1.5 · reference 归位 | ✅ 完成 | `analysis-report/` `my-game/` 移入 `studio/reference/` |
| Phase 2 · Git 初始化 | ✅ 完成 | git init + tag `v4-foundation` |
| Breakout 验证项目 | ✅ 可玩 | 5 关 / 5 道具 / 49 自动化测试 / AI 美术 |
| B 流程验证（数据驱动 + GDD 三原则） | ✅ 完成 | ConfigLoader + GDD 重写 + consistency-check |
| 工作室能力补强（v2） | ✅ 完成 | hook 改造为 CodeBuddy 原生 + Team Mode SOP + PATCHES + qa-gate + scope-check + validate-assets |

---

## 当前能力库

| 类别 | 数量 | 关键代表 |
|---|---|---|
| **agent** | 21 | producer / pm / architect / qa-lead / designer / art-director / **ux-designer** / engineer / debugger / reviewer / refactorer / tester / qa / docs-writer / postmortem-keeper / release-manager / godot-architect / godot-gdscript / godot-scene / godot-renderer / godot-perf |
| **skill** | 25 | start / help / new-project / setup-engine / design-review / quick-design / review-all-gdds / architecture-decision / create-epics / create-stories / story-readiness / sprint-plan / dev-story / quick-fix / story-done / daily-check / smoke-check / retrospective / consistency-check / **qa-gate** / **scope-check** / art-asset-pipeline / milestone-review / release-checklist / timiai-image |
| **rule** | 7 | project-structure（4 层架构 + 16 子目录）/ commit-discipline / design-authoring（含三原则）/ language-policy / data-driven / test-standards / **patches**（自我迭代） |
| **hook** | 6 | validate-commit / pre-commit-lite / **session-start**（CodeBuddy SessionStart）/ **log-agent**（PostToolUse）/ **detect-gaps**（Stop）/ **validate-assets** |
| **template** | 12 | PROJECT.md.tpl / gdd-8-sections / story / epic / sprint-plan / retro / adr / consistency-report / ux-spec / hud / accessibility / daily-report / **patch** |
| **studio docs** | 6 | studio-handbook（含 Pitfalls）/ language-policy / collaboration-protocol / workflow-guide / **team-mode-sop** / engine-reference（48 文件） |

---

## 已知能力 vs 计划差距（来自 v4 §5 TODO 队列）

| 计划项 | 当前状态 |
|---|---|
| `qa-gate` skill | ✅ 完成 |
| `scope-check` skill | ✅ 完成 |
| `validate-assets.sh` hook | ✅ 完成 |
| PATCHES 自我迭代机制 | ✅ 完成（rule + template） |
| PromptX-style SubAgent | ✅ 已落实（agent frontmatter）|
| 项目初始化引导 skill | ✅ `new-project` 已实现 |
| 引擎选择 | ✅ Godot 4.6.2 已锁 |
| `quick-design` skill | ✅ 已做 |
| `producer` agent | ✅ 已装 |
| `release-prep` skill | ⏳ 推迟（用 `release-checklist` Phase 4 完整版替代） |
| `post-launch` skill | ⏳ 推迟（Phase 4 决定） |
| `validate-push.sh` hook | ⏳ 推迟（实战需要时再加） |
| `adopt` skill（接手已有项目）| ⏳ 推迟 |
| `dev-story` 双通道分流强化 | ⚠️ 部分（边界已写，自动检测未做） |
| `/help` 双通道指引补全 | ⚠️ 部分 |
| `retrospective` 跨 sprint 汇总 | ⚠️ 部分（有历史 action 跟踪，缺 velocity 趋势）|
| `smoke-check` 分级 | ⏳ 推迟 |
| CI/CD 策略 | ⏳ Phase 3-4 项 |

---

## Phase 1 · 12 批历史（仅作回溯）

| # | 批次 | 状态 |
|---|---|---|
| 1 | 目录骨架 | ✅ |
| 2 | language-policy | ✅ |
| 3-5 | skill 22 个（三轮）| ✅ |
| 6 | hook 5 个 | ✅（后续重做为 CodeBuddy 原生）|
| 7-8 | agent 30 个 | ✅（后删 unity/unreal 10 个，留 21）|
| 9 | rule 6 个 | ✅ |
| 10 | template 9 个 | ✅ |
| 11 | engine-reference 占位 48 | ✅ |
| 12 | 收尾一致性扫 | ✅ |

---

## Breakout 验证项目（详见 `projects/breakout/`）

| Sprint | Stories | 状态 |
|---|---|---|
| Sprint 1 | S1-01 ~ S1-05（10 pts）| ✅ |
| Sprint 2 | S2-01 ~ S2-07（12 pts）| ✅ |

| Epic | 状态 |
|---|---|
| E1 核心玩法 | ✅ |
| E2 计分 HUD | ✅ |
| E3 道具系统 | ✅ |
| E4 多关卡 | ✅ |
| E5 菜单打磨 | ✅ |

| 测试 | 数量 |
|---|---|
| Levels Data | 21 |
| GameManager | 19 |
| PowerupManager | 9 |
| **Total** | **49 PASS** |

| VFX 实现 | P0 全部 + P1 全部 |
|---|---|
| VFX-01..VFX-07 + VFX-10 | ✅ |
| VFX-08 关卡过渡 | ⏳ P2 推迟 |
| VFX-09 Game Over 慢放 | ⏳ P2 推迟 |

---

## 关键修正记录

| 时间 | 修正 |
|---|---|
| 2026-05-14 | frontmatter 规范修正（rule .mdc / skill / agent 三套）|
| 2026-05-14 | bg 重生成（gpt-image-2 替代 gemini fallback）|
| 2026-05-14 | 球穿砖块 bug → 碰撞改 _physics_process |
| 2026-05-14 | 类型推断错（abs → absf, := → 显式类型）|
| 2026-05-14 | UI anchors_preset=8 失效 → 改全宽 + horizontal_alignment |
| 2026-05-15 | data-driven "假做" → ConfigLoader autoload 改造 |
| 2026-05-15 | multi_ball → clear_row 命名修正 |
| 2026-05-15 | UX 文字反馈 / VFX-07 buff 计时条 |
| 2026-05-15 | hook 重大认知修正：CodeBuddy 完全兼容 Claude Code Hooks → 3 个骨架 hook 重写为真正可用 |
| 2026-05-15 | Team Mode 验证可用 → SOP 文档 |
| 2026-05-15 | 新增 ux-designer agent + design-authoring 三原则 |

---

## 待办（按优先级）

### 🔴 P0 · 现在做（短小确定）

无。

### 🟡 P1 · 下一个项目实战时验证

| # | 项 | 触发场景 |
|---|---|---|
| 1 | skill 串联流程实战验证 | 开新项目时跑 start → new-project → design-review → create-epics → ... 完整链 |
| 2 | Team Mode 在 design-review / consistency-check / smoke-check 中改造为并行 | 这些 skill 实际被调用时 |
| 3 | PATCHES 机制首次使用 | 在新项目实战中遇到 skill 描述问题 |
| 4 | unused agent 实战验证 | postmortem-keeper / release-manager 等未实战过的 |

### 🟢 P2 · 远期 / 按需

| # | 项 | 触发场景 |
|---|---|---|
| 1 | VFX-08/09（关卡过渡 + Game Over 慢放）| breakout 后续 polish |
| 2 | release-prep / post-launch skill | 真要发版时 |
| 3 | validate-push.sh hook | 接入 GitHub 远程仓库后 |
| 4 | adopt skill | 需要接手已有项目时 |
| 5 | dev-story 双通道自动判定 | 出现多次"该走哪个 skill"误判时 |
| 6 | retrospective velocity 趋势 | sprint 数 ≥ 5 后 |
| 7 | smoke-check 分级 | sprint 内多次冒烟时 |
| 8 | CI/CD（GitHub Actions）| Phase 3-4 |
| 9 | 引擎参考标准化 | 需要在 reference 中搜索时 |

---

## 阻塞 / 决策记录

| 时间 | 决策 | 影响 |
|---|---|---|
| 2026-05-14 | 抽出 v4-tasks.md 独立任务面板 | 进度可视化 |
| 2026-05-14 | language-policy 薄壳模式 | rule 指向完整版 |
| 2026-05-14 | engine 选 Godot | 锁定首个引擎 |
| 2026-05-14 | engine/ 进 git | 协作者版本一致 |
| 2026-05-14 | 删除 unity/unreal 10 agent | godot-only |
| 2026-05-14 | multi_ball 简化为清行（ADR-0001）| Phase 2 重做真正多球 |
| 2026-05-15 | data-driven 全面推进（ConfigLoader + GDD 重写）| 所有数值统一外置 |
| 2026-05-15 | hook 全面重做为 CodeBuddy 原生 | 3 个骨架激活 |
| 2026-05-15 | 新增 ux-designer 角色（执行者）| art-director 仅审核 |
