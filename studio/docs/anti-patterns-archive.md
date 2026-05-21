# 反模式 ARCHIVE · 历史触发与演化

> **本文是 ARCHIVE 层**——仅 RCA / postmortem / debug 时查阅。**不参与任何自动注入或行数 lint**。
>
> 当前修法见 `anti-patterns.md`（MANUAL 层）；速读见 `anti-patterns-digest.md`（CORE 层）。

## 判例索引

| AP | 来源事件 | 项目 / 日期 | 锚点 |
|---|---|---|---|
| AP-01~08 | bolt-1-1 全周期 retro | bolt-1-1 / 2026-05-16 | §A1 |
| AP-07 实测铁证 | settings.json 权限失效复测 | 2026-05-18 | §A2 |
| AP-09 | combo-B story-002 engineer 截断事件 | platformer-2 / 2026-05-18 | §A3 |
| AP-10 | platformer-2 vertical slice 实玩崩 | platformer-2 / 2026-05-19 | §A4 |
| AP-11 | art-director in-context 评审找到 transform 链 bug | platformer-2 / 2026-05-19 | §A5 |

---

## §A1 · bolt-1-1 全周期事件（AP-01~08 来源）

**触发**：bolt-1-1 项目 2026-05-15 → 16 全周期 retro 沉淀 8 条反模式。

**关键数据**：
- 第二节："Agent 利用率：~10%"
- 第一节："用户反馈轮次 3"（多次"不对/不够好"才修对）
- 第六节列出 Anti-Pattern 1-8

**关联**：`studio/docs/retro-bolt-1-1-experience.md` 第六节

**演化**：
- 2026-05-18 v1.0 初始版本（AP-01~08）
- 2026-05-18 v1.1 加强 AP-07 描述
- 2026-05-19 v1.2 新增 AP-09
- 2026-05-19 v1.3 新增 AP-10 + 修复 AP-09 截断
- 2026-05-19 v1.4 新增 AP-11
- 2026-05-20 v2.0 渐进披露重构：完整版拆为 MANUAL（修法）+ ARCHIVE（历史）

---

## §A2 · AP-07 settings.json 权限失效实测铁证

**触发**：2026-05-18 团队反复遇到"配置写了但不生效"问题，做完整复测含重启 IDE。

**实测结果（含重启前后两轮）**：

| 配置 | 命令 | 期望（如生效）| 实际 |
|---|---|---|---|
| `permissions.allow: [Bash(New-Item:*)]` + `defaultMode: bypassPermissions` | `New-Item ...` | 不弹 | 不弹 |
| `permissions.deny: [Bash(New-Item:*)]`（关键反证） | `New-Item ...` | **应被拒绝** | **直接成功** |
| `hooks.PreToolUse: matcher=Bash` 指向脚本（脚本写日志 + 输出 deny JSON） | 执行 Bash 命令 | hook 写日志、deny 拦截 | **hook 从未被自动调用**，命令照旧执行 |
| **重启 IDE 后**，同上配置 | 执行 Bash 命令 | 加载新 hooks | **依然不调用** hook |
| 内置高危命令 `Remove-Item` 即使 allow 列表+hook allow JSON | `Remove-Item file.txt` | 不弹 | **强制弹窗** |

**结论**：CodeBuddy 当前版本 IDE **既不读取 `permissions`，也不加载 `hooks`**。schema 沿用 Claude Code 但实现未接入。

**关联**：
- 项目级证据：`.codebuddy/PERMISSIONS.md`（含完整实测 T1-T7 + 重启复测）
- 修法（强制约束）见 `anti-patterns.md` AP-07
- backlog：BL-S012 / BL-S013

---

## §A3 · AP-09 combo-B engineer 截断事件

**触发**：2026-05-18 platformer-2 story-002 engineer 写 player.gd ~220 行，实际落盘 19 行。声称 self_rubric 6/6 PASS 但 reviewer 发现截断 → REQUEST_CHANGES。

**根因**：pre-tool-bash.py hook bug（line 90/92-100 错误代码导致非 Bash 工具回传 modifiedInput → IDE 处理时截断）。

**修复**：
- 2026-05-19 修复 hook（删除错误的 modifiedInput 回传）
- 2026-05-19 v1.2 把"防截断"作为防御性条款保留为 AP-09

**关联**：BL-S023（hook 修复 done）/ BL-S024（replace_in_file 长 session 失败）

---

## §A4 · AP-10 platformer-2 vertical slice 实玩崩

**触发**：2026-05-19 platformer-2 M2 vertical slice 用户首次实玩 < 1 分钟发现：
1. 画面糟糕到不知道在玩什么（资产像但不对）
2. 镜头不动（根本忘了加 Camera2D）
3. 玩家走出屏幕也没反应（无边界）

**机制层证据全 PASS**：self_rubric 7/7 / reviewer APPROVE_WITH_NITS / shadow QA-PASS / headless EXIT 0 / 测试 16/18 PASS。

**根因深层**：
1. schema 是"代码契约"不是"产品契约"
2. reviewer / shadow 都是同代 LLM 共享盲区
3. 资产生成 ≠ 资产合用
4. 没有 playtest gate
5. GDD §4/§5/§6 写了但 engineer 实现时没真读

**历史回声**：bolt-1-1 retro 第六节 AP-06 说"用户反馈循环没有自动学习"——AP-10 是它的升级版：连用户反馈机会都没有。整个 platformer-2 M0-M2 全程 0 用户介入。这印证了 combo-A validation §一已警告"0 反馈 ≠ 做对"。

**修复**：
- BL-S031 dev-story 加 playtest_pending 状态（done）
- BL-S033 vertical slice 5 项清单 TPL-09（done）
- BL-S035 verdict 加 _MECHANISM 后缀禁止 AI 自宣 QUALITY_PROVEN（done）
- BL-P2-017 / 018 / 019 platformer-2 hotfix（done）

**关联文档**：
- combo-A validation：`studio/reports/evolution-combo-a-validation.md`
- combo-B validation：`studio/reports/evolution-combo-b-validation.md` v3.1（verdict 降级 QUALITY_FAILED）

---

## §A5 · AP-11 SignalNetwork transform 链事件

**触发**：2026-05-19 platformer-2 vertical slice 实玩反馈"管道完全看不到"。art-director spawn 走 TPL-05 in-context 评审找到 root cause。

**事件经过**：
1. main agent 自己看 raw 资产 PNG 觉得"还行"
2. 集成到 level_01.tscn 后用户实玩反馈管道不见
3. spawn art-director 看 in-context 截图（capture_00/01/02_x*.png）
4. art-director 发现 SignalNetwork 节点 `type="Node"` 而非 `Node2D` → transform 链断裂 → PipeA/B/C 全部渲染在世界坐标 (0,0)
5. 同时发现 pipe_node.gd 的 `rotation_steps` 是普通 var 没标 `@export`，scene tscn 设的 2 在运行时被默认 0 覆盖

**修复**：
- SignalNetwork node `type=Node` → `Node2D`，脚本 `extends Node` → `extends Node2D`
- pipe_node.gd `var rotation_steps` → `@export var rotation_steps`
- pipe_node.gd `_ready()` 加 `rotation_degrees = rotation_steps * 90.0`

**修复后效果**：管道全部出现 + 旋转正确。

**沉淀**：
- TPL-05 v2 强制 in-context 渲染评审
- screenshot 工具抽到 `studio/templates/godot-screenshot/`
- AP-11 收录 5 类常见根因清单
- BL-S038（consistency-check skill 加 transform 链断裂自动诊断）— open

---

## 弃用记录

记录历经讨论但已被替换的旧方案：

- 2026-05-19：~~playbook 季度归档机制~~ → 替换为"工作中临时缓冲区 → 阶段性筛选 → 并入 AGENT.md 本体 → playbook 清理"。原方案问题：归档未必触发，且每次注入 100+ 行 lesson 反向降低 agent 效能
- 2026-05-19：~~playbook inject 最近 3 条 lesson~~ → 替换为"完全不自动注入，agent 按需 read"。原方案问题：3 条选择缺乏判定，且仍有上下文成本
- 2026-05-19：~~硬上限阻塞写作~~ → 替换为"分级提醒（safe/notice/review/approval）"。原方案问题：反向激励 agent 凑到上限，且无法预见未来必要超限场景

---

## 修订历史

- 2026-05-18 v1.0 初始版本（bolt-1-1 retro 沉淀 8 条 AP-01 ~ AP-08）
- 2026-05-18 v1.1 加强 AP-07：补充 hooks 字段也不生效的实测铁证（含重启 IDE 复测）
- 2026-05-19 v1.2 新增 AP-09（sub-agent 声称 PASS 但未验证落盘完整性）
- 2026-05-19 v1.3 新增 AP-10（AI 自嗨循环：机制全 PASS 但产品不能玩）+ 修复 AP-09 段被截断
- 2026-05-19 v1.4 新增 AP-11（Godot 渲染层陷阱）
- 2026-05-20 v2.0 渐进披露重构：原 anti-patterns.md 拆为 MANUAL（修法）+ ARCHIVE（本文，历史触发）。digest 保持 CORE 不动
