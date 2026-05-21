# art-director · ARCHIVE

> 历史判例与详细推导。仅 RCA / postmortem / 视觉决策溯源时查。
> 不参与自动注入或 lint 行数检查。

## 判例索引

| 日期 | 项目 | 触发场景 | 锚点 / 引用 |
|---|---|---|---|
| 2026-05-16 | bolt-1-1 | 4 帧动画输出 4 个不同角色（reference-based 流程缺失）| §A1 + AP-03 |
| 2026-05-19 | platformer-2 | art-director 仅看 raw 资产 PASS，但游戏内 SignalNetwork transform 链断裂导致管道全部不渲染 | §A2 + AP-10 + AP-11 |

---

## §A1 · bolt-1-1 4 帧动画一致性事故（2026-05-16）

**触发**：M6.2 阶段需要 4 帧角色动画。流程没有走 reference-based，4 个独立 text2image prompt 并行出图。

**经过**：
1. art-asset-pipeline 直接 4 次调 text2image，每次 prompt 写 "same character with different pose"
2. 4 张图返回时 art-director 仅看 raw 资产，每张单独看都"挺像那么回事"
3. 拼成动画后用户实玩立即识破——"这是 4 个不同的人"
4. 复盘：LLM 跨调用没有记忆，"same character" 文字提示零效果

**根因**：
- 跨 LLM 调用一致性靠 prompt 写"same X" → AP-03
- art-director 评审时未把 4 帧并排对比（缺多帧一致性 5 项检查）

**修法（已落地）**：
- HANDBOOK §7 角色多帧动画评审：禁止并行 text2image 出多帧，必须先评审 1 张 canonical key sprite + AD-CHAR-KEY APPROVE 才派生
- 新增决议词汇：`AD-CHAR-KEY` / `AD-CHAR-ANIM-SET`
- 派生帧必须用 image_edit 模式 + reference 链

**关联文档**：
- 完整 retro：`projects/bolt-1-1/retros/2026-05-16-m6.2-art-asset-pipeline.md`
- AP-03：`studio/docs/anti-patterns.md` § AP-03

---

## §A2 · platformer-2 SignalNetwork transform 链断裂事故（2026-05-19）

**触发**：vertical slice 实玩反馈"管道完全看不到"。最初 main agent 认为是渲染 bug 不知所措。

**经过**：
1. main agent 自己看 raw 资产 PNG（pipe_straight.png）觉得"还行"
2. 集成到 level_01.tscn 后用户实玩反馈管道不见
3. spawn art-director 走 TPL-05 v2 in-context 评审
4. art-director 看 capture_00/01/02_x*.png 截图发现 PuzzleArea (700, 480) 位置只有空白
5. 诊断到 SignalNetwork 节点 `type="Node"` 而非 `Node2D` → transform 链断裂 → PipeA/B/C 全部渲染在世界坐标 (0,0)
6. 同时发现 pipe_node.gd 的 `rotation_steps` 是普通 var 没标 `@export`，scene tscn 设的 2 在运行时被默认 0 覆盖

**根因**：
- 仅看 raw 资产判 APPROVE 是 AP-10 自嗨循环的典型表现
- Godot 渲染层陷阱：transform 链断裂 / @export 缺失 / z_index 遮挡 → AP-11

**修法（已落地）**：
- TPL-05 v2 强制要求 in-context 截图作为评审输入；没截图则 REJECT 任务
- screenshot 工具抽到 `studio/templates/godot-screenshot/`
- art-director CORE 红线 [1]：资产入库前必走 in-context 渲染评审
- art-director HANDBOOK §3 5 维评审第 3 维"背景透明 / 渲染层"显式包含"transform 链断裂 / z_index 错误"诊断

**关联文档**：
- AP-10：`anti-patterns.md` § AP-10 + `anti-patterns-archive.md` §A4
- AP-11：`anti-patterns.md` § AP-11 + `anti-patterns-archive.md` §A5
- 评审报告：`projects/platformer-2/reports/art-review-2026-05-19-vertical-slice.md`

---

## 决议词汇演化

- v1.0：`AD-CONCEPT-VISUAL` / `AD-ART-BIBLE` / `AD-PHASE-GATE`
- v1.1（2026-05-16 bolt-1-1 事故后）：新增 `AD-CHAR-KEY` / `AD-CHAR-ANIM-SET`（多帧动画专用）
- v2.0（2026-05-19 platformer-2 事故后）：新增 `AD-APPROVE` / `AD-MINOR-ISSUES` / `AD-REJECT`（TPL-05 v2 in-context 评审专用）

---

## 弃用记录

- 2026-05-16 ~~"art-director 仅审 raw 资产"~~ → 替换为"必须看 in-context 截图"。原方案漏掉所有渲染层 bug
- 2026-05-19 ~~"5 维评审"~~ → 升级为 6 维（含元数据完整 .import 检查），AP-04 修法

---

## 修订历史

- 2026-05-20 v1.0 初始版本（D-M6 BL-S042 建立 ARCHIVE 骨架）
