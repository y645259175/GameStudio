---
project_name: mario-1-1
engine: godot
engine_version: 4.6.2
phase: dev
status: M5-clearable-via-cheat
created_at: 2026-05-15
last_updated: 2026-05-15
lead: ZStodio
---

# Super Mario Bros · World 1-1 复刻

## 一句话概述

经典 NES《超级马里奥兄弟》第 1-1 关复刻，目标是**单关完整体验**——奔跑、跳跃、踩敌、吃菇变大、打金币、进旗杆通关。

## 工作方式（重要）

**渐进式策划，先框架后细节**：

1. **第 1 轮**（已完成）：项目骨架 + 一句话概述
2. **第 2 轮**：GDD 8 节大框架，每节列出"我们要写哪些子项"，但内部留待第 3 轮填充
3. **第 3 轮**：往大框架里填血肉——具体动作动效 / 敌人 AI / 关卡布局 / 数值
4. **第 4 轮**：拆 epic / story，开始动手做
5. **第 5 轮**：可玩初版

每轮结束都通过 reviewer agent 审核，过了才进下一轮。

## 目标玩家

- 怀旧玩家（80-90 后熟悉原作）
- 平台游戏入门玩家
- 流程验证用途（验证工作室对**复杂度更高**的项目是否能跑通）

## 类型定位

2D Side-Scrolling Platformer · 单关复刻

## 引擎与平台

- Godot 4.6.2 / GDScript
- Windows PC
- 1280×720 viewport（原作是 256×240，按比例放大）
- 60 FPS

## 里程碑

| # | 里程碑 | 目标 |
|---|---|---|
| M1 | GDD 大框架 | 8 节标题 + 子项清单 |
| M2 | GDD 细节填充 | 全部子项有具体内容 + ux-spec / art bible |
| M3 | epic / story 拆分 + 数据表 | 可执行任务清单 |
| M4 | 核心玩法可玩（移动+跳+踩敌） | Sprint 1 done |
| M5 | 完整 1-1 关卡可通关 | Sprint 2 done |
| M6 | 美术 + 动画 + 音效完整 | Sprint 3 done |

## 范围约束

**只做**：1-1 关全部内容（含开始动画、过场、通关画面）
**不做**：1-2 / 1-3 等其他关卡、双人模式、世界地图

## 关联文档

- GDD：`projects/mario-1-1/gdd/`
- 数值表：`projects/mario-1-1/data/`
- 美术参考：`projects/mario-1-1/art/`

## Reference

- 原作：Super Mario Bros (NES, 1985, Nintendo)
- 关卡数据可参考：https://supermariobroswiki.com (网络资料)
