# designer · ARCHIVE

> 历史判例。仅 RCA / postmortem / 设计决策溯源时查。

## 判例索引

| 日期 | 项目 | 触发场景 | 锚点 |
|---|---|---|---|
| 2026-05-19 | platformer-2 | move_speed 数值不一致（GDD 180 vs story AC 300）| §A1 |
| 2026-05-19 | platformer-2 | 实玩崩 3 项波及设计层（无 camera/边界/反馈在 GDD 中未明示）| §A2 |

---

## §A1 · platformer-2 数值不一致事故（2026-05-19）

**触发**：reviewer 在 story-002 review 时发现 GDD §3 写 `move_speed = 180 px/s` 但 story-002 AC-1 写 `300 px/s`。

**经过**：
1. designer 在 GDD §3 数值规范段写 `move_speed = 180 px/s`
2. PM 拆 story-002 时 AC 写 `300 px/s`（手感更快）
3. engineer 实现时按 story 取了 300
4. reviewer 标 critical_issue 但**无人裁定**——designer / engineer / reviewer 三方都没主动发起共识
5. 最终代码用了 300，但 GDD 没改 → 下个 sprint 起新 story 还会撞墙

**根因**：跨 agent 数值一致性回路缺失，没有"发现冲突 → 走三方共识"的 SOP 强制路径。

**修法（已落地）**：
- BL-S026 数值一致性回路 SOP（→ `tool-usage-no-popup/MANUAL.md` § value-consistency）
- designer CORE 红线 + reviewer CORE 红线 都加"发现跨文件数值不一致 → 必须主动建议三方共识"
- consistency-check skill 加自动检查（待实施）

**教训**：designer 必须主动校准 story AC 与 GDD 数值，发现冲突立即走数值一致性回路。

---

## §A2 · platformer-2 实玩崩波及设计层（2026-05-19）

**触发**：vertical slice 实玩反馈 3 项 P0：无 camera / 无边界 / 资产糊。

**设计层失职部分**：
- "无 camera / 无边界" 本应在 GDD §4 UX 反馈 / §5 边界处理中提前明示
- engineer 实现时未读 GDD §4/§5/§6 → 按"AC 列表"实现，AC 没说就没做
- designer 写 GDD 时把"camera / boundary / feedback"当作"显然要做"，没有显式条目让 engineer/reviewer 能 grep 到

**根因**：GDD ↔ 实现脱钩——GDD 假设了"显然"的内容，但 engineer/reviewer 只按 grep 关键词工作。

**修法（已落地）**：
- BL-S034 GDD ↔ 实现一致性 grep（待 consistency-check skill 改造，open）
- designer CORE 红线 [3]：§7 接口引用必须具体到段落标题，不能笼统
- 教训：每章 GDD 必须含可被 engineer/reviewer **直接 grep 的关键词**（camera / boundary / kill_zone / death_feedback / win_feedback）

---

## 决议词汇演化

- v1.0（2026-05-19 combo-B 改造）：新增 `DESIGN-COMPLETE` / `DESIGN-DRAFT` / `DESIGN-BLOCKED`

---

## 修订历史

- 2026-05-20 v1.0 初始版本（从 HANDBOOK §历史教训分离落 ARCHIVE）
