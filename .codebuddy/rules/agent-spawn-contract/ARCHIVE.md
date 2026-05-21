# Agent Spawn Contract · ARCHIVE

> 历史演化与判例。仅 RCA / postmortem / 架构溯源时查。
> 当前规则见 `RULE.mdc`（CORE）和 `MANUAL.md`（详细 SOP）。

## 演化时间线

### v1.0 · 2026-05-15（mario-1-1 起步）
- 初始 5 条契约（现状注入 / 任务模式 / 交付顺序 / 落盘 / IDE 工具）
- TPL-01 ~ TPL-04（实现 / milestone / GDD / bug）

### v1.1 · combo-A 进化（2026-05-17）
**触发**：bolt-1-1 retro 第六节 AP-01 "agent 自己干一切"——31 agent 利用率 < 10%。

**变更**：
- 新增 TPL-05 ~ TPL-08（资产评审 / 一致性审 / 测试 / commit review）
- 加"高频 spawn 模板库"段，让 main agent 复制粘贴即用
- spawn 默认 `mode: bypassPermissions` 避免权限弹窗打断

**效果**：platformer-2 M0 真 spawn 6 个不同 agent + 并行省时（详见 `studio/reports/evolution-combo-a-validation.md`）。

### v2.0 · combo-B 进化（2026-05-18）
**触发**：combo-A 速度证 / 质量未证 → 需要给 sub-agent 产出契约 + 自检机制。

**变更**：
- 新增 §知识注入协议：spawn 5 核心 agent 时强制 read output-schema.yaml + AGENT.md § 自检
- run.py 自动 inject（dev-story / milestone-review）
- 决策"不注入 playbook 全文"——按需查避免上下文爆炸

### v2.1 · 防截断协议（2026-05-19）
**触发**：platformer-2 story-002 engineer 写 220 行 player.gd 实际落盘 19 行（hook bug）。

**变更**：加 §防截断协议——交付前 read_file 验行数 < 80% 视为截断。

**根因修复**：pre-tool-bash.py hook bug（line 90/92-100 错误代码导致非 Bash 工具回传 modifiedInput）→ 已 fix。本协议作防御性兜底保留。

### v2.2 · 并行模式认知修正（2026-05-19）
**触发**：发现 sub-agent（无 name 参数 task）是串行等待，不是真并行；只有 team 模式（带 name + team_name）才真异步。

**变更**：
- 加 §并行模式选择指南
- milestone-review run.py + dev-story --shadow 输出提示改为推荐 team 模式

### v2.3 · BL-S017 项目上下文自动注入（2026-05-19）
**触发**：每次 spawn 都要在 prompt 手贴 PROJECT.md ~500 字符。

**变更**：加 §项目上下文自动注入——sub-agent 自己 read_file，main agent 不必手贴。

### v2.4 · TPL-05 v2 in-context 渲染强制（2026-05-19）
**触发**：AP-10 platformer-2 vertical slice 实玩崩——art-director 仅看 raw 资产判 APPROVE，但游戏内 SignalNetwork transform 链断裂导致管道全部不渲染。

**变更**：TPL-05 v2 强制要求 in-context 截图作为评审输入；没截图则 REJECT 任务。

### v2.5 · TPL-09 vertical slice 5 项清单（2026-05-19）
**触发**：AP-10 修法。

**变更**：新增 TPL-09——任何 vertical slice / playable level story 进 reviewing 时强制评审 5 项（camera / 边界 / 视觉 / 死亡 / 完成）。

### v3.0 · 渐进披露重构（2026-05-20）
**触发**：rule 765 行，每次 spawn 想用模板都得读完才知道用哪个，严重违反渐进披露原则。

**变更**：
- CORE（RULE.mdc）精简到 ~30 行，仅留 5 契约 + TPL 索引
- MANUAL（本文同目录）含详细契约说明 + 9 TPL 全文 + 协议段
- ARCHIVE（本文）收纳演化时间线 + 判例

**节省**：CORE 注入从 765 行降到 ~30 行（97% 缩减）。

---

## 判例

### §A1 · combo-A spawn 链路通电

详见 `studio/reports/evolution-combo-a-validation.md`：
- platformer-2 M0：3 agent 并行（designer + docs-writer + art-director）30 分钟产出 ~1500 行 GDD/README/style-guide
- 反馈轮次 0、main agent 0 代笔
- Verdict v1.0 → v1.1 修订：从 GATE_PASSED 降级 SPEED_PROVEN/QUALITY_UNPROVEN

### §A2 · combo-B 自检机制 + 截断事件

详见 `studio/reports/evolution-combo-b-validation.md`：
- engineer 第一次 self_rubric 6/6 PASS 但实际 19 行（hook bug 截断）
- reviewer 独立 review 发现 → 验证"质量机制有效"的第一个端到端证据
- shadow review 一致性：story-003 reviewer + qa-lead shadow 双 PASS

### §A3 · TPL-05 v2 真实捕获事故

2026-05-19 platformer-2 art-director 走 TPL-05 v2 in-context 评审：
- raw 4 资产看着 OK
- 但 in-context 截图发现管道全部不见
- 诊断到 SignalNetwork node `type="Node"` → transform 链断裂
- 同时发现 pipe_node.gd `rotation_steps` 缺 `@export`
- 修复后管道全部出现

这是 TPL-05 v2 / AP-10 修法的**首次成功捕获**，证明 in-context 强制有价值。

---

## 弃用记录

- 2026-05-19 ~~"playbook 自动注入最近 3 条 lesson"~~ → 改为"完全不自动注入，agent 按需 read"。原方案 token 成本仍高且 3 条选择无判定标准
- 2026-05-19 ~~"shadow 用同 batch task spawn"~~ → 改为强制 team 模式。原方案 shadow 会看到主 reviewer verdict 丧失独立性
- 2026-05-20 ~~"硬上限 200 行限制 playbook"~~ → 改为分级提醒（safe/notice/review/approval）。详见渐进披露架构

---

## 关联文档

- 当前 CORE：`RULE.mdc`
- 当前 MANUAL：`MANUAL.md`
- 反模式：`studio/docs/anti-patterns.md`
- combo-A validation：`studio/reports/evolution-combo-a-validation.md`
- combo-B validation：`studio/reports/evolution-combo-b-validation.md`
- 渐进披露架构：`studio/docs/progressive-disclosure-architecture.md`
