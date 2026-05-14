# consistency-report · 一致性检查报告模板

> 本模板由 `consistency-check` skill 调用。落盘到 `projects/<name>/reports/consistency-<date>.md`。

---

```markdown
---
check_date: ${DATE}
check_scope: ${SCOPE}       # full / gdd-only / stories-only / code-only
result: pass / warn / fail
errors: ${ERROR_COUNT}
warnings: ${WARNING_COUNT}
---

# 一致性检查报告 · ${DATE}

## 摘要

| 类别 | 数量 |
|---|---|
| ❌ 错误 | ${ERROR_COUNT} |
| ⚠️ 警告 | ${WARNING_COUNT} |
| ✅ 通过 | ${PASS_COUNT} |

## 错误详情

### E1 · ${ERROR_TITLE}

- **类型**：引用断裂 / 数值不一致 / 缺失文件
- **位置**：`${FILE_PATH}`
- **详情**：
- **修复建议**：

## 警告详情

### W1 · ${WARNING_TITLE}

- **类型**：占位未填 / 弱引用 / 风格不一致
- **位置**：`${FILE_PATH}`
- **详情**：
- **建议**：

## 通过项

| # | 检查项 | 状态 |
|---|---|---|
| 1 | GDD ↔ story 引用闭合 | ✅ |
| 2 | story ↔ code 引用闭合 | ✅ |
| 3 | 数值表 ↔ GDD §5 一致 | ✅ |
| 4 | ADR 引用完整 | ✅ |
| 5 | 路径约束合规 | ✅ |

## 修复追踪

| # | 问题 | 修复 PR | 状态 |
|---|---|---|---|
| — | — | — | — |
```
