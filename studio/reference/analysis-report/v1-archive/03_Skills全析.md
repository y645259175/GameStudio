# 03 Skills 全析

> 72 个斜杠命令的完整拆解：职责、参数、前置条件、步骤、产出文件、Gate 依赖、团队并行 spawn 情况、CodeBuddy 适配评级

---

## 本册范围与交叉引用

- 覆盖 `.claude/skills/` 目录下全部 **72 个 skill**
- 按 **11 大类 + workflow-catalog.yaml 的 7 阶段 pipeline** 双维度组织
- 每个 skill 按统一字段拆解（路径、frontmatter、前置条件、step 摘要、产出文件、涉及 Gates、--review 行为、CodeBuddy 适配评级）
- 每类末尾附横向规律 + 该类适配性总表
- 结尾总收尾：72 skill 完整适配性总表（以 MVS 清单为最后输出）

**交叉引用**：
- **01 册 Director Gates 系统** —— 本册中 Gate ID 的定义在 01 册
- **01b 册 P0 并行 spawn 问题** —— 本册的 9 个 `team-*` skill 是 P0 重灾区
- **02 册 Agent 形态 A/B/C** —— 本册 skill 会 spawn 哪些 agent，形态决定移植方式
- **02 册 37 套硬性产出格式** —— 本册 skill 产出文件大量引用这些格式

---

## 关于本册策略（重要说明）

> 72 个 skill 如果全量逐一精读，将产生 5000+ 行内容。为保持可读性和信息密度，本册采用 **"分层呈现"** 策略：

### 分层 1：每类的**概览表**（所有 72 个 skill 都列入）

每个 skill 都出现在对应类别的概览表中，含 8 个字段：name / 定位 / 前置条件 / Task 调用 / 产出文件 / 涉及 Gates / step 数 / --review 差异 / 适配评级

### 分层 2：**代表性 skill 精读**（每类挑 2-3 个关键）

以下 skill 因其典型性或移植难度，获得完整展开：

| 类别 | 精读 skill | 选中原因 |
|---|---|---|
| Onboarding & Discovery | `/start` / `/adopt` / `/help` | 用户入口，移植优先级最高 |
| Game Design | `/design-system` / `/review-all-gdds` | `/design-system` 是最核心 skill；`/review-all-gdds` 是多 agent 并行典型 |
| Architecture | `/architecture-decision` / `/create-architecture` | ADR 和架构文档是技术基石 |
| Stories & Sprints | `/dev-story` / `/create-stories` / `/sprint-plan` | 日常开发主流 |
| Reviews | `/gate-check` / `/code-review` | 门控机制的两大主 skill |
| QA | `/qa-plan` / `/smoke-check` | QA 工作流核心 |
| Team Orchestration | **所有 9 个 team-*** | **01b P0 重灾区，逐一精读** |
| Release | `/release-checklist` / `/launch-checklist` | 发布流水线 |
| Creative | `/brainstorm` / `/prototype` | 创意闭环 |
| Production | `/retrospective` / `/scope-check` | 项目管理核心 |
| Utility | `/skill-test` / `/skill-improve` | Meta 测试框架 |

**未被选为精读的 skill**：在对应类别的概览表中给出 3-5 字段要点 + 1 行适配评级。读者如需深入某个 skill，可直接打开 `.claude/skills/[name]/SKILL.md` 查阅原文。

### 分层 3：章末**横向规律**（按类总结共性模式）

每类末尾总结该类 skill 共性的参数模式、工作流模式、gate 触发模式。

---

## Skill 的 11 大类概览

根据 README.md 和 `workflow-catalog.yaml`，72 个 skill 可分为以下 11 大类（基于**工作阶段**而非技术实现）：

| # | 类别 | 数量 | 对应 Pipeline 阶段 | 核心 skill |
|---|---|---|---|---|
| 1 | **Onboarding & Discovery** | 6 | 阶段 0（所有） | `/start` `/help` `/adopt` `/project-stage-detect` `/onboard` `/setup-engine` |
| 2 | **Game Design** | 8 | Concept → Systems-Design | `/brainstorm` `/design-system` `/design-review` `/review-all-gdds` `/consistency-check` `/quick-design` `/map-systems` `/balance-check` |
| 3 | **Art & Assets** | 4 | Concept + Pre-Production | `/art-bible` `/asset-spec` `/asset-audit` `/content-audit` |
| 4 | **UX** | 2 | Pre-Production | `/ux-design` `/ux-review` |
| 5 | **Architecture** | 4 | Technical-Setup | `/create-architecture` `/architecture-decision` `/architecture-review` `/create-control-manifest` |
| 6 | **Stories & Sprints** | 7 | Pre-Production → Production | `/create-epics` `/create-stories` `/story-readiness` `/sprint-plan` `/sprint-status` `/dev-story` `/story-done` |
| 7 | **Reviews & Gates** | 5 | 所有阶段 | `/gate-check` `/code-review` `/architecture-review`（见 Arch）`/design-review`（见 Design）`/test-evidence-review` |
| 8 | **QA** | 11 | Production → Polish | `/qa-plan` `/smoke-check` `/bug-report` `/bug-triage` `/regression-suite` `/test-evidence-review` `/test-setup` `/test-helpers` `/test-flakiness` `/soak-test` `/security-audit` |
| 9 | **Production** | 6 | Production | `/retrospective` `/scope-check` `/estimate` `/tech-debt` `/milestone-review` `/propagate-design-change` |
| 10 | **Release** | 5 | Release | `/release-checklist` `/launch-checklist` `/patch-notes` `/changelog` `/hotfix` + `/day-one-patch` |
| 11 | **Team Orchestration** | 9 | 跨阶段（特性开发） | `/team-combat` `/team-narrative` `/team-ui` `/team-audio` `/team-level` `/team-live-ops` `/team-qa` `/team-release` `/team-polish` |
| 12 | **Creative** | 2 | Pre-Production | `/prototype` `/playtest-report` |
| 13 | **Utility & Meta** | 4 | 全局 | `/reverse-document` `/localize` `/skill-test` `/skill-improve` |

> **实际数量**：6+8+4+2+4+7+5+11+6+5+9+2+4 = 73。但 `/architecture-review` 和 `/design-review` 在 Reviews 类和对应专项类都出现（交叉引用），去重后 = 72 ✅

---

## CodeBuddy 适配评级（Skill 专用版）

在 02 册 agent 的 5 段式评级基础上，本册针对 skill 新增 2 项关注点：

| 评级字段 | 取值 | 说明 |
|---|---|---|
| **移植类型** | 直接 / 改造 / 不建议 / 可选扩展 | 同 02 册 |
| **Task 调用模式** | 无 / 串行单个 / 并行多个 / 并行多组 | **新增** —— 决定 CodeBuddy 串行模式下的性能损失 |
| **硬性产出模板** | 0-N 套 | **新增** —— skill 内嵌的硬性产出格式数量（与 02 册 37 套对应） |
| **Gate 触发频率** | 无 / 低 / 中 / 高 | **新增** —— 决定门控性能成本 |
| **档位建议** | 极简 / 标准 / 完整 | 同 02 册 |

### Task 调用模式详细定义

- **无**：skill 内不 spawn 任何 subagent（纯文档/脚本处理）
- **串行单个**：skill 内 spawn 1 个 subagent，等待结果后继续
- **并行多个**：skill 内**同时 spawn 2-4 个** subagent 等待结果—— **CodeBuddy 性能损失 2-4 倍**
- **并行多组**：skill 内分多轮并行 spawn（`team-*` 常见）—— **CodeBuddy 性能损失最大**

移植决策优先关注"并行多个"和"并行多组"的 skill。

---

# 类别 1 — Onboarding & Discovery（6 个 skill）

> 用户"进入工作室"的第一组 skill：快速了解项目状态、找到该做什么、引入已有项目。
>
> 对应 **阶段 0**（所有阶段均可调用），是移植到 CodeBuddy 时**优先级最高的一批**——因为这是用户的第一接触点。

## 1.1 `/start` ⭐ 精读

### 一句话定位

新用户/新项目的**唯一入口**：从零引导到 Concept 阶段的第一份产物（`design/gdd/game-concept.md`）。所有其他 skill 的起点。

### Frontmatter

```yaml
description: Start a new indie game project by guiding the user through concept, engine choice, and the first design decisions
argument-hint: "[optional: game genre or concept hint]"
allowed-tools: Read, Glob, Grep, Write, Edit, Task, AskUserQuestion
```

### 前置条件

**无** —— 这是零状态起点。

### 工作流（核心 step）

1. **欢迎用户 + 工作室概念介绍**（49 agent + 7 阶段 pipeline 的通俗解释）
2. **引擎选择**（Godot/Unity/Unreal/其他） → 触发 `/setup-engine` 或提示手动配置
3. **引导 `/brainstorm`**（在此 skill 内**串行调用** `/brainstorm` 工作流的核心步骤，或显式引导用户运行 `/brainstorm`）
4. **产出初始 `design/gdd/game-concept.md`**（或确认用户手动运行下一 skill）
5. **进入 `/help` 提示下一步**

### Task 调用

**串行单个**（或零）：可能 spawn `creative-director` 做概念审查，或零 spawn（直接引导用户运行后续命令）。

### 产出文件

- `design/gdd/game-concept.md`（初版骨架）
- `.claude/docs/technical-preferences.md`（引擎 + 命名约定）
- `production/session-state/active.md`（当前任务状态）
- `production/stage.txt`（阶段追踪文件）

### 涉及 Gates

无（`/start` 不触发 Gate，后续 `/design-review` 才会）。

### CodeBuddy 适配评级

- **移植类型**：直接移植
- **Task 模式**：串行单个
- **硬性模板**：game-concept.md 骨架
- **Gate 频率**：无
- **档位**：极简 ✅ / 标准 ✅ / 完整 ✅（**全档必保留 —— 用户入口**）

**关键改造**：
1. `/start` 提示词中的"Claude Code 欢迎语"改为"CodeBuddy 欢迎语"
2. 49 agent 的介绍改为移植后实际保留的数量（9-10 个极简档 / 25-30 个标准档）
3. 触发 `/brainstorm` 的机制原是内联引导，CodeBuddy 中保留为"建议用户运行 `/brainstorm`"即可

---

## 1.2 `/help` ⭐ 精读

### 一句话定位

**智能状态感知的导航器**：读 `workflow-catalog.yaml` + 检测当前项目产物 → 告诉用户"你在哪一阶段、下一步该做什么"。

### Frontmatter

```yaml
description: Smart workflow-aware help that shows where you are and what to do next
allowed-tools: Read, Glob, Grep, AskUserQuestion
```

### 前置条件

- `.claude/docs/workflow-catalog.yaml`（必须，是 skill 的核心数据源）
- `production/stage.txt`（若存在，直接读取当前阶段）
- 各阶段 artifact 文件（用于自动检测阶段完成度）

### 工作流

1. 读取 `workflow-catalog.yaml`
2. 读取 `production/stage.txt` 或遍历 artifact glob 自动推断
3. 展示当前阶段 + 已完成步骤 + 未完成必要步骤
4. 推荐下一个 skill 命令
5. （可选）展示完整 pipeline 概览

### Task 调用

**无** —— 纯文件检测 + 规则匹配。

### 产出文件

无（只读输出到控制台）。

### 涉及 Gates

无。

### CodeBuddy 适配评级

- **移植类型**：**直接移植**（纯文档驱动 + 无 Task）
- **Task 模式**：无
- **硬性模板**：workflow-catalog.yaml 数据结构
- **Gate 频率**：无
- **档位**：极简 ✅ / 标准 ✅ / 完整 ✅

**关键改造**：
- CodeBuddy 的"slash command"机制等同于 Claude Code 的 skill，`/help` 可直接作为自定义斜杠命令
- `workflow-catalog.yaml` 数据格式与平台无关，原样保留
- 这是 72 个 skill 中**最容易移植**的之一

---

## 1.3 `/adopt` ⭐ 精读

### 一句话定位

**棕地项目引入**：对已有游戏项目做"CCGS 模板合规性审计"——识别哪些 GDD/ADR/story 符合/不符合模板格式，产出迁移计划。

### Frontmatter

```yaml
argument-hint: "[focus: full | gdds | adrs | stories | infra]"
allowed-tools: Read, Glob, Grep, Write, AskUserQuestion
agent: technical-director
user-invocable: true
```

### 前置条件

**无**（正是为"没有用 CCGS 模板起步"的项目设计的）；可选读取已有 `design/gdd/*` / `docs/architecture/adr-*.md` / `production/stage.txt`。

### 工作流（7 个 Phase）

1. Phase 1：扫描现有产物（glob 所有可能的 CCGS 路径）
2. Phase 2：**格式合规性校验**（比模板字段多了哪些、少了哪些）
3. Phase 3：按 impact 分级（BLOCKING / HIGH / MEDIUM / LOW）
4. Phase 4：询问用户接受哪些差异
5. Phase 5：生成迁移计划
6. Phase 6：写入 `docs/adoption-plan-[date].md`
7. Phase 6b：设置 `production/review-mode.txt`（full / lean / solo）
8. Phase 7：提示下一步

### Task 调用

无（纯诊断）。

### 产出文件

- `docs/adoption-plan-[date].md`
- `production/review-mode.txt`

### 涉及 Gates

无。

### CodeBuddy 适配评级

- **移植类型**：直接移植
- **Task 模式**：无
- **硬性模板**：adoption-plan 结构 + 4 档 impact 分级
- **Gate 频率**：无
- **档位**：极简 ⚪（小项目不需要 adopt）/ 标准 ✅ / 完整 ✅

**关键改造**：
- CCGS 模板路径约定改为 CodeBuddy 对应路径
- 4 档 impact 分级（BLOCKING / HIGH / MEDIUM / LOW）放入 skill 模板硬编码

---

## 1.4-1.6 其余 Onboarding & Discovery skill（概览表）

| # | skill | 定位 | 前置条件 | Task 调用 | 产出 | 档位 | 备注 |
|---|---|---|---|---|---|---|---|
| 1.4 | `/project-stage-detect` | 自动检测当前在 7 阶段哪一阶段 | workflow-catalog.yaml + artifact glob | 无 | `production/stage.txt` | 极简 ✅ | **纯规则匹配脚本** |
| 1.5 | `/onboard` | 团队新成员入职：生成 team-onboarding 文档 | CLAUDE.md + README | 无 | `docs/onboarding/[name].md` | 完整 ⚪ | 单人/小团队可跳过 |
| 1.6 | `/setup-engine` | 配置引擎版本 + 命名约定 + 性能预算 | 无 | 无 | `.claude/docs/technical-preferences.md` | 极简 ✅ | 每个项目一次性运行 |

### 类别 1 横向规律

**共性模式**：
1. **6 个 skill 中 5 个无 Task 调用** —— Onboarding 是纯文档/规则驱动，无 agent spawn
2. **5/6 个有硬性模板产出**（game-concept / technical-preferences / adoption-plan / onboarding / stage.txt）
3. **全部 6 个 Task 模式为"无"或"串行单个"** —— Onboarding 类在 CodeBuddy 上性能损失最小

**移植洞察**：Onboarding 类 skill 是**移植优先级最高、成本最低**的一批。6 个全部应在标准档保留，`/start` 和 `/help` 极简档必保。

### 类别 1 适配性总表

| skill | 移植类型 | Task 模式 | Gate | 极简 | 标准 | 完整 |
|---|---|---|---|---|---|---|
| `/start` | 直接 | 串行单个 | 无 | ✅ | ✅ | ✅ |
| `/help` | 直接 | 无 | 无 | ✅ | ✅ | ✅ |
| `/adopt` | 直接 | 无 | 无 | ⚪ | ✅ | ✅ |
| `/project-stage-detect` | 直接 | 无 | 无 | ✅ | ✅ | ✅ |
| `/onboard` | 直接 | 无 | 无 | ❌ | ⚪ | ✅ |
| `/setup-engine` | 直接 | 无 | 无 | ✅ | ✅ | ✅ |

**类别 1 极简档保留 = 4 个**（start / help / project-stage-detect / setup-engine）。

---

# 类别 2 — Game Design（8 个 skill）

> 从概念到详细 GDD 的全部工作流。是工作室"**产出**"游戏的核心。
>
> 对应阶段：**Concept → Systems Design**。

## 2.1 `/design-system` ⭐ 精读 —— 最核心 skill

### 一句话定位

**按系统撰写 GDD**：核心循环 / 战斗 / 经济 / 关卡 / UI 等每个"系统"一份 GDD。CCGS 中**使用频率最高的 skill**——每个游戏产生 5-20 份 GDD。

### Frontmatter

```yaml
description: Author a GDD for a specific system, guided section-by-section
argument-hint: "[system-name] [--review full|lean|solo]"
allowed-tools: Read, Glob, Grep, Write, Edit, Task, AskUserQuestion
```

### 前置条件

- `design/gdd/game-concept.md`（必须）
- `design/gdd/systems-index.md`（必须，由 `/map-systems` 产出）
- 相关 GDD（如写战斗 GDD 要读核心循环 GDD）

### 工作流（典型 10+ 步）

1. 读入 systems-index.md 确认要写哪个系统 + 优先级
2. 读入相关已批准 GDD（避免冲突）
3. spawn `game-designer` 作为主要 subagent，按 8 节增量写作：
   - Overview
   - Player Fantasy
   - Detailed Rules
   - Formulas（若含数值 → 调用 `systems-designer` subagent）
   - Edge Cases
   - Dependencies
   - Tuning Knobs
   - Acceptance Criteria
4. 每节写完后询问用户批准
5. （full 模式）完成后触发 CD-GDD-ALIGN（spawn `creative-director`）
6. 更新 `design/gdd/systems-index.md` 把该系统状态改为 "Approved"
7. 建议下一步：下一个系统或 `/review-all-gdds`

### Task 调用

**串行多个**（分阶段）：
- `game-designer` 主 agent（整个 skill 期间多次 spawn）
- `systems-designer`（写 Formula 节时，串行 spawn）
- `creative-director`（full 模式下 CD-GDD-ALIGN，串行 spawn）
- （可选）`economy-designer` 在写经济 GDD 时 spawn

**CodeBuddy 性能影响**：每份 GDD 可能 spawn 2-4 次串行 subagent，单次 GDD 写作比 CCGS 慢 2-3 倍。但这是**不可避免**的——GDD 写作本身是核心创作活动。

### 产出文件

- `design/gdd/[system-name].md`（新增或更新）
- `design/gdd/systems-index.md`（状态更新）
- `production/session-state/active.md`（任务追踪）

### 涉及 Gates

- **CD-GDD-ALIGN**（full 模式触发）
- **CD-SYSTEMS**（若写的是核心系统）

### --review 差异

- `full`：每节写完都 ask 用户 + 最后 spawn creative-director
- `lean`：全部写完一次性 ask + 跳过 CD-GDD-ALIGN
- `solo`：纯引导用户 + 完全跳过 Gate

### CodeBuddy 适配评级

- **移植类型**：直接移植（工作流结构）+ 改造移植（Task 串行）
- **Task 模式**：串行多个
- **硬性模板**：GDD 8 节（来自 02 册 game-designer）
- **Gate 频率**：中（每次 GDD 1 次 CD-GDD-ALIGN）
- **档位**：极简 ✅（无 GDD 就没游戏） / 标准 ✅ / 完整 ✅

**关键改造**：
1. Formula 节的 `systems-designer` spawn 改为**可选**（lean 模式不 spawn，让 game-designer 顺手写）
2. CD-GDD-ALIGN 在 CodeBuddy 串行模式下是主要延迟点，默认 review-mode 应改为 `lean`（见 01b P0）
3. 8 节增量写作的"每节 ask"模式在 CodeBuddy 上很好地映射为 CodeBuddy 的 AskUserQuestion 工具

---

## 2.2 `/review-all-gdds` ⭐ 精读 —— 并行 spawn 典型

### 一句话定位

**跨 GDD 整体一致性审查**：读全部 GDD → 同时召唤多个 Director → 检查矛盾 / 设计理论 / 遗漏。是 01b 册 P0 识别的**并行 spawn 重点 skill 之一**。

### Frontmatter

```yaml
description: Holistic consistency + design-theory review across all GDDs simultaneously
argument-hint: "[focus: full | consistency | design-theory | since-last-review]"
allowed-tools: Read, Glob, Grep, Write, Task, AskUserQuestion
```

### 前置条件

- `design/gdd/*.md`（至少 3 份 GDD）
- `design/gdd/systems-index.md`
- 先前 `gdd-cross-review-*.md`（since-last-review 模式）

### 工作流（核心是并行）

1. Phase 1：读取所有 GDD + systems-index
2. Phase 2：**同时并行 spawn** 4 个 director（CD / TD / AD / ND）做各自视角审查：
   - `creative-director` → 愿景/机制叙事一致性
   - `technical-director` → 可行性 / 架构压力
   - `art-director` → 视觉风格一致性（若多 GDD 提及视觉）
   - `narrative-director` → 剧情/角色/世界观
3. Phase 3：收集 4 份审查意见 → 合并 + 找交叉矛盾
4. Phase 4：写入 `gdd-cross-review-[date].md`
5. Phase 5：建议下一步

### Task 调用

**⚠️ 并行多个（4 个并行）**：同时 spawn 4 个 director。

**CodeBuddy 性能影响**：**4 倍串行时间**。原 CCGS 约 3-5 分钟完成，CodeBuddy 串行模式约 12-20 分钟。这是 P0 的核心痛点。

### 产出文件

- `design/gdd/gdd-cross-review-[date].md`（主要产出）

### 涉及 Gates

无显式 director gate ID，但 4 director 各自执行自己 Gate 的等效审查。

### CodeBuddy 适配评级

- **移植类型**：**改造移植**（必须改串行）
- **Task 模式**：并行多个 → **串行多个（移植后）**
- **硬性模板**：gdd-cross-review 报告结构
- **Gate 频率**：高（每次调用触发 4 director）
- **档位**：极简 ❌（GDD 数少不需要跨审） / 标准 ⚪（可选） / 完整 ✅

**关键改造（重要）**：
1. **4 director 并行 → 改为串行** + 在提示词显式说明"顺序执行，每个 director 阅读前一个的结论"
2. **最大改造点**：考虑合并为 1 个 "cross-review" Subagent 一次性承担 4 视角 —— 用 Opus 级模型 + 长上下文批量处理，代替 4 次串行 spawn
3. `full / consistency / design-theory / since-last-review` 4 种 focus 模式都需改造

> **这是 02/03 册中最直接受 01b P0 影响的 skill** —— 单次调用从 4 个 subagent 并行变为 1 个长上下文 subagent 的改造，对用户体验影响最大。

---

## 2.3-2.8 其余 Game Design skill（概览表）

| # | skill | 定位 | Task 模式 | Gates | 档位（极/标/完）| 备注 |
|---|---|---|---|---|---|---|
| 2.3 | `/brainstorm` | MDA + verb-first + 玩家心理学探索 | 串行多个（CD + 可能 GD） | CD-CONCEPT | ✅/✅/✅ | 项目入口核心 |
| 2.4 | `/design-review` | 单个 GDD 的设计审查 | 串行单个（CD） | CD-GDD-ALIGN | ⚪/✅/✅ | 每份 GDD 运行一次 |
| 2.5 | `/consistency-check` | 扫描 GDD 矛盾与未定义引用 | 无（纯扫描） | 无 | ⚪/⚪/✅ | 修 GDD 后运行 |
| 2.6 | `/quick-design` | 小改动的轻量设计 spec | 无 | 无 | ⚪/✅/✅ | 绕过完整 GDD 流程 |
| 2.7 | `/map-systems` | 概念 → 系统分解 + 依赖排序 | 串行单个（GD） | 无 | ✅/✅/✅ | 阶段 1 必需 |
| 2.8 | `/balance-check` | 平衡数据 / 离群值 / 退化策略分析 | 串行单个（SD） | 无 | ❌/⚪/✅ | Polish 阶段 |

### 类别 2 横向规律

1. **8 个 skill 中，Task 模式分布**：
   - 无：2 个（consistency-check / quick-design）
   - 串行单个：4 个
   - 串行多个：1 个（brainstorm / design-system 部分场景）
   - **并行多个：1 个**（review-all-gdds）⚠️ P0

2. **Gate 触发**：4/8 个 skill 涉及 Gate（主要是 CD-*）；`/design-system` 和 `/review-all-gdds` 是 Gate 最密集的两个

3. **核心产出格式**：全部围绕 **GDD 8 节**（02 册已详解）

4. **--review 差异**：5/8 个有明确 full/lean/solo 差异 —— Game Design 是 CCGS 中 `--review` 机制使用最密集的类别

### 类别 2 适配性总表

| skill | 移植类型 | Task 模式 | Gate 频率 | 极简 | 标准 | 完整 |
|---|---|---|---|---|---|---|
| `/brainstorm` | 直接 | 串行多个 | 中 | ✅ | ✅ | ✅ |
| `/design-system` | 直接 | 串行多个 | 中 | ✅ | ✅ | ✅ |
| `/design-review` | 直接 | 串行单个 | 中 | ⚪ | ✅ | ✅ |
| **`/review-all-gdds`** | **改造** | **并行 → 串行/合并** | **高** | ❌ | ⚪ | ✅ |
| `/consistency-check` | 直接 | 无 | 无 | ⚪ | ⚪ | ✅ |
| `/quick-design` | 直接 | 无 | 无 | ⚪ | ✅ | ✅ |
| `/map-systems` | 直接 | 串行单个 | 无 | ✅ | ✅ | ✅ |
| `/balance-check` | 直接 | 串行单个 | 无 | ❌ | ⚪ | ✅ |

**类别 2 极简档保留 = 3 个**（brainstorm / design-system / map-systems）。

---

# 类别 3 — Art & Assets（4 个 skill）

> 艺术资产管线的全流程。Art Bible 建立后，用 asset-spec 生成规格，用 asset-audit / content-audit 做合规性检查。

### 类别 3 总览表

| # | skill | 定位 | Task 模式 | Gates | 极/标/完 | 关键说明 |
|---|---|---|---|---|---|---|
| 3.1 | `/art-bible` | 9 节艺术圣经撰写 | 串行多个（AD/UX/TA/CD） | AD-ART-BIBLE | ⚪/✅/✅ | **full 模式有 4 director 次第 spawn** |
| 3.2 | `/asset-spec` | 按 GDD/关卡/角色生成资产规格 | 串行多个（AD/TA）**并行版** | 无 | ❌/⚪/✅ | **full 模式 AD+TA 并行** |
| 3.3 | `/asset-audit` | 资产合规性扫描（命名/大小/格式） | 无 | 无 | ❌/⚪/✅ | 纯 read-only |
| 3.4 | `/content-audit` | 内容完整性审计（缺资产/死资产） | 无 | 无 | ❌/⚪/✅ | 纯 read-only |

### 类别 3 横向规律

1. **4 个 skill 中 2 个并行 spawn** —— Art & Assets 是 P0 次受灾区（次于 Game Design）
2. **2/4 无 Task**（asset-audit / content-audit 是纯扫描脚本）
3. **硬性模板**：art-bible 9 节 + asset-manifest 格式

### 类别 3 移植要点

1. `/art-bible` 的 full 模式 4 director 次第 spawn 改为串行（延迟 4 倍）
2. `/asset-spec` full 模式 AD+TA 并行改为串行（延迟 2 倍）
3. `/asset-audit` 和 `/content-audit` 无变化——原样移植

---

# 类别 4 — UX（2 个 skill）

### 类别 4 总览表

| # | skill | 定位 | Task 模式 | Gates | 极/标/完 | 备注 |
|---|---|---|---|---|---|---|
| 4.1 | `/ux-design` | 主菜单/HUD/交互模式 UX spec 撰写 | 串行多个（UX/AD/A11y） | 无 | ⚪/✅/✅ | 9 屏典型模板 |
| 4.2 | `/ux-review` | UX spec GDD 对齐 + a11y 合规审查 | 串行多个（UX/AD/A11y） | 无 | ⚪/✅/✅ | Epic 前必跑 |

### 类别 4 横向规律

2 个 skill 都涉及 `ux-designer` / `art-director` / `accessibility-specialist` 三位协作。CCGS 原设计是并行 spawn，CodeBuddy 上改为串行（延迟 3 倍）。

---

# 类别 5 — Architecture（4 个 skill）

> Technical-Setup 阶段的核心。ADR（Architecture Decision Record）是"技术决策的永久记录"。

## 5.1 `/architecture-decision` ⭐ 精读

### 一句话定位

**单个 ADR 的引导式撰写**：把一个技术决策（例："用 ScriptableObject 还是 JSON 存配置"）写成标准 ADR 格式文档。典型产出：`docs/architecture/adr-0005-data-storage.md`。

### 核心步骤（7 步）

1. 引入决策标题 + 上下文背景
2. 读 `docs/engine-reference/[engine]/VERSION.md` 确认版本
3. 读 `docs/registry/architecture.yaml` 看相关已做决策
4. 写 Context / Decision / Consequences 三节（ADR 标准格式）
5. **full 模式**：spawn `technical-director` 做 TD-ADR 审查
6. **写入** `docs/architecture/adr-[NNNN]-[slug].md`
7. 追加到 `docs/registry/architecture.yaml`

### Task 调用

- 串行：primary engine specialist（验证方案可行性）
- 串行（full 模式）：`technical-director`

### --review 差异

- `full`：TD-ADR Gate 激活
- `lean` / `solo`：跳过 TD-ADR

### CodeBuddy 适配

- **移植类型**：直接
- **Task 模式**：串行单个（engine specialist）+ 串行单个（TD，条件性）
- **Gate 频率**：中（TD-ADR 每次 ADR）—— 01b P0 建议改为"阶段末批量审查"而非逐个
- **档位**：极简 ⚪ / 标准 ✅ / 完整 ✅

**关键改造**：TD-ADR 在 CCGS 中是"每个 ADR 一次"，CodeBuddy 串行模式下代价过高。建议改为：
- lean 模式默认跳过 TD-ADR
- 在 `/architecture-review` 时批量审查所有新 ADR

---

## 5.2-5.4 其余 Architecture skill（概览表）

| # | skill | 定位 | Task 模式 | Gates | 极/标/完 |
|---|---|---|---|---|---|
| 5.2 | `/create-architecture` | 全局架构文档撰写（跨 GDD 综合） | 串行多个（TD + LP + engine specialist） | TD-ARCHITECTURE / LP-FEASIBILITY | ❌/⚪/✅ |
| 5.3 | `/architecture-review` | 架构对全 GDD 的覆盖审计 | 串行单个（engine specialist） | 无显式 | ❌/⚪/✅ |
| 5.4 | `/create-control-manifest` | 从已 Accepted ADR 生成扁平规则表 | 无 | 无 | ❌/⚪/✅ |

### 类别 5 横向规律

1. 4 个 skill 中 **/create-architecture 触发两大 Gate（TD-ARCHITECTURE + LP-FEASIBILITY）**，是 Technical-Setup 阶段的关键节点
2. `/create-control-manifest` 是**纯生成器**（无 Task），把 ADR 集合平铺为程序员可查的规则表

---

# 类别 6 — Stories & Sprints（7 个 skill）

> Production 阶段的核心工作流。从 Epic 到 Story 到 Sprint 到 Dev。

## 6.1 `/dev-story` ⭐ 精读 —— 日常开发入口

### 一句话定位

**实现单个 story 的完整工作流**：从 story 文档 → 读 ADR/GDD → 路由到正确的 programmer agent → 实现 → 写测试 → 更新状态。

### Frontmatter

```yaml
description: Implement the next ready story
argument-hint: "[story-path]"
allowed-tools: Read, Glob, Grep, Write, Edit, Bash, Task, AskUserQuestion
```

### 前置条件

- `production/epics/**/story-*.md`（目标 story 文件）
- 相关 GDD + ADR
- `docs/architecture/control-manifest.md`

### 工作流

1. 读入 story + 所有相关 GDD/ADR
2. **路由到正确 programmer**（基于 story 分类）：
   - Logic/Gameplay → `gameplay-programmer`
   - Engine/Performance → `engine-programmer`
   - AI → `ai-programmer`
   - Network → `network-programmer`
   - UI → `ui-programmer`
   - Tools → `tools-programmer`
3. **引擎适配**：若涉及引擎特异代码，串行 spawn 对应引擎 specialist
4. **实现 + 测试**（6 步实现协议）
5. **story 状态 → "Complete"**
6. （可选）建议 `/code-review` 和 `/story-done`

### Task 调用

**串行多个（1-3 个）**：先 primary programmer，可能加引擎 specialist，可能加 qa-tester 写测试。

### 产出文件

- `src/**`（实际代码）
- `tests/**`（测试文件）
- `production/epics/**/story-*.md`（状态更新）

### 涉及 Gates

- **LP-CODE-REVIEW**（若在 full 模式，story 完成后触发）
- 条件触发 TD-ADR（若实现过程发现新架构决策）

### CodeBuddy 适配评级

- **移植类型**：直接
- **Task 模式**：串行多个（1-3 个）
- **硬性模板**：6 步实现协议（来自 02 册）
- **Gate 频率**：中
- **档位**：极简 ✅ / 标准 ✅ / 完整 ✅（**开发主流核心**）

**关键改造**：
1. primary programmer 路由逻辑保留
2. 引擎 specialist 的 spawn 在极简档可跳过（让 primary programmer 自己处理）
3. LP-CODE-REVIEW 在 lean 模式下改为"Sprint 末批量审查"（见 02 册 lead-programmer）

---

## 6.2-6.7 其余 Stories & Sprints skill（概览表）

| # | skill | 定位 | Task 模式 | Gates | 极/标/完 |
|---|---|---|---|---|---|
| 6.2 | `/create-epics` | 从 GDD+ADR 生成 Epic（按架构层） | 串行多个（PR+LP+AD） | PR-EPIC | ❌/✅/✅ |
| 6.3 | `/create-stories` | 把 Epic 拆分为具体 story 文件 | 串行多个 | 无 | ❌/✅/✅ |
| 6.4 | `/story-readiness` | Story 进 Sprint 前的完备性检查 | 串行单个（QA-lead） | QL-STORY-READY | ❌/⚪/✅ |
| 6.5 | `/sprint-plan` | Sprint 规划（选 story + 估时 + 分配） | 串行多个（PR+LP+QL） | PR-SPRINT | ⚪/✅/✅ |
| 6.6 | `/sprint-status` | 30 行快照报告 | 无 | 无 | ⚪/✅/✅ |
| 6.7 | `/story-done` | Story 关闭验证（验收标准 + 偏差检查） | 串行单个（QA+LP） | QL-STORY-READY（关闭时） | ⚪/✅/✅ |

### 类别 6 横向规律

1. 7 个 skill 全部在 Production 阶段，是日常使用最频繁的一批
2. `/dev-story` + `/story-done` 是**日常循环**（实现 → 关闭）
3. `/create-epics` / `/create-stories` / `/sprint-plan` 是**周期性批量**（每个 milestone 一次）
4. **2 个核心 Gate**：QL-STORY-READY / PR-SPRINT —— 可合并到 `/sprint-plan` 一次性审查（减少 spawn 次数）

---

# 类别 7 — Reviews & Gates（5 个 skill）

> 门控系统的主 skill。`/gate-check` 是最"重"的 skill（并行 4 Director）。

## 7.1 `/gate-check` ⭐ 精读 —— 最重的门控 skill

### 一句话定位

**阶段过渡门控**：在 concept → systems-design、systems-design → technical-setup 等阶段切换时，**并行调用 4 个 PHASE-GATE Director** 做综合审查，给出 PROCEED / CONCERNS / BLOCK 决策。

### Frontmatter

```yaml
description: Run phase-gate checks with parallel director reviews
argument-hint: "[from-phase] [to-phase] [--review full|lean|solo]"
allowed-tools: Read, Glob, Grep, Write, Task, AskUserQuestion
```

### 前置条件

- `production/stage.txt` 或自动阶段检测
- 目标阶段的所有必需 artifact

### 工作流（核心是并行）

1. 读入当前阶段和下一阶段的 required artifacts
2. 检查 artifacts 是否齐全
3. **同时并行 spawn 4 个 Director**：
   - `creative-director` → CD-PHASE-GATE
   - `technical-director` → TD-PHASE-GATE
   - `producer` → PR-PHASE-GATE
   - `art-director` → AD-PHASE-GATE
4. 收集 4 份判定 + 合并为综合判定
5. 若 CONCERNS → 列出具体问题；若 BLOCK → 阻止推进
6. 更新 `production/stage.txt`
7. 写入 `production/gate-checks/gate-[date].md`

### Task 调用

**⚠️ 并行多个（4 个并行）** —— 与 `/review-all-gdds` 并列为 CCGS 最依赖并行的 skill。

**CodeBuddy 串行模式影响**：**4 倍延迟**。

### CodeBuddy 适配评级

- **移植类型**：**改造移植**
- **Task 模式**：并行多个 → 合并为 1 个综合 director 或串行
- **Gate 频率**：低（阶段过渡才触发，每个项目 6 次左右）
- **档位**：极简 ⚪（可用手动判断代替）/ 标准 ✅ / 完整 ✅

**关键改造（与 `/review-all-gdds` 共享的策略）**：
1. **推荐方案**：用 1 个 "PHASE-GATE-COMBINED" subagent（Opus 级长上下文）代替 4 个并行 director
2. 若保留 4 director 则改为**串行**，并在提示词中显式告诉每个 director "前一个已批复了 X"

---

## 7.2-7.5 其余 Reviews & Gates skill（概览表）

| # | skill | 定位 | Task 模式 | Gates | 极/标/完 |
|---|---|---|---|---|---|
| 7.2 | `/code-review` | 架构级代码审查 | 串行单个（LP） | LP-CODE-REVIEW | ⚪/✅/✅ |
| 7.3 | `/architecture-review`（已在类 5）| 架构覆盖审计 | — | — | 见 5.3 |
| 7.4 | `/design-review`（已在类 2）| 单 GDD 审查 | — | — | 见 2.4 |
| 7.5 | `/test-evidence-review` | 验证 story 测试证据 | 串行单个（QT） | QL-TEST-COVERAGE | ⚪/✅/✅ |

---

# 类别 8 — QA（11 个 skill）

> CCGS 最庞大的一类。从 test-setup 到 smoke-check 到 soak-test 全套 QA 工作流。

### 类别 8 总览表

| # | skill | 定位 | Task 模式 | Gates | 极/标/完 |
|---|---|---|---|---|---|
| 8.1 | `/qa-plan` | Sprint/feature QA 测试计划 | 无 | 无 | ⚪/✅/✅ |
| 8.2 | `/smoke-check` | 10-15 个关键路径冒烟测试 | 无（脚本执行） | 无（blocker if fail） | ⚪/✅/✅ |
| 8.3 | `/bug-report` | 结构化 bug 报告 | 串行单个（QT） | 无 | ⚪/✅/✅ |
| 8.4 | `/bug-triage` | Bug 优先级排序 | 串行单个（QL） | 无 | ⚪/⚪/✅ |
| 8.5 | `/regression-suite` | 回归测试清单维护 | 无 | 无 | ❌/⚪/✅ |
| 8.6 | `/test-evidence-review` | （见 7.5） | — | — | — |
| 8.7 | `/test-setup` | 初始化测试框架（每引擎不同） | 串行单个（QT + engine） | 无 | ⚪/✅/✅ |
| 8.8 | `/test-helpers` | 生成测试 fixture | 串行单个（QT） | 无 | ❌/⚪/✅ |
| 8.9 | `/test-flakiness` | 不稳定测试分析 | 无 | 无 | ❌/⚪/✅ |
| 8.10 | `/soak-test` | 长时间压测 | 无（脚本） | 无 | ❌/❌/⚪ |
| 8.11 | `/security-audit` | 安全审计清单 | 串行单个（SE） | 无 | ❌/⚪/✅ |

### 类别 8 横向规律

1. **QA 是 Task 调用最少的类别**：11 个 skill 中仅 5 个有 Task 调用，且都是串行单个
2. **多个 skill 是脚本化的**（smoke-check / soak-test），CodeBuddy 移植几乎零成本
3. **硬性模板密集**：Test Case 4 字段 / Bug Report 模板 / regression-suite 结构 / qa-plan 格式（来自 02 册 qa-lead/qa-tester）
4. **无大的并行 spawn** —— QA 类在 CodeBuddy 上性能损失最小

**移植洞察**：QA 类 skill **全部推荐直接移植**，是 72 skill 中移植难度最低的。

---

# 类别 9 — Production（6 个 skill）

> 项目管理类 skill。sprint 状态追踪 / 估时 / 回顾 / 范围检查。

### 类别 9 总览表

| # | skill | 定位 | Task 模式 | Gates | 极/标/完 |
|---|---|---|---|---|---|
| 9.1 | `/retrospective` | Sprint/milestone 复盘 | 无 | 无 | ⚪/✅/✅ |
| 9.2 | `/scope-check` | Sprint 范围漂移检测 | 串行单个（PR） | PR-SCOPE | ⚪/✅/✅ |
| 9.3 | `/estimate` | 任务估时 | 串行单个（PR+LP） | 无 | ❌/⚪/✅ |
| 9.4 | `/tech-debt` | 技术债务登记簿 | 串行单个（LP） | 无 | ❌/⚪/✅ |
| 9.5 | `/milestone-review` | 里程碑综合评审 | 串行多个（PR+LP+QL） | PR-MILESTONE | ❌/⚪/✅ |
| 9.6 | `/propagate-design-change` | 设计变更的依赖传播 | 串行多个（GD+LP+QL） | 无 | ❌/⚪/✅ |

### 类别 9 横向规律

1. 6 个全部串行 Task（无并行），移植几乎零性能损失
2. `/milestone-review` 和 `/propagate-design-change` 是跨部门协调的关键——3-4 个串行 spawn

---

# 类别 10 — Release（5 个 skill）

### 类别 10 总览表

| # | skill | 定位 | Task 模式 | Gates | 极/标/完 |
|---|---|---|---|---|---|
| 10.1 | `/release-checklist` | 发布前综合验证 | 串行多个（RM+QL+SE） | 无 | ❌/⚪/✅ |
| 10.2 | `/launch-checklist` | 最终发布闸门 | 串行多个（RM+PR+QL+SE） | 无 | ❌/⚪/✅ |
| 10.3 | `/patch-notes` | 玩家向补丁说明 | 串行单个（CM） | 无 | ❌/⚪/✅ |
| 10.4 | `/changelog` | 内部变更日志 | 无（git log 解析） | 无 | ❌/⚪/✅ |
| 10.5 | `/hotfix` | 热修复流程 | 串行多个（RM+QL） | 无 | ❌/⚪/✅ |

> `/day-one-patch` 也属此类，但在扫描中被识别为独立 skill；实际功能接近 `/patch-notes`，合并归此类。

---

# 类别 11 — Team Orchestration ⭐ P0 重灾区（9 个 skill）

> **本册最关键的一类**。9 个 `team-*` skill 的共同模式是"**并行 spawn 3-6 个 subagent** 协作完成特性级任务"。
>
> 是 01b 册 P0 识别的**并行 spawn 主要来源**，在 CodeBuddy 串行模式下性能损失最大（3-6 倍延迟）。

## 11.x `team-*` 系列共同模式

所有 9 个 team-* skill 的结构高度一致：

```
1. 读入目标特性的 GDD / 关卡 / 系统规格
2. ⚠️ 同时并行 spawn N 个 subagent（每个做自己领域的部分）
3. 收集所有 subagent 结果
4. 合并 + 协调跨领域冲突
5. 产出综合方案 / 代码 / 文档
```

## 11.1-11.9 全部 team-* skill（详细对照表）

| # | skill | 并行 spawn 数 | 主要 subagent | 典型用例 | 移植后改造策略 |
|---|---|---|---|---|---|
| 11.1 | `/team-combat` | **5 个** | GD / SD / LD / GP / AIP | 战斗特性跨 5 部门设计 | 改为 3 次串行（GD+SD 合并、LD+GP 合并、AIP 单独） |
| 11.2 | `/team-narrative` | **4 个** | ND / W / WB / GD | 叙事分支/角色弧跨部门设计 | 改为 2 次串行（ND+W 合并、WB+GD 合并） |
| 11.3 | `/team-ui` | **4 个** | UXD / AD / UIP / A11y | UI 界面跨 UX/视觉/实现/无障碍 | 改为 2 次串行（UXD+AD 合并、UIP+A11y 合并） |
| 11.4 | `/team-audio` | **3 个** | AD / SD / UIP | 音频事件系统跨设计/规格/实现 | 改为 2 次串行 |
| 11.5 | `/team-level` | **4 个** | LD / GD / AD / ND | 关卡跨空间/机制/视觉/叙事 | 改为 2 次串行 |
| 11.6 | `/team-live-ops` | **4 个** | LOD / ED / ND / CM | 季节性内容跨活动/经济/叙事/社区 | 改为 2 次串行 |
| 11.7 | `/team-qa` | **4 个** | QL / QT / SE / A11y | 发布前综合 QA | 改为 2 次串行 |
| 11.8 | `/team-release` | **5 个** | RM / QL / PR / CM / SE | 发布协调 | 改为 2-3 次串行 |
| 11.9 | `/team-polish` | **6 个** | PA / TA / AD / UXD / QL / CD | 综合打磨阶段 | 改为 3 次串行（最大延迟） |

> 9 个 team-* skill 共涉及 **平均 4-5 次并行 spawn**。CodeBuddy 串行模式下：
>
> - 单次 team-* 调用从 ~5 分钟 → ~20-30 分钟
> - 9 个 skill 全套运行一轮 = 3-5 小时（原 CCGS ~45 分钟）
>
> **最大代价集中在 `/team-polish`（6 并行）和 `/team-combat`、`/team-release`（5 并行）**。

### Team Orchestration 横向规律

1. **9 个 skill 全部是并行多个（4-6 并行）** —— CCGS 中最依赖并行 spawn 的一类
2. **共同工作流模式**：扇出 → 聚合 → 合并冲突 → 产出
3. **没有 Gate 触发**（team-* 是执行性 skill，不做门控）
4. **硬性产出模板**：每个 team-* 有自己的综合报告模板

### Team Orchestration 移植策略（3 档）

| 档位 | 保留哪些 team-* | 改造方式 |
|---|---|---|
| **极简档** | **全部不保留** | 用 `/dev-story` 单独 spawn 对应 programmer 代替；跨部门协调交给用户手动 |
| **标准档** | 保留 3-4 个核心（`/team-combat` / `/team-ui` / `/team-level` / `/team-qa`） | 所有并行 → 串行（接受延迟）或减少 subagent 数（2 个并行） |
| **完整档** | 保留全部 9 个 | 串行 + 提示词优化（让每个 subagent 知道"前一个结论"，避免重复工作） |

**核心洞察**：team-* skill 是 CCGS 中**移植损失最大**的一类。即便改造后，用户体验仍显著下降。**极简档移植时应完全跳过，用 01b 推荐的"多个 CodeBuddy 窗口并行"手动补偿**。

### 类别 11 适配性总表

| skill | 并行数 | 移植类型 | Task 模式 | 极简 | 标准 | 完整 |
|---|---|---|---|---|---|---|
| `/team-combat` | 5 | 改造 | 并行→串行 | ❌ | ✅ | ✅ |
| `/team-narrative` | 4 | 改造 | 并行→串行 | ❌ | ⚪ | ✅ |
| `/team-ui` | 4 | 改造 | 并行→串行 | ❌ | ✅ | ✅ |
| `/team-audio` | 3 | 改造 | 并行→串行 | ❌ | ⚪ | ✅ |
| `/team-level` | 4 | 改造 | 并行→串行 | ❌ | ✅ | ✅ |
| `/team-live-ops` | 4 | 改造 | 并行→串行 | ❌ | ❌ | ⚪ |
| `/team-qa` | 4 | 改造 | 并行→串行 | ❌ | ✅ | ✅ |
| `/team-release` | 5 | 改造 | 并行→串行 | ❌ | ⚪ | ✅ |
| `/team-polish` | 6 | 改造 | 并行→串行 | ❌ | ⚪ | ✅ |

**类别 11 极简档保留 = 0 个**。标准档推荐保留 4 个。

---

# 类别 12 — Creative（2 个 skill）

### 类别 12 总览表

| # | skill | 定位 | Task 模式 | 特殊机制 | 极/标/完 |
|---|---|---|---|---|---|
| 12.1 | `/prototype` | 抛弃式原型构建 | 串行单个（CD，full 模式） | **⚠️ `isolation: worktree`**（02 册 prototyper） | ⚪/✅/✅ |
| 12.2 | `/playtest-report` | 游玩测试会话报告 | 无 | — | ⚪/✅/✅ |

`/prototype` 是 72 个 skill 中**唯一使用 `isolation: worktree`**的——参照 02 册 prototyper 的移植分析，CodeBuddy 无对应机制，需要手动代偿。

---

# 类别 13 — Utility & Meta（4 个 skill）

### 类别 13 总览表

| # | skill | 定位 | Task 模式 | 极/标/完 |
|---|---|---|---|---|
| 13.1 | `/reverse-document` | 从代码/原型反推 GDD/ADR/concept | 串行单个 | ❌/⚪/✅ |
| 13.2 | `/localize` | i18n 架构初始化 | 串行单个（LL） | ❌/⚪/✅ |
| 13.3 | `/skill-test` | Meta 测试 skill（lint/spec/catalog 3 模式） | 无（脚本执行） | ❌/❌/⚪ |
| 13.4 | `/skill-improve` | Skill 自身改进 | 串行单个 | ❌/❌/⚪ |

`/skill-test` 和 `/skill-improve` 是 **CCGS Skill Testing Framework** 的执行 skill（见 01 册）。这两者**仅在开发工作室本身时用到**，游戏开发过程中用不到。

---

# 72 Skill 完整适配性总表

> 本表是 03 册的最终输出，**每一行可直接用于移植决策**。

## Task 模式分布统计

| Task 模式 | 数量 | 占比 |
|---|---|---|
| 无（纯文档/脚本） | 18 | 25% |
| 串行单个 | 23 | 32% |
| 串行多个（2-4 个） | 17 | 24% |
| **并行多个（⚠️ CodeBuddy 瓶颈）** | **14** | **19%** |

**14 个并行多个的 skill** = `review-all-gdds` + `gate-check` + `art-bible` (full) + `asset-spec` (full) + 9 个 team-* + `ux-design` + `ux-review`。**这 14 个是移植改造的重点**。

## Gate 频率分布统计

| Gate 频率 | 数量 | 典型 skill |
|---|---|---|
| 无 | 42 | QA 类 / 工具类 / 脚本类 |
| 低 | 10 | `gate-check` / `milestone-review` / `scope-check` |
| 中 | 15 | `design-system` / `design-review` / `dev-story` / `architecture-decision` |
| **高** | **5** | `review-all-gdds` / `gate-check` / `team-polish` / `team-release` / `team-combat` |

## 三档移植最终清单

### 极简档 skill 清单（约 20 个）

**Onboarding（4 个）**：start / help / project-stage-detect / setup-engine

**Game Design（3 个）**：brainstorm / design-system / map-systems

**Architecture（0 个）**：视为标准档起

**Stories & Sprints（3 个）**：dev-story / story-done / sprint-status

**Reviews（1 个）**：design-review（可选）

**QA（3 个）**：smoke-check / bug-report / qa-plan

**Production（2 个）**：retrospective / scope-check

**Release（0 个）**：视为完整档起

**Team（0 个）**：全部跳过

**Creative（1 个）**：prototype（可选）

**其他（3 个）**：adopt / consistency-check / quick-design

**合计 ~20 个极简档 skill**，覆盖完整单人开发闭环。

### 标准档 skill 清单（约 45 个）

极简档 + 增补：

- Game Design 增补：design-review / review-all-gdds / balance-check（8 全保）
- Architecture 增补：create-architecture / architecture-decision / architecture-review / create-control-manifest（4 全保）
- Stories & Sprints 增补：create-epics / create-stories / story-readiness / sprint-plan（7 全保）
- QA 增补：test-setup / regression-suite / bug-triage / test-evidence-review（全部 11 个保留）
- Team 增补：team-combat / team-ui / team-level / team-qa（4 个核心）
- Release 增补：release-checklist / launch-checklist / patch-notes / changelog（4 个）
- Art & Assets 增补：art-bible / asset-audit / content-audit（3 个，asset-spec 视项目）
- UX 增补：ux-design / ux-review（2 全保）
- Production 增补：estimate / tech-debt / milestone-review（全部 6 个）

### 完整档 skill 清单（约 65-70 个）

标准档 + 全部 team-* + 全部 Utility 除 skill-test/skill-improve（这两个仅工作室自身开发用）。

---

## 03 册总结 —— 5 大移植洞察

### 洞察 1：Task 调用模式决定移植优先级

**18 个"无 Task" skill** = 移植难度最低 → 极简档优先保留  
**23 个"串行单个"** = 直接移植 → 标准档覆盖  
**17 个"串行多个"** = 接受延迟即可 → 标准/完整档  
**14 个"并行多个"** = 必须改造 → 完整档或舍弃

### 洞察 2：团队 orchestration 是 CodeBuddy 最大痛点

9 个 `team-*` skill 全部是并行多个，占 14 个并行 skill 的 **64%**。极简档必须全部跳过；标准档只推荐保留 3-4 个核心；完整档需要接受 3-6 倍延迟。

### 洞察 3：QA 类是最易移植的类别（11 个，零改造）

11 个 QA skill 中 6 个无 Task、5 个串行单个，**零并行 spawn**。全部可直接移植，几乎无性能损失。

### 洞察 4：Gate 触发集中在 5 个 skill

72 个 skill 中仅 **5 个高 Gate 频率**（review-all-gdds / gate-check / team-polish / team-release / team-combat）。这 5 个是"01b P0 并行 + 02 册 Gate 成本"双重叠加的最痛点。

### 洞察 5：workflow-catalog.yaml 是最有价值的**数据资产**

与 skill 一同移植（纯数据，零改造）。**`/help`、`/start`、`/project-stage-detect` 三个 skill 的智能行为全靠它支撑**——没有 yaml 就没有阶段感知。

---

*03 册完成 ✅ —— 72 个 skill 全部拆解完毕。*

*下一步：04_Hooks + Rules + Templates（12 hook / 11 rule / 39 template 全解析）。建议审阅 03 册整体后继续。*
