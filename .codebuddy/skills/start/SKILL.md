---
name: start
type: skill
status: active
description: Entry point skill that identifies user intent and routes to the appropriate workshop or project-level skill.
---

# Start · 工作室入口 skill

## 何时使用

用户在新会话开始、不确定从哪个 skill 入手、或意图模糊时加载本 skill。典型触发：
- "我想开始一个新项目"
- "今天该做什么"
- "帮我看看现状"
- 未明确触发任何其他 skill 的初始指令

## 输入 / 触发条件

- 用户的自然语言初始指令
- 当前工作区根目录（用于检测是工作室根 / 项目根 / 空仓库）
- 现有项目状态（`projects/*/PROJECT.md` 是否存在）

## 流程步骤

1. **环境识别**：读 `studio/docs/studio-handbook.md` 与 `projects/*/PROJECT.md`，判断当前在工作室根还是某项目下
2. **意图分类**：把用户输入归为以下之一：
   - 新建项目 → 路由到 `new-project` skill
   - 日常开发 → 路由到 `dev-story` 或 `quick-fix` skill
   - 检查 / 验收 → 路由到 `daily-check` / `smoke-check` / `consistency-check`
   - 设计 / 评审 → 路由到 `design-review` / `architecture-decision`
   - 美术资产 → 路由到 `art-asset-pipeline`
   - 不确定 → 进入交互澄清（最多 3 个候选 skill 二选一）
3. **路由**：明确告知用户"我要切换到 `<skill-name>` skill"，加载目标 skill
4. **兜底**：如果意图无法归类，引导用户阅读 `studio/docs/studio-handbook.md` 或调用 `help` skill

## 输出

- 一句话路由说明（中文）
- 加载目标 skill 后由该 skill 接管

## 引用

- 上游规划：v4 §6.1.1（22 skill 工作室级 8 之首）
- 相关 skill：`new-project` `dev-story` `quick-fix` `daily-check` `help`
- 相关 rule：`project-structure`、`ai-effort-estimation`（涉及多步规划 / 时间估计时按此 rule 表述）

## Known Limitations / Phase 2 Review Points

- [Phase 2 TODO] 意图分类目前靠 AI 判断，无明确规则表；积累若干会话后可总结分类决策树
- [Phase 2 TODO] 与 `help` skill 的边界待打磨（help 偏说明书，start 偏路由）
