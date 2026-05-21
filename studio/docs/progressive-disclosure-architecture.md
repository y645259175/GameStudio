# 渐进披露架构 · 工作室级设计

> 2026-05-20 v1.0 · 用户 + main agent 共同决策
> 触发：rule/skill/agent 文档体积失控（rules 1523 行 / skills 2477 行 / agents 2089 行 = 总 ~6000 行 / ~200KB），sub-agent spawn 时上下文被无关信息占用。

## 三大目标

1. **渐进披露**（更聚焦更准确）：在合适的时候调用对应上下文，需求逐渐明确时逐渐展示更多细节
2. **准确输入**（更稳定）：不能为了精简导致工作质量下降；需要时 agent 能想到去找、且能顺利找到
3. **进化有边界**（防止再堆砌）：增量进化时时刻保住前两条红线

## 三层模型

```
CORE（极简强制注入）
  ↓ 识别场景关键词
MANUAL（手册，按需 read_file）
  ↓ RCA / postmortem / debug
ARCHIVE（档案，深度查询）
```

| 层 | 文件 | 长度 | 注入时机 | 内容 |
|---|---|---|---|---|
| CORE | `RULE.mdc` / `SKILL.md` / `AGENT.md` | rule/skill ≤30 · agent ≤40 | 每次或 spawn 时 | 身份 + 红线 + 何时升级 + 索引 |
| MANUAL | `MANUAL.md` / `PLAYBOOK.md` / `HANDBOOK.md` | ≤150 | agent 主动 read | 完整 SOP + 字段细则 |
| ARCHIVE | `ARCHIVE.md` | 无上限 | 仅 RCA 时 | 历史判例 + 弃用记录 |

样板：`anti-patterns.md`(MANUAL 层 · 462) + `anti-patterns-digest.md`(CORE 层 · 36) 已是范本。

## 红线机制（分级提醒，非硬上限）

避免硬上限反向激励 agent 凑到上限。

| 阶段 | 阈值（rule/skill）| 阈值（agent）| 动作 |
|---|---|---|---|
| 🟢 safe | ≤30 | ≤40 | lint 静默 |
| 🟡 notice | 31-50 | 41-60 | 写日志 / hook 输出 NOTE |
| 🟠 review | 51-80 | 61-100 | **打回 agent**：必须头部加 `<!-- OVER_LIMIT_REASON: ... -->` |
| 🔴 approval | 80+ | 100+ | **必须用户审批**：commit msg 加 `[layer-override]` tag |

MANUAL 层阈值：safe ≤150 · notice 151-250 · review 251-400 · approval 400+

ARCHIVE 层不参与 lint，但建议有"判例索引表"避免无序堆积。

### 实施

- lint 工具：`.codebuddy/scripts/check_progressive_disclosure.py`
- commit-msg hook 集成：`.codebuddy/hooks/pre-commit-discipline.py`（在 tag 检查通过后调 lint）
- 跑全量：`python .codebuddy/scripts/check_progressive_disclosure.py`
- 严格模式：`--strict`（提醒区也算 fail）

## CORE 写作要点

✅ 包含
- 一句话目的 / 身份
- 3-5 条强制约束
- 何时升级到 MANUAL（具体场景关键词）
- 索引指针：`详细 SOP 见 MANUAL.md § X`

❌ 不包含
- 历史触发事件（→ ARCHIVE）
- 完整 SOP 步骤（→ MANUAL）
- 边界 / 罕见 case（→ MANUAL 或 ARCHIVE）
- 决议词汇详细说明（→ MANUAL）

## 知识进化时的"分层归档"决策树

新内容产生时（retro / playbook 精炼 / 用户反馈），按以下顺序归类：

```
新内容来了
  │
  ├── 是否每次干同类活都要遵守？
  │     是 → CORE（精简到 1-2 行）
  │     否 → ↓
  │
  ├── 是否在某个具体场景必须遵守？
  │     是 → MANUAL §对应场景
  │     否 → ↓
  │
  └── 是否仅作为历史溯源？
        是 → ARCHIVE
```

**反模式**：不归类直接追加到 CORE 末尾——这是滑坡的开端。

## 维护协议

- agent 在 retro / playbook 精炼时，必须按上面决策树分层归档
- 归档完成后必须跑 lint 确认未触红线
- 触红线 → 优先精简 / 拆层 → 万不得已才加 OVER_LIMIT_REASON
- 季度回顾：扫一遍 CORE 看是否能进一步下沉到 MANUAL

## 引用

- 三件套模板：`studio/templates/progressive-disclosure/`
- lint 工具：`.codebuddy/scripts/check_progressive_disclosure.py`
- commit hook：`.codebuddy/hooks/pre-commit-discipline.py`
- 当前进度：BL-S040~045 系列（见 `studio/backlog.md`）
