# Breakout Regression Matrix

> Sprint 2 起，每次 commit 前 / sprint 结尾 跑此清单

## 自动化 (`run-tests.ps1`)

| Suite | Cases | Pass | Fail | 上次跑 |
|---|---|---|---|---|
| Levels Data | 21 | 21 | 0 | 2026-05-14 |
| GameManager | 24 | 24 | 0 | 2026-05-14 |
| PowerupManager | 7 | 7 | 0 | 2026-05-14 |
| **TOTAL** | **52** | **52** | **0** | — |

## 引擎校验

```
godot --headless --check-only --path projects/breakout/game --quit
```

| 时间 | EXIT |
|---|---|
| 2026-05-14 22:10 | 0 ✅ |

## 手动测试场景

### 启动 / 主菜单
- [x] 直接打开项目能进入主菜单
- [x] 标题 BREAKOUT 居中、显示控制说明
- [x] SPACE 进入游戏
- [x] ESC 退出

### 核心玩法
- [x] 挡板左右移动（A/D 或 ←/→）
- [x] SPACE 发球后球反弹
- [x] 球碰挡板按位置反弹角度
- [x] 球碰砖块上下/左右正确反弹（不穿透）
- [x] 球出底部扣 1 命
- [x] 3 命用完触发 Game Over

### HUD
- [x] Score 实时更新
- [x] Lives 心形 ♥ 实时更新
- [x] Level 实时更新

### 砖块
- [x] HP 1 砖块（蓝色）一击碎
- [x] HP 2 砖块（绿色）二击碎，第一击变色 + 闪白
- [x] HP 3 砖块（黄色）三击碎，逐级变色
- [x] 不可破坏砖块（灰色）打不掉，闪白反馈

### 关卡切换
- [x] 第 1 关全清后自动进第 2 关
- [x] 球速逐关递增 300 → 460
- [x] 通关第 5 关显示 YOU WIN + 生命奖励

### 道具
- [x] 砖块销毁有概率掉道具
- [x] wide_paddle (W, 绿) → 挡板加宽 10s
- [x] narrow_paddle (N, 红) → 挡板缩窄 10s
- [x] speed_ball (S, 黄) → 球加速 8s
- [x] multi_ball (M, 蓝) → 立即清除一行砖块（简化版，详见 autorun Issue #1）
- [x] extra_life (+, 粉) → 生命 +1（封顶 5）
- [x] 单局封顶 6 个道具

### 暂停 / 恢复
- [x] 游戏中按 ESC 暂停（球停 + 半透明遮罩 + PAUSED 文字）
- [x] 暂停时再按 ESC 恢复
- [x] Game Over / Win 时按 ESC 回主菜单（不进暂停状态）

### 重启
- [x] Game Over 按 SPACE 从第 1 关重新开始
- [x] Win 按 SPACE 从第 1 关重新开始

## 已知问题（Phase 2 待办）

1. multi_ball 简化为"清行"，真正的多球管理留 Phase 2
2. 无音效（GDD §3 提及但 Sprint 1-2 未实施）
3. 道具掉率 / 持续时长尚未 playtest 校准
4. 无设置菜单（音量 / 控制重映射）
