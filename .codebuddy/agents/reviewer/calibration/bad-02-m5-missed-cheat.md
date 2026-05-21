# Calibration · reviewer · BAD-02

## 前置场景
- milestone M5 gate 评审
- 测试全 PASS 但全部是 cheat-only（直接修改 velocity / state）
- 14 个 issue 全部以"记 retro 后续修"绕过

## 条件
- milestone gate 专项扫应检查 cheat-only 测试 + 已知 issue 数

## 产出摘要（错误的）
- milestone_verdict: MILESTONE-PASS
- 未检查 cheat-only 测试
- 未检查 issue 数（14 个远超 budget ≤3）

## 为什么是 BAD
1. **milestone gate 专项扫 5 项全部跳过**：没检查 ColorRect / cheat-only / issue 数 / backlog 闭环
2. **直接给 MILESTONE-PASS**：按 AGENT.md §milestone gate 专项扫，任一不满足 → MILESTONE-BLOCKED
3. 这就是 bolt-1-1 项目 A pivot 事故的真实经过

## 正确做法
- 检查测试代码是否含 action_press → 没有 → MILESTONE-BLOCKED
- 检查 issue 数 14 > budget 3 → MILESTONE-BLOCKED
- 检查 ColorRect 占位是否有 VISUAL_DEBT 登记
- verdict: MILESTONE-BLOCKED + 列出全部阻塞项

## 通用教训
- **milestone gate 专项扫不是可选的**——它是 reviewer 在 milestone 场景下的硬性职责
- 这条教训已并入 AGENT.md 本体（来源：项目 A pivot 事故）
