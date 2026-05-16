# Studio Backlog · 工作室级未排期事项

> 所有**与具体项目无关、属于工作室运营改进**的事项都登记在这里。
> 项目级 issue 仍登记在 `projects/<name>/stories/backlog.md`。
>
> 创建：2026-05-16（bolt-1-1 经验复盘后建立）
> 触发：之前所有 BL-xxx 都散落在项目 backlog，studio 改进项无处登记 → 工作室级问题被掩盖

## 格式约定

类型枚举：
- `agent-improve` — 某个 agent 内容 / 边界 / 触发条件改进
- `skill-improve` — skill 真正可执行化（从文档变成 pipeline）
- `rule-enforce` — rule 加 hook / 校验脚本，从口头约定变强制
- `tooling` — 工具链（hook / pipeline / scripts）
- `sop-doc` — 流程文档（anti-patterns / case-study）
- `migration` — v4 迁移计划遗留项

## 未排期

| ID | 类型 | 标题 | priority | 来源 | 状态 |
|---|---|---|---|---|---|
| BL-S001 | sop-doc | 写 `studio/docs/anti-patterns.md`，沉淀 8 条通用反模式 + 检测信号 + 修法 | P0 | retro-bolt-1-1-experience | open |
| BL-S002 | agent-improve | 修 `agent-spawn-contract` rule，加 5 个高频 spawn 模板示例 + 完整 task prompt | P0 | retro-bolt-1-1-experience | open |
| BL-S003 | migration | v4 Phase 1 批 12 收尾扫：cross-reference 验证 + 修复断链 | P0 | v4-tasks.md 遗留 | open |
| BL-S004 | rule-enforce | commit-discipline rule 加 pre-commit hook 强制 [story]/[fix]/[chore]/[hotfix] tag | P0 | retro-bolt-1-1-experience | open |
| BL-S005 | skill-improve | `milestone-review` skill 端到端化（spawn 三方 agent + 自动写报告 + 落 backlog） | P1 | retro-bolt-1-1-experience | open |
| BL-S006 | tooling | timiai-image：image_edit 限流自动切 chat_image fallback | P1 | retro-bolt-1-1-experience | open |
| BL-S007 | tooling | godot 项目模板抽离到 `studio/templates/godot-project/`（player.gd / sprite_helper.gd / camera_follow.gd 等通用脚手架） | P1 | retro-bolt-1-1-experience | open |
| BL-S008 | tooling | session-start hook 注入 anti-patterns + 上次 session agent/skill 调用记录 | P1 | retro-bolt-1-1-experience | open |
| BL-S009 | migration | v4 Phase 1 批 7/8 抽查 5 个高频 agent（engineer/reviewer/qa/art-director/debugger）质量 | P1 | v4-tasks.md 遗留 | open |
| BL-S010 | rule-enforce | 9 个 rule 每个配 `validate.sh`，PreToolUse / pre-commit 跑 | P1 | retro-bolt-1-1-experience | open |
| BL-S011 | tooling | screenshot_tool 自动化：sprint 收尾 hook 自动跑 + spawn art-director 评审 | P2 | retro-bolt-1-1-experience | open |
| BL-S012 | tooling | settings.json 权限配置 helper：`add-bash-cmd <name>` 命令式工具 | P2 | retro-bolt-1-1-experience | open |
| BL-S013 | sop-doc | `studio/docs/codebuddy-environment-quirks.md`（IDE 插件 vs CLI / 复合命令审批 / .import 元数据等客户端行为） | P2 | retro-bolt-1-1-experience | open |
| BL-S014 | tooling | `daily-check` skill 加自动汇总 "今天 spawn 了哪些 agent / skill 利用率" | P2 | retro-bolt-1-1-experience | open |
| BL-S015 | sop-doc | 可访问性 SOP 模板（高对比 / 色弱 / 输入重映射 / 字幕系统）作为 GDD §6 UX 节常驻清单 | P2 | bolt-1-1 GDD 引出 | open |
| BL-S016 | tooling | image_edit 多次 429 → 自动写"限流冷却时间"到 cache，下次提交前先查 | P2 | M6.2 实战 | open |
| BL-S017 | agent-improve | 31 agent 启动时自动读 PROJECT.md + 当前 milestone backlog，不用 main agent 重复贴上下文 | P1 | retro-bolt-1-1-experience | open |
| BL-S018 | skill-improve | skill 从 markdown 升级到可调用工具：每个 skill 配一个 `run.py` 或 `run.sh` | P1 | retro-bolt-1-1-experience | open |

## 备注

- P0 = 严重影响下一项目质量（如不修，下次新项目还会犯同样错误）
- P1 = 显著提效或防再坑
- P2 = nice-to-have / 长线改进

每条 issue 关闭时：
1. 状态改 `done`
2. 写明 commit hash
3. 移到 "已完成" 段

## 已完成

（暂无）

## 关联文档

- 完整反思：`studio/docs/retro-bolt-1-1-experience.md`
- v4 迁移计划：`.codebuddy/plans/v4-tasks.md`（剩余 6 批未做完）
- 项目 backlog 对照（项目级 issue 不登记在这里）：`projects/<name>/stories/backlog.md`
