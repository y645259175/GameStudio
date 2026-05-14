---
name: studio-incubator-migration-v4
overview: 将已对齐的支柱 1（能力覆盖面）+ 支柱 2（产物形态 v4 工作室孵化器架构）锁定结论，落成一份独立的迁移规划文档，防止后续对话遗忘；预留支柱 3 占位。
todos:
  - id: create-migration-doc
    content: 在 d:\AI\GameStudio\.codebuddy\plans\ 下新建 studio-incubator-migration-v4_
    status: completed
---

## 产品概述

在 `d:\AI\GameStudio\.codebuddy\plans\` 下新建 1 份 markdown 文档，作为「MVS+ v4 工作室孵化器迁移规划」的防遗忘锚点，锁定已对齐的支柱 1（能力覆盖面）与支柱 2（产物形态 = 工作室孵化器架构）结论，并为支柱 3（验收机制）预留占位章节，集中列出所有已锁 TODO 队列，便于后续对话继续追加。

## 核心内容

- **章节 1 背景与定位**：说明本文档在 CCGS 原始报告 / v2 修订之上的定制位置；复述工作室新目标（对标 Steam 小型商业作品，原型+长周期打磨+双通道+多项目孵化）。
- **章节 2 支柱 1 锁定（能力覆盖面 v4）**：21 必装 skill + 5 hook + 5-6 rule + 9 template + 9-10 agent 的总量；相对 v1 MVS 的加项清单（sprint-plan / architecture-decision / balance-design / consistency-check 升必装 / quick-fix）；新增 hook validate-commit.sh（仅管 GDD/JSON，不管 tag）；新增 rule commit-discipline.md（软建议）；双通道路由（重 /dev-story、轻 /quick-fix）与 4 类 commit tag（[story]/[quick]/[fix]/[refactor]）+ 3 条 OR 判据。
- **章节 3 支柱 2 锁定（产物形态 v4 = 工作室孵化器）**：
- 顶层结构：`.codebuddy/` + `studio/`（最小版：只建 docs/studio-handbook.md + postmortems/）+ `projects/`（含 `_archived/`）+ 根 README；
- 单项目结构：`game/`（真实交付物）+ `design/`（不含 balance，GDD 小节**示意非强制**，项目落地时再定）+ `production/`（stories/sprints/consistency-reports/retros/prototypes，原型放项目内）+ `docs/`（architecture/ADR + api + runbooks）+ PROJECT.md；
- 产物 4 Tier 分层（A/B/C/D）；
- 新目标 4 维度 + 孵化维度覆盖表（发行 ❌TODO / 长周期 ✅✅ / 商业品质 ⚠️ / 双通道 ✅ / 孵化 ✅）。
- **章节 4 支柱 3（验收机制 v4）占位**：仅列待定问题清单（多项目验收粒度、retro 跨项目合并、smoke-check 分级），不展开。
- **章节 5 已锁 TODO 队列**：P0 Release 4 skill / 质量校验扩展 hook / 6 个能力改造 / 3 个开放点 / xsfk-designer 三项暂不移植的结构改造。
- **章节 6 迁移路径（粗）**：Phase 1 骨架 → Phase 2 首个项目落地 → Phase 3 验收机制补件 → Phase 4 Release TODO 消化。

## 约束

- 仅新建 1 份文档，不修改 `analysis-report/` 与 `.codebuddy/plans/` 下任何现有文件。
- 不创建任何真实项目目录（不建 `projects/<name>/`、`studio/` 等，只在文档中描述结构）。
- 不写 skill/hook/rule 的实现代码，只列清单与职责。
- GDD 小节在文档中必须显式标注「示意，非强制，项目落地时决定」。
- 文档定位为「防遗忘锚点」，已对齐内容记录完整即可，不过度扩写。

## 文档形态

纯 markdown 文档，无代码实现。

## 路径与命名

- 目标路径：`d:\AI\GameStudio\.codebuddy\plans\studio-incubator-migration-v4_<短hash>.md`
- 命名风格参照同目录既有文件：`analysis-report-v2-revision_08399d50.md`、`ccgs-deep-analysis-report_6aec7e96.md`（`<slug>_<8位hash>.md`）
- 短 hash 使用 8 位随机十六进制（与既有风格一致）

## 文档结构设计

### 章节骨架（按固定顺序）

1. 文档元信息（版本 v4 / 创建时间 / 状态：支柱 1+2 已锁、支柱 3 待展开）
2. 背景与定位
3. 支柱 1 锁定结论（能力覆盖面）
4. 支柱 2 锁定结论（产物形态 = 工作室孵化器）
5. 支柱 3 占位（验收机制）
6. 已锁 TODO 队列
7. 迁移路径（粗）
8. 附录：与 v1/v2/v3 的关键差异速查表

### 关键排版约定

- 所有目录树用 ```text 代码块包裹，避免 md 渲染歧义
- 覆盖表、差异表统一用 markdown 表格
- 每个支柱章节开头放 3 行「锁定摘要」box：总量 / 相对前版差异 / 用户拍板要点
- GDD 小节示意处使用明显的引用块 `>` 并标注「示意，非强制」
- 支柱 3 占位章节用 `> TODO: 待展开` 标记待定问题

## 实施要点

- **一次写入成文**：章节骨架固定，内容源于上下文已锁结论，一次 write_to_file 落盘即可，不需要分块追加
- **只读参考不改动**：读取 `.codebuddy/plans/` 已有文件仅为对齐命名风格，不修改
- **不创建任何目录**：顶层结构与项目结构仅在文档中以目录树形式描述，不真实创建
- **防歧义**：文档内明确标注「本文档描述的目录结构为规划，非当前仓库实际结构」

## 落盘后验证

- 文件可读、markdown 结构完整
- 六大主章节齐全、目录树代码块正确闭合
- 支柱 3 占位显式可见、TODO 章节项数对齐上下文锁定清单