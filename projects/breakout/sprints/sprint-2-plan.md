# Sprint 2 · Plan

**起止**：2026-05-14 ~ 2026-05-21（1 周）
**目标**：完整体验闭环（道具 + 多关卡完整流程 + 主菜单 / 暂停）

> 注：实际编码部分在 Sprint 1 收尾日已经预先完成（autorun 模式批量推进）。本计划文档为产物锚点，事后填表。

## velocity

- Sprint 1 实际：10 pts
- Sprint 2 估值：12 pts（预先完成的工作量映射）

## 入选 stories（事后回填）

| ID | 标题 | Pts | 状态 | Epic |
|---|---|---|---|---|
| S2-01 | 道具基础（5 种 + 掉落）| 4 | done | E3 |
| S2-02 | 道具效果计时回滚 | 2 | done | E3 |
| S2-03 | 多关卡数据测试（21 cases）| 1 | done | E4 |
| S2-04 | 主菜单（标题 / 操作 / Start）| 2 | done | E5 |
| S2-05 | 暂停遮罩（ESC 切换）| 1 | done | E5 |
| S2-06 | Game Over / Win UX 优化（ESC 回菜单）| 1 | done | E5 |
| S2-07 | GameManager 单测套件（24 cases）| 1 | done | 技术债 |

合计 **12 pts**，已 100% done。

## 关键决策

- **multi_ball 简化为"清屏一行"**：完整多球管理超出 1 个 sprint 范围（详见 autorun-2026-05-14.md Issue #1），保留视觉刺激与道具差异化
- **测试驱动方式**：自写轻量框架（不引入 GUT），通过 `extends SceneTree` + `_initialize` + `quit(0/1)` 模式
- **autoload 解耦**：powerup_manager 改用 `Engine.get_main_loop().root.get_node("GameManager")` 弱引用，便于单测

## 完成产出

- 6 个新脚本：powerup.gd / powerup_manager.gd / main_menu.gd + 3 个 test 脚本
- 3 个新场景：powerup.tscn / main_menu.tscn / 主场景增加 PauseOverlay
- 测试 suite：3 个文件 / 52 cases / 100% 绿

## 风险/已记录

- Issue #1（multi_ball 简化）已存档，留 Phase 2 真正多球
- Sprint 2 实际是与 Sprint 1 合并 batch 完成，velocity 估算非真实分布

## Verdict

**SPRINT_PLANNED**（事后追认）
