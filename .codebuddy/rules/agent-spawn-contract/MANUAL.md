# Agent Spawn Contract · MANUAL

<!-- OVER_LIMIT_REASON: 包含 9 个 TPL 模板（每个 ~30-50 行）+ 5 契约详细 + 5 个协议段。
TPL 之间存在交叉引用（TPL-08 / TPL-09 互补，TPL-05 / TPL-11 引用 AP-10/11），拆分会破坏可比照性。
agent 需要使用 spawn 模板时通常一次只读 1 个 TPL，本文已用 §小节分隔便于跳转。
拆分到 9 个独立文件反而增加 read_file 次数（每次 spawn 都要查路径）。 -->

> CORE 见 `RULE.mdc`（5 条契约 + TPL 索引）。本文是详细 SOP / 模板 / 协议。
> 历史演化（combo-A / combo-B / 各 BL 修法）见 `ARCHIVE.md`。

## §契约 1 · 现状注入（Pre-spawn Briefing）

spawn prompt 必须含以下 3 项 read_file 指令（让 sub-agent 自己读，不在 prompt 里贴大段上下文）：

```
请你 read_file 以下文件作为前置上下文：
1. projects/<PROJECT>/PROJECT.md（项目元数据 / engine / stage）
2. projects/<PROJECT>/stories/backlog.md（当前 milestone 阻塞项）
3. .codebuddy/agents/<你自己>/AGENT.md（Domain Owned / Does NOT Own / 红线）
```

**反模式**：main agent 在 prompt 里手贴 PROJECT.md 全文 → 浪费 ~500 字符且不复用。

## §契约 2 · 任务模式声明（Task Mode）

prompt 头部必须明示模式之一：

| Mode | 含义 | 典型场景 |
|---|---|---|
| `DRAFT` | 新建文件 | story 实现 / GDD 起草 |
| `REFINE` | 在现有文件上改进 | GDD 二轮 / 代码 refactor |
| `PATCH` | 局部修复 | bug fix / hotfix |
| `REVIEW` | 不写文件，只审 | code review / asset review / milestone gate |

加上 `Output path` 和 `Output mode: new_file / append / replace`。

## §契约 3 · 交付-关闭顺序（Delivery Before Shutdown）

sub-agent 必须先 `send_message(type="message")` 交付内容，main agent 确认后才能 shutdown。

```
1. send_message(type="message", content="交付摘要 + 产出路径 + self_rubric 结果")
2. 等 main agent ACK
3. send_message(type="shutdown_response", approve=true, reason="任务完成")
```

**反模式**：直接 shutdown，main agent 不知道交付了什么。

## §契约 4 · 落盘强制（Persistence Required）

产出 ≥ 50 行的内容必须落盘到指定 `Output path`，不允许只在 send_message 内联返回。

50 行以下的简短产出（如 review verdict）可 inline。

## §契约 5 · 文件操作必须用 IDE 工具

- 删文件：`delete_file` 工具，**禁止** `Remove-Item` / `rm` / `del` 命令行
- 读文件：`read_file`
- 写文件：`write_to_file`
- 局部改：`replace_in_file`
- 移动 / 改名：用 IDE 工具或 `Move-Item`（命令行 Move-Item 不被特殊拦截）

详见 `tool-usage-no-popup` rule。

## §知识注入（combo-B v2.0+）

spawn 5 个核心 agent（engineer / reviewer / qa-lead / designer / art-director）时强制在 prompt 加这段：

```
## 你的产出契约与自检（combo-B 强制）
1. read_file `.codebuddy/agents/<AGENT_NAME>/output-schema.yaml` — 产出字段 + self_rubric
2. read_file `.codebuddy/agents/<AGENT_NAME>/AGENT.md` § 自检步骤 + § 产出契约
3. 交付前必须跑 self_rubric 自查，全过后在 send_message 中标 `self_rubric: N/N PASS`
4. 工作中如发现新经验 → 追加到 `.codebuddy/agents/<AGENT_NAME>/playbook.md` 待消化区
```

**自动注入**：dev-story / milestone-review run.py 在 prompt 末尾自动追加此段（参 BL-S017）。

**不注入 playbook 全文**：playbook.md 是临时缓冲区（按需查看），spawn prompt 不含 playbook 内容。

## §并行模式选择

| 模式 | 语法 | 行为 | 适用 |
|---|---|---|---|
| **同 batch 多 task** | 一次 message 发多个 task 调用（无 name 参数） | IDE 并发执行，main agent 等全部完成才继续 | 独立无依赖任务 |
| **team 模式** | task 带 `name` + `team_name` 参数 | 异步 spawn 立即返回，成员 send_message 协作 | 有依赖 / 需隔离 / 需协作 |

**必须用 team 模式的场景**：
1. milestone-review 三方：producer 依赖 qa-lead + reviewer 子报告
2. shadow-review：reviewer + shadow 必须完全隔离判断
3. 长链依赖协作（engineer → tester → reviewer 中间需 send_message 协调）

**可以用 batch task 的场景**（独立互不干扰）：
1. GDD 多章节并行起草
2. calibration 样例批量生成
3. 多个独立文档同时起草

## §防截断协议（v3 · 2026-05-19 hook 修复后）

> 根因已修复（pre-tool-bash.py hook bug，BL-S023 done）。本协议作防御性兜底。

1. 写完后 `read_file` 验证行数：实际 < 预期 80% → 用 replace_in_file 追加补全
2. 不强制分段写（hook 修复后长文件可一次写完）
3. self_rubric `[防截断]` 条目降为"建议检查"——read_file 确认完整即 PASS

## §Shadow Spawn 参数

shadow agent 的 task 调用建议加 `max_turns` 防超时：
- shadow agent（只读 review）：`max_turns: 10`
- 主 agent（写文件 + 验证）：`max_turns: 20`
- 长任务（GDD 起草 / 多文件实现）：`max_turns: 30`

超时后 shadow 未产出 verdict → main agent 记录 "shadow timeout" 但不阻塞主流程。

## §项目上下文自动注入（BL-S017）

任何 sub-agent 在项目内执行任务时，spawn prompt 头部必须含：

```
## 项目上下文自检（必读，做任何事之前先跑）
请 read_file 以下作为前置上下文：
1. projects/<PROJECT>/PROJECT.md
2. projects/<PROJECT>/stories/backlog.md "未排期" 段
3. .codebuddy/agents/<你>/AGENT.md § Domain Owned / Does NOT Own / 历史教训

## 强制约束（来自 anti-patterns）
- AP-07：删文件用 delete_file，禁止 Remove-Item / rm / del
- AP-09：写完长文件 read_file 验行数 < 80% 视为截断需补全
- AP-10：vertical slice 必须含 camera/边界/视觉/反馈/完成 5 项；AI verdict 加 _MECHANISM 后缀
- AP-11：资产看不到先诊断 transform 链 / @export / z_index
```

**节省**：每次 spawn 不必手贴 PROJECT.md 内容（~500 字符）。

---

## §高频 Spawn 模板库（TPL-01~09）

### 模板索引

| ID | 用途 | Subagent | 何时用 | 输出路径 |
|---|---|---|---|---|
| TPL-01 | 实现单个 user story | `engineer` | story 进 implementing 状态 | story 关联 game/scripts/* |
| TPL-02 | Milestone gate 三方综合 | `qa-lead` + `producer` + `reviewer` | milestone 推进前 | `projects/<name>/reports/milestone-*.md` |
| TPL-03 | GDD 章节起草 / 精修 | `designer` | M0 / GDD 修订 | `projects/<name>/gdd/gdd-N-*.md` |
| TPL-04 | 回归 bug 根因排查 | `debugger` | 用户反馈 / 测试失败 ≥ 2 次 | inline + 修复建议 |
| TPL-05 | 资产入库前评审（v2 in-context）| `art-director` | 新资产批次入库前 | `projects/<name>/reports/art-review-*.md` |
| TPL-06 | 跨 chapter 一致性审 | `reviewer` | GDD 多章定稿后 | `projects/<name>/reports/consistency-*.md` |
| TPL-07 | 测试用例编写 | `tester` | implement 完成后 | `projects/<name>/qa/tests/test_*.gd` |
| TPL-08 | Commit 前 code review | `reviewer` | 大改动 commit 前（≥ 100 行 / ≥ 5 文件）| inline |
| TPL-09 | Vertical Slice 5 项清单评审（AP-10 修法）| `reviewer` | vertical slice / playable level story 进 reviewing 时 | inline AP10-PASS/PARTIAL/FAIL |

### TPL-01 · 实现单个 user story

**何时用**：story 状态从 ready → implementing 时由 main agent spawn engineer 实现。
**Subagent**：`engineer`

```
你是 engineer agent。本次任务：实现 story-<ID>。

## 任务模式: DRAFT
## Output paths（必须落盘）:
  - <主文件>
  - <场景 / 数据文件>
## Output mode: new_file

## 现状注入
- read_file projects/<PROJECT>/stories/<STORY>.md（story 全文）
- read_file projects/<PROJECT>/gdd/<对应 GDD 章节>.md
- read_file projects/<PROJECT>/PROJECT.md（engine / stage）
- read_file 现有相关代码（不重复造轮子）

## 实现约束
- 严格按 story AC-1~AC-N 实现
- 数值用 @export（data-driven），不硬编码
- engine_check 必须 EXIT 0（运行 godot --headless --check-only）
- ≥ 100 行 → 标 needs_review: true

## combo-B 产出契约
- read_file `.codebuddy/agents/engineer/output-schema.yaml`
- read_file `.codebuddy/agents/engineer/AGENT.md` § 自检步骤
- self_rubric N/N PASS 才能交付（含 [防截断] 验证落盘行数）

## 交付协议
1. 落盘所有文件 + headless EXIT 0
2. send_message(content="files_changed=...; AC=N/M; engine_check=0; needs_review=...; self_rubric=N/N PASS; verdict=IMPL-COMPLETE/PARTIAL/BLOCKED")
3. shutdown_response approve=true

## 不允许
- ColorRect 不标 _PLACEHOLDER_（AP-04）
- 不跑 headless check 就交付
- 数值硬编码
- 跳过 self_rubric
```

### TPL-02 · Milestone gate 三方综合判断

**何时用**：milestone 推进前（如 pre-production → production）。
**Subagent**：`qa-lead` + `reviewer`（独立 spawn 拿子报告）→ `producer`（综合）

> ⚠️ **必须 team 模式**：producer 依赖前两方 send_message 子报告（见 §并行模式）。

3 个 prompt 模板见 `milestone-review/run.py` 自动生成（推荐入口：`python .codebuddy/skills/milestone-review/run.py --project <p> --from <a> --to <b>`）。

### TPL-03 · GDD 章节起草 / 精修

**Subagent**：`designer`

```
你是 designer agent。本次任务：起草 / 精修 GDD §N <章节标题>。

## 任务模式: DRAFT 或 REFINE
## Output path: projects/<PROJECT>/gdd/gdd-N-<slug>.md

## 现状注入
- read_file projects/<PROJECT>/PROJECT.md（pillars / stage）
- read_file projects/<PROJECT>/gdd/gdd-1-overview.md（世界观基线）
- read_file 上下文 GDD 章节（避免概念冲突）

## 必须 8 节齐全
1. 章节目标
2. 玩家路径 / 核心循环
3. 数值规范（≥ 5 个具体值，无 [TBD]）
4. UX 反馈
5. 边界处理（≥ 3 边界场景）
6. 性能指标
7. 系统接口（引用其他章节具体段落）
8. 交付验收 checklist（≥ 3 项）

## 决议词汇
- DESIGN-COMPLETE / DESIGN-DRAFT / DESIGN-BLOCKED

## 反模式提醒
- 不可凭空创作（必须基于 PROJECT.md pillars）
- §3 不允许 [TBD] 占位
- §7 引用必须具体到段落标题，不能笼统"见§X"
```

### TPL-04 · 回归 bug 根因排查

**Subagent**：`debugger`

```
你是 debugger agent。本次任务：诊断 <现象描述>。

## 任务模式: REVIEW（不修代码，只给根因 + 修法建议）
## Output: send_message inline 5 段产出

## 现状注入
- 用户反馈 / 测试失败 log 全文
- 关联代码 / 场景文件

## 5 段产出
1. 现象复现步骤
2. 根因分析（含 stack / log 证据）
3. 修法建议（具体到 file:line）
4. 回归测试建议
5. 是否需升级到 anti-patterns（新模式触发？）

## 不允许
- 不给具体证据（必须 file:line / log 行）
- "可能是 X" 等模糊推测
- 直接改代码（→ 升级 spawn engineer）
```

### TPL-05 · 资产入库前评审（v2 · AP-10 修法加 in-context 渲染强制）

**何时用**：art-asset-pipeline 产出新批次资产，入库 / commit 前。
**Subagent**：`art-director`

> ⚠️ **强制变更（AP-10 修法）**：单独看 raw 资产 PNG 不算 in-context 评审。**必须**有"资产在游戏内实际渲染的截图"作为评审输入。

```
你是 art-director agent。评审 <ASSET_BATCH_DESC> 批次资产。

## 任务模式: REVIEW
## Output path: projects/<PROJECT>/reports/art-review-<DATE>-<batch-slug>.md

## 现状注入（必读）

### A. Raw 资产
- list_dir <ASSETS_DIR>
- read_file 每张 raw png

### B. In-context 游戏内渲染截图（强制）
- 让 main agent 跑 studio/templates/godot-screenshot/ 生成 capture_*.png 至少 3 张
- read_file 每张 in-context 截图
- **没有截图 → REJECT 任务，要求 main agent 先生成**

### C. 风格基线
- read_file projects/<PROJECT>/art/style-guide.md
- read_file 关联 .tscn（看节点类型 + z_index）
- read_file anti-patterns.md AP-03 / AP-04 / AP-10 / AP-11

## 评审 6 维（每维 PASS/MINOR/FAIL + 引用 in-context 截图）
1. 风格一致性 + 截图中各资产是否协调
2. 尺寸 / 像素密度 + 截图中实际大小对比
3. 背景透明 / 渲染层 + 截图中是否有遮挡 / transform 链断裂
4. 命名规范
5. 可访问性 / 对比度 + 截图中前景/背景对比 ≥ 4.5:1
6. 元数据完整 (.import) + 截图中真实显示而非 fallback

## 强制诊断（AP-10 修法）
任何资产应出现但没出现 → 必须诊断（顺序）：
1. node 类型 (Node vs Node2D)
2. @export 字段是否齐全
3. z_index / CanvasLayer
4. scene 配置 vs 脚本默认值的覆盖关系
诊断结果必须写入 reject_remediation。

## 综合 verdict
- AD-APPROVE（5 维全 PASS + .import 全 true + 截图所有资产可见）
- AD-MINOR-ISSUES（准入但记 backlog VISUAL_DEBT）
- AD-REJECT（必须列 reject_remediation）

## 不允许
- 仅看 raw 资产就给 AD-APPROVE
- 跳过"为什么资产不渲染"的诊断
- "看上去合理" 等空泛措辞
```

### TPL-06 · 跨 chapter 一致性审

**Subagent**：`reviewer`

```
你是 reviewer agent。审 GDD §1~§N 多章节一致性。

## 任务模式: REVIEW
## Output path: projects/<PROJECT>/reports/consistency-<DATE>.md

## 现状注入
- read_file 全部 GDD 章节
- read_file PROJECT.md（pillars 是基准）

## 检查 5 类不一致
1. 数值矛盾（同一指标多章不同值）
2. 命名漂移（同一概念多章异名）
3. 时序冲突（A 章前置依赖 B 章产出）
4. pillars 偏离（某章违背 PROJECT.md 三大支柱）
5. 接口断链（A 章引用 B 章不存在的段落）

## 综合 verdict
- ALL-CONSISTENT / MINOR-DRIFT / MAJOR-CONFLICT
```

### TPL-07 · 测试用例编写

**Subagent**：`tester`

```
你是 tester agent。为 story-<ID> 编写测试。

## 任务模式: DRAFT
## Output path: projects/<PROJECT>/qa/tests/test_<slug>.gd

## 现状注入
- read_file story md
- read_file 实现代码（engineer 刚落盘）

## 测试覆盖必须包含（test-standards rule + dev-story 红线）
1. happy path: AC-1~AC-N 每条 ≥ 1 测试
2. edge case
3. **真实玩家路径测试（红线）**: ≥ 2 条用 Input.action_press / action_release 模拟，禁止直接 set velocity / state

## engine check
跑 godot --headless --script <test 文件> --quit，EXIT 0 + stdout 含 PASS

## 不允许
- 只写 cheat-mode 测试
- 直接 set 内部状态作为唯一手段
- 跳过 edge case
```

### TPL-08 · Commit 前 code review

**Subagent**：`reviewer`

```
你是 reviewer agent。Code review 本次改动。

## 任务模式: REVIEW
## Output: send_message inline 评审 verdict + 修改清单（不必落盘）

## 现状注入
- read_file 全部改动文件
- read_file 关联 story md / GDD 章节
- 检查 commit msg 草稿

## 评审 4 维（每维 PASS/FAIL + ≥1 evidence 行号）
1. correctness — AC 覆盖 / 数值与 GDD 一致
2. risk — 全局状态 / 性能热点 / 命名冲突
3. style — snake_case / @export / 注释
4. test_quality — 含 action_press 真实输入 / edge case

## 综合 verdict
- APPROVE / APPROVE_WITH_NITS / REQUEST_CHANGES

## 不允许
- "看起来没问题"（必须给具体行号 + 理由）
- 评审 > 30 分钟（拆成多次小评审，每次 ≤ 200 行 diff）
```

### TPL-09 · Vertical Slice 5 项清单评审（AP-10 修法）

**何时用**：任何 vertical slice / playable demo / 完整 level / 可玩关卡 story 进入 reviewing 阶段时**必跑**。
**Subagent**：`reviewer`（聚焦"玩起来对不对"维度，与 TPL-08 代码维度独立）

```
你是 reviewer agent。本次任务：vertical slice 5 项清单评审（AP-10 修法）。

## 任务模式: REVIEW
## Output: send_message verdict + 5 项 checklist 结果
## 不允许简化或跳过任一项——每项缺失 → REQUEST_CHANGES

## 现状注入
1. read_file 关卡场景：projects/<PROJECT>/game/scenes/levels/<LEVEL>.tscn
2. read_file 玩家场景：projects/<PROJECT>/game/scenes/player.tscn
3. read_file 关卡管理：projects/<PROJECT>/game/scripts/level/level_manager.gd
4. read_file GDD §4 UX / §5 边界 / §6 性能

## 5 项强制 checklist

### 1. Camera2D 跟随玩家
- grep player.tscn 或 level_*.tscn 是否含 [node ... type="Camera2D"]
- 必须含 position_smoothing_enabled = true（或注释说明为何不要）
- 必须含 limit_left/top/right/bottom

### 2. 屏幕/世界边界
- level_*.tscn 必须含至少：左/右边界 StaticBody + 底部 KillZone Area2D
- KillZone 触发后必须有反馈（重置位置 / 屏幕 fade / print）

### 3. 主角视觉辨识度
- 主角 sprite 与 ground/背景 对比度 ≥ 4.5:1
- 必须有 1px 描边或显著轮廓

### 4. 死亡/失败反馈
- KillZone + respawn 逻辑
- 至少 print log "[killzone] respawned"

### 5. 完成/胜利反馈
- GoalArea (Area2D) + body_entered
- LevelManager emit level_completed signal + 至少 print 提示

## 综合 verdict
- AP10-PASS（5 项全 PASS）
- AP10-PARTIAL（4 PASS + 1 MINOR，列 minor + ETA）
- AP10-FAIL（≥1 FAIL → REQUEST_CHANGES 退回 implementing）

## 后续动作
- AP10-PASS → main agent 跑 dev-story --action playtest 进入用户实玩
- AP10-FAIL → 退回 reviewing，开 hotfix 子任务
```

---

## §模板使用统计建议

每个 milestone gate 时检查：
- 9 个 TPL 中调过 ≥ 5 个 → 健康
- < 3 个 → 中招 AP-01 / AP-02

## §与 anti-patterns 的映射

- TPL-01 现状注入 → AP-02 反模式修法（不让 main agent 重复贴上下文）
- TPL-02 三方 → AP-01 修法（强制 spawn）
- TPL-04 → AP-06 修法（用户反馈触发结构化 RCA）
- TPL-05 v2 → AP-10 / AP-11 修法（in-context 渲染强制）
- TPL-09 → AP-10 修法（vertical slice 5 项清单）

## §spawn 前自检清单（8 项全过）

- [ ] 已 read 现状文档？
- [ ] 已在 prompt 注入现状（路径 + 关键内容）？
- [ ] 已声明 mode（DRAFT / REFINE / PATCH / REVIEW）？
- [ ] 已指定 output_path + output_mode？
- [ ] 已说明"先发 message 再 shutdown"协议？
- [ ] 已说明"落盘到指定路径"要求？
- [ ] 已包含"文件操作必须用 IDE 工具，禁止 Remove-Item/rm/del"约束？（契约 5）
- [ ] 已包含"写完后 read_file 验证行数 + 防截断"要求？（AP-09）
