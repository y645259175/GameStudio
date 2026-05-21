# patches · MANUAL

> CORE 见 `RULE.mdc`。

## §format · PATCH 文件格式

```yaml
---
patch_id: PATCH-NNN
target: skills/dev-story/SKILL.md
priority: P0|P1|P2|P3
status: open|merged|rejected|stale
discovered_in: <项目名> sprint-N
discovered_at: 2026-05-15
discovered_by: <agent 名 / 用户>
merged_at: null
---

# PATCH-NNN: <一句话标题>

## 问题
<场景 + 触发条件 + 影响>

## 当前行为
<引用主文件原文片段>

## 建议改动
<伪 diff 或描述>

## 验证
<测试用例 / 预期效果>
```

## §目录结构

```
.codebuddy/skills/<name>/
├── SKILL.md                  ← 主文件
├── patches/                  ← 待合并
│   ├── PATCH-001-...md
│   └── PATCH-002-...md
└── archive/                  ← 旧版本归档
    ├── SKILL.md.v1
    └── SKILL.md.v2
```

agents / rules 同结构。

## §P0-P3 分级

| 优先级 | 含义 | 处理时机 |
|---|---|---|
| P0 | 阻塞 / 错误 / 严重不一致 | 立即合并 |
| P1 | 影响体验 / 缺关键能力 | 1 sprint 内合并 |
| P2 | 改进 / 边界澄清 | 累积 ≥3 批量合并 |
| P3 | nice-to-have / 风格 | 累积 ≥5 或评审周期合并 |

## §merge-flow · 合并工作流

1. 把当前主文件复制到 `archive/<NAME>.<ext>.v<N>`
2. 按 PATCH 描述修改主文件
3. PATCH frontmatter 改 `status: merged` + `merged_at: <date>`
4. PATCH 文件保留在 `patches/`（不删，作为变更日志）
5. commit msg：`[refactor] <name>: merge N patches (PATCH-001..00N)`

## §relations · 与其他机制的边界

| 机制 | 区别 |
|---|---|
| ADR | 项目内架构决策；PATCH 是工作室能力的迭代 |
| Retro action items | retro 关注 sprint 流程；PATCH 关注具体能力文件 |
| consistency-check | 找代码↔文档不一致；PATCH 是这种不一致的修复入口 |

## §触发场景

| 场景 | 谁写 |
|---|---|
| reviewer 评审 skill 输出时发现 verdict 词汇不规范 | reviewer 自动写 |
| 用户说"这个 skill 描述太模糊" | 用户口述 + AI 写 |
| consistency-check 发现 skill 引用路径不存在 | 主 agent 写 |
| 实战中发现 agent 越权 / 边界不清 | reviewer / producer 写 |
| 新发现的 CodeBuddy 能力颠覆旧描述 | 主 agent 写修正 |

## §拒绝 / 过期

- 评审后认为不该改：`status: rejected` + 写理由
- 长期未处理且场景已变：`status: stale`

## §Known Limitations

- 未集成自动化（PATCH 数量监控、合并提醒）
- 跨能力复合 PATCH（同时改 skill + rule）需拆为两个独立 PATCH
