---
name: create-epics
type: skill
status: active
description: Breaks GDD chapters into epics, each scoped to a coherent feature area deliverable in 1-3 sprints.
---

# Create-Epics · 拆分 epics

## 何时使用

GDD 已定稿、要进入开发前，把 GDD 章节拆成 epics。每个 epic 是 1-3 个 sprint 可完成的功能域。

典型触发：
- "/create-epics"
- "把 GDD 拆成 epics"
- `new-project` 后续路由（stage = pre-production）

## 输入 / 触发条件

- 当前在项目根
- GDD 已存在且通过 `design-review`（8 节完整）
- 可选：项目目标 milestone（用于优先级排序）

## 流程步骤

1. **读 GDD**：扫 8 节，识别可作为 epic 的功能域
2. **粗划**：AI 提议 5-15 个 epic 候选，每个含：
   - title（英文 kebab-case）
   - 一句话定位（中文）
   - GDD 章节引用
   - 粗估 sprint 数（1 / 2 / 3）
3. **依赖梳理**：标注 epic 间的依赖关系（前置 / 并行 / 阻塞）
4. **优先级排序**：按 milestone 倒推优先级
5. **交互修订**：用户对每个 epic 拍板"接受 / 修改 / 拆 / 合并 / 推迟"
6. **落盘**：`projects/<name>/epics/<epic-id>.md`
7. **路由提示**：建议下一步调用 `sprint-plan` 选 epic 进 sprint，或 `create-stories` 拆某个 epic

## 输出

- 一组 `projects/<name>/epics/<epic-id>.md`
- 终端内 epic 依赖图（mermaid 文本）

## 引用

- 上游规划：v4 §6.1.1
- 相关 skill：`design-review` `create-stories` `sprint-plan` `milestone-review`
- 相关 rule：`design-authoring` `project-structure`
- 相关 template：[Phase 2 TODO] epic.md.tpl（9 template 清单未列）

## Known Limitations / Phase 2 Review Points

- [Phase 2 TODO] epic 模板未在 9 template 清单中
- [Phase 2 TODO] 依赖图当前为 mermaid 文本，无可视化工具集成
- [Phase 2 TODO] 优先级排序逻辑靠 AI 判断，未来可加权重模型
