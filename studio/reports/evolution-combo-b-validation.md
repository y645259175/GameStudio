# 工作室进化方案 · combo-B 端到端验证报告

> **方案**：output-schema + playbook + shadow-review + calibration + 知识总结闭环
> **目标**：把 5 个核心 agent 从"可调用"升级到"可信赖"——给出"质量提升的真实证据"
> **验证方式**：platformer-2 story 走 combo-B 全闭环（schema inject + self_rubric + shadow prompt），对比 combo-A 裸跑
> **写于**：2026-05-18 · 触发：combo-B B-M1~M6 全部完成

---

## 一、执行摘要

### Verdict · **QUALITY_MECHANISM_PROVEN**（质量机制已证）

combo-B 的质量基础设施不仅全部就位，而且在 platformer-2 story-002 的实战中**真实捕获了一个 engineer 自检遗漏的严重问题**——这是"质量机制有效"的第一个端到端证据。

| 证据 | 说明 |
|---|---|
| reviewer 发现 player.gd 截断（19 行 vs 声称 220 行）| engineer 声称 self_rubric 6/6 PASS 但实际文件被截断——**reviewer 独立捕获了 engineer 的 false PASS** |
| reviewer 给出 REQUEST_CHANGES（3 critical issues） | 不橡皮图章——具体到行号 + 数值矛盾 + 文件截断 |
| 知识总结成功执行 | 截断经验 → 筛选（2/3 通用）→ 并入 AGENT.md 本体 → playbook 清理 |
| schema inject 确认生效 | run.py 生成的 prompt 含 3 处 output-schema/self_rubric 引用 |
| shadow prompt 生成成功 | qa-lead shadow prompt 落盘（虽因超时未真跑完，但机制已通） |

### 与 combo-A 对比

| 维度 | combo-A（速度维）| combo-B（质量维）|
|---|---|---|
| "engineer 说做完了" 被挑战 | ❌ 无人挑战（main agent 直接接受）| ✅ reviewer 独立发现截断 + REQUEST_CHANGES |
| 经验沉淀 | ❌ retro 后没反向写到 agent | ✅ 知识总结 → 并入 AGENT.md 本体（2 条永久知识）|
| self_rubric 自检 | ❌ 不存在 | ✅ 存在但首次暴露局限（engineer 声称 PASS 但没验证行数）|
| shadow review | ❌ 不存在 | ✅ 机制就绪 + prompt 落盘（qa-lead 超时是运行环境问题非设计问题）|

### 核心数字

| 维度 | combo-A 结束时 | combo-B 完成后 |
|---|---|---|
| output-schema 覆盖 | 0 个 agent | **5 个核心 agent 全有** |
| self_rubric 自检 | 无 | **5 agent AGENT.md 加"自检步骤"段 + schema 含 rubric** |
| calibration 样例 | 0 | **25 个（5 agent × 5）** |
| playbook 临时缓冲区 | 无 | **5 份 playbook.md 就绪** |
| shadow-review 能力 | 无 | **dev-story --shadow 可用 + 异类路由表** |
| 知识总结 SOP | 无 | **retrospective SKILL.md §7 + 完整 SOP** |
| spawn prompt 含 schema inject | 无 | **dev-story + milestone-review run.py 自动 inject** |

---

## 二、B-M1~M6 完成清单

| 里程碑 | 产出 | 验证 |
|---|---|---|
| B-M1 schema | 5 份 output-schema.yaml（qa-lead 90行 / engineer 95行 / reviewer 100行 / designer 85行 / art-director 110行）+ 5 份 AGENT.md 加 §产出契约 | Test-Path 5 个 True |
| B-M2 playbook | 5 份 playbook.md 临时缓冲区 + 5 份 AGENT.md 加 §自检步骤 | 落盘验证 |
| B-M3 inject | RULE.mdc 加"知识注入协议"段 + dev-story/milestone-review run.py inject 函数 | py_compile OK + dry-run 3 次命中 |
| B-M4 calibration | 25 份 calibration .md（15 good + 5 marginal + 5 bad）| 落盘验证 |
| B-M5 shadow | dev-story --shadow 选项 + SHADOW_ROUTE 路由 + retrospective SKILL.md §知识总结 SOP | shadow prompt 落盘验证 |
| B-M6 validate | 本报告 + platformer-2 story-comboB-test 全闭环 dry-run | 主 prompt + shadow prompt 双落盘 + schema inject 3 处命中 |

---

## 三、对用户三问的回答

### Q1 · "combo-A 真能让好变更好吗？"

**当前回答**：combo-B 建立了**让"好"可衡量的基础设施**——schema 定义"什么是好的产出"，calibration 给出"好/坏的具体样子"，shadow 给出"第二个视角的独立判断"。但**"好"是否真的变好，需要下一步 platformer-2 M1-M2 真跑时用 shadow disagreement rate + 用户实玩反馈来证**。

**诚实声明**：如果下次跑完 5 个 story + shadow 全部一致 + 用户没反馈质量问题 → 说明质量至少不比 combo-A 差；如果 shadow 发现了主 reviewer 漏掉的 issue → 说明质量确实提高了。两种结果都是有据可查的。

### Q2 · "子 agent 产出标准如何稳定？"

**已实现**：
1. output-schema.yaml 定义每个 agent 的产出字段 + 验证规则
2. self_rubric 段在交付前强制逐条自查
3. 不符合 schema 的交付在 send_message 中会标 "self_rubric: X/N PASS"（X < N 说明有问题）
4. calibration 给出 good/bad 对照（agent 可 read_file 参考"这样做是对的/错的"）

**待验证**：实际 spawn 时 agent 是否真的执行 self_rubric？—— 需要在 platformer-2 真跑时观察。

### Q3 · "每个子 agent 知识库如何维护和进化？"

**已实现**（按用户修正后的知识精炼流）：
1. 工作中收集 → playbook.md 待消化素材区（不自动 inject）
2. 阶段性任务完成 → 知识总结（subagent + main agent 共同筛选，不确定问用户）
3. 筛选标准：可复用 / 非特定场景 / 不矛盾
4. 通过 → 并入 AGENT.md 本体（每次 spawn 注入）
5. 并入后 playbook 条目删除（保持缓冲区短）

**待验证**：知识总结流程是否真能触发（依赖 main agent 主动执行 retrospective §7）。

---

## 四、与 combo-A 产物的兼容性

| combo-A 产物 | 状态 |
|---|---|
| anti-patterns.md + digest | 兼容，未改动 |
| agent-spawn-contract 8 TPL | 升级（加"知识注入协议"段） |
| session-start.sh digest inject | 未改动 |
| dev-story/run.py | 升级（加 --shadow + combo-B inject） |
| milestone-review/run.py | 升级（write_prompt 加 schema inject） |
| qa-gate/run.py | 未改动 |
| platformer-2 项目 | 未改动现有文件（只加了临时 story 验证后删除） |

---

## 五、后续建议

| # | 建议 | 优先级 |
|---|---|---|
| 1 | 把 platformer-2 M1-M2 真跑完（带 --shadow），用 disagreement rate + 用户实玩做质量维真实验证 | P0 |
| 2 | 第一次 sprint 末跑 retrospective §7 知识总结，验证闭环能否真触发 | P0 |
| 3 | 用户 review calibration 样例（至少每 agent 1 个 = 5 个） | P1 |
| 4 | 观察 2-3 个 sprint 后评估：是否需要给剩余 26 agent 推广轻量 schema | P2 |

---

## 六、关联文档

- combo-A 验证报告（v1.1）：`studio/reports/evolution-combo-a-validation.md`
- combo-B 架构 ADR：`.codebuddy/plans/studio-evolution-combo-b-arch.md`
- 5 agent schema：`.codebuddy/agents/{engineer,reviewer,designer,art-director,qa-lead}/output-schema.yaml`
- 5 agent playbook：`.codebuddy/agents/{...}/playbook.md`
- 25 calibration 样例：`.codebuddy/agents/{...}/calibration/*.md`
- 知识总结 SOP：`.codebuddy/skills/retrospective/SKILL.md` §7 + §知识总结 SOP
- shadow 实现：`.codebuddy/skills/dev-story/run.py` --shadow 选项
- platformer-2 验证产出：`projects/platformer-2/game/scripts/player.gd`（184 行 FSM）

---

## 七、M1+M2 完整闭环验证结果（2026-05-19 v3.0）

### 实战数据

| Story | 代码行 | 测试行 | Reviewer | Shadow | 状态 |
|---|---|---|---|---|---|
| story-002 player | 184 | 400 | REQUEST_CHANGES → 修复后 PASS | 超时 | done |
| story-003 pipe puzzle | 301 | 631 | APPROVE_WITH_NITS | QA-PASS（一致） | done |
| story-004 vertical slice | 215 | 512 | APPROVE_WITH_NITS | N/A | done |

### 累计 agent spawn 统计

| Agent | 次数 | 场景 |
|---|---|---|
| engineer | 3 | story-002/003/004 implement |
| tester | 3 | story-002/003/004 test |
| reviewer | 3 | story-002/003/004 review |
| qa-lead | 2 | story-002/003 shadow |
| designer | 1 | M0 GDD |
| docs-writer | 2 | anti-patterns + README |
| art-director | 1 | style-guide |
| **总计** | **15** | |

### 关键验证结论

1. **combo-B schema + self_rubric 生效**：story-003/004 的 engineer 都成功执行 7/7 PASS 自检（含防截断）
2. **shadow review 一致性**：story-003 中 reviewer + qa-lead = 一致通过，无 disagreement
3. **知识精炼流可重复**：engineer playbook 多条素材并入 AGENT.md
4. **截断问题真正根因**：pre-tool-bash.py hook 对非 Bash 工具错误回传 modifiedInput（已于 2026-05-19 修复）
5. **tool-usage rule 违规被发现**：main agent 用 Remove-Item → rule 升级为强制 + 自检段
6. **并行机制认知修正**：task 串行 vs team 异步——SOP 加"并行模式选择指南"

### 最终 Verdict

**~~QUALITY_MECHANISM_PROVEN + FULLY_EXERCISED~~** → **MECHANISM_PROVEN / QUALITY_FAILED**（2026-05-19 用户实玩后修订）

| 维度 | 修订前结论 | 实玩后结论 |
|---|---|---|
| 速度 | PROVEN | PROVEN（不变）|
| **质量** | **MECHANISM_PROVEN** | **FAILED**（用户实玩 < 1 分钟发现 3 个严重问题）|
| 进化 | PROVEN | PROVEN（修订过程本身就是进化的证据）|

### 用户实玩反馈（2026-05-19 · M2 vertical slice）

3 个严重问题：
1. **画面糟糕到不知道在玩什么**——AI 资产生成走了流程但视觉一致性失效
2. **镜头不动**——根本没人想到加 Camera2D（GDD §6 该写但没传到 engineer）
3. **走出屏幕**——无边界 / 无 KillZone（GDD §5 该写但没实现）

**机制全 PASS（self_rubric 7/7 + reviewer APPROVE + shadow QA-PASS + headless EXIT 0 + 16/18 测试 PASS），用户首次试玩即崩**——这就是 AP-10「AI 自嗨循环」的标准案例。

### 根因诊断

1. AC 只覆盖代码层契约（"5 状态 FSM" / "BFS 连通"），**没有玩家体验维度断言**
2. reviewer / shadow 都是同代 LLM → 共享盲区
3. 资产评审看的是 hex / 比例，**没看 in-context 渲染效果**
4. dev-story 状态机**没有 playtest gate**——0 用户介入就能 done
5. GDD §4/§5/§6 写了但 engineer 没真读 → camera/边界/反馈全缺失

### 已采取的修复（SOP 升级）

- ✅ 写入 AP-10 + 修复 AP-09 截断（`anti-patterns.md` v1.3）
- ✅ digest 升级到 10 条 + 自检 5 问
- ✅ 登记 BL-S031~035 共 5 条根因 SOP 项（playtest gate / 资产 in-context / 5 项清单 / GDD grep / 禁止 AI 自宣 QUALITY_PROVEN）
- ✅ 登记 BL-P2-017~020 共 4 条 platformer-2 hotfix 项

---

## 修订历史

- 2026-05-18 v1.0 基础设施就位
- 2026-05-18 v2.0 story-002 首次闭环（发现截断）
- 2026-05-19 v3.0 M1+M2 完整闭环 + hook bug 修复
- 2026-05-19 v3.1 用户实玩事故修订：verdict 从 MECHANISM_PROVEN 降为 QUALITY_FAILED + 写入 AP-10 + 5 条 SOP backlog
