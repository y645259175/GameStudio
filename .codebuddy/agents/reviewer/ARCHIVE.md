# reviewer · ARCHIVE

> 历史判例。仅 RCA / postmortem / review 决策溯源时查。

## 判例索引

| 日期 | 项目 | 触发场景 | 锚点 |
|---|---|---|---|
| 2026-05-15 | 项目 A | reviewer 未在 milestone gate 介入，14 issue + cheat-only 通过 M5/M6 | §A1 |
| 2026-05-19 | platformer-2 | 4 维 PASS 但 vertical slice 实玩崩 3 项 | §A2 |
| 2026-05-19 | platformer-2 | 数值不一致 标 critical 但无人裁定 | §A3 |

---

## §A1 · 项目 A pivot 事故（2026-05-15）

**触发**：项目 A 在 M5/M6 通过了"全 ColorRect + 14 issue + cheat-only PASS"的版本。

**经过**：
1. reviewer 未在 milestone gate 主动介入（按当时流程 reviewer 只在 commit 前评审单个 diff）
2. 多个 issue 用"记 retro 绕过"代替修复
3. 测试只覆盖 cheat-only 路径（直接改 velocity / state）
4. 14 个 issue 累积通过 M5/M6 → 用户实玩发现项目根本不能玩

**根因**：reviewer 角色边界过窄（只管 diff，不管 milestone）+ 绕过决策无 SOP。

**修法（已落地）**：
- reviewer Domain Owned 加"milestone gate 代码质量维度（与 qa-gate 联动）"
- HANDBOOK 加"milestone gate 专项扫"流程
- BL-S025 流程逃逸禁令（→ `tool-usage-no-popup/MANUAL.md` § flow-discipline）

---

## §A2 · platformer-2 vertical slice 实玩崩（2026-05-19）

**触发**：reviewer 给了 APPROVE_WITH_NITS 但用户实玩 < 1 分钟发现 3 个 P0：无 camera / 无边界 / 资产不渲染。

**经过**：
1. reviewer 走完 4 维评审（correctness / risk / style / test_quality）每维 PASS
2. self_rubric 7/7 PASS
3. 用户实玩立即发现"画面糟糕到不知道在玩什么 / 镜头不动 / 走出屏幕没反应"

**根因**：
- 4 维代码评审是"代码契约"维度，不覆盖"产品体验"维度
- reviewer 与 engineer / shadow 都是同代 LLM，共享盲区
- 没有"vertical slice 体验维度"的独立评审

**修法（已落地）**：
- AP-10 修法：新增 TPL-09 vertical slice 5 项清单评审（camera / 边界 / 视觉 / 死亡 / 完成）
- 5 项评审与 4 维代码评审是**独立维度**，不能用代码 PASS 推断 vertical slice OK
- reviewer CORE 红线 [4]：vertical slice review 必须独立跑 TPL-09
- AI verdict 加 `_MECHANISM` 后缀，`QUALITY_PROVEN` 仅用户实玩反馈触发（AP-10 修法）

**教训**：4 维代码评审 PASS ≠ vertical slice 可玩。代码可信不等于产品可玩。

---

## §A3 · platformer-2 数值不一致 reviewer 失职（2026-05-19）

**触发**：reviewer 在 story-002 review 时发现 GDD §3 写 180 而 story AC 写 300，标了 critical_issue 就交差。

**根因**：reviewer 发现冲突后只标 issue 没主动触发裁定流程——把"标出问题"当成"完成职责"。

**修法（已落地）**：
- reviewer CORE 红线 [5]：发现跨文件数值不一致 → 必须主动建议三方共识（BL-S026），不能只标 issue
- BL-S026 数值一致性回路 SOP

**教训**：reviewer 不是"找茬员"，发现冲突后要驱动解决（spawn 或建议 main agent 走三方共识）。

---

## 决议词汇演化

- v1.0：`REVIEW-PASS` / `REVIEW-CHANGES` / `REVIEW-COMMENT`
- v2.0（2026-05-19 AP-10 修法）：新增 `AP10-PASS` / `AP10-PARTIAL` / `AP10-FAIL`（TPL-09 vertical slice 评审专用）

---

## 修订历史

- 2026-05-20 v1.0 初始版本（从 HANDBOOK §历史教训分离落 ARCHIVE）
