---
name: consistency-check
description: Cross-artifact consistency scan that checks GDD, stories, code, and config alignment.
allowed-tools:
disable: false
---

# Consistency-Check · 跨产物一致性扫描

## 何时使用

跨 GDD ↔ stories ↔ 代码 ↔ 配置的一致性扫描，被 `dev-story` skill 内自动调用，也在 sprint 末由 `smoke-check` 调用。对应 v4 §4.5（Q5=D 双触发）。

典型触发：
- `dev-story` 内自动（写完 story 时）
- `smoke-check` 末段
- 手动 `/consistency-check`

## 输入 / 触发条件

- 当前项目根（必有 `PROJECT.md` + `gdd/`）
- 扫描范围：默认全量，可指定单 story / 单模块

## 流程步骤

1. **GDD 完整性**：`gdd/` 下文档是否含 8 节（§4 Q7-C）
2. **GDD ↔ stories 映射**：每个 user story 是否能追溯到 GDD 某节
3. **stories ↔ 代码映射**：done 状态的 story 是否有对应代码改动
4. **代码 ↔ 配置映射**：硬编码扫（违反 `data-driven` rule）
5. **报告生成**：按 `templates/consistency-report.md.tpl` 填空，分级标注（critical / warn / info）
6. **退出条件**：critical = 0 → 通过；critical > 0 → 阻塞调用方 skill（如 `dev-story` 不让 commit）

## 输出

- `projects/<name>/reports/consistency-YYYY-MM-DD-HHmm.md`
- 终端摘要（critical / warn / info 计数 + top issues）

## 引用

- 上游规划：v4 §4.5 Q5=D、§6.1.1
- 相关 skill：`dev-story` `smoke-check` `daily-check`
- 相关 rule：`design-authoring` `data-driven`
- 相关 template：`templates/consistency-report.md.tpl`

## Known Limitations / Phase 2 Review Points

- [Phase 2 TODO] 代码 ↔ 配置映射当前靠正则扫魔法数字，准确性有限
- [Phase 2 TODO] story ↔ 代码映射依赖 commit message 含 story id，需 `commit-discipline` rule 强制
- [Phase 2 TODO] 大项目扫描性能未优化，scan 耗时 > 30s 时需要改增量扫
