---
name: quick-design
description: Lightweight design facilitator for small decisions outside the 8-section GDD. Use when user says "快速设计 / 小设计点 / quick design / 不想走全流程". Examples - tweaking a single number, adding a small UI element, deciding a minor mechanic. Outputs a 1-page note, not a full chapter.
allowed-tools: read_file, write_to_file, search_content
disable: false
---

# quick-design · 轻量设计节点

## 何时加载

- 设计点小（< 1 小时讨论可决）
- 不影响 GDD 整体结构
- 用户明确说"快速搞一下" / "不需要全流程"

**不加载场景**：影响核心循环 / 跨系统 → 走 `design-review`；纯架构 → 走 `architecture-decision`。

## 输入契约

| 输入 | 来源 |
|---|---|
| 设计点描述 | 用户 |
| 受影响系统 | 用户 / GDD 检索 |

## 流程

### Step 1 · 边界判断

3 个问题：
1. 是否改动核心循环？
2. 是否需修改 ≥ 2 个 GDD 章节？
3. 是否引入新系统？

任一为 YES → 升级到 `design-review`。

### Step 2 · 调用 designer 简版

让 `designer` agent 给出：
- 1-2 个备选方案
- 推荐方案 + 理由（1 段）
- 影响面（哪些已有内容会变）

### Step 3 · 落盘 1-page note

`projects/<name>/gdd/notes/<topic>-<date>.md`，包含：
- 决策 1 句话
- 备选 2-3 个 + 取舍
- 受影响 GDD 章节 / 数值
- 关联 story（如已立项）

### Step 4 · 同步引用

如果决策影响 GDD 某章 → 在该章末尾加一行 `> 注：<topic>，详见 notes/<topic>-<date>.md`

## 输出契约

| 字段 | 内容 |
|---|---|
| `verdict` | `DECIDED` / `ESCALATE_TO_DESIGN_REVIEW` |
| `note_path` | `projects/<name>/gdd/notes/<topic>-<date>.md` |
| `affected_sections` | GDD 受影响章节列表 |

## 调用的 agent

- `designer`（sonnet 即可，量小）

## 加载的 rule

- `design-authoring`（轻量遵循）

## 失败 / 降级

| 异常 | 策略 |
|---|---|
| Step 1 判断为大问题 | 立即升级到 `design-review` |
| designer 拿不出方案 | 升级 `architect` 或回到用户澄清 |

## 验收标准

- note 在 1 页内（< 200 行）
- 决策清晰 + 可追溯
- 不破坏 GDD 整体一致性

## Known Limitations

- 边界判断靠经验，可能漏判应升级的设计
- 量大时 notes/ 目录会膨胀（Phase 2 评估归档策略）
