---
id: S1-01
epic: E1
priority: P0
estimate: 1
status: done
gdd-anchor: gdd/gdd-breakout.md#§1-引擎配置
completed-at: 2026-05-14
---

# S1-01 · Godot 项目初始化

**Epic**：E1 · 核心玩法原型
**GDD 锚点**：§1 引擎配置
**点数**：1

## User Story

作为工程师，我需要创建 Godot 4.x 项目骨架，以便后续 story 有统一的工程基础。

## 验收标准

- [ ] `projects/breakout/game/` 下有 `project.godot`
- [ ] 分辨率设定 1280×720
- [ ] 主场景 `main.tscn` 存在且可运行（空白窗口）
- [ ] 目录结构：`scenes/` `scripts/` `resources/` `assets/`

## 技术备注

- Godot 4.x，GDScript
- 渲染：Forward+
- 窗口模式：固定 1280×720，不可拉伸

