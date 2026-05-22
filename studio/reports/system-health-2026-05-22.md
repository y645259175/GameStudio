# 工作室基础设施健康体检 · 2026-05-22

> 触发：D 系列渐进披露改造完成后，用户提问"这套 skill / agent / hook 真的在工作吗？是否真带来了更高效更准确的工作？"
>
> 方法：脚本扫描 `.codebuddy/`，对照 `settings.json` 挂载状态、jsonl 日志、项目报告 spawn 痕迹给出客观结论。
>
> 体检脚本：本报告基于一次性脚本生成，未沉淀为常驻 skill（避免过早抽象）。下次体检可重写。

## 一句话结论

**部分真，部分自欺**：3 个挂载 hook + 5 核心 agent calibration + commit-msg lint 真在工作；
但 **18/25 skill 是纯文档（可执行率 12%）**、**26/31 agent 没经过三层化**、**没有任何 agent/skill 调用日志在跑**——这意味着我们其实**不知道系统真实利用率**。

---

## 1. SKILLS · 25 个，可执行率 12%

| 状态 | 数量 | 名单 |
|---|---|---|
| 有 run.py（真可调用）| **3** | dev-story / milestone-review / qa-gate |
| 有 PLAYBOOK 但无 run.py | 6 | art-asset-pipeline / retrospective / scope-check / timiai-image / dev-story / qa-gate |
| **纯文档 SKILL.md**（main agent 只能 read 模仿）| **18** | architecture-decision / consistency-check / create-epics / create-stories / daily-check / design-review / help / new-project / quick-design / quick-fix / release-checklist / review-all-gdds / setup-engine / smoke-check / sprint-plan / start / story-done / story-readiness |

**问题**：纯文档 skill 在 main agent 视角 ≈ 不存在。skill 的核心价值（封装 + 复用 + 强制 SOP）没兑现。

**对应 backlog**：BL-S018（标 partial-done · 实际 12%）

---

## 2. AGENTS · 31 个，仅 5 个完成三层化

| 状态 | 数量 | 名单 |
|---|---|---|
| **CORE + HANDBOOK + ARCHIVE**（完整三层）| **5** | art-director / designer / engineer / qa-lead / reviewer |
| CORE + HANDBOOK | 1 | ux-designer |
| **CORE only**（未三层化）| **25** | architect / debugger / docs-writer / godot-* (5) / pm / postmortem-keeper / producer / qa / refactorer / release-manager / tester / unity-* (5) / unreal-* (5) |

**问题**：D 系列 45% CORE 减少的红利只惠及 5 核心 agent。剩下 25 个 agent 的 CORE 仍混着判例和细则。

**对应 backlog**：未登记，需新增 BL-S（建议 P1）

---

## 3. HOOKS · 4 个真挂载，6 个未启用

### ✅ 真挂载并工作

| 触发点 | hook | 状态 | 证据 |
|---|---|---|---|
| `SessionStart` | `session-start.py` | OK | settings.json 引用 |
| `UserPromptSubmit` | `user-prompt-route.py` | OK · 7 条路由规则 | settings.json 引用 |
| `PreToolUse` | `pre-tool-bash.py` | OK · 5/19~5/22 共 860 行拦截日志 | jsonl 日志 |
| `git/commit-msg` | `pre-commit-discipline.py` | OK · 4 次 commit 全部带 tag 通过 | `.git/hooks/commit-msg` |

### ⚠️ 未启用（设计了但没挂）

| 文件 | 性质 | 影响 |
|---|---|---|
| `log-agent.sh` | 度量 hook · **关键缺失** | **没有 agent / skill 调用日志在跑** |
| `validate-commit.sh` / `pre-commit-lite.sh` | sh 备用 | 无影响（已被 .py 取代）|
| `session-start.sh` | sh 备用 | 无影响 |
| `detect-gaps.sh` / `validate-assets.sh` | 骨架 | 设计已存在但从未启用 |

---

## 4. 历史调用证据 · 没有度量数据

### 现有证据

| 维度 | 数据 |
|---|---|
| pre-tool-bash 日志 | 4 个 jsonl · 共 860 行（2026-05-19/20/21/22）|
| 项目报告 "spawn" 关键词 | **19 次**（5 个文件，platformer-2 + bolt-1-1 实战痕迹）|
| 5 核心 agent calibration | **25 个真实判例**（每 agent 5 个，含 good/bad/marginal）|

### 关键缺失

```
.codebuddy/logs/
  ├── pre-tool-hook-2026-05-19.jsonl  (595 行，PreToolUse 拦截)
  ├── pre-tool-hook-2026-05-20.jsonl  (193 行)
  ├── pre-tool-hook-2026-05-21.jsonl  (67 行)
  └── pre-tool-hook-2026-05-22.jsonl  (5 行)

❌ 没有 agent-spawn-*.jsonl
❌ 没有 skill-call-*.jsonl
```

**这意味着**：
- session-start 设计的"agent_count < 3 警告"段从未触发
- BL-S014（daily-check 自动汇总 spawn 数据）一直是空头支票
- "AI 应该多用 sub-agent" 是猜的，没有反馈环
- 我们其实**不知道**系统真实利用率

**对应 backlog**：BL-S014（open · P2）→ 应升级为 P0（这是元能力问题）

---

## 5. 渐进披露 lint · 全合规

| 项 | 状态 |
|---|---|
| 总文件数 | 91（rule + skill + agent + 文档）|
| safe / notice | 大多数 |
| review / approval（带 OVER_LIMIT_REASON 自审）| 少量 |
| **lint exit code** | **0（PASS）** |

D 系列改造后**没有再退化**。但要注意：lint 只能验证"格式合规"，不能验证"内容是否真该按渐进披露写"。

---

## 6. 推荐行动（按 ROI 排序）

| 优先级 | 任务 | 投入 | 价值 |
|---|---|---|---|
| **P0-A** | 启用 log-agent hook（捕获每次 task spawn / skill 调用 → jsonl）| 1-2h | **元能力**——从此能用数据回答"系统真在工作吗"，所有未来改进有反馈环 |
| **P0-B** | 给 5 个最常用纯文档 skill 加 run.py（consistency-check / story-readiness / smoke-check / quick-fix / story-done）| 2-3h | 可执行率 12% → 32%，能在更多场景真用上 |
| P1 | 26 个非核心 agent 渐进披露改造（CORE 缩到 ≤40 行 + 拆 HANDBOOK）| 2h | 让 D 系列 45% CORE 减少惠及全部 agent |
| P2 | 跑一次手动 "agent 调用统计"作为基线（grep 项目报告）| 30min | 没度量先做手动审计也比没有强 |

---

## 7. 体检结果对应 backlog 调整建议

| backlog | 当前状态 | 建议变动 |
|---|---|---|
| BL-S014 daily-check 汇总 spawn 数据 | open · P2 | **升 P0** 并改写为"启用 log-agent hook + 度量基础设施" |
| BL-S018 25 skill 配 run.py | partial-done | 拆为 P0（5 个最常用）+ P1（剩余 13 个）|
| 新增 BL-S043 | - | "26 个非核心 agent 三层化"（P1）|

---

## 8. 历史教训

> **没有度量的"改进"全是盲飞。**
>
> D 系列重构投入 13h+ 工作量，CORE 注入降 45% ——这是好事。
> 但**没人知道这 45% 的减少是否真的让 sub-agent 工作得更好**，因为我们没有 agent 利用率 / 错误率 / 重复 spawn 率的基线数据。
>
> 下一阶段必须先建度量（log-agent），再谈优化。否则任何"我们的 skill 体系更聚焦了"的话都是空话。

---

## 附录：体检方法可重复

```bash
# 重跑体检（写一次性脚本到 .codebuddy/temp/health_check.py）
python .codebuddy/temp/health_check.py
# 关键检查项：skill run.py 比例 / agent 三层完整度 / hook 挂载状态 / logs 类型分布
```

体检不应作为常驻 skill —— 频率太低（建议每次大改造后 + 每月一次）。
