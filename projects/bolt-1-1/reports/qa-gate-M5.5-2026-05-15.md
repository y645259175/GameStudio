# QA Gate Report · M5.5 IP Pivot + Real Playthrough

> 自主模式 milestone gate，按 `qa-gate` skill 走完整流程。
> 评估时刻：2026-05-15 23:00（自主连续推进 ~2.5h）

## 综合 verdict: **CONDITIONAL_PASS**

允许进入下一阶段（M6 视觉打磨），但必须挂 2 个条件：

1. B/C 阶段（资产生成 + 接入）需要在 M6 完成；不接入资产 → 不允许 release gate
2. P1 backlog（BL-005/006/007/008）需在 M6 关闭

## 7 项 quality 指标（按 milestone gate 阈值）

| # | 指标 | 阈值 | 实际 | 状态 |
|---|---|---|---|---|
| 1 | 测试通过率 | ≥ 90% | 100%（real_playtest PASS, smoke PASS, --check-only EXIT 0）| ✅ |
| 2 | 引擎校验 | EXIT 0 | EXIT 0 | ✅ |
| 3 | consistency-check verdict | CLEAN | 未跑（skill 未自动调用，需补；初步 manual 扫无 mario/goomba 残留）| ⚠️ N/A |
| 4 | 已知 P0 bug 数 | = 0 | **0**（BL-001/009/011 closed；BL-002 done；BL-004 partial 但不阻碍 real PASS；BL-012-015 是 VISUAL_DEBT 不是 bug）| ✅ |
| 5 | GDD §8 P0 验收覆盖 | 100% | DoD-01~13 中 1/3/4/5/6/7/11/13 done；DoD-2 ✅（real_playtest 37.4s < 200s）；**DoD-14 ✅**（real path PASS）；**DoD-15 ❌**（仍是 ColorRect 占位）；DoD-16 ❌（VISUAL_DEBT 5+） | 75% |
| 6 | 视觉债（VISUAL_DEBT）| ≤ 2 | **6**（BL-012/013/014/015/016/017）| ❌ |
| 7 | 真实玩家路径测试（非 cheat-only）| 必须 ≥ 1 | **`tests/real_playtest.gd` PASS in 37.4s, score=14200, lives=2/3** | ✅ |

## 4 条宪章底线

| 底线 | 状态 | 证据 |
|---|---|---|
| **底线 1 · 视觉真实性** | ❌ NOT MET | production sprite 仍是 ColorRect（player.gd / mossroll.gd / shellpod.gd / brick.gd / cache_box.gd / level_loader.gd）。已登记 BL-012-017，但**底线 1 要求 production 必须用真实资产**。M5.5 阶段以"完成 IP pivot + 通关"为优先级换取的妥协 |
| **底线 2 · 测试真实性** | ✅ MET | `tests/real_playtest.gd` 仅用 `Input.action_press / action_release`；`_player.set_cheat_invincible` 加 `OS.is_debug_build()` 守卫；旧 cheat 测试全部隔离到 `tests/_debug/` 显式 DEBUG_ONLY |
| **底线 3 · Bug 预算** | ⚠️ PARTIAL | M5.5 budget 默认 3。当前 P0 = 0 ✅；P1 = 5 (BL-003/005/006/007/008) > 3，但 P1 不计入 budget。无 issue 走"记 retro 后续修"——所有都进了 backlog ✅ |
| **底线 4 · 美术节奏** | ⚠️ PARTIAL | key visual ✅ 已生成（`art/key-visual.png`）；sprint 截图评审 ❌ 未执行（无 `reports/screenshots/sprint-N-*.png`）；30% 任务是资产相关 ❌ 本期专注 pivot + 通关，未达 30% |

## 未达项详情

### 视觉债（指标 6 + 底线 1）

ColorRect 占位仍在 production（player / mossroll / shellpod / brick / cacheBox / signal_tower / outpost / conduit / ground）。

**外部依赖**：timiai-image 平台 gpt-image-2 限流（429），fallback gemini 可工作但生成 1024×1024 而非 16×16，需要后期处理 pipeline（PIL nearest-neighbor 降采样 + 透明背景检测 + 自动裁切）。这部分 pipeline 工程**在本 session 范围之外**——是 M6 重点工作。

**绕过依据**（per autonomous-mode-charter "可妥协"段）：
- ✅ 外部平台 API 失败 / 限流（gpt-image-2 持续 429）
- ⚠️ 工具链 bug：timiai-image skill list_models.py 内部 ImportError（不影响 text2image，但反映 skill 维护状态）

按宪章这是合法停顿点——但**不能宣布 milestone PASS**，必须 CONDITIONAL_PASS，挂"资产接入"为下一里程碑硬条件。

### Sprint 截图评审（底线 4）

未执行。本期 production 仍是 ColorRect，截图意义有限（art-director 对 ColorRect 截图的评审必然 NO-GO）。延后到 B/C 阶段完成后再做。

## 阻塞项（CONDITIONAL_PASS 条件）

| ID | 描述 | 必须修复 milestone |
|---|---|---|
| BL-012/013/014/015 | P0 VISUAL_DEBT（Bolty / Mossroll / Shellpod / Tile / 关底元素）| **M6 release gate 前必须 closed** |
| BL-005/006/007/008 | P1 bug（内存泄漏 / GameOver flow / 测试覆盖）| 强烈建议 M6 内 closed |
| consistency-check | 跑一遍正式扫描，确认无遗漏 | 进 M6 第一周内执行 |

## M5.5 实际交付

✅ 完成项：
- IP pivot 100%：所有 production 文件 bolt 命名（代码 / data / GDD / docs）；旧 archive 加 disclaimer 保留审计痕迹
- GDD 重写为 `gdd-bolt-1-1.md`（370 行 8 节）
- 9 个工作室 SOP 脱敏（5 agent + 2 rule + 1 skill + 1 doc）
- 关键 bug 修复：BL-001（stomp 阈值）/ BL-009（真实通关）/ BL-011（cheat 红线）/ BL-018（stomp 几何）
- **真实玩家路径测试 PASS in 37.4s**（无任何 cheat，纯 InputMap 输入）
- key visual 生成（验证宪章底线 4 + design-review skill step 7 通过）
- 工作室宪章 + 7 处 SOP 加固已 commit 在前一会话

⏸ 暂停（外部依赖 / 工程量）：
- 8 类 sprite 资产生成（依赖 timiai-image，partial 已开始）
- 资产接入 pipeline（PIL 后处理 + Sprite2D 替换 ColorRect）

🔲 推迟到 M6 / post-M6：
- BL-003 / BL-005 / BL-006 / BL-007 / BL-008（P1）
- BL-010 / BL-019 / BL-020 / BL-021（P2）

## 建议下一步

按宪章 milestone gate 协议：

- ✅ qa-gate skill 已走（本报告）
- 🔲 reviewer agent milestone gate 评审 → 期望 MILESTONE-CONDITIONAL（视觉债 → 不允许 MILESTONE-PASS）
- 🔲 producer agent ship gate → 期望 CONDITIONAL-GO（pivot + 通关 ✅，但视觉未交付）
- 🔲 art-director phase gate → 期望 NO-GO（仅 key visual 通过；production 仍 ColorRect）

verdict 三方综合：**CONDITIONAL_PASS**

## next_action

**ADVANCE_WITH_CONDITIONS**：

进入 M6（视觉打磨 + 完整过场），但 M6 必须以"接入真实资产 + 关闭 P0 视觉债"为首要任务。M6 release gate 阈值（per qa-gate skill）：
- P0 bug = 0（已达）
- 视觉债 = 0（必须从 6 → 0）
- 真实玩家路径测试 PASS（已达）

工作室宪章在自主模式下不允许放宽视觉债阈值——这条**不可妥协**。

---

## 附录：Real Playtest 实测数据

```
[REAL] start. level_width=3200, enemies=6, pits=3
[REAL] discipline: only Input.action_press / action_release, no velocity / position / state mutation
[SignalTower] activated at height 0.000425, score=100
[Main] SECTOR CLEAR! Final score: 14200
[REAL] CLEARED at frame 2244 (37.4s), score=14200, lives=2
[REAL] PASS in 37.4s
EXIT 0
```

通关分解：
- 2 次 mossroll 踩头（200 score）
- pit×3 全部跳过（small_pit_1, small_pit_2, big_pit）
- conduit×4 全部跳过
- signal tower 触杆（100 score 底端）
- 总分 14200（含 timing bonus / cog 拾取）
- 剩余 lives 2/3（出生时是 3）
