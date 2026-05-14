---
name: consistency-check
description: Cross-artifact consistency scan. Use when user says "查一致性 / consistency check / GDD 和代码对得上吗 / cross-check". Validates GDD ↔ stories ↔ code ↔ data alignment. Called by dev-story (gating), smoke-check, story-done.
allowed-tools: read_file, list_dir, search_content
disable: false
---

# consistency-check · 跨产物一致性扫

## 何时加载

- `dev-story` 提交前 gating
- `smoke-check` 中调用
- `story-done` 收尾前
- 用户说"查一下 GDD 和代码对得上"

**不加载场景**：仅看代码风格 → `reviewer` agent；GDD 内部 → `review-all-gdds`。

## 输入契约

| 输入 | 来源 | 必需 |
|---|---|---|
| GDD 章节 | `projects/<name>/gdd/*.md` | ✅ |
| 数值表 | `projects/<name>/data/*.json` | ✅ |
| 代码 | `projects/<name>/game/scripts/**` | ✅ |
| ADR | `projects/<name>/adr/*.md` | 推荐 |
| 范围 | full / story-id / files | ✅ |

## 流程

### Step 1 · 范围定位

| 范围 | 触发场景 |
|---|---|
| `full` | smoke-check |
| `story-id` | dev-story / story-done |
| `files` | 用户指定 |

### Step 2 · 4 维度扫描

#### A. GDD ↔ 代码

- GDD 提到的系统是否有代码实现（grep 关键字 / 文件名）
- 代码中的核心循环是否和 GDD §2 一致

#### B. 数值表 ↔ 代码常量

- `data/*.json` 中的数值
- 代码中 `const` / `var` 硬编码的数值
- 二者不一致 → 标 DRIFT

#### C. ADR ↔ 代码模式

- ADR 决定的架构（单例 / 事件 / 状态机）
- 代码是否遵循

#### D. story AC ↔ 代码行为

仅在 story 范围内：
- 每条 AC 是否有对应代码 / 测试覆盖

### Step 3 · 列冲突清单

```
| # | 类型 | 位置 A | 位置 B | 建议 |
|---|---|---|---|---|
| 1 | 数值漂移 | data/levels.json:ball_speed=300 | scripts/ball.gd:speed=350 | 以表为准 |
```

### Step 4 · 委托 reviewer 复核

冲突清单交 `reviewer` agent (sonnet) 二次审：
- 假阳性过滤（如代码里的数值是测试常量，故意与表不同）

### Step 5 · 落盘报告

`projects/<name>/reports/consistency-<scope>-<date>.md`，按 `templates/consistency-report.md`。

### Step 6 · gate 决策

| 冲突数 | verdict |
|---|---|
| 0 | `CLEAN` |
| 1-3 | `MINOR` |
| ≥ 4 或含 critical（核心循环、关键数值）| `MAJOR` |

## 输出契约

| 字段 | 内容 |
|---|---|
| `verdict` | `CLEAN` / `MINOR` / `MAJOR` |
| `report_path` | reports/consistency-*.md |
| `conflicts_count` | int |
| `by_type` | {gdd_code, data_code, adr_code, ac_code} 各计数 |

## 调用的 agent

- `reviewer` (sonnet)（复核）
- 多领域冲突时升级 `architect` (opus) / `qa-lead` (opus)

## 加载的 rule

- `data-driven`（数据驱动检查）
- `design-authoring`
- `language-policy`

## 失败 / 降级

| 异常 | 策略 |
|---|---|
| 数值表缺 | 跳过 B 维度 + 标提醒 |
| ADR 缺 | 跳过 C 维度 |
| 关键字匹配失败导致大量假阳性 | reviewer 过滤后再决策 |

## 验收标准

- 4 维度全跑或显式跳过 + 原因
- 报告清单完整
- verdict 明确

## Known Limitations

- 关键字匹配粗（无 AST 分析）
- 跨语言数值（中文资料 vs 英文常量名）依赖 reviewer 判断
