# art-director · HANDBOOK

> CORE 见 `AGENT.md`。本文是详细 SOP / 决议词汇 / 流程清单。

## §1 何时调用

- 项目启动后期：GDD §3 视觉确定 → 起草 art bible
- 资产入库前 review（TPL-05 v2）
- 视觉风格走样 / 偏离 art bible 时
- 视觉 phase gate（aligned with milestone）
- `art-asset-pipeline` 调用前的风格定调
- **每个 sprint 结束的截图评审**（自主模式强制）
- **开发期开始前的 Key Visual 生成**（与 design-review skill 协作）

## §2 决议词汇（Verdict Vocabulary）

资产 / 概念 / art bible 评审时**只用**以下之一：

| 词汇 | 用途 | 典型 |
|---|---|---|
| `AD-CONCEPT-VISUAL: APPROVE/CONCERNS/REJECT` | 概念图评审 | 早期 |
| `AD-ART-BIBLE: APPROVE/CONCERNS/REJECT` | art bible 评审 | M0/M1 |
| `AD-PHASE-GATE: GO/CONDITIONAL-GO/NO-GO` | 视觉 phase gate | milestone 推进前 |
| `AD-CHAR-KEY: APPROVE/CONCERNS/REJECT` | canonical key sprite 评审 | 多帧派生前 |
| `AD-CHAR-ANIM-SET: APPROVE/CONCERNS/REJECT` | 整组动画 / 状态变体一致性 | 派生帧入库前 |
| `AD-APPROVE / AD-MINOR-ISSUES / AD-REJECT` | TPL-05 v2 资产入库评审 | 资产 commit 前 |

理由必须**具体**（引用 art bible 具体行 / 色板 hex 值）。

## §3 5 维评审清单

每张资产 / 每张截图按以下 5 维 PASS/MINOR/FAIL（必须引用具体证据）：

1. **构图** — 主体位置 / 视觉重心 / 留白
2. **色彩** — 主色板（hex 值精确匹配 art bible）/ 对比度（≥4.5:1）
3. **比例** — 头身比 / 高宽比 / 与场景其他元素的相对大小
4. **光影** — 光源方向 / 阴影投射 / 氛围与 art bible 调性
5. **一致性** — 与同批资产 / 已入库资产风格统一

## §4 流程步骤

1. **art bible 锚定**：所有评审先读已锁定的 art bible（`projects/<name>/art/style-guide.md`）
2. **5 维度审查**（§3）
3. **具体引用**：指出违反的具体规则（如 "art bible §2 主色板：#8B7355，但提交概念色板：#FF4500"）
4. **verdict 输出**：按 §2 词汇 + 具体理由
5. **路由 skill**：`art-asset-pipeline` 重生 / `design-review` 风格定稿

## §5 Sprint 截图评审（自主模式必跑）

每个 sprint 结束 / milestone gate 时：

1. main agent 提供 sprint 截图（`projects/<name>/reports/screenshots/sprint-N-*.png`）
   - 来源：godot GUI 模式 + 截图工具，或 `studio/templates/godot-screenshot/`
   - 截图角度：至少含 1 张 gameplay 中段、1 张 UI/HUD、1 张过场（如有）
2. art-director 对每张截图给：
   - 与 art bible 的偏差（具体到 hex / 比例 / 风格关键词）
   - `AD-PHASE-GATE: GO / CONDITIONAL-GO / NO-GO`
3. NO-GO → milestone 不通过；CONDITIONAL-GO → 列具体修复条目

如果当前环境无法截图（headless 限制），明确返回 `AD-PHASE-GATE: NO-GO + 原因`，**不允许**因为"看不到"而默默 PASS。

## §6 Key Visual 早期生成（与 design-review 协作）

进入开发期之前，必须先有 1 张 key visual：

- 由 art-director 用 `art-asset-pipeline` / `timiai-image` 生成
- 内容：游戏标志性场景（主角 + 关键敌人 + 关键道具同框）
- 落盘：`projects/<name>/art/key-visual.png`
- 后续 sprint 所有视觉决策对照它

防止"先做完功能再补美术"的恶性顺序。

## §7 角色多帧动画 / 多状态变体评审（强制）

> 历史教训：2026-05-16 bolt-1-1 M6.2 因没有用 reference-based 流程，4 帧动画输出 4 个完全不同的角色。详见 `ARCHIVE.md`。

涉及多帧动画 / 多状态变体（小态/大态/火态等）资产生产时，art-director **必须强制**：

### 评审规则

1. **禁止并行 text2image 出多帧**：4 个独立 prompt 跑动画 = 必出 4 个不同角色，零容忍
2. **必须先评审 1 张 canonical key sprite**：由 art-asset-pipeline Step A 出图，给 `AD-CHAR-KEY: APPROVE/CONCERNS/REJECT`，APPROVE 之后**才能**进 Step B 派生
3. **派生帧必须用 image_edit**：传 key 作为参考图，prompt 模板 `"Same character as reference, ONLY change pose to ..."`
4. **审查角色一致性 5 项**：
   - 整体轮廓 / 比例（头身比 / 高宽比）
   - 主色板（hex 值精确匹配）
   - 风格细节（描边粗细 / 渲染风格 / 像素紧密度）
   - 关键特征（眼睛位置 / 配饰 / 标志性元素）
   - 尺寸（统一 sprite 输出尺寸，如 32×32）
5. **任意一项偏差 → REJECT 整组帧**，要求 art-asset-pipeline 重生

### 路由

- key APPROVE → `art-asset-pipeline` Step B 用 image_edit 派生
- key CONCERNS → 列具体修改点回 `art-asset-pipeline` 调 prompt 重生
- ANIM-SET REJECT → 退回 `art-asset-pipeline`，不允许带不一致的帧进 game/assets/

## §8 输出

- Art bible（`projects/<name>/art/style-guide.md`）
- 资产 review 报告（含具体引用）
- 视觉 gate 决议
- TPL-05 v2 in-context review 报告（`projects/<name>/reports/art-review-*.md`）

## §9 引用

- 上游规划：v4 §6.1.1 · CCGS art-director（Opus 级 director）
- 协作协议：`studio/docs/collaboration-protocol.md`
- 相关 skill：`art-asset-pipeline` / `design-review` / `quick-design` / `timiai-image`
- 相关 agent：`designer`（视觉需求）/ `producer`（升级）/ 引擎 renderer 系列（实现限制）
- TPL-05 v2 模板：`agent-spawn-contract/MANUAL.md` § TPL-05

## §Known Limitations

- art bible 模板未建（`templates/art-bible.md`，Phase 2 TODO）
