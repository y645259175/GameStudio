---
project_name: bolt-1-1
engine: godot
engine_version: 4.6.2
phase: dev
status: pivot-from-mario-1-1
created_at: 2026-05-15
last_updated: 2026-05-15
lead: ZStodio
ip_disclosure: "Original work. No third-party IP, no resemblance to Nintendo Mario or other commercial titles."
---

# Bolt: Sector 1-1

## 一句话概述

工业风像素平台跳跃。机械豆 **Bolty** 在被废弃的 Sector 1-1 中前进，目标激活信号塔召唤主基地。

致敬经典 NES 时代横版平台跳跃手感（加减速 / 可变跳高 / 踩敌反馈），但视觉、角色、世界观全部原创。

## 项目背景（IP 说明）

本项目原始形态为 mario-1-1（Super Mario Bros 1-1 复刻），2026-05-15 因 IP 风险 pivot 为完全原创的 bolt-1-1：

- 主角换为机械豆 Bolty（圆头工业机器人，与马里奥的胡子大叔造型完全不同）
- 敌人 / 道具 / 关底元素全部原创命名 + 重新视觉设计
- 关卡 beat / 玩法机制 / 手感数值保留（这部分是技术学习的核心）
- 详细映射见 `docs/naming-map.md`，pivot 决策见 `retros/2026-05-15-quality-failure-postmortem.md`

## 类型定位

2D Side-Scrolling Platformer · 单关原创关卡 · 单人单局

## 目标体验

| 时刻 | 玩家心理 | 设计触发 |
|---|---|---|
| 0-3s | "我控制着这个小机器人" | 出生即可走，无开场剧情 |
| 3-8s | "他能跳，跳得有重量" | 第一只 Mossroll 在前方，必须跳过 |
| 8-15s | "踩头能赢！" | 第一只 Mossroll 安排在玩家"被迫跳起的落点" |
| 15-25s | "Cache Box 里有东西" | 第一个 Cache Box 给齿轮，第二个给 Power Berry |
| 25-40s | "我变大了！能撞砖块了！" | 吃 Power Berry 后立刻给一段砖块墙感受新能力 |
| 40-60s | "我被挑战了，我赢了！" | 双 Conduit 双 Mossroll 压力段 |

## 引擎与平台

- Godot 4.6.2 / GDScript
- Windows PC（主目标）/ Web HTML5（Phase 2）
- 1280×720 viewport，60 FPS
- 数据驱动：所有数值在 `data/*.json`

## 里程碑

| # | 里程碑 | 目标 | 状态 |
|---|---|---|---|
| M1 | GDD 大框架 | 8 节标题 + 子项清单 | ✅ done（mario-1-1 阶段）|
| M2 | GDD 细节填充 | 全部子项 + ux-spec + art bible | ✅ done（v1.2-ux-refined）|
| M3 | epic / story 拆分 + 数据表 | 可执行任务清单 | partial（task-list 替代）|
| M4 | 核心玩法可玩（移动+跳+踩敌） | Sprint 1 done | ✅ done |
| M5 | 完整 Sector 1-1 可通关 | Sprint 2 done | ⚠️ cheat-only PASS, real PASS pending |
| **M5.5** | **IP pivot + 原创资产 + 14 backlog 修复** | bolt 原创化 + 真实通关 + 视觉一致 | 🔄 in progress |
| M6 | 视觉打磨 + 完整过场 | Sprint 3 done | 🔲 待启动 |

## 范围约束

**只做（IN）**：
- Sector 1-1 完整关卡（出生 → 信号塔 → 基地过场）
- Bolty 三态：small / big / fire
- 敌人：Mossroll（巡逻）、Shellpod（绿甲，地面巡逻）
- 道具：Power Berry、Spark Bloom、Pulse Core（Phase 2）、Blue Crystal
- 关卡元素：地面、砖块、Cache Box、Conduit（含 1 个可进入金币房）、Cog 齿轮、Signal Tower、Outpost
- HUD：BOLTY 得分 / Cog 数 / SECTOR 标识 / TIME 倒计时

**不做（OUT）**：
- 1-2 / 1-3 等其他关卡
- 多人 / 世界地图 / 存档
- 水下 / 城堡内部
- 配置选项菜单（仅占位）
- 多语言（英文 HUD 占位）
- 移动端 / 自定义键位 / 自制音乐

## 关联文档

- GDD：`gdd/gdd-bolt-1-1.md`
- 命名映射：`docs/naming-map.md`
- 数值表：`data/`
- 美术参考：`art/`
- Backlog：`stories/backlog.md`
- 历史 retro：`retros/2026-05-15-*.md`

## 工作方式

按工作室 dev-story / qa-gate / autonomous-mode-charter SOP 推进。视觉资产红线 + 真实玩家路径测试 + bug 预算严格执行。
