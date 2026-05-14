# 04 Hooks + Rules + Templates 全析

> CCGS 的**自动化防线**（12 Hook）+ **路径规范**（11 Rule）+ **产出模板库**（38 Template）的完整拆解
>
> 这三类资产是 CCGS 的"**幕后操作员**"——它们不写代码、不做设计，但确保每次交互都符合规范、每次产出都格式一致、每次风险都被主动检测。

---

## 本册范围与交叉引用

- **Part A**：12 个 Hook 脚本（`.claude/hooks/*.sh`）
- **Part B**：11 个 Rule（`.claude/rules/*.md`）
- **Part C**：38 个 Template（`.claude/docs/templates/*.md`，含 3 个协作协议子模板）
- **Part D**：`settings.json` 的 Hook 注册机制（与 Part A 联动）

**交叉引用**：
- **01 册**：Hook 事件系统、权限配置
- **01b 册 P3**：CodeBuddy 不支持 SubagentStart/Stop / PostCompact / Notification（4 hook 不可移植）
- **01b 册 P1**：CodeBuddy 不支持 Rule 路径作用域（11 rule 需合并/手动）
- **02 册**：每个 agent 的协议 → Part C 的 3 套协作协议模板（**已发现 CCGS 自带这 3 套，是关键发现**）
- **03 册**：每个 skill 的产出文件 → Part C 的对应 Template

---

## 概览对比表：三类资产的定位与差异

| 维度 | Hooks（12） | Rules（11） | Templates（38） |
|---|---|---|---|
| **作用时机** | 事件触发时（自动） | 文件匹配时（自动）+ skill 显式引用 | skill 产出文件时（人工调用） |
| **作用机制** | Bash 脚本运行 | 加载到 agent 上下文 | 填充占位符后写入文件 |
| **平台依赖** | 重（Bash/Windows/jq/python） | 轻（纯 Markdown） | 无（纯 Markdown） |
| **移植难度** | **高**（CodeBuddy 事件不全） | 中（无路径 glob） | **低**（平台无关） |
| **CodeBuddy ROI** | 部分可用（8/12 事件映射） | 高（合并为全局 Rule） | **极高**（38 个全部零改造迁移） |

---

# Part A — 12 个 Hook 脚本全解析

## A.0 Hook 事件总览与 CodeBuddy 映射

### 12 Hook 的事件分布与映射状态

| # | Hook | CCGS 事件 | CodeBuddy 对应事件 | 映射状态 |
|---|---|---|---|---|
| 1 | session-start.sh | SessionStart | SessionStart | ✅ |
| 2 | detect-gaps.sh | SessionStart | SessionStart | ✅ |
| 3 | session-stop.sh | Stop | Stop / SessionEnd | ✅ |
| 4 | pre-compact.sh | PreCompact | PreCompact | ✅ |
| 5 | post-compact.sh | PostCompact | **无对应** | ❌ |
| 6 | validate-commit.sh | PreToolUse(Bash) | PreToolUse | ✅ |
| 7 | validate-push.sh | PreToolUse(Bash) | PreToolUse | ✅ |
| 8 | validate-assets.sh | PostToolUse(Write/Edit) | PostToolUse | ✅ |
| 9 | validate-skill-change.sh | PostToolUse(Write/Edit) | PostToolUse | ✅ |
| 10 | log-agent.sh | SubagentStart | **无对应** | ❌ |
| 11 | log-agent-stop.sh | SubagentStop | **无对应** | ❌ |
| 12 | notify.sh | Notification | **无对应** | ❌ |

**结果**：
- **8/12 可直接映射**（覆盖 SessionStart / Stop / PreCompact / PreToolUse / PostToolUse 5 种事件）
- **4/12 无法移植**（post-compact / log-agent / log-agent-stop / notify）

### 关键观察：统一契约模式

**所有 7 个需要事件数据的 hook 统一从 `stdin` 读 JSON payload**，没有依赖 `$CLAUDE_HOOK_*` 或 `$HOOK_*` 环境变量。

**这意味着**：CodeBuddy 的 hook 契约如果保持 JSON stdin 输入（这是主流做法），**脚本逻辑几乎零改造**。主要改造集中在 `settings.json` 的事件注册语法映射。

---

## A.1-A.4 上下文管理类 Hook（4 个）

### A.1 `session-start.sh`（会话开始上下文注入）

| 字段 | 值 |
|---|---|
| 事件 | SessionStart |
| matcher | `""`（所有） |
| 核心逻辑 | 输出当前 git 分支、最近 5 commit、最新 sprint/milestone、开放 bug 数、TODO/FIXME 计数；若 `production/session-state/active.md` 存在则打印尾部 20 行 |
| 失败策略 | fail-soft |
| 依赖 | `git` / `find` / `grep` / `wc` / `tail` |
| Windows | ✅（纯 POSIX） |

**CodeBuddy 适配**：直接移植，事件名相同。**档位：极简 ✅ / 标准 ✅ / 完整 ✅**（会话启动必保）。

### A.2 `detect-gaps.sh`（文档缺口自动检测）

| 字段 | 值 |
|---|---|
| 事件 | SessionStart（与 A.1 **并列注册**） |
| 核心逻辑 | 检测无 GDD 的源码目录 / 无 README 的原型 / 无 ADR 的 core 代码 / 无 sprint 计划的大型代码库，输出 `⚠️ GAP` 警告 + 建议运行的 skill |
| 失败策略 | fail-soft |
| Windows | ✅（需 bash 而非 sh，用了数组+here-string） |

**关键价值**：CCGS "自我检测 + 引导用户"哲学的核心体现——配合 `/help` skill 形成完整导航系统。

**CodeBuddy 适配**：直接移植。**档位：极简 ✅ / 标准 ✅ / 完整 ✅**。

### A.3 `session-stop.sh`（会话结束归档）

| 字段 | 值 |
|---|---|
| 事件 | Stop |
| 核心逻辑 | 读过去 8 小时 git commits + 未提交文件，若 `active.md` 存在则追加到 `session-logs/session-log.md` |
| 失败策略 | fail-soft（写入 `2>/dev/null`） |
| Windows | ✅ |

**CodeBuddy 适配**：CodeBuddy 有 **Stop** 和 **SessionEnd** 两个事件——任选其一。**档位：极简 ✅ / 标准 ✅ / 完整 ✅**。

### A.4 `pre-compact.sh`（压缩前状态转储）

| 字段 | 值 |
|---|---|
| 事件 | PreCompact |
| 核心逻辑 | 压缩前自动转储**会话恢复所需信息**到对话：active.md 前 100 行 / git 工作树变更 / GDD 中的 WIP/TODO 行；追加压缩时间戳到 `compaction-log.txt` |
| 失败策略 | fail-soft |
| Windows | ✅ |

**关键价值**：CCGS"上下文管理"最精妙的设计——用 hook 在压缩前自动"写一份压缩后需要的恢复清单"。

**CodeBuddy 适配**：直接移植，CodeBuddy 完全支持 PreCompact。**档位：极简 ✅ / 标准 ✅ / 完整 ✅**（**上下文管理关键**）。

---

## A.5 ⚠️ `post-compact.sh`（不可移植）

| 字段 | 值 |
|---|---|
| 事件 | PostCompact |
| 核心逻辑 | 压缩完成后提示 Claude 立即读 `active.md` 恢复上下文 |
| CodeBuddy 状态 | ❌ **不可移植**（无 PostCompact 事件） |

**代偿方案**：
1. 把"压缩后读 active.md"指令合并到 `pre-compact.sh` 的输出文本中
2. 或在 `session-start.sh` 输出加一行"如刚完成压缩请读 active.md"

**影响**：功能**部分丢失**，但损失小（用户/AI 主动意识即可）。**档位：极简 ❌ / 标准 ⚪（带代偿） / 完整 ⚪**。

---

## A.6-A.9 质量校验类 Hook（4 个）

### A.6 `validate-commit.sh`（最重要的硬性质量门）

| 字段 | 值 |
|---|---|
| 事件 | PreToolUse |
| matcher | `"Bash"` + 命令含 `git commit` |
| 核心逻辑 | 4 类校验：(1) GDD 8 必备节缺失 → warning；(2) `assets/data/*.json` 非法 → **`exit 2` 阻止**；(3) `src/gameplay/` 硬编码 → warning；(4) 无 owner 的 TODO → warning |
| 失败策略 | **混合**（JSON 非法 fail-hard，其余 fail-soft） |
| 依赖 | `python` / `git` / `grep -E` |
| Windows | 需 bash（用 `[[ ]]` 和 here-string） |

**关键价值**：CCGS **唯一的"硬性质量门"** —— 其他 hook 全 fail-soft，只有 commit 校验真正能阻塞错误操作。

**CodeBuddy 适配**：直接移植，事件名相同。**档位：极简 ⚪（Game Jam 可不要）/ 标准 ✅ / 完整 ✅**。

### A.7 `validate-push.sh`（Git push 警告）

| 字段 | 值 |
|---|---|
| 事件 | PreToolUse |
| matcher | `"Bash"` + 命令含 `git push` |
| 核心逻辑 | 推到 develop/main/master 时打印警告（build？测试？无 S1/S2？）；当前 `exit 2` 已被注释 |
| 失败策略 | fail-soft（有待激活的 fail-hard 分支） |

**CodeBuddy 适配**：直接移植。**档位：极简 ⚪ / 标准 ✅ / 完整 ✅**。

### A.8 `validate-assets.sh`（资产文件校验）

| 字段 | 值 |
|---|---|
| 事件 | PostToolUse |
| matcher | `"Write|Edit"` + 路径匹配 `assets/` |
| 核心逻辑 | 文件名含大写/空格/连字符 → warning；`assets/data/*.json` 非法 → **`exit 1` 阻止** |
| 失败策略 | 混合 |

**CodeBuddy 适配**：直接移植。**档位：极简 ⚪ / 标准 ✅ / 完整 ✅**。

### A.9 `validate-skill-change.sh`（Skill 修改提示）

| 字段 | 值 |
|---|---|
| 事件 | PostToolUse |
| matcher | `"Write|Edit"` + 路径匹配 `.claude/skills/` |
| 核心逻辑 | 检测到 skill 文件修改时输出建议："Run /skill-test static <skill-name>" |
| 失败策略 | fail-soft |

**注意**：此 hook 价值依赖 `/skill-test` skill 存在（仅完整档保留）。**档位：极简 ❌ / 标准 ❌ / 完整 ⚪**。

---

## A.10-A.12 ⚠️ 不可移植 Hook（3 个）

### A.10 `log-agent.sh` + A.11 `log-agent-stop.sh`（SubagentStart/Stop 审计）

| 字段 | 值 |
|---|---|
| 事件 | SubagentStart / SubagentStop |
| 核心逻辑 | 从 stdin JSON 解析 `agent_type`，追加到 `production/session-logs/agent-audit.log` |
| CodeBuddy 状态 | ❌ **不可移植**（无 SubagentStart/Stop 事件） |

**价值**：CCGS 的"审计追踪"——知道某次会话调用了哪些 agent，对调试和性能分析有价值。

**代偿方案（成本高）**：
1. 在每个 skill 的 step 里手动加日志写入——但要改 72 个 skill，**ROI 极低**
2. **务实方案**：放弃审计追踪，需要时手动分析会话日志

**档位**：极简 ❌ / 标准 ❌ / 完整 ⚪。**对日常开发影响小**，主要损失在性能分析能力。

### A.12 `notify.sh`（Windows 弹窗通知）

| 字段 | 值 |
|---|---|
| 事件 | Notification |
| 核心逻辑 | 通过 `powershell.exe` 调用 NotifyIcon 弹出 Windows 气球通知 |
| CodeBuddy 状态 | ❌ **不可移植**（无 Notification 事件） |

**评价**：本身就是 Windows 专用且价值低，**直接舍弃**最合理。**档位：极简 ❌ / 标准 ❌ / 完整 ❌**。

---

## A.13 settings.json Hook 注册机制

### CCGS 原格式

```json
{
  "hooks": {
    "SessionStart": [
      { "matcher": "", "hooks": [
        { "type": "command", "command": "bash .claude/hooks/session-start.sh" },
        { "type": "command", "command": "bash .claude/hooks/detect-gaps.sh" }
      ]}
    ],
    "PreToolUse": [
      { "matcher": "Bash", "hooks": [
        { "type": "command", "command": "bash .claude/hooks/validate-commit.sh" },
        { "type": "command", "command": "bash .claude/hooks/validate-push.sh" }
      ]}
    ]
  },
  "permissions": {...}
}
```

### CodeBuddy 对应格式

```json
{
  "hooks": {
    "SessionStart": [...],     // ✅
    "SessionEnd": [...],       // ✅（对应 CCGS 的 Stop）
    "PreToolUse": [...],       // ✅
    "PostToolUse": [...],      // ✅
    "PreCompact": [...],       // ✅
    "Stop": [...],             // ✅
    "UserPromptSubmit": [...]  // CodeBuddy 独有
    // ⚠️ 无 PostCompact / SubagentStart / SubagentStop / Notification
  }
}
```

### 关键发现：格式 85% 兼容

CodeBuddy 的 `settings.json` hook 注册格式与 Claude Code **几乎一致**（相同的 hooks 键名、matcher 字段、command 数组结构）。

**8 个可移植 hook 的 settings.json 注册改造量极低**——改事件名 + 移除 4 个不支持事件即可。

### 权限字段改造

CCGS 的 `permissions` 字段（`allow/deny` 列表）需改为 CodeBuddy 的 PreToolUse hook 的 `permissionDecision: deny` 替代（详见 01 册）。

---

## Part A 横向规律

### 规律 1：Hook 的 4 大职责分布

| 职责 | 数量 | hook |
|---|---|---|
| 上下文管理 | 4 | session-start / session-stop / pre-compact / post-compact |
| 质量校验 | 4 | validate-commit / validate-push / validate-assets / validate-skill-change |
| 审计/通知 | 3 | log-agent / log-agent-stop / notify |
| 诊断提示 | 1 | detect-gaps |

### 规律 2：fail-soft 是主流（10/12）

仅 2 个 hook 真正阻塞操作（validate-commit / validate-assets 的 JSON 校验）。**CCGS 哲学：提醒而非强制**——让 AI 和用户知道有问题，但不绕过决策。

**移植洞察**：CodeBuddy 上同样推荐 fail-soft 为主，仅明确错误（如非法 JSON）才 fail-hard。

### 规律 3：统一 stdin JSON 契约（不依赖环境变量）

所有 hook 通过 `stdin` 读 JSON payload。这是 Claude Code hooks 标准契约，与 CodeBuddy 预期一致——**脚本本身几乎零改造**。

### 规律 4：Windows 兼容性普遍良好

全部 12 hook 都为 Windows Git Bash 环境做过适配：用 `grep -E` 而非 `-P`、`\` → `/` 路径归一化、Python 按 `python → python3 → py` 探测、`notify.sh` 主动用 `powershell.exe`。

### 规律 5：4 个 hook 无法移植（33%）

| 不可移植 | 影响 | 代偿 |
|---|---|---|
| post-compact.sh | 小 | 合并到 pre-compact 输出或 session-start |
| log-agent.sh | 中（审计能力丢失） | ROI 低，建议放弃 |
| log-agent-stop.sh | 中 | 同上 |
| notify.sh | 微小 | 直接舍弃 |

### Part A 适配性总表

| hook | 事件 | matcher | 失败 | CB 状态 | 极简 | 标准 | 完整 |
|---|---|---|---|---|---|---|---|
| session-start.sh | SessionStart | `""` | soft | ✅ | ✅ | ✅ | ✅ |
| detect-gaps.sh | SessionStart | `""` | soft | ✅ | ✅ | ✅ | ✅ |
| session-stop.sh | Stop | `""` | soft | ✅ | ✅ | ✅ | ✅ |
| pre-compact.sh | PreCompact | `""` | soft | ✅ | ✅ | ✅ | ✅ |
| post-compact.sh | PostCompact | `""` | soft | ❌ | ❌ | ⚪ | ⚪ |
| validate-commit.sh | PreToolUse | Bash | **hard** | ✅ | ⚪ | ✅ | ✅ |
| validate-push.sh | PreToolUse | Bash | soft | ✅ | ⚪ | ✅ | ✅ |
| validate-assets.sh | PostToolUse | Write/Edit | **hard** | ✅ | ⚪ | ✅ | ✅ |
| validate-skill-change.sh | PostToolUse | Write/Edit | soft | ✅ | ❌ | ❌ | ⚪ |
| log-agent.sh | SubagentStart | `""` | soft | ❌ | ❌ | ❌ | ⚪ |
| log-agent-stop.sh | SubagentStop | `""` | soft | ❌ | ❌ | ❌ | ⚪ |
| notify.sh | Notification | `""` | soft | ❌ | ❌ | ❌ | ❌ |

**极简档保留 = 4 个**（session-start / detect-gaps / session-stop / pre-compact）  
**标准档保留 = 8 个**（加 4 个 validate-*）  
**完整档保留 = 9 个**（加 validate-skill-change）

---

# Part B — 11 个 Rule 全解析

## B.0 Rule 机制概览

### CCGS 原设计

CCGS 的 Rule 通过 **YAML frontmatter 的 `paths` 字段** 实现"路径作用域"——AI 编辑匹配路径下的文件时，对应 Rule 自动加载到上下文。权威路径-规则映射表在 `.claude/docs/rules-reference.md`。

| Rule 文件 | 作用路径 | 类别 |
|---|---|---|
| ai-code.md | `src/ai/**` | 代码（AI） |
| data-files.md | `assets/data/**` | 数据/资产 |
| design-docs.md | `design/gdd/**` | **设计文档（最核心）** |
| engine-code.md | `src/core/**` | 代码（引擎层） |
| gameplay-code.md | `src/gameplay/**` | **代码（玩法，最重要）** |
| narrative.md | `design/narrative/**` | 设计文档（叙事） |
| network-code.md | `src/networking/**` | 代码（网络） |
| prototype-code.md | `prototypes/**` | 代码（放宽约束，与 prototyper 配合） |
| shader-code.md | `assets/shaders/**` | 代码（Shader） |
| test-standards.md | `tests/**` | 测试 |
| ui-code.md | `src/ui/**` | 代码（UI） |

### CodeBuddy 限制与代偿策略

**核心限制**：CodeBuddy 的 Rule 支持 3 种加载模式（`alwaysApply` / 智能体请求 / 手动），**不支持 glob 路径作用域**。

**代偿方案**（01b 册 P1 已分析）：

| 方案 | 描述 | 优劣 |
|---|---|---|
| **A 合并** | 11 条合并为 3 条全局规则（code / design-docs / test）`alwaysApply: true` | 简单，**失去细粒度**——所有代码都加载所有代码规则 |
| **B 手动** | 保留 11 条作为手动规则，skill 内显式 `@rule-name` | 保留细粒度，**需改 72 个 skill** |
| **C 混合（推荐）** | 通用 3 条 alwaysApply（design-docs / code-standards 合并版 / test-standards），专项 4 条改为智能体请求模式（shader / prototype / ai / network），UI 规则 alwaysApply | 平衡——**推荐方案** |

---

## B.1 代码规范类 Rule（7 个，按重要度排序）

### B.1.1 ⭐ `gameplay-code.md`（最重要的代码规则）

**作用路径**：`src/gameplay/**`

**8 条强制项，最重要 3 条**：
1. **ALL gameplay values MUST come from external config/data files, NEVER hardcoded**（数据驱动铁律）
2. Use delta time for ALL time-dependent calculations（帧率独立）
3. NO direct references to UI code — use events/signals for cross-system communication（玩法/UI 解耦）

**关联 agent**：gameplay-programmer（主责）/ ai-programmer / network-programmer / ui-programmer（解耦对象）/ ue-gas-specialist / godot-gdscript-specialist / systems-designer

**关联 skill**：dev-story / code-review / test-setup / test-helpers / prototype / regression-suite / team-combat

**CodeBuddy 适配**：
- **方案 C 推荐处理**：作为"code-standards" 合并 Rule 的核心节，`alwaysApply: true`
- 数据驱动铁律是最高优先级 —— 应放置在合并 Rule 的开头

### B.1.2 `engine-code.md`（引擎层零分配铁律）

**作用路径**：`src/core/**`

**9 条强制项，最重要 3 条**：
1. **ZERO allocations in hot paths**（update loops / rendering / physics）
2. Engine code must NEVER depend on gameplay code（依赖方向：engine ← gameplay）
3. Profile before AND after every optimization — document the measured numbers

**CodeBuddy 适配**：
- **风险**：作为全局 alwaysApply 会让所有代码都加载"零分配"约束，对 gameplay 代码过度严格
- **推荐**：手动规则模式（`@engine-code`），仅在 engine-programmer / performance-analyst 调用时引用

### B.1.3 `ai-code.md`（AI 性能预算 2ms）

**作用路径**：`src/ai/**`

**8 条强制项，最重要 3 条**：
1. **AI update budget: 2ms per frame maximum** —— profile to verify
2. All AI parameters must be tunable from data files
3. **Never trust AI input from the network without validation**

**CodeBuddy 适配**：智能体请求模式（仅 AI 项目相关 skill 引用），无 AI 系统的项目零开销。

### B.1.4 `network-code.md`（服务端权威）

**作用路径**：`src/networking/**`

**8 条强制项，最重要 3 条**：
1. **Server is AUTHORITATIVE for all gameplay-critical state**
2. All network messages must be versioned for forward/backward compatibility
3. Client predicts locally, reconciles with server — implement rollback for mispredictions

**CodeBuddy 适配**：智能体请求模式，多人项目才激活。

### B.1.5 `ui-code.md`（UI 单向依赖）

**作用路径**：`src/ui/**`

**8 条强制项，最重要 3 条**：
1. **UI must NEVER own or directly modify game state** —— display only, use commands/events
2. All UI text must go through the localization system —— no hardcoded user-facing strings
3. Support both keyboard/mouse AND gamepad input；Scalable text and colorblind modes are mandatory

**CodeBuddy 适配**：含 UI 项目几乎都需要——可以 `alwaysApply: true` 或合并到 code-standards。

### B.1.6 `shader-code.md`（最庞大的代码规则）

**作用路径**：`assets/shaders/**`

**~20 条强制项**（分 5 节：Naming / Code Quality / Performance / Cross-Platform / Variants），**最重要 3 条**：
1. File naming: `[type]_[category]_[name].[ext]`，前缀 `spatial_/canvas_/particles_/post_`
2. No magic numbers；Avoid dynamic branching in fragment shaders
3. Test on minimum spec target hardware；Provide fallback/simplified versions for lower quality tiers

**CodeBuddy 适配**：智能体请求模式，仅 shader / VFX 相关 skill 引用。

### B.1.7 `prototype-code.md`（唯一"放宽约束"的 Rule）

**作用路径**：`prototypes/**`

**~14 条强制项**（主要是反向约束），最重要 3 条：
1. Every prototype MUST have a `README.md` with hypothesis / how to run / status / findings
2. **No production code may reference or import from `prototypes/`; Prototypes must not modify files outside `prototypes/`**（隔离）
3. **Prototype code is NOT migrated directly** —— rewritten to production standards when validated

**与 02 册 prototyper agent 配合**：CCGS 中 prototyper 用 `isolation: worktree` 实现技术隔离，这条 Rule 实现规则隔离。CodeBuddy 移植后 worktree 丢失（02 册），这条 Rule 的价值**反而上升**——成为唯一的隔离防线。

**CodeBuddy 适配**：alwaysApply: true（**重要**：作为 worktree 损失的代偿）。

---

## B.2 设计文档规范类 Rule（2 个）

### B.2.1 ⭐ `design-docs.md`（GDD 8 节规范，全册最核心 Rule）

**作用路径**：`design/gdd/**`

**9 条强制项，最重要 3 条**：
1. **Every design document MUST contain these 8 sections**: Overview / Player Fantasy / Detailed Rules / Formulas / Edge Cases / Dependencies / Tuning Knobs / Acceptance Criteria（**8 节结构强制**）
2. Design documents MUST be written incrementally: skeleton first, one section at a time with user approval, write to file immediately（增量撰写流程）
3. Acceptance criteria must be testable —— a QA tester must be able to verify pass/fail（可测试性）

**关联 agent**：game-designer（主责）/ systems-designer / creative-director / narrative-director / level-designer / economy-designer / qa-lead

**关联 skill**：quick-design / design-review / review-all-gdds / create-architecture / propagate-design-change / consistency-check / reverse-document / map-systems / scope-check

**CodeBuddy 适配**：**alwaysApply: true 强烈推荐** —— 这是 CCGS 与 02 册"GDD 8 节"硬性产出格式相联动的最核心 Rule。所有设计 skill 都需要遵循。

### B.2.2 `narrative.md`（叙事一致性）

**作用路径**：`design/narrative/**`

**8 条强制项，最重要 3 条**：
1. All new lore must be cross-referenced against existing lore for contradictions
2. Every lore entry must specify canon level: Established / Provisional / Under Review
3. No line of dialogue should exceed 120 characters for dialogue box constraints

**CodeBuddy 适配**：智能体请求模式，仅叙事项目激活。

---

## B.3 数据/资产规范（1 个）

### B.3.1 `data-files.md`（构建阻塞级别）

**作用路径**：`assets/data/**`

**8 条强制项，最重要 3 条**：
1. **All JSON files must be valid JSON —— broken JSON blocks the entire build pipeline**（构建阻塞）
2. File naming: lowercase with underscores only, following `[system]_[name].json` pattern
3. **No orphaned data entries** —— every entry must be referenced by code or another data file

**与 Hook 联动**：`validate-commit.sh` 和 `validate-assets.sh` 都校验 `assets/data/*.json` 的语法合法性 —— 这条 Rule + 2 个 Hook 形成完整的"数据文件防御链"。

**CodeBuddy 适配**：alwaysApply: true（高 ROI，几乎所有项目都需要）。

---

## B.4 测试规范（1 个）

### B.4.1 `test-standards.md`

**作用路径**：`tests/**`

**8 条强制项，最重要 3 条**：
1. Test naming: `test_[system]_[scenario]_[expected_result]` pattern
2. Every test must have a clear arrange/act/assert structure
3. **Every bug fix must have a regression test that would have caught the original bug**

**关联 agent**：qa-lead / qa-tester / gameplay-programmer / engine-programmer / tools-programmer / devops-engineer  
**关联 skill**：test-setup / test-helpers / test-evidence-review / test-flakiness / regression-suite / qa-plan / smoke-check / soak-test / team-qa / story-done

**CodeBuddy 适配**：alwaysApply: true（含测试的项目都需要）。

---

## Part B 横向规律

### 规律 1：11 Rule 中 5 条"必备"，6 条"按需"

| 必备（alwaysApply 或合并核心）| 按需（智能体请求模式） |
|---|---|
| design-docs.md（GDD 8 节）⭐ | ai-code（无 AI 项目跳过） |
| gameplay-code.md（数据驱动）⭐ | network-code（单人项目跳过） |
| data-files.md（JSON 合法性） | shader-code（无 shader 跳过） |
| test-standards.md（测试规范） | engine-code（小项目少改引擎） |
| prototype-code.md（worktree 代偿） | narrative.md（无叙事跳过） |

### 规律 2：所有 11 条 Rule 都仅声明 `paths` 字段

CCGS 的 Rule frontmatter **极简**——只用 `paths`，没有 `name` / `description` / `alwaysApply` / `globs` 等字段。这种简洁性使得**移植到 CodeBuddy 时易于改造**——只需补加 `alwaysApply: true` 或类似的加载模式声明。

### 规律 3：Rule 与 Agent / Skill 的隐式联动

CCGS 的 Rule **没有显式 @mention 引用 agent 或 skill**——关联是通过路径模式自然发生的（编辑某路径时，对应 Rule 自动加载，对应 agent 也自然被相关 skill spawn）。

**移植洞察**：CodeBuddy 因无 path glob，必须把这种隐式联动改为**显式声明** —— 在 agent 提示词或 skill 提示词里写 `Reference: @code-standards rule`。

### 规律 4：3 个 Rule 是 Hook 的"上游规范"

| Rule | 联动的 Hook | 防御链 |
|---|---|---|
| design-docs.md（GDD 8 节）| validate-commit.sh（commit 时检查 GDD 8 节） | 写时遵循 + commit 时校验 |
| data-files.md（JSON 合法）| validate-commit.sh + validate-assets.sh（双校验） | 写时遵循 + commit/edit 双校验 |
| test-standards.md | （隐式：dev-story skill 内嵌测试要求） | 写时遵循 |

**移植关键**：Rule + Hook 配合的"双防御"在 CodeBuddy 上完全可保留 —— Rule 用 alwaysApply，Hook 用 PreToolUse + PostToolUse。

### 规律 5：CodeBuddy 移植的 3 大核心动作

1. **3 条 alwaysApply 全局 Rule**（design-docs / code-standards 合并版 / test-standards）—— 替代 CCGS 的全局编辑规范
2. **保留 prototype-code 作为独立 alwaysApply Rule** —— 代偿 worktree 损失
3. **5 条转为智能体请求模式**（ai / network / shader / engine / narrative）—— 仅相关项目激活

### Part B 适配性总表

| Rule | 类别 | 关键约束 | CB 模式建议 | 极简 | 标准 | 完整 |
|---|---|---|---|---|---|---|
| design-docs.md ⭐ | 设计文档 | GDD 8 节强制 | alwaysApply | ✅ | ✅ | ✅ |
| gameplay-code.md ⭐ | 代码（玩法） | 数据驱动 / 帧率独立 / UI 解耦 | alwaysApply（合并到 code-standards） | ✅ | ✅ | ✅ |
| data-files.md | 数据 | JSON 合法 / 命名 / 无孤儿 | alwaysApply | ✅ | ✅ | ✅ |
| test-standards.md | 测试 | 命名 / AAA 结构 / 回归覆盖 | alwaysApply | ✅ | ✅ | ✅ |
| prototype-code.md | 隔离 | 严禁 prototype/production 互访 | alwaysApply（worktree 代偿） | ⚪ | ✅ | ✅ |
| ui-code.md | 代码（UI） | 单向依赖 / 本地化 / 无障碍 | alwaysApply 或合并 | ⚪ | ✅ | ✅ |
| ai-code.md | 代码（AI） | 2ms 预算 / 数据驱动 | 智能体请求 | ❌ | ⚪ | ✅ |
| engine-code.md | 代码（引擎） | 零分配 / 依赖方向 | 智能体请求 | ❌ | ⚪ | ✅ |
| network-code.md | 代码（网络） | 服务端权威 / 版本化 | 智能体请求 | ❌ | ❌ | ⚪ |
| shader-code.md | 代码（Shader） | 命名 / 性能 / 跨平台 | 智能体请求 | ❌ | ⚪ | ✅ |
| narrative.md | 设计（叙事） | 一致性 / canon 级 / 120 字符 | 智能体请求 | ❌ | ⚪ | ✅ |

**极简档保留 = 4-5 条**（design-docs / gameplay-code / data-files / test-standards + 视项目 ui-code）  
**标准档保留 = 8-9 条**  
**完整档保留 = 11 条**

---

# Part C — 38 个 Template 全解析

## C.0 Template 库总览

CCGS 的 Template 是**填空式产出模板**，由各个 skill 在产出文件时引用。共 38 个：
- **35 个顶层 Template**（位于 `.claude/docs/templates/`）
- **3 个协作协议子 Template**（位于 `.claude/docs/templates/collaborative-protocols/`）⭐ **重大发现**

### 关键发现：CCGS 已自带 3 套协作协议模板

02 册反复提到"3 套共享协议"（设计型 4 步 / 实现型 6 步 / leadership 5 步）—— 实际上**CCGS 自己已经把这 3 套抽离为模板**：

```
.claude/docs/templates/collaborative-protocols/
  ├── design-agent-protocol.md          (Question-First Workflow 4 步)
  ├── implementation-agent-protocol.md   (Implementation Workflow 6 步)
  └── leadership-agent-protocol.md       (Strategic Decision Workflow 5 步)
```

**重要事实**：这些模板已存在，但 49 个 agent 的 md 文件**没有引用它们**——仍然把协议内容**重复**写在每个 agent 里。CCGS 作者的"共享化"工作只走了一半（创建模板但未让 agent 用）。

**移植到 CodeBuddy 的关键动作**：
1. 直接复用这 3 个模板文件
2. 修改 49 个 agent，把协议章节改为显式引用模板（如 `Refer to: @design-agent-protocol`）
3. 这样**一次性消除 ~1300 行重复**（02 册估算）

---

## C.1 协作协议模板（3 个）⭐ 核心发现

### C.1.1 `design-agent-protocol.md`

**适用 agent**（13 个）：creative-director / game-designer / systems-designer / level-designer / economy-designer / world-builder / art-director / audio-director / narrative-director / ux-designer / live-ops-designer + producer + technical-director（部分章节）

**核心结构（5 大节）**：
1. Question-First Workflow（4 步）
2. Example Interaction Pattern（含完整对话示例）
3. Collaborative Mindset（6 条）
4. Structured Decision UI（AskUserQuestion 工具用法）
5. Format Guidelines + Multi-question batch 示例

**与 02 册的关系**：02 册的"设计型 4 步协议"完全对应此模板。

### C.1.2 `implementation-agent-protocol.md`

**适用 agent**（10 个）：lead-programmer / qa-lead / release-manager / localization-lead / 6 个 programmer（gameplay/engine/ai/network/tools/ui）+ technical-artist / sound-designer（实际不该用）/ writer（实际不该用）/ performance-analyst / 12 引擎子专员

**核心结构（5 大节）**：
1. Implementation Workflow（6 步：Read → Ask → Propose → Implement → Approval → **/story-done**）
2. Example Interaction Pattern（damage_calculator.gd 完整示例）
3. Collaborative Mindset（**含"Story 完成必走 /story-done"** 关键约束）
4. Structured Decision UI
5. Architecture questions batch 示例

**与 02 册的关系**：02 册的"实现型 6 步协议" + 第 6 步明确要求 `/story-done`——这是 02 册没识别出的细节。

### C.1.3 `leadership-agent-protocol.md`

**适用 agent**（4 个）：creative-director / technical-director / producer + art-director（部分）

**核心结构（5 大节）**：
1. Strategic Decision Workflow（5 步：Understand → Frame → Options → Recommend → Support）
2. Example Interaction Pattern（**crafting Alpha 范围决策**完整示例 —— 极有教学价值）
3. Collaborative Mindset
4. Structured Decision UI
5. Strategic decision batch 示例

**与 02 册的关系**：02 册的"5 步协作协议（Ask → Options → Decision → Draft → Approval）"完全对应——是 Director 级 Tier 1 的标志。

### 3 个协议模板的横向规律

| 维度 | design | implementation | leadership |
|---|---|---|---|
| 适用 agent 数 | 13 | 10+12 引擎 | 4 |
| 核心步骤数 | 4 | 6 | 5 |
| 关键差异 | "Options + 推荐" 模式 | 强制 `/story-done` 收尾 | "Recommend 但 user 决定" |
| 决策粒度 | 设计选项 | 架构选择 | 战略方向 |
| 是否含完整示例对话 | ✅ | ✅ | ✅（最长） |

**CodeBuddy 适配评级**：
- **移植类型**：**直接移植**（纯 Markdown 模板）
- **移植后改造点**：每个 agent 的 frontmatter 或正文加 `protocol: design / implementation / leadership` 字段，由 CodeBuddy skill 在 spawn agent 时自动注入对应协议
- **价值**：移植此 3 模板 + 让 agent 显式引用 = **02 册识别的"3 处大型可抽离 snippet 节省 1300 行"完全实现**
- **档位**：**全档必保留 ✅✅✅**

---

## C.2 设计文档类 Template（10 个）

| # | Template | 对应 skill | 对应 agent | 关键字段数 |
|---|---|---|---|---|
| C.2.1 | `game-concept.md` | /start, /brainstorm | creative-director | ~10 节（pillars / MDA / 范围层） |
| C.2.2 | `game-design-document.md` ⭐ | /design-system | game-designer | **8 节强制**（与 design-docs Rule 联动） |
| C.2.3 | `game-pillars.md` | /brainstorm | creative-director | 3-5 个 pillars |
| C.2.4 | `pitch-document.md` | /brainstorm | creative-director | logline / hook / proof points |
| C.2.5 | `systems-index.md` | /map-systems | game-designer | 系统列表 + 依赖 + 优先级 |
| C.2.6 | `economy-model.md` | /design-system（经济） | economy-designer | sources / sinks / curves |
| C.2.7 | `difficulty-curve.md` | /design-system | systems-designer | XP / 难度 / 时间分布 |
| C.2.8 | `level-design-document.md` | /level-design | level-designer | **9 字段**（Level Document Standard） |
| C.2.9 | `narrative-character-sheet.md` | /design-system（角色） | narrative-director | 弧 / 动机 / 关系 |
| C.2.10 | `faction-design.md` | /design-system | world-builder | 派系结构 / 关系 / 领地 |

**移植洞察**：10 个设计模板**全部与 02 册识别的硬性产出格式对应**——比如 `game-design-document.md` 就是 GDD 8 节，`level-design-document.md` 就是 9 字段。**直接迁入 CodeBuddy skill 模板，零改造**。

---

## C.3 架构与技术类 Template（5 个）

| # | Template | 对应 skill | 关键字段 |
|---|---|---|---|
| C.3.1 | `architecture-decision-record.md` | /architecture-decision | Context / Decision / Consequences |
| C.3.2 | `architecture-doc-from-code.md` | /reverse-document | 反推架构文档 |
| C.3.3 | `architecture-traceability.md` | /architecture-review（rtm） | 需求-架构追溯矩阵 |
| C.3.4 | `technical-design-document.md` | /create-architecture | 系统级技术设计 |
| C.3.5 | `design-doc-from-implementation.md` | /reverse-document | 反推设计文档 |

**移植洞察**：5 个技术模板包含 ADR 经典格式——业界标准结构，与平台无关。

---

## C.4 美术与音频类 Template（2 个）

| # | Template | 对应 skill | 关键字段 |
|---|---|---|---|
| C.4.1 | `art-bible.md` | /art-bible | **9 节**（与 02 册 art-director 对应） |
| C.4.2 | `sound-bible.md` | /design-system（音频） | 调色板 / 命名 / 混音 |

---

## C.5 UX 与无障碍类 Template（4 个）

| # | Template | 对应 skill | 关键字段 |
|---|---|---|---|
| C.5.1 | `ux-spec.md` | /ux-design | 屏幕级 UX 规格 |
| C.5.2 | `hud-design.md` | /ux-design | HUD 元素 / 状态驱动 |
| C.5.3 | `interaction-pattern-library.md` | /ux-design | 输入模式库 |
| C.5.4 | `accessibility-requirements.md` | /ux-design | **WCAG tier**（与 02 册 accessibility-specialist 对应） |
| C.5.5 | `player-journey.md` | /ux-design | 玩家路径地图 |

实际是 5 个，C.5 类应为 5 项（编号已修正）。

---

## C.6 项目管理类 Template（7 个）

| # | Template | 对应 skill | 关键字段 |
|---|---|---|---|
| C.6.1 | `sprint-plan.md` | /sprint-plan | sprint 模板 + 范围 + 估时 |
| C.6.2 | `milestone-definition.md` | /milestone-review | 里程碑成功标准 |
| C.6.3 | `risk-register-entry.md` | /retrospective | 风险登记册条目 |
| C.6.4 | `post-mortem.md` | /retrospective | 失败后复盘 |
| C.6.5 | `project-stage-report.md` | /project-stage-detect | 阶段进度报告 |
| C.6.6 | `incident-response.md` | （/team-release）| 危机沟通模板 |
| C.6.7 | `concept-doc-from-prototype.md` | /reverse-document | 从原型反推 concept |

---

## C.7 测试与质量类 Template（2 个）

| # | Template | 对应 skill | 关键字段 |
|---|---|---|---|
| C.7.1 | `test-plan.md` | /qa-plan | QA 测试计划结构 |
| C.7.2 | `test-evidence.md` | /test-evidence-review | 测试证据 4 字段 |

---

## C.8 发布类 Template（3 个）

| # | Template | 对应 skill | 关键字段 |
|---|---|---|---|
| C.8.1 | `release-checklist-template.md` | /release-checklist | 平台特定 checklist |
| C.8.2 | `release-notes.md` | /patch-notes | 发布说明 |
| C.8.3 | `changelog-template.md` | /changelog | 内部变更日志 |

---

## C.9 Meta 类 Template（1 个）

| # | Template | 对应 skill | 关键字段 |
|---|---|---|---|
| C.9.1 | `skill-test-spec.md` | /skill-test | Meta 测试 spec |

---

## Part C 横向规律

### 规律 1：38 Template 与 02 册"硬性产出格式"高度重叠

02 册识别了 37 套硬性产出格式（agent 维度），04 册识别 38 个 Template（资产维度）。两个数字接近、内容互证：
- 02 册的"GDD 8 节" = C.2.2 `game-design-document.md`
- 02 册的"Lore Document 5 字段" = C.2.10 + 隐含在 narrative.md
- 02 册的"Level Document 9 字段" = C.2.8 `level-design-document.md`
- 02 册的"Sprint Plan 模板" = C.6.1 `sprint-plan.md`
- 02 册的"Bug Report 模板" = （隐含在 test-plan / test-evidence）
- ...

**结论**：CCGS 的"硬性产出格式"实际是**Template 库的具象表达**——agent 不发明产出格式，而是按 Template 填空。

### 规律 2：38 个 Template 全部与平台无关

100% 是 Markdown 文件，无 Bash / Python / 引擎特异语法。**移植到 CodeBuddy 时零改造**——直接复制到 `.codebuddy/docs/templates/` 即可。

### 规律 3：3 个协作协议 Template 是 02 册"3 套共享 snippet"的现成实现

CCGS 已经把这 3 套协议抽离为模板，但**未让 agent 文件引用它们**——这是 CCGS 自己未完成的优化。**移植到 CodeBuddy 时是必做动作**。

### 规律 4：Template 数量分布反映 CCGS 重心

| 类别 | 数量 | 占比 | 说明 |
|---|---|---|---|
| 设计文档 | 10 | 26% | **最大类别** —— 体现 CCGS 是"design-driven studio" |
| 项目管理 | 7 | 18% | 次大 —— 严肃管理流程 |
| UX/无障碍 | 5 | 13% | accessibility 是一等公民 |
| 架构技术 | 5 | 13% | ADR 文化 |
| 协作协议 | 3 | 8% | 共享 snippet（待 agent 引用） |
| 发布 | 3 | 8% | |
| 美术/音频 | 2 | 5% | |
| 测试 | 2 | 5% | |
| Meta | 1 | 3% | |

**CCGS 的 DNA**：**设计 > 管理 > UX > 架构** —— 设计文档密度最高，体现"先想清楚再写代码"的工程哲学。

### Part C 适配性总表

**所有 38 个 Template = 直接移植，零改造**。

| 类别 | 数量 | 极简 | 标准 | 完整 |
|---|---|---|---|---|
| 协作协议（3）⭐ | 3 | ✅ ✅ ✅ | ✅ ✅ ✅ | ✅ ✅ ✅ |
| 设计文档（10） | 10 | 4 必保（GDD/concept/pillars/systems-index）+ 6 按需 | 8 必保 | 10 全保 |
| 架构（5） | 5 | 1 必保（ADR）| 3 必保 | 5 全保 |
| UX（5） | 5 | 0 | 3 必保 | 5 全保 |
| 美术音频（2）| 2 | 0 | 2 全保 | 2 全保 |
| 项目管理（7）| 7 | 1 必保（sprint-plan）| 5 必保 | 7 全保 |
| 测试（2） | 2 | 0 | 2 全保 | 2 全保 |
| 发布（3） | 3 | 0 | 1 必保（release-notes）| 3 全保 |
| Meta（1） | 1 | 0 | 0 | 1 |

**极简档保留 = 9 个 Template**（3 协议 + 4 设计 + 1 ADR + 1 sprint-plan）  
**标准档保留 = 27 个 Template**  
**完整档保留 = 38 个 Template**（全部）

---

# Part D — 联动关系图与移植路线

## D.1 三类资产的联动闭环

```
┌─────────────────────────────────────────────────────────────┐
│                    Hook（事件触发）                            │
│                                                              │
│  pre-commit ──→ 检查 GDD 8 节 ──→ 引用 design-docs.md (Rule)  │
│                                                              │
│  post-edit  ──→ 检查 JSON ────→ 引用 data-files.md  (Rule)   │
└─────────────────────────────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────┐
│                    Rule（路径作用域）                          │
│                                                              │
│  design-docs.md ──→ 强制 GDD 8 节                             │
│                              │                               │
│                              ▼                               │
│                    引用 game-design-document.md (Template)   │
└─────────────────────────────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────┐
│                  Template（产出模板）                          │
│                                                              │
│  game-design-document.md ──→ skill 填空产出 GDD               │
│                              │                               │
│                              ▼                               │
│                    被 Hook 校验（回到顶端）                     │
└─────────────────────────────────────────────────────────────┘
```

**三类资产形成闭环**：
1. **Template** 提供产出格式
2. **Rule** 强制约束（写时遵循）
3. **Hook** 校验（提交时检查）

任一环节缺失，质量保障就有漏洞。**移植 CodeBuddy 时必须保留这个闭环**——不能只移 Template 不移 Rule，也不能只移 Rule 不移 Hook。

## D.2 三类资产的移植 ROI 排序

| 排序 | 资产类别 | 改造成本 | 价值 | ROI |
|---|---|---|---|---|
| 1 | Templates（38 个） | **0**（直接复制） | 极高（37 套硬性格式） | **极高** |
| 2 | Rules（11 个） | 低（合并为 3 alwaysApply + 5 智能体请求） | 高（质量底线） | **高** |
| 3 | Hooks（12 个，8 个可移植） | 中（settings.json 改写 + Bash 脚本环境） | 中（自动化提示） | 中 |

**移植先后建议**：先 Template → 再 Rule → 最后 Hook。理由是 Template 价值最大且零成本，可以**先获得 ~80% 的硬性格式覆盖**。

## D.3 极简档移植清单（最小可行集）

```
Templates (9):
  - 3 协作协议
  - game-design-document.md
  - game-concept.md
  - game-pillars.md
  - systems-index.md
  - architecture-decision-record.md
  - sprint-plan.md

Rules (4-5):
  - design-docs.md (alwaysApply)
  - gameplay-code.md (合并到 code-standards, alwaysApply)
  - data-files.md (alwaysApply)
  - test-standards.md (alwaysApply)
  - [视项目] ui-code.md

Hooks (4):
  - session-start.sh
  - detect-gaps.sh
  - session-stop.sh
  - pre-compact.sh
```

**总计 17-18 个资产**——这是 CCGS Hook+Rule+Template 体系的"骨架最小子集"。

---

# 04 册总结 —— 5 大移植洞察

## 洞察 1：38 个 Template 是最高 ROI 资产（零成本，极大价值）

直接复制即可获得 CCGS 的 37 套硬性产出格式。**第一阶段移植应优先完成 Template 全量迁移**。

## 洞察 2：3 个协作协议 Template 是 02 册"共享 snippet"的现成解决方案

CCGS 已抽离 3 协议但未让 agent 引用——**移植时让 agent 显式引用，一次性消除 1300 行重复**。

## 洞察 3：Hook 体系移植后保留 2/3 功能（8/12 可移植）

CodeBuddy 的事件机制不全，但**核心 8 个 Hook 都可保留**（上下文管理 + 质量校验）。损失的 3 个（log-agent / log-agent-stop / notify）和 1 个（post-compact）可代偿。

## 洞察 4：Rule 路径作用域损失需用"3 全局 + 5 智能体请求"代偿

11 条 Rule 不能直接移植，但通过**方案 C 混合策略**可保留 80% 价值——3 条核心规则全局生效，5 条专项规则按需激活。

## 洞察 5：Hook + Rule + Template 形成闭环，任一环节缺失质量保障就有漏洞

移植时必须**3 类同时移植**，否则会出现"Rule 强制 GDD 8 节但 Hook 不校验"或"Template 已用但 Rule 未约束"的漏洞。

---

## 04 册资产移植总清单（一表汇总）

| 类别 | CCGS 数量 | 极简档保留 | 标准档保留 | 完整档保留 | 主要损失 |
|---|---|---|---|---|---|
| Hooks | 12 | 4 | 8 | 9 | 3 hook 不可移植（log-agent×2 + notify）+ 1 部分丢失（post-compact） |
| Rules | 11 | 4-5 | 8-9 | 11 | 路径作用域机制丢失，用 alwaysApply + 智能体请求代偿 |
| Templates | 38 | 9 | 27 | 38 | **零损失** |
| **合计** | **61** | **17-18** | **43-44** | **58** | 3 资产丢失，5%-15% 功能影响 |

---

*04 册完成 ✅ —— 12 hook + 11 rule + 38 template 全部拆解完毕。*

*下一步：05_CodeBuddy 移植建议 —— 汇总前 4 册结论，产出能力矩阵、MVS 清单、5 阶段路线图、风险清单、决策辅助表。*


