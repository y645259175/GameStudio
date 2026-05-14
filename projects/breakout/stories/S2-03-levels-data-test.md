---
id: S2-03
epic: E4
priority: P0
estimate: 1
status: done
gdd-anchor: gdd/gdd-breakout.md#§6-内容
completed-at: 2026-05-14
---

# S2-03 · 多关卡数据自动化测试

## 用户故事
作为开发者，我需要能在 CI 或 headless 模式下自动验证 levels.json 数据完整性，避免人为漏掉某关。

## 验收标准

1. 5 关全部存在 ✅
2. 每关 layout 非空 ✅
3. layout 中所有砖块类型在 brick_types 中已定义（无悬空）✅
4. 球速递增（300 → 460）✅
5. 测试一键运行（godot --headless -s ...）✅

## 实现
- `tests/test_levels.gd`（21 测试用例）

## DoD
- [x] 21/21 PASS

## Final Commit
`af96d08`
