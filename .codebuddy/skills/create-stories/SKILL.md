---
name: create-stories
description: Breaks an epic into actionable user stories with acceptance criteria, tagged to GDD sections.
allowed-tools:
disable: false
---

# Create-Stories · 拆分 user stories

## 何时使用

把一个 epic 拆成可执行的 user stories。每条 story 是一个 sprint 内可完成的最小交付单元。

典型触发：
- "/create-stories <epic-id>"
- "把这个 epic 拆成 stories"
- 由 `create-epics` skill 末段引导调用

## 输入 / 触发条件

- 当前在某项目根（`projects/<name>/`）
- 目标 epic 已存在（`projects/<name>/epics/<epic-id>.md` 或在 GDD 中标注）
- 可选：sprint 容量参考（来自上一 sprint 的 velocity）

## 流程步骤

1. **读 epic**：解析 epic 的目标 / 范围 / 验收标准
2. **GDD 锚定**：找到 epic 对应的 GDD 章节（违反 `design-authoring` rule 时阻塞）
3. **粗拆**：AI 提议 3-8 条 user story，每条按 INVEST 原则（Independent / Negotiable / Valuable / Estimable / Small / Testable）
4. **交互修订**：用户对每条 story 拍板"接受 / 修改 / 拆 / 合并"
5. **细化**：每条 story 含：
   - title（英文 kebab-case）
   - 用户视角描述（中文："作为 X，我想 Y，以便 Z"）
   - 验收标准（中文，3-5 条）
   - 估算（XS / S / M / L / XL）
   - GDD 引用（章节锚点）
6. **落盘**：`projects/<name>/stories/<sprint>/<story-id>.md`，从 `templates/...` 中找 story 模板（**注**：当前 9 template 清单未列 story 模板，§9.4 兜底审计时评估）
7. **commit 建议**：`[story] add stories for <epic-id>`

## 输出

- 一组 `projects/<name>/stories/<sprint>/<story-id>.md`
- 终端内 stories 摘要表

## 引用

- 上游规划：v4 §6.1.1
- 相关 skill：`create-epics` `sprint-plan` `story-readiness` `design-review`
- 相关 rule：`design-authoring`
- 相关 template：[Phase 2 TODO] story.md.tpl（9 template 清单未列）

## Known Limitations / Phase 2 Review Points

- [Phase 2 TODO] story 模板未在 9 template 清单中
- [Phase 2 TODO] INVEST 自检靠 AI 判断，未来可加 hook 自动校验
- [Phase 2 TODO] 估算尺度（XS-XL）的具体含义需在工作室宪法中定义
