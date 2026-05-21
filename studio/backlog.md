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
| BL-S001 | sop-doc | 写 `studio/docs/anti-patterns.md`，沉淀 8 条通用反模式 + 检测信号 + 修法 | P0 | retro-bolt-1-1-experience | **done**（2026-05-20 · 实际沉淀 11 条 · digest 36 行 + manual 258 行 + archive 150 行 三层结构）|
| BL-S002 | agent-improve | 修 `agent-spawn-contract` rule，加 5 个高频 spawn 模板示例 + 完整 task prompt | P0 | retro-bolt-1-1-experience | **done**（2026-05-20 · MANUAL.md 共 9 个 TPL · TPL-01~09 含 implementer/designer/reviewer/qa/architect/debugger/refactor/art-director-review/vertical-slice）|
| BL-S003 | migration | v4 Phase 1 批 12 收尾扫：cross-reference 验证 + 修复断链 | P0 | v4-tasks.md 遗留 | open |
| BL-S004 | rule-enforce | commit-discipline rule 加 pre-commit hook 强制 [story]/[fix]/[chore]/[hotfix] tag | P0 | retro-bolt-1-1-experience | **done**（2026-05-19 · pre-commit-discipline.py + .git/hooks/commit-msg 挂载 + 3 case 测试通过）|
| BL-S005 | skill-improve | `milestone-review` skill 端到端化（spawn 三方 agent + 自动写报告 + 落 backlog） | P1 | retro-bolt-1-1-experience | open |
| BL-S006 | tooling | timiai-image：image_edit 限流自动切 chat_image fallback | P1 | retro-bolt-1-1-experience | open |
| ~~BL-S007~~ | ~~tooling~~ | ~~godot 项目模板抽离~~ | ~~P1~~ | ~~retro-bolt-1-1-experience~~ | **cancelled**（2026-05-21 · 用户决策：等有更稳定成熟的项目再做，目前模板会过早抽象）|
| BL-S008 | tooling | session-start hook 注入 anti-patterns + 上次 session agent/skill 调用记录 | P1 | retro-bolt-1-1-experience | **done**（2026-05-20 · session-start.py 已含 digest 路径指引 + 三层结构提示 · agent/skill 利用率统计仍待 BL-S014 完成）|
| BL-S009 | migration | v4 Phase 1 批 7/8 抽查 5 个高频 agent（engineer/reviewer/qa/art-director/debugger）质量 | P1 | v4-tasks.md 遗留 | **done**（2026-05-19 · architect 体检 5 agent · ARCH-MINOR_GAPS · designer/reviewer FAIR 已修补 · 报告 studio/reports/agent-audit-5core-2026-05-19.md）|
| BL-S010 | rule-enforce | 9 个 rule 每个配 `validate.sh`，PreToolUse / pre-commit 跑 | P1 | retro-bolt-1-1-experience | open |
| BL-S011 | tooling | screenshot_tool 自动化：sprint 收尾 hook 自动跑 + spawn art-director 评审 | P2 | retro-bolt-1-1-experience | open |
| BL-S012 | tooling | settings.json 权限配置 helper：`add-bash-cmd <name>` 命令式工具 | P2 | retro-bolt-1-1-experience | open |
| BL-S013 | sop-doc | `studio/docs/codebuddy-environment-quirks.md`（IDE 插件 vs CLI / 复合命令审批 / .import 元数据等客户端行为） | P2 | retro-bolt-1-1-experience | **done**（2026-05-19 · studio/docs/codebuddy-environment-quirks.md 已建 · 8KB）|
| BL-S014 | tooling | `daily-check` skill 加自动汇总 "今天 spawn 了哪些 agent / skill 利用率" | P2 | retro-bolt-1-1-experience | open |
| BL-S015 | sop-doc | 可访问性 SOP 模板（高对比 / 色弱 / 输入重映射 / 字幕系统）作为 GDD §6 UX 节常驻清单 | P2 | bolt-1-1 GDD 引出 | open |
| BL-S016 | tooling | image_edit 多次 429 → 自动写"限流冷却时间"到 cache，下次提交前先查 | P2 | M6.2 实战 | open |
| BL-S017 | agent-improve | 31 agent 启动时自动读 PROJECT.md + 当前 milestone backlog，不用 main agent 重复贴上下文 | P1 | retro-bolt-1-1-experience | **done**（2026-05-19 · agent-spawn-contract 加"项目上下文自动注入"协议）|
| BL-S018 | skill-improve | skill 从 markdown 升级到可调用工具：每个 skill 配一个 `run.py` 或 `run.sh` | P1 | retro-bolt-1-1-experience | **partial-done**（qa-gate / milestone-review / dev-story 已通电，详见 evolution-combo-a-validation） |
| BL-S019 | tooling | milestone-review run.py 解析 backlog 表格 false positive：把已 closed 项判 blocker（解析逻辑过保守）| P2 | combo-A validation | open |
| BL-S020 | skill-improve | dev-story `--action done` 后自动跑 consistency-check（当前只是文字提示）| P2 | combo-A validation | open |
| BL-S021 | tooling | session-start.sh 在 PowerShell 内嵌 git bash 时 `find projects` 返回 0（路径分隔符问题）| P2 | combo-A validation | open |
| BL-S022 | tooling | dev-story run.py 解析 PROJECT.md `engine` 字段时多行 yaml 解析错误（"godot\\nengine_version"）| P3 | combo-A validation | open |
| BL-S023 | tooling | **pre-tool-bash.py hook bug 影响所有非 Bash 工具**：line 90/92-100 错误代码导致 modifiedInput 无条件回传（含完整文件内容）→ write_to_file/replace_in_file 截断 + 参数异常。已于 2026-05-19 修复 | P0 | combo-B 实战 + hook 审计 | **done**（2026-05-19）|
| BL-S024 | sop-doc | replace_in_file 在长 session 中频繁失败（"old_str not found" / "found multiple times"）：根因 = 上下文过时 + old_str 选取不精确。需要写入 tool-usage rule "long session 卫生" 段 | P1 | combo-B 实战 | **done**（2026-05-19 · tool-usage rule §Long Session 卫生）|
| BL-S025 | rule-enforce | engineer 流程逃逸案例：story-004 时 engineer 直接重写 player.gd 而非走 dev-story re-implement。dev-story SOP 加"如发现需要重写已交付内容必须 spawn 新 story 或回 implementing 状态" | P1 | combo-B 实战 story-004 | **done**（2026-05-19 · tool-usage rule §流程逃逸禁令）|
| BL-S026 | rule-enforce | 跨 agent 数值一致性回路缺失：reviewer 发现 GDD 写 180px/s 而 story-AC 写 300px/s，无人裁定。需要 designer-engineer-reviewer 三方共识 SOP（数值变化时三方都要确认）| P1 | combo-B story-002 reviewer 发现 | **done**（2026-05-19 · tool-usage rule §数值一致性回路 + designer/reviewer AGENT.md 历史教训）|
| BL-S027 | tooling | Godot headless 测试只能 SMOKE，不能跑物理：`_physics_process` 在 headless 单帧模式无法执行 → tester 大量 SKIP。引入 GUT 框架或 multi-frame 测试方案 | P2 | platformer-2 tester SKIP 6 条 | **partial-done**（2026-05-19 · tool-usage rule §Godot Headless 测试限制 已写入应对 · GUT 引入待 M3）|
| BL-S028 | sop-doc | VISUAL_DEBT 不上 backlog 反模式：engineer 在 story 中提到债务但未真正登记到 stories/backlog.md。dev-story SOP 加"红线检查：debt_logged 字段必须能在 backlog 中被 grep 到" | P2 | platformer-2 BL-P2-010~013 漏登 | open |
| BL-S029 | rule-enforce | 知识精炼流第 4 步"删除已并入条目"被忽视：playbook.md 出现条目错乱（line 22 两条记录粘连 + 重复行）。SOP 应规定用 replace_in_file 精确删除而非 write_to_file 整体重写 | P2 | combo-B 知识总结实战 | open |
| BL-S030 | sop-doc | shadow review prompt 还是同 batch 而非 team 模式生成：dev-story/run.py 已在提示文字中改为 team，但实际 spawn 时 main agent 仍倾向用 batch task（行为惯性）。需要 SOP 明确"shadow 必须用 team mode"+ 示例 | P1 | combo-B story-003 shadow review | **done**（2026-05-19 · tool-usage rule §Shadow Review 必须 team mode）|
| BL-S031 | rule-enforce | **dev-story 状态机加 playtest_pending 状态（AP-10 修法）**：reviewing → playtest_pending → done。playtest_pending 必须真人玩家 ≥ 1 分钟实玩才能进 done，AI 不允许自跳。需要修改 `.codebuddy/skills/dev-story/run.py` 状态机 + RULE.mdc TPL-01 加体验维度 AC 模板 | P0 | platformer-2 实玩事故 | **done**（2026-05-19）|
| BL-S032 | sop-doc | **资产评审必须 in-context 渲染（AP-10 修法）**：art-director 不能只看 1024x1024 raw 图，必须看资产**在 level 里的截图**（缩放到目标尺寸 + 跟其他元素对比）。修改 art-director TPL-05 加截图集成步骤 | P0 | platformer-2 实玩事故 | **done**（2026-05-19 · TPL-05 v2 + studio/templates/godot-screenshot/ + AP-11）|
| BL-S033 | rule-enforce | **vertical slice 强制 5 项清单（AP-10 修法）**：camera follow / 屏幕边界 / 主角视觉辨识度 / 死亡反馈 / 完成反馈——任一缺失 reviewer 必须 REQUEST_CHANGES。写入 `agent-spawn-contract` 新增 TPL-09 vertical-slice 模板 | P0 | platformer-2 实玩事故 | **done**（2026-05-19 · TPL-09）|
| BL-S034 | sop-doc | **GDD ↔ 实现一致性 grep（AP-10 修法）**：每完成一个 story，main agent 必须 grep GDD 关键词（camera/boundary/feedback/death/win）确认是否在代码中体现。consistency-check skill 加此自动检查 | P1 | platformer-2 实玩事故 | open（已在 designer AGENT.md 历史教训中提示，consistency-check skill 改造待 M3）|
| BL-S035 | rule-enforce | **不允许 AI 自我宣布 QUALITY_PROVEN**：必须有用户实玩反馈作证据；只有机制 PASS → `QUALITY_MECHANISM_PROVEN`。更新 qa-gate / milestone-review verdict 词汇表 | P0 | platformer-2 实玩事故 | **done**（2026-05-19 · qa-gate run.py + milestone-review run.py verdict 全加 _MECHANISM 后缀）|
| BL-S036 | tooling | **3 层 hook 体系**（AP-10 后续设计修正）：SessionStart 精简引导 + UserPromptSubmit 按 prompt 关键词精准注入 + PreToolUse image_gen/Remove-Item 拦截 | P0 | hook 设计反思 | **done**（2026-05-19）|
| BL-S037 | tooling | **timiai-image SKILL.md 适配工作室**：加"零、首次必跑 _check_key.py"段 + 工作室 fallback 路径明确（key 不可用时降级流程）+ _check_key.py 自检脚本 | P0 | platformer-2 资产事故 | **done**（2026-05-19）|
| BL-S038 | tooling | consistency-check skill 加 transform 链断裂自动诊断（AP-11 修法）：扫描 .tscn 中 Node 类型节点是否有 Node2D/Control 子节点（错误的 transform 链断裂） | P1 | AP-11 来源 | open |
| BL-S039 | sop-doc | **AP-11 渲染层陷阱反模式**：transform 链断裂 / @export 缺失 / z_index 遮挡 — 资产 OK 但游戏内不渲染 | P0 | platformer-2 art-director in-context 评审找到 | **done**（2026-05-19 · anti-patterns.md v1.4 + digest 11 条）|
| BL-S040 | architecture | **渐进披露三层架构**（CORE / MANUAL / ARCHIVE）：rule/skill/agent 全部按三层组织。CORE 极简强制注入，MANUAL 按场景查阅，ARCHIVE 仅 RCA 时查 | P0 | rule/skill/agent 体积失控（rules 1523 / skills 2477 / agents 2089）| **done**（2026-05-20 · D-M1~M6 · CORE 减少 45.2% · 见 evolution-progressive-disclosure-validation.md）|
| BL-S041 | tooling | **UserPromptSubmit hook 关键词路由更新**：当前指向旧文档结构（如"美术任务 → timiai-image SKILL.md 全文"），改造后应指向 PLAYBOOK 具体段（"美术任务 → SKILL.md CORE + PLAYBOOK §1"）。同时加上"知识库三层结构"引导 | P1 | D-M6 风险 R4 | **done**（2026-05-21 · 6 条原规则全部更新指向 PLAYBOOK/MANUAL/HANDBOOK 具体段 + 新增 rule_progressive_disclosure 第 7 条 + 8/8 测试 PASS）|
| BL-S042 | sop-doc | **5 核心 agent ARCHIVE.md 逐步建立**：当前 CORE 引用了 ARCHIVE.md（待建），实际历史教训仍在 HANDBOOK 中。下次有新历史教训积累时再建（不凭空创作）| P2 | D-M6 风险 R3 | **done**（2026-05-21 · 5 个 ARCHIVE.md 全部建立 · art-director 86 / designer 62 / reviewer 81 / qa-lead 85 / engineer 140 行 · 历史教训从 HANDBOOK 分离 + 留指针 · 基于 platformer-2/bolt-1-1 真实判例不凭空创作）|

## 备注

- P0 = 严重影响下一项目质量（如不修，下次新项目还会犯同样错误）
- P1 = 显著提效或防再坑
- P2 = nice-to-have / 长线改进

每条 issue 关闭时：
1. 状态改 `done`
2. 写明 commit hash
3. 移到 "已完成" 段

## 已完成

（暂无完整 done；BL-S001 / S002 / S008 / S018 部分实现，详见 `studio/reports/evolution-combo-a-validation.md`）

## 关联文档

- 完整反思：`studio/docs/retro-bolt-1-1-experience.md`
- 反模式知识库（BL-S001 部分实现）：`studio/docs/anti-patterns.md` + `anti-patterns-digest.md`
- spawn 模板库（BL-S002 部分实现）：`.codebuddy/rules/agent-spawn-contract/RULE.mdc` § 高频 spawn 模板库
- combo-A 端到端验证报告：`studio/reports/evolution-combo-a-validation.md`
- v4 迁移计划：`.codebuddy/plans/v4-tasks.md`（剩余 6 批未做完）
- 项目 backlog 对照（项目级 issue 不登记在这里）：`projects/<name>/stories/backlog.md`
