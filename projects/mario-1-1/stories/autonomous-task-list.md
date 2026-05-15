---
mode: autonomous
created: 2026-05-15
note: 自主运行模式下的任务清单，不走 pm 拆 epic 流程。每项完成打 [x]，遇阻碍记 issue。
---

# Mario 1-1 自主任务清单

## Sprint 1 (M4) · 核心玩法（已 done）

- [x] T1-01 Godot 项目骨架 + ConfigLoader autoload（已存在）
- [x] T1-02 InputManager 键位映射（已存在 project.godot input map）
- [x] T1-03 Player 节点 + 走/跑加减速 + 转身减速（已存在 player.gd）
- [x] T1-04 Player 跳跃（可变高度 + 重力切换）（已存在）
- [x] T1-05 Player 状态机骨架 SMALL/BIG/FIRE/DEAD（已存在）
- [x] T1-06 简单关卡 + Camera2D follow（已存在 main.tscn）
- [x] T1-07 headless --check-only 通过

## Sprint 2 (M5) · 完整 1-1 关卡

### 关卡载入
- [ ] T2-01 LevelLoader：读 data/levels/1-1.json 生成实体
- [ ] T2-02 Tile 系统：地面 ground + 坑 pits → StaticBody2D
- [ ] T2-03 关卡边界（左不出生点墙 / 右关卡终点 / 下死亡线）

### 敌人
- [ ] T2-04 Goomba：巡逻 + 撞墙反向 + 被踩死
- [ ] T2-05 Koopa Green：巡逻 + 被踩缩壳 + 踢壳弹射

### 砖块系统
- [ ] T2-06 普通砖块：小态顶颠动 / 大态砸碎
- [ ] T2-07 问号块：active/used 状态 + 顶后产出
- [ ] T2-08 隐藏砖块（hidden_oneup）

### 道具
- [ ] T2-09 SuperMushroom：生成 + 移动 + 拾取变大
- [ ] T2-10 FireFlower：生成 + 拾取变火力
- [ ] T2-11 Coin：拾取 + +200 + 100 coin = +1UP
- [ ] T2-12 1UPMushroom：从 hidden_oneup 砖出
- [ ] T2-13 Star（暂可省，标记 nice-to-have）

### 关底
- [ ] T2-14 Flagpole：触杆 + 滑下 + 分段计分
- [ ] T2-15 Castle：进城堡 + WORLD CLEAR

### 流程
- [ ] T2-16 死亡 / 重生 / 命数耗尽 → GameOver
- [ ] T2-17 TIME 倒计时 + ≤100 警告
- [ ] T2-18 暂停 ESC

### 验证
- [ ] T2-19 headless 跑通 - 不死亡通关一次

## Sprint 3 (M6) · 美术音效（占位等级）

- [ ] T3-01 HUD：MARIO + 分数 / coin / WORLD / TIME
- [ ] T3-02 Player 状态视觉占位（已有 ColorRect 颜色切换，OK）
- [ ] T3-03 敌人视觉占位
- [ ] T3-04 砖块/问号块/管道视觉占位
- [ ] T3-05 旗杆/城堡视觉占位
- [ ] T3-06 标题界面 + Press SPACE
- [ ] T3-07 通关界面 + 时间结算
- [ ] T3-08 暂停画面
- [ ] T3-09 音效 → Phase 2 TODO（无版权资源）
- [ ] T3-10 BGM → Phase 2 TODO

## DoD 验收（M6 完成时跑）

- [ ] DoD-01 双击 exe 5s 内可控（自主模式跳过 exe，用 godot 启动验证）
- [ ] DoD-02 不死亡 < 200s 通关
- [ ] DoD-03 3 种死亡触发
- [ ] DoD-04 死亡 < 1.5s 重生
- [ ] DoD-05 3 种状态转换
- [ ] DoD-06 关卡 6 个 Beat 出现（与 GDD 对齐）
- [ ] DoD-07 HUD 实时正确
- [ ] DoD-08 隐藏内容触发
- [ ] DoD-11 暂停可用
- [ ] DoD-12 30min 无 crash（自主模式简化为 5min）
- [ ] DoD-13 数值表与代码解耦

## 自主模式简化项

| 项 | 简化 | 原因 |
|---|---|---|
| 音效 / BGM | 不做 | 无版权资源 / Phase 2 |
| pm/architect agent spawn | 不调用 | 直接执行更快 |
| 美术资产真实绘制 | 用 ColorRect 占位 | M6 优先表现 |
| 单元测试 | 仅关键逻辑 | 时间预算 |
| reviewer 终审 | 不调用 | 自检 + headless 通过即可 |
| Star（无敌道具） | 跳过 | nice-to-have，1-1 可选 |
| 移动平台 B5 段 | 简化 / 跳过 | 复杂度高，1-1 玩家不必需 |
| Piranha Plant | 跳过 | 占位级别即可 |
