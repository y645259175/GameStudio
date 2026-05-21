# 渐进披露架构 · D 系列验证报告

> 2026-05-20 v1.0
> 触发：rule/skill/agent 文档体积失控（rules 1523 / skills 2477 / agents 2089 = 总 ~6000 行 ~200KB），sub-agent spawn 时上下文被无关信息占用。
> 决策：用户 + main agent 共同设计三层渐进披露架构（CORE / MANUAL / ARCHIVE）+ 分级提醒红线机制。

## Verdict · **GOAL_ACHIEVED**（三大目标全部达成）

| 目标 | 改造前 | 改造后 | 验证 |
|---|---|---|---|
| 1. 渐进披露 | 全部塞 CORE，平均 ~70 行 / 文件 | CORE 平均 ~30 行，详细 SOP 入 MANUAL，历史入 ARCHIVE | lint exit=0，所有文件分层合规 |
| 2. 准确输入 | agent 看 765 行 spawn-contract 才知道用哪个 TPL | CORE 28 行带索引，agent 按需 read MANUAL §TPL-XX | TPL 索引 + 跳转指引齐全 |
| 3. 进化有边界 | 只能凭自觉，反复滑坡（agent-spawn-contract 116 → 765 行的演化是反例）| 分级提醒 lint + commit-msg hook 强制 | 已集成到 pre-commit-discipline.py |

## 6 个里程碑成果

| 里程碑 | 内容 | 关键产出 |
|---|---|---|
| **D-M1 基础设施** | lint 工具 + commit hook 集成 + 6 个三件套模板 + 架构文档 | `.codebuddy/scripts/check_progressive_disclosure.py`（166 行）+ `studio/templates/progressive-disclosure/` 6 文件 + `studio/docs/progressive-disclosure-architecture.md` |
| **D-M2 anti-patterns 样板** | digest 36 (CORE) + manual 258 (MANUAL) + archive 150 (ARCHIVE) | 三层分离 = 全工作室复刻样板 |
| **D-M3 rules 改造** | 10 个 rule 全部合规：3 个重灾区拆三层，3 个加 OVER_LIMIT_REASON，4 个本身合规 | agent-spawn-contract 765→28+475+115 / tool-usage 127→44+80+40 / patches 163→26+89 |
| **D-M4 skills 改造** | 25 个 skill：6 个重灾区拆三层，19 个加 OVER_LIMIT_REASON 或本身合规 | timiai-image 776→68+234+169（**最大节省 -676 行**）/ qa-gate 142→46+108 / dev-story 89→48+78 |
| **D-M5 agents 改造** | 31 个 agent：6 个核心拆三层，14 个加 OVER_LIMIT_REASON，11 个本身合规 | art-director 170→52+170 / designer 130→53+130 / engineer 102→59+102 |
| **D-M6 验证** | session-start.py 加渐进披露指引 + 体积对比 + 本报告 | lint exit=0 / CORE 减少 45.2% |

## 分级提醒机制（红线）

| 区 | 阈值（rule/skill）| 阈值（agent）| 阈值（MANUAL）| 动作 |
|---|---|---|---|---|
| 🟢 safe | ≤30 | ≤40 | ≤150 | lint 静默 |
| 🟡 notice | 31-50 | 41-60 | 151-250 | 写日志 / hook 输出 NOTE |
| 🟠 review | 51-80 | 61-100 | 251-400 | 必须 `<!-- OVER_LIMIT_REASON: ... -->` 自审 |
| 🔴 approval | 80+ | 100+ | 400+ | 必须用户 `[layer-override]` commit tag（除非已自审通过）|

**用户决策（关键）**：拒绝硬上限（避免反向激励 agent 凑数）+ 拒绝季度归档（机制不生效）→ 改用分级提醒，让超限是**显性的"知情决定"**而非**隐性的"违规"**。

## CORE 体积对比（git HEAD vs 现工作区）

24 个关键 CORE 文件总行数：**2692 → 1474（减少 1218 行 / 45.2%）**

| 类别 | HEAD | CUR | 减少 |
|---|---|---|---|
| Rules（10 个）| 824 | 577 | -247（-30%）|
| 5 核心 agent CORE | 523 | 317 | -206（-39%）|
| 重灾区 skill CORE | 1345 | 286 | **-1059（-79%）** |
| anti-patterns 三件套 CORE 部分 | 0 | 36（digest）| 新增 |

**最大单点节省**：timiai-image SKILL.md 776 → 68 行（节省 -676 行 / -88%）。

## 已落地的红线机制（防止再次滑坡）

1. **lint 工具**：`python .codebuddy/scripts/check_progressive_disclosure.py`
   - 扫所有 rule/skill/agent CORE + MANUAL/PLAYBOOK/HANDBOOK
   - 输出按区分类 + 是否有 OVER_LIMIT_REASON 标注
   - exit code: 0 全过 / 1 review 区无 reason / 2 approval 区无 reason 且无 [layer-override]
2. **commit-msg hook 集成**：`.codebuddy/hooks/pre-commit-discipline.py`
   - tag 检查通过后自动调 lint
   - lint 失败 → 阻塞 commit + 给具体修复建议
3. **OVER_LIMIT_REASON 自审注释**：超 review 阈值时 agent 自己解释为何必须超限，强制思考"是否真值得超"
4. **[layer-override] commit tag**：approval 区无 reason 时强制用户介入

## 文件分层结构（最终）

```
.codebuddy/
├── rules/<name>/
│   ├── RULE.mdc              ← CORE（红线 + 索引）
│   ├── MANUAL.md              ← 详细 SOP（按需）
│   └── ARCHIVE.md             ← 历史判例（仅 RCA）
├── skills/<name>/
│   ├── SKILL.md               ← CORE（触发 + 入口 + 红线）
│   ├── PLAYBOOK.md            ← 详细 SOP（按需）
│   └── ARCHIVE.md             ← 历史 / 弃用
├── agents/<name>/
│   ├── AGENT.md               ← CORE（Domain + 协作 + 红线 + 契约）
│   ├── HANDBOOK.md            ← 详细流程 / 决议词汇
│   ├── ARCHIVE.md             ← 历史判例
│   ├── output-schema.yaml     ← 产出契约（保持不变）
│   ├── playbook.md            ← 临时缓冲区（保持不变）
│   └── calibration/           ← 黄金样例（保持不变）
└── scripts/
    └── check_progressive_disclosure.py
studio/
├── docs/
│   ├── progressive-disclosure-architecture.md  ← 架构总文档
│   ├── anti-patterns-digest.md                 ← CORE 样板
│   ├── anti-patterns.md                        ← MANUAL 样板
│   └── anti-patterns-archive.md                ← ARCHIVE 样板
└── templates/progressive-disclosure/           ← 三件套模板
```

## 风险与未尽事项

### R1 · MANUAL 之间存在交叉引用，拆分破坏可比照性

agent-spawn-contract MANUAL 480 行（含 9 个 TPL 互相引用）触 approval 区。决策：保留 + OVER_LIMIT_REASON。备选方案：拆为 9 个独立 TPL-XX.md，但反而增加 read_file 次数。**待观察实战效果，1-2 个 sprint 后回评是否需要拆**。

### R2 · 部分 agent 旧 AGENT.md 已搬到 HANDBOOK，丢失了 frontmatter

5 个核心 agent 的 HANDBOOK.md 是从 AGENT.md 改名而来，仍含 `---` frontmatter（CodeBuddy 不会因此误识别——HANDBOOK.md 不是 agent 入口文件）。但建议下次清理 frontmatter 减少混淆。

### R3 · 5 核心 agent 的 ARCHIVE.md 尚未建

CORE 中提到"详细判例 → ARCHIVE.md（待建）"，但实际未建（HANDBOOK 中已含历史教训段）。建议下次有历史教训积累时再建（不现在凭空创作）。

### R4 · UserPromptSubmit hook 关键词路由未更新

`user-prompt-route.py` 当前的关键词触发是基于旧文档结构（如"美术任务 → timiai-image SKILL.md 全文"），改造后应该指向 PLAYBOOK 具体段（"美术任务 → SKILL.md CORE + PLAYBOOK §1 五步工作流"）。**已加入 backlog BL-S041**。

## 关联文档

- 架构文档：`studio/docs/progressive-disclosure-architecture.md`
- lint 工具：`.codebuddy/scripts/check_progressive_disclosure.py`
- commit hook：`.codebuddy/hooks/pre-commit-discipline.py`
- 三件套模板：`studio/templates/progressive-disclosure/`
- session-start hook：`.codebuddy/hooks/session-start.py`（已含三层结构指引）
- 样板：`studio/docs/anti-patterns{,-digest,-archive}.md`

## 修订历史

- 2026-05-20 v1.0 初始版本（D-M1~M6 完成时落盘）
