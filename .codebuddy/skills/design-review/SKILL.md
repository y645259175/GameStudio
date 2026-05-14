---
name: design-review
description: GDD authoring and review facilitator that ensures the 8-section structure is complete and internally consistent.
allowed-tools:
disable: false
---

# Design-Review · GDD 评审 / 修订

## 何时使用

起草新 GDD 章节、或对已有 GDD 做评审 / 修订时调用。强制 8 节完整性（v4 §4 Q7-C）。

典型触发：
- "/design-review"
- "评审一下战斗系统 GDD"
- `new-project`（stage=concept）后续路由

## 输入 / 触发条件

- 当前在项目根
- 目标 GDD 章节（如已存在）或新章节主题
- 相关上下文文档（市场分析 / 用户研究 / 竞品分析，如有）

## 流程步骤

1. **范围确定**：是新建 GDD 章节还是修订既有
2. **8 节 checklist**（按 `design-authoring` rule）：
   - 概述 / 玩法循环 / 系统设计 / 数值与平衡 / UX / 美术 / 音频 / 交付与验收
3. **逐节填充 / 修订**：交互式问答，AI 提议 + 用户修订
4. **一致性自检**：与已有 GDD 章节交叉验证（数值不冲突 / 玩法循环闭合 / 引用名一致）
5. **落盘**：`projects/<name>/gdd/<chapter>.md`，按 `templates/gdd-8-sections.md` 填充
6. **path 标注**：在章节末尾加"上游 epic / 下游 stories"链接（如已存在）
7. **路由提示**：评审通过后建议调用 `create-epics` 或 `review-all-gdds`

## 输出

- `projects/<name>/gdd/<chapter>.md`
- 终端内 8 节完整性表（每节 ✅ / ⚠️）

## 引用

- 上游规划：v4 §4 Q7-C、§6.1.1
- 相关 skill：`review-all-gdds` `create-epics` `quick-design`
- 相关 rule：`design-authoring`
- 相关 template：`templates/gdd-8-sections.md.tpl`

## Known Limitations / Phase 2 Review Points

- [Phase 2 TODO] 8 节内部交叉一致性扫描当前靠 AI 判断，未来可由 hook 自动校验
- [Phase 2 TODO] 与已有 GDD 章节的交叉引用名校验依赖 `consistency-check`，性能未优化
- [Phase 2 TODO] 美术 / 音频节的产出格式（图 / wav）未定义引用规范
