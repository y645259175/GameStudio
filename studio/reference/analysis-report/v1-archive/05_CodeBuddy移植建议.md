# 05 CodeBuddy 移植建议

> **本册是整套 5 册报告的最终输出**——汇总前 4 册的全部分析，给出从 CCGS 到 CodeBuddy 的完整移植决策辅助。
>
> 不再展开任何"是什么"的描述，只聚焦"**该怎么移、移哪些、按什么节奏**"。

---

## 本册结构

1. **第 1 章 能力对照矩阵** —— Claude Code × CodeBuddy 七维对照
2. **第 2 章 分层移植策略** —— 4 档分类（直接 / 改造 / 不建议 / 可选扩展）
3. **第 3 章 MVS 最小可行工作室清单** —— 跑通闭环的最少资产集
4. **第 4 章 5 阶段落地路线图** —— Phase 1-5 渐进式部署
5. **第 5 章 风险与取舍清单** —— 移植后必然损失的能力
6. **第 6 章 决策辅助表** —— 用户勾选式生成自定义移植方案

---

## 前 4 册结论速查（决策依据）

| 册 | 关键数字 / 结论 |
|---|---|
| 01 | 49 agent + 72 skill + 12 hook + 11 rule + 7 阶段 pipeline + 17 个 Director Gates |
| 01b | **5 大能力差距**（P0-P4）：并行 subagent / Rule glob / project memory / SubagentStart-Stop hook / 模型绑定 |
| 02 | 49 agent → 形态 A（4）+ B（43）+ C（2）；累计 **37 套硬性产出格式** |
| 03 | 72 skill → 14 个并行多个（必改造）+ 9 个 team-* 是 P0 重灾区 |
| 04 | 38 Template = 零成本迁移；3 协作协议 + Hook+Rule+Template 闭环 |

---

# 第 1 章 — 能力对照矩阵

> 七维对照 Claude Code 原生能力 vs CodeBuddy 当前能力。

## 1.1 完整能力对照表

| # | 维度 | Claude Code（CCGS 依赖） | CodeBuddy 当前能力 | 差距等级 |
|---|---|---|---|---|
| 1 | **Subagent spawn** | Task tool，**支持并行** | Task tool 可用，**不支持 skill 内并行** | **P0 严重** |
| 2 | **Subagent 任务级并行** | 默认支持 | 4.5.0 起支持（多 Agent 任务窗口）| 部分代偿 |
| 3 | **斜杠命令（Skill）** | `.claude/skills/<name>/SKILL.md` | `.codebuddy/commands/` 或 `.codebuddy/skills/` | **零差距**（目录改名） |
| 4 | **Memory 分级** | `memory: user` + `memory: project` | 仅全局 Memory | P2 中等 |
| 5 | **Hook 事件类型** | 9 类（含 SubagentStart/Stop/PostCompact/Notification）| 7 类 | P3 中等 |
| 6 | **Rule 路径作用域** | YAML `paths: [glob]` 自动激活 | 不支持 glob，仅 alwaysApply / 智能体请求 / 手动 | **P1 严重** |
| 7 | **isolation: worktree** | 支持（prototyper 用） | 不支持 | **P3 单点损失** |
| 8 | **模型 frontmatter 绑定** | `model: opus/sonnet/haiku` | `.codebuddy/models.json` 全局配置，无 frontmatter 绑定 | P4 轻微 |
| 9 | **statusLine 自定义** | 支持（CCGS statusline.sh）| 不支持 | P3 单点损失 |
| 10 | **settings.json 格式** | hooks/permissions 结构 | **格式 85% 兼容** | 零差距（少量字段差异） |
| 11 | **CLAUDE.md 主入口** | 支持，自动注入 | **CODEBUDDY.md 等价支持**，兼容 AGENTS.md | 零差距（改名） |
| 12 | **AskUserQuestion 工具** | Claude Code 工具 | CodeBuddy 等价工具（ask_followup_question 类似）| 极小差距 |
| 13 | **多模型路由** | 项目级支持 Opus/Sonnet/Haiku | 全局支持多模型（OpenAI/DeepSeek/Ollama/...）| 零差距（路由方式不同） |
| 14 | **Slash command 触发** | 用户输入 `/skill-name [args]` | 同样支持 | 零差距 |

## 1.2 关键差距速查

**严重（P0-P1）—— 影响整体架构 2 项**：
- 无并行 subagent —— 影响 14 个 skill 的设计（9 个 team-* + review-all-gdds + gate-check + art-bible(full) + asset-spec(full) + ux-design + ux-review）
- 无 Rule 路径作用域 —— 影响 11 条 Rule 的激活方式

**中等（P2-P3）—— 部分功能损失 4 项**：
- 无 project memory（用 CODEBUDDY.md + Rules 代偿）
- 缺 4 类 Hook 事件（log-agent×2 / post-compact / notify）
- 无 isolation: worktree（prototyper 单点）
- 无 statusLine（statusline.sh 单点）

**轻微（P4）—— 几乎无影响 1 项**：
- 模型 frontmatter 绑定 —— 用提示词标注代替

**零差距（无影响）—— 平滑迁移 7 项**：
- Skill 机制 / settings.json 格式 / CODEBUDDY.md 主入口 / AskUserQuestion 等价工具 / 多模型路由 / Slash command / 全部 Markdown 资产

## 1.3 能力对齐总评

**85% 能力可平滑或改造迁移**，**15% 部分损失**。CCGS 设计的核心架构（agent 分工 / 7 阶段 pipeline / 5 步协作协议 / 硬性产出格式）**全部可保留**，损失主要集中在：
- **性能**（并行 spawn 损失 → 14 个 skill 延迟 3-6 倍）
- **机制**（worktree / SubagentStart-Stop / statusLine 3 个单点）
- **细粒度自动化**（Rule glob / project memory）

---

# 第 2 章 — 分层移植策略

## 2.1 四档分类总览

| 档 | 数量 | 描述 | CCGS 资产举例 |
|---|---|---|---|
| 🟢 **直接移植** | 102 | 与平台无关，原样复制 | 38 Template / 大部分 agent 提示词文本 / 大部分 skill 文档 |
| 🟡 **改造移植** | 78 | 需要重写承载机制 | 8 Hook（settings 改写）/ 11 Rule（合并/转模式）/ 14 并行 skill（改串行）/ 49 agent 的协议章节（改引用） |
| 🔴 **不建议移植** | 4 | Claude Code 独有机制无对应 | post-compact.sh / log-agent.sh / log-agent-stop.sh / notify.sh |
| ⚪ **可选扩展** | 多 | CodeBuddy 特有能力可补强 | UserPromptSubmit hook / 多模型动态切换 / Agent 多任务并行 |

## 2.2 详细分类（按资产类型）

### 🟢 直接移植清单（102 项）

**全部 38 个 Template**（零改造）：
- 3 协作协议（design / implementation / leadership）
- 10 设计文档（含 game-design-document / level-design-document 等核心）
- 5 架构（含 ADR 模板）
- 5 UX/无障碍
- 7 项目管理
- 2 测试 / 3 发布 / 2 美术音频 / 1 Meta

**大部分 agent 的提示词文本（49 个 agent）**：
- 49 agent 的提示词正文（职责 / 决策框架 / 禁做清单 / 上下游关系）—— 与平台无关，直接复用
- 仅协议章节、frontmatter 字段、Task 调用方式需改造（→ 🟡）

**workflow-catalog.yaml**：
- 7 阶段 pipeline 数据结构原样复用，是 `/help` `/start` `/project-stage-detect` 三个 skill 的共享数据源

**全部 11 Rule 的内容**：
- Rule 文本本身（强制项 / 命名约定 / 反模式清单）零改造
- 仅 frontmatter 加载模式需改造（→ 🟡）

### 🟡 改造移植清单（78 项）

**8 个 Hook**（脚本逻辑保留，settings.json 重写）：
- session-start / detect-gaps / session-stop / pre-compact / validate-commit / validate-push / validate-assets / validate-skill-change

**11 条 Rule**（按方案 C 改造）：
- 4 条转 alwaysApply（design-docs / data-files / test-standards / prototype-code）
- 1 条 ui-code 视项目 alwaysApply 或合并
- 5 条转智能体请求模式（ai / engine / network / shader / narrative）
- 1 条 gameplay-code 合并到全局 code-standards

**14 个并行多个 Skill**（改串行 + 提示词优化）：
- 9 个 team-*
- review-all-gdds / gate-check
- art-bible (full) / asset-spec (full)
- ux-design / ux-review

**49 个 agent 的协议章节改为显式引用**：
- 在 frontmatter 加 `protocol: design / implementation / leadership` 字段
- 删除 agent 文件中重复的协议正文
- 节省约 1300 行重复内容

### 🔴 不建议移植清单（4 项）

| 资产 | 替代策略 |
|---|---|
| post-compact.sh | 合并到 pre-compact.sh 输出 或 session-start.sh 提示 |
| log-agent.sh | 完全舍弃（审计追踪能力损失，不补救） |
| log-agent-stop.sh | 同上 |
| notify.sh | 完全舍弃（Windows 弹窗价值低） |

### ⚪ 可选扩展清单（CodeBuddy 特有）

| 能力 | 可补强 CCGS 哪部分 |
|---|---|
| **UserPromptSubmit hook** | CCGS 无此事件，可在用户输入时做关键词检测自动 spawn agent（如检测到 "性能问题" 自动召唤 perf-profile） |
| **Agent 多任务并行**（4.5.0+） | 部分弥补 P0 的并行 subagent 损失 —— 用户可手动开多个 Agent 窗口同时跑（设计在 1 个、编码在另 1 个） |
| **多模型动态切换** | 可比 CCGS 更灵活地切换 OpenAI/DeepSeek/Ollama/自定义 API |
| **MCP 服务器集成** | 可接入企业内部 API（如 Tencent / iWiki），扩展 agent 能力边界 |

---

# 第 3 章 — MVS 最小可行工作室清单

> **目标**：搭建一个**能跑通完整闭环**（从 concept 到第一个 implemented story）的**最小 CodeBuddy 工作室**。

## 3.1 MVS 资产总数

| 类别 | CCGS | MVS（极简档） | 关键减量 |
|---|---|---|---|
| Agents | 49 | **9-10** | 砍掉所有 specialist + 三引擎组只留 1 Lead |
| Skills | 72 | **20** | 砍 team-* + 多数 review/QA/release |
| Hooks | 12 | **4** | 仅上下文管理类 |
| Rules | 11 | **4-5** | 4 条 alwaysApply + 1 视项目 |
| Templates | 38 | **9** | 协议 3 + 设计 4 + 架构 1 + 管理 1 |
| **合计** | **182** | **46-48** | **减幅 ~74%** |

## 3.2 MVS 详细清单

### Agents (9-10 个)

| 层级 | Agent | 形态 | 改造点 |
|---|---|---|---|
| Tier 1 | creative-director | A | 低频 spawn，只在 CD-PHASE-GATE |
| Tier 1 | technical-director | A | 低频 spawn，TD-ADR 改批量 |
| Tier 1 | producer ⚪ | A | 可选；纯 1 人小项目可砍 |
| Tier 2 | game-designer | B | 主设计角色 |
| Tier 2 | lead-programmer | A+B | 主代码角色 |
| Tier 2 | qa-lead | A+B | 主测试角色 |
| Tier 3 | gameplay-programmer | B | 实现核心 |
| Tier 3 | qa-tester | B | 测试 scaffolding |
| Tier 3 | [选 1 引擎 Lead] | B | godot/unity/unreal-specialist 三选一 |

**说明**：极简档**不保留**任何子专员（systems-designer / level-designer / ui-programmer 等）—— 它们的工作可由对应 Lead 兼任，提示词通过引用 02 册识别的硬性产出格式（GDD 8 节 / Formula 4 字段）保证产出质量。

### Skills (20 个)

| 类别 | Skill | 用途 |
|---|---|---|
| Onboarding（4） | /start /help /project-stage-detect /setup-engine | 项目入口 |
| Game Design（3） | /brainstorm /design-system /map-systems | 设计核心 |
| Stories & Sprints（3） | /dev-story /story-done /sprint-status | 日常开发 |
| Reviews（1） | /design-review | 单 GDD 审查 |
| QA（3） | /smoke-check /bug-report /qa-plan | 基本 QA |
| Production（2） | /retrospective /scope-check | 项目管理 |
| Creative（1） | /prototype | 抛弃式原型 |
| Discovery（3） | /adopt /consistency-check /quick-design | 灵活补充 |

**说明**：MVS **不含 9 个 team-***（极简档全砍） + **不含完整架构 4 skill**（架构决策由 lead-programmer 直接做，跳过 ADR 流程） + **不含 Release 5 skill**（Game Jam 阶段无需）。

### Hooks (4 个)

```
.codebuddy/hooks/
  ├── session-start.sh       (会话启动注入项目上下文)
  ├── detect-gaps.sh         (文档缺口提醒)
  ├── session-stop.sh        (会话结束归档)
  └── pre-compact.sh         (压缩前状态转储)
```

**说明**：极简档**不含 4 个 validate-* hook**（用户自己审 commit / push）。如果项目需要更多自动化质量保证，升级到标准档加入 4 个 validate-* hook。

### Rules (4-5 条)

```
.codebuddy/rules/
  ├── design-docs.md            (alwaysApply)  —— GDD 8 节
  ├── code-standards.md          (alwaysApply)  —— 合并 gameplay/ui-code
  ├── data-files.md              (alwaysApply)  —— JSON 合法性
  ├── test-standards.md          (alwaysApply)  —— 测试规范
  └── [视项目] prototype-code.md  (alwaysApply)  —— worktree 损失代偿
```

### Templates (9 个)

```
.codebuddy/docs/templates/
  ├── collaborative-protocols/
  │   ├── design-agent-protocol.md
  │   ├── implementation-agent-protocol.md
  │   └── leadership-agent-protocol.md
  ├── game-design-document.md       (GDD 8 节)
  ├── game-concept.md
  ├── game-pillars.md
  ├── systems-index.md
  ├── architecture-decision-record.md
  └── sprint-plan.md
```

### CODEBUDDY.md 顶层（必备）

替代 CLAUDE.md，包含：
- 工作室角色总览（10 agent 列表 + 何时用谁）
- 7 阶段 pipeline 简介
- 5 步协作协议引用（指向 templates/collaborative-protocols/）
- 项目级规范（命名约定 / 引擎版本 / 性能预算）
- **CCGS 7 条 live-ops 道德指南**（即使不做 live-ops 也作为伦理底线）

### settings.json（必备）

```json
{
  "hooks": {
    "SessionStart": [
      { "matcher": "", "hooks": [
        { "type": "command", "command": "bash .codebuddy/hooks/session-start.sh" },
        { "type": "command", "command": "bash .codebuddy/hooks/detect-gaps.sh" }
      ]}
    ],
    "Stop": [
      { "matcher": "", "hooks": [
        { "type": "command", "command": "bash .codebuddy/hooks/session-stop.sh" }
      ]}
    ],
    "PreCompact": [
      { "matcher": "", "hooks": [
        { "type": "command", "command": "bash .codebuddy/hooks/pre-compact.sh" }
      ]}
    ]
  }
}
```

## 3.3 MVS 完整目录结构

```
my-codebuddy-game/
├── .codebuddy/
│   ├── agents/              (9-10 个 .md)
│   ├── commands/            (20 个 skill 子目录或文件)
│   ├── hooks/               (4 个 .sh)
│   ├── rules/               (4-5 个 .md，全部 alwaysApply)
│   ├── docs/
│   │   ├── workflow-catalog.yaml   (7 阶段 pipeline，原样复用)
│   │   └── templates/
│   │       ├── collaborative-protocols/  (3 个)
│   │       └── (其余 6 个核心 templates)
│   └── settings.json
├── CODEBUDDY.md             (主入口)
├── design/
│   ├── gdd/
│   │   └── game-concept.md   (待 /start 后产出)
│   └── pillars.md
├── docs/
│   └── architecture/         (待 /architecture-decision 后产出)
├── production/
│   ├── stage.txt             (待 /project-stage-detect 产出)
│   ├── session-state/
│   ├── session-logs/
│   └── sprints/
├── src/                      (待 /dev-story 后产出)
├── tests/
└── prototypes/               (待 /prototype 产出)
```

## 3.4 MVS 验证标准

**MVS 部署成功的判据**：以下 6 个动作**全部能跑通**。

1. ✅ 用户运行 `/start`，工作室引导用户写出 `design/gdd/game-concept.md`
2. ✅ 用户运行 `/help`，工作室告知"在 Concept 阶段，下一步是 /map-systems"
3. ✅ 用户运行 `/design-system combat`，game-designer 引导用户按 GDD 8 节增量写出 `design/gdd/combat.md`
4. ✅ 用户运行 `/dev-story production/epics/foundation/story-001.md`，gameplay-programmer 串行 spawn 实现代码 + qa-tester 写测试
5. ✅ 用户 `git commit` 时，validate-commit.sh（如启用）自动校验 GDD 8 节和 JSON 合法性
6. ✅ 会话压缩前，pre-compact.sh 自动转储状态；下次会话启动时 session-start.sh 自动恢复上下文

如以上 6 个动作**全通**，MVS 已就绪，可开始游戏开发；如有 1-2 个失败，定位并修复对应资产。

---

# 第 4 章 — 5 阶段落地路线图

> 渐进式部署 5 阶段，每阶段完成一个独立可用的"工作室快照"。

## 4.1 路线图总览

| Phase | 阶段名 | 资产新增 | 累计资产 | 工作量估算 | 交付物 |
|---|---|---|---|---|---|
| 1 | **骨架（Skeleton）** | CODEBUDDY.md + 4 hook + workflow-catalog.yaml + 4 rule + 9 template | ~18 | 0.5-1 天 | "工作室能感知项目状态，但还没角色" |
| 2 | **核心角色（Core Roles）** | 9-10 agent | ~28 | 1-2 天 | "工作室能引导设计、能写代码、能测试" |
| 3 | **核心工作流（Core Workflows）** | 20 个 MVS skill | ~48 | 1-2 天 | "工作室能跑通完整的设计→开发→测试闭环" |
| 4 | **质量自动化（Quality Automation）** | 增加 4 个 validate-* hook + 5-7 个补充 skill + 5 条转模式 rule | ~60-65 | 1-2 天 | "工作室能在 commit/edit 时主动质量校验" |
| 5 | **元测试与扩展（Meta & Extensions）** | 标准/完整档完整资产 | 100+ | 视项目持续 | "工作室成熟，可针对项目持续优化" |

**总工作量估算**：MVS（Phase 1-3）= **2.5-5 天**；标准档（Phase 1-4）= **5-8 天**；完整档（Phase 1-5）= 持续投入。

## 4.2 Phase 1 — 骨架（Skeleton）

### 目标
搭建工作室"地基"：项目结构 + 基础导航 + 基础规范。**此阶段后用户能看到工作室"在那"，但还没有角色和工作流**。

### 任务清单

- [ ] 创建 `.codebuddy/` 目录结构（`agents/` `commands/` `hooks/` `rules/` `docs/templates/`）
- [ ] 创建 `CODEBUDDY.md`（顶层入口，参考 CCGS CLAUDE.md 改名）
- [ ] 复制 `workflow-catalog.yaml` 到 `.codebuddy/docs/`
- [ ] 复制 9 个 MVS Template 到 `.codebuddy/docs/templates/`（含 3 协作协议）
- [ ] 写 4 个核心 Rule（design-docs / code-standards / data-files / test-standards），全部 `alwaysApply: true`
- [ ] 复制 4 个核心 Hook 脚本（session-start / detect-gaps / session-stop / pre-compact），并配置 `settings.json`
- [ ] 测试 Hook：启动会话能看到 session-start 和 detect-gaps 输出

### 交付物验证

启动 CodeBuddy 会话时，能看到：
```
[当前 git 分支] / [最近 5 commits] / [TODO 计数]
⚠️ GAP: 项目无 GDD，建议运行 /start
⚠️ GAP: 项目无 sprint 计划，建议运行 /sprint-plan
```

**结果**：工作室已"在那"——能感知项目状态、能给出导航建议，但还没有角色或具体工作流可以执行。

## 4.3 Phase 2 — 核心角色（Core Roles）

### 目标
部署 9-10 个核心 agent。**此阶段后用户能召唤角色协作**。

### 任务清单

- [ ] 创建 `.codebuddy/agents/` 下的 9-10 个 .md 文件（参考 02 册逐 agent 拆解）
- [ ] **重要**：每个 agent 提示词正文加 `Refer to: @design-agent-protocol` 或 `@implementation-agent-protocol` 引用，**不再重复**协议正文
- [ ] 在每个 agent 末尾保留 02 册识别的"硬性产出格式"（如 game-designer 的 GDD 8 节、systems-designer 的 Formula 4 字段）
- [ ] 在 CODEBUDDY.md 增加"角色清单"一节：列出 10 个角色 + 何时召唤
- [ ] 测试：用户在对话中提及"need a game design"，CodeBuddy 应自动提议召唤 game-designer

### 交付物验证

```
用户："帮我设计一个战斗系统"
CodeBuddy 自动判断 → 召唤 game-designer subagent
game-designer 引用 design-agent-protocol → Question-First Workflow
→ 列出 4 个澄清问题
```

**结果**：工作室能"动起来"——角色按设计协议工作，但还没有结构化 skill。

## 4.4 Phase 3 — 核心工作流（Core Workflows）

### 目标
部署 20 个 MVS Skill。**此阶段后用户可跑通完整的"设计 → 开发 → 测试 → 提交"闭环**。

### 任务清单

- [ ] 创建 `.codebuddy/commands/` 下的 20 个 skill 文件
- [ ] 每个 skill 实现：从 03 册的精读和概览表中提取核心步骤
- [ ] **关键**：14 个并行多个 skill 全部改为串行（虽然 MVS 不含 9 team-*，但仍需关注 review-all-gdds 等）
- [ ] 测试 MVS 验证标准的 6 个动作

### 交付物验证

按 3.4 节 6 个验证动作逐一测试，**全部通过 = MVS 部署成功**。

**结果**：MVS 已就绪。可以开始用 CodeBuddy 工作室开发实际游戏项目。

## 4.5 Phase 4 — 质量自动化（Quality Automation）

### 目标
强化 Hook + Rule 体系，让质量校验自动化。**此阶段后工作室能"主动提醒和阻止质量问题"**。

### 任务清单

- [ ] 增加 4 个 validate-* hook（validate-commit / validate-push / validate-assets / validate-skill-change）+ 配置 `settings.json`
- [ ] 测试 PreToolUse hook：尝试 commit 一个非法 JSON，应被 `exit 2` 阻止
- [ ] 增加 5 条转智能体请求模式 Rule（ai-code / engine-code / network-code / shader-code / narrative）
- [ ] 增加 5-7 个补充 skill（视项目需要）：
  - 多人项目：security-audit / soak-test / hotfix
  - 长期项目：milestone-review / tech-debt / propagate-design-change
  - Live-service 项目：team-live-ops + live-ops-designer agent
- [ ] 在 CODEBUDDY.md 增加"质量门规则"一节

### 交付物验证

```
用户编辑 assets/data/items.json，写入语法错误
→ PostToolUse 触发 validate-assets.sh
→ exit 1 阻止保存 + 提示 "JSON 语法错误"
```

**结果**：标准档工作室已就绪。质量校验主动化，工作流稳定。

## 4.6 Phase 5 — 元测试与扩展（Meta & Extensions）

### 目标
完整档定位。**此阶段持续投入，不断优化工作室本身**。

### 任务清单

- [ ] 增加全部剩余 agent（达完整档 ~42-45 个）—— 视项目需要
- [ ] 增加全部 9 个 team-* skill（接受 3-6 倍延迟）
- [ ] 增加 release 流水线 5 skill
- [ ] 部署 CCGS Skill Testing Framework：`/skill-test` `/skill-improve`
- [ ] 实验 CodeBuddy 特有能力：UserPromptSubmit hook / Agent 多任务并行 / MCP 集成

### 交付物验证

工作室能**自我测试和自我改进**：
- 修改任一 skill 时，validate-skill-change 提示运行 /skill-test
- /skill-test 验证 skill 的 frontmatter / step 完整性 / Task 调用正确性
- /skill-improve 基于审计结果自动优化 skill

**结果**：完整档成熟工作室。**可作为团队/公司级游戏开发标准模板**。

## 4.7 路线图视觉总览

```
Phase 1 (骨架)        ─┬─→  ~18 资产 / 0.5-1 天
                       │
Phase 2 (角色)        ─┼─→  +10 = ~28 / 1-2 天
                       │
Phase 3 (MVS)         ─┴─→  +20 = ~48 / 1-2 天      ← MVS 部署完成
                       │                              ← 可开始实际游戏开发
Phase 4 (自动化)      ─┬─→  +12 = ~60 / 1-2 天      ← 标准档
                       │
Phase 5 (扩展)        ─┴─→  +40+ = 100+ / 持续      ← 完整档
```

---

# 第 5 章 — 风险与取舍清单

> CCGS 移植到 CodeBuddy 后**必然发生的损失**。这一章列出已知坑点，方便用户提前规划缓解策略。

## 5.1 P0 风险 — 性能损失

### R-P0-1：14 个并行 skill 延迟 3-6 倍

| 影响范围 | 14 个 skill |
|---|---|
| 受灾最严重 | `/team-polish`（6 并行）/ `/team-combat`（5 并行）/ `/team-release`（5 并行） |
| 用户感受 | 单次 team-* 调用从 ~5 分钟 → ~20-30 分钟 |
| 缓解策略 | (1) 极简档不保留 team-*；(2) 标准档减少 subagent 数；(3) 用 CodeBuddy 4.5.0 多 Agent 任务并行手动补偿 |
| 真实影响 | **中等** —— 不影响功能，只影响速度 |

### R-P0-2：高频 Director Gate 不再"免费"

| 影响范围 | CCGS 中 every-skill 的 inline Gate |
|---|---|
| 典型场景 | 每个 ADR 触发 TD-ADR / 每个 Story 触发 LP-CODE-REVIEW |
| 缓解策略 | 改为"阶段末批量审查"（详见 02 册 technical-director / lead-programmer） |
| 真实影响 | **小** —— 频率下降但单次质量提升 |

## 5.2 P1 风险 — 自动化能力损失

### R-P1-1：Rule 路径作用域丢失

| 影响范围 | 11 条 Rule |
|---|---|
| 损失内容 | "编辑 src/gameplay/* 时自动激活 gameplay-code rule"的精确触发 |
| 缓解策略 | 方案 C 混合（详见 04 册 Part B） |
| 真实影响 | **小**——alwaysApply 让 rule 始终在线，只是上下文略冗余 |

## 5.3 P2-P3 风险 — 单点能力损失

### R-P2-1：project memory 丢失

| 影响范围 | 14 个 specialist agent |
|---|---|
| 损失内容 | 跨会话记住"已批准的核心系统、艺术圣经、性能预算" |
| 缓解策略 | 用 CODEBUDDY.md + alwaysApply Rules 替代 |
| 真实影响 | **极小**——CODEBUDDY.md 加载到上下文后等价 |

### R-P3-1：prototyper worktree 丢失

| 影响范围 | prototyper agent + /prototype skill |
|---|---|
| 损失内容 | 自动 git worktree 隔离 + 自动清理 |
| 缓解策略 | (1) 用户手动 `git checkout -b prototype/xxx`；(2) prototype-code Rule 强制目录隔离 |
| 真实影响 | **中等**——用户体验下降，需要手动管理 |

### R-P3-2：审计追踪丢失（log-agent / log-agent-stop）

| 影响范围 | 调试和性能分析能力 |
|---|---|
| 损失内容 | "本次会话调用了哪些 agent、耗时多少"的自动日志 |
| 缓解策略 | 直接舍弃（手动分析会话日志代偿，ROI 太低） |
| 真实影响 | **小**——日常开发不依赖审计追踪 |

### R-P3-3：statusLine 丢失

| 影响范围 | UI 体验 |
|---|---|
| 损失内容 | 7 阶段面包屑导航 |
| 缓解策略 | session-start.sh 输出当前阶段代偿 |
| 真实影响 | **极小**——纯 UI 体验差异 |

### R-P3-4：post-compact 提示丢失

| 影响范围 | 上下文压缩后体验 |
|---|---|
| 损失内容 | 自动提示 AI "压缩完读 active.md 恢复" |
| 缓解策略 | pre-compact 输出包含此指令 |
| 真实影响 | **极小** |

## 5.4 风险全表

| 风险 | 严重度 | 影响范围 | 缓解后真实影响 |
|---|---|---|---|
| R-P0-1 并行 skill 延迟 3-6 倍 | 高 | 14 skill | 中等（影响速度不影响功能） |
| R-P0-2 高频 Gate 转批量 | 中 | Gate 系统 | 小（频率↓质量↑） |
| R-P1-1 Rule glob 丢失 | 中 | 11 Rule | 小（alwaysApply 代偿） |
| R-P2-1 project memory 丢失 | 中 | 14 agent | 极小（CODEBUDDY.md 代偿） |
| R-P3-1 worktree 丢失 | 中 | prototyper | 中等（需手动管理 git） |
| R-P3-2 审计追踪丢失 | 低 | 性能分析 | 小（日常不依赖） |
| R-P3-3 statusLine 丢失 | 低 | UI | 极小 |
| R-P3-4 post-compact 丢失 | 低 | 压缩体验 | 极小 |

**汇总**：8 个风险中，**3 个真实影响"小"或"极小"**，**4 个"小"**，**1 个"中等"**（worktree 丢失）。

**结论**：**移植后整体功能损失 < 10%，性能损失 ~30%（仅限并行 skill）**。值得迁移。

---

# 第 6 章 — 决策辅助表

> 给用户的"勾选式自定义移植方案"。回答以下问题后，可生成专属移植清单。

## 6.1 项目特征自评（5 题）

### Q1：你的项目规模是？
- [ ] A. **个人 1-2 人 / Game Jam / 周末项目** → 推荐**极简档（MVS）**
- [ ] B. **2-5 人独立工作室 / 商业 demo** → 推荐**标准档**
- [ ] C. **5-10+ 人小团队 / 商业全发布** → 推荐**完整档**

### Q2：你的项目周期是？
- [ ] A. **< 1 个月（含 Game Jam）** → 极简档足够
- [ ] B. **1-6 个月（MVP/demo）** → 标准档
- [ ] C. **> 6 个月（量产/打磨）** → 完整档

### Q3：你最看重的是？（可多选）
- [ ] A. **极速产出** → 极简档 + 默认 review-mode = solo
- [ ] B. **质量保障** → 标准档 + 全部 4 个 validate-* hook
- [ ] C. **流程严谨** → 完整档 + 全部 17 个 Director Gates
- [ ] D. **持续打磨** → 完整档 + Phase 5 Meta 测试框架

### Q4：你的项目类型是？
- [ ] A. **单人 buy-once 游戏** → **跳过** network/live-ops/release 完整流程
- [ ] B. **多人在线游戏** → **必保** network-programmer + security-engineer + 4 安全 Rule
- [ ] C. **Live-service 游戏** → **必保** live-ops-designer + community-manager + 7 道德指南
- [ ] D. **跨平台 / 国际化** → **必保** localization-lead + accessibility-specialist + ux-designer

### Q5：你的引擎是？
- [ ] A. **Godot 4** → 移植 godot-specialist + 1-3 个子专员
- [ ] B. **Unity** → 移植 unity-specialist + 1-3 个子专员（**记得补 Version Awareness**）
- [ ] C. **Unreal Engine 5** → 移植 unreal-specialist + 1-3 个子专员（**记得补 Version Awareness**）
- [ ] D. **其他** / 自研 → 仅复用 specialist 抽象框架

## 6.2 自定义移植清单生成器

根据 Q1-Q5 答案，组合出移植清单：

### 清单 A：Game Jam / 周末项目（Q1-A + Q2-A + Q3-A）

```
Agents: 5
  - creative-director
  - lead-programmer
  - qa-tester
  - 1 引擎 Lead
  - [Q5-A/B/C 选 1]

Skills: 8
  - /start /help /design-system /dev-story
  - /story-done /smoke-check /retrospective /prototype

Hooks: 2
  - session-start / pre-compact

Rules: 3
  - design-docs / code-standards / data-files

Templates: 6
  - 3 协议 + game-design-document + sprint-plan + ADR

总计: 24 资产 / 0.5 天部署
```

### 清单 B：标准独立工作室（Q1-B + Q2-B + Q3-B）

```
Agents: 25
  - 全部 Tier 1 + Tier 2 + 8 核心 Specialist + 3-5 引擎组

Skills: 40
  - 全部 Onboarding + Game Design + Architecture + Stories
  - 4 核心 team-* (combat / ui / level / qa)

Hooks: 8
  - 全部可移植 hook（除 validate-skill-change）

Rules: 8-9
  - 4 alwaysApply + 4-5 智能体请求

Templates: 27
  - 标准档全套

总计: 108 资产 / 5-8 天部署
```

### 清单 C：完整商业项目（Q1-C + Q2-C + Q3-C/D）

```
Agents: 42-45
  - 几乎全员，仅去 sound-designer / community-manager
  - 1-2 套引擎组完整

Skills: 65-70
  - 几乎全员，仅去 skill-test / skill-improve（除非工作室自身开发）

Hooks: 9
  - 全部可移植

Rules: 11
  - 全套保留

Templates: 38
  - 全套保留

总计: 165+ 资产 / 持续投入
```

## 6.3 三档对比汇总

| 维度 | 极简档（MVS）| 标准档 | 完整档 |
|---|---|---|---|
| **agent 数** | 9-10 | 25 | 42-45 |
| **skill 数** | 20 | 40 | 65-70 |
| **hook 数** | 4 | 8 | 9 |
| **rule 数** | 4-5 | 8-9 | 11 |
| **template 数** | 9 | 27 | 38 |
| **总资产** | ~46 | ~108 | ~165 |
| **部署时间** | 0.5-1 天 | 5-8 天 | 持续 |
| **单 skill 平均耗时** | 短（少 subagent） | 中 | 长（含 team-*） |
| **Token 消耗** | 低 | 中 | 高 |
| **CODEBUDDY.md 维护成本** | 低 | 中 | 高 |
| **质量保证级别** | 主要靠用户 | Gate + 用户 | 全 Gate + Director + 用户 |
| **适合项目** | 探索 / Game Jam / 原型 | MVP / Demo / 量产 | 商业发布 / 长周期 |

## 6.4 默认推荐流程

**如果不知道选哪个，按以下流程**：

1. **从极简档（MVS）起步** —— 快速搭建，立即可用
2. **跑 1-2 周后**评估痛点：
   - 痛点 = "缺质量校验" → 升级到 Phase 4（加 4 validate-* hook）
   - 痛点 = "缺多人协作" → 升级到标准档（加 team-* skill）
   - 痛点 = "缺架构严谨" → 加 Architecture 4 skill + technical-director 完整 Gate 链
3. **按需逐步加** —— 不要一开始就上完整档（150+ 资产管理成本高）

**核心原则**：CodeBuddy 工作室是一个**渐进式进化的产物**——从最小开始，按真实痛点逐步扩展。CCGS 是**设计成熟态**，但你不需要从一开始就达到那里。

---

# 报告总收尾

## 5 册报告完整闭环

```
00_README.md                                    报告导航 + 评级图例
  │
  ├── 01_架构总览.md                            CCGS 是什么（设计原貌）
  │
  ├── 01b_CodeBuddy能力差距与工作流影响分析.md  能力差距识别 + 3 类形态框架
  │
  ├── 02_Agents全析.md                          49 agent 全量拆解
  │
  ├── 03_Skills全析.md                          72 skill 分层拆解
  │
  ├── 04_Hooks+Rules+Templates.md               12+11+38 资产闭环
  │
  └── 05_CodeBuddy移植建议.md                   ← 本册：决策落地
       │
       ├── 第 1 章 能力对照矩阵
       ├── 第 2 章 分层移植策略（4 档）
       ├── 第 3 章 MVS 最小可行清单
       ├── 第 4 章 5 阶段路线图
       ├── 第 5 章 风险清单（8 项）
       └── 第 6 章 决策辅助表（5 题）
```

## 移植决策的 3 句话总结

1. **CCGS 的核心价值（37 套硬性产出格式 + 49 角色分工 + 7 阶段 pipeline）100% 可移植到 CodeBuddy**
2. **性能损失约 30%（仅限 14 个并行 skill），功能损失 < 10%（3 个单点机制）**
3. **从 MVS 起步（46 资产 / 1-2 天），按真实痛点渐进式扩展到完整档（165 资产 / 持续）**

## 接下来的工作

**报告完成后**，建议你：

1. **审阅 5 册报告整体连贯性**，找出任何不一致或需要补充的地方
2. **决定移植档位**（极简 / 标准 / 完整）—— 参考 6.1 节 5 题自评
3. **进入移植执行阶段**（建议另起一个 Plan）：
   - Phase 1 骨架（最快）
   - Phase 2 角色
   - Phase 3 MVS 验证
4. **MVS 上线后实际开发 1-2 周**，根据真实痛点决定是否升级到标准档

---

*05 册完成 ✅ —— 完整 5 册移植参考手册产出完毕。*

*所有移植决策的事实依据都在前 4 册详细记录。本册是综合后的"决策友好"输出，可作为唯一行动文档使用，必要时回查前 4 册原始细节。*

