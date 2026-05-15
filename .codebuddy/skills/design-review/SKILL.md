---
name: design-review
description: GDD authoring & review facilitator. Use when user says "写 GDD / 起草设计 / design review / 评审设计 / 概念到设计". Owns the concept-dialogue-driven GDD structure (no fixed 8 sections), the draft→cross-review→revise loop, and gates phase-1→phase-2 advancement. Calls designer/art-director/ux-designer for content, reviewer for cross-check, producer for arbitration.
allowed-tools: read_file, write_to_file, list_dir, search_content
disable: false
---

# design-review · GDD 起草与评审

## 何时加载

- 项目从 concept 进入 design 阶段
- 用户说"写 GDD" / "评审设计" / "概念定下来了"
- 单章重写 / 新增 GDD 章节
- gate 决策："这个设计能不能进开发？"

**不加载场景**：小设计点用 `quick-design`；架构类决策用 `architecture-decision`。

## 输入契约

| 输入 | 来源 | 必需 |
|---|---|---|
| 项目 concept（一句话）| `PROJECT.md` 或用户 | ✅ |
| 设计材料（参考图 / 类似游戏 / 玩法概述）| 用户 | 推荐 |
| `templates/gdd-skeleton.md` | 模板（建议骨架，非强制）| ✅ |
| `rules/design-authoring/RULE.mdc` | 强制 | ✅ |
| `rules/agent-spawn-contract/RULE.mdc` | 强制（多 agent 协作）| ✅ |

## 流程总览

```
Step 1 范围确认
  ↓
Step 2 概念对话（CONCEPT DIALOGUE）  ← 关键新增
  ↓ 产出"本项目专属章节列表"
Step 3 加载 + 偏差判定
  ↓
Step 4 三轮循环（DRAFT → CROSS-REVIEW → REVISE）  ← 关键新增
  ↓
Step 5 reviewer 终审
  ↓
Step 6 落盘
  ↓
Step 7 gate 输出
```

---

### Step 1 · 范围确认

确定本次：

- **A 起草**：从零写 GDD
- **B 单章重写**：替换某一节
- **C 评审**：审已存在的 GDD，输出 verdict
- **D 增补**：在已有 GDD 上加新章节

只有 A / D 走完整 Step 2 概念对话；B 跳过；C 仅做 reviewer 路径。

---

### Step 2 · 概念对话（CONCEPT DIALOGUE）

> **核心理念**：GDD 章节由对话产出，不是套模板。

main agent 与用户（或 designer agent 代理用户）对话，弄清以下问题，至少 3 轮、至多 7 轮：

#### 必问清单

| # | 问题 | 用途 |
|---|---|---|
| Q1 | 一句话：玩家在玩什么？（核心动词）| 锁定 core gameplay |
| Q2 | 玩家最爽的 30 秒长什么样？| 锁定 core fantasy |
| Q3 | 一局多长？一段游程多长？有没有跨局留存？| 决定要不要 meta loop 章节 |
| Q4 | 关卡 / 章节 / 程序生成 / 沙盒 / 叙事 哪种是主要内容载体？| 决定"内容与节奏"该怎么写或要不要写 |
| Q5 | 单人 / 多人 / 联机 / 异步 ？ | 决定要不要"匹配 / 同步 / 反作弊"章节 |
| Q6 | 美术风格大方向？参考？ | 锁定视觉支柱 |
| Q7 | 平台 / 帧率 / 性能预算 | 决定"交付与验收"内容 |
| Q8 | 不做清单（明确放弃的功能）| 锁定范围 |

#### 选问清单（按必问回答触发）

- 如果 Q3 提到 meta loop → 加问 "永久解锁内容？经济系统？"
- 如果 Q4 选程序生成 → 加问 "什么是种子？什么不变？什么变？"
- 如果 Q4 选叙事 → 加问 "分支结构？文本量级？是否本地化？"
- 如果 Q5 选多人 → 加问 "匹配维度？反作弊深度？"

#### 概念对话产出物

落盘到 `projects/<name>/gdd/concept-dialogue.md`，包含：

```markdown
## 概念回答清单
Q1-Q8（含选问）的回答全文

## 项目专属章节列表（本对话产出）
- ## 概述（必）
- ## 核心玩法（必）
- ## 系统设计（必）
- ## 视觉与美术（必）
- ## 交付与验收（必）
- ## XXX（项目特殊）
- ## YYY（项目特殊）

## 与建议骨架的偏差
- 砍：哪些建议节没有，原因
- 加：哪些非建议节加了，原因

## 偏差度
none | minor | major
```

---

### Step 3 · 加载 + 偏差判定

1. read `templates/gdd-skeleton.md` 的"建议骨架"
2. 与 Step 2 产出的"专属章节列表"对比
3. 计算偏差度：
   - `none`：完全用建议 8 节
   - `minor`：增删 1-2 节
   - `major`：增删 ≥ 3 节，或结构重构
4. 若 `major`，要求 designer 在 GDD 落盘时同步写 `gdd-skeleton-rationale.md`

---

### Step 4 · 三轮循环（DRAFT → CROSS-REVIEW → REVISE）

**强制遵守 `agent-spawn-contract` rule**（4 条契约：现状注入 / 模式声明 / 交付顺序 / 落盘强制）。

#### Step 4a · 草稿轮（DRAFT round）

并行 spawn 相关 agents（按章节归属）：

| 章节范围 | 主笔 agent |
|---|---|
| 概述 / 核心玩法 / 系统设计 / 数值 / 内容节奏 / 验收 | `designer` |
| 视觉与美术 / 美术 bible | `art-director` |
| UX / HUD / 微交互 / 动效规格 | `ux-designer` |
| 技术风险 / 架构相关章节 | `architect`（若需要）|

**spawn 前必须**：

- read 现有 GDD（如有）+ Step 2 概念对话产出
- 在 prompt 注入：完整概念对话内容、章节边界、其他 agent 同时在写哪些章节
- 声明 mode（DRAFT / REFINE / PATCH）

每个 agent 各自闭门写自己负责的章节草稿，落盘到 `projects/<name>/gdd/draft/<agent>-<round>.md`。

#### Step 4b · 互审轮（CROSS-REVIEW round）

> 这是真正的"讨论"环节。

并行 spawn 同一批 agents（轮次 +1）：

每个 agent 收到 **所有人的 4a 草稿**，写一份"对其他 agent 章节的 findings 清单"，每份 ≤ 5 条：

- 矛盾点（如 designer 写"5 状态"vs ux-designer 假设"3 状态"）
- 边界冲突（两人都写了同一规格但不同值）
- 缺漏（designer 提到的系统在 ux 部分没有对应反馈设计）
- 越界（agent 写了不属于自己 domain 的内容）
- 提议（建议增加 / 删除某节）

落盘 `projects/<name>/gdd/draft/cross-review-<round>.md`，main agent 汇总。

如果出现以下任一情况，**升级 reviewer agent 介入**：
- 同一冲突被 ≥ 2 个 agent 标出
- 涉及核心规格（如核心循环 / 平台 / 性能）
- 任何 agent 给 `BLOCKED` 标志

如果出现以下情况，**升级 producer 仲裁**：
- 互审后 designer 与 art-director 仍不一致
- 涉及范围（IN/OUT）变更
- 涉及里程碑或截止时间影响

#### Step 4c · 修订轮（REVISE round）

并行 spawn 同一批 agents：

每个 agent 收到自己的 4a 草稿 + 别人对自己的 findings + main agent 汇总的仲裁结果，**只改自己负责的章节**，落盘到 `projects/<name>/gdd/draft/<agent>-<round+1>.md`。

#### 循环判定

完成 4c 后，main agent 检查：

- 互审的 findings 是否全部解决？
- 还有未决冲突？

如果全部解决 → 进入 Step 5。
如果有 1-2 处遗留 → 再循环一次 4b/4c（最多 2 次循环，避免无限）。
如果 ≥ 3 处遗留 → 升级 producer 强制收口。

---

### Step 5 · reviewer 终审

调用 `reviewer` agent，给 verdict：

- `APPROVED`：5 维度全覆盖 + 概念对话产出的章节全部有内容 + 内部一致 + 可进入开发
- `CONDITIONAL`：有 1-3 处需补强，列具体条目
- `BLOCKED`：核心矛盾（如核心循环与平台矛盾），需重写

reviewer 的 input：
- `gdd-skeleton-rationale.md`（如有）
- 最终汇总后的 GDD（已经过 4abc 循环）
- 概念对话产出
- 互审 findings 历史

---

### Step 6 · 落盘

按 `design-authoring` rule：

- 主 GDD → `projects/<name>/gdd/gdd-<chapter>.md`
- 概念对话 → `projects/<name>/gdd/concept-dialogue.md`
- 偏差说明（major 偏差时） → `projects/<name>/gdd/gdd-skeleton-rationale.md`
- 草稿历史 → `projects/<name>/gdd/draft/` （评审后可归档到 `reports/archive/`）
- 评审报告 → `projects/<name>/reports/gdd-review-<date>.md`

---

### Step 7 · gate 输出

如果是 phase gate：明确告诉 producer 是否可以进入开发阶段。

## 输出契约

| 字段 | 内容 |
|---|---|
| `verdict` | `APPROVED` / `CONDITIONAL` / `BLOCKED` |
| `gdd_path` | 落盘路径 |
| `concept_dialogue_path` | 概念对话产出路径 |
| `skeleton_deviation` | none / minor / major |
| `findings` | 不通过项清单（含位置 + 建议） |
| `cross_review_rounds` | 互审循环了几轮 |
| `next_action` | 进开发 / 修后再审 / 重做 |

## 调用的 agent

- `designer`（opus，主笔）
- `art-director`（视觉章节）
- `ux-designer`（UX/动效章节）
- `reviewer`（sonnet，互审介入 + 终审）
- 必要时 `architect`（技术可行性 / 架构相关章节）
- 必要时 `producer`（仲裁）

## 加载的 rule

- `agent-spawn-contract`（**强制**：4 条契约）
- `design-authoring`（最小覆盖 5 维度 + 内容精度三原则 + 锚点稳定性）
- `language-policy`
- `project-structure`

## 失败 / 降级

| 异常 | 策略 |
|---|---|
| concept 不清晰 | Step 2 至少问到 Q1-Q8 全部有非空答案才推进 |
| 概念对话超过 7 轮仍发散 | 升级 producer 强制收口 |
| 5 个最小覆盖维度有 < 5 个有内容 | 强制 `BLOCKED` |
| 互审循环 > 2 轮仍冲突 | 升级 producer 仲裁 |
| designer 与 architect 给出矛盾建议 | reviewer 介入；仍不一致升级 producer |

## 验收标准

- 5 个最小覆盖维度全部有非空内容
- 概念对话产出的所有章节均有 ≥ 1 段实质内容
- 验收清单 ≥ 5 条 + 全部可衡量
- 风险 ≥ 3 条 + 缓解措施
- 互审 findings 全部已解决或已升级仲裁

## Known Limitations

- 评审依赖 reviewer agent 的语义判断，缺自动化指标
- 跨章节冲突的检测依赖互审轮，仍可能漏（兜底依赖 `consistency-check`）
- 概念对话本身依赖用户 / designer 的提问质量

## 历史教训

- **2026-05-15 mario-1-1 detail 事故 #1**：spawn designer-1 时未注入现有 GDD 现状，导致从零重写。修复：新增 `agent-spawn-contract` rule。
- **2026-05-15 mario-1-1 detail 事故 #2**：用户质疑"为什么强制 8 节，没有讨论环节"。修复：本 skill 引入 Step 2 概念对话 + Step 4 三轮循环，废弃 8 节强制约束（改为最小覆盖 5 维度）。
