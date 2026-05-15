---
name: scope-check
description: Project scope drift detection. Use when user says "范围跑偏 / scope check / 这个还在原计划里吗 / 是不是做太多了". Compares current implementation against GDD core pillars and PROJECT.md milestones. Catches feature creep early.
allowed-tools: read_file, list_dir, search_content
disable: false
---

# scope-check · 项目范围漂移检测

## 何时加载

- 进入新 sprint 前 / sprint 中 mid-sprint 检查
- 用户说"我们做太多了吗" / "这还是当初要做的游戏吗"
- 当 stories 累计超过 epic 估算的 1.5 倍
- milestone-review 调用本 skill 作为子检查

**不加载场景**：单 story 内的实现细节（走 `dev-story`）；技术架构是否合理（走 `architecture-decision`）。

## 输入契约

| 输入 | 来源 | 必需 |
|---|---|---|
| GDD §1 概述 + §2 玩法循环 | `projects/<name>/gdd/gdd-*.md` | ✅ 核心三柱：核心动词 / 目标玩家 / 类型定位 |
| PROJECT.md 里程碑 | `projects/<name>/PROJECT.md` | ✅ |
| 已完成 stories | `projects/<name>/stories/*.md` (status=done) | ✅ |
| 进行中 / backlog stories | 同上 (status=in-progress / ready) | ✅ |
| 当前 phase | `PROJECT.md.phase` | ✅ |

## 流程

### Step 1 · 提取项目"三柱"

从 GDD §1-2 抽出：

- **核心动词**（如 breakout = 弹球反弹消砖）
- **目标玩家**（如休闲玩家 / 全年龄）
- **类型定位**（如 2D Arcade / Breakout Clone）

这三柱是项目身份。任何变化必须经 ADR 决议。

### Step 2 · 对比已完成内容是否服务三柱

逐个 done story 打分：

| 评级 | 含义 |
|---|---|
| **CORE** | 直接服务核心动词（如挡板移动 / 球反弹 / 砖块消除）|
| **SUPPORT** | 支撑核心体验（如计分 / 关卡 / UI）|
| **NICE_TO_HAVE** | 锦上添花，可去（如背景特效）|
| **DRIFT** ⚠️ | 与三柱无关（如打砖块项目突然加 RPG 装备系统）|

### Step 3 · 评估 in-progress / backlog

同上对每个 ready/in-progress story 评级。

特别关注 backlog 中的 **DRIFT** 项——这是早期发现 scope creep 的关键。

### Step 4 · 计算占比

| 指标 | 健康范围 |
|---|---|
| CORE 占比（pts） | ≥ 40% |
| SUPPORT 占比 | 30-50% |
| NICE_TO_HAVE 占比 | ≤ 20% |
| DRIFT 占比 | 0%（任何 DRIFT 都需评审） |

### Step 5 · milestone 对齐检查

读 PROJECT.md 里程碑：

- 当前 phase 应完成的里程碑是否完成？
- 是否在做"未来 phase 的事"（如还在 dev 阶段就在做 release polish）？
- 是否跳过了关键里程碑？

### Step 6 · 委托 producer 判断

调用 `producer` agent (opus)：
- 综合 CORE/SUPPORT/NICE_TO_HAVE/DRIFT 占比 + 里程碑对齐
- 给 verdict：
  - `ON_SCOPE` ✅ 健康
  - `DRIFT_WARNING` ⚠️ 有偏离迹象（DRIFT > 0% 或 NICE_TO_HAVE > 30%）
  - `OFF_SCOPE` ❌ 严重偏离（DRIFT 多 / 关键里程碑被跳过）

### Step 7 · 输出报告

`projects/<name>/reports/scope-check-<date>.md`：

```
# Scope Check - <date>
## Verdict: ON_SCOPE / DRIFT_WARNING / OFF_SCOPE

## 项目三柱
- 核心动词: ...
- 目标玩家: ...
- 类型定位: ...

## 已完成 stories（按评级）
| Story | Pts | 评级 | 备注 |
|---|---|---|---|

## Backlog 中的隐患
- ⚠️ S3-04 加 RPG 装备系统 → DRIFT（与"街机打砖块"定位冲突）

## 占比统计
- CORE: 60%
- SUPPORT: 30%
- NICE_TO_HAVE: 10%
- DRIFT: 0%

## Milestone 对齐
- M2 应完成 ✅
- M3 进度 80%
- 异常: 无

## 建议
- DRIFT_WARNING 时：把 DRIFT story 移出 sprint，或经 ADR 决议是否扩展三柱
```

## 输出契约

| 字段 | 内容 |
|---|---|
| `verdict` | `ON_SCOPE` / `DRIFT_WARNING` / `OFF_SCOPE` |
| `report_path` | reports/scope-check-*.md |
| `drift_stories` | DRIFT 评级的 story id 列表 |
| `core_ratio` | CORE 占比 |
| `recommendation` | 具体下一步建议 |

## 调用的 agent

- `producer` (opus, gate 决策)
- `pm` (opus, milestone 对齐数据)
- `designer` (opus, 三柱抽取 + DRIFT 是否扩三柱判断)

## 加载的 rule

- `design-authoring`（GDD 三柱来源）
- `commit-discipline`

## 失败 / 降级

| 异常 | 策略 |
|---|---|
| GDD §1-2 不清晰，无法抽三柱 | 升级 `design-review` 重新明确 |
| stories 状态不全（缺 frontmatter） | 跳过这些 story + 提示 pm 补全 |
| DRIFT 项有合理理由（如玩家反馈驱动） | 推荐起 ADR 评估是否扩三柱 |

## 验收标准

- 三柱明确
- 所有 done / in-progress / backlog stories 都有评级
- verdict 输出有数据支撑（占比 + milestone 状态）

## Known Limitations

- 评级靠语义判断，可能误判（特别是创意性的 SUPPORT vs NICE_TO_HAVE 边界）
- 三柱本身可能演化（早期定位与中期可能不同），本 skill 不强制冻结，由 ADR 管理
