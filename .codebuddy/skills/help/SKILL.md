---
name: help
type: skill
status: active
description: Workshop capability index that explains available skills, agents, hooks, rules, and templates with usage examples.
---

# Help · 工作室能力说明书

## 何时使用

用户想了解工作室提供哪些能力、某个 skill 怎么用、或在多个 skill 之间犹豫时调用。区别于 `start`：
- `start` = 路由（"我帮你切到对的 skill"）
- `help` = 说明书（"工作室有哪些能力 / 某能力怎么用"）

典型触发：
- "/help"
- "工作室能做什么"
- "consistency-check 是干嘛的"
- "skill 列表"

## 输入 / 触发条件

- 可选：具体能力名（skill / agent / hook / rule / template 之一）
- 无参时默认输出工作室能力总览

## 流程步骤

1. **参数判断**：有具体名字 → 详细说明；无参 → 总览
2. **总览模式**：列出 5 类能力（skill 22 / agent 30 / hook 5 / rule 6 / template 9）+ 每类前 3 个常用项
3. **详细模式**：读对应文件（如 `.codebuddy/skills/<name>/SKILL.md`）→ 提炼"何时使用 + 流程 + 典型输入/输出"
4. **关联引导**：列出与查询项相关的其他 skill / rule
5. **使用示例**：给 1-2 个真实触发语示例

## 输出

- 终端内中文说明（不落盘）
- 详细模式可附"完整文档地址"链接

## 引用

- 上游规划：v4 §6.1.1
- 数据源：`.codebuddy/{skills,agents,hooks,rules,templates}/`
- 相关 skill：`start`

## Known Limitations / Phase 2 Review Points

- [Phase 2 TODO] 与 `start` 的边界靠 AI 判断，未来积累若干会话后可固化分流规则
- [Phase 2 TODO] 当能力数量增长（>50）时，总览模式需分页 / 索引
- [Phase 2 TODO] 跨语言用户（非中文母语）的英文输出模式未考虑
