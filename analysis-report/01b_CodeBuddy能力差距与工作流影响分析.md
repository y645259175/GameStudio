# 01b — CodeBuddy 能力差距与工作流影响分析

> **本册定位**：这是插在 01（架构总览）与 02（Agents 全析）之间的专项分析册。  
> 01 册告诉你"CCGS 是什么"，01b 册告诉你"移植到 CodeBuddy 后，什么会不一样、哪些流程必须重新设计"。  
> **本册是移植决策最重要的参考依据**，05 册的所有建议均以本册为基础。
>
> **数据来源**：CodeBuddy 官方文档（最后更新：2026-05-08）+ release notes 核实  
> **分析方法**：逐条差距 → 受影响的 CCGS 机制 → 级联影响链 → 重新设计方向

---

## 快速导读

本册识别出 **5 个关键差距**，按影响程度从高到低排列：

| 优先级 | 差距点 | 影响范围 | 影响等级 |
|---|---|---|---|
| P0 | Subagent 并行机制差异 | 所有 team-* skill + Gate 系统 + 效率设计 | 架构级重设计 |
| P1 | Rules 无路径作用域 | 11 条路径规范 + 代码质量防线 | 机制替代 |
| P2 | Memory 无项目级别 | 14 个 specialist agent 的项目记忆 | 机制替代 |
| P3 | Hook 事件缺失（SubagentStart/Stop / PostCompact / Notification） | 审计追踪 + 会话恢复 + 通知 | 局部功能丢失 |
| P4 | 模型无法在 Agent 层声明绑定 | 分层成本控制 + Haiku 轻量场景 | 使用习惯改变 |

---

## 第一章 P0：Subagent 并行机制差异

### 通俗解释

CCGS 的很多工作流是"同时派出多个助手去做不同的事，然后汇总结果"（并行）。CodeBuddy 目前在单次对话内只能"一个接一个地派出助手"（串行）。虽然 CodeBuddy 4.5.0 新增了"多任务并行"（可以同时开多个独立 Agent 任务），但这是用户手动开启的多窗口模式，不是 Skill 内部自动调度的并行。

### 差距详情

| 维度 | CCGS / Claude Code | CodeBuddy 实际 |
|---|---|---|
| **Skill 内并行** | `Task` tool 可在一次 Skill 执行中同时发出多个子 agent 调用，等全部返回后继续 | Subagent agentic 模式：串行调用，一个完成后才能下一个 |
| **多窗口并行** | 不是设计意图（CCGS 是单 session 框架） | 4.5.0 新增：用户可开多个独立 Agents 任务窗口，手动并行 |
| **中途干预** | 用户可随时介入 Task 调用结果 | agentic 模式不支持中途干预，只能等完成或强制中断 |

### 受影响的 CCGS 机制（逐一列举）

#### 1. Director Gates 并行协议（最直接受损）

CCGS 的 `/gate-check` 同时 spawn 4 个总监：
```
并行发出：CD-PHASE-GATE + TD-PHASE-GATE + PR-PHASE-GATE + AD-PHASE-GATE
→ 4个总监同时审核，取最严格结果
→ 理论耗时 = max(4个审核时间) ≈ 1个审核时间
```

改为串行后：
```
CD → 等结果 → TD → 等结果 → PR → 等结果 → AD → 等结果
→ 理论耗时 = sum(4个审核时间) ≈ 4倍时间
```

**影响**：`/gate-check` 从快速质量门控变成耗时的阶段检查。在实际使用中，如果每次 gate-check 要依次等待 4 个总监，用户体验会严重下降，会导致用户倾向于跳过或减少使用。

#### 2. team-* skill 的所有并行 Phase（中等受损）

CCGS 的 9 个 team-* skill 普遍使用并行 spawn 模式。以 `/team-combat` 为例：
- Phase 1：game-designer + art-director **同时**分析设计方向
- Phase 3：gameplay-programmer + technical-artist + sound-designer + ai-programmer **同时**实现各自部分

改为串行后：
- 每个 team-* skill 的执行时间翻倍到 3-4 倍
- 原本"协同感"变为"接力感"，对于复杂功能（如 `/team-narrative` 涉及 writer + world-builder + narrative-director）效率损耗最大

#### 3. `/review-all-gdds` 的并行审查（中等受损）

设计上 Phase 1（一致性检查）和 Phase 2（设计理论审查）独立，同时运行。串行后效率减半。

#### 4. `/brainstorm` 后期的并行总监分析（轻度受损）

brainstorm 后期同时 spawn creative-director + art-director 分析视觉方向和创意支柱，串行后顺序改变但影响可接受。

### 级联影响：工作流必须重新设计的部分

#### 设计原则改变

CCGS 的工作流设计原则是"只要任务相互独立，就并行"，这带来高效率但也带来高 agent 数量。  
**移植后新原则必须是：只有真正不可拆分的子任务才调用 subagent，尽量合并到主 agent 完成。**

#### 哪些 Skill 需要"精简 subagent 调用"

| Skill 类型 | CCGS 的 subagent 数量 | 移植建议 |
|---|---|---|
| `/gate-check` | 4 个并行总监 | 减为 2 个（跳过 AD/PR，仅保 CD+TD）；或将 Gate 内容合并进单个"综合审核 agent" |
| `team-*` 系列（9个） | 3-6 个并行 specialist | 保留 1-2 个最关键的 specialist，其余合并进主 skill prompt |
| `/review-all-gdds` | 2 个并行审查 | 合并为 1 个综合审查 agent |
| `/brainstorm` 后期 | 2 个并行总监 | 合并为 1 个 |

#### "高频 Gate 调用"需要改为"低频里程碑审查"

CCGS 的 Gates 设计为"轻量、高频、内嵌在每个 skill 里"——因为并行执行几乎不增加时间。  
串行后，应该：
- 移除大多数 per-skill 的内联 gate（对应 `lean` 模式的逻辑）
- 只在真正的**阶段边界**（Concept → Systems Design 等）触发综合门控
- 默认评审模式建议从 `lean` 改为接近 `solo`，手动在关键节点调用门控

#### 整体工作流节奏的变化

| 维度 | CCGS 设计 | CodeBuddy 移植后建议 |
|---|---|---|
| Gate 频率 | 每个 skill 内可以有多个 gate | 每个**阶段**只有 1 个综合 gate |
| Team skill 结构 | 3-6 个 agent 并行 Phase | 1-2 个 agent 串行，主 skill 承担更多合并工作 |
| Director 参与 | 总监们高频出现在各 skill 中 | 总监们低频出现，只在阶段门控和重大决策时召唤 |
| 检查力度 | 细粒度（每个 Story、每个 GDD、每个 ADR 都有 gate） | 粗粒度（每个 Epic 或每个阶段一次综合检查） |

### CodeBuddy 的补偿机制（正向信息）

- **Agents 模式多任务并行**（4.5.0+）：用户可以同时开多个独立 Agents 任务。虽然不是 Skill 内自动调度，但可以让用户**手动**把独立的设计任务分到不同窗口并行跑，再汇总结果。这是一个可利用的补偿手段，但需要用户主动配合，不能自动化。
- **Plan 模式**：复杂任务先出 Plan 让用户确认，再自动执行。这实际上把"并行"换成了"更清晰的串行"，适合高质量工作流。

---

## 第二章 P1：Rules 无路径作用域（Glob Pattern）

### 通俗解释

CCGS 的规则像"区域性法规"——写在 `src/gameplay/**` 里的规则只在你修改该目录下的文件时才生效，不会干扰其他目录。  
CodeBuddy 的规则是"全局性法规"——没有路径过滤，一条规则要么总是激活，要么智能体觉得相关时激活，要么手动 `@` 触发。

### 差距详情

| 机制 | CCGS | CodeBuddy |
|---|---|---|
| 路径 glob 激活 | 支持（例：`src/gameplay/**` 仅在改 gameplay 代码时激活） | 不支持 |
| 加载模式 | 文件路径匹配 | 总是 / 智能体请求 / 手动 |
| 规则数量上限 | 不限（按路径分散不影响） | 建议核心规则 3-5 个（总是类），其余按需 |

### 受影响的 CCGS 机制

CCGS 的 11 条路径作用域规则：

| 规则文件 | 作用路径 | 移植影响 |
|---|---|---|
| `gameplay-code.md` | `src/gameplay/**` | 无法自动按路径触发，需改为"手动 @" |
| `engine-code.md` | `src/core/**` | 同上 |
| `ai-code.md` | `src/ai/**` | 同上 |
| `network-code.md` | `src/networking/**` | 同上 |
| `ui-code.md` | `src/ui/**` | 同上 |
| `design-docs.md` | `design/gdd/**` | 同上 |
| `test-standards.md` | `tests/**` | 同上 |
| `prototype-code.md` | `prototypes/**` | 同上 |
| `shader-code.md` | 着色器文件 | 同上 |
| `data-files.md` | 数据配置文件 | 同上 |
| `narrative.md` | 叙事文档 | 同上 |

### 级联影响

**原有质量防线的自动化程度大幅下降**：

CCGS 的设计意图是"AI 在改某个目录的文件时，相关规范自动注入上下文，防止违规"。  
失去路径作用域后，这条防线要靠以下方式替代：

1. **"智能体请求"模式**：规则只加载名称和描述，当 AI 判断相关时自动读取原文。这在实践中不如路径 glob 可靠，AI 不总能正确判断"现在应该读 gameplay-code 规则"。

2. **合并进 CODEBUDDY.md**：把最重要的 3-5 条规则直接写进 CODEBUDDY.md 全局生效。但这会使 CODEBUDDY.md 膨胀，且所有规则都会消耗上下文。

3. **Skill 内嵌入规则引用**：在 `/dev-story` 等代码开发 skill 里，明确要求 AI "在修改 gameplay/ 目录前先读 @gameplay-rules"。把自动化变为显式约定。

**实用建议**：
- 对于**强制性核心规范**（无硬编码数值、公开 API 必须有文档注释等）→ 合并进 CODEBUDDY.md，`alwaysApply: true`，全局生效
- 对于**目录专属规范**（shader 特殊优化要求、networking 安全规范等）→ 改为手动规则，在相关 skill 里写明"进入该目录前请阅读 @rule-name"
- 舍弃"11 条独立规则"的精细分工，合并为 3 条：①代码通用规范 ②设计文档规范 ③测试规范

---

## 第三章 P2：Memory 无项目级别

### 通俗解释

CCGS 允许某些角色（specialist agents）"记住当前项目的技术细节"，跨会话不需要重新介绍项目背景。  
CodeBuddy 只有全局记忆（记住用户个人偏好），没有"只对这个项目生效的记忆"。

### 差距详情

| 类型 | CCGS | CodeBuddy |
|---|---|---|
| `memory: user` | 跨项目，记住用户风格/偏好 | 全局 Memory，相当于 user memory |
| `memory: project` | 跨会话，记住当前项目的技术细节 | **无直接对应** |
| 无 memory 声明 | 只在当前会话有效 | 每次新会话都是空白上下文 |

### 受影响的 CCGS 机制

CCGS 中有 `memory: project` 的 14 个 specialist agents（在 v0.3.0+ 版本中批量添加）：
`art-director / audio-director / economy-designer / game-designer / gameplay-programmer / lead-programmer / level-designer / narrative-director / systems-designer / technical-artist / ui-programmer / ux-designer / world-builder + prototyper`

这些 agent 的"项目记忆"通常包含：引擎版本和配置、项目架构约定、已做的关键技术决策、当前正在做的系统。

### 级联影响

**每次新会话需要"重新介绍项目"**：

在 CCGS 中，`memory: project` 的 agent 在新会话中能记住"上次说的技术栈是 Godot 4.3 + GDScript"。  
在 CodeBuddy 中，每次新会话，这些 agent 都需要重新获取项目背景。

**解决路径**：
1. **CODEBUDDY.md 承担项目背景**：把引擎版本、架构决策、项目状态等写入 CODEBUDDY.md，每次会话自动注入。这是 CodeBuddy 推荐的方式，也是 CCGS 中 `active.md` + `technical-preferences.md` 的功能。

2. **Rules（alwaysApply）替代 project memory**：把项目核心约定写成规则，`alwaysApply: true`，每次会话自动加载。这是最接近 `memory: project` 语义的替代方案。

3. **影响"会话恢复速度"而非功能本身**：project memory 在 CCGS 中主要解决"继续上次工作"的摩擦，而不是承载不可替代的信息。通过 CODEBUDDY.md + Rules 组合，功能上是等价的，只是需要提前维护这些文件的内容。

**实质影响评级**：中等。功能可以被完全替代，代价是需要主动维护 CODEBUDDY.md 和 Rules 的内容质量。

---

## 第四章 P3：Hook 事件缺失

### 差距详情

| CCGS Hook | 对应 CodeBuddy 事件 | 状态 |
|---|---|---|
| `session-start.sh` (SessionStart) | SessionStart | 可映射 |
| `detect-gaps.sh` (SessionStart) | SessionStart | 可映射 |
| `validate-commit.sh` (PreToolUse Bash) | PreToolUse | 可映射 |
| `validate-push.sh` (PreToolUse Bash) | PreToolUse | 可映射 |
| `validate-assets.sh` (PostToolUse Write/Edit) | PostToolUse | 可映射 |
| `validate-skill-change.sh` (PostToolUse Write/Edit) | PostToolUse | 可映射 |
| `pre-compact.sh` (PreCompact) | PreCompact | 可映射 |
| `session-stop.sh` (Stop) | SessionEnd + Stop | 需分拆 |
| `log-agent.sh` (SubagentStart) | **无对应事件** | 不可移植 |
| `log-agent-stop.sh` (SubagentStop) | **无对应事件** | 不可移植 |
| `post-compact.sh` (PostCompact) | **无对应事件** | 不可移植 |
| `notify.sh` (Notification) | **无对应事件** | 不可移植 |

### 级联影响（按 Hook 分析）

#### log-agent.sh / log-agent-stop.sh（SubagentStart/Stop）— 审计追踪功能丢失

CCGS 用这两个 hook 记录每个 subagent 的调用日志，生成 `production/session-logs/` 审计追踪，用于：
- 追溯"这次会话里哪些 agent 被调用了"
- 调试 skill 执行路径
- 统计 agent 使用频率

**移植影响**：审计追踪功能无法自动化。可通过 skill 内主动写日志文件来部分替代，但需要在每个 skill 里手动加"记录调用日志"的步骤，不如 hook 方式透明。

#### post-compact.sh（PostCompact）— 会话恢复提醒丢失

CCGS 在压缩后自动提醒"请读 active.md 恢复状态"。  
**移植影响**：可通过 PreCompact hook（CodeBuddy 支持）提前注入会话状态到压缩指导，在压缩时保存关键信息。PostCompact 的"提醒恢复"行为在 CodeBuddy 中可以通过 `Stop` hook 模拟（每次 Agent 停止响应时检查是否需要提醒）。影响轻微。

#### notify.sh（Notification）— Windows Toast 通知丢失

纯便利性功能，影响极轻。可通过 PreCompact 或 Stop hook 里调用系统通知命令替代。

### 总结：P3 影响可控

7 个 hook 可以直接映射，4 个不可移植。其中真正有功能价值的只有审计追踪（SubagentStart/Stop），但这个功能可以通过在 skill 层手动记录来部分弥补。

---

## 第五章 P4：模型无法在 Agent 层声明绑定

### 通俗解释

CCGS 的 agent 文件里可以写"这个 agent 用 Haiku 模型（省钱、快速）"或"用 Opus（最强、最贵）"。  
CodeBuddy 的 Subagent 目前没有"指定这个 agent 必须用某个模型"的机制；模型在 UI 下拉列表里由用户手动选，或配置 `models.json` 列出可用模型，但 agent 定义文件里控制不了。

### 受影响的 CCGS 机制

CCGS 用 Haiku 的轻量 agent（sound-designer / qa-tester / devops-engineer / community-manager / accessibility-specialist）和轻量 skill（/help / /sprint-status / /project-stage-detect / /changelog / /patch-notes / /onboard / /scope-check / /story-readiness）。  
这些都是"只读、不做复杂判断"的场景，用 Haiku 节省大量成本。

### 级联影响

**成本与分层控制**：  
如果所有 subagent 和 skill 都默认用 Sonnet，原本节省的成本会消失。  
对于重度使用 CCGS 工作流的团队，这可能是使用习惯的重大改变。

**替代方案**：
1. 在 agent 提示词正文里写"本 agent 适合用轻量模型运行"，并在 CODEBUDDY.md 或 Rules 里写明分层使用建议，让用户在触发不同类型 agent 时手动切换模型。
2. 接受"全部用同一模型"的简化，不追求 Haiku/Sonnet/Opus 三档分层。

**实质影响**：功能上无损，成本上可能上升，但对个人开发者影响不大。

---

## 第六章 附加正向差距（CodeBuddy 比 CCGS 强的地方）

这些差距是**对移植工作室有利的**，值得在设计新工作室时主动利用：

| CodeBuddy 能力 | CCGS 缺失 | 利用建议 |
|---|---|---|
| **Plan 模式**（AI 先出计划让用户确认再执行） | Claude Code 无原生 Plan 模式，CCGS 靠协作协议模拟 | 移植工作室应将 Plan 模式作为核心工作流，替代部分 Director Gate 的审核功能 |
| **Automation 定时任务** | CCGS 只有 session 生命周期 hook，无定时任务 | 可以做"每日自动检查项目状态"、"每周生成 sprint 进度报告"等 CCGS 没有的能力 |
| **Agents 模式多任务并行**（4.5.0+） | Claude Code 是单 session 框架 | 用户可以手动并行：一个 Agents 任务写代码，另一个任务做设计文档，结果汇总 |
| **Figma 转代码** | CCGS 无此能力 | 游戏工作室的 UI 工作流可以接入 Figma，大幅提升 UI 开发效率 |
| **CODEBUDDY.md 自动加载**（全局上下文） | CCGS 的 CLAUDE.md 功能类似，但 @ 引用机制不同 | 可以把整个工作室的核心约定放在 CODEBUDDY.md，始终有效 |
| **Skills 的 references/ 目录**（按需加载文档） | CCGS 的 skill 只有单个 SKILL.md | 游戏开发的大量参考文档（引擎 API、设计理论）可以放进 references/，只在需要时加载，节省 token |
| **MCP 集成** | CCGS 无 MCP | 可以接入版本管理、项目追踪、数据库等工具，扩展工作室能力 |

---

## 第七章 综合影响：移植后的工作室画像

### 必须放弃的设计

1. **自动并行 Gate 系统**（4 总监并行）→ 改为手动触发的综合门控
2. **高频内联 Gate**（每个 skill 内嵌 gate）→ 改为低频里程碑 gate
3. **团队 skill 的多 agent 并行 phase**（team-combat / team-narrative 等）→ 改为主 skill 承担更多，少用 subagent
4. **路径 glob 自动规范注入**→ 改为显式约定 + 手动 @rule

### 必须重新设计的工作流

| 原始工作流 | 受损原因 | 重新设计方向 |
|---|---|---|
| `/gate-check` | 4 并行总监 → 串行 | 单一"综合阶段评审" Subagent + Plan 模式做评审 |
| 所有 `team-*` skill | 并行 phase → 串行 | 精简为 1-2 个 specialist + 主 skill 合并输出，或利用多任务并行窗口 |
| `review-all-gdds` | 2 并行分析 → 串行 | 合并为 1 个综合 GDD 审查 skill |
| per-story LP-CODE-REVIEW | 每个 story 都有 Gate → 频率太高 | 每个 Sprint 末做一次批量代码审查 |
| per-ADR TD-ADR gate | 每个 ADR 都有 Gate → 频率太高 | 阶段末综合 ADR 审查 |

### 可以保留的核心价值（无损移植）

1. **五步协作协议**（Ask → Options → Decision → Draft → Approval）——最重要的，原样保留
2. **49 个角色的分工体系**——提示词内容直接移植，调整 memory 策略
3. **72 个 skill 的工作流逻辑**——流程步骤可移植，去掉/合并并行 subagent 调用
4. **7 阶段 Pipeline 的文件约定**——产出文件格式、目录结构可原样保留
5. **7 个 Hook 的校验逻辑**——脚本内容可复用，格式几乎不变
6. **Director Gates 的提示词文本**——所有门控的 prompt 可直接复用，只是触发方式改变
7. **CODEBUDDY.md 主入口**（原 CLAUDE.md）——直接改名，内容基本可用
8. **编码/设计/测试规范文本**——原样移植进 Rules 或 CODEBUDDY.md

### 移植后工作室的能力定位

从"高度自动化的 AI 工作室模拟器"（49 agent 并行协作）  
→ "高质量辅助开发的 AI 工作台"（核心角色串行、Plan 模式主导、关键节点人工触发评审）

这不是降级，而是**适配串行模式下的最优解**：
- 减少"AI 之间互相 review 的开销"
- 增加"Plan 模式让用户全程参与"
- 利用 CodeBuddy 特有的 Automation 和 Agents 多任务弥补并行缺失

---

## 章末：差距影响速查表

> 后续 02/03/04 册中每个条目的适配评估，均以本章的影响分析为基础。

| 差距 | 受影响条目数量 | 可补救程度 | 关键改造动作 |
|---|---|---|---|
| P0 并行 subagent | 9 个 team-* + gate-check + review-all-gdds + brainstorm + create-architecture + ux-review + design-system 等 ≈ 15-18 个 skill 涉及多 agent spawn | 可补救，但需要重新设计 | 精简 subagent 数量；默认 lean/solo 模式；利用多任务并行窗口 |
| P1 Rule 路径 glob | 11 条规则 | 可补救，功能不损失 | 合并为 3 条全局规则 + 手动规则 |
| P2 project memory | 14 个 specialist agent | 可补救，需维护 CODEBUDDY.md | 用 CODEBUDDY.md + alwaysApply Rules 替代 |
| P3 Hook 事件缺失 | 4 个 hook | 部分不可补救（审计追踪） | 在 skill 层手动记录日志 |
| P4 模型绑定 | 8 个轻量 skill + 5 个轻量 agent | 功能无损，成本可能上升 | 提示词注明建议模型，用户手动切换 |

---

## 第八章 移植后规模对比（直观看到精简幅度）

> 这张表帮助你直观感受"移植后到底剩多少东西可用"。注意：精简不等于功能减少，而是把 49 个角色的并行协作合并为更少角色的串行协作，工作覆盖范围基本不变。

| 资产类别 | CCGS 原始数量 | 移植后建议数量 | 精简比例 | 主要精简动作 |
|---|---|---|---|---|
| Agents（角色） | 49 | 20-30（取决于是否保留全部三引擎专员组） | 约 40-60% | 引擎专员组按选择留 1 套（+5）；合并部分子专员；轻量 agent 合并 |
| Skills（斜杠命令） | 72 | 25-40 | 约 45-65% | 9 个 team-* 简化为 3-5 个；analysis 类合并；utility 类按需 |
| Hooks | 12 | 7（CodeBuddy 支持的事件） | 约 40% | log-agent / log-agent-stop / post-compact / notify 不可移植 |
| Rules | 11 | 3-5 | 约 60-70% | 11 条路径规则合并为通用编码规范 + 设计文档规范 + 测试规范 |
| Templates | 39 | 30+ | 约 20% | 模板纯文本，几乎无需精简 |
| Director Gates | 17 | 6-8 | 约 50% | 4 个 PHASE-GATE 合并为 1-2 个综合阶段评审；per-skill 内联 gate 大量减少 |

**总体规模**：从 49+72+12+11 ≈ 144 个核心资产 → 约 60-80 个核心资产，**减幅约 45%**。

---

## 第九章 决策影响树（按你的取向选移植策略）

> 不同的开发风格和团队规模，对差距的容忍度不同。这张树帮助你快速定位适合自己的移植深度。

```
你最看重什么？
│
├── 极速产出（Game Jam / 1人团队 / 周末项目）
│   推荐策略：极简移植（MVS）
│   ├── 移植 5-8 个核心 agent（user / creative-director / lead-programmer / qa-lead + 1 个引擎专员）
│   ├── 移植 10-15 个核心 skill（start / brainstorm / design-system / dev-story / story-done 等）
│   ├── 移植 3-4 个 hook（session-start / validate-commit / pre-compact / session-stop）
│   ├── 默认 review-mode = solo
│   └── 接受：无 Gate / 无 Director / 全靠用户判断
│
├── 平衡效率与质量（独立开发者 / 2-3 人小团队 / 中长期项目）
│   推荐策略：标准移植
│   ├── 移植 25-30 个 agent（含 4 个 Director、6 个 Lead、若干 Specialist + 1 套引擎专员组）
│   ├── 移植 30-40 个 skill（保留主流程 + team-* 合并版 + 关键 review/QA skill）
│   ├── 移植 7 个 hook（CodeBuddy 全部支持的事件）
│   ├── 默认 review-mode = lean，关键阶段切到 full
│   └── 接受：Gate 串行执行（耐心等）/ team-* 简化为单 agent
│
└── 最大严谨度（多人协作 / 商业项目 / 重要代码）
    推荐策略：完整移植
    ├── 移植 40+ agent（仅删 1 个引擎组的子专员，保留所有通用专员）
    ├── 移植 50+ skill（全套，team-* 仅 phase 内合并）
    ├── 移植 7 个 hook + skill 内手动审计
    ├── 默认 review-mode = full
    └── 接受：流程偏慢（适合"慢工出细活"场景）/ 用户需主动维护 CODEBUDDY.md
```

### 三种策略的取舍对比

| 维度 | 极简移植 | 标准移植 | 完整移植 |
|---|---|---|---|
| 单次 Skill 平均耗时 | 短（无 subagent） | 中（少量串行 subagent） | 长（多次串行 spawn） |
| Token 消耗 | 低 | 中 | 高 |
| 用户认知负担 | 低（命令少） | 中 | 高（命令多） |
| 输出质量保证 | 主要靠用户 | Gate + 用户 | Gate + Director + 用户 |
| 适合的项目阶段 | 探索 / 原型 | MVP / 量产 | 后期打磨 / 商业发布 |
| CODEBUDDY.md 维护成本 | 低 | 中 | 高 |

### 默认推荐

如果你不知道选哪个，**先用极简移植起步**。等工作流跑顺、形成肌肉记忆后，再按需要把单个 skill/agent 逐步加进来——比从完整版开始砍要容易得多。

---

## 第十章 Agent 移植 3 类形态（全报告统一框架）

> 这是从 01b 差距分析推导出的**关键设计原则**，在 02 册详细应用，并作为 05 册移植建议的归类依据。

### 核心洞察

CodeBuddy 不支持 skill 内并行 spawn subagent，但**每个 agent 的"提示词内容"和"调用方式"是可以分开处理的两件事**：
- 提示词内容（职责、决策框架、输出模板）—— 大多有独立复用价值
- 调用方式（何时 spawn、被谁 spawn）—— 必须适配 CodeBuddy 的串行限制

### 3 类形态定义

| 形态 | 特征 | 移植处理 | 典型代表 |
|---|---|---|---|
| **A — Gate 专用角色** | 提供战略/审查视角，原本跨多 skill 频繁 spawn | 保留独立 md，**大幅降低 spawn 频率**（只在阶段 Gate + 手动咨询时 spawn），其余场景在 skill 里**内嵌决策框架片段** | 4 个 Director 级角色（CD/TD/PR/AD） |
| **B — 执行角色** | 完成具体产出（写代码/文档/对话/测试） | 保留独立 md，skill 内串行 spawn（接受单次延迟） | 大多数 Tier 2 Lead + Tier 3 执行型专员 |
| **C — 参考角色** | 职责窄、规范型，独立 spawn 价值低 | **不保留独立 md**，提示词拆进 Rules/CODEBUDDY.md | 轻量 Haiku 型专员（sound-designer/accessibility-specialist 等） |

### 判断流程

```
这个 agent 的提示词内容有独立复用价值吗？
│
├── 否 → 跳过（极少见）
│
└── 是 → 它产出的主要是"审查意见"还是"具体产物"？
    │
    ├── 规范/参考（主要给别人用） → 形态 C（拆进 Rules）
    │
    ├── 审查意见（APPROVE/REJECT） → 形态 A（Gate 专用，低频 spawn）
    │
    └── 具体产物（代码/文档/对话） → 形态 B（skill 内串行 spawn）
```

### 形态分布预估（49 个 agent）

| 形态 | 数量估计 | 占比 |
|---|---|---|
| 形态 A（Gate 专用） | 4 | 约 8% |
| 形态 B（执行角色） | 25-30 | 约 55% |
| 形态 C（参考角色） | 15-20 | 约 35% |

精确归类在 02 册逐份拆解时确定。

### 为什么这个框架重要

传统的"移植 / 不移植"二元判断会导致两个极端：要么全部保留（每次 spawn 都卡顿），要么大量删减（丢失提示词价值）。  
**3 类形态框架提供了中间路径**：保留所有有价值的提示词内容，但调整调用方式以适配 CodeBuddy 的串行模式。

这个思路也是 01b 第七章"必须重新设计的工作流"的具体落地方案——不是简单地删掉高频调用的 agent，而是把它们**从"自动 spawn"转为"提示词内嵌 + 关键点 spawn"**。

---

*01b 册完成。阅读建议：在读 02/03/04 册时，每个条目的适配评级均参照本册的差距分析。05 册的移植建议将基于这三种策略给出具体的资产清单。*
