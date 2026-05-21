---
id: story-002-player-movement
status: done
priority: P0
milestone: M1
gdd_anchor: gdd-3-mechanics.md §4.2
---
# Story-002 · 主角移动与跳跃

## 描述

实现 Vex Pell（主角）的基础移动系统：地面跑动 + 单跳 + 壁面附着（wall cling）。

## Acceptance Criteria

- [ ] AC-1: 主角能左右移动（move_speed = 300 px/s，基于 delta_time 帧率无关）
- [ ] AC-2: 主角能单跳（jump_height = 200 px，重力 980 px/s²，基于 delta_time）
- [ ] AC-3: 主角接触墙壁时进入 wall_cling 状态（下滑速度 50 px/s）
- [ ] AC-4: 状态机包含 5 状态：IDLE / RUN / JUMP / FALL / WALL_CLING
- [ ] AC-5: InputMap actions：move_left / move_right / jump
- [ ] AC-6: godot --headless --check-only EXIT 0

## 测试红线

本 story 涉及玩家可见行为 → tester 必须含真实输入路径测试（action_press）。