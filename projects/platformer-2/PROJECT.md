# Project · platformer-2

> **状态**：本项目是**工作室进化方案 combo-A 的端到端验证项目**（详见 `studio/docs/retro-bolt-1-1-experience.md` 与 `studio/backlog.md` BL-S001-S008）。
>
> 与 bolt-1-1 / breakout 的区别：本项目从 M0 起**强制使用 spawn 模板 + run.py**，main agent 不允许独角戏。**所有 GDD / README / art guide / story 都必须 spawn agent 产出**。

## Metadata

- **engine**: Godot 4.6.2
- **engine_version**: v4.6.2-stable
- **stage**: production
- **phase**: M2
- **created**: 2026-05-18
- **purpose**: 验证 combo-A 进化方案（agent 利用率从 10% → ≥ 50%）

## 当前 milestone

- **M0** · GDD + 项目骨架（pre-production）
- **M1** · 核心循环 prototype（→ production）
- **M2** · vertical slice（1 个完整 level + 视觉资产）

## 核心约束（攻心验证用）

| 约束 | 说明 |
|---|---|
| **C-1 · 0 main-agent-only artifact** | GDD / README / 关键代码 / 测试 / art review 必须由 sub-agent spawn 产出 |
| **C-2 · 100% 走 spawn 模板** | 每次 spawn 必须使用 `agent-spawn-contract` rule 末尾模板库的某个 TPL-XX |
| **C-3 · 100% 走 run.py** | dev-story / qa-gate / milestone-review 必须用 run.py 触发，不允许 main agent 自己仿写报告 |
| **C-4 · 反模式自检** | 每次 milestone 触发 anti-patterns digest 自检 |

## 游戏设计简介（待 designer agent 完整起草）

- **类型**: 2D 平台跳跃 + 拼图（pipe puzzle 元素）
- **主题**: 蒸汽朋克 / 信号塔（与 bolt-1-1 同世界观但不同地图）
- **核心循环**: 跳跃 + 解锁 + 计时挑战
- **目标周期**: M0-M2 一周内完成

> 实际 GDD 8 节内容**严格不允许 main agent 直接撰写**，必须 spawn `designer` agent 用 TPL-03 起草。

## 链接

- 进化方案：`studio/docs/retro-bolt-1-1-experience.md`
- studio backlog：`studio/backlog.md`
- 反模式知识库：`studio/docs/anti-patterns.md`
- spawn 模板库：`.codebuddy/rules/agent-spawn-contract/RULE.mdc` § 高频 spawn 模板库
- 验证报告（待生成）：`studio/reports/evolution-combo-a-validation.md`
