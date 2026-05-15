---
date: 2026-05-15
phase: phase-1 design
type: postmortem
severity: medium
status: resolved
---

> **历史档案 · 2026-05-15 之前命名版本**
>
> 项目已在 2026-05-15 pivot 至 bolt-1-1 完全原创版本。
> 本档案保留旧命名作为审计痕迹，不代表当前项目状态。
> 当前命名见 `docs/naming-map.md`，当前 GDD 见 `gdd/gdd-bolt-1-1.md`。

# Postmortem · GDD detail 阶段 multi-agent spawn 事故

## 事故概述

为 `mario-1-1` 的 GDD detail 阶段组建团队 `mario-gdd-detail`，spawn 三个 agent 并行工作：

- `designer-1`（§1/§2/§4/§6/§8）
- `art-director-1`（§3）
- `ux-designer-1`（§3.6 + §7）

结果：

1. designer-1 与现有 999 行 reviewed 版 GDD 产出冲突的"独立从零起草"版本
2. art-director-1 落盘 `section-3-visual.md`（200 行），与现有主 GDD 中的 §3 内容并存（重复）
3. ux-designer-1 在 shutdown_response 的 reason 字段里声称"提交 §3.6 + §7"，但实际产出**从未送达**（reason 不是交付通道）

## 直接原因

main agent（即我）在 spawn 三个 agent 时：

| 失误 | 后果 |
|---|---|
| 没 read 现有 GDD 现状 | agent 不知道有 999 行 reviewed 版本 |
| 没在 prompt 注入现状 | agent 各自从零起草 |
| 没声明任务模式（DRAFT / REFINE / PATCH） | agent 默认选最大动作 = 重写 |
| 没要求"先 message 交付，再 shutdown" | ux-designer-1 把产出写在 reason 字段丢失 |
| 没要求"落盘到指定 path" | art-director-1 自己选了独立文件路径，与主 GDD 脱节 |

## 根本原因

工作室此前**没有"agent spawn 协议"层面的 rule**。`design-review` skill 的 Step 3 只说"调用 designer agent"，没有任何关于现状注入 / 模式声明 / 交付协议的硬性约束。

## 修复

落地以下变更（已完成）：

1. ✅ 新建 `rules/agent-spawn-contract/RULE.mdc` —— 4 条硬性契约：
   - 契约 1 · 现状注入
   - 契约 2 · 任务模式声明（DRAFT / REFINE / PATCH / REVIEW）
   - 契约 3 · 交付-关闭顺序（先 message 交付，再 shutdown_response）
   - 契约 4 · 落盘强制（output_path + verify）

2. ✅ 重写 `skills/design-review/SKILL.md` 的 Step 3，整合上述 4 条契约 + 多 agent 并行的额外要求

3. ✅ 在以下 skill 加载 `agent-spawn-contract` rule：
   - `dev-story`
   - `art-asset-pipeline`
   - `architecture-decision`
   - `design-review`

## Action Items

| # | Action | 责任人 | 时机 |
|---|---|---|---|
| AI-1 | 决策本次产出处置：丢弃 / 部分 merge / 重启 diff 评审 | producer + 用户 | next session |
| AI-2 | ux-designer-1 的 §3.6 / §7 内容缺失 → 下次重 spawn 时严格遵守新契约 | main agent | next session |
| AI-3 | 把 `agent-spawn-contract` 列入 `help` skill 的"必读 rule"清单 | docs-writer | 下个 sprint |
| AI-4 | 跨项目复盘：检查其他项目（breakout）是否也有类似 spawn 事故 | postmortem-keeper | 下个 sprint |
| AI-5 | **HANDOFF · Patch-07**：1-1 是否保留可进入管道（金币房）作为 P1 功能由 designer 决定。当前 §6.3 / §6 Beat 4 已写"管道下方水管房（金币雨）"，但 §3.6 VFX-22 标 NEED_HANDOFF。决议落 ADR | designer | next session |

## 后续状态（更新 2026-05-15 18:40）

- ✅ AI-1 已解决：选择方案 B 人工 merge，§3.1/§3.2/§3.5/§3.7/§3.8 已合并 art-director-1 的 `section-3-visual.md`（归档至 `reports/archive/`）；designer-1 的 IN/OUT 范围声明 + 3 条新风险已 cherry-pick；其余从零起草版本丢弃
- ✅ AI-2 已解决：重 spawn ux-designer-2 走新契约，交付 15 条补丁清单，全部已合入 GDD v1.2
- 当前 GDD 版本：`v1.2-ux-refined`

## 教训（一句话）

> spawn agent 不是"叫人来干活"，而是"派发一份带现状 + 模式 + 交付协议的契约"。缺任何一项，agent 都会自由发挥，并行时必互冲。
