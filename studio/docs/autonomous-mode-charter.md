# 自主模式宪章 · Autonomous Mode Charter

> 工作室级团队约定。所有 agent / skill 在自主模式下都必须遵守。
> 这不是 rule 文件，而是宪章——所有相关 rule / skill / agent 通过引用本文件来共享同一套底线。

## 什么是自主模式

用户给出"完成 X 项目到 Y 标准，中间不停下确认"这类指令时，main agent 进入**自主模式**：

- 用户不在线（或不期望被打断）
- main agent 同时扮演 producer / qa / reviewer 多重角色
- 决策权下放给 main agent

## 核心原则

**自主模式 ≠ 妥协质量。**

自主模式只是"沟通方式"的简化（不每步确认），**不是质量门的简化**。所有 milestone gate / DoD / 测试标准与有人模式完全一致。

## 不可妥协的底线

### 底线 1 · 视觉真实性

- production 视觉必须使用真实资产（来自 `art-asset-pipeline` / 用户提供 / 已验证的免费素材）
- `ColorRect` / 纯色 `Polygon2D` 仅允许在测试 / 调试视图 / 显式 `_PLACEHOLDER_` 命名的临时占位
- 占位必须登记 `[VISUAL_DEBT]` backlog story，注明 due milestone
- **违反**：视为 milestone 不通过

### 底线 2 · 测试真实性

- 必须包含至少一条"真实玩家路径"测试（用 InputMap action_press 等真实输入 API）
- cheat / debug 模式必须在测试代码或 `#if DEBUG` 条件编译里，**不允许**进 production 代码
- "通过测试"不是看数量，是看**覆盖路径**：cheat-only PASS = 不算 PASS
- **违反**：milestone 不通过

### 底线 3 · Bug 预算

- 每个 milestone 完成时，已知未修 issue 数 ≤ 该 milestone 的 budget（默认 3）
- 超出 budget → 不允许进下一 milestone，必须先修
- "记 retro 后续修"**不能**作为 issue 的归宿；必须开 backlog story（带 priority + due milestone）
- 同一 issue 出现 ≥ 2 次或绕过会改架构 → 必须 spawn `debugger` 做 RCA，不允许拍脑袋绕过

### 底线 4 · 美术节奏

- 开发期至少 30% 任务是资产生成 / 视觉打磨（不允许"先功能后美术"完全分离）
- 每 sprint 结束截图存档（`projects/<name>/reports/screenshots/sprint-N.png`），由 `art-director` 给视觉 verdict
- key visual（关键视觉参考图）必须在开发期开始前就生成

## 可妥协的（且仅这些）

只有以下情况可以作为"绕过"理由：

- 外部平台 API 失败 / 限流 / 离线（如 timiai-image 队列爆满）
- 第三方依赖 bug 且无 workaround
- 用户提供的素材本身有问题
- 引擎 / 工具链 bug 且非短期能修

**注意**：在自主模式下"我没时间"**不算**理由。"我决定砍掉"也**不算**——必须是外部不可控因素。

## Milestone Gate 协议

自主模式下 main agent 宣布 milestone 完成前，**必须**：

1. 调用 `qa-gate` skill 走完整流程
2. spawn `reviewer` agent 做 milestone 评审
3. spawn `producer` agent 做 ship gate（至少一次）
4. 上述任一返回 BLOCKED → 不允许宣布完成

## 引用本宪章的 rule / skill / agent

- `dev-story` skill：在自主模式段引用本宪章
- `engineer` agent：视觉资产红线引用本宪章底线 1
- `tester` agent：真实路径测试引用本宪章底线 2
- `qa-gate` skill：milestone 强制门引用本宪章底线 3
- `art-director` agent：截图评审引用本宪章底线 4

## 历史教训（本宪章存在的原因）

- **2026-05-15 项目 A pivot 事故**：main agent 在自主模式下交付了 ColorRect 拼图 + 14 个未修 issue + cheat-only 通关测试，外形上"milestone PASS"但实质上是垃圾。复盘归档于 `projects/<project-A>/retros/2026-05-15-quality-failure-postmortem.md`（含旧命名审计痕迹，已加 disclaimer 标记 pivot）。
