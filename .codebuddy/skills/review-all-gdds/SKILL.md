---
name: review-all-gdds
type: skill
status: active
description: Cross-chapter GDD review that surfaces conflicts, gaps, and naming inconsistencies across all design documents.
---

<!-- OVER_LIMIT_REASON: GDD 跨章节扫描的 5 类不一致清单 + 触发场景必须一并展示，分散会让 reviewer 漏检。 -->

# Review-All-GDDs · 跨 GDD 全量审视

## 何时使用

milestone 节点 / sprint 末 / 重大设计变更后，对项目所有 GDD 章节做横向扫描，找冲突 / 缺口 / 命名不一致。

典型触发：
- "/review-all-gdds"
- "看看所有 GDD"
- `milestone-review` 内自动调用

## 输入 / 触发条件

- 当前在项目根
- `projects/<name>/gdd/` 下至少有 2 章 GDD

## 流程步骤

1. **扫描清单**：列出 `gdd/` 下所有 .md 文件
2. **章节级别 8 节扫**：每章是否含 8 节（依赖 `design-review` 的产物）
3. **跨章一致性扫**：
   - 同名实体（角色 / 系统 / 资源）的定义是否一致
   - 数值是否冲突（同属性在不同章节给出不同值）
   - 玩法循环是否闭合（A 章节引用 B 章节，B 是否真的存在）
   - 引擎 / 工具假设是否一致
4. **缺口扫**：列出"被引用但未起草"的章节
5. **报告生成**：分级（critical / warn / info）输出建议修订项
6. **落盘**：`projects/<name>/reports/gdd-review-YYYY-MM-DD.md`
7. **路由提示**：critical > 0 时建议 `design-review` 修订对应章节

## 输出

- `projects/<name>/reports/gdd-review-YYYY-MM-DD.md`
- 终端内问题数表 + top issues

## 引用

- 上游规划：v4 §4 Q7-C、§6.1.1
- 相关 skill：`design-review` `consistency-check` `milestone-review`
- 相关 rule：`design-authoring`
- 相关 template：`templates/consistency-report.md.tpl`（复用一致性报告模板）

## Known Limitations / Phase 2 Review Points

- [Phase 2 TODO] 大项目 GDD 数 > 30 时扫描性能未优化
- [Phase 2 TODO] 跨章一致性的判定靠 AI 语义匹配，错报率有待校准
- [Phase 2 TODO] 与 `consistency-check` 的边界：本 skill 偏 GDD 内部、`consistency-check` 偏 GDD↔代码↔配置
