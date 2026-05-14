---
name: review-all-gdds
description: Cross-chapter GDD audit. Use when user says "审一遍所有 GDD / 全 GDD 一致性 / cross-check design / 章节冲突". Runs across projects/<name>/gdd/*.md, surfaces conflicts, gaps, and naming inconsistencies. Heavier than consistency-check (which spans GDD + code + config).
allowed-tools: read_file, list_dir, search_content
disable: false
---

# review-all-gdds · 跨章节 GDD 审计

## 何时加载

- GDD 章节数 ≥ 3 且彼此引用频繁
- 进入下一阶段前的设计 gate
- 用户说"我担心章节之间有矛盾"

**不加载场景**：单章修改 → 走 `design-review`；跨产物（GDD + 代码） → 走 `consistency-check`。

## 输入契约

| 输入 | 来源 |
|---|---|
| `projects/<name>/gdd/*.md` 全部章节 | 项目目录 |
| 数值表 `data/*.json` | 项目数据 |
| `rules/design-authoring/RULE.mdc` | 规则 |

## 流程

### Step 1 · 全量收集

`list_dir projects/<name>/gdd/` → 拿到全部 md。

### Step 2 · 三类一致性扫描

| 类别 | 检查内容 |
|---|---|
| **命名** | 角色 / 系统 / 道具名是否多写法（如 "boss" vs "Boss" vs "首领"）|
| **数值** | 各章节给出的数值是否互斥（如玩法说 100HP，平衡说 80HP）|
| **逻辑** | 玩法循环依赖的系统在系统章节是否定义？|

### Step 3 · 章节交叉引用图

构建简单图：
- 节点 = 章节 / 系统名 / 角色名
- 边 = 引用关系
- 找：孤立节点（被定义但无引用）、悬空引用（引用了未定义的）

### Step 4 · 委托 reviewer 复核

调用 `reviewer` agent 复核 Step 2 结果，给 verdict：
- `CLEAN`：无冲突
- `MINOR`：< 5 处命名差异，建议批量修
- `MAJOR`：≥ 1 处数值/逻辑矛盾，需 designer 介入

### Step 5 · 输出报告

`projects/<name>/reports/gdd-cross-review-<date>.md`：

```
## 命名差异
| 概念 | 写法 | 出现位置 |
|---|---|---|
| boss | "Boss"/"首领"/"boss" | gdd-1.md:15, gdd-3.md:42 |

## 数值冲突
| 概念 | 章 A | 章 B | 建议 |
|---|---|---|---|

## 悬空引用
| 引用方 | 被引用名 | 状态 |
```

## 输出契约

| 字段 | 内容 |
|---|---|
| `verdict` | `CLEAN` / `MINOR` / `MAJOR` |
| `report_path` | 报告路径 |
| `naming_issues` | 数量 |
| `numeric_conflicts` | 数量 |
| `dangling_refs` | 数量 |

## 调用的 agent

- `reviewer`（sonnet）
- 冲突时升级 `designer`

## 加载的 rule

- `design-authoring`
- `language-policy`（中英术语一致性）

## 失败 / 降级

| 异常 | 策略 |
|---|---|
| GDD 章节 < 2 | 直接返回 `CLEAN`（无可比对）|
| 数值表与 GDD 矛盾 | 优先以数值表为准，标注 GDD 待修 |

## 验收标准

- 命名差异 ≤ 5 处或全部修复
- 0 数值冲突
- 0 悬空引用（或全部加 TODO 标注）

## Known Limitations

- 命名相似度判断靠字符串匹配（无 NLP）
- 跨语言术语对照（中文/英文）需手维护
