---
id: ADR-0001
title: multi_ball 道具阶段性简化为 row_clear
status: accepted
date: 2026-05-14
---

# ADR-0001: multi_ball 道具阶段性简化为"清除一行砖块"

## 状态
**accepted**（Sprint 2，待 Phase 2 重新评估）

## 背景

GDD §4 S3 道具系统中 `multi_ball` 被定义为"立即生成 +2 球同时存在"，与扩板/缩板/加减速/+1 命构成 5 种道具的差异化效果。

实施时发现：当前架构下 ball 是 main.tscn 的单一 Area2D 节点，整个游戏多处假设单球：
- 碰撞检测（main.gd._check_*_collisions）只面向 1 个 ball
- HUD 与 game_over 流程基于 "ball.is_launched / ball.position.y > 740" 单球判断
- BallTrail（Line2D）只跟随单球
- bricks_remaining 与计分的 emit 时机假设球生命周期单一

真正的多球需要：
1. 把 ball 抽象为对象池 + 集合管理
2. 碰撞检测改为遍历所有球
3. 球丢失只在"最后一球"时触发 lose_life
4. BallTrail 多实例
5. 物理同步与帧预算评估

工作量约 3-5 pts，超出 Sprint 2 已规划范围。

## 候选方案

### A · 完整多球（按原 GDD）
- ✅ 与 GDD 完全一致
- ❌ 1 个 sprint 装不下；推迟其他 epic
- ❌ 风险：性能 / 信号风暴未评估

### B · multi_ball 简化为"立即清除一行随机砖块"
- ✅ 保持 5 种道具差异化
- ✅ 视觉冲击力强（清屏快感）
- ✅ 0.5 pt 实现（已完成）
- ❌ 与 "multi_ball" 命名不符；新人会困惑

### C · 删除 multi_ball，替换为另一种道具
- ✅ 命名一致
- ❌ 道具池缩到 4 种，弱化系统
- ❌ 已生成的美术 / 字母 "M" 标识浪费

## 决策

**采用方案 B**，但显式记录命名不一致：

- 在代码中保留 `powerup_type = "multi_ball"`（避免改 levels.json + powerup.gd + powerup_manager.gd 多处）
- 在 powerup.gd 的 ICONS 中标识 "M"
- 在 GDD §4 S3 / qa/regression-matrix.md / autorun log 全部记录"当前实现 = 清行 / 命名沿用 multi_ball"
- 加一行注释在 powerup_manager.gd 的对应 case：`# 简化版：立即销毁一行砖块（详见 autorun-2026-05-14.md Issue #1）`

## 后果

### 正面
- Sprint 2 按计划 12 pts 内完成
- 保留道具系统完整 5 种差异化
- 玩家体验：清屏的爽快感作为强力道具，可能比"多 1 个球"更直观

### 负面
- 命名 ↔ 行为偏离，新加入开发者需要读 ADR 才知情
- 真正的多球留到 Phase 2，需要重构 ball 集合管理

### 缓解
- ✅ 已加注释
- ✅ Phase 2 候选 epic E7 "Multi-ball 真正实现"
- ⚪ 后续如果决定不做真多球，可改名 powerup_type="row_clear"（一次性 commit）

## 受影响的代码 / 文档

- `projects/breakout/game/scripts/powerup_manager.gd:78-80`
- `projects/breakout/game/data/levels.json:101`（powerups.types 数组）
- `projects/breakout/gdd/gdd-breakout.md` §4 S3
- `projects/breakout/qa/regression-matrix.md`
- `projects/breakout/epics/README.md`（E7 候选）
- `.codebuddy/plans/autorun-2026-05-14.md` Issue #1

## 引用

- Reviewer 评审建议 P0：`REVIEW-APPROVE` 条件性通过，要求记录 multi_ball 简化
- agent: reviewer (sonnet) / architect (opus)
