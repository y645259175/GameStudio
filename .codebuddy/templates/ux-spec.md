# ux-spec · UX 规格模板

> 本模板由 `design-review` skill 调用（当涉及 UX 设计时）。落盘到 `projects/<name>/gdd/ux-spec-<feature>.md`。

---

```markdown
---
feature: ${FEATURE_NAME}
status: draft
last_review: ${DATE}
gdd_ref: ${GDD_REF}        # 关联 GDD 章节（如 §7.UX 与 HUD）
---

# UX Spec · ${FEATURE_NAME}

## 用户画像

| 维度 | 描述 |
|---|---|
| 核心用户 | — |
| 使用场景 | — |
| 技术水平 | — |

## 用户故事

\`\`\`
作为 <角色>，
我想要 <功能>，
以便 <目的>。
\`\`\`

## 界面流转

\`\`\`
[入口] → [主界面] → [操作] → [反馈] → [出口]
\`\`\`

### 流转详情

| 步骤 | 界面 | 操作 | 预期反馈 | 异常处理 |
|---|---|---|---|---|
| 1 | — | — | — | — |

## 交互规格

| 元素 | 操作 | 反馈 | 状态变化 |
|---|---|---|---|
| — | 点击 / 长按 / 滑动 | — | — |

## 信息架构

### 页面元素层级

\`\`\`
Screen
├── Header
│   ├── Title
│   └── Action Button
├── Content
│   ├── List Item 1
│   └── List Item 2
└── Footer
    └── Navigation
\`\`\`

## 响应式 / 多端适配

| 平台 | 分辨率 | 布局策略 | 交互差异 |
|---|---|---|---|
| PC | 1920x1080 | — | 鼠标 + 键盘 |
| Mobile | 375x812 | — | 触控 |

## 无障碍检查

- [ ] 色彩对比度 ≥ 4.5:1（WCAG AA）
- [ ] 焦点顺序符合逻辑
- [ ] 所有交互元素有 aria-label
- [ ] 字号 ≥ 14pt（移动端 ≥ 16pt）

## 关联

- GDD：${GDD_REF}
- HUD 模板：`hud.md`
- 无障碍模板：`accessibility.md`
```
