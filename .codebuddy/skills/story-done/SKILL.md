---
name: story-done
description: Story closure flow that verifies acceptance criteria, updates status, and triggers consistency-check.
allowed-tools:
disable: false
---

# Story-Done · Story 完成验收

## 何时使用

一条 story 实现完成、要标记 done 时调用。是 `dev-story` 的退出动作。

典型触发：
- "/story-done <story-id>"
- "这个 story 做完了"
- `dev-story` skill 末段自动调用

## 输入 / 触发条件

- 当前在项目根
- 目标 story 状态 = in-progress
- 相关代码改动 / 配置改动已落盘

## 流程步骤

1. **验收标准逐条核对**：把 story 验收标准列出来，AI + 用户逐条 ✅ / ❌
2. **不通过处理**：任一条 ❌ → 中止本 skill，提示返回 `dev-story`
3. **consistency-check**：调用 `consistency-check` skill，critical > 0 则中止
4. **state 更新**：story frontmatter `status: in-progress → done`
5. **velocity 累加**：把 story 估算计入当前 sprint velocity
6. **commit 建议**：`[story] done <story-id>: <短描述>`
7. **路由提示**：当前 sprint 还有 in-progress story → 提示选下一个；全部 done → 提示 `smoke-check`

## 输出

- 更新后的 story 文件（status = done）
- 终端内验收摘要 + velocity 更新 + 路由建议

## 引用

- 上游规划：v4 §6.1.1
- 相关 skill：`dev-story` `consistency-check` `smoke-check` `sprint-plan`
- 相关 rule：`commit-discipline` `design-authoring`

## Known Limitations / Phase 2 Review Points

- [Phase 2 TODO] velocity 累加机制依赖 sprint-plan 的"容量已装载"字段，需对齐
- [Phase 2 TODO] 验收标准核对当前是 AI 提问 + 用户回答，未来可加自动化测试钩子
- [Phase 2 TODO] story 跨 sprint（carry-over 的 story 完成）时 velocity 归属哪个 sprint 未定义
