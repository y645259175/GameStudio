# ADR · 工作室进化方案 combo-B（攻质量）架构决策记录

> **方案代号**：combo-B —— output-schema + playbook + shadow-review + calibration + retro→playbook 闭环
> **触发**：combo-A SPEED_PROVEN/QUALITY_UNPROVEN 验证报告（v1.1）+ 用户三问（"agent 真能让好变更好吗 / 标准如何稳 / 知识如何进化"）
> **作者**：architect agent（spawn 起草）
> **写于**：2026-05-18
> **状态**：DRAFT（待 main agent 审阅后转 plan_create 关联历史主体）
> **总投入估算**：16 小时（B-M1~B-M6 六个里程碑）

---

## 1 · 背景与问题

### 1.1 现状一句话

combo-A 把"31 agent + 25 skill 99% 摆设"改造为"6 个核心 agent + 3 个 skill 真可调用"——**链路通了**，**但产出可信度未被验证**。这一边界在 evolution-combo-a-validation.md v1.1 的 §一 / §七 已经明文承认：7 项验收全部位于"速度 / 流程"维，质量维 0 项有据可查。

### 1.2 用户三问（必须由 combo-B 给出答案）

| # | 用户原始提问 | combo-B 给出的回答机制 |
|---|---|---|
| Q1 | "combo-A 真能让'好'变得更好吗？" | M3 shadow-review 给独立维度数据 + M6 用 platformer-2 与 bolt-1-1 同位产出做盲测对比 |
| Q2 | "子 agent 产出标准如何稳定？" | M1 output-schema.yaml（每个 agent 一份契约）+ M2 self-rubric 自检 |
| Q3 | "每个子 agent 知识库如何维护和进化？" | M2 playbook.md + M5 retrospective→playbook 反向沉淀闭环 |

### 1.3 不能再添 agent

retro 第九节 + combo-A 后记的核心结论是：**"下一阶段最高价值的工作不是再添 agent，而是把现有 agent 中的 5-10 个核心真正变成可信工具。"** combo-A 已经做完了"可调用"维度，combo-B 必须做完"可信赖"维度，**绝不允许借机扩 agent 数量**。本 ADR 只覆盖 5 个核心 agent（engineer / reviewer / designer / art-director / qa-lead），其余 26 个 agent 在 combo-B 验证通过后再考虑扩。

### 1.4 为什么是这 5 个 agent

- **覆盖了 dev-story 状态机的 4 个关键阶段**（designer 出 GDD → engineer 实现 → reviewer 审 → qa-lead gate），加上 art-director 守视觉红线（bolt-1-1 M6.2 4 帧不一致就栽在这里）
- combo-A 实际 spawn 命中率：engineer 1 次 / reviewer 1 次 / designer 1 次 / art-director 1 次 / qa-lead（间接，通过 qa-gate run.py）—— 5 个全部进入了真实链路
- 产出质量直接决定项目成败（其他如 docs-writer / debugger / refactorer 是辅助流，可以靠这 5 个的 schema 反向约束）

---

## 2 · 决策（5 项措施 + 优先级）

按"成熟度差距 × 杠杆效应"排序（高杠杆先做）：

| # | 措施 | 何为成功 | 优先级 | 杠杆理由 |
|---|---|---|---|---|
| **M1** | output-schema.yaml | 5 个 agent 各有一份产出契约，AGENT.md 引用 schema | P0 | 没有 schema 时 self-rubric 无规则可依，shadow-review 也无对照标准 → schema 是其他 4 项的前提 |
| **M2** | playbook.md + self-rubric | playbook 起步、AGENT.md 加 "交付前必须 self-check schema" 段 | P0 | 让本 sprint 的 agent 直接受益（无须等 retro 才进化） |
| **M3** | spawn-template auto-inject | TPL-XX + run.py 自动把 playbook 头部 + 最近 3 lesson + schema 一同注入 prompt | P0 | 没有自动注入，schema/playbook 永远会退化为"摆设" → 这是 combo-A 教训的直接迁移 |
| **M4** | calibration set | 每 agent 5 个样例（3 good + 1 marginal + 1 bad），25 个共计 | P1 | 是 self-rubric 和 shadow-review 的"对照数据"。但生产 25 个样例 = 整个 combo-B 最重的活，必须最后做 |
| **M5** | shadow-review + retro→playbook 闭环 | 关键产出由异类 agent 二审；sprint 末 retrospective skill 反写 playbook | P1 | 是 combo-A "reviewer 同代 LLM 同盲区"问题的正面回应；retro→playbook 是闭环的最后一环 |

**"playbook 进化机制"被合并进 M5**——它不是独立第 5 项，而是 retro skill 的扩展。算下来正好 5 项措施 = M1 schema + M2 playbook/rubric + M3 注入 + M4 calibration + M5 shadow+retro闭环。

### 2.1 为什么不是平均铺开

- M1 / M3 不做完，M4 calibration 没法写——calibration 的"good/bad"判定必须基于 schema
- M5 shadow 不做完，质量维永远 UNPROVEN——这是用户三问 Q1 的唯一直接答案
- M2 是"农民式"基本功，但成本最低（每个 agent 仅 30 行起步）

---

## 3 · 5 个核心 agent 现状成熟度评估

### 3.1 评估维度（每维 1 分，满分 5）

1. **角色定义清晰度**：domain owned / does not own 是否明确？
2. **决议词汇标准化**：是否有可解析的 verdict 词汇？
3. **历史教训沉淀**：是否有"为什么这样做"的反模式段？
4. **协作协议**：上游 / 下游 / 冲突升级是否写清？
5. **产出契约**：是否定义了产出物的结构 / 字段 / 验收标准？（**这一维 5 个 agent 全部 0 分** —— 是 combo-B 的核心补缺点）

### 3.2 评估表

| Agent | 行数 | 维度 1 | 维度 2 | 维度 3 | 维度 4 | 维度 5 | 总分 | 已有强项（基线） | 缺什么 | combo-B 投入 |
|---|---|:---:|:---:|:---:|:---:|:---:|:---:|---|---|:---:|
| **qa-lead** | 87 | ✅ | ✅ | ⚠️ | ✅ | ❌ | **3.5/5** | Domain Owned/Not Own 完整 + QA-PASS/CONDITIONAL/BLOCK 三 verdict + 上下游协作协议 | output-schema.yaml（gate report 7 字段）+ 5 calibration（已有 bolt-1-1 真实样本可抽）+ playbook.md（仅需补"为什么 1 个 marginal 黑屏可 CONDITIONAL"经验） | **2h** |
| **engineer** | 80 | ✅ | ❌ | ✅ | ⚠️ | ❌ | **2.5/5** | 视觉资产红线（实战教训）+ 绕过决策 SOP + 2 条历史教训具体到事故 | 决议词汇缺（无 IMPL-PASS/BLOCK）+ output-schema.yaml（implementation report：files_changed / tests_added / red_lines_checked / debt_logged 4 字段）+ 5 calibration（bolt-1-1 + platformer-2 story-001 都可抽）+ playbook 升级（把 "历史教训" 段拆出来） | **3h** |
| **reviewer** | 56 | ✅ | ✅ | ⚠️ | ⚠️ | ❌ | **3/5** | 三组决议词汇（REVIEW/MILESTONE/GDD 各 3 档）+ milestone gate 专项扫 5 项 | output-schema.yaml（review report：critical[]/suggestion[]/verdict/evidence_lines 4 字段）+ 5 calibration（含 1 条 bolt-1-1 漏报的 cheat-only 测试 = bad case）+ playbook（沉淀"哪些 ColorRect 算违规、哪些算合法占位"的细分规则） | **3h** |
| **designer** | 46 | ⚠️ | ❌ | ❌ | ❌ | ❌ | **1/5** | 仅有 4 步流程骨架 + skill/rule 引用 | 一切：Domain Owned / Verdict 词汇 / 历史教训 / 协作协议 / output-schema / calibration 全无；platformer-2 GDD 三章 979 行虽被 spawn 出来，但**没有"为什么这样写"的反向沉淀** | **4h** |
| **art-director** | 154 | ✅ | ✅ | ✅ | ✅ | ❌ | **4/5** | Domain Owned/Not Own 完整 + 4 类决议词汇（CONCEPT/BIBLE/PHASE/CHAR-KEY/CHAR-ANIM）+ bolt-1-1 M6.2 4 帧事故的反模式沉淀 + 5 维评审标准 + sprint 截图评审 SOP | output-schema.yaml（visual review report：5_dimensions 各项 score / hex_violations / verdict 字段）+ 5 calibration（bolt-1-1 M6.2 4 帧 = 现成的 1 bad case + platformer-2 style guide = 1 good case） | **3h** |

### 3.3 评估表读法

- **总投入 15h（不含 M5/M6 共占 4h）**：与本 ADR 末尾 §7 总和 16h 不矛盾——§3 仅算 5 个 agent 的 schema/playbook/calibration 个体投入（M1+M2+M4），§7 把 M3 注入工具改造（2h）+ M5 shadow 实施（2h）+ M6 验证（2h）独立列出。重叠在于：M5 retro→playbook 反写逻辑共享 M3 的注入 hook，所以 M5 仅算 2h（不重复算 5 agent 的 playbook 起步）
- **designer 4h 是最重的 agent**：因为它从 1/5 起步，要做的不是"补一段"而是"建骨架"
- **qa-lead 仅 2h** 是合理的：它已经 3.5/5，只缺第 5 维（schema），且 bolt-1-1 已经有 2 份真实 qa-gate 报告可直接抽 calibration

### 3.4 评估表口径声明

- `✅` = 1 分（明确且充分）；`⚠️` = 0.5 分（部分有但不完整）；`❌` = 0 分（缺）
- "总分"按 5 维加权后四舍五入到 0.5 档
- **维度 5（产出契约）5 个 agent 全部 0 分**——这正是 combo-B 全场要补的核心缺口；如果维度 5 已经有，则 combo-B 的核心价值减半
- art-director 行数 154 远高于其他，但**维度 5 仍然 0 分**——印证"长不等于质量契约"，这点本身就是 combo-B 的设计依据

### 3.5 关键洞察（必须采纳）

> **不能给 5 个 agent 同样的骨架。** qa-lead 已经接近完整，只补 schema 和 calibration 即可；designer 几乎从零起，需要先建 Domain Owned + Verdict 词汇再谈 schema。**每个 agent 的投入要按"差距"算，不是按"目标"均摊。** 如果按均摊，结果是 qa-lead 被过度装饰、designer 还是骨架——这正是 combo-B 要避免的"投入分布失衡"风险。

### 3.6 每个 agent 已有可作为 calibration 来源的真实历史

| Agent | 现成 good 来源 | 现成 marginal 来源 | 现成 bad 来源 | 缺口 |
|---|---|---|---|---|
| qa-lead | bolt-1-1 m6 qa-gate verdict（CONDITIONAL）| bolt-1-1 m5 验收（含 4 issue）| 无—— qa-lead 在 bolt-1-1 未真用 | 1 bad 需反向构造（如"漏阻塞 cheat-only 测试"） |
| engineer | platformer-2 story-001 脚手架 / bolt-1-1 story-005 | bolt-1-1 m4 jump 公式实现 | bolt-1-1 项目 A pivot 全 ColorRect = 现成 bad | 0 缺口（bolt-1-1 真实事故覆盖） |
| reviewer | platformer-2 story-001 reviewer verdict（含具体行号支撑）| bolt-1-1 某次 review-changes | bolt-1-1 m5 漏报 cheat-only = bad | 0 缺口 |
| designer | platformer-2 GDD §3 视觉章节（979 行三章中抽段）| bolt-1-1 m1 GDD（含 jump 公式自洽性）| 无—— bolt-1-1 GDD 没正式 fail 过 | 1 bad 需反向构造（如"数值硬编码到代码"违反 data-driven） |
| art-director | platformer-2 style guide（243 行）| bolt-1-1 m6 style guide v1 | bolt-1-1 m6.2 4 帧不一致 = 现成 bad | 0 缺口 |

**结论**：5 个 agent 中只有 qa-lead / designer 各需要 1 个反向构造的 bad case，其他全部可从历史抽——这是 calibration 投入仅 3h 的关键支撑。

---

## 4 · 目录结构决策

### 4.1 终态目录

```
.codebuddy/agents/<name>/
├── AGENT.md              ← 角色定义（保持，但末尾加 schema/playbook/calibration 引用段）
├── playbook.md           ← 知识库（追加式，retro 自动反写）★ 新增
├── output-schema.yaml    ← 产出契约（self-rubric 与 shadow-review 共同对照）★ 新增
└── calibration/          ← 黄金样例 ★ 新增
    ├── good-1-<topic>.md
    ├── good-2-<topic>.md
    ├── good-3-<topic>.md
    ├── marginal-1-<topic>.md
    └── bad-1-<topic>.md
```

### 4.2 关键决策与理由

#### 决策 1 · 用 yaml 不用 json schema 标准

**理由**：

1. **可读性**：agent 自己 read 时，yaml 比 json schema 标准（含 `type / required / properties / patternProperties`）少 30~50% 字符，token 友好
2. **轻量**：本工作室不需要 IDE 校验插件 / CI 断言；yaml 只作"语义对照表"用，由 self-rubric 段口头校验即可
3. **混合内容**：yaml 允许内嵌 markdown 注释（`# ...`），方便每个字段后写"为什么需要 / 错例参考"
4. **拒绝过度工程**：json schema 标准的 `$ref / oneOf / definitions` 在本场景几乎用不到——5 个 agent 各自的 schema 互相独立，不共享类型

**反例**：曾考虑用 json schema 标准，但发现要么得引入 ajv 做校验（违反 retro "不要做不能跑的工具"），要么仍然只是文档（那不如 yaml 简洁）。

#### 决策 2 · calibration 用 .md 不用结构化数据

**理由**：

1. **样例的价值在"为什么 good / 为什么 bad"的解释**，不在格式化字段。比如 reviewer 的 bad case："这条 review 没漏 cheat-only 测试 = 错误，因为该测试改 velocity = 100 直接绕过 input handler" —— 这种解释不是结构化的
2. **markdown 可以直接被 spawn-template 注入到 prompt**，不需要解析步骤
3. **retrospective 反向写 playbook 时**也是写 markdown 段，与 calibration 同格式 → 同一支笔写两处，连贯
4. **每个文件命名约定**：`<good|marginal|bad>-<序号>-<主题>.md`，便于 grep 抽样

**反例**：曾考虑 yaml 数组结构（每个样例一个 yaml object 含 input/output/score），但发现 input 部分本身就是大段 markdown，硬塞 yaml 反而难读；放弃。

#### 决策 3 · AGENT.md 不被 schema/playbook 替代

AGENT.md 仍然是入口（"我是谁、我管什么"），新增的三件套是**支撑**：

- AGENT.md 末尾加一段 `## 产出契约`，引用 output-schema.yaml
- AGENT.md 末尾加一段 `## 知识库`，引用 playbook.md 与 calibration/
- 这样保持向后兼容（旧的 AGENT.md 引用方式不变）

---

## 5 · 进化闭环 SOP（M5 retro→playbook 反写）

### 5.1 闭环流程图

```
sprint 末
   │
   ▼
[retrospective skill 启动]
   │   触发条件：dev-story 多个 story 完成 / milestone-review 给出 pass/conditional verdict
   │
   ▼
[扫描本 sprint spawn 历史]
   │   数据来源：.codebuddy/state/spawn-log.jsonl（combo-A 已建）
   │   字段：agent_name / spawn_time / story_id / verdict / issues_logged
   │
   ▼
[按 agent 分组，识别 lesson]
   │   规则：本次 spawn 涉及的反模式（AP-XX）/ 事故 / 需修复偏差
   │   示例：engineer 在 story-002 重复用 ColorRect 占位 → AP-09 视觉占位漂移
   │
   ▼
[反向写 playbook]
   │   追加到 .codebuddy/agents/<name>/playbook.md 的 "## 历史教训" 段
   │   格式：- 2026-05-XX project-Y story-Z 事故：<现象>。修法：<下次怎么做>。AP 关联：<AP-XX>
   │
   ▼
[下次 spawn 该 agent]
   │   spawn-template 自动 inject：playbook.md 头部（domain）+ 最近 3 条 lesson + output-schema 字段清单
   │
   ▼
[闭环完成]
```

### 5.2 实施改造清单（spawn-template 自动 inject 的具体修改点）

| 文件 | 修改点 | 估算行数 | 难点 |
|---|---|:---:|---|
| `.codebuddy/rules/agent-spawn-contract/RULE.mdc` | TPL-01~08 模板里"知识注入"段从静态 8 条 anti-patterns 升级为：8 AP + **AGENT.md 本体（含已精炼知识）** + output-schema.yaml 字段清单 | ~80 行（8 模板 × 10 行/模板） | 模板写出来 + 给个伪代码示例 inject 怎么做（不强制工具实现） |
| `.codebuddy/skills/dev-story/run.py` | spawn engineer/tester/reviewer 时，prompt 起草段读 `.codebuddy/agents/<name>/AGENT.md`（含精炼知识）+ 拼 output-schema.yaml 字段清单 | ~60 行 | 文件 IO + 简单字符串拼接，无 LLM 调用 |
| `.codebuddy/skills/milestone-review/run.py` | spawn reviewer/qa-lead/architect 三方 prompt 时同上 | ~40 行 | 同上 |
| `.codebuddy/skills/retrospective/SKILL.md`（新逻辑）+ 不强制起 run.py | retrospective skill 末尾增加 "知识总结步骤"：识别本阶段触发的 agent → subagent + main agent 共同筛选可复用 lesson → 通过的并入 AGENT.md 本体 → playbook 中对应条目删除 | ~50 行（仅 SOP，不写代码） | 决定是否做 run.py（暂不做，靠 main agent 在阶段完成时人工触发） |

**总改造成本：~230 行配置 + ~100 行 python**，≈ 2 小时（M3 + M5 注入逻辑共享）。

### 5.3 边界声明（2026-05-18 v1.1 用户修正）

- **retrospective skill 暂不写 run.py**：因为反写逻辑高度依赖 LLM 判断（"哪些算 lesson"），run.py 不调 LLM 的边界（combo-A 洞察 2）会让它沦为"扫日志输出表格"——不如让 main agent 在阶段性任务完成时直接做。
- **playbook 是临时缓冲区，不是永久知识库**：
  1. 工作中收集信息 → 写入 playbook.md "原始素材区"（**不自动注入 spawn prompt**，按需查看）
  2. 阶段性任务完成后发起"知识总结"——由 subagent + main agent 共同筛选，不确定的问用户
  3. 筛选标准：不能注入不可复用的知识 / 不能注入过于特定场景的知识 / 不能注入和项目其他模块矛盾的知识
  4. 通过筛选的知识**并入 AGENT.md 本体**（正式段落，确保每次 spawn 都注入）
  5. 并入后 playbook 中对应条目**删除**（playbook 保持为短的临时区）
- **不需要季度归档机制**（因为总结后会清理，playbook 不会无限增长）
- **200 行硬上限保留**（但正常情况下不会触达——如果经常触达说明"总结提炼"没跟上节奏）

---

## 6 · shadow-review 实施细节

### 6.1 哪些产出必须 shadow

| 产出物 | 必须 shadow？ | 原因 |
|---|:---:|---|
| GDD 章节（design-review 全章 / quick-design 单点） | ✅ 必须 | bolt-1-1 时 jump 公式自洽性靠用户挑出，单 agent 自查无法避免同代 LLM 盲区 |
| commit 前 review verdict（REVIEW-PASS/CHANGES） | ✅ 必须 | combo-A 验证报告 §一 质量盲区第 2 条直接点名 |
| qa-gate verdict（QA-PASS/CONDITIONAL/BLOCK） | ✅ 必须 | release 决策风险最高 |
| milestone-review 三方 verdict | ✅ 必须 | 已经"三方"但都是同代 LLM；shadow 用 producer 视角覆盖 |
| 脚手架 commit（如 platformer-2 story-001 main.tscn 框架） | ❌ 不必 | 风险低 + 量大，shadow 全部会让 token 翻倍 |
| docs-writer 类（README / anti-patterns） | ❌ 不必 | 不直接影响产品质量，节省成本 |
| 数值微调（quick-fix 改 jump_speed 从 580→600） | ❌ 不必 | 风险低 |

### 6.2 shadow agent 选择（异类原则）

避免同质化的关键是**用不同 domain 的 agent 做 shadow**，不要让两个 reviewer 互审：

| 主 agent 产出 | shadow agent | 用什么视角 shadow |
|---|---|---|
| designer GDD 章节 | **reviewer**（不是另一个 designer） | 用代码可实现性视角检查（数值是否可参数化、状态机是否能实现） |
| reviewer code review verdict | **qa-lead** | 用回归矩阵覆盖性视角检查（是否漏了真实输入路径测试断言） |
| qa-gate run.py 给的 verdict | **producer**（兼任 PM 视角） | 用范围 / 时间 / 风险三轴 trade-off 视角检查（是否过度阻塞 / 漏阻塞） |
| art-director 资产 review | **designer** | 用 GDD §3 视觉关键词一致性视角检查（不只看 hex 偏差，看是否符合"魔幻 + 卡通"等抽象关键词） |
| milestone-review 三方 verdict | **architect**（如未在主三方中） | 用结构性影响视角（这个 milestone 通过 / 阻塞会影响哪些 ADR 的前提假设） |

### 6.3 shadow disagreement 处理

```
main agent shadow agent
   │              │
   ▼              ▼
 verdict_main   verdict_shadow
   │              │
   └──────┬───────┘
          ▼
   [二者一致] ─→ 直接采纳（无开销）
          │
          ▼
   [二者不一致]
          │
          ▼
   1. main agent 仲裁（必须 read 两边的 evidence）
   2. 选择采纳哪一方 + 说明理由
   3. 落盘 disagreement-record.md → projects/<name>/reviews/disagreements/<date>-<topic>.md
   4. 如果 disagreement 触及反模式 → 自动入 anti-patterns digest
   5. 升级条件：连续 3 次 disagreement 同一 agent 对 → spawn architect / producer 仲裁 + 写 ADR
```

### 6.4 成本估算与 opt-out

- **每个 milestone 多 spawn 1-2 个 shadow agent**：按 combo-A 经验，每次 spawn ~1.5-30 分钟（reviewer 类 ~1 分钟，designer 类 ~30 分钟）
- **总时间增量约 +20%**：可接受
- **opt-out 选项**：用户在 PROJECT.md 写 `quality_mode: fast` 时，仅 GDD 章节 + qa-gate verdict 必须 shadow，其余降级（默认 `quality_mode: balanced` 全跑）。这条防止某些短期项目（如 game jam）因 shadow 成本而拒绝采纳 combo-B

### 6.5 disagreement-record 模板（落盘字段）

```markdown
# Disagreement Record · <date> · <topic>

- **主 agent**: <name>（verdict: <verdict-main>）
- **shadow agent**: <name>（verdict: <verdict-shadow>）
- **触发场景**: <story-id / milestone / commit-hash>

## 主 agent 证据
- <evidence 1，含具体行号 / hex / 数值>
- <evidence 2>

## shadow agent 证据
- <evidence 1>
- <evidence 2>

## main agent 仲裁
- 采纳：<main / shadow>
- 理由：<具体>
- 是否触及反模式：<AP-XX 或 无>
- 是否升级：<是/否；若是，spawn 哪个 agent>

## 后续动作
- [ ] backlog 入项（如有）
- [ ] anti-patterns digest 更新（如有）
- [ ] playbook 反写（如有）
```

### 6.6 一个具体 disagreement 想象例

> **场景**：platformer-2 story-002 (player.gd) 完成后，
> - reviewer 给 `REVIEW-PASS`（理由：测试 3/3 PASS，覆盖率达标）
> - shadow qa-lead 给 `QA-CONDITIONAL`（理由：测试缺真实输入路径，全是直改 velocity）
>
> **仲裁**：main agent read 测试代码 → 确认 qa-lead 正确（命中 AP-04 cheat-only 测试）→ 采纳 shadow → 退回 tester 补真实输入路径测试 → 落盘 disagreement-record + 更新 reviewer playbook（追加 lesson "对 platformer 类 story 必须显式断言 input handler 被调用"）。

这就是 combo-B 期望的"shadow 救一次场"的真实样态——通过异类 agent 视角，捕捉同代 LLM 的盲区。

---

## 7 · 5 项措施实施顺序与里程碑

### 7.1 里程碑表

| 里程碑 | 内容 | 投入 | 产出 | 依赖 |
|---|---|:---:|---|---|
| **B-M1** | 5 个 agent 写 output-schema.yaml + AGENT.md 末尾加 `## 产出契约` 引用 | **3h** | 5 份 schema 文件 + 5 份 AGENT.md 增量；qa-lead schema 优先（最易 + 现成 calibration 数据） | 无 |
| **B-M2** | 5 个 agent 创建 playbook.md（起步含 domain 段 + 已有历史教训移入）+ AGENT.md 增加 `## 自检步骤`（交付前必须 self-check schema） | **4h** | 5 份 playbook.md 初版（每份 30-80 行）；engineer / art-director 已有教训直接迁移；designer 从零（需 main agent + spawn quick-design 协助拟定 domain） | M1 |
| **B-M3** | 改造 spawn-template + run.py 自动 inject playbook + schema | **2h** | RULE.mdc TPL 模板升级 + dev-story/milestone-review run.py 加 inject 函数 + 单测（spawn 1 个 engineer 验证 prompt 含 schema 段） | M1, M2 |
| **B-M4** | 5 agent calibration set（每个 5 个样例 = 25 个） | **3h** | 25 个 .md 样例文件；优先抽 bolt-1-1 真实历史（M6.2 4 帧 = 现成 bad / story-005 = good 等）；designer 因无历史，需从 platformer-2 GDD 三章生成 + 反向构造 1 bad case | M1（schema 决定 good/bad 判定标准） |
| **B-M5** | shadow-review 实施 + retro→playbook 闭环 | **2h** | dev-story/milestone-review run.py 加 `--shadow` 选项 + 异类 agent 路由表 + retrospective skill SOP 增 §"playbook 反写步骤" | M3 |
| **B-M6** | platformer-2 实战验证 combo-B | **2h** | spawn 1-2 个 story（建议 story-002 player.gd 或 story-005 vertical slice）走 combo-B 全闭环；对比 bolt-1-1 同类 story；落盘 `studio/reports/evolution-combo-b-validation.md` | M1~M5 |
| **合计** | | **16h** | | |

### 7.2 投入上调原因（vs 原估 10h）

- **calibration 比预期重**：原估默认每个样例 10 分钟（直接抽历史），但实测 designer 因无历史得反向构造 + 5 个全要写"为什么 good / bad"解释，每个 ~25 分钟 → 25 × 25min ≈ 10h（最终压缩到 3h 是因为只写最关键的解释，不要过度分析）
- **shadow 实施被原估遗漏**：原估只算了"在 SOP 里写一段"，未算 run.py 路由 + opt-out 配置 + disagreement-record 模板 → 单独算 2h
- **B-M6 验证不能省**：combo-A 的教训是"不真跑就不知道质量维 UNPROVEN"，combo-B 必须用 platformer-2 真做一次盲测对比，否则又会陷入"看起来通了但没证据"

### 7.3 推荐执行顺序

**强烈建议串行 M1→M2→M3→M4→M5→M6，不要并行**。原因：

- M1 不完，M2 self-rubric 没规则可写
- M3 不完，M4 calibration 没法验证（无 schema 怎么判 good/bad）
- M5 shadow 不完，M6 验证报告没数据可写

**例外**：M1 内部 5 个 agent 的 schema 起草可并行 spawn 5 个 designer/architect 子 agent（参考 combo-A 并行 spawn 3 designer 经验，省时 ~50%）

### 7.4 内部并行机会清单（在串行框架下）

| 里程碑 | 内部并行点 | 节省 |
|---|---|---|
| B-M1 | 5 agent schema 由 main agent 并行 spawn 5 个 architect 子 agent，每个负责 1 份 schema | 3h → ~1.5h（受最慢的 designer schema 限） |
| B-M2 | 同上：5 agent playbook 起步并行 spawn | 4h → ~2h |
| B-M4 | 25 个样例可分 5 批，每个 agent 负责自己的 5 个，全程并行 | 3h → ~1.2h（最慢的 designer 限，因含反向构造 bad case） |
| B-M3 / M5 | **不能并行**——run.py 改造涉及共享文件，必须串行 | — |
| B-M6 | **不能并行**——验证本身是端到端的，并行会破坏对照逻辑 | — |

**乐观估算（充分并行）**：16h → ~10-11h，但**强烈不推荐为了省时间过度并行**，因为：

1. 并行 spawn 多 sub-agent 会增加 main agent 的"协调复杂度"
2. M1/M2/M4 的产出彼此交叉引用（playbook 引 schema、calibration 引 schema），并行可能产出"互相不一致"的版本
3. retro 第二节"心理负担太重"的反模式 = 过度并行的另一面

**建议中庸方案**：M1 / M2 / M4 内部 5 agent 并行，但**M1→M2→M4 之间严格串行**。预期总投入 ~12-13h（vs 串行 16h），保留质量底线。

---

## 8 · 风险 + Out-of-scope

### 8.1 三大风险

| 风险 | 触发条件 | 影响 | 缓解 |
|---|---|---|---|
| **R1 · calibration 同质化盲区** | 25 个样例靠当前 LLM 自己生成 → "good 看起来 good 是因为 LLM 觉得 good" | shadow-review 用同类 calibration 后，仍然漏掉真实用户层面的盲区（如 bolt-1-1 4 帧不一致那种） | 强制 ≥ 60% calibration 来自 bolt-1-1 真实历史（不是 LLM 生造）；用户必须人工 review **至少 5 个**（每 agent 1 个）；写 BL-S023 跟踪未人工 review 的样例数 |
| **R2 · shadow review 多耗 token** | 每个 milestone 多 1-2 个 spawn → token 翻 ~20%；某些预算紧张的项目可能拒绝 combo-B | "工具不被用" = 最大失败模式（参考 retro 第二节 99% agent 摆设） | 提供 `quality_mode: fast / balanced / strict` 三档（PROJECT.md 字段）；fast 仅 GDD/qa-gate 必 shadow，其余 opt-out；balanced 默认；strict 全 shadow |
| **R3 · playbook 长成新摆设** | 知识总结节奏跟不上 → playbook 堆满未提炼的原始素材 | 噪声降低 agent 效能；或反过来——main agent 跳过"知识总结"环节，playbook 永远空 | 200 行硬上限保留兜底；正常路径是"收集 → 总结 → 并入 AGENT.md → 删除 playbook 对应条目"；如果连续 2 个 sprint playbook 既没新增也没清理 → main agent 必须自查 + 提醒用户 |

### 8.2 Out-of-scope（明确不做的）

| 不做项 | 不做原因 |
|---|---|
| **不做剩余 26 个 agent** 的 schema/playbook/calibration | 投入产出比低 + 用户认知负担过大；等 5 个核心验证后（B-M6 完成）再扩。预估每个非核心 agent 仅需 ~1h（schema/playbook/calibration 各砍掉 50%），但要等数据说话 |
| **不做 commit-discipline hook 强制** | 属于 combo-A 遗留 BL-S004，与 combo-B 质量主线无关；保留 backlog |
| **不做 token 自动统计 / cost dashboard** | 依赖 IDE 接口（我们无法控制），不在工作室自治范围；保留 BL-S013 长期跟踪 |
| **不做 calibration 自动评分** | "自动评分"等于让 LLM 给 LLM 打分 = R1 同质化的极端版；保留人工 + shadow 双轨 |
| **不做 schema 强制校验工具（ajv 类）** | 参考 §4.2 决策 1，与 yaml 决策一致；schema 仅作"语义对照表"，由 self-rubric 段口头校验 |
| **不做 playbook 全文 RAG 检索** | 5 个 agent × 200 行上限 = 1000 行总量，注入"最近 3 lesson"足够；RAG 增加复杂度无收益 |
| **不做 retrospective→playbook 的 run.py 工具化** | 参考 §5.3，主要逻辑依赖 LLM 判断，不能写成纯 python；观察 2-3 sprint 后再评估 |

### 8.3 不做但建议（保留 backlog）

- BL-S023 (新)：calibration 人工 review 跟踪（5 agent × 至少 1 个 = 5 个样例必须用户读过）
- BL-S025 (新)：26 个非核心 agent 的轻量 schema 推广（依赖 B-M6 验证结论）

---

## 9 · 与 combo-A 产物的兼容性声明

| combo-A 产物 | combo-B 影响 | 行为 |
|---|---|---|
| `studio/docs/anti-patterns.md` + digest | 兼容；retro→playbook 时新增反模式应同步更新 digest | 增量追加，不破坏现有 8 条 AP |
| `agent-spawn-contract/RULE.mdc` 8 个 TPL | 升级（M3）：每个 TPL 注入段从静态 8 AP 升级到"AP + playbook + schema" | 修改不删除，向后兼容 |
| 3 个 run.py（qa-gate / milestone-review / dev-story） | 升级（M3 + M5）：spawn-prompt 起草段加 inject 函数 + 加 `--shadow` 选项 | 不破坏既有 dry-run 能力 |
| `session-start.sh` digest 注入 | 不动（M3 是 spawn-time 注入，与 session-start 是不同时机的两个机制） | 保留 |
| platformer-2 项目（M0 + M1 story-001） | M6 验证基地；新 story 走 combo-B 全闭环 | 不重写已有产出，只在新 story 上验证 |

---

## 10 · 决策快照（给 plan_create overview 抽要）

> 以下段直接可粘贴为 plan body 的 §决策概览：

**Combo-B 用"output-schema + playbook + shadow-review + calibration + retro→playbook 闭环"5 件套，把 5 个核心 agent（engineer/reviewer/designer/art-director/qa-lead）从"可调用"升级到"可信赖"。投入 16 小时分布在 6 个里程碑（M1 schema 3h → M2 playbook 4h → M3 注入 2h → M4 calibration 3h → M5 shadow+retro 2h → M6 platformer-2 验证 2h）。按成熟度分级处理：qa-lead 仅 2h（已 3.5/5），designer 4h（仅 1/5）。最终用 platformer-2 与 bolt-1-1 同位产出做盲测对比，给出"质量提升的真实证据"——这是 combo-A SPEED_PROVEN/QUALITY_UNPROVEN 验证的正面后续。**

---

## 11 · 关联文档

- combo-A 验证报告（v1.1）：`studio/reports/evolution-combo-a-validation.md`
- retro 经验复盘：`studio/docs/retro-bolt-1-1-experience.md`
- 反模式知识库：`studio/docs/anti-patterns.md` + digest
- spawn 模板库：`.codebuddy/rules/agent-spawn-contract/RULE.mdc`
- 三个核心 skill：`.codebuddy/skills/{qa-gate,milestone-review,dev-story}/run.py`
- 5 agent AGENT.md：`.codebuddy/agents/{engineer,reviewer,designer,art-director,qa-lead}/AGENT.md`
- 验证基地：`projects/platformer-2/`（M0 完成、M1 story-001 完成、待 combo-B M6 用新 story 验证）

---

## 修订历史

- 2026-05-18 v1.0 · architect agent spawn 起草初版（DRAFT）
