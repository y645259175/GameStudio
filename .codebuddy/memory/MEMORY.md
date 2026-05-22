# 工作室长期记忆 · MEMORY.md

> 跨会话稳定事实。短期/日常工作笔记请写到 `YYYY-MM-DD.md` 而非这里。

## 用户偏好与原则

- **AI 估时原则**（已并入 update_memory ID 59617001）：
  按"改动行数 + 不确定性"评估，不要用人类工时直觉。模板化重构 100-500 行 ≈ 几秒，文件数 ≠ 复杂度。
- **不接受硬上限**（lint 阈值设计反馈）：
  分级提醒（safe/notice/review/approval）优于硬上限——硬上限会反向激励"凑到上限"且不能预测未来。
- **不喜欢"留 backlog 当收尾"**：如果剩下任务几分钟可做完，直接做完。"分阶段确认"在模板化任务里是浪费。
- **关注"是否真在工作"而不是"是否完整"**：偏向用证据/数据评估系统，反感百科全书式堆砌。

## 项目级架构约定

- **四层架构**：`.codebuddy/`（能力层）+ `studio/`（工作室层）+ `engine/`（引擎层 gitignored）+ `projects/`（项目层）
- **不在根目录建文件**（除 README.md）
- **路径不引用 `analysis-report/` 或 `my-game/`**（历史遗留，已迁走）
- **新建项目前必须** `read_file studio/docs/project-structure-full.md`

## 文件 / 文档分层（渐进披露三层架构）

> 来源：D 系列改造（2026-05-20~21），见 `studio/docs/progressive-disclosure-architecture.md`

每个 rule / skill / agent 三层：
- **CORE**（`RULE.mdc` / `SKILL.md` / `AGENT.md`）：身份 + 红线 + 索引（每次注入 / spawn 必带）
- **MANUAL / PLAYBOOK / HANDBOOK**：详细 SOP / 模板（按需 read_file）
- **ARCHIVE**：历史判例（仅 RCA / postmortem 时查）

文件改动有 lint 分级提醒（不硬上限）：
- 30/40 行 → notice（写日志不阻塞）
- 50/60 行 → review（必须加 `<!-- OVER_LIMIT_REASON: ... -->` 自审）
- 80/100 行 → approval（commit msg 加 `[layer-override]` 表示用户已审批）

`.codebuddy/scripts/check_progressive_disclosure.py` 是 lint 工具，已挂到 commit-msg hook。

## 项目状态（2026-05-22）

### 历史项目（已不再处理）
- **bolt-1-1**：M6.2 完成，已归档
- **platformer-2**：vertical slice 实玩崩教训沉淀为 AP-10/11 后归档（2026-05-21 入库）

### 正在用的基础设施
- **挂载工作的 hook**（4 个）：
  - SessionStart → `session-start.py`（精简引导）
  - UserPromptSubmit → `user-prompt-route.py`（7 条关键词路由）
  - PreToolUse → `pre-tool-bash.py`（拦危险操作 + auto-allow）
  - git commit-msg → `pre-commit-discipline.py`（强制 [tag] + 渐进披露 lint）

### 关键反模式（11 条 AP）
速读：`studio/docs/anti-patterns-digest.md` (CORE)
完整 SOP：`studio/docs/anti-patterns.md` (MANUAL)
历史判例：`studio/docs/anti-patterns-archive.md` (ARCHIVE)

最严重的 3 条：
- **AP-10** 自嗨循环：AI 自己宣布质量 PROVEN（必须有用户实玩反馈）
- **AP-11** 渲染层陷阱：transform 链断裂 / @export 缺失 → 资产 OK 但游戏内不渲染
- **AP-04** 凭直觉清理：看到"不被引用"就删，没看用途

## 已知严重缺陷（截至 2026-05-22）

> 详见 `studio/reports/system-health-2026-05-22.md`

1. **可执行 skill 仅 12%**：18/25 个 skill 是纯文档（main agent 只能 read 模仿）
2. **三层化只覆盖 5 核心 agent**：剩余 26 个 agent 没经过 D 系列改造
3. **零度量**：`.codebuddy/logs/` 只有 PreToolUse 日志，没有 agent spawn / skill 调用记录 → **不知道系统真实利用率**

## CodeBuddy IDE 环境约定

- **禁止用 shell 命令做文件操作**：用 IDE 工具 `read_file` / `write_to_file` / `replace_in_file` / `delete_file`
- **PowerShell 中文 + emoji 易触发 GBK 编码错误**：用 `$env:PYTHONIOENCODING="utf-8"` 或重定向到文件读取
- **commit msg 含中文 / 多行**：必须用 `git commit -F file.txt`，不能用 `-m`
- **CodeBuddy 高危关键词扫描**：`Remove-Item` / `rm` / `del` / `git reset --hard` 弹窗 hook 之前拦——绕过见 `.codebuddy/PERMISSIONS.md`
