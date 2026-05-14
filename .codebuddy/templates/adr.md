# adr · Architecture Decision Record 模板

> 本模板由 `architecture-decision` skill 调用。落盘到 `projects/<name>/adr/<NNNN>-<slug>.md`。
>
> 编号规则：4 位零填充递增，从 `0001` 开始。索引文件 `0000-index.md` 由 skill 自动维护。

---

```markdown
---
adr_id: ${ADR_ID}           # 如 0001-render-pipeline
status: proposed            # proposed / accepted / deprecated / superseded
date: ${DATE}
deciders: [${DECIDERS}]
supersedes:                 # 如被新 ADR 取代则填 ADR ID
related_gdd:                # 关联 GDD 章节（如 §4.渲染）
---

# ADR ${ADR_ID} · ${TITLE}

## 上下文

<!-- 为什么需要做这个决策？触发条件是什么？ -->

## 决策

<!-- 我们选择了什么方案？ -->

## 候选方案

| # | 方案 | 优点 | 缺点 | 结论 |
|---|---|---|---|---|
| A | — | — | — | 选择 / 放弃 |
| B | — | — | — | 选择 / 放弃 |
| C | — | — | — | 选择 / 放弃 |

## 理由

<!-- 为什么选 A 不选 B/C？关键 trade-off 是什么？ -->

## 影响

### 正面

-

### 负面

-

### 风险

| 风险 | 概率 | 缓解 |
|---|---|---|
| — | — | — |

## 关联

- GDD：${RELATED_GDD}
- Stories：${RELATED_STORIES}
- 其他 ADR：${RELATED_ADRS}
```
