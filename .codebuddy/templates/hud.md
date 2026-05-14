# hud · HUD 元素清单模板

> 本模板由 `design-review` skill 调用（当涉及 HUD 设计时）。落盘到 `projects/<name>/gdd/hud-<screen>.md`。

---

```markdown
---
screen: ${SCREEN_NAME}
status: draft
last_review: ${DATE}
gdd_ref: ${GDD_REF}        # 关联 GDD §7
---

# HUD 元素清单 · ${SCREEN_NAME}

## 屏幕布局

\`\`\`
┌──────────────────────────────────┐
│  [Status Bar]         [MiniMap]  │
│                                  │
│                                  │
│         [Game View]              │
│                                  │
│                                  │
│  [Skill Bar]    [Inventory Btn]  │
└──────────────────────────────────┘
\`\`\`

## 元素清单

| # | 元素 | 位置 | 尺寸 | 显示条件 | 信息内容 | 更新频率 | 交互 |
|---|---|---|---|---|---|---|---|
| 1 | HP 条 | 左上 | 200x20 | 始终 | 当前/最大 HP | 实时 | 无 |
| 2 | 技能栏 | 底部中 | 4x64px | 战斗中 | CD / 可用 | 技能触发时 | 点击释放 |

## 动画 / 过渡

| 元素 | 触发 | 动画类型 | 时长 | 缓动 |
|---|---|---|---|---|
| — | — | — | — | — |

## 本地化要点

| 元素 | 文本 TID | 最大长度 | 截断策略 |
|---|---|---|---|
| — | — | — | — |

## 性能预算

| 指标 | 目标 | 说明 |
|---|---|---|
| Draw calls | ≤ — | — |
| Overdraw | ≤ — | — |
| 更新频率 | ≤ —Hz | 非关键信息降频 |

## 关联

- GDD：${GDD_REF}
- UX 规格模板：`ux-spec.md`
- 无障碍模板：`accessibility.md`
```
