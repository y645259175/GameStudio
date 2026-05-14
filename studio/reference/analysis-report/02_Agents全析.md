# 02 — 49 个 Agent 全析

> **本册范围**：CCGS `.claude/agents/` 目录下全部 49 个 agent 定义文件的逐份完整拆解。每个 agent 按统一字段呈现：通俗概述、frontmatter 元信息、职责骨架、决策机制、上下游关系、CodeBuddy 适配评级。
>
> **与其他册的关系**：
> - 上游：01_架构总览（三层体系、协调规则、Director Gates 系统）+ 01b_差距分析（决定每个 agent 的适配评级）
> - 下游：03_Skills 全析（每个 skill 调用的 agent 来自本册）、05_移植建议（从本册的 49 个评级汇总最终移植清单）
>
> **统一拆解字段**：
> 1. 一句话定位（通俗，无门槛）
> 2. Frontmatter 元信息（name / model / memory / tools / disallowedTools / maxTurns / skills 等）
> 3. 核心职责（原文摘要 + 中文提炼）
> 4. 关键工作流程（决策模式、提问/选项/起草节奏）
> 5. 上下游关系（委派给谁、被谁委派、与谁咨询、向谁升级）
> 6. 涉及的 Director Gates（如有）
> 7. "禁止做"列表（划清域边界）
> 8. **CodeBuddy 适配评级**（绑定 01b 的极简 / 标准 / 完整三档策略）

---

## 评级与策略对应说明

> 本册每个 agent 的"适配评级"采用以下两层标注：

**第一层 — 移植类型**（沿用 00 册图例）：
- **直接移植**：内容与平台无关，复制粘贴即可
- **改造移植**：功能有价值，但承载机制需要改写
- **不建议移植**：CodeBuddy 无对应实现或价值低
- **可选扩展**：CodeBuddy 特有能力可补强

**第二层 — 移植档位**（来自 01b 第九章）：
- **极简档**：5-8 个核心 agent，适合 Game Jam / 1 人项目
- **标准档**：25-30 个 agent，适合独立开发者 / 2-3 人小团队
- **完整档**：40+ agent，适合多人协作 / 商业项目

每个 agent 末尾会标注："**适合保留档位**：极简 ✅ / 标准 ✅ / 完整 ✅"——勾选越多，说明该 agent 越基础，越值得移植；只在完整档勾选的，是"锦上添花"型角色。

---

## 第三层评级维度 — 移植形态（本册核心框架）

> **核心洞察**：CodeBuddy 不支持 skill 内并行 spawn subagent（详见 01b 章 P0）。这意味着 CCGS 原本"每个 skill 都 spawn 多个 agent"的设计在 CodeBuddy 上代价高昂。  
> 但并非所有 agent 都必须以"独立 subagent"形式存在——它们的**提示词内容**（职责、决策框架、输出模板）与**调用方式**（何时被 spawn）是两件可以分开处理的事。

基于"提示词内容价值"和"CodeBuddy 调用开销"两个维度，49 个 agent 在移植后可分为 **3 类形态**：

### 形态 A — Gate 专用角色（保留独立 md + 只在 Gate 时 spawn）

**特征**：
- 提供战略决策、独立视角审查，不直接做具体执行
- 原本在 CCGS 多个 skill 里被频繁 spawn（并行协议下成本低）
- 在 CodeBuddy 串行模式下，频繁 spawn 代价过高

**移植处理**：
- 保留独立 md 文件（提示词内容有价值）
- **大幅降低调用频率**：只在阶段过渡 Gate（如 PR-PHASE-GATE、CD-PHASE-GATE）和用户手动咨询（如 `@creative-director 这个范围如何裁`）时 spawn
- CCGS 原本写进 skill 的 per-skill inline Gate 改为：skill 提示词里**内嵌**该 Director 的决策框架片段，避免每次都 spawn

**典型代表**：creative-director / technical-director / producer / art-director（4 个 Director 级角色）

### 形态 B — 执行角色（保留独立 md + skill 内串行 spawn）

**特征**：
- 完成具体任务（写代码、写设计文档、写对话、做测试规划）
- 每次只被一个 skill 在特定 phase 调用
- 输出是结构化产物（文件、代码），不是审查意见

**移植处理**：
- 保留独立 md 文件
- 在 skill 内串行 spawn（接受单次调用的延迟）
- 如果一个 skill 原本 spawn 多个执行角色，移植后需评估：合并为 1-2 个串行 spawn + 主 skill 承担余下工作

**典型代表**：gameplay-programmer / writer / systems-designer / level-designer / ux-designer 等负责"做东西"的角色

### 形态 C — 参考角色（提示词拆分为 Rules/CODEBUDDY.md 片段）

**特征**：
- 职责窄、决策轻量（通常是 Haiku 级轻量 agent）
- 提示词的价值在于"特定领域的规范与最佳实践"
- 独立 spawn 价值低（信息用 rule 注入即可）

**移植处理**：
- **不保留独立 md 文件**，也不作为独立 subagent 存在
- 把其提示词中的核心规范拆出，合并进 CodeBuddy Rules 或 CODEBUDDY.md 相关章节
- 在需要这些规范的 skill 提示词里直接引用（`@rule-name` 或写进 skill 正文）

**典型代表**：sound-designer / accessibility-specialist / community-manager / qa-tester / devops-engineer 等规范型 Haiku 角色

### 形态分布预估

通读 agent-roster 和各文件定位后初步估算：

| 形态 | 数量估计 | 占比 |
|---|---|---|
| 形态 A（Gate 专用） | 4 | 约 8% |
| 形态 B（执行角色） | 25-30 | 约 55% |
| 形态 C（参考角色） | 15-20 | 约 35% |

精确归类在 02 册逐份拆解时确定。每个 agent 的评级末尾都会明确标注其**移植形态**。

### 形态选择判断流程

```
这个 agent 在 CCGS 中的提示词内容是否有独立复用价值？
│
├── 否 → 跳过（极少见）
│
└── 是 → 这个 agent 主要靠"被 skill spawn"还是"给 skill 提供规范"？
    │
    ├── 提供规范 → 形态 C（拆进 Rules/CODEBUDDY.md）
    │
    └── 被 spawn → 它提供的是审查意见还是具体产出？
        │
        ├── 审查意见 → 形态 A（Gate 专用，低频 spawn）
        │
        └── 具体产出 → 形态 B（skill 内串行 spawn）
```

---

## 评级字段完整说明（后续每个 agent 均按此五段式）

综合以上，每个 agent 末尾的 CodeBuddy 适配评级将包含 5 项信息：

1. **移植类型**：直接移植 / 改造移植 / 不建议移植 / 可选扩展
2. **移植形态**：A（Gate 专用）/ B（执行）/ C（参考）
3. **关键改造点**：逐条列出
4. **适合保留档位**：极简 / 标准 / 完整（勾选）
5. **调用频率建议**（仅形态 A 和 B 适用）：高频（每个相关 skill）/ 中频（阶段过渡）/ 低频（仅手动调用）

---

# Tier 1 — Directors（总监级）

> 共 3 个角色：creative-director / technical-director / producer。
> 这三个是整个工作室的"决策大脑"——只做战略决策、不做执行，全部使用 Opus 模型，全部 `memory: user`。
> 在 CodeBuddy 上，这三个角色是**所有移植档位都建议保留**的核心。

---

## 1. creative-director（创意总监）

### 一句话定位

游戏项目最高的创意权威，负责守护"这是一款什么样的游戏"的整体愿景，是所有创意冲突（设计 vs 叙事 vs 美术 vs 音频）的最终裁决者。

### Frontmatter 元信息

```yaml
name: creative-director
description: "...highest-level creative authority...binding decisions on game vision, tone, aesthetic direction..."
tools: Read, Glob, Grep, Write, Edit, WebSearch
model: opus
maxTurns: 30
memory: user
disallowedTools: Bash      # 禁止执行 shell 命令
skills: [brainstorm, design-review]
```

**关键点解读**：
- `disallowedTools: Bash`——明确禁止执行 shell。创意总监不该接触系统层操作，这是一道安全防线。
- `skills: [brainstorm, design-review]`——绑定了 2 个 skill，意思是当用户调用这两个 skill 时，本 agent 是默认参与者。
- `maxTurns: 30`——最多 30 个对话回合就必须停下，防止 agent 陷入无穷追问。

### 核心职责（6 项）

| 职责 | 通俗解释 |
|---|---|
| **愿景守护**（Vision Guardianship） | 维护游戏核心支柱（Pillars）/ 核心幻想（Core Fantasy）/ 目标体验（Target Experience），每个创意决策都要追溯到支柱 |
| **支柱冲突裁决**（Pillar Conflict Resolution） | 当游戏设计、叙事、美术、音频目标互相冲突时，按 MDA 美学优先级裁决 |
| **基调与感觉**（Tone and Feel） | 用"体验目标"（具体的游戏瞬间描述）而不是抽象形容词来定义游戏情感 |
| **竞品定位**（Competitive Positioning） | 维护一张"定位地图"，把本作和同类作品放在 2-3 个关键轴上对比 |
| **范围裁定**（Scope Arbitration） | 创意野心超出产能时，决定砍什么、简化什么、保留什么，应用"支柱接近度测试" |
| **参考资料策划**（Reference Curation） | 维护游戏/电影/音乐/艺术的参考库，为方向提供灵感 |

### 决策框架（评估任何创意决策时按顺序应用）

1. 服务核心幻想吗？
2. 尊重已有支柱吗？（每个都要 check，不只是最相关的）
3. 服务目标 MDA 美学吗？
4. 与已有决策能否构成连贯体验？
5. 强化竞品定位吗？
6. 在约束内可实现吗？

### 引用的理论框架

- **MDA 8 类美学**：Sensation / Fantasy / Narrative / Challenge / Fellowship / Discovery / Expression / Submission
- **Self-Determination Theory**：Autonomy / Competence / Relatedness 三大心理需求
- **Flow State**：心流入口、心流维持、有意的心流打断
- **Ludonarrative Consonance**：机制和叙事必须互相强化，避免"机制说一套叙事说一套"

### 关键工作流程（5 步战略决策）

1. 理解完整背景（提问 + 读相关文档 + 识别真正利害）
2. 框定决策（核心问题 + 影响下游什么 + 评估标准）
3. 提供 2-3 个战略选项（每个含具体内容/牺牲什么/下游后果/风险/参考案例）
4. 给出明确推荐（理由 + 接受的取舍 + "但这是你的决定"）
5. 支持用户决策（文档化 ADR/支柱更新 + 通知相关部门 + 设置成功标准）

### 涉及的 Director Gates

| Gate ID | 触发场景 | 判定词 |
|---|---|---|
| CD-PILLARS | 游戏支柱定义后 | APPROVE / CONCERNS / REJECT |
| CD-GDD-ALIGN | GDD 起草后 | APPROVE / CONCERNS / REJECT |
| CD-SYSTEMS | systems-index 完成后 | APPROVE / CONCERNS / REJECT |
| CD-NARRATIVE | 叙事内容生成后 | APPROVE / CONCERNS / REJECT |
| CD-PLAYTEST | 游玩测试报告后 | APPROVE / CONCERNS / REJECT |
| CD-PHASE-GATE | 阶段过渡时（必须） | READY / CONCERNS / NOT READY |

**Gate 输出格式硬性要求**：第一行必须是 `[GATE-ID]: VERDICT`，技能读取首行判定。

### 上下游关系

**委派给**：game-designer / art-director / audio-director / narrative-director（4 个 Tier 2 lead）

**升级目标（接收以下冲突）**：
- game-designer vs narrative-director（机制叙事一致性冲突）
- art-director vs audio-director（美术音频基调冲突）
- 任何"改变游戏身份"的决策
- 部门主管无法解决的支柱冲突
- 创意意图 vs 产能的范围问题

### 禁止做

- 写代码或做技术实现决策
- 批准/拒绝单个资产（交给 art-director）
- 做 Sprint 级别排期决策（交给 producer）
- 写最终对话或叙事文本（交给 narrative-director）
- 做引擎或架构选择（交给 technical-director）

### CodeBuddy 适配评级

**移植类型**：直接移植（提示词内容）+ 改造移植（frontmatter 字段）

**移植形态**：**A — Gate 专用角色**  
（提供战略审查，原本在 brainstorm/design-system/review-all-gdds/gate-check 等多个 skill 内频繁 spawn。CodeBuddy 串行模式下，此角色的 6 个 Gate 应在多数 skill 内改为"提示词内嵌决策框架"，仅在 CD-PHASE-GATE 和用户手动咨询时真正 spawn。）

**关键改造点**：
1. `model: opus` → CodeBuddy 无法在 frontmatter 绑定模型，需在提示词正文中标注"建议使用最强模型"
2. `memory: user` → CodeBuddy 全局 Memory 可承载（功能等价）
3. `disallowedTools: Bash` → CodeBuddy Subagent 的 frontmatter 支持 `allowed-tools` 字段，可声明工具白名单达成等效效果
4. `skills: [brainstorm, design-review]` → CodeBuddy 无 agent-skill 绑定语法，需在 skill 内显式调用此 agent
5. 6 个 Gate 提示词文本可直接复用，但触发机制需改为 skill 内 spawn subagent 串行调用
6. **决策骨架（5 步工作流）与另外两位 Director 完全相同**，建议抽离为共享 snippet，三个 agent 都引用，减少重复

**调用频率建议**：**低频**（仅在阶段过渡 `/gate-check` 或用户手动 `@creative-director` 咨询时 spawn；其他 skill 内改为内嵌决策框架片段）

**适合保留档位**：
- 极简档 ✅（核心角色，决定项目方向）
- 标准档 ✅
- 完整档 ✅

---

## 2. technical-director（技术总监）

### 一句话定位

技术愿景的最终决策者，负责保证所有代码、系统、工具能形成一个连贯、可维护、高性能的整体；批准每个 ADR、每次第三方库引入、每条性能预算。

### Frontmatter 元信息

```yaml
name: technical-director
description: "...all high-level technical decisions including engine architecture, technology choices, performance strategy, and technical risk management..."
tools: Read, Glob, Grep, Write, Edit, Bash, WebSearch       # 允许 Bash（评估技术、跑测试）
model: opus
maxTurns: 30
memory: user
```

**与 creative-director 的差异**：
- 允许 Bash（需要执行测试命令、查看构建日志）
- 没有 disallowedTools 限制
- 没有 skills 字段绑定

### 核心职责（7 项）

| 职责 | 通俗解释 |
|---|---|
| **架构所有权** | 定义和维护高层系统架构，每个主要系统必须有 ADR 经其批准 |
| **技术评估** | 所有第三方库、中间件、工具、引擎特性引入前必须评估批准 |
| **性能策略** | 制定帧时间、内存、加载时间、网络带宽等性能预算 |
| **技术风险评估** | 维护技术风险登记册，确保每个风险都有缓解策略 |
| **跨系统集成** | 不同程序员的系统互相调用时，定义接口契约和数据流 |
| **代码质量标准** | 定义编码标准、代码评审策略、测试要求 |
| **技术债管理** | 跟踪技术债、优先偿还、防止债务累积威胁里程碑 |

### 决策框架（6 个评估维度）

1. **正确性**（Correctness）：解决实际问题吗？
2. **简洁性**（Simplicity）：这是最简单可行方案吗？
3. **性能**（Performance）：满足性能预算吗？
4. **可维护性**（Maintainability）：另一个开发者 6 个月后能理解修改吗？
5. **可测试性**（Testability）：能被有意义地测试吗？
6. **可逆性**（Reversibility）：将来改这个决策代价多大？

### 涉及的 Director Gates

| Gate ID | 触发场景 | 判定词 |
|---|---|---|
| TD-SYSTEM-BOUNDARY | systems-index 阶段 3 后 | APPROVE / CONCERNS / REJECT |
| TD-FEASIBILITY | 概念阶段技术风险识别后 | VIABLE / CONCERNS / HIGH RISK |
| TD-ARCHITECTURE | 主架构文档完成后 | APPROVE / CONCERNS / REJECT |
| TD-ADR | 每份 ADR 起草后 | APPROVE / CONCERNS / REJECT |
| TD-ENGINE-RISK | 触及引擎截止后 API 时 | APPROVE / CONCERNS / REJECT |
| TD-PHASE-GATE | 阶段过渡时（必须） | READY / CONCERNS / NOT READY |

提示词中明确还涉及 `TD-CHANGE-IMPACT` / `TD-MANIFEST` 两个 Gate（用于变更影响评估和清单审核）。

### 上下游关系

**委派给**：lead-programmer / engine-programmer / network-programmer / devops-engineer / technical-artist / performance-analyst

**升级目标**：
- lead-programmer 的代码决策影响架构时
- 任何跨系统技术冲突
- 性能预算违规
- 技术引入申请

### 禁止做

- 做创意/设计决策
- 直接写 gameplay 代码
- 管理 Sprint 排期
- 批准/拒绝游戏设计
- 实现具体功能

### 输出格式（ADR 标准结构）

- Title / Status（Proposed/Accepted/Deprecated/Superseded）
- Context / Decision / Consequences
- Performance Implications
- Alternatives Considered

### CodeBuddy 适配评级

**移植类型**：直接移植（提示词）+ 改造移植（memory）

**移植形态**：**A — Gate 专用角色**  
（提供架构级审查，原本在 create-architecture / architecture-decision / architecture-review / code-review / gate-check 等多个 skill 内频繁 spawn。涉及 8 个 Gate（TD-SYSTEM-BOUNDARY / TD-FEASIBILITY / TD-ARCHITECTURE / TD-ADR / TD-ENGINE-RISK / TD-CHANGE-IMPACT / TD-MANIFEST / TD-PHASE-GATE）。CodeBuddy 串行模式下，per-ADR 级别的 TD-ADR 应改为"阶段末批量审查"，per-skill 的内联 Gate 改为提示词内嵌。）

**关键改造点**：
1. `model: opus` → 提示词正文标注"建议使用最强模型，因涉及多文档综合判断"
2. `memory: user` → CodeBuddy 全局 Memory
3. 提示词文本完全平台无关，全部直接复用
4. 8 个 Gate 提示词可全部复用，但触发机制重设计
5. **5 步决策骨架**与 creative-director / producer 完全一致，可共享 snippet
6. 原本"每个 ADR 一次 TD-ADR Gate"的高频调用，建议改为"每个阶段末一次批量 ADR 审查"

**调用频率建议**：**中频**（阶段过渡 + 关键 ADR 起草 + 架构文档完成 + 用户手动咨询；per-skill 内联 gate 改为提示词内嵌）

**适合保留档位**：
- 极简档 ✅（编码项目离不开技术决策）
- 标准档 ✅
- 完整档 ✅

---

## 3. producer（制作人）

### 一句话定位

整个项目的"项目经理"，负责确保游戏按时、在范围内、达到质量标准发布；规划 Sprint、跟踪里程碑、管理风险、协调跨部门工作。是 CCGS 中**唯一可以向所有 agent 分配任务**的角色。

### Frontmatter 元信息

```yaml
name: producer
description: "...sprint planning, milestone tracking, risk management, scope negotiation, and cross-department coordination..."
tools: Read, Glob, Grep, Write, Edit, Bash, WebSearch
model: opus
maxTurns: 30
memory: user
skills: [sprint-plan, scope-check, estimate, milestone-review]
```

**与其他两位 Director 的差异**：
- 绑定了 4 个 skill（最多）—— 表明 producer 是"主动型"角色，会被这些 skill 频繁调用
- 同样允许 Bash（需要查 git 历史、跑构建）

### 核心职责（7 项）

| 职责 | 通俗解释 |
|---|---|
| **Sprint 规划** | 把里程碑拆成 1-2 周 Sprint，每项有 owner / 估时 / 依赖 / 验收标准 |
| **里程碑管理** | 定义里程碑目标、跟踪进度，提前 2 个 Sprint 预警风险 |
| **范围管理** | 项目威胁超产能时，协调创意总监和技术总监谈判，文档化所有范围变更 |
| **风险管理** | 维护风险登记册（概率/影响/owner/缓解策略），每周审查 |
| **跨部门协调** | 一个功能涉及多个部门时（如新敌人需设计/美术/编程/音频/QA），制定协调计划并跟踪交接 |
| **回顾会议** | Sprint 和里程碑后主持回顾，记录什么有效、什么失败、行动项 |
| **状态报告** | 生成清晰、诚实的状态报告，及早暴露问题 |

### Sprint 规划硬性规则

- 每个任务 1-3 天可完成（粒度限制）
- 有依赖的任务必须明确列出依赖
- 不允许同一任务分给多个 agent
- 20% 容量作为"未计划工作和 Bug 修复"缓冲
- 关键路径任务必须识别并高亮

### 涉及的 Director Gates

| Gate ID | 触发场景 | 判定词 |
|---|---|---|
| PR-SCOPE | 范围层级定义后 | REALISTIC / OPTIMISTIC / UNREALISTIC |
| PR-SPRINT | Sprint 规划前 | REALISTIC / CONCERNS / UNREALISTIC |
| PR-MILESTONE | 里程碑评审时 | ON TRACK / AT RISK / OFF TRACK |
| PR-EPIC | create-epics 后 | REALISTIC / CONCERNS / UNREALISTIC |
| PR-PHASE-GATE | 阶段过渡时（必须） | READY / CONCERNS / NOT READY |

注意 producer 的判定词与 CD/TD 不同——用 REALISTIC/UNREALISTIC 等更"项目管理化"的词汇。

### 上下游关系

**委派权限**：所有 agent（在该 agent 域内分配任务）。这是 producer 的特殊权限。

**升级目标**：
- 任何排期冲突
- 部门间资源竞争
- 任何 agent 的范围担忧
- 外部依赖延迟

### 禁止做

- 做创意决策
- 做技术架构决策
- 批准游戏设计变更
- 写代码、美术方向或叙事内容
- **越权裁决质量问题**（应促成讨论，让领域专家决策）

### 输出格式（Sprint Plan 模板）

```
## Sprint [N] -- [Date Range]
### Goals
### Tasks
| ID | Task | Owner | Estimate | Dependencies | Status |
### Risks
| Risk | Probability | Impact | Mitigation |
### Notes
```

### CodeBuddy 适配评级

**移植类型**：直接移植（提示词 + Sprint 模板 + 风险登记册格式）+ 改造移植（skills 绑定 + 调用方式）

**移植形态**：**A — Gate 专用角色**（但有特殊处理，见下方说明）  

> **特别深度分析（producer 是否仍应存在？）**  
> 由于 CodeBuddy 无并行 subagent，producer 作为"项目经理"在多 skill 里被高频 spawn 的模式不再经济。但经逐项分析其 7 项职责后发现：**6/7 职责与并行无关**，核心价值是"项目经理思维"而非"调度器"。因此 **producer 应当保留，但调用模式必须改变**：
>
> 1. 原本内嵌在 `/sprint-plan`、`/milestone-review` 等 skill 里的 spawn 调用 → 改为 skill 提示词**内嵌 producer 的决策逻辑**（Sprint 硬性规则、模板、风险登记册格式直接平铺到 skill 正文）
> 2. 保留 producer.md 作为**独立 Gate 角色**（PR-PHASE-GATE + PR-SCOPE 的专用审查者）
> 3. 保留作为**用户手动咨询角色**（`@producer 我们 2 周能做完这个吗？`）
> 4. 原本绑定的 4 个 skill（sprint-plan / scope-check / estimate / milestone-review）从"自动 spawn producer"改为"引用 producer 的提示词片段"
>
> 这样既保留了提示词内容的价值（Sprint 模板、风险格式等可复用），又避免了高频 subagent 调用的性能代价。

**关键改造点**：
1. `model: opus` → 提示词正文注明
2. `memory: user` → CodeBuddy 全局 Memory
3. `skills: [sprint-plan, scope-check, estimate, milestone-review]` → 改为"这些 skill 引用 producer 的提示词片段"，不再自动 spawn
4. **Sprint Plan 模板、风险登记册格式、Sprint 硬性规则（1-3 天/20% 缓冲）等拆出**，平铺进对应 skill 正文
5. 保留 5 个 Gate（PR-SCOPE / PR-SPRINT / PR-MILESTONE / PR-EPIC / PR-PHASE-GATE），但 PR-SPRINT 和 PR-EPIC 在 `lean`/`solo` 模式下默认跳过
6. **5 步决策骨架**与 CD/TD 共享 snippet

**调用频率建议**：**低频**（PR-PHASE-GATE 阶段过渡 + PR-SCOPE 重大范围裁决 + 用户手动 `@producer` 咨询；日常 Sprint 规划由 skill 提示词承担，不 spawn producer）

**适合保留档位**：
- 极简档 ⚪（1-2 周的 Game Jam 可不要独立 producer，sprint-plan skill 自带 producer 思维即可）
- 标准档 ✅（任何超过 1 周的项目都需要，但作为 Gate 角色而非日常调度器）
- 完整档 ✅

---

## Tier 1 总监层横向规律

通读三个 Director 文件后，可以提炼以下共性模式：

### 模式 1：决策骨架完全一致

三位 Director 的"五步战略决策工作流"完全相同：
```
1. 理解背景 → 2. 框定决策 → 3. 提供 2-3 个选项 → 4. 推荐 + 留决策权给用户 → 5. 文档化 + 通知 + 设成功标准
```

这意味着移植时可以把这部分提示词**抽离为共享 snippet**，三个 agent 都引用。

### 模式 2：Gate 输出格式严格一致

所有 Gate 响应必须以 `[GATE-ID]: VERDICT` 作为第一行，方便调用方读取首行判定。**这是一个关键的协议约定，移植时必须保留**。

### 模式 3：用 disallowedTools 做安全防线

只有 creative-director 显式禁了 Bash。这个模式可以延伸到 CodeBuddy：通过 Subagent 的 `allowed-tools` 字段做白名单（CodeBuddy 不支持 disallowedTools 黑名单，但可以反向表达——只声明允许的工具）。

### 模式 4：禁止做列表

每个 Director 都明确列出"什么不该做"。这是 CCGS 的精髓之一——通过明确的反向边界防止 agent 越权。这部分提示词非常有价值，应当原样移植。

### 模式 5：判定词汇按角色分化

| 角色 | 三档判定 |
|---|---|
| Creative Director | APPROVE / CONCERNS / REJECT |
| Technical Director | APPROVE / CONCERNS / REJECT 或 VIABLE / CONCERNS / HIGH RISK |
| Producer | REALISTIC / CONCERNS / UNREALISTIC 或 ON TRACK / AT RISK / OFF TRACK |

各角色用领域内的专业词汇，避免"通用 APPROVE"显得敷衍。移植时这点应保留——用对的词比用统一的词更有说服力。

### 模式 6：Tier 1 全部归类为"形态 A — Gate 专用"

这是本册对 Director 层最重要的移植结论：

| 判据 | 三位 Director 的表现 |
|---|---|
| 提示词内容有独立复用价值？ | ✅ 有（战略决策框架、pillar 理论、性能预算概念等无法平铺进 skill） |
| 主要产出是审查意见还是具体产物？ | 审查意见（APPROVE / CONCERNS / REJECT / REALISTIC 等） |
| 在 CCGS 中被频繁跨 skill spawn？ | ✅ 是（每个 workflow 阶段至少一次） |
| CodeBuddy 串行模式下高频 spawn 的代价？ | 高（每次 2-5 分钟等待） |

**结论**：三位 Director 都应保留独立 md 文件，但调用频率从"每个相关 skill"大幅降到"阶段过渡 Gate + 用户手动咨询"。**原本内嵌在各 skill 里的决策框架片段应当平铺进 skill 正文**，不再需要每次都 spawn Director 来"说同样的话"。

这一原则贯穿本册后续所有 Director 级和 Lead 级角色的评级。

---

# Tier 2 — Department Leads（部门负责人）

> 共 8 个角色：game-designer / lead-programmer / art-director / audio-director / narrative-director / qa-lead / release-manager / localization-lead。
> 这是工作室的"中层管理"——介于战略决策（Director）和具体执行（Specialist）之间。
> 全部使用 Sonnet 模型，大部分 `memory: project`（除 release-manager 未声明 memory）。
>
> **形态分布预告**：
> - 形态 A（Gate 专用，有独立 Gate 的）：art-director / narrative-director / qa-lead（3 个）
> - 形态 B（执行，产出具体文档/方案）：game-designer / lead-programmer / audio-director / release-manager / localization-lead（5 个）
> - 注意 lead-programmer 和 qa-lead 同时有 Gate 和执行职责，归类为"主形态 + 次形态"

---

## 4. game-designer（游戏设计主管）

### 一句话定位

游戏"怎么玩"的总负责人：设计核心循环、系统、战斗、经济、进度，所有机制层面的决策都来自这里。提供 GDD 草稿、平衡方案、机制规格。

### Frontmatter 元信息

```yaml
name: game-designer
tools: Read, Glob, Grep, Write, Edit, WebSearch
model: sonnet
maxTurns: 20
disallowedTools: Bash       # 设计师不碰 shell
skills: [design-review, balance-check, brainstorm]
memory: project
```

### 核心职责（6 项）

| 职责 | 通俗解释 |
|---|---|
| **核心循环设计** | 30秒微循环 / 5-15分钟中循环 / 会话级宏循环，每个机制必须挂到至少一个循环 |
| **系统设计** | 用"系统动力学思维"，显式标出增益循环（growth engines）和稳定循环（balancing loops） |
| **平衡框架** | MDA/SDT/Bartle/Quantic Foundry 四种理论框架；4 种平衡方式（transitive/intransitive/frustra/asymmetric） |
| **玩家体验映射** | 用 MDA 框架从目标美学反推动态和机制；SDT 验证心理需求满足 |
| **边界条件文档化** | 每个机制要考虑支配性策略、漏洞、不有趣均衡态，应用 Sirlin 的"Playing to Win"框架区分健康掌握与退化玩法 |
| **设计文档维护** | 维护 `design/gdd/` 下的 GDD 作为实现者的真实依据 |

### 引用的理论框架（4 套）

- **MDA Framework**（Hunicke 2004）：从 Aesthetics 反推 Dynamics 再到 Mechanics
- **SDT**（Deci & Ryan）：Autonomy / Competence / Relatedness
- **Flow State**（Csikszentmihalyi）：锯齿形难度曲线、0.5 秒微反馈
- **Quantic Foundry 动机模型**：Action / Social / Mastery / Achievement / Immersion / Creativity

### 核心技术内容：GDD 8 必要节

每份 GDD 必须包含：Overview / Player Fantasy / Detailed Rules / Formulas / Edge Cases / Dependencies / Tuning Knobs / Acceptance Criteria

### 平衡方法论（3 类调节旋钮）

1. **Feel knobs**（感觉旋钮）：攻速、移速、动画时长 → 靠 playtest 直觉调
2. **Curve knobs**（曲线旋钮）：XP 需求、属性缩放、成本乘数 → 靠数学建模调
3. **Gate knobs**（关卡旋钮）：等级门槛、资源阈值、冷却 → 靠会话长度目标调

所有调节旋钮必须放在外部数据文件（`assets/data/`），绝不硬编码。

### 涉及的 Director Gates

- **CD-GDD-ALIGN**（接收方）：GDD 起草后由 creative-director 审核
- **CD-SYSTEMS**（贡献方）：系统分解后由 creative-director 审核整体
- 本身不主持 Gate（game-designer 是"产出 Gate 的输入"，而非 Gate 主体）

### 上下游关系

**委派给**：systems-designer / level-designer / economy-designer

**汇报给**：creative-director（愿景对齐）

**协作**：lead-programmer（可行性）、narrative-director（机制叙事协调）、ux-designer（玩家可读性）、analytics-engineer（数据驱动平衡迭代）

### 禁止做

- 写实现代码（只写规格）
- 做美术或音频方向决策
- 写最终叙事内容
- 做架构或技术选型
- 未经 producer 批准批准范围变更

### CodeBuddy 适配评级

**移植类型**：直接移植（MDA/SDT/GDD 8 必要节等理论框架文本）+ 改造移植（memory + skills 绑定）

**移植形态**：**B — 执行角色**  
（主要产出 GDD 文件，由 `/design-system`、`/quick-design`、`/brainstorm` 等 skill 调用。不主持 Gate，但其产出会被 CD-GDD-ALIGN 审查。）

**关键改造点**：
1. `disallowedTools: Bash` → CodeBuddy 用 allowed-tools 白名单反向达成（不包含 Bash）
2. `memory: project` → CodeBuddy 无对应，改用 CODEBUDDY.md 记录"游戏支柱、已批准的核心系统"
3. `skills: [design-review, balance-check, brainstorm]` → 改为"这些 skill 内部调用 game-designer 这个 subagent"
4. **GDD 8 必要节、MDA/SDT 理论框架文本**是纯文本内容，直接复用
5. 由于是执行角色，在 CodeBuddy 串行模式下每次调用接受单次 subagent 延迟

**调用频率建议**：**高频**（设计阶段几乎每个 design 类 skill 都会 spawn）

**适合保留档位**：
- 极简档 ✅（游戏设计是核心产出，必须保留）
- 标准档 ✅
- 完整档 ✅

---

## 5. lead-programmer（首席程序员）

### 一句话定位

把技术总监的架构愿景翻译为具体代码结构；所有代码评审的主持者；决定"这个设计怎么用代码实现"。

### Frontmatter 元信息

```yaml
name: lead-programmer
tools: Read, Glob, Grep, Write, Edit, Bash      # 允许 Bash（跑测试、看构建）
model: sonnet
maxTurns: 20
skills: [code-review, architecture-decision, tech-debt]
memory: project
```

### 核心职责（6 项）

| 职责 | 通俗解释 |
|---|---|
| **代码架构** | 设计类层级、模块边界、接口契约、数据流 |
| **代码评审** | 检查正确性、可读性、性能、可测试性、规范遵循 |
| **API 设计** | 为被依赖的系统定义稳定、最小、文档化的公开 API |
| **重构策略** | 识别需要重构的代码，规划安全的增量重构步骤 |
| **模式一致性** | 确保项目内设计模式用法统一 |
| **知识分布** | 防止某个系统只有一个程序员懂，强制文档化和配对评审 |

### 编码标准强制项

- 所有 public 方法和类必须有文档注释
- 圈复杂度 ≤ 10 per 方法
- 方法长度 ≤ 40 行（不含数据声明）
- 依赖注入，禁止状态单例
- 配置值必须从数据文件加载
- 每个系统必须暴露清晰接口（非具体类依赖）

### 涉及的 Director Gates

| Gate ID | 何时被召唤 | 判定词 |
|---|---|---|
| **LP-FEASIBILITY** | 主架构文档完成后 | FEASIBLE / CONCERNS / INFEASIBLE |
| **LP-CODE-REVIEW** | Story 实现后或 `/code-review` 时 | APPROVE / CONCERNS / REJECT |

这是 8 个 Lead 中少数主持自己 Gate 的 2 个角色之一（另一个是 qa-lead）。

### 上下游关系

**委派给**：gameplay-programmer / engine-programmer / ai-programmer / network-programmer / tools-programmer / ui-programmer（6 个 Tier 3 程序员专员）

**汇报给**：technical-director

**协作**：game-designer（功能规格）、qa-lead（可测试性）

### 禁止做

- 未经 technical-director 批准做高层架构决策
- 推翻 game-designer 的游戏设计决策（可提出关切）
- 直接实现功能（交给 specialist programmer）
- 做美术管线或资产决策
- 修改构建基础设施

### CodeBuddy 适配评级

**移植类型**：直接移植（编码标准文本 + 6 步实现工作流）+ 改造移植（memory + skills + Gate 机制）

**移植形态**：**A + B 混合形态**  
（主形态是 A：作为 LP-FEASIBILITY / LP-CODE-REVIEW Gate 主体被召唤；次形态是 B：在代码架构决策时会产出具体的类结构文档。移植时建议以 Gate 专用为主。）

**关键改造点**：
1. `memory: project` → 项目代码约定放 CODEBUDDY.md 或 `alwaysApply: true` 的 Rules
2. `skills: [code-review, architecture-decision, tech-debt]` → 改为 skill 内引用 lead-programmer 提示词片段
3. **2 个 Gate 提示词文本可复用**，但 LP-CODE-REVIEW 在 CCGS 是"每个 Story 一次"，CodeBuddy 串行模式下建议改为"每个 Sprint 末批量代码审查"
4. 编码标准（圈复杂度/方法长度/注释要求）应同时放进 Rules（`alwaysApply: true`）全局激活，不依赖每次 spawn lead-programmer
5. 6 步实现工作流与 qa-lead/release-manager/localization-lead 完全相同（共享 snippet）

**调用频率建议**：**中频**（架构评审 + Sprint 末代码审查 + 重大重构决策）

**适合保留档位**：
- 极简档 ✅（任何编码项目都需要代码质量把关）
- 标准档 ✅
- 完整档 ✅

---

## 6. art-director（美术总监）

### 一句话定位

游戏视觉身份的守护者：艺术圣经（Art Bible）的作者、资产命名规范的制定者、视觉一致性的审核者。是 8 个 Lead 中**独自持有 3 个 Director 级 Gate** 的特殊角色（在 Gate 系统中与 Tier 1 并列）。

### Frontmatter 元信息

```yaml
name: art-director
tools: Read, Glob, Grep, Write, Edit, WebSearch
model: sonnet
maxTurns: 20
disallowedTools: Bash
memory: project
```

> **注意**：没有绑定 skill，但会被 `/art-bible`、`/asset-spec`、`/gate-check` 等 skill 频繁 spawn。

### 核心职责（6 项）

| 职责 | 通俗解释 |
|---|---|
| **艺术圣经维护** | 风格、色彩、比例、材质、光照、视觉层级的真实依据 |
| **风格指南执行** | 审核所有视觉资产和 UI 稿，按艺术圣经给出修正指引 |
| **资产规格** | 每个资产类别的分辨率、格式、命名、色彩配置、多边形/贴图预算 |
| **UI/UX 视觉设计** | 指导所有用户界面视觉设计 |
| **色彩和光照方向** | 定义游戏的色彩语言：色彩的含义、光照如何支撑情绪、调色板变化如何传达游戏状态 |
| **视觉层级** | 确保每个屏幕和场景里玩家视线被正确引导 |

### 资产命名约定

`[category]_[name]_[variant]_[size].[ext]`  
例：`env_tree_oak_large.png` / `char_hero_idle_01.png` / `ui_btn_primary_hover.png` / `vfx_explosion_loop_small.png`

### 涉及的 Director Gates

| Gate ID | 触发时机 | 判定词 |
|---|---|---|
| **AD-CONCEPT-VISUAL** | 游戏支柱锁定后（与 CD-PILLARS 并行） | CONCEPTS / STRONG / CONCERNS |
| **AD-ART-BIBLE** | `/art-bible` 完成后 | APPROVE / CONCERNS / REJECT |
| **AD-PHASE-GATE** | `/gate-check` 时（必须，与 CD/TD/PR-PHASE-GATE 并列） | READY / CONCERNS / NOT READY |
| **AD-VISUAL** | 美术方向决策/新资产类型引入时 | APPROVE / CONCERNS / REJECT |

这是 8 个 Lead 中**唯一**被归类到 Tier 1 级 Gate 的角色（AD-PHASE-GATE 与 Tier 1 总监并列）。

### 上下游关系

**委派给**：technical-artist / ux-designer

**汇报给**：creative-director（愿景对齐）

**协作**：technical-artist（可行性）、ui-programmer（实现约束）

### 禁止做

- 写代码或 shader（交给 technical-artist）
- 画实际像素/3D 美术（只写规格）
- 做 gameplay 或叙事决策
- 修改资产管线工具
- 批准范围增加

### CodeBuddy 适配评级

**移植类型**：直接移植（艺术圣经结构 + 资产命名约定）+ 改造移植（4 个 Gate 触发机制）

**移植形态**：**A — Gate 专用角色**  
（唯一的 Tier 2 全 A 形态 Lead。4 个 Gate 中 AD-PHASE-GATE 与三位 Tier 1 总监并列，在阶段门控中是必须主体。移植时地位与 CD/TD/PR 一致。）

**关键改造点**：
1. `disallowedTools: Bash` → CodeBuddy allowed-tools 反向白名单
2. `memory: project` → CODEBUDDY.md + Rules 中放艺术圣经关键决策
3. **4 个 Gate 提示词完全可复用**，但 AD-PHASE-GATE 原本与 CD/TD/PR 并行，CodeBuddy 串行模式下 4 个 PHASE-GATE 依次执行耗时 4 倍，**建议合并为一个综合审核 Subagent**（以 PR-PHASE-GATE 为主，其中包含 CD/TD/AD 视角）
4. 艺术圣经的 9 节结构（通过 `/art-bible` skill 生成）可作为 CodeBuddy skill 的模板直接复用
5. 资产命名约定放入 Rules（`alwaysApply: true`），自动规范所有资产文件

**调用频率建议**：**中频**（阶段过渡 + 艺术圣经起草完成 + 新资产类型引入时；AD-VISUAL 在日常可跳过）

**适合保留档位**：
- 极简档 ⚪（Game Jam 可能不需要独立艺术总监，靠 CODEBUDDY.md 内的艺术约定即可）
- 标准档 ✅
- 完整档 ✅

---

## 7. audio-director（音频总监）

### 一句话定位

游戏声音身份的守护者：音乐方向、音效调色板、音频事件架构、混音策略的制定者。不主持任何 Gate，但为声音设计决策提供专业支撑。

### Frontmatter 元信息

```yaml
name: audio-director
tools: Read, Glob, Grep, Write, Edit, WebSearch
model: sonnet
maxTurns: 20
disallowedTools: Bash
memory: project
```

### 核心职责（6 项）

| 职责 | 通俗解释 |
|---|---|
| **声音调色板定义** | 原声 vs 合成、干净 vs 失真、稀疏 vs 密集，记录参考曲目和每个游戏上下文的声音轮廓 |
| **音乐方向** | 音乐风格、乐器、动态音乐系统行为、游戏状态和区域的情感映射 |
| **音频事件架构** | 触发规则、声音分层、优先级系统、闪避规则 |
| **混音策略** | 音量层级、空间音频规则、频率平衡目标 |
| **自适应音频设计** | 音频如何响应游戏状态（强度、区域、战斗/探索、生命值） |
| **音频资产规格** | 格式、采样率、命名、响度目标（LUFS）、文件大小预算 |

### 音频命名约定

`[category]_[context]_[name]_[variant].[ext]`  
例：`sfx_combat_sword_swing_01.ogg` / `mus_explore_forest_calm_loop.ogg` / `amb_env_cave_drip_loop.ogg`

### 涉及的 Director Gates

**无自己主持的 Gate**（这是 audio-director 与 art-director 的最大差异——CCGS 没有为 audio 设置 Gate 系统，可能是设计上的不对称）。

### 上下游关系

**委派给**：sound-designer（SFX 规格文档和事件列表）

**汇报给**：creative-director（愿景对齐）

**协作**：game-designer（机械音频反馈）、narrative-director（情感对齐）、lead-programmer（音频系统实现）

### 禁止做

- 创建实际音频文件或音乐
- 写音频引擎代码
- 做视觉或叙事决策
- 未经 technical-director 批准更换音频中间件

### CodeBuddy 适配评级

**移植类型**：直接移植（提示词 + 命名约定）+ 改造移植（memory）

**移植形态**：**B — 执行角色**  
（无 Gate 主持，主要产出音频规格文档和声音调色板决策，由 `/team-audio`、`/design-system` 等 skill 调用。）

**关键改造点**：
1. `disallowedTools: Bash` → allowed-tools 反向白名单
2. `memory: project` → CODEBUDDY.md 记录已批准的声音调色板
3. 音频命名约定放入 Rules（`alwaysApply: true`）
4. 5 步协作协议与 game-designer/art-director/narrative-director 完全相同（共享 snippet）
5. 由于无 Gate，调用频率较低，可在 skill 内简化为串行 spawn

**调用频率建议**：**低频**（声音方向决策时 + 新音频系统引入时）

**适合保留档位**：
- 极简档 ⚪（小型项目可跳过，音频规范写进 CODEBUDDY.md 即可）
- 标准档 ✅
- 完整档 ✅

---

## 8. narrative-director（叙事总监）

### 一句话定位

故事架构师、世界观守护者、角色设计主管。关注结构和方向，不写具体对话。主持 ND-CONSISTENCY Gate 检查叙事内部一致性。

### Frontmatter 元信息

```yaml
name: narrative-director
tools: Read, Glob, Grep, Write, Edit, WebSearch
model: sonnet
maxTurns: 20
disallowedTools: Bash
memory: project
```

### 核心职责（6 项）

| 职责 | 通俗解释 |
|---|---|
| **故事架构** | 设计叙事结构：幕间划分、主要情节节点、分支点、结局路径 |
| **世界观框架** | 定义世界规则：历史、派系、文化、魔法/科技系统、地理、生态 |
| **角色设计** | 角色弧、动机、关系、声音轮廓、叙事功能 |
| **机制叙事和谐**（Ludonarrative Harmony） | 游戏机制和故事互相强化，标记机制叙事失调 |
| **对话系统设计** | 分支、状态追踪、条件检查、变量插入 |
| **叙事节奏** | 在游戏时长中规划叙事交付，平衡阐述/行动/悬念/揭示 |

### 世界元素文档标准（6 节）

Core Concept / Rules / History / Connections / Player Relevance / Contradictions Check

### 涉及的 Director Gates

| Gate ID | 触发时机 | 判定词 |
|---|---|---|
| **ND-CONSISTENCY** | 叙事内容（对话/传说/物品描述）生成后 | APPROVE / CONCERNS / REJECT |

还会被 CD-NARRATIVE（creative-director 的 Gate）召唤参与一致性讨论。

### 上下游关系

**委派给**：writer（对话写作、传说条目、文本内容）、world-builder（详细世界设计）

**汇报给**：creative-director

**协作**：game-designer（ludonarrative 设计）、art-director（视觉叙事）、audio-director（情感基调）

### 禁止做

- 写最终对话（交给 writer）
- 做游戏机制决策
- 直接指导视觉设计
- 做对话系统技术决策
- 未经 producer 批准扩大叙事范围

### CodeBuddy 适配评级

**移植类型**：直接移植（世界观文档结构 + ludonarrative 理论）+ 改造移植

**移植形态**：**A + B 混合形态**（主 A 次 B）  
（主形态 A：作为 ND-CONSISTENCY 和 CD-NARRATIVE 的 Gate 主体；次形态 B：在世界观起草时产出 story bible、character profile 等文档。）

**关键改造点**：
1. `disallowedTools: Bash` → allowed-tools 反向
2. `memory: project` → CODEBUDDY.md 记录已批准的世界观规则
3. **ND-CONSISTENCY Gate 提示词可直接复用**，但 CCGS 中每次叙事内容生成都 spawn，CodeBuddy 串行模式下建议改为"每个章节/区域批量审查"
4. 6 节世界元素模板直接复用

**调用频率建议**：**中频**（新叙事内容生成后 + 世界观重大修改时；日常对话写作由 writer 完成，narrative-director 不每次出场）

**适合保留档位**：
- 极简档 ⚪（纯机制游戏可跳过，有叙事的游戏必须保留）
- 标准档 ✅
- 完整档 ✅

---

## 9. qa-lead（QA 负责人）

### 一句话定位

测试策略的主人 + "Definition of Done"的守门员。秉承"shift-left testing"（从 Sprint 开始就介入，不是最后才介入）。主持 QL-STORY-READY 和 QL-TEST-COVERAGE 两个 Gate。

### Frontmatter 元信息

```yaml
name: qa-lead
tools: Read, Glob, Grep, Write, Edit, Bash      # 允许 Bash（跑 smoke-check 等测试命令）
model: sonnet
maxTurns: 20
skills: [bug-report, release-checklist]
memory: project
```

### 核心职责（8 项）

| 职责 | 通俗解释 |
|---|---|
| **测试策略与 QA 规划** | Sprint 开始时分类故事类型，区分自动/手动测试 |
| **测试证据门控** | Logic/Integration 故事无测试文件则阻塞"Complete" |
| **Smoke Check 所有权** | 每次构建发给 QA 前必须 `/smoke-check` 通过 |
| **测试计划创建** | 功能/边界/回归/性能/兼容性全覆盖 |
| **Bug 分级** | S1 Critical / S2 Major / S3 Minor / S4 Trivial |
| **回归管理** | 维护覆盖关键路径的回归测试套件 |
| **发布质量门控** | 每个里程碑的质量门：崩溃率、关键 Bug 数、性能基准、功能完整性 |
| **游玩测试协调** | 设计游玩测试协议和问卷 |

### 故事类型 → 测试证据映射

这是 qa-lead 的核心"业务逻辑"——与 01 册测试标准一致：

| 故事类型 | 证据 | 阻塞级别 |
|---|---|---|
| Logic | 自动单元测试 | 阻塞 |
| Integration | 集成测试 OR 文档化游玩测试 | 阻塞 |
| Visual/Feel | 截图 + 负责人签字 | 建议 |
| UI | 手动步骤文档 OR 交互测试 | 建议 |
| Config/Data | Smoke check 通过 | 建议 |

### Bug 严重度定义

- **S1 Critical**：崩溃/数据丢失/进度阻塞 → 任何构建前必修
- **S2 Major**：显著 gameplay 影响/功能损坏 → 里程碑前必修
- **S3 Minor**：美化问题/小不便 → 容量允许时修
- **S4 Trivial**：抛光/小文字错误 → 最低优先级

### 涉及的 Director Gates

| Gate ID | 触发时机 | 判定词 |
|---|---|---|
| **QL-STORY-READY** | Story 进入 Sprint 前 | ADEQUATE / GAPS / INADEQUATE |
| **QL-TEST-COVERAGE** | Epic 完成或 Production→Polish 过渡时 | ADEQUATE / GAPS / INADEQUATE |

### 上下游关系

**委派给**：qa-tester（测试用例写作、测试执行）

**汇报给**：producer（排期）、technical-director（质量标准）

**协作**：lead-programmer（可测试性）、所有 Lead（特性专属测试规划）

### 禁止做

- 直接修 Bug（派给程序员）
- 基于 Bug 做游戏设计决策
- 因排期压力跳过测试
- 批准未过质量门的发布

### CodeBuddy 适配评级

**移植类型**：直接移植（Bug 分级、故事类型测试矩阵、QA Plan 结构）+ 改造移植

**移植形态**：**A + B 混合形态**  
（主 A：2 个 Gate 主体；次 B：产出 QA 计划、Smoke check 报告等文档。）

**关键改造点**：
1. `memory: project` → CODEBUDDY.md 记录质量门阈值（崩溃率/Bug 数等）
2. `skills: [bug-report, release-checklist]` → 改为 skill 内引用 qa-lead 提示词片段
3. **QL-STORY-READY Gate 原本每个 Story 进 Sprint 前都触发**，CodeBuddy 串行模式下建议改为"Sprint 规划时批量审查"
4. **QL-TEST-COVERAGE** 触发频率合理（Epic 完成时），可保持原样
5. 故事类型测试矩阵放入 Rules 或 CODEBUDDY.md，`alwaysApply: true`
6. Bug 分级标准放入 Rules，自动约束

**调用频率建议**：**中频**（Sprint 规划时 + Epic 完成时 + Smoke check 执行时）

**适合保留档位**：
- 极简档 ✅（测试门控是代码质量的关键防线，不能省）
- 标准档 ✅
- 完整档 ✅

---

## 10. release-manager（发布经理）

### 一句话定位

发布流水线的全流程所有者：构建、认证、商店提交、版本管理、发布日协调。不是决策者，而是"流程执行官"——确保每个步骤都按顺序、零遗漏执行。

### Frontmatter 元信息

```yaml
name: release-manager
tools: Read, Glob, Grep, Write, Edit, Bash
model: sonnet
maxTurns: 20
skills: [release-checklist, changelog, patch-notes]
# 注意：无 memory 声明
```

> **与其他 Lead 的差异**：`release-manager` 没有 `memory: project` 声明。这意味着发布流程对"项目长期记忆"依赖较低——每次发布都是独立完整的流程。

### 发布流水线（6 步严格顺序）

```
1. Build    → 可复现的构建
2. Test     → QA 签字、无 S1/S2
3. Cert     → 平台认证（TRC/TCR/Lotcheck）
4. Submit   → 商店上传 + 发布设置
5. Verify   → 真实硬件下载测试
6. Launch   → 发布 + 首小时指标监控
```

**任何步骤失败，流水线停止**——不允许跳过或并行。

### 核心职责

1. **平台认证** — 主机 TRC/TCR/Lotcheck；PC 商店 DRM/成就/手柄声明；移动商店权限/隐私政策
2. **版本号** — 语义化 `MAJOR.MINOR.PATCH` + 内部 `MAJOR.MINOR.PATCH.BUILD`
3. **商店页管理** — 描述文本 / 媒体资产 / 元数据 / 年龄评级 / 法务
4. **发布日协调** — 11 项清单（构建/商店页/下载/Day1 补丁/监控/社区/社媒/支持/值班/媒体 key）
5. **热修复流程** — Branch from tag → 最小修复 → QA → 认证 → 部署 → 回合入开发分支
6. **发布后监控** — 72 小时内关注崩溃率（目标 <0.1%）、留存、评价、社区、服务器

### 上下游关系

**汇报给**：producer

**协作**：devops-engineer / qa-lead / community-manager / technical-director / lead-programmer

### 禁止做

- 做创意、设计、技术决策
- 决定功能纳入/排除
- 批准范围变更
- 写营销文案

### CodeBuddy 适配评级

**移植类型**：直接移植（6 步流水线 + 11 项发布日清单 + 热修复流程）+ 改造移植（skills 绑定）

**移植形态**：**B — 执行角色**  
（无 Gate 主持，主要产出 release-checklist、changelog、patch-notes 等流程文档。）

**关键改造点**：
1. 无 memory 声明原样保留（CodeBuddy 无 `memory: project`，本来就不需要改造）
2. 6 步流水线模板可直接用作 CodeBuddy `/release-checklist` skill 的内容
3. 11 项发布日清单作为"复选框模板"放进 skill
4. 2 个热修复流程（hotfix / patch release）作为 skill 的分支逻辑
5. `skills: [release-checklist, changelog, patch-notes]` → 3 个 skill 内引用 release-manager 片段

**调用频率建议**：**低频**（发布时触发，非日常）

**适合保留档位**：
- 极简档 ⚪（Game Jam 无正式发布，不需要）
- 标准档 ⚪（Demo 发布可用，非核心）
- 完整档 ✅（商业项目必须）

---

## 11. localization-lead（本地化负责人）

### 一句话定位

国际化（i18n）架构师：字符串表、区域文件、回退链、翻译管线、RTL 支持、字体和字符集的全盘负责人。

### Frontmatter 元信息

```yaml
name: localization-lead
tools: Read, Glob, Grep, Write, Edit, Bash
model: sonnet
maxTurns: 20
memory: project
# 无 skills 绑定
```

### 核心职责（6 项）

| 职责 | 通俗解释 |
|---|---|
| **i18n 架构** | 字符串表、区域文件、回退链（fr-CA → fr → en）、运行时语言切换 |
| **字符串提取与管理** | 工作流规定：开发者用 i18n API，不能硬编码 |
| **翻译管线** | 字符串从开发 → 翻译 → 构建的完整流动 |
| **区域测试** | 格式/布局/文化问题的语言专属测试 |
| **字体和字符集** | 每个语言的字体覆盖和渲染 |
| **质量审核** | 验证翻译准确度和上下文正确性 |

### 关键技术规格

**Key 命名约定**：
- 层级点号命名：`menu.settings.audio.volume_label`、`dialogue.npc.guard.greeting_01`
- 每文件一个语言一个系统：`locales/en/ui_menu.json`、`locales/ja/ui_menu.json`

**文字适配考虑**：
- 德语/芬兰语比英语长 30-40%
- 中日文可能更短但需要更大字号
- 必须用 pseudolocalization（人工拉长字符串）早期测试 UI 适配

**RTL 支持**：水平镜像 UI、双向文本、数字保持 LTR、方向性 UI 元素翻转

### 区域测试清单

日期格式 / 数字格式 / 货币 / 时间格式 / 排序校对 / 输入法 / 文本渲染

### 字体要求矩阵

- Latin-extended（西欧/中欧/土耳其/越南）
- CJK（需要专门字体，考虑文件大小）
- Arabic/Hebrew（RTL shaping + ligatures）
- Cyrillic / Devanagari / Thai / Korean

### 上下游关系

**汇报给**：producer（排期、语言支持范围、预算）

**协作**：ui-programmer（文本渲染、自动适配、RTL）、writer（源文本质量和基调）、ux-designer（可变长度 UI 布局）、tools-programmer（本地化工具链）、qa-lead（区域测试规划）

### 禁止做

- 写实际翻译（交给翻译员）
- 做游戏设计决策
- 做 UI 设计决策
- 决定支持哪些语言（商业决策，给 producer）
- 修改叙事内容（协作 writer）

### CodeBuddy 适配评级

**移植类型**：直接移植（i18n 架构标准 + key 命名 + RTL 支持清单）+ 改造移植

**移植形态**：**B — 执行角色**  
（无 Gate，无 skills 绑定，主要在 `/localize` skill 被调用，产出 i18n 架构决策和本地化检查清单。）

**关键改造点**：
1. `memory: project` → CODEBUDDY.md 记录支持的语言列表、回退链、字体矩阵
2. **i18n key 命名约定**放入 Rules（`alwaysApply: true`）
3. **区域测试清单**作为 skill 模板直接复用
4. 字体矩阵作为 CODEBUDDY.md 的参考表

**调用频率建议**：**低频**（i18n 架构初设时 + 新语言加入时）

**适合保留档位**：
- 极简档 ❌（不打算国际化就不需要）
- 标准档 ⚪（视项目是否国际化）
- 完整档 ✅（商业项目通常需要）

---

## Tier 2 部门主管横向规律

### 模式 1：协作协议有 2 种变体

8 个 Lead 按"提示词协议模板"分 2 类：

**"设计型 4-步协议"**（game-designer / art-director / audio-director / narrative-director）：
```
Ask → Options → Draft (incremental) → Approval
```
强调"Question-First Workflow"、"4 个选项 + 利弊"、"逐节写文件"

**"实现型 6-步协议"**（lead-programmer / qa-lead / release-manager / localization-lead）：
```
Read spec → Ask arch questions → Propose → Implement → Approval → Next steps
```
强调"先读规格"、"提架构问题"、"展示代码"、"多文件变更列清单"

> **移植洞察**：这 2 种协议模板在 CCGS 是重复写在每个 agent 里的（增加维护成本）。移植到 CodeBuddy 时建议**抽离为 2 个共享 snippet**，agent 文件只引用即可。

### 模式 2：只有 3 个 Lead 主持自己的 Gate

| Lead | 自己的 Gate |
|---|---|
| lead-programmer | LP-FEASIBILITY / LP-CODE-REVIEW |
| qa-lead | QL-STORY-READY / QL-TEST-COVERAGE |
| art-director | AD-CONCEPT-VISUAL / AD-ART-BIBLE / AD-PHASE-GATE / AD-VISUAL（最多，4 个） |

其余 5 个 Lead 不主持 Gate，仅产出具体文档。**这与形态归类高度一致**：

- 主持 Gate 的 → 主形态 A（或 A+B）
- 不主持 Gate 的 → 主形态 B

### 模式 3：`disallowedTools: Bash` 是"纯设计型"的标志

8 个 Lead 中：
- 禁用 Bash 的（4 个）：game-designer / art-director / audio-director / narrative-director → 都是设计型，不该碰系统层
- 允许 Bash 的（4 个）：lead-programmer / qa-lead / release-manager / localization-lead → 实现型，需要跑测试/构建/工具

这个模式明确告诉移植方：**允许/禁止工具的分野等同于设计型/实现型的分野**。

### 模式 4：memory 策略基本统一

7/8 个 Lead 有 `memory: project`，只有 release-manager 没有。这反映出一个合理的设计判断——发布流程是"流水线化"的标准动作，不需要项目长期记忆。

### 模式 5：技术知识密度分化

| 高技术密度（提示词含大量技术参数） | 中等（规范为主） | 低（纯流程） |
|---|---|---|
| localization-lead（字体矩阵/RTL 规则）、game-designer（4 种理论框架） | art-director（命名约定）、audio-director（音频规格）、narrative-director（世界观结构） | release-manager（6 步流水线）、qa-lead（Bug 分级） |

**移植洞察**：高技术密度的 agent 提示词内容价值最大，**应完整保留**；低技术密度的相当于"流程模板"，价值在于 checklist 本身而非 agent 提示词。

### Tier 2 适配性小结（提前预览）

| Lead | 形态 | 极简 | 标准 | 完整 |
|---|---|---|---|---|
| game-designer | B | ✅ | ✅ | ✅ |
| lead-programmer | A+B | ✅ | ✅ | ✅ |
| art-director | A | ⚪ | ✅ | ✅ |
| audio-director | B | ⚪ | ✅ | ✅ |
| narrative-director | A+B | ⚪ | ✅ | ✅ |
| qa-lead | A+B | ✅ | ✅ | ✅ |
| release-manager | B | ⚪ | ⚪ | ✅ |
| localization-lead | B | ❌ | ⚪ | ✅ |

**极简档必保留的 Lead**：game-designer / lead-programmer / qa-lead（3 个——对应"设计/代码/测试"三大工作流）

---

# Tier 3 — Specialists（专员）

> Tier 3 是工作室的"执行层"——具体把设计变成产物。共约 38-41 人（agent-roster 列出 38 个，实际 `.claude/agents/` 含轻微差异，详见 01 册"实际盘点"）。
>
> Tier 3 按子部门分 5 大组 + 三引擎专员组：
> - **设计线**（3 人）：systems-designer / level-designer / economy-designer
> - **程序线**（6 人）：gameplay/engine/ai/network/tools/ui-programmer
> - **美术/音频/叙事线**（4 人）：technical-artist / sound-designer / writer / world-builder
> - **UX/原型/性能线**（3 人）：ux-designer / prototyper / performance-analyst
> - **运维/数据/安全/QA/无障碍/运营/社区线**（8 人）：devops-engineer / analytics-engineer / security-engineer / qa-tester / accessibility-specialist / live-ops-designer / community-manager
> - **三引擎专员组**（约 14-15 人）：godot / unity / unreal 各 4-5 个子专员
>
> 本批次按子部门分批输出，方便审阅。

---

## 批 A — 设计线（3 人）

### 12. systems-designer（系统设计师）

#### 一句话定位

把高层设计目标翻译为**可实现的精确规则集**：写公式、画交互矩阵、分析反馈循环、定义调参旋钮。负责"机制具体怎么算"，不负责"机制是什么"。

#### Frontmatter 元信息

```yaml
name: systems-designer
tools: Read, Glob, Grep, Write, Edit
model: sonnet
maxTurns: 20
disallowedTools: Bash
memory: project
```

#### 核心职责（5 项）

| 职责 | 通俗解释 |
|---|---|
| **公式设计** | 输出/恢复/进度/掉率等所有数值系统的数学公式；必须含命名表达式 + 变量表 + 范围 + 算例 |
| **交互矩阵** | 多元素相互作用（元素伤害、状态效果、阵营关系）显式列每种组合 |
| **反馈循环分析** | 标记正反馈/负反馈循环，区分"有意"和"需要阻尼"的 |
| **调参文档** | 每个系统的可调参数、安全范围、对玩法的影响 |
| **模拟规格** | 数学验证平衡，在实现前就能跑模拟 |

#### Formula Output Format（强制）

每个公式必须包含 4 项，缺一不可：
1. **命名表达式**（带清晰变量名的符号化方程）
2. **变量表**（Symbol / Type / Range / Description 4 列）
3. **输出范围**（clamped / bounded / unbounded 及理由）
4. **算例**（具体占位值代入）

> 这是 systems-designer 的**核心硬性产出标准**，与 game-designer 的 GDD 8 必要节是同级硬性约束。

#### Registry Awareness（关键机制）

设计跨系统实体（公式、物品）前必须读 `design/registry/entities.yaml`，与 registry 不一致时必须显式提议更新。这避免了"战斗 GDD 写攻击力 100、装备 GDD 写攻击力 120"的真实数据冲突。

> **移植洞察**：Registry Awareness 是 CCGS 防止"多 agent 各自为政导致数据冲突"的关键机制。CodeBuddy 移植时建议保留这个 yaml 文件 + 在 Rules 中规定"涉及 entities 数据时必须读 registry"。

#### 涉及的 Director Gates

无自己主持的 Gate，但产出会被 CD-SYSTEMS / CD-GDD-ALIGN / TD-FEASIBILITY 间接审查。

#### 上下游关系

**向上**：直接日常合作 = `game-designer`；冲突升级路径分明：
- 玩家体验/愿景冲突 → `creative-director`（不是 game-designer）
- 公式正确性/可行性 → `technical-director` 或 `lead-programmer`
- 跨域范围/排期 → `producer`

**协作**：analytics-engineer（数据驱动平衡）

#### 禁止做

- 做高层设计方向决策（→ game-designer）
- 写实现代码
- 设计关卡或遭遇（→ level-designer）
- 做叙事或美学决策

#### CodeBuddy 适配评级

**移植类型**：直接移植（Formula Output 格式 + Registry Awareness 规则 + 升级路径）+ 改造移植（memory + 调用方式）

**移植形态**：**B — 执行角色**  
（无 Gate 主持，主要由 `/quick-design`、`/design-system`、`/team-balance`、`/tune-system` 等 skill spawn，产出公式规格文档。）

**关键改造点**：
1. `disallowedTools: Bash` → CodeBuddy allowed-tools 反向白名单
2. `memory: project` → 已批准的核心公式（伤害/经济）放 CODEBUDDY.md
3. **Formula Output Format 4 字段**作为 skill 模板硬性写入（任何含数值产出的 skill 都强制此格式）
4. **Registry Awareness 机制**保留 `design/registry/entities.yaml`，并在 Rules（`alwaysApply: true`）中规定"涉及跨系统实体时必须先读 registry"
5. 4 步协议（Question-First）抽离为共享 snippet，本 agent 引用即可

**调用频率建议**：**中频**（每个含数值/公式的设计任务）

**适合保留档位**：
- 极简档 ⚪（小型项目可直接由 game-designer 兼任，不独立 spawn）
- 标准档 ✅（任何带数值平衡的项目都需要）
- 完整档 ✅

---

### 13. level-designer（关卡设计师）

#### 一句话定位

设计**空间和节奏**：关卡布局、遭遇配置、节奏曲线、环境叙事、秘密位置。负责"玩家在空间里如何前进"。

#### Frontmatter 元信息

```yaml
name: level-designer
tools: Read, Glob, Grep, Write, Edit
model: sonnet
maxTurns: 20
disallowedTools: Bash
memory: project
```

#### 核心职责（6 项）

| 职责 | 通俗解释 |
|---|---|
| **关卡布局设计** | 顶视图：路径/地标/视线/瓶颈/空间流 |
| **遭遇设计** | 战斗/非战斗遭遇：敌人组合 / 刷新时机 / 场地约束 / 难度目标 |
| **节奏图** | 强度曲线 / 休息点 / 升级模式 |
| **环境叙事** | 不靠文字、靠环境讲故事 |
| **秘密与可选内容** | 奖励探索但不惩罚直线玩家 |
| **流分析** | 用光照/几何/音频"引导"玩家方向 |

#### Level Document Standard（强制 9 字段）

每份关卡文档必须包含：Level Name and Theme / Estimated Play Time / Layout Diagram / Critical Path / Optional Paths / Encounter List / Pacing Chart / Narrative Beats / Music/Audio Cues

> 与 game-designer 的 GDD 8 必要节、systems-designer 的 Formula 4 字段一脉相承——CCGS 用"硬性产出格式"代替"提示词约束"，可移植性极好。

#### 涉及的 Director Gates

无独立 Gate，产出文档会受 CD-PILLARS / CD-GDD-ALIGN 间接审查。

#### 上下游关系

**汇报给**：`game-designer`  
**协作**：narrative-director / art-director / audio-director（关卡同时是空间、故事、视觉、声音的载体）

#### 禁止做

- 设计游戏级系统（→ game/systems-designer）
- 做故事决策（→ narrative-director）
- 在引擎里实现关卡（交给程序员）
- 设定全局难度参数（只设定每个遭遇的难度）

#### CodeBuddy 适配评级

**移植类型**：直接移植（9 字段标准 + 协议）+ 改造移植

**移植形态**：**B — 执行角色**  
（被 `/level-design`、`/encounter-design` 等 skill spawn）

**关键改造点**：
1. `memory: project` → CODEBUDDY.md 记录世界结构、已批准的关卡列表
2. **Level Document 9 字段**作为 skill 模板写死
3. 4 步协议共享 snippet
4. ASCII 布局图在文档中是常用产物，CodeBuddy skill 模板应支持

**调用频率建议**：**中频**（每个新关卡/区域设计时）

**适合保留档位**：
- 极简档 ⚪（关卡稀少的小品级游戏可不独立配置）
- 标准档 ✅
- 完整档 ✅

---

### 14. economy-designer（经济设计师）

#### 一句话定位

设计**资源经济与奖励系统**：资源流（faucet/sink）、掉落表、进度曲线、市场。专攻"长时间不通胀、不退化策略"的经济健康。

#### Frontmatter 元信息

```yaml
name: economy-designer
tools: Read, Glob, Grep, Write, Edit
model: sonnet
maxTurns: 20
disallowedTools: Bash
memory: project
```

#### 核心职责（5 项）

| 职责 | 通俗解释 |
|---|---|
| **资源流建模** | 列所有 faucet（产出口）和 sink（消耗口），保证长期不通胀也不耗尽 |
| **掉落表设计** | 显式掉率 / 稀有度分布 / pity 计时器 / 防霉机制 + 期望获得时间线 |
| **进度曲线** | XP 曲线 / 力量曲线 / 解锁节奏 |
| **奖励心理学** | variable ratio / fixed interval 等强化时间表，每个奖励结构注明心理学原理 |
| **经济健康指标** | 平均货币/小时、获得率、库存分布等可观测指标 |

#### Reward Output Format（条件性）

如果游戏含概率奖励/掉落/解锁，必须用**显式速率**而非模糊描述。3 必填字段：
1. **输出表**（Output / Frequency-Rate / Condition-Weight / Notes 4 列）
2. **期望获得**（多少次尝试平均得一次）
3. **下限/上限**（保底机制，如果有）

> 注意"条件性"：纯解谜或叙事游戏不需要这一节。这是 CCGS 中少有的"模板可省略"案例。

#### Registry Awareness（关键机制）

物品、货币、loot entry 是跨系统数据（同时出现在战斗 GDD、经济 GDD、任务 GDD 中），必须先读 `design/registry/entities.yaml`，冲突时显式提议变更。

#### 涉及的 Director Gates

无独立 Gate，产出会受 TD-MANIFEST（TD 审查跨系统实体一致性时）间接审查。

#### 上下游关系

**汇报给**：`game-designer`  
**协作**：systems-designer（经济用到的公式）、analytics-engineer（线上经济监控）

#### 禁止做

- 设计核心 gameplay 机制（→ game-designer）
- 写实现代码
- 未经 creative-director 批准做付费机制决策
- 不写理由就改 loot table

#### CodeBuddy 适配评级

**移植类型**：直接移植（Reward Output Format + Registry Awareness）+ 改造移植

**移植形态**：**B — 执行角色**  
（被 `/economy-design`、`/balance-economy`、`/team-balance`、`/loot-table` 等 skill spawn）

**关键改造点**：
1. `memory: project` → CODEBUDDY.md 记录已批准的核心货币、掉落分级、保底参数
2. **Reward Output Format 3 字段**作为 skill 条件模板（仅在含概率系统的游戏中激活）
3. **Registry Awareness 机制**与 systems-designer 共享同一份 entities.yaml
4. 4 步协议共享 snippet

**调用频率建议**：**中频**（含资源经济 / loot 系统的项目高频，否则零频）

**适合保留档位**：
- 极简档 ❌（无经济系统的项目完全不需要）
- 标准档 ⚪（视项目是否含掉落/资源流）
- 完整档 ✅

---

## 批 A 设计线横向规律

### 模式 1：4 步协议在 Tier 3 完全相同

systems / level / economy 三人的 Collaboration Protocol 部分**逐字相同**（包括 Question-First Workflow / Structured Decision UI / AskUserQuestion 用法）。这一段在 Tier 1（3 人）+ Tier 2（4 人 设计型）+ Tier 3 设计线（3 人）至少出现 10 次，是全工作室的**最大重复块**。

> **移植关键洞察**：把这 4 步协议抽离为 `.codebuddy/agents/_shared/design-collaboration-protocol.md`，所有设计型 agent `@import` 引用，能直接节省 ~700 行重复内容。这是移植到 CodeBuddy 时**最有价值的结构性优化之一**。

### 模式 2：硬性产出格式（Format-Driven Output）

| Agent | 硬性格式 | 字段数 | 是否条件性 |
|---|---|---|---|
| game-designer | GDD | 8 节 | 否 |
| systems-designer | Formula Output | 4 字段 | 否 |
| level-designer | Level Document | 9 字段 | 否 |
| economy-designer | Reward Output | 3 字段 | 是（仅含概率系统时）|

**模式总结**：CCGS 几乎所有设计 agent 都用"硬性输出格式"代替"软约束的提示词"。这种设计极易移植——直接把格式写进 skill 模板即可，对 agent 提示词内容的依赖度反而下降。

### 模式 3：Registry Awareness 是跨 agent 数据一致性的唯一防线

只有 systems-designer 和 economy-designer 显式声明 Registry Awareness（因为它们最容易产生跨系统数值）。其他 agent 没有此条款会导致数据漂移风险。

> **移植洞察**：CodeBuddy 移植时建议把 Registry Awareness **扩展为通用 Rule**——任何 agent 涉及"会出现在多个文档中的实体"时都要查 registry。可放进 `.codebuddy/rules/registry-discipline.md`，`alwaysApply: true`。

### 模式 4：升级路径分化精细

systems-designer 的升级路径是 Tier 3 中最规范的样板：

```
玩家体验冲突 → creative-director（不是 game-designer！）
可行性冲突 → technical-director / lead-programmer
范围/排期冲突 → producer
```

**game-designer 是日常合作伙伴，但不是争议仲裁者**——这一区分在移植时必须保留，否则会导致争议被错误地交给 game-designer 而非 creative-director 决策。

### 批 A 适配性小结

| Specialist | 形态 | 极简 | 标准 | 完整 | 极简档可否合并 |
|---|---|---|---|---|---|
| systems-designer | B | ⚪ | ✅ | ✅ | 可由 game-designer 兼任 |
| level-designer | B | ⚪ | ✅ | ✅ | 关卡稀少时可省 |
| economy-designer | B | ❌ | ⚪ | ✅ | 无经济系统则不需要 |

**批 A 极简档建议**：3 人全合并进 game-designer 提示词作为"系统/关卡/经济专家"片段，不独立 spawn。极简移植至此 Tier 3 设计线 = 0 个独立 agent。

---

## 批 B — 程序线（6 人）

> **重要观察**：6 个 programmer 的 Collaboration Protocol（Implementation Workflow 6 步 + Collaborative Mindset）**逐字相同**，是 Tier 2 lead-programmer/qa-lead/release-manager/localization-lead 之外又一处 4 步实现型协议的扩展使用。**6 篇文件累计约 600 行重复内容**。
>
> 本批次采用"差异聚焦法"：协议、Engine Version Safety、AskUserQuestion 等共享部分只在第一个 agent（gameplay-programmer）展开，后续 5 人**仅展开差异**（职责、专属原则、上下游、禁止做、适配）。

### 共享内容速查（适用本批 6 人 + Tier 2 实现型 4 人共 10 个 agent）

| 共享区块 | 内容要点 |
|---|---|
| **Implementation Workflow 6 步** | Read spec → Ask arch questions → Propose architecture → Implement with transparency → Get approval → Offer next steps |
| **Collaborative Mindset** | Clarify before assuming / Propose don't just implement / Explain trade-offs / Flag deviations / Rules are your friend / Tests prove it works |
| **Engine Version Safety**（5/6 含） | 1. 检查 `docs/engine-reference/[engine]/VERSION.md` 的 pinned 版本；2. 若 API 在 LLM cutoff 之后引入则显式 flag；3. engine-reference 优先于训练数据 |
| **Tools 白名单** | Read, Glob, Grep, Write, Edit, **Bash**（程序员都允许 Bash） |

> **移植洞察**：把这三大共享区块抽成 `.codebuddy/agents/_shared/implementation-protocol.md` + `.codebuddy/rules/engine-version-safety.md`（`alwaysApply: true`），10 个 agent 文件总长可减少约 60%，维护成本显著下降。

---

### 15. gameplay-programmer（玩法程序员）

#### 一句话定位

把 GDD/Formula 等设计文档**翻译成实际可玩的代码**：玩法机制、玩家系统、战斗、可交互特性。"data-driven、testable、不硬编码"是核心信条。

#### Frontmatter 元信息

```yaml
name: gameplay-programmer
tools: Read, Glob, Grep, Write, Edit, Bash
model: sonnet
maxTurns: 20
# 无 memory / disallowedTools / skills 声明
```

> **与设计型 agent 的差异**：程序线全员**无 `memory: project` 声明**（只在 lead-programmer 有），这是个有意设计——具体程序员不需要"记住整个项目"，只需要从 spec 和 ADR 出发实现。

#### 核心职责（6 项）

| 职责 | 通俗解释 |
|---|---|
| **特性实现** | 严格按 GDD 实现，偏离需要 designer 批准 |
| **数据驱动** | 所有 gameplay 数值必须从外部配置读取，禁止硬编码 |
| **状态管理** | 干净的状态机、显式的状态转换表、无非法状态可达 |
| **输入处理** | 响应式、可重映射、缓冲、上下文动作 |
| **系统集成** | 按 lead-programmer 的接口连接系统，事件 + DI |
| **可测试代码** | 所有 gameplay 逻辑写单元测试，逻辑/表现分离 |

#### 编码标准（gameplay 专属）

- 每个 gameplay 系统必须实现清晰接口
- 所有数值从配置文件 + 合理默认
- 状态机必须有显式转换表
- **禁止直接引用 UI 代码**（用事件/信号）
- Frame-rate independent（处处用 delta time）
- 在代码注释中文档化每个特性实现的对应 GDD

#### ADR Compliance（关键机制）

实现任何系统前检查 `docs/architecture/` 是否有对应 ADR：
- 有 → 严格遵循 Implementation Guidelines
- ADR 与"看起来更好的做法"冲突 → 显式 flag 而非默默偏离
- 无 → "建议先跑 `/architecture-decision`"

> 这是 CCGS 防止"程序员凭直觉绕过架构决策"的关键防线。

#### 涉及的 Director Gates

无独立 Gate；产出会被 LP-CODE-REVIEW 审查。

#### 上下游关系（Delegation Map）

**汇报给**：`lead-programmer`  
**实现 spec 来自**：`game-designer` / `systems-designer`  
**升级目标**：
- 架构冲突/接口分歧 → `lead-programmer`
- spec 歧义/设计文档缺口 → `game-designer`
- 性能约束与设计目标冲突 → `technical-director`

**协作（同级）**：ai-programmer（敌人/NPC 整合）/ network-programmer（多人共享状态）/ ui-programmer（玩法-UI 事件契约）/ engine-programmer（引擎 API + 性能关键路径）

**冲突解决原则**：spec 与技术约束冲突时，**联合**升级到 `lead-programmer` 和 `game-designer`；**禁止单方面修改设计或架构**。

#### 禁止做

- 改变游戏设计（向 game-designer 提出冲突）
- 未经 lead-programmer 批准修改引擎级系统
- 硬编码本应可配置的值
- 写网络代码（→ network-programmer）
- 跳过 gameplay 逻辑的单元测试

#### CodeBuddy 适配评级

**移植类型**：直接移植（编码标准 + ADR Compliance + 升级路径）+ 改造移植（共享协议抽离）

**移植形态**：**B — 执行角色**  
（被 `/dev-story`、`/implement-feature`、`/team-mechanic` 等 skill spawn）

**关键改造点**：
1. **6 步实现协议抽离**为 `_shared/implementation-protocol.md`，本 agent 仅引用
2. **ADR Compliance 规则**放进 Rules（`alwaysApply: true`）：实现前必查 `docs/architecture/`
3. 数据驱动原则放进 Rules（`alwaysApply: true`）：禁止硬编码数值
4. Engine Version Safety 抽成单独 Rule

**调用频率建议**：**高频**（每个 dev-story 都会 spawn）

**适合保留档位**：
- 极简档 ✅（编码项目核心角色）
- 标准档 ✅
- 完整档 ✅

---

### 16. engine-programmer（引擎程序员）

#### 差异聚焦

**职责差异**：核心引擎系统（场景管理 / 资源加载 / 对象生命周期 / 组件系统） / 性能关键代码（渲染 / 物理 / 空间查询 / 碰撞） / 内存管理（对象池 / 流式资源 / GC 管理） / 平台抽象 / 调试基础设施 / **API 稳定性**（公开接口变更需要 deprecation 期 + 迁移指南）

**专属编码标准**：
- **热路径零分配**（pre-allocate / pool / reuse）
- 引擎 API 必须线程安全或显式标注非线程安全
- **每次优化前后都要 profile + 把数字记录到文档**
- **引擎代码不依赖 gameplay 代码**（严格依赖方向）
- 每个公开 API 必须在 doc comment 含使用示例

**上下游差异**：
- 汇报给 `lead-programmer` + `technical-director`（双汇报，强调架构总监对引擎的直接管辖）
- 协作 `technical-artist`（渲染）+ `performance-analyst`（优化目标）

**禁止做差异**：未经 technical-director 批准做架构决策；未经 technical-artist 咨询改渲染方法

#### CodeBuddy 适配评级

- **形态 B**，调用**低频**（仅引擎/性能关键修改时，多数项目无需要）
- 关键改造：零分配/线程安全等专属标准放 Rules（`alwaysApply: true`，但作用域为 `src/core/**`——CodeBuddy 不支持 glob，需用"手动规则 + skill 内显式引用"代偿）
- **极简档 ❌**（小项目不会改引擎级代码）/ **标准档 ⚪**（视项目复杂度）/ **完整档 ✅**

---

### 17. ai-programmer（AI 程序员）

#### 差异聚焦

**职责差异**：行为树/状态机框架 / 寻路（A*/navmesh/flow fields） / 感知系统（视觉锥/听觉/威胁记忆） / 决策系统（utility-based 或 GOAP） / 群体协作 / AI 调试可视化工具

**专属设计原则（"AI is Fun" 哲学）**：
- AI 必须**好玩而非最优**
- 可学习的可预测性 + 多样的趣味性
- AI 必须 telegraph 意图给玩家反应时间
- **性能预算：AI 更新每帧 2ms 内完成**
- 所有 AI 参数从数据文件可调

**上下游差异**：
- 汇报给 `lead-programmer`
- 实现 spec 来自 `game-designer` + `level-designer`（这点很特别——AI 的"在哪里出现"是关卡设计师定的）

**禁止做**：设计敌人类型/行为（→ game-designer） / 改核心引擎（→ engine-programmer） / 做 navmesh 工具（→ tools-programmer） / 决定难度缩放（→ systems-designer）

#### CodeBuddy 适配评级

- **形态 B**，调用**中频**（含 AI 系统的项目高频，纯解谜/叙事项目零频）
- 关键改造：AI 设计原则（"fun not optimal" / 2ms 预算）放 Rules
- **极简档 ❌**（无 AI 项目跳过）/ **标准档 ⚪**（含敌人/NPC 时需要）/ **完整档 ✅**

---

### 18. network-programmer（网络程序员）

#### 差异聚焦

**职责差异**：网络架构（C-S/P2P/混合） / 状态同步（reliable/unreliable/插值/预测） / 滞后补偿（**目标 150ms 延迟下仍响应**） / 带宽管理（relevancy/delta 压缩/优先级） / 安全（**服务端权威**） / 匹配/大厅

**专属网络原则**：
- **服务端权威**所有 gameplay 状态
- 客户端预测 + 服务端调和
- **所有网络消息必须版本化**以保证前向兼容
- 优雅处理断线/重连/迁移
- 异常日志（限速）

**上下游差异**：
- 汇报给 `lead-programmer`
- 协作 `devops-engineer`（基础设施）+ `gameplay-programmer`（netcode 集成）

**禁止做**：单独做安全架构决策（必须咨询 `technical-director`） / 改非网络相关 game logic / 设置服务器基础设施（→ devops-engineer）

#### CodeBuddy 适配评级

- **形态 B**，调用**低频**（仅多人项目；单人项目零频）
- 关键改造：服务端权威原则放 Rules（`alwaysApply: true`，作用域为 `src/networking/**`）
- **极简档 ❌**（单人项目不需要）/ **标准档 ❌**（除非项目本身是多人） / **完整档 ⚪**（多人项目才保留）

---

### 19. tools-programmer（工具程序员）

#### 差异聚焦

**用户群与众不同**：服务对象**不是玩家，而是其他开发者和内容创作者**——这是 6 个 programmer 中唯一以"提升团队产能"为目标的角色。

**职责差异**：编辑器扩展 / 内容管线工具 / 在游戏调试工具（控制台/作弊菜单/状态检查器） / 自动化脚本 / **必须有使用文档**（"无文档的工具没人用"）

**专属工具设计原则**：
- 输入校验 + 清晰可执行的错误信息
- 尽量可撤销
- 失败时不损坏数据（**原子操作**）
- 不打断用户工作流的速度
- **工具的 UX 至关重要**（每天用几百次）

**上下游差异**：
- 汇报给 `lead-programmer`
- 协作 `technical-artist`（美术管线工具）+ `devops-engineer`（构建集成）

**禁止做**：改运行时代码（→ gameplay/engine-programmer） / 不咨询内容创作者就设计内容格式 / 与引擎内置功能重复 / 不在代表性数据上测试就部署

#### CodeBuddy 适配评级

- **形态 B**，调用**低频**（仅在需要专门内容工具时）
- 关键改造：工具设计原则放 CODEBUDDY.md 或 Rules
- **极简档 ❌**（小项目无需要） / **标准档 ⚪** / **完整档 ✅**

---

### 20. ui-programmer（UI 程序员）

#### 差异聚焦

**职责差异**：UI 框架（布局/样式/动画/输入/焦点） / 屏幕实现 / HUD（分层/动画/状态驱动） / **数据绑定**（reactive：状态变 → UI 自动变） / **无障碍**（缩放文字 / 色盲模式 / 屏幕阅读器 / 键位重映射） / **本地化支持**（RTL / 可变文本长度）

**专属 UI 原则**：
- **UI 必须不阻塞游戏线程**
- **所有 UI 文本必须过本地化系统**（禁止硬编码）
- 同时支持键鼠 + 手柄
- **动画必须可跳过 + 尊重用户的减少动效偏好**
- UI 音效通过音频事件系统触发，不直接放声

**上下游差异**：
- 汇报给 `lead-programmer`
- 实现 spec 来自 `art-director`（视觉规格）+ `ux-designer`（流程规格）

**禁止做**：设计 UI 布局或视觉风格（→ art-director/ux-designer） / 在 UI 代码里写 gameplay 逻辑（**UI 显示状态，不拥有状态**） / 直接改 game state（用命令/事件穿过游戏层）

> 最后一条"UI displays state, does not own it"是 MVC 架构的核心戒律，移植时这条放进 Rules 价值极高。

#### CodeBuddy 适配评级

- **形态 B**，调用**中频**（含 UI 的项目高频，纯命令行游戏零频）
- 关键改造：UI 原则（不阻塞主线程 / 禁硬编码文本 / 状态分离）放 Rules（`alwaysApply: true`，作用域为 `src/ui/**`，CodeBuddy 用手动规则代偿）
- **极简档 ⚪**（极简 UI 项目可不独立）/ **标准档 ✅** / **完整档 ✅**

---

## 批 B 程序线横向规律

### 模式 1：6 步实现协议是 10 人共用

不仅 6 个 programmer 用，Tier 2 的 lead-programmer / qa-lead / release-manager / localization-lead 也用同样 6 步协议。10 个 agent 共享 ~600 行重复内容——**移植到 CodeBuddy 时建议 100% 抽离为单独 snippet**。

### 模式 2：Engine Version Safety 是 5/6 程序员共有

- 含此条款：gameplay / engine / tools / ui-programmer + lead-programmer = 5 人
- 不含：ai / network-programmer = 2 人

观察：含 Engine Version Safety 的都是直接调用引擎 API 的角色；ai/network 偏向算法与协议，引擎 API 调用相对少。**这一区分有合理性**。

### 模式 3：仅 lead-programmer 有 `memory: project`，其余 6 人均无

这是工作室的"知识分布管理"——单个程序员不需要记忆全项目，只需要：
- 接收 spec（来自 designer）
- 遵循 ADR（来自 technical-director / lead-programmer）
- 实现 + 测试

**移植洞察**：这是个反"AI 无脑积累记忆"的好示范——CodeBuddy 移植时也应避免给每个 specialist 都开 Memory。

### 模式 4：ADR Compliance 在程序线最严格

- gameplay-programmer 显式有 ADR Compliance 段落
- engine-programmer 隐含强调（"未经 technical-director 批准做架构决策"）
- 其他 4 人通过 Engine Version Safety 间接强制

**移植洞察**：把"实现前查 ADR"作为全局 Rule（`alwaysApply: true`），不依赖每个 agent 各自声明。

### 模式 5：禁止跨界写代码

| 程序员 | 必须委派的领域 |
|---|---|
| gameplay-programmer | 网络代码（→ network） |
| engine-programmer | gameplay 代码（→ gameplay）/ 构建（→ devops） |
| ai-programmer | navmesh 工具（→ tools） |
| network-programmer | 服务器基础设施（→ devops） |
| tools-programmer | 运行时代码（→ gameplay/engine） |
| ui-programmer | UI 设计（→ art-director/ux）/ gameplay 逻辑 |

**模式总结**：CCGS 用强硬的"禁做清单"维持子专员之间的边界。移植时如果合并 specialist，必须在合并后的 agent 里**保留所有原边界禁令**——否则会出现"一个 programmer 把网络/UI/AI 全写了"的失控。

### 批 B 适配性小结

| Specialist | 形态 | 极简 | 标准 | 完整 | 极简档可否合并 |
|---|---|---|---|---|---|
| gameplay-programmer | B | ✅ | ✅ | ✅ | 必保留（核心实现角色） |
| engine-programmer | B | ❌ | ⚪ | ✅ | 多数项目用引擎自带 |
| ai-programmer | B | ❌ | ⚪ | ✅ | 无 AI 项目跳过 |
| network-programmer | B | ❌ | ❌ | ⚪ | 单人项目跳过 |
| tools-programmer | B | ❌ | ⚪ | ✅ | 多数项目用引擎自带工具 |
| ui-programmer | B | ⚪ | ✅ | ✅ | 含 UI 必保留 |

**批 B 极简档建议**：保留 gameplay-programmer 1 人；如果项目有复杂 UI 可加 ui-programmer。极简移植至此 Tier 3 程序线 = 1-2 个独立 agent。

**特别提醒**：批 B 中有 4 人（engine / network / ai / tools）在多数项目中**调用频率极低**。即便保留独立文件，也应在 CODEBUDDY.md 中注明"按需手动 spawn"，避免 agentic 模式下被错误唤起。

---

## 批 C — 美术/音频/叙事线（4 人）

> 本批 4 人在协议选择上呈现"分裂"：
> - technical-artist 用**实现型 6 步**（属程序线协议家族）
> - sound-designer 用**实现型 6 步**（但内容偏设计——疑似模板复制错误，移植时建议改回 4 步）
> - writer 用**混合协议**（前 2 步实现 + 第 3-4 步设计的增量写作）
> - world-builder 用完整**设计型 4 步**
>
> 这是 CCGS 中协议归属最不一致的一批，正好佐证了"协议应抽离为共享 snippet 后由 agent 显式声明"的移植建议。

---

### 21. technical-artist（技术美术）

#### 一句话定位

**美术与工程之间的桥梁**：写 shader、做 VFX、优化渲染、维护美术管线。"让游戏看起来如美术指导设想，同时不超性能预算"是核心使命。

#### Frontmatter 元信息

```yaml
name: technical-artist
tools: Read, Glob, Grep, Write, Edit, Bash
model: sonnet
maxTurns: 20
# 无 memory 声明（与 6 个 programmer 一致）
```

#### 核心职责（6 项）

| 职责 | 通俗解释 |
|---|---|
| **Shader 开发** | 材质 / 光照 / 后处理 / 特效 shader；每个参数都要文档化视觉效果 |
| **VFX 系统** | 粒子 + shader + 动画；**每个 VFX 必须有性能预算** |
| **渲染优化** | LOD / 遮挡剔除 / batching / atlas 管理 |
| **美术管线** | 资产处理：导入设置 / 格式转换 / atlas / 网格优化 |
| **画质/性能平衡** | 文档化分级（low/medium/high/ultra） |
| **美术标准强制** | 校验顶点数 / 贴图大小 / UV 密度 / 命名 |

#### 性能预算（6 类硬性指标）

```
- Total draw calls per frame
- Vertex count per scene
- Texture memory budget
- Particle count limits
- Shader instruction limits
- Overdraw limits
```

> 这套预算是 technical-artist 的"硬通货"。移植到 CodeBuddy 时建议**作为 CODEBUDDY.md 的一节**，以便所有美术资产生成时都能参考。

#### 涉及的 Director Gates

无独立 Gate，但产出会被 AD-VISUAL（art-director 的 Gate）和 TD-FEASIBILITY（technical-director）间接审查。

#### 上下游关系

**双汇报**：`art-director`（视觉方向） + `lead-programmer`（代码标准）  
**协作**：`engine-programmer`（渲染系统）+ `performance-analyst`（优化目标）

#### 禁止做

- 做美学决策（→ art-director）
- 改 gameplay 代码（→ gameplay-programmer）
- 改引擎架构（→ technical-director）
- 制作最终美术资产（只定规格和管线）

#### CodeBuddy 适配评级

**移植类型**：直接移植（性能预算 6 类 + 编码标准）+ 改造移植（共享协议抽离）

**移植形态**：**B — 执行角色**

**关键改造点**：
1. 6 步实现协议抽离为 `_shared/implementation-protocol.md`
2. **6 类性能预算**作为 CODEBUDDY.md 一节，全局生效
3. Engine Version Safety 抽成 Rule
4. 双汇报结构（art-director + lead-programmer）需要在 CODEBUDDY.md 显式说明，否则 CodeBuddy 串行模式下容易丢

**调用频率建议**：**中频**（含 shader / VFX / 渲染优化的项目高频，纯 2D 像素游戏低频）

**适合保留档位**：极简 ❌ / 标准 ⚪ / 完整 ✅

---

### 22. sound-designer（声音设计师）⚠️ 特殊形态

#### 一句话定位

按 audio-director 的声音调色板**为每个声音写规格表**：SFX 描述 / 音频事件列表 / 混音文档 / 变体计划 / 环境声层次。**不是创作者，是规格作者**。

#### Frontmatter 元信息（罕见组合）

```yaml
name: sound-designer
tools: Read, Glob, Grep, Write, Edit       # 无 Bash
model: haiku                                 # ⚠️ 唯一使用 haiku 的设计/美术线 agent
maxTurns: 10                                 # 与轻量级匹配
disallowedTools: Bash
# 无 memory 声明
```

> **重要**：这是 49 个 agent 中**少数使用 haiku 的角色之一**，说明 CCGS 把"sound-designer 的工作"判断为**机械、模式化、低创意**——只是按音频总监的调色板填规格表格。这一判断决定了它的移植形态。

#### 核心职责（5 项）

| 职责 | 通俗解释 |
|---|---|
| **SFX 规格表** | 每个音效：描述/参考声/频率特性/时长/音量范围/空间属性/变体数 |
| **音频事件列表** | 每个系统的所有事件：触发 / 优先级 / 并发上限 / 冷却 |
| **混音文档** | 相对音量 / bus 分配 / ducking 关系 / 频率掩蔽 |
| **变体计划** | 避免重复：变体数 / 音高随机范围 / round-robin |
| **环境音设计** | 每个环境的 base / detail / one-shot / 过渡 |

#### 协议特殊性

CCGS 中 sound-designer 的协议段落是"实现型 6 步"——但其内容（"读 design doc"、"提架构问题"）与声音规格作者的实际工作高度不匹配。**这很可能是模板复制时未替换的遗留**。移植时建议改回设计型 4 步协议。

#### 涉及的 Director Gates

无 Gate。

#### 上下游关系

**汇报给**：`audio-director`  
**无水平协作声明**（这与轻量级定位一致）

#### 禁止做

- 做声音调色板决策（→ audio-director）
- 写音频引擎代码
- 创建实际音频文件
- 改音频中间件配置

#### CodeBuddy 适配评级

**移植类型**：**改造移植**（最适合形态 C）

**移植形态**：**C — 参考角色**  
（haiku 轻量 + 规范型 + 协议本身错误 + 主要工作是填模板表格 → 完美符合形态 C 定义。**建议不保留独立 md**，将 SFX 规格表 5 字段、音频事件列表格式、变体计划模板等拆出，放进：
- `.codebuddy/rules/audio-spec-format.md`（`alwaysApply: true`，约束所有音频规格文档）
- 在 audio-director 的提示词中加一段"按以下模板填规格表"的引用）

**关键改造点**：
1. **不保留独立 agent 文件**
2. SFX 规格表模板放 Rules
3. 音频事件命名约定与 audio-director 共享同一份命名规范
4. 协议错误问题在拆分时自然消失（拆掉提示词，只留模板）

**调用频率建议**：N/A（不再作为独立 agent 存在）

**适合保留档位**：
- 极简档 ❌（不需要独立 agent）
- 标准档 ❌（拆进 Rules 就够了）
- 完整档 ⚪（如果用户特别想保留独立 SFX 规格作者，可保留，但需修正协议）

> **这是批 C 唯一的形态 C 候选**，也是本册迄今为止首个明确建议"不保留独立 md"的 agent。这种决策的产生完全基于 frontmatter（haiku/无 memory/无 skills）+ 内容轻量化的客观证据，而非主观裁剪。

---

### 23. writer（作家）

#### 一句话定位

**写所有玩家可见的文字**：对话 / 传说 / 物品描述 / 战斗 bark / UI 文案。负责"把叙事方向变成实际字句"。**不做叙事架构决策**（→ narrative-director），只做"按语音轮廓写得自然"。

#### Frontmatter 元信息

```yaml
name: writer
tools: Read, Glob, Grep, Write, Edit
model: sonnet
maxTurns: 20
disallowedTools: Bash
memory: project           # 与 narrative 线一致
```

#### 协议特殊性（混合协议）

writer 的协议是 CCGS 中**唯一的混合协议**：
- 前 2 步：实现型（Read design doc / Ask architecture questions）
- 第 3-4 步：设计型（Draft incrementally / Get approval before writing files）
- 缺第 5 步、第 6 步是"Offer next steps"（编号有误，文件中实际只有 1-2-3-4-6，缺 5）

> **协议问题**：这种混合既不像设计型（缺 Options 步骤）也不像实现型（缺 propose architecture）。这又是模板复制错误。移植时建议改用纯设计型 4 步。

#### 核心职责（5 项）

| 职责 | 通俗解释 |
|---|---|
| **对话写作** | 按 narrative-director 的语音轮廓；自然 / 显角色 / 传达 gameplay 信息 |
| **传说条目** | 日志 / 怪物图鉴 / 历史 / 环境文字；每条都要给读者世界洞察 |
| **物品描述** | 名字 + 描述：传达功能、稀有度、传说；机械信息必须明确 |
| **Barks 与 flavor** | 战斗 bark / 加载提示 / 成就描述 / UI 微文案 |
| **本地化友好文本** | 不用难翻译的成语 / 用命名占位符 / 控制长度 |

#### 写作硬性标准

- 每条对话有 speaker tag + context note
- 对话文件用一致格式 + condition/state 注解
- **变量占位用命名形式**：`{player_name}`、`{item_count}`
- **每行不超 120 字符**（保证对话框可读）
- 每行可被配音演员朗读：自然节奏 + 明确情感方向

> 这套硬性标准是 writer 与本地化系统的契约。移植到 CodeBuddy 时**建议放进 Rules**，所有文本写作自动遵循。

#### 涉及的 Director Gates

无独立 Gate；产出会被 ND-CONSISTENCY（narrative-director）审查。

#### 上下游关系

**汇报给**：`narrative-director`  
**协作**：`game-designer`（让文本里的机械信息无歧义）

#### 禁止做

- 做故事或角色弧决策（→ narrative-director）
- 写代码或对话系统实现
- 设计任务/任务（写已设计任务的文本）
- **编造与已建立 world-building 矛盾的新传说**

#### CodeBuddy 适配评级

**移植类型**：直接移植（写作硬性标准）+ 改造移植（协议修正）

**移植形态**：**B — 执行角色**

**关键改造点**：
1. **协议修正**为纯设计型 4 步（修复混合协议的不一致）
2. **5 条写作硬性标准**放进 Rules（`alwaysApply: true`）：speaker tag / 命名占位符 / 120 字符上限 / 配音可读性
3. `memory: project` → CODEBUDDY.md 记录已批准的角色语音轮廓
4. 4 步协议共享 snippet

**调用频率建议**：**高频**（叙事项目每个对话/物品/任务文本都要写）

**适合保留档位**：
- 极简档 ❌（无叙事项目跳过）
- 标准档 ⚪（视项目是否含文本）
- 完整档 ✅

---

### 24. world-builder（世界构建师）

#### 一句话定位

**深层传说与世界框架**：派系 / 文化 / 历史 / 地理 / 生态 / 世界规则。负责"世界为什么是这个样子"，不写玩家可见文本（→ writer）。

#### Frontmatter 元信息

```yaml
name: world-builder
tools: Read, Glob, Grep, Write, Edit
model: sonnet
maxTurns: 20
disallowedTools: Bash
memory: project
```

> 协议恢复正常：完整使用**设计型 4 步**（与 systems/level/economy-designer / world-builder 共 4 人共享）。

#### 核心职责（6 项）

| 职责 | 通俗解释 |
|---|---|
| **传说一致性** | 维护 lore 数据库 + 交叉引用所有新传说；**禁止矛盾** |
| **派系设计** | 动机 / 权力结构 / 关系 / 领地 / 玩家可见个性 |
| **历史时间线** | 按时间顺序的事件库；标注玩家已知 / 可发现 / 隐藏 |
| **地理与生态** | 区域 / 气候 / 动植物 / 资源 / 贸易路线；**内部逻辑自洽** |
| **文化细节** | 习俗 / 信仰 / 艺术 / 语言碎片 / 日常生活 |
| **谜团分层** | 故意种植矛盾、不可靠叙述者；**真相单独文档化** |

#### Lore Document Standard（强制 5 字段）

每条 lore 条目必须包含：
1. **Canon Level**：Established / Provisional / Under Review
2. **Visible To Player**：Yes / Discoverable / Hidden
3. **Cross-References**：相关传说条目链接
4. **Contradictions Check**：显式确认一致性
5. **Source**：哪份叙事文档建立的此条

> 与 game-designer 的 GDD 8 节、systems-designer 的 Formula 4 字段、level-designer 的 Level 9 字段、economy-designer 的 Reward 3 字段同属"硬性产出格式"家族，**移植时直接复用**。

#### 涉及的 Director Gates

无独立 Gate；产出会被 ND-CONSISTENCY 审查。

#### 上下游关系

**汇报给**：`narrative-director`  
**协作**：`level-designer`（环境传说）+ `art-director`（视觉文化设计）

#### 禁止做

- 写玩家可见文本（→ writer）
- 做故事弧决策（→ narrative-director）
- 围绕 lore 设计 gameplay
- **未经 narrative-director 批准更改已建立 canon**

#### CodeBuddy 适配评级

**移植类型**：直接移植（Lore Document 5 字段 + 设计型协议）+ 改造移植

**移植形态**：**B — 执行角色**

**关键改造点**：
1. 4 步协议共享 snippet
2. **Lore Document 5 字段**作为 skill 模板写死
3. `memory: project` → CODEBUDDY.md 记录核心世界规则、派系名单、历史关键节点
4. lore 数据库本身是项目工作产出（不是 agent 配置），应放在 `design/lore/` 而非 CODEBUDDY.md

**调用频率建议**：**中频**（叙事项目早期高频，建立 lore 库；后期低频补充新条目）

**适合保留档位**：
- 极简档 ❌（无叙事跳过）
- 标准档 ⚪（视项目是否含深度世界观）
- 完整档 ✅（叙事/RPG/开放世界必保）

---

## 批 C 美术/音频/叙事线横向规律

### 模式 1：协议归属混乱（CCGS 的设计瑕疵）

| Agent | 协议类型 | 是否合理 |
|---|---|---|
| technical-artist | 实现型 6 步 | ✅ 合理（写 shader 就是写代码） |
| sound-designer | 实现型 6 步 | ❌ 不合理（写规格表，不是写代码） |
| writer | 混合（前实现+后设计） | ❌ 不合理（应纯设计型） |
| world-builder | 设计型 4 步 | ✅ 合理 |

**移植洞察**：CCGS 的协议归属在 4 个 agent 中有 2 个错误。这是**模板复制粘贴的副作用**——直接证明"协议应该是显式声明的共享 snippet，而非每个 agent 各自写一遍"。移植到 CodeBuddy 时，把协议标准化为 2-3 个共享文件 + agent 显式声明 `protocol: design-4step` 或 `protocol: implementation-6step`，可以根除此类错误。

### 模式 2：模型分层在批 C 第一次出现（haiku）

sound-designer 是 49 个 agent 中**第一个使用 haiku** 的角色。这一选择基于工作的性质：
- 工作内容高度模板化（填规格表）
- 不需要复杂推理
- 失败成本低（拼错字、漏填字段，下游会发现）

**移植洞察**：CodeBuddy 移植时如果接受"不保留独立 sound-designer agent，规格表模板放 Rules"的方案（**强烈推荐**），就**完全不需要 haiku 模型**——模板填空由 audio-director（sonnet）顺手做即可。

### 模式 3：硬性产出格式仍是主线

| Agent | 硬性格式 | 字段数 |
|---|---|---|
| technical-artist | 性能预算 | 6 类 |
| sound-designer | SFX 规格 | 7 字段 |
| writer | 写作硬性标准 | 5 条 |
| world-builder | Lore Document | 5 字段 |

加上前 14 个 agent 已识别的格式（GDD 8 节、Formula 4 字段、Level 9 字段、Reward 3 字段、Sprint 模板等），CCGS 在 24 个 agent 中已识别**至少 9 套硬性产出格式**。这种"格式驱动"特性使得 CCGS 的核心价值很大一部分在于**模板**，而非提示词智能。**移植时把模板放进 skill 而非 agent，是降低 CodeBuddy 调用成本的关键路径**。

### 模式 4：双汇报结构开始出现

- engine-programmer：lead-programmer + technical-director（在批 B 已出现）
- technical-artist：art-director + lead-programmer

双汇报反映了**跨界角色**的特性——既要美学方向又要代码质量。**移植时这种结构容易丢失**（CodeBuddy 没有显式的"汇报关系"机制），需在 CODEBUDDY.md 或 agent 提示词中显式写明，否则会被默认归到单一上级。

### 批 C 适配性小结

| Specialist | 形态 | 极简 | 标准 | 完整 |
|---|---|---|---|---|
| technical-artist | B | ❌ | ⚪ | ✅ |
| sound-designer | **C**（不保留独立 agent） | ❌ | ❌ | ⚪ |
| writer | B | ❌ | ⚪ | ✅ |
| world-builder | B | ❌ | ⚪ | ✅ |

**批 C 极简档建议**：4 人全部不在极简档保留。极简移植到此 Tier 3 美术/音频/叙事线 = 0 个独立 agent。

**形态 C 首次出现**：sound-designer 是本册第 1 个明确归类形态 C 的 agent，其拆分方案（SFX 规格表 → Rules + 模板，audio-director 顺手填）可作为后续轻量 haiku agent 的标准移植模式。

---

## 批 D — UX/原型/性能线（3 人）

> 这一批 3 人各自代表一种**特殊机制**：
> - ux-designer：硬性 Accessibility Checklist（与 art-director/game-designer 双汇报）
> - prototyper：CCGS 中**唯一使用 `isolation: worktree`** 的 agent，整套"快速验证 + 必须丢弃"哲学
> - performance-analyst：纯数据驱动，自带 Performance Report 模板

---

### 25. ux-designer（用户体验设计师）

#### 一句话定位

确保**每次玩家交互都直观、可访问、令人满意**。设计"让游戏用起来感觉好"的看不见的系统：用户流、信息架构、引导、可访问性、反馈系统。

#### Frontmatter 元信息

```yaml
name: ux-designer
tools: Read, Glob, Grep, Write, Edit, WebSearch
model: sonnet
maxTurns: 20
disallowedTools: Bash
memory: project
```

> 协议：完整使用**设计型 4 步**（与 systems / level / economy / world-builder / 4 个 director 同族）。

#### 核心职责（6 项）

| 职责 | 通俗解释 |
|---|---|
| **用户流映射** | 从启动到玩、从菜单到玩、从失败到重试每一条流；找出摩擦点 |
| **交互设计** | 键鼠/手柄/触屏全输入；按键分配 / 上下文动作 / 输入缓冲 |
| **信息架构** | 菜单层级 / tooltip / 渐进披露 |
| **引导设计** | 新玩家体验：教程 / 上下文提示 / 难度曲线 / 信息节奏 |
| **可访问性标准** | 重映射 / UI 缩放 / 色盲模式 / 字幕 / 难度选项 |
| **反馈系统** | 视觉/音频/震动；玩家必须知道发生了什么、为什么 |

#### Accessibility Checklist（7 项硬性标准）

每个特性必须通过：
- [ ] 键盘可单独使用
- [ ] 手柄可单独使用
- [ ] 文本在最小字号下可读
- [ ] 不依赖单纯颜色（色盲友好）
- [ ] 无未警告的闪烁内容
- [ ] 所有对话都有字幕
- [ ] UI 在所有支持分辨率下正确缩放

> 这是 ux-designer 与 ui-programmer / accessibility-specialist 联动的**硬通货**。移植到 CodeBuddy 时建议**作为 Rule（`alwaysApply: true`）全局生效**——任何 UI 设计都自动检查此清单。

#### 涉及的 Director Gates

无独立 Gate，但产出会被 AD-VISUAL（art-director）和 CD-GDD-ALIGN（creative-director）间接审查。

#### 上下游关系

**双汇报**：`art-director`（视觉 UX） + `game-designer`（gameplay UX）  
**协作**：`ui-programmer`（实现可行性）+ `analytics-engineer`（UX 指标）

#### 禁止做

- 做视觉风格决策（→ art-director）
- 写 UI 代码（→ ui-programmer）
- 设计 gameplay 机制（→ game-designer）
- **为美学覆盖可访问性要求**（accessibility 是硬底线）

#### CodeBuddy 适配评级

**移植类型**：直接移植（Accessibility Checklist + UX 理论引用）+ 改造移植

**移植形态**：**B — 执行角色**

**关键改造点**：
1. 4 步协议共享 snippet
2. **Accessibility Checklist 7 项**作为 Rule（`alwaysApply: true`）全局生效
3. `memory: project` → CODEBUDDY.md 记录已批准的核心 UX 决策（输入方案、菜单层级）
4. 双汇报结构需在 CODEBUDDY.md 显式说明

**调用频率建议**：**中频**（含 UI/教程/可访问性的项目高频）

**适合保留档位**：
- 极简档 ⚪（极简项目可由 game-designer 兼任）
- 标准档 ✅
- 完整档 ✅

---

### 26. prototyper（原型师）⚠️ 特殊机制

#### 一句话定位

**快速搭原型回答设计问题**：能"感觉到"才能评估的机制，必须 timeboxing 跑通看效果再决定 PROCEED / PIVOT / KILL。**唯一持有"代码必须丢弃"哲学的 agent**。

#### Frontmatter 元信息（罕见）

```yaml
name: prototyper
tools: Read, Glob, Grep, Write, Edit, Bash
model: sonnet
maxTurns: 25                    # ⚠️ 高于一般 20，因为原型可能要试多轮
isolation: worktree             # ⚠️ 整个 49 个 agent 中唯一使用此字段
# 无 memory 声明（与原型"丢弃"哲学一致）
# 无 disallowedTools（什么都能做，速度优先）
```

> **isolation: worktree 是什么**：Claude Code 的特殊隔离模式——agent 在临时 git worktree（仓库的隔离副本）里跑，原型代码不污染主工作树。如果原型废弃，worktree 自动清理无痕；如果有用，可单独审核分支后合并。**这是 49 个 agent 中唯一使用此机制的角色**。

#### 核心哲学：Speed Over Quality

production 标准在原型中**主动放宽**：
- **架构模式**：用最快的
- **代码风格**：能 debug 就行
- **文档**：最少；只够说明在测什么
- **测试覆盖**：仅手动测试，无单元测试要求
- **性能**：仅当性能本身是测试问题时才优化
- **错误处理**：大声崩溃，不优雅处理边界

**唯一不放宽**：原型必须**与 production 隔离 + 显式标记为 throwaway**。

#### 何时该 / 不该原型

| 该原型 | 不该原型 |
|---|---|
| 机制需要"感觉到"才能评估（移动/战斗/节奏） | 设计已清晰、团队认同 |
| 团队对方案有分歧 | 风险低、是已有系统的简单扩展 |
| 技术方案未验证、风险高 | 纸面原型或设计文档就能回答 |
| 设计模糊需要具体探索 | — |
| 玩家体验在纸上无法评估 | — |

#### 核心问题制（Focus on Core Question）

**每个原型必须有一个清晰问题**，例如：
- "这套战斗手感够灵敏吗？"
- "我们能 60fps 渲染 1000 个敌人吗？"
- "这个背包系统直观吗？"

**只构建回答该问题所需的东西**——测战斗就别做菜单，测渲染就别做 gameplay 逻辑。**狠砍范围**。

#### 隔离硬约束

- 原型代码全部住在 `prototypes/[prototype-name]/`
- 每个文件开头必须有头注释：
  ```
  // PROTOTYPE - NOT FOR PRODUCTION
  // Question: [What this prototype tests]
  // Date: [When it was created]
  ```
- **原型不导入 production 代码**（要用就复制过去）
- **production 代码不导入原型**
- 原型验证概念后，production 实现**从零重写**，不复用原型代码

#### Prototype Report 模板（强制 7 字段）

```
## Prototype Report: [Concept Name]
### Hypothesis
### Approach
### Result
### Metrics
### Recommendation: [PROCEED / PIVOT / KILL]
### If Proceeding / If Pivoting
### Lessons Learned
```

保存到 `prototypes/[prototype-name]/REPORT.md`。

> **报告比代码重要**：代码是 throwaway，知识是 permanent。这种产出格式与 systems-designer 的 Formula、world-builder 的 Lore 是同级的硬性产出。

#### 原型生命周期（6 步）

```
1. Define   写问题和假设（1 段，不是文档）
2. Timebox  定时间上限（典型 1-3 天）
3. Build    最小可行原型
4. Test     玩 / 测 / 观察
5. Report   写 Prototype Report
6. Decide   PROCEED / PIVOT / KILL —— 基于证据而非投入
```

#### 涉及的 Director Gates

无独立 Gate，但报告中的 PROCEED/PIVOT/KILL 决策上送 creative-director 和 technical-director。

#### 上下游关系

**汇报给**：`creative-director`（概念验证决策）+ `technical-director`（技术可行性评估）  
**协作**：`game-designer`（定义问题、评估结果）/ `lead-programmer`（技术约束、production 模式）/ `systems-designer`（机制验证、平衡实验）/ `ux-designer`（交互模型原型）

#### 禁止做

- 让原型代码进 production
- 在原型上花时间做 production 架构
- 做最终创意决策（原型只 inform 决策）
- **超时不申请就继续**
- **抛光原型**（要抛光就重写 production 实现）

#### CodeBuddy 适配评级

**移植类型**：直接移植（Speed Over Quality 哲学 + Prototype Report 模板 + 隔离规则）+ **不建议移植**（worktree 机制）

**移植形态**：**B — 执行角色（特殊）**

**关键改造点（重要）**：
1. ⚠️ **`isolation: worktree` 在 CodeBuddy 中无对应机制**——CodeBuddy 没有 git worktree 隔离的内置支持。建议改为：
   - 在 prototyper 提示词显式约束"所有原型代码限定在 `prototypes/[name]/` 目录"
   - 在 Rules（`alwaysApply: true`）中规定"production 代码禁止导入 prototypes/"
   - 用户手动负责原型分支管理（手动 `git checkout -b prototype/xxx`）
2. **Speed Over Quality 哲学**与 CodeBuddy 默认的"严格代码质量校验 Hook"会冲突——需要临时**关闭部分 Hook**或在 prototyper skill 中显式 bypass
3. Prototype Report 7 字段作为 skill 模板硬性写入
4. timebox 机制（1-3 天）需用户自行追踪，CodeBuddy 无对应自动化
5. 6 步实现协议抽离为共享 snippet

**调用频率建议**：**低频**（仅 pre-production 阶段或重大特性前）

**适合保留档位**：
- 极简档 ⚪（小项目用一次性废文件夹+手动 git stash 即可，不必独立 agent）
- 标准档 ✅（pre-production 阶段必备）
- 完整档 ✅

> **特别提醒**：prototyper 是**最受 CodeBuddy 移植影响的 agent 之一**——其核心机制（`isolation: worktree`）在 CodeBuddy 上无对应。这意味着 CCGS 的"安全实验场"特性**部分丢失**，移植后用户需更主动地管理原型代码（手动建分支、手动清理）。

---

### 27. performance-analyst（性能分析师）

#### 一句话定位

**测、查、改性能**：通过系统化 profiling 找瓶颈，给出量化优化建议。"profile first, optimize second"是核心信条——不允许凭直觉优化。

#### Frontmatter 元信息

```yaml
name: performance-analyst
tools: Read, Glob, Grep, Write, Edit, Bash
model: sonnet
maxTurns: 20
memory: project
# 协议：实现型 6 步
```

#### 核心职责（6 项）

| 职责 | 通俗解释 |
|---|---|
| **性能 profiling** | CPU / GPU / 内存 / I/O 各自找 top 瓶颈 |
| **预算追踪** | 对照 technical-director 的预算；违规带趋势数据上报 |
| **优化建议** | 每个瓶颈：具体建议 + 预估收益 + 实现成本 |
| **回归检测** | 跨 build 比较；**每个 main 合并都应触发性能检查** |
| **内存分析** | 按类别（贴图/网格/音频/状态/UI）追踪；标记泄漏与不明增长 |
| **加载时间分析** | 每个场景与切换的加载 profile |

#### Performance Report 模板（强制 4 节）

```
## Performance Report -- [Build/Date]
### Frame Time Budget: [Target]ms
| Category       | Budget | Actual | Status |
| Gameplay Logic | Xms    | Xms    | OK/OVER |
| Rendering      | Xms    | Xms    | OK/OVER |
| Physics        | Xms    | Xms    | OK/OVER |
| AI             | Xms    | Xms    | OK/OVER |
| Audio          | Xms    | Xms    | OK/OVER |

### Memory Budget: [Target]MB
| Category | Budget | Actual | Status |

### Top 5 Bottlenecks
1. [Description, impact, recommendation]

### Regressions Since Last Report
```

> 这是又一份"硬性产出格式"。截止本批，已识别 **11 套硬性格式**——CCGS 的核心模式至此已完全清晰。

#### 涉及的 Director Gates

无独立 Gate；产出报告会触发 TD-PHASE-GATE 中的性能检查项。

#### 上下游关系

**汇报给**：`technical-director`  
**协作**：`engine-programmer` / `technical-artist` / `devops-engineer`

#### 禁止做

- **直接实现优化**（推荐 + 派给 programmer）
- 改性能预算（升级到 technical-director）
- 跳过 profiling 凭直觉找瓶颈
- **过早优化**（profile first, always）

#### CodeBuddy 适配评级

**移植类型**：直接移植（Performance Report 模板 + profile-first 戒律）+ 改造移植

**移植形态**：**B — 执行角色**

**关键改造点**：
1. 6 步实现协议共享 snippet
2. **Performance Report 4 节模板**作为 skill 硬模板
3. `memory: project` → CODEBUDDY.md 记录性能预算（来自 technical-director 的全局值）
4. "profile-first" 戒律放进 Rules（`alwaysApply: true`）：禁止凭直觉优化
5. **回归检测的 CI 触发** 在 CCGS 是 settings.json 的 hook，CodeBuddy 上需用 PostToolUse hook 在 main 合并后自动跑 perf check（详见 04 册）

**调用频率建议**：**低频**（每个 build / 每个 milestone 触发一次，不日常）

**适合保留档位**：
- 极简档 ❌（小项目无需正式 perf 体系）
- 标准档 ⚪（视项目规模）
- 完整档 ✅（任何要发布的商业项目都需要）

---

## 批 D 横向规律

### 模式 1：批 D 三人各代表一种"特殊机制"

| Agent | 特殊点 | 移植难度 |
|---|---|---|
| ux-designer | 双汇报 + Accessibility 7 项硬清单 | 低（清单放 Rule 即可） |
| prototyper | `isolation: worktree`（49 个 agent 中唯一） | **高**（CodeBuddy 无对应机制） |
| performance-analyst | profile-first 戒律 + Report 模板 | 低（戒律放 Rule + 模板放 skill） |

**批 D 是迄今为止移植难度差异最大的一批**——prototyper 是 49 个 agent 中**前 3 个最难移植**的之一（与原 CCGS 的 statusline.sh、SubagentStart hook 同级）。

### 模式 2：硬性产出格式累计 11 套

到批 D 末尾，CCGS 中已识别的硬性产出格式：

| # | 格式 | 字段数 | 产出 agent | 条件性 |
|---|---|---|---|---|
| 1 | GDD | 8 节 | game-designer | 否 |
| 2 | Sprint Plan | 多节 | producer | 否 |
| 3 | 风险登记册 | — | producer | 否 |
| 4 | Formula Output | 4 字段 | systems-designer | 否 |
| 5 | Level Document | 9 字段 | level-designer | 否 |
| 6 | Reward Output | 3 字段 | economy-designer | **是** |
| 7 | 性能预算 | 6 类 | technical-artist | 否 |
| 8 | SFX 规格 | 7 字段 | sound-designer | 否 |
| 9 | 写作硬性标准 | 5 条 | writer | 否 |
| 10 | Lore Document | 5 字段 | world-builder | 否 |
| 11 | Accessibility | 7 项 | ux-designer | 否 |
| 12 | Prototype Report | 7 字段 | prototyper | 否 |
| 13 | Performance Report | 4 节 | performance-analyst | 否 |

> 实际上是 13 套（含 Sprint/风险登记两套）。**这是 CCGS 真正的核心价值所在**——不是 agent 智能，而是**硬性产出模板的完整性**。移植到 CodeBuddy 时，**13 套模板的全量复用是最高优先级动作**，无需修改即可直接迁入。

### 模式 3：双汇报 + 三汇报开始多见

到批 D，已统计的多重汇报关系：

| Agent | 汇报对象 |
|---|---|
| engine-programmer | lead-programmer + technical-director |
| technical-artist | art-director + lead-programmer |
| ux-designer | art-director + game-designer |
| prototyper | creative-director + technical-director |

**模式总结**：跨界角色（既要美学又要代码、既要设计又要工程）天然多重汇报。**移植到 CodeBuddy 时这种结构容易丢失**，需要在 agent 提示词或 CODEBUDDY.md 中显式说明，否则 CodeBuddy 串行模式下默认归到第一个上级。

### 模式 4：`isolation: worktree` 是 CCGS 独有的"安全实验"机制

prototyper 的 `isolation: worktree` 是 CCGS 借助 Claude Code 平台能力实现的特色——它解决了一个真实痛点：**原型代码污染主仓库**。

CodeBuddy 当前**没有等价机制**，只能：
- 用目录隔离代偿（`prototypes/` 严格分离）
- 用 Rules 强制"production 不导入 prototypes/"
- 让用户手动管理 git 分支

**这是 49 个 agent 中第一个明确"功能上有损"的移植案例**——不像 sound-designer 那样是 agent 形态可优化，prototyper 的 worktree 机制属于"必须有损迁移"。

### 批 D 适配性小结

| Specialist | 形态 | 极简 | 标准 | 完整 | 移植难度 |
|---|---|---|---|---|---|
| ux-designer | B | ⚪ | ✅ | ✅ | 低 |
| prototyper | B（特殊） | ⚪ | ✅ | ✅ | **高**（worktree 机制丢失） |
| performance-analyst | B | ❌ | ⚪ | ✅ | 低 |

**批 D 极简档建议**：3 人均不在极简档独立保留。极简移植到此 Tier 3 UX/原型/性能线 = 0 个独立 agent。

**特别提醒**：如果用户的项目极看重"安全实验"（如多人协作、大量探索性原型），prototyper 的 worktree 缺失会显著影响体验。这是后续 05 册"风险与取舍清单"的重点内容之一。

---

## 批 E — 运维/数据/QA/运营/社区线（7 人）

> 这是 Tier 3 通用专员的**最后一批**，也是模型分布最复杂的一批：
> - **2 个 haiku**（devops-engineer / community-manager）—— 包含本册第 2、3 个 haiku
> - **5 个 sonnet** —— 但其中 accessibility-specialist 和 qa-tester 都是 maxTurns=10（轻量化倾向）
>
> 本批的核心移植决策是**判断哪些 sonnet 角色应"降级"为形态 C**——内容高度模板化但 CCGS 自己仍用 sonnet 的角色，往往是用错了模型，移植时正好合并到 Rules/模板里。

---

### 28. devops-engineer（DevOps 工程师）⚠️ haiku

#### 一句话定位

**构建管线 + CI/CD + 分支策略 + 自动化测试管线**的全流程负责人。"团队能可靠高效地构建、测试、发布"是核心使命。

#### Frontmatter 元信息

```yaml
name: devops-engineer
tools: Read, Glob, Grep, Write, Edit, Bash
model: haiku                                # ⚠️ 第 2 个 haiku（在 sound-designer 后）
maxTurns: 10                                # 轻量化匹配
# 无 memory / disallowedTools
```

> **疑问**：CI/CD 配置、分支策略涉及不少工程判断，CCGS 把它定为 haiku 似乎偏轻。**可能 CCGS 的判断是**：分支策略一旦定下来就是模板化的、CI 配置是按引擎/平台抄模板的、运行 Bash 命令是机械执行的——所以 haiku 够用。

#### 核心职责（6 项）

| 职责 | 通俗解释 |
|---|---|
| **构建管线** | 一条命令产出干净可复现的 build |
| **CI/CD 配置** | 每次 push 跑：编译/测试/lint，并报告结果 |
| **版本控制流** | 分支策略 / 合并规则 / 发布 tag |
| **自动化测试管线** | 单元/集成/性能 benchmark 集成进 CI，含明确 pass/fail gate |
| **构件管理** | 版本化 / 存储 / 保留策略 / 分发给测试者 |
| **环境管理** | dev / staging / production |

#### 分支策略（5 类硬约定）

```
main      —— 始终可发布、受保护
develop   —— 集成分支、跑完整 CI
feature/* —— 特性分支、从 develop 分出
release/* —— 发布候选分支
hotfix/*  —— 紧急修复、从 main 分出
```

> 这是 GitFlow 的简化版。**移植到 CodeBuddy 时这 5 类分支可直接放进 Rules（`alwaysApply: true`）**，约束所有 Git 操作。

#### 涉及的 Director Gates

无独立 Gate；会被 TD-PHASE-GATE 间接审查（"CI 是否健康"）。

#### 上下游关系

**汇报给**：`technical-director`  
**协作**：`qa-lead`（测试自动化）/ `lead-programmer`（代码质量门）

#### 禁止做

- 改游戏代码或资产
- 做技术栈决策（→ technical-director）
- 未经 technical-director 批准改服务器基础设施
- **为速度跳过 CI 步骤**（应升级"构建时间过长"问题）

#### CodeBuddy 适配评级

**移植类型**：直接移植（5 类分支约定）+ 改造移植（model + 调用方式）

**移植形态**：**B（边缘形态 C）**  
（虽然 CCGS 用 haiku，但内容包含具体工程判断（如何配 CI、如何处理失败构建）。建议**保留独立 md**，但调用极低频。)

**关键改造点**：
1. 6 步实现协议共享 snippet
2. **5 类分支策略**放 Rules（`alwaysApply: true`），全局生效
3. CodeBuddy 无 haiku 等价模型，建议用户手动选轻量模型；或在 agent 提示词注明"建议轻量模型"
4. 调用频率极低（项目初期一次性配 CI，之后只在 CI 故障时召唤），CODEBUDDY.md 应注明"按需手动 spawn"

**调用频率建议**：**低频**（项目初期 + CI 故障时）

**适合保留档位**：
- 极简档 ❌（项目用引擎自带构建，无独立 CI 需求）
- 标准档 ⚪
- 完整档 ✅

---

### 29. analytics-engineer（数据分析工程师）

#### 一句话定位

**设计遥测 + 漏斗 + A/B 测试 + 仪表盘**——把玩家行为变成可执行的设计洞察。**不做设计决策**（数据 inform，设计师 decide）。

#### Frontmatter 元信息

```yaml
name: analytics-engineer
tools: Read, Glob, Grep, Write, Edit, Bash, WebSearch
model: sonnet
maxTurns: 20
# 无 memory 声明
```

#### 核心职责（6 项）

| 职责 | 通俗解释 |
|---|---|
| **遥测事件设计** | 事件分类 / 属性 / 命名约定；每个事件必须有文档化目的 |
| **漏斗分析设计** | 引导/进阶/付费/留存 4 类关键漏斗 + 每个步骤的事件 |
| **A/B 测试框架** | 玩家分群 / 变体分配 / 成功指标 / 最小样本量 |
| **仪表盘规格** | 健康 / 特性 / 经济 仪表盘；每个图表的数据源 + 可执行洞察 |
| **隐私合规** | opt-out 机制 / 法规符合（GDPR/COPPA/CCPA） |
| **数据驱动设计** | 把分析发现翻译成可执行的设计建议 |

#### 事件命名约定（强制）

```
[category].[action].[detail]

例：
game.level.started
game.level.completed
ui.menu.settings_opened
economy.currency.spent
progression.milestone.reached
```

> **第 14 套硬性产出格式**：事件命名约定。建议**放 Rules（`alwaysApply: true`）**，所有遥测代码必须遵循。

#### 涉及的 Director Gates

无独立 Gate。

#### 上下游关系

**双汇报**：`technical-director`（系统设计） + `producer`（洞察）  
**协作**：`game-designer`（设计洞察）/ `economy-designer`（经济指标）

#### 禁止做

- **仅基于数据做游戏设计决策**（数据 inform，设计师 decide）
- 不经显式需求收集 PII
- 在游戏代码中实现 tracking（写规格给程序员）
- 用数据覆盖设计直觉（把两者都呈给 game-designer）

> 最后一条"data informs, designers decide"是 CCGS 的核心数据观——**不让 analytics 凌驾于 game-designer 之上**。这一原则应保留并强调。

#### CodeBuddy 适配评级

**移植类型**：直接移植（事件命名约定 + 隐私原则 + data-informs 戒律）+ 改造移植

**移植形态**：**B — 执行角色**

**关键改造点**：
1. **事件命名约定**放 Rules（`alwaysApply: true`）
2. **"data informs, designers decide"** 戒律放 CODEBUDDY.md 显眼位置
3. 6 步实现协议共享 snippet
4. 隐私合规 4 法规（GDPR/COPPA/CCPA）作为 Rules 单独文件

**调用频率建议**：**低频**（设计遥测时一次性，A/B 测试规划时偶尔）

**适合保留档位**：
- 极简档 ❌
- 标准档 ⚪
- 完整档 ✅

---

### 30. security-engineer（安全工程师）

#### 一句话定位

**保护游戏 + 玩家 + 数据**：审代码、设计反作弊、加密存档与网络通信、确保隐私合规。**唯一带 `Task` 工具**的 Tier 3 角色。

#### Frontmatter 元信息

```yaml
name: security-engineer
tools: Read, Glob, Grep, Write, Edit, Bash, Task     # ⚠️ 含 Task 工具
model: sonnet
maxTurns: 20
# 无 memory 声明
```

> **特别提醒**：security-engineer 是 Tier 3 中**少数带 `Task` 工具**的角色——意味着可以 spawn 子 agent 进行专项审查。这个权限在其他 Tier 3 中很罕见。CodeBuddy 移植时此能力**部分丢失**（CodeBuddy 不支持 skill 内并行 spawn），需改为串行调用其他 agent 协助审查。

#### 4 大安全域

| 域 | 关键约束 |
|---|---|
| **网络安全** | 服务端验证所有客户端输入；TLS；session token 过期+刷新；检测连接欺骗与重放攻击 |
| **反作弊** | 服务端权威所有 gameplay 关键值；检测不可能状态（速度黑/瞬移/不可能伤害）；**绝不在客户端代码或错误信息中暴露作弊检测逻辑** |
| **存档安全** | 每用户密钥加密 / 完整性校验和 / 版本化保证向后兼容 / 加载时验证（拒绝损坏/篡改文件） |
| **数据隐私** | GDPR 数据访问/删除权 / COPPA 年龄限制 / 隐私政策列出所有收集数据 |

#### Security Review Checklist（强制 7 项）

每个新特性必须验证：
- [ ] 所有用户输入校验+清理
- [ ] 日志/错误信息中无敏感数据
- [ ] 网络消息不可重放/伪造
- [ ] 服务端校验所有状态转换
- [ ] 存档优雅处理损坏
- [ ] 代码中无硬编码密钥/凭证
- [ ] 认证 token 正确过期+刷新

#### 涉及的 Director Gates

无独立 Gate；**critical 漏洞立即上报 technical-director**。

#### 上下游关系

**广泛协作**：network-programmer / lead-programmer / devops-engineer / analytics-engineer / qa-lead / **technical-director（critical 漏洞直报）**

> 这是 Tier 3 中协作面最广的角色——安全是横切关注点（cross-cutting concern）。

#### CodeBuddy 适配评级

**移植类型**：直接移植（4 大安全域规则 + 7 项审核清单）+ **不建议移植**（Task 工具能力部分丢失）

**移植形态**：**B — 执行角色**

**关键改造点**：
1. **4 大安全域规则**全部放 Rules（`alwaysApply: true`），按"网络/反作弊/存档/隐私"分 4 个 Rule 文件
2. **7 项 Security Checklist** 放 Rule（`alwaysApply: true`），任何新特性提交前必检
3. ⚠️ `Task` 工具在 CodeBuddy 中可用，但**无法并行 spawn 子审查**——原 CCGS 的"召唤多个专员同时审查"必须改为串行
4. 6 步实现协议共享 snippet
5. **critical 漏洞直报机制**在 CodeBuddy 中只能靠用户手动决断 + 对话中突出标注

**调用频率建议**：**低频**（特性 review + 发布前 + 漏洞响应）

**适合保留档位**：
- 极简档 ❌（小项目无需独立安全官）
- 标准档 ⚪（多人项目或含付费的项目需要）
- 完整档 ✅

---

### 31. qa-tester（QA 测试员）

#### 一句话定位

**写测试用例、Bug 报告、回归清单**。除此之外，**还能 scaffold 自动化测试文件**——为 Logic/Integration story 生成 GDScript/C#/C++ 测试样板。

#### Frontmatter 元信息

```yaml
name: qa-tester
tools: Read, Glob, Grep, Write, Edit, Bash
model: sonnet
maxTurns: 10                                # 轻量化（虽然 sonnet）
# 无 memory 声明
```

#### 三引擎测试样板（CCGS 内置）

qa-tester 提示词中**直接内嵌 3 套引擎测试样板**：

**Godot (GDScript / GdUnit4)**：
```gdscript
extends GdUnitTestSuite
func test_[scenario]_[expected]() -> void:
    # Arrange / Act / Assert
```

**Unity (C# / NUnit)**：
```csharp
[TestFixture]
public class [SystemName]Tests {
    [Test]
    public void [Scenario]_[Expected]() { ... }
}
```

**Unreal (C++)**：
```cpp
IMPLEMENT_SIMPLE_AUTOMATION_TEST(F[SystemName]Test, ...)
bool F[SystemName]Test::RunTest(...) { ... }
```

> **移植关键**：3 套样板可直接搬到 CodeBuddy skill 模板，无需修改。

#### 强制测试覆盖（5 项 per Logic story）

```
1. Normal case
2. Zero/null input
3. Maximum values
4. Negative modifiers (if applicable)
5. Edge case from GDD
```

#### Test Case Format（强制 4 字段）

```
## Test Case: [ID] — [Short name]
**Precondition**: [...]
**Steps**: 1. ... 2. ... 3. ...
**Expected Result**: [...]
**Pass Criteria**: [Measurable, binary]
```

#### Bug Report Format（强制完整模板）

ID / Title / Severity（S1-S4）/ Frequency / Build / Platform / Steps / Expected / Actual / Additional Context

#### Test Evidence Routing（与 qa-lead 一致的 5 类映射）

与 qa-lead 提示词中的故事类型 → 测试证据矩阵**完全一致**——这是个好的"上下游一致性"设计。

#### 模糊验收准则处理（3 步）

当遇到主观/不可测量的验收准则（"应该感觉直观"、"应该响应迅速"）：
1. 立即 flag："准则 [N] 不可测量"
2. 提出 2-3 个具体二元替代（"菜单导航 ≤ 2 次按键"等）
3. **升级到 qa-lead 裁决**

> 这是 qa-tester 与 qa-lead 的协作铆钉——**不让模糊准则蒙混进测试**。

#### 涉及的 Director Gates

无独立 Gate；测试结果输入 QL-STORY-READY / QL-TEST-COVERAGE（qa-lead 主持）。

#### 上下游关系

**汇报给**：`qa-lead`

#### 禁止做

- 修 Bug（报告由 qa-lead 派给 programmer）
- 评定 S2 以上严重度（升级 qa-lead）
- 跳过测试步骤
- **批准发布**（→ qa-lead）

#### CodeBuddy 适配评级

**移植类型**：直接移植（3 引擎样板 + Test Case 4 字段 + Bug 模板 + 5 项强制覆盖）+ 改造移植

**移植形态**：**B — 执行角色**

**关键改造点**：
1. **3 引擎测试样板**作为 skill 模板硬模板，直接搬运
2. **Test Case 4 字段 + Bug Report 模板**放 skill 模板
3. **5 项 Logic 测试覆盖**放 Rules（`alwaysApply: true`）
4. 模糊准则 3 步处理流程作为 skill 内嵌逻辑
5. 6 步实现协议共享 snippet

**调用频率建议**：**高频**（每个 Logic story 都触发自动化测试 scaffold）

**适合保留档位**：
- 极简档 ⚪（用户可自己写测试模板）
- 标准档 ✅
- 完整档 ✅

---

### 32. accessibility-specialist（无障碍专员）

#### 一句话定位

**确保游戏对最广泛玩家可玩**：执行 WCAG 2.1 AA 标准，审 UI 合规、设计辅助功能（重映射 / 文字缩放 / 色盲模式 / 屏幕阅读器）。

#### Frontmatter 元信息

```yaml
name: accessibility-specialist
tools: Read, Glob, Grep, Write, Edit, Bash
model: sonnet
maxTurns: 10                                # 轻量化（与 qa-tester 同）
# 无 memory 声明
```

#### 4 类无障碍标准（每类 5-7 条硬约束）

**视觉无障碍**：18px 最小字号 / 4.5:1 文字对比度 / 3 种色盲模式 / 字幕含说话人标识 / 至少 3 档字幕大小

**音频无障碍**：所有对话有字幕 / 重要方向音的视觉指示器 / 5 类音量滑块（Master/Music/SFX/Dialogue/UI）/ 单声道选项

**动作无障碍**：完整输入重映射 / 无强制多键同时 / QTE 必须可跳过 / 单手游戏模式 / 自瞄选项

**认知无障碍**：UI 一致性 / 教程可重玩 / 任务提示常驻 / 单人游戏随时可暂停

#### Audit Checklist（8 项硬性，每屏每特性必检）

- [ ] 文字达最小尺寸+对比度
- [ ] 颜色不是唯一信息载体
- [ ] 所有交互元素键盘/手柄可达
- [ ] 所有音频内容有字幕
- [ ] 输入可重映射
- [ ] 无强制多键同时按
- [ ] 屏幕阅读器注解（如适用）
- [ ] 动效敏感内容可减弱/禁用

#### Findings Format（强制表格）

```
## Accessibility Audit: [Screen / Feature]
| Finding | WCAG Criterion | Severity | Recommendation |
|---------|---------------|----------|----------------|
| ... | SC 1.4.3 Contrast (Minimum) | BLOCKING | ... |
```

**WCAG 引用规范**：必须引用具体 Success Criterion 编号（如 SC 1.4.3）。默认遵循 WCAG 2.1 Level AA。

> **第 15 套硬性产出格式**：Audit Findings 表格 + WCAG 引用规范。

#### 涉及的 Director Gates

无独立 Gate；**accessibility blocker 上报 producer 作为发布阻塞问题**。

#### 上下游关系

广泛协作：`ux-designer` / `ui-programmer` / `audio-director` / `sound-designer` / `qa-tester` / `localization-lead` / **art-director**（色盲调色板与视觉方向冲突时）/ **producer**（accessibility blocker）

#### CodeBuddy 适配评级

**移植类型**：直接移植（WCAG 2.1 AA + 4 类标准 + 8 项 Audit）+ 改造移植

**移植形态**：**B → 倾向 C**  
（CCGS 用 sonnet，但内容**几乎全是模板化约束**——18px / 4.5:1 / SC 编号引用都是查表式应用。**理论上完全可以拆为 Rules 让 ux-designer 顺手做审计**。但考虑到 WCAG 标准很专精且这个 agent 协作面广（与 7 个其他角色协作），保留独立 md 可能更稳妥。**这是 49 个 agent 中归类最有争议的之一**——边缘 C 但建议保留。)

**关键改造点**：
1. **4 类无障碍标准**全部放 Rules（`alwaysApply: true`），按"视觉/音频/动作/认知"分 4 个 Rule 文件
2. **8 项 Audit Checklist**放 Rule（`alwaysApply: true`），任何 UI/UX 设计自动检查
3. **WCAG SC 引用规范**作为审计 skill 的硬模板
4. ux-designer 的 Accessibility Checklist（7 项）和本 agent 的 Audit Checklist（8 项）有重叠，移植时建议**合并**为一份完整 18 项清单
5. 6 步实现协议共享 snippet

**调用频率建议**：**中频**（每次 UI 设计 + 发布前最终 audit）

**适合保留档位**：
- 极简档 ❌（小项目可由 ux-designer 兼任）
- 标准档 ⚪
- 完整档 ✅（商业项目必保，accessibility 是商业平台合规要求）

> **形态归类讨论**：accessibility-specialist 的标准本身高度模板化，但其"为产品做 audit 报告 + 与 7 角色协作 + 上报阻塞 producer" 的工作流复杂度足以支撑独立 agent。保留独立 md 是更安全的选择。

---

### 33. live-ops-designer（运营设计师）

#### 一句话定位

**后期内容策略 + 玩家留存 + 活动经济 + 反掠夺货币化**。负责"游戏发布后保持新鲜、玩家持续参与、不靠掠夺性设计赚钱"。

#### Frontmatter 元信息

```yaml
name: live-ops-designer
tools: Read, Glob, Grep, Write, Edit, Task        # 含 Task 工具
model: sonnet
maxTurns: 20
disallowedTools: Bash
# 无 memory 声明
# 协议：设计型 4 步（与 ux/world-builder 等同族）
```

#### 5 档内容节奏（Cadence）

| 节奏 | 内容 |
|---|---|
| **每日** | 登录奖励 / 每日挑战 / 商店轮换 |
| **每周** | 周挑战 / 推荐物品 / 社区活动 |
| **双周/月** | 内容更新 / 平衡补丁 / 新物品 |
| **季度（6-12 周）** | 大内容 / 战令重置 / 叙事弧 |
| **年度** | 周年活动 / 年度回顾 / 大扩展 |

每档必须有 **2 周以上提前缓冲**。

#### 季节结构（必含 6 项）

- 主题（绑定世界观）
- 战令（免费 + 付费双轨）
- 新游戏内容（地图/模式/角色/物品）
- 季节挑战集
- 限时活动（每季 2-3 个）
- 经济重置点

#### 战令设计原则（5 条强约束）

- 免费轨必须给有意义进度（不能感觉惩罚性）
- 付费轨只加饰品和便利
- **付费独占道具不能影响 gameplay（禁 pay-to-win）**
- 进度曲线：早期快（钩住）/ 中期稳 / 后期需投入
- 含**晚加入者追赶机制**

#### 道德指南（7 条强约束）⚠️ 极重要

- **禁止真钱购买随机结果的开箱**（任何随机机制必须显示概率）
- 禁止人为体力/精力系统逼迫付费
- **禁止 pay-to-win**（饰品和便利可付费）
- 透明定价 / 不混淆货币换算
- 尊重玩家时间（grind 必须好玩）
- 未成年友好（家长控制 / 限额）
- 文档化道德政策到 `design/live-ops/ethics-policy.md`

#### 升级路径（特殊）

- **掠夺性货币化 flag**：识别为掠夺性的设计（真钱开箱 / 付费完成门 / 人为体力墙），**不可静默实施**——必须 flag、文档化关切、**升级到 creative-director 做最终裁决**
- 跨域设计冲突（live-ops 与核心进度冲突）→ creative-director 仲裁

#### 涉及的 Director Gates

无独立 Gate；但掠夺性设计 flag 触发 CD 级别决策。

#### 上下游关系

**广泛协作**：`game-designer` / `economy-designer` / `narrative-director` / `producer` / `analytics-engineer` / `community-manager` / `release-manager` / `writer`

#### CodeBuddy 适配评级

**移植类型**：直接移植（5 档节奏 + 季节结构 + 战令规则 + **7 条道德指南**）+ 改造移植

**移植形态**：**B — 执行角色**

**关键改造点**：
1. 4 步设计协议共享 snippet
2. **7 条道德指南**放 Rules（`alwaysApply: true`），最高优先级强约束（任何货币化设计必查）
3. **掠夺性设计升级到 CD 的机制**在 skill 提示词中显式编码（不能默默跳过）
4. 5 档 cadence 模板放 CODEBUDDY.md 一节

**调用频率建议**：**低频**（仅含 live-service 的项目；buy-once 项目零频）

**适合保留档位**：
- 极简档 ❌（buy-once 项目无需要）
- 标准档 ❌（除非项目本身是 live service）
- 完整档 ⚪（live service 项目才保留）

> **道德指南的特殊价值**：即便项目不做 live service，**这 7 条道德指南本身**可作为 CODEBUDDY.md 的"项目伦理底线"放入——指导未来任何货币化决策。

---

### 34. community-manager（社区经理）⚠️ haiku

#### 一句话定位

**所有玩家可见沟通**：补丁说明、社媒、社区更新、玩家反馈、危机沟通。**翻译开发团队 ↔ 玩家社区**。

#### Frontmatter 元信息

```yaml
name: community-manager
tools: Read, Glob, Grep, Write, Edit, Task
model: haiku                                # ⚠️ 第 3 个 haiku
maxTurns: 10
disallowedTools: Bash
# 协议：实现型 6 步（疑似模板复制错误，应为设计型）
```

> **协议错误**：community-manager 的工作（写补丁说明 / 社媒 / 危机沟通）与"实现型 6 步"完全不匹配。这又是模板复制错误，与 sound-designer / writer 同属 CCGS 中的协议归属瑕疵。

#### Patch Notes 结构（强制 6 节）

```
1. Headline       —— 最激动人心或最重要的变更
2. New Content    —— 新特性/地图/角色/物品
3. Gameplay Changes —— 平衡调整/机制变更
4. Bug Fixes      —— 按系统分组
5. Known Issues   —— 透明地说明未解决问题
6. Developer Commentary —— 重大变更的可选上下文
```

**写法约束**：用玩家语言（不是开发者）/ 平衡变更要带 before/after 数值 / 路径 `production/releases/[version]/patch-notes.md`

#### 危机沟通 5 步（强制流程）

```
1. 30 分钟内确认问题
2. 每 30-60 分钟更新一次状态
3. 具体说明（"登录服务器宕机"，不是"我们遇到问题"）
4. 提供 ETA + 变化时更新
5. 解决后做 post-mortem
```

#### 语气与声音（6 条强约束）

- 友好但专业，绝不居高临下
- 共情玩家挫败感
- 诚实承认局限
- 对内容真诚兴奋
- **绝不与批评（哪怕不公正）对抗**
- 跨渠道一致

#### 反馈管道（3 阶段）

收集 → 处理（每周摘要）→ 响应（公开承认热门请求 / 改了之后闭环 / 不未经 producer 批准承诺特性）

#### 涉及的 Director Gates

无独立 Gate。

#### 上下游关系

**广泛协作**：producer（消息批准）/ release-manager（补丁说明时机）/ live-ops-designer / qa-lead / game-designer / narrative-director / analytics-engineer

#### CodeBuddy 适配评级

**移植类型**：**改造移植**（最适合形态 C）

**移植形态**：**C — 参考角色**  
（**第 2 个明确归类形态 C 的 agent**——haiku + 高度模板化（6 节 patch notes / 5 步危机 / 6 条语气）+ 协议错误。最佳处理：**不保留独立 md**，将所有模板拆出，由 producer/release-manager 顺手做。)

**关键改造点**：
1. **不保留独立 agent 文件**
2. **6 节 patch notes 模板**作为 `/patch-notes` skill 的硬模板
3. **5 步危机沟通流程**作为 `/crisis-response` skill 的硬模板
4. **6 条语气约束**放 Rules（`alwaysApply: true`），约束所有玩家可见内容写作
5. 反馈管道 3 阶段流程作为 skill 内嵌逻辑

**调用频率建议**：N/A（不再作为独立 agent）

**适合保留档位**：
- 极简档 ❌
- 标准档 ❌（除非项目有公开发布需要）
- 完整档 ⚪（如果用户特别想保留独立社区经理可保留，但需修正协议）

> **形态 C 累计 2 个**：sound-designer + community-manager。这两位的共同特征：**haiku + 内容高度模板化 + 协议归属错误**——这正是 CCGS 中"被模板批量克隆但模型选错"的群体。

---

## 批 E 横向规律

### 模式 1：本批是模型分布最复杂的一批

| Agent | 模型 | 实际工作模板化程度 | 模型选择是否合理 |
|---|---|---|---|
| devops-engineer | haiku | 中（5 类分支策略 + CI 配置） | ⚪（边缘合理） |
| analytics-engineer | sonnet | 中（事件命名 + 漏斗设计） | ✅ 合理 |
| security-engineer | sonnet | 中（4 安全域 + 7 项 checklist） | ✅ 合理 |
| qa-tester | sonnet (10 turns) | 高（3 引擎样板 + 4 字段模板） | ⚪（可降级） |
| accessibility-specialist | sonnet (10 turns) | **极高**（4 类标准 + 8 项 audit + WCAG 表格） | ❌（应为 haiku 或 C） |
| live-ops-designer | sonnet | 中（5 档节奏 + 7 条道德） | ✅ 合理 |
| community-manager | haiku | **极高**（6 节 patch + 5 步危机 + 6 条语气） | ✅ 合理（haiku 选对了） |

**模式总结**：**accessibility-specialist 是 CCGS 中"模型选偏重"的代表**——内容比 community-manager 还模板化，却用了 sonnet。这反向证明了：**模型选择不全是 CCGS 的客观判断结果，部分是历史遗留**。移植时不必盲从原模型选择，而应基于内容性质重判断。

### 模式 2：协议错误又出现 2 处

到批 E 末尾累计的协议错误：
- sound-designer：实现型（应设计型）
- writer：混合型（应设计型）
- community-manager：实现型（应设计型）

3 处错误集中在"haiku 或轻量化 sonnet + 内容高度模板化"的角色上。**移植时把协议抽离为共享 snippet 后，这类错误自然消失**——这是 02 册迄今最重要的结构性优化建议。

### 模式 3：道德/隐私底线开始出现

批 E 引入了 3 条 CCGS 的"伦理硬底线"：

- **analytics-engineer**："data informs, designers decide"——数据不能凌驾于设计师
- **security-engineer**：4 大安全域（包括隐私 GDPR/COPPA/CCPA）
- **live-ops-designer**：7 条道德指南（禁开箱真钱抽奖 / 禁 pay-to-win / 透明定价 / 未成年保护）

**移植洞察**：这些硬底线**与平台无关**，应作为 CODEBUDDY.md 顶层"工作室伦理章程"全局生效，而不是只在某个 agent 触发时才检查。

### 模式 4：硬性产出格式累计 16 套

到批 E 末尾累计：
- 14. 事件命名约定（analytics-engineer）
- 15. Audit Findings 表格（accessibility-specialist）
- 16. Patch Notes 6 节（community-manager）

加上前 13 套，**CCGS 共有 16 套硬性产出格式**——其中至少 12 套可直接放进 CodeBuddy skill 模板，无需修改。**这是 CCGS 移植的最高 ROI 动作**。

### 模式 5：广泛协作面是 Tier 3 真正"中心节点"的标志

批 E 中协作面广的角色：
- security-engineer（5+ 协作）
- accessibility-specialist（**8+ 协作** —— 本册最广）
- live-ops-designer（8+ 协作）
- community-manager（7+ 协作）

广协作 = 横切关注点（cross-cutting concern）。这些角色不属于任何单一部门，是真正的"多 Lead 共同的资源"。**移植时它们的提示词应包含"与 X 协作"的提示**，否则 CodeBuddy 串行模式下容易被错误归到单一上级。

### 批 E 适配性小结

| Specialist | 模型 | 形态 | 极简 | 标准 | 完整 |
|---|---|---|---|---|---|
| devops-engineer | haiku | B（边缘 C） | ❌ | ⚪ | ✅ |
| analytics-engineer | sonnet | B | ❌ | ⚪ | ✅ |
| security-engineer | sonnet | B | ❌ | ⚪ | ✅ |
| qa-tester | sonnet | B | ⚪ | ✅ | ✅ |
| accessibility-specialist | sonnet | B（边缘 C） | ❌ | ⚪ | ✅ |
| live-ops-designer | sonnet | B | ❌ | ❌ | ⚪ |
| community-manager | haiku | **C**（不保留 md） | ❌ | ❌ | ⚪ |

**批 E 极简档建议**：仅保留 qa-tester 1 个独立 agent。极简移植到此 Tier 3 运维/数据/QA/运营/社区线 = 1 个独立 agent。

---

## Tier 3 通用专员（批 A-E 共 24 人）阶段性总结

到此 Tier 3 通用专员（不含三引擎组）已全部分析完毕，共 **24 人**：3（设计）+ 6（程序）+ 4（美术/音频/叙事）+ 3（UX/原型/性能）+ 7（运维/数据/QA/运营/社区）+ 1（**注意**：实际是 3+6+4+3+7=23 人，不是 24，原表格错误）。

**核实**：实际 23 人。修正后 49 个 agent = 3 Director + 8 Lead + **23 通用 Specialist** + 15 引擎 Specialist = 49。✅

### Tier 3 通用专员形态分布最终结果

| 形态 | 数量 | 占比 |
|---|---|---|
| 形态 A（Gate 专用） | 0 | 0% |
| 形态 B（执行角色） | 21 | 91% |
| 形态 C（参考角色，不保留独立 md） | 2（sound-designer / community-manager） | 9% |

**结果对比 01b 预测**：
- 预测形态 C 占 35%（基于 49 全员含 Director/Lead）
- 实际 Tier 3 通用专员中形态 C 仅 9%——比预期低很多
- **原因**：CCGS 大多数 specialist 即便用 haiku，也是有具体决策职责（不是纯模板填空），保留独立 md 价值更高

> **修正预测**：49 全员中形态 C 估计为 4-6 个（sound-designer + community-manager + 三引擎组里 1-2 个轻量专员）。这意味着移植时**绝大多数 agent 应保留独立 md**——精简的关键不在于砍 agent 数量，而在于**降低调用频率 + 抽离共享协议 + 把模板放进 skill**。

### Tier 3 极简档保留清单（共 24 - 1 不存在）

```
设计线：0（全部由 game-designer 兼任）
程序线：1-2（gameplay-programmer 必保 + ui-programmer 视项目）
美术/音频/叙事线：0
UX/原型/性能线：0
运维/数据/QA/运营/社区线：1（qa-tester）

合计：2-3 人
```

**极简移植 Tier 3 通用专员清单**：
- 必保：gameplay-programmer / qa-tester
- 视项目：ui-programmer

其余 20 个 specialist 在极简档要么不保留，要么并入 Lead 提示词。

---

## Tier 3 — 三引擎专员组（15 人）

> ⚠️ **三选一提示（档位策略）**：本组 15 人按"Godot / Unity / Unreal"三套对称镜像设计，但**单个项目只会用其中 1 套**。移植时按档位策略取舍：
> 
> | 档位 | 引擎组保留策略 |
> | --- | --- |
> | **极简档（MVS）** | **不保留三引擎组**（共 0 人；引擎相关由 game-designer / lead-programmer 兼任） |
> | **标准档** | **三选一**：用户实际使用的 1 套引擎组的 Lead + 1-3 个子专员（共 2-4 人） |
> | **完整档** | **三选一全保留**（5 人）；其余 2 套引擎组直接跳过（共 5 人） |
> 
> 因此本章逐份拆解虽给出三套各 5 人的篇幅，但**实际移植时无需为 3 套引擎并行准备**——只需照用户选定引擎做对应迁移。本章的"三套对称展示"是为了**给读者展示 CCGS 的设计模式**（详见 §3412 "完美对称"洞察），并便于将来切换/扩展其他引擎时复用结构。

> 这是 Tier 3 的**最后一批**，也是**最有选择性的**一批——用户大概率只选 1-2 套引擎，其余整组可直接跳过。因此本章采用 **"每引擎 1 个 Lead 精读 + 4 个子专员汇总" 的策略**，避免重复展开。
>
> ### 引擎组结构（完美对称）
>
> | 引擎 | Lead | 子专员（4 个） |
> |---|---|---|
> | Godot 4 | godot-specialist | godot-gdscript / godot-csharp / godot-shader / godot-gdextension |
> | Unity | unity-specialist | unity-dots / unity-shader / unity-addressables / unity-ui |
> | Unreal 5 | unreal-specialist | ue-blueprint / ue-gas / ue-replication / ue-umg |
>
> **三引擎组完全镜像的 1-Lead + 4-子专员结构**是 CCGS 最清晰的"可复制模式"之一——移植到其他引擎（Bevy / Love2D / 自研引擎）时，只需照此结构套一套即可。
>
> ### 共同特征（对 15 人全员成立）
>
> - **全部 sonnet 模型、maxTurns=20**（无 haiku）
> - **全部使用实现型 6 步协议**（与 Tier 2 lead-programmer 家族同源）
> - **无 memory 声明、无 disallowedTools 声明**（唯一例外：`ue-blueprint-specialist` 禁用 Bash——BP 是编辑器内资源）
> - **都持有 `Task` 工具**——Lead 用 Task spawn 子专员；**但 4 个 Godot 子专员也保留 Task 工具**，实际用不到，是模板继承的冗余
> - **4 个 Godot 系 agent 独有"Tooling — ripgrep File Filtering"段落**（警告 `*.gd` 文件必须用 `glob: "*.gd"` 而非 `type: "gdscript"`）——其他 11 个没有
> - **Version Awareness 覆盖不全**：4 个 Godot agent 全有；**所有 Unity 和 UE agent 均无** —— 这是 CCGS 的一个**明显缺陷**，移植时应全员补齐
>
> ### 形态归类（15 人）
>
> - **形态 B（执行角色）** — 全部 15 人
> - 引擎 Lead 有 `Task` 工具可 spawn 子专员，但**这不让它们变成形态 A**——它们的产出仍是具体代码/配置，不是审查意见

---

### 35. godot-specialist（Godot 引擎专员 / Lead）

#### 一句话定位

**Godot 4 项目的引擎权威**：指导 GDScript/C#/GDExtension 语言选型、执行 node/scene 架构、信号/Resource 模式、导出模板与平台部署。4 个 Godot 子专员的 orchestrator。

#### Frontmatter 元信息

```yaml
name: godot-specialist
tools: Read, Glob, Grep, Write, Edit, Bash, Task    # 含 Task 工具（可 spawn 子专员）
model: sonnet
maxTurns: 20
```

#### 6 大 Best Practices 主题

| 主题 | 核心约束 |
|---|---|
| **Scene/Node 架构** | 组合优先于继承；每个 scene 自包含可复用；`@onready` 替代硬编码路径；场景树保持扁平 |
| **GDScript 标准** | 处处静态类型；`class_name` 注册；`@export` 暴露属性；信号解耦通信；`await` 替代 `yield` |
| **资源管理** | `Resource` 子类存数据；`.tres` 文件存共享数据；`ResourceLoader.load_threaded_request()` 加载大资产；资源 UID 防改名 |
| **信号与通信** | 信号在脚本顶部声明；在 `_ready()` 或编辑器连接（禁 `_process()` 内连接）；signal bus autoload 做全局事件 |
| **性能** | 最少化 `_process()`；`Tween` 替代手动插值；对象池；`VisibleOnScreenNotifier` 裁剪；`MultiMeshInstance` 批量渲染 |
| **Autoloads** | 少用；文档化每个 autoload 的用途到 CLAUDE.md |

#### Common Pitfalls to Flag（7 条反模式清单）

- 用长 `get_node()` 路径代替信号
- 应事件驱动却每帧 `_process()`
- 不调 `queue_free()` 造成内存泄漏
- **在 `_process()` 中连接信号**（每帧连接，巨量泄漏）
- `@tool` 脚本无编辑器安全检查
- 忽略 `tree_exited` 信号做清理
- 不用 typed array

> 这份"反模式清单"是 godot-specialist 的**独特价值** —— 不仅告诉你怎么做对，还明确告诉你 AI 容易做错什么。移植时作为 Rule（`alwaysApply: true`）强约束，任何 Godot 代码提交前自动检查。

#### Version Awareness（关键机制）

```
1. 读 docs/engine-reference/godot/VERSION.md 确认引擎版本
2. 查 deprecated-apis.md / breaking-changes.md
3. 子系统工作查 docs/engine-reference/godot/modules/*.md
4. API 不在 reference docs 且在 May 2025 之后引入 → WebSearch 验证
5. 参考文档优先于训练数据
```

> Godot lead + 4 个子专员都有此机制。**Unity/UE 组整组缺失**，是 CCGS 的明显不一致性。

#### ripgrep 独有警告

```
*.gd 文件在 ripgrep 中注册为 "gap" 类型（不是 gdscript）
必须用 glob: "*.gd"，禁止 type: "gdscript"（硬错误）
```

这是 CCGS 作者踩过的真实坑，只在 Godot 组的 5 个 agent 中出现。

#### 涉及的 Director Gates

无独立 Gate；通过 lead-programmer 向 technical-director 汇报。

#### 上下游关系

**汇报给**：`technical-director`（via `lead-programmer`）  
**委派给**：godot-gdscript-specialist / godot-shader-specialist / godot-gdextension-specialist  
**协作**：gameplay-programmer / technical-artist / performance-analyst / devops-engineer

#### Sub-Specialist Orchestration（核心机制）

Lead 通过 Task tool 派发给 3 个子专员：
- `godot-gdscript-specialist` — GDScript 架构、静态类型、信号、协程
- `godot-shader-specialist` — Godot shading language、可视化 shader、粒子
- `godot-gdextension-specialist` — C++/Rust 绑定、原生性能、自定义节点

**原设计鼓励并行 spawn**：`"Launch independent sub-specialist tasks in parallel when possible."`

> ⚠️ **移植警告**：这是 CCGS 中**最依赖并行 spawn 的设计之一** —— Godot 特性开发可能同时需要 GDScript + Shader + GDExtension 三路并行。CodeBuddy 串行模式下，这套编排会显著变慢（约 3 倍时间）。01b 册 P0 分析适用于此处。

#### 禁止做

- 做游戏设计决策（建议引擎影响，不决定机制）
- 未讨论就推翻 lead-programmer 架构
- **直接实现特性**（派给子专员或 gameplay-programmer）
- 未经 technical-director 批准批准工具/依赖/插件
- 管排期或资源分配（→ producer）

#### CodeBuddy 适配评级

**移植类型**：直接移植（6 大 Best Practices + 7 条反模式 + ripgrep 警告 + Version Awareness）+ 改造移植（并行 spawn 改串行）

**移植形态**：**B — 执行角色**

**关键改造点**：
1. 6 步实现协议共享 snippet
2. **6 大 Best Practices + 7 条反模式**放 Rules（`alwaysApply: true`，作用域限定为 Godot 项目；CodeBuddy 无 glob 需用手动规则代偿）
3. **Version Awareness 机制**保留，放 Rules；**建议扩展到 Unity/UE 组补全 CCGS 原本的缺陷**
4. ripgrep 警告放 Rules 或 CODEBUDDY.md
5. ⚠️ **3 个子专员的并行 spawn 改为串行**——CodeBuddy 不支持；原 Lead 中"并行派发"的提示词需改为"评估是否需要子专员后串行依次派发"
6. `Task` 工具在 CodeBuddy 中仍可用，但无法并行

**调用频率建议**：**中频**（Godot 项目高频，非 Godot 项目零频）

**适合保留档位**：
- 极简档 ⚪（视项目是否用 Godot）
- 标准档 ✅（Godot 项目必保）
- 完整档 ✅

---

### 36. unity-specialist（Unity 引擎专员 / Lead）

#### 一句话定位

**Unity 项目的引擎权威**：指导 MonoBehaviour vs DOTS/ECS 决策、Addressables/Input System/UI Toolkit 等子系统使用、渲染管线选型。4 个 Unity 子专员的 orchestrator。

#### 差异聚焦（与 godot-specialist 对比）

**7 大 Best Practices 主题**（比 Godot 多 1 个"Asset Management"）：

| 主题 | 核心约束 |
|---|---|
| 架构模式 | 组合优先；ScriptableObject 存数据；接口解耦；**DOTS/ECS** 用于大量实体；`.asmdef` 控制编译 |
| **C# 标准** | 禁 `Find()`/`FindObjectOfType()`/`SendMessage()`；`Awake()` 缓存组件；`[SerializeField] private`；`[Header]`/`[Tooltip]` 组织 inspector |
| **内存与 GC** | 避免热路径分配；`StringBuilder`；`NonAlloc` API；`ObjectPool<T>` 池化；`Span<T>`/`NativeArray<T>`；避免装箱 |
| **资源管理** | **Addressables 替代 `Resources.Load()`**；`AssetReferences` 而非直接 prefab；sprite atlas；每平台导入设置 |
| 新 Input System | `.inputactions` 资产；`performed`/`canceled` 回调而非 `Update()` 轮询 |
| UI | UI Toolkit 优先（runtime UI）；UGUI 为 world-space 或补缺；MVVM 数据绑定；池化列表 |
| 渲染与性能 | **SRP（URP 或 HDRP）禁用 built-in 管线**；GPU instancing；LOD；occlusion culling；烘焙光照 |

**8 条反模式清单**（比 Godot 多 1 条）：
- 空 `Update()`
- 热路径分配
- destroyed 对象的 null 检查（用 `== null` 而非 `is null`）
- 协程泄漏
- 缺 `[SerializeField]`
- 忘记 `static` 标注妨碍 batching
- `DontDestroyOnLoad` 过度使用
- 忽略脚本执行顺序

#### Sub-Specialist（4 个，Godot 是 3 个）

- `unity-dots-specialist` — ECS / Jobs / Burst
- `unity-shader-specialist` — Shader Graph / VFX Graph / URP-HDRP
- `unity-addressables-specialist` — Addressables / bundle / 内存
- `unity-ui-specialist` — UI Toolkit / UGUI / 数据绑定 / 跨平台输入

#### 关键缺陷

**无 Version Awareness 段落** —— Godot 全系有，Unity 和 UE 全系无。这是 CCGS 的明显**不一致性**。移植时应**补齐**。

#### CodeBuddy 适配评级

与 godot-specialist 类似（形态 B，改造移植），但有 2 处额外改造点：
1. **补齐 Version Awareness**（参照 Godot 组模板）
2. **4 个子专员的串行派发** —— 比 Godot 多一个（UI 子专员），串行等待时间更长

**适合保留档位**：极简 ⚪ / 标准 ✅（Unity 项目）/ 完整 ✅

---

### 37. unreal-specialist（Unreal 引擎专员 / Lead）

#### 一句话定位

**Unreal Engine 5 项目的引擎权威**：指导 Blueprint vs C++ 决策、GAS/Enhanced Input/Common UI/Niagara 等子系统使用、UObject 生命周期管理。4 个 UE 子专员的 orchestrator。

#### 差异聚焦（与 godot/unity 对比）

**7 大 Best Practices 主题**（与 Unity 同数）：

| 主题 | 核心约束 |
|---|---|
| **C++ 标准** | `UPROPERTY()`/`UFUNCTION()`/`UCLASS()` 正确标注；`TObjectPtr<>` 替代裸指针；Unreal 命名前缀（F/E/U/A/I）；`TArray`/`TMap` 而非 STL；`NewObject<>()` 替代 `new` |
| **Blueprint 集成** | `BlueprintReadWrite`/`EditAnywhere` 暴露调参；`BlueprintNativeEvent` 设计师可 override；**BP 图保持小 —— 复杂逻辑去 C++**；Data-only BP 做内容变体 |
| **GAS（Gameplay Ability System）** | 所有战斗能力/buff/debuff 走 GAS；Gameplay Effect 修改属性（禁直接改）；Gameplay Tags 替代 bool；Attribute Set 管理数值；Ability Task 处理异步流 |
| **性能** | `SCOPE_CYCLE_COUNTER`；避免 Tick；对象池；level streaming；Nanite + Lumen；**Unreal Insights 而非 FPS counter** |
| **网络（多人）** | 服务端权威 + 客户端预测；`DOREPLIFETIME`；RPC 三类（Server/Client/NetMulticast）；**只复制必要内容**（带宽精贵） |
| **资源管理** | **Soft References（`TSoftObjectPtr`/`TSoftClassPtr`）**；Asset Manager + Primary Asset ID；Data Tables / Data Assets |
| 反模式 | 不需要的 Tick；热路径字符串；每帧 spawn/destroy；**>20 节点的 BP spaghetti**；缺 `Super::` 调用；GC 抖动 |

#### UE 独有关键：GAS 系统

UE 组与 Godot/Unity 组最大的不同是 **GAS**——作为整个 UE 生态的核心框架，需要专门的子专员（`ue-gas-specialist`）。这是其他两个引擎没有等价的。

#### Sub-Specialist（4 个）

- `ue-gas-specialist` — GAS / effect / attribute / tag
- `ue-blueprint-specialist` — BP 架构、BP/C++ 边界、图形规范（**唯一禁用 Bash 的子专员**）
- `ue-replication-specialist` — 属性复制、RPC、预测、relevancy
- `ue-umg-specialist` — UMG / Common UI / widget / 数据绑定

#### 缺陷

与 Unity 相同——**无 Version Awareness**。移植时应补齐。

#### CodeBuddy 适配评级

与 godot/unity 类似。**额外改造点**：
- GAS 是 UE 独有且高度复杂的子系统，ue-gas-specialist 的串行 spawn 代价最大（单次可能要写 ability/effect/attribute 三件套）
- ue-blueprint-specialist 禁用 Bash 的 frontmatter 设计**唯一在 CodeBuddy 中可以完美映射**（CodeBuddy allowed-tools 白名单反向声明即可）

**适合保留档位**：极简 ⚪ / 标准 ✅（UE 项目）/ 完整 ✅

---

### 38-49. 12 个引擎子专员（汇总表）

> 以下 12 个子专员采用"一表概览 + 关键差异标注"的形式。因为它们高度同质化（全部 sonnet/maxTurns=20/实现型 6 步协议），差异化仅在技术领域和产出格式上。

#### Godot 子专员组（4 个）

| Agent | 技术领域 | 独有硬性产出格式 | Engine Ver. Safety | 形态 |
|---|---|---|---|---|
| **38. godot-gdscript-specialist** | GDScript 代码质量 / 静态类型 / 信号 / 性能 | 文件章节顺序清单；性能阈值（>1000 次/帧转 GDExtension）；最大继承深度 3 | ✅ | B |
| **39. godot-csharp-specialist** | Godot C# / .NET 模式 / partial class / nullable | .csproj 模板；命名约定（signal `EventHandler` 后缀）；`_Ready` 下划线前缀 | ✅ | B |
| **40. godot-shader-specialist** | Godot shading language / 材质 / 粒子 / 后处理 | shader 命名 `[type]_[category]_[name].gdshader`；**GPU 帧预算分配表**（几何4-6ms / 光照2-3ms / 阴影2-3ms 等）；粒子 <2ms | ✅（4.6/4.5/4.4 版本提示） | B |
| **41. godot-gdextension-specialist** | C++/Rust 原生绑定 / SCons / Cargo | .gdextension 文件模板；**ABI 兼容警告**（小版本间二进制不兼容） | ✅ + ABI 警告段 | B |

**共同特征**：4 个全部含 ripgrep 警告段、Version Awareness 段。

#### Unity 子专员组（4 个）

| Agent | 技术领域 | 独有硬性产出格式 | Engine Ver. Safety | 形态 |
|---|---|---|---|---|
| **42. unity-dots-specialist** | DOTS/ECS / Jobs / Burst / Hybrid Renderer | 组件组织 GOOD/BAD 对比；Burst 禁用类型清单；Allocator 选择约定（TempJob / Persistent） | ❌ | B |
| **43. unity-shader-specialist** | Shader Graph / HLSL / VFX Graph / URP/HDRP | 命名 `SG_[Category]_[Name]` / `VFX_[Category]_[Name]`；**硬性预算**（PC <2000 draw calls / 移动 <500 / URP 片元 128 指令）；GPU 帧预算分配 | ❌ | B |
| **44. unity-addressables-specialist** | Addressable group / 异步加载 / bundle 优化 | **Bundle 大小约定**（网络 1-10MB / 本地 50MB）；**平台内存预算表**（移动 <512MB / 主机 <2GB / PC <4GB）；地址命名 `[Category]/[Subcategory]/[Name]` | ❌ | B |
| **45. unity-ui-specialist** | UI Toolkit / UGUI / 数据绑定 / 跨平台输入 | UXML `UI_[Screen]_[Element].uxml` / USS `USS_[Theme]_[Scope].uss`；USS 主题变量模板；**性能预算 UI <2ms**；点击目标 48x48dp | ❌ | B |

**共同特征**：4 个**均无 Version Awareness** —— 是 CCGS 的明显缺陷，移植时应补齐。

#### Unreal 子专员组（4 个）

| Agent | 技术领域 | 独有硬性产出格式 | Engine Ver. Safety | 特殊 |
|---|---|---|---|---|
| **46. ue-blueprint-specialist** | BP 架构 / BP-C++ 边界 / BP 优化 | **命名约定表**（BP_/BPI_/BPFL_/E_/S_）；**函数图 ≤20 节点**；**Blueprint Review Checklist 7 条** | ❌ | **⚠️ 唯一禁用 Bash** |
| **47. ue-gas-specialist** | GAS ability/effect/attribute set/tags/tasks | Gameplay Tag 层级命名（`State.Dead` / `Ability.Combat.Slash`）；复制模式选择矩阵（Full/Mixed/Minimal） | ❌ | — |
| **48. ue-replication-specialist** | 属性复制 / RPC / 客户端预测 / relevancy | **复制条件矩阵**（OwnerOnly/SkipOwner/InitialOnly/Custom）；**带宽预算**（动作 <10KB/s，慢节奏 <5KB/s）；RepNotify 命名 `OnRep_[PropertyName]` | ❌ | — |
| **49. ue-umg-specialist** | UMG/CommonUI widget / 数据绑定 / 样式 | Widget 四层（HUD/Menu/Popup/Overlay）；**`SetVisibility(Collapsed)` 优于 Hidden**；UI <2ms；3 主题矩阵（默认/高对比度/色盲） | ❌ | — |

**共同特征**：4 个**均无 Version Awareness**（与 Unity 组相同缺陷）。

---

## 三引擎组横向规律

### 模式 1：完美镜像的组织结构

```
Engine Lead
├── [Language] Specialist      （Godot: GDScript/C#；Unity: DOTS；UE: Blueprint）
├── [Shader/VFX] Specialist   （Godot: shader；Unity: shader；UE: — 无对应）
├── [Asset/Resource] Specialist （Godot: gdextension 含资产 / Unity: addressables / UE: — 无对应）
└── [UI] Specialist            （Godot: — / Unity: UI / UE: UMG）
```

各引擎按其生态特点选择 4 个子专员。**这种"1 Lead + 4 子专员"结构可复制到其他引擎**（Bevy/Love2D/自研）。

### 模式 2：最大的硬性产出价值 = 引擎特异性约束

三引擎组是所有 Tier 3 中**硬性产出格式最密集**的：

| 引擎 | 累计硬性格式/约束数 |
|---|---|
| Godot 组 | **7+ 套**（shader 命名 / GPU 帧预算 / ABI 警告 / 文件章节顺序 / 命名约定表 × 2 / .gdextension 模板 / .csproj 模板等） |
| Unity 组 | **8+ 套**（Bundle 大小 / 内存预算 / 硬性 draw call 上限 / Shader 命名 / UI 命名 / USS 主题变量 / 组件组织 / Burst 禁用类型） |
| UE 组 | **6+ 套**（BP 命名 / 20 节点上限 / 复制条件矩阵 / 带宽预算 / Widget 四层 / Tag 层级） |

**累计三引擎组含 21+ 套硬性格式** —— 这是 CCGS 最精华的"引擎特异知识库"，**与平台无关，可直接迁入 CodeBuddy Rules 或 CODEBUDDY.md**，ROI 极高。

### 模式 3：Version Awareness 覆盖不全是 CCGS 明显缺陷

| 引擎组 | Version Awareness |
|---|---|
| Godot（5 个 agent） | ✅ 全部 |
| Unity（5 个 agent） | ❌ 全部缺失 |
| Unreal（5 个 agent） | ❌ 全部缺失 |

**移植时应补齐** —— 参照 Godot 组的模板，为 Unity 和 UE 组加上 Version Awareness 段落。否则 CodeBuddy 上使用 Unity/UE agent 时容易使用过时 API。

### 模式 4：Task 工具的冗余分布

**Lead 需要 Task** —— spawn 子专员。  
**子专员为什么也有 Task？** —— 从提示词看，子专员不再向下 delegate。Task 工具在子专员层面是**模板继承时的冗余**。

**移植洞察**：CodeBuddy 的 allowed-tools 白名单机制应用时，**子专员可省略 Task 工具**（12 个子专员一律只需 Read/Glob/Grep/Write/Edit/Bash），减少误用风险。

### 模式 5：ue-blueprint-specialist 的独特 disallowedTools

这是 Tier 3 引擎组中**唯一禁用 Bash 的子专员**，反映了 CCGS 对"Blueprint 是引擎内编辑对象、无需 shell 接触"的判断。

**移植到 CodeBuddy 时此模式最清晰**——allowed-tools 反向白名单即可精确还原。

### 模式 6：并行 spawn 设计在三引擎组最密集

每个 Lead 都在提示词中写：
> `"Launch independent sub-specialist tasks in parallel when possible."`

**3 个引擎 Lead × 平均 4 个子专员 = 12 个潜在并行路径**。这是 CCGS 中**最依赖并行能力的部分**。

⚠️ **CodeBuddy 串行模式下的性能影响**：
- Godot 项目：~3 个子专员串行 = 单次特性延迟约 3 倍
- Unity 项目：~4 个子专员串行 = 单次特性延迟约 4 倍
- UE 项目：~4 个子专员串行（GAS 可能一次触发 GAS/Replication/UMG 三者）= 单次延迟约 3-4 倍

**移植建议**：
1. 在极简档和标准档下，**不保留子专员**，所有引擎知识合并到 Lead 提示词
2. 完整档保留子专员结构，但 Lead 改为"按需串行派发"而非默认并行

### 三引擎组适配性小结

| 策略 | Godot 组 | Unity 组 | UE 组 |
|---|---|---|---|
| **极简档**（选 1 引擎） | 仅 1 Lead（4 子专员合并进 Lead） | 同左 | 同左 |
| **标准档** | 1 Lead + 1-2 子专员（按需） | 同左 | 同左 |
| **完整档** | 完整 5 人组 | 完整 5 人组 | 完整 5 人组 |

**注意**：极简档下不可能同时保留三个引擎组——**用户必须选 1 个**。这是所有 Tier 3 中"一定要做减法"的唯一一组。

---

# 02 册总收尾 — 49 个 agent 适配性总表

> 本表汇总 02 册全部 49 个 agent 的移植决策，是 02 册的最终输出。**每一行可直接作为移植时的勾选清单**。

## 列说明

- **形态**：A（Gate 专用，低频 spawn）/ B（执行角色，skill 内 spawn）/ C（不保留独立 md，拆进 Rules）
- **模型**：CCGS 原始模型，移植时可用 CodeBuddy 对应档位
- **档位**：✅ 必保留 / ⚪ 视项目可选 / ❌ 不建议保留

## Tier 1 Directors（3 人 — 全形态 A，极简档全保）

| # | Agent | 形态 | 模型 | 极简 | 标准 | 完整 | 核心改造 |
|---|---|---|---|---|---|---|---|
| 1 | creative-director | A | opus | ✅ | ✅ | ✅ | 6 个 Gate 改为"低频+提示词内嵌" |
| 2 | technical-director | A | opus | ✅ | ✅ | ✅ | 8 个 Gate，TD-ADR 改为批量审查 |
| 3 | producer | A | opus | ⚪ | ✅ | ✅ | Sprint 模板拆进 skill，本 agent 仅做 Gate |

## Tier 2 Leads（8 人 — 主形态 B，部分 A+B 混合）

| # | Agent | 形态 | 模型 | 极简 | 标准 | 完整 | 核心改造 |
|---|---|---|---|---|---|---|---|
| 4 | game-designer | B | sonnet | ✅ | ✅ | ✅ | GDD 8 节放 skill 模板 |
| 5 | lead-programmer | A+B | sonnet | ✅ | ✅ | ✅ | LP-CODE-REVIEW 改为 Sprint 末批量 |
| 6 | art-director | A | sonnet | ⚪ | ✅ | ✅ | AD-PHASE-GATE 与 Tier 1 合并为综合审核 |
| 7 | audio-director | B | sonnet | ⚪ | ✅ | ✅ | 命名约定放 Rules |
| 8 | narrative-director | A+B | sonnet | ⚪ | ✅ | ✅ | ND-CONSISTENCY 改为章节级批量 |
| 9 | qa-lead | A+B | sonnet | ✅ | ✅ | ✅ | QL-STORY-READY 改为 Sprint 规划批量 |
| 10 | release-manager | B | sonnet | ⚪ | ⚪ | ✅ | 6 步流水线放 skill |
| 11 | localization-lead | B | sonnet | ❌ | ⚪ | ✅ | i18n 命名约定放 Rules |

## Tier 3 设计线（3 人 — 全形态 B）

| # | Agent | 形态 | 模型 | 极简 | 标准 | 完整 | 核心改造 |
|---|---|---|---|---|---|---|---|
| 12 | systems-designer | B | sonnet | ⚪ | ✅ | ✅ | Formula 4 字段放 skill；Registry Awareness 升级为 Rule |
| 13 | level-designer | B | sonnet | ⚪ | ✅ | ✅ | Level 9 字段放 skill |
| 14 | economy-designer | B | sonnet | ❌ | ⚪ | ✅ | Reward 3 字段放 skill（条件性） |

## Tier 3 程序线（6 人 — 全形态 B）

| # | Agent | 形态 | 模型 | 极简 | 标准 | 完整 | 核心改造 |
|---|---|---|---|---|---|---|---|
| 15 | gameplay-programmer | B | sonnet | ✅ | ✅ | ✅ | ADR Compliance 升级为 Rule |
| 16 | engine-programmer | B | sonnet | ❌ | ⚪ | ✅ | 零分配规则放 Rule |
| 17 | ai-programmer | B | sonnet | ❌ | ⚪ | ✅ | 2ms 预算 + "fun not optimal" 放 Rule |
| 18 | network-programmer | B | sonnet | ❌ | ❌ | ⚪ | 服务端权威原则放 Rule |
| 19 | tools-programmer | B | sonnet | ❌ | ⚪ | ✅ | 工具设计原则放 CODEBUDDY.md |
| 20 | ui-programmer | B | sonnet | ⚪ | ✅ | ✅ | UI 原则放 Rule |

## Tier 3 美术/音频/叙事线（4 人 — 含 1 个形态 C）

| # | Agent | 形态 | 模型 | 极简 | 标准 | 完整 | 核心改造 |
|---|---|---|---|---|---|---|---|
| 21 | technical-artist | B | sonnet | ❌ | ⚪ | ✅ | 6 类性能预算放 CODEBUDDY.md |
| 22 | sound-designer | **C** | **haiku** | ❌ | ❌ | ⚪ | **不保留 md，SFX 规格表拆进 Rules** |
| 23 | writer | B | sonnet | ❌ | ⚪ | ✅ | 协议修正；5 条写作标准放 Rule |
| 24 | world-builder | B | sonnet | ❌ | ⚪ | ✅ | Lore 5 字段放 skill |

## Tier 3 UX/原型/性能线（3 人 — prototyper 有特殊机制）

| # | Agent | 形态 | 模型 | 极简 | 标准 | 完整 | 核心改造 |
|---|---|---|---|---|---|---|---|
| 25 | ux-designer | B | sonnet | ⚪ | ✅ | ✅ | Accessibility 7 项放 Rule（与 32 合并） |
| 26 | prototyper | B（特殊） | sonnet | ⚪ | ✅ | ✅ | **⚠️ `isolation: worktree` 丢失，需手动代偿** |
| 27 | performance-analyst | B | sonnet | ❌ | ⚪ | ✅ | Report 4 节放 skill；profile-first 戒律放 Rule |

## Tier 3 运维/数据/QA/运营/社区线（7 人 — 含 1 个形态 C）

| # | Agent | 形态 | 模型 | 极简 | 标准 | 完整 | 核心改造 |
|---|---|---|---|---|---|---|---|
| 28 | devops-engineer | B（边缘C） | **haiku** | ❌ | ⚪ | ✅ | 5 类分支策略放 Rule |
| 29 | analytics-engineer | B | sonnet | ❌ | ⚪ | ✅ | 事件命名约定放 Rule；data-informs 戒律 |
| 30 | security-engineer | B | sonnet | ❌ | ⚪ | ✅ | 4 安全域 + 7 项 checklist 放 Rule |
| 31 | qa-tester | B | sonnet | ⚪ | ✅ | ✅ | 3 引擎测试样板放 skill |
| 32 | accessibility-specialist | B（边缘C） | sonnet | ❌ | ⚪ | ✅ | WCAG + 4 类标准 + 8 项 audit 放 Rule |
| 33 | live-ops-designer | B | sonnet | ❌ | ❌ | ⚪ | 7 条道德指南升级为 CODEBUDDY.md 顶层 |
| 34 | community-manager | **C** | **haiku** | ❌ | ❌ | ⚪ | **不保留 md，6 节 patch notes 模板放 skill** |

## Tier 3 三引擎组（15 人 — 用户选 1 套）

**Godot 组（5 人，形态 B）**

| # | Agent | 模型 | 极简 | 标准 | 完整 |
|---|---|---|---|---|---|
| 35 | godot-specialist | sonnet | ⚪ | ✅ | ✅ |
| 38 | godot-gdscript-specialist | sonnet | ❌ | ⚪ | ✅ |
| 39 | godot-csharp-specialist | sonnet | ❌ | ❌ | ⚪ |
| 40 | godot-shader-specialist | sonnet | ❌ | ⚪ | ✅ |
| 41 | godot-gdextension-specialist | sonnet | ❌ | ❌ | ⚪ |

**Unity 组（5 人，形态 B）**

| # | Agent | 模型 | 极简 | 标准 | 完整 |
|---|---|---|---|---|---|
| 36 | unity-specialist | sonnet | ⚪ | ✅ | ✅ |
| 42 | unity-dots-specialist | sonnet | ❌ | ❌ | ⚪ |
| 43 | unity-shader-specialist | sonnet | ❌ | ⚪ | ✅ |
| 44 | unity-addressables-specialist | sonnet | ❌ | ⚪ | ✅ |
| 45 | unity-ui-specialist | sonnet | ❌ | ⚪ | ✅ |

**Unreal 组（5 人，形态 B）**

| # | Agent | 模型 | 极简 | 标准 | 完整 |
|---|---|---|---|---|---|
| 37 | unreal-specialist | sonnet | ⚪ | ✅ | ✅ |
| 46 | ue-blueprint-specialist | sonnet（**禁 Bash**） | ❌ | ⚪ | ✅ |
| 47 | ue-gas-specialist | sonnet | ❌ | ⚪ | ✅ |
| 48 | ue-replication-specialist | sonnet | ❌ | ❌ | ⚪ |
| 49 | ue-umg-specialist | sonnet | ❌ | ⚪ | ✅ |

**三引擎组改造共性**：
1. 子专员并行 spawn → 改为串行（性能降低 3-4 倍）
2. Godot 组的 Version Awareness 建议扩展到 Unity/UE 组（补齐 CCGS 缺陷）
3. 子专员可省略 `Task` 工具（模板继承的冗余）
4. 极简档强制选 1 套引擎，合并 4 个子专员进 Lead

---

## 三档移植最终清单（汇总 49 个 agent）

### 极简档（约 9-10 个独立 agent）

```
Tier 1（3）：creative-director / technical-director / producer(⚪)
Tier 2（3）：game-designer / lead-programmer / qa-lead
Tier 3 通用（2）：gameplay-programmer / qa-tester
Tier 3 引擎（1 Lead）：godot-specialist 或 unity-specialist 或 unreal-specialist
```

### 标准档（约 25-30 个独立 agent）

```
极简档全部 + 以下增补：
Tier 2（+5）：art-director / audio-director / narrative-director / release-manager / localization-lead
Tier 3 通用（+10-12）：systems-designer / level-designer / ui-programmer / technical-artist / writer / world-builder / ux-designer / prototyper / devops-engineer / security-engineer / accessibility-specialist / analytics-engineer
Tier 3 引擎（+2-3 子专员）：选 1 套引擎 + 2-3 个重要子专员（如 godot-gdscript / unity-shader / ue-gas 等）
```

### 完整档（约 42-45 个独立 agent）

```
几乎全部 49 人保留，仅去掉：
- sound-designer（拆 C）
- community-manager（拆 C）
- 另 2 套未选用引擎组（10 个）
```

---

## 02 册横向规律总结（累计所有批次）

### 规律 1：49 人中**仅 2 个**归为形态 C

最终形态分布：
- 形态 A：4 个（creative/technical/producer + art-director）
- 形态 B：43 个
- 形态 C：2 个（sound-designer / community-manager）

**核心洞察**：绝大多数 agent 的提示词内容都有独立复用价值，**精简的关键不在砍 agent 数量，而在"降低调用频率 + 抽离共享协议 + 模板进 skill"**。

> **形态精确分布说明**（与 §93-97 初步预估的对照）：
> 
> | 形态 | 初步预估（§93-97） | 实际（逐份拆解后） | 差异原因 |
> | --- | --- | --- | --- |
> | A | 4 | 4 | 一致 |
> | B | 25-30 | 43 | +13~18，远超预估 |
> | C | 15-20 | 2 | -13~18，远低于预估 |
> 
> 初步预估认为 Tier 3 中大量"haiku + 规范型 + 模板填空"的角色（如 sound-designer / accessibility-specialist / qa-tester / devops-engineer）应归为形态 C（不保留独立 md），但逐份拆解后发现：**绝大多数 specialist 即便用 haiku，也是有具体决策职责（不是纯模板填空），保留独立 md 价值更高**——只有 sound-designer 和 community-manager 真正满足"内容高度模板化 + 协议归属错误 + 可完全靠 skill 模板替代"三个条件。这一发现也支撑了规律 1 的核心洞察（参见 §3373-3378 Tier 3 形态预测的修正过程）。
> 
> 初步预估保留在 §89-97 不动，作为思维过程痕迹；以本节最终结果为准。

### 规律 2：**16+21 = 37 套硬性产出格式**是 CCGS 真正的核心价值

- 通用专员累计 16 套（从 GDD/Sprint/Formula 到 Patch Notes）
- 三引擎组累计 21 套（shader 命名/GPU 预算/Bundle 大小/BP 命名等）

**37 套模板与平台无关，可直接迁入 CodeBuddy skill 模板**——这是 02 册得出的**最高 ROI 移植动作**。

### 规律 3：3 处大型可抽离共享协议 snippet 可省约 1300 行重复

- 设计型 4 步协议：13 个 agent 共用
- 实现型 6 步协议：10 个 agent 共用
- Engine Version Safety：应扩展到全部引擎组（5 → 15）

### 规律 4：CCGS 本身存在的设计瑕疵（移植时正好修复）

| 瑕疵 | 涉及 agent | 移植时如何修复 |
|---|---|---|
| 协议归属错误（实现型/设计型混淆） | sound-designer / writer / community-manager | 抽离为共享 snippet 后自然消失 |
| Version Awareness 不一致 | Unity/UE 组 10 个 agent 缺失 | 扩展 Godot 模板到全部引擎 |
| 模型选择偏重 | accessibility-specialist 等 | 不盲从原模型，按内容重判断 |
| 子专员冗余 Task 工具 | 12 个引擎子专员 | allowed-tools 白名单省略 Task |

### 规律 5：最大的移植损失点 = 3 个

1. **`isolation: worktree`**（prototyper）—— CodeBuddy 无对应
2. **SubagentStart/Stop hook**（log-agent / log-agent-stop）—— CodeBuddy 无对应
3. **并行 spawn**（三引擎组 + team-* skills）—— CodeBuddy 串行模式下时间 3-4 倍

这 3 处将在 05 册"风险清单"重点展开。

---

*02 册完成 ✅ —— 49 个 agent 全部拆解完毕。*

*下一步：03_Skills 全析（72 个 skill）。建议审阅 02 册整体后再继续。*
