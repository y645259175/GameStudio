# qa-lead · ARCHIVE

> 历史判例。仅 RCA / postmortem / 质量门决策溯源时查。

## 判例索引

| 日期 | 项目 | 触发场景 | 锚点 |
|---|---|---|---|
| 2026-05-15 | bolt-1-1 / 项目 A | M5/M6 cheat-only 测试 PASS 通过 | §A1 |
| 2026-05-19 | platformer-2 | shadow review 在 story-002 中超时 + story-003 同 batch 失独立性 | §A2 |
| 2026-05-19 | platformer-2 | qa-gate 给 GATE_PASSED 但用户实玩崩 → 引入 _MECHANISM 后缀 | §A3 |

---

## §A1 · cheat-only 测试通过 milestone（2026-05-15）

**触发**：bolt-1-1 / 项目 A pivot 期间，测试套件 PASS 但用户实玩全是占位/无功能。

**经过**：
1. tester 写测试时直接 `set player.velocity = Vector2(100, 0)` 而非通过 `Input.action_press("move_right")`
2. 测试 PASS 但代码可能根本没绑定 InputMap
3. qa-gate 仅看"测试通过率 ≥ 95%" 这一项给 GATE_PASSED
4. 用户实玩按键无反应

**根因**：qa-gate 缺少"真实玩家路径测试"独立维度，cheat 测试 PASS 不等于真按键有效。

**修法（已落地）**：
- qa-gate 7 项指标第 7 项：真实玩家路径测试（InputMap action_press 必须 ≥ 1 条 PASS）
- test-standards rule § 红线：玩家可见行为必须有 ≥ 1 条 action_press 测试
- tester CORE 红线：禁止 cheat-only 测试

---

## §A2 · shadow review 异常（2026-05-19）

**触发**：platformer-2 story-002 / story-003 测试 shadow review 流程时出问题。

**story-002**：
- shadow `qa-lead` agent 超时（max_turns 不限被卡死）
- 主 reviewer 发现截断 → REQUEST_CHANGES（机制有效）
- 但 shadow 没产出 verdict → 失去对照价值

**story-003**：
- main agent 用 batch task spawn reviewer + qa-lead shadow（错误用法）
- 同 batch 共享上下文 → shadow 看到主 reviewer 的部分输出
- shadow 给的"独立 verdict"实际受了主 reviewer 影响 → 失独立性

**根因**：
- shadow agent 缺 max_turns 限制 → 长任务超时
- 同 batch task 与 team 模式区分不清 → shadow 必须 team 模式才能真正隔离

**修法（已落地）**：
- agent-spawn-contract MANUAL § shadow spawn 参数建议：max_turns 10/20/30
- BL-S030 shadow 必须 team mode（→ `tool-usage-no-popup/MANUAL.md` § shadow-team-mode）
- dev-story --shadow 输出提示改为推荐 team 模式

---

## §A3 · QUALITY_PROVEN 自宣事故（2026-05-19）

**触发**：platformer-2 vertical slice qa-gate 给 GATE_PASSED，但用户首次实玩 < 1 分钟发现 3 个 P0。

**根因**：qa-gate 7 项 metrics 全 PASS 不等于产品体验 OK——机制层证据 ≠ 用户实玩证据。

**修法（已落地）**：
- AP-10 修法：AI 给的 verdict 必须带 `_MECHANISM` 后缀
  - `GATE_PASSED_MECHANISM` / `CONDITIONAL_PASS_MECHANISM` / `ADVANCE_MECHANISM`
- 禁止自宣 `QUALITY_PROVEN` / `READY_FOR_RELEASE`（必须用户实玩反馈触发）
- qa-gate run.py + milestone-review run.py verdict 词汇全更新
- qa-lead CORE 红线 [4]：禁止自宣 QUALITY_PROVEN

**教训**：qa-lead 是机制层质量门，不能替代用户实玩。

---

## 决议词汇演化

- v1.0：`QA-PASS` / `QA-CONDITIONAL` / `QA-BLOCK`
- v1.1（2026-05-19 AP-10 修法）：所有 verdict 加 `_MECHANISM` 后缀；新增 `GATE_PASSED_MECHANISM` / `CONDITIONAL_PASS_MECHANISM` / `GATE_FAILED`

---

## 修订历史

- 2026-05-20 v1.0 初始版本（D-M6 BL-S042 建立 ARCHIVE，从 platformer-2 实战 + bolt-1-1 retro 沉淀）
