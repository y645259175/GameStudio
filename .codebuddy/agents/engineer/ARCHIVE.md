# engineer · ARCHIVE

> 历史判例。仅 RCA / postmortem / 实现决策溯源时查。

## 判例索引

| 日期 | 项目 | 触发场景 | 锚点 |
|---|---|---|---|
| 2026-05-15 | 项目 A | 全场 ColorRect 占位 + 14 issue 全绕过 | §A1 |
| 2026-05-18 | platformer-2 | write_to_file 静默截断（220→19 行）| §A2 |
| 2026-05-18 | platformer-2 | headless EXIT 0 ≠ 实现完整 | §A3 |
| 2026-05-19 | 自身（main agent）| .gitignore 偏见误判 .timiai_key 不存在 | §A4 |
| 2026-05-19 | 自身（main agent）| skill 没 run.py 就自己干（替代 spawn agent）| §A5 |
| 2026-05-19 | 自身（main agent）| 文档 ≠ 启用（hook 没挂载到 IDE）| §A6 |

---

## §A1 · 项目 A pivot 事故（2026-05-15）

**触发**：项目 A 自主运行时 engineer 默认全场 ColorRect 占位 + 14 个 issue 全部用"记 retro"绕过未修。

**经过**：
1. story 涉及视觉表现，但 engineer 没扫 assets/ 也没发起 art-asset-pipeline
2. 直接用 ColorRect 当占位
3. 遇到 14 个 bug，每个都"记 retro"绕过（把"绕过 + 记录"当作"完成"）
4. 用户实玩看到的是"调试图"

**根因**：
- engineer 没有"视觉资产红线"——AC 里没说不做就不做
- "绕过决策" 缺乏 SOP——绕过等于完成

**修法（已落地）**：
- engineer CORE 红线 [2]：ColorRect 必须标 `_PLACEHOLDER_` + 注释 TODO[VISUAL_DEBT BL-XXX]
- engineer HANDBOOK § 视觉资产红线
- engineer HANDBOOK § 绕过决策 SOP：现象级绕过必须升级 debugger / 开 backlog
- dev-story 流程 §3 视觉资产前置检查

---

## §A2 · write_to_file 静默截断事故（2026-05-18）

**触发**：platformer-2 story-002 engineer 写 ~220 行 player.gd，实际落盘 19 行。

**经过**：
1. engineer 用 write_to_file 写 player.gd（FSM 5 状态实现）
2. 工具返回成功
3. engineer 声称 "self_rubric: 6/6 PASS" + "IMPL-COMPLETE"
4. reviewer 发现 player.gd 只有 19 行 → REQUEST_CHANGES

**根因**：pre-tool-bash.py hook bug（line 90/92-100 错误代码导致非 Bash 工具回传 modifiedInput → IDE 处理时截断）。

**修法（已落地）**：
- 2026-05-19 修复 hook 根因（BL-S023 done）
- 防御性保留 AP-09：engineer 写完后 read_file 验证行数 < 80% 视为截断
- output-schema.yaml self_rubric 加 `[防截断]` 第 7 项

**教训**：交付前必须 read_file 验证落盘完整性，不能只信任 write_to_file 返回值。

---

## §A3 · headless EXIT 0 ≠ 实现完整（2026-05-18）

**触发**：截断后的 19 行 player.gd 只有 export 声明没有函数体，但 godot --headless --check-only EXIT 0。

**根因**：engine_check 只验证语法合法，不验证 AC 覆盖。"语法正确" ≠ "功能完整"。

**修法（已落地）**：
- engineer HANDBOOK § 历史教训：engine_check EXIT 0 不证明实现完整，必须对照 AC 逐条验证
- output-schema.yaml self_rubric `[2]` AC 覆盖独立检查项

---

## §A4 · .gitignore 偏见事故（2026-05-19）

**触发**：platformer-2 资产生成 main agent 直接用 `image_gen` 工具而非走 timiai-image skill。

**经过**：
1. main agent 想生成资产
2. 看到 .gitignore 排除了 `.timiai_key` 文件
3. **错误推理**："git 不追踪 → 仓库没有 → 我没 key"
4. 跳过 `timiai-image` skill 直接用 `image_gen`
5. 结果资产质量糟糕（1024×1024 → 32×32 Lanczos 降采样后糊到不识别）

**真相**：用户其实有 `.timiai_key`（40 字节真实存在），只是 `.gitignore` 排除而已。

**根因**：判断文件是否存在用错了方式——`.gitignore` 排除 ≠ 文件不存在。

**修法（已落地）**：
- 创建 `_check_key.py` 自检脚本
- timiai-image SKILL.md 加"零、首次必跑 _check_key.py"段
- engineer HANDBOOK § 历史教训："判断文件是否存在只能用 `read_file` / `Test-Path` 实测"

---

## §A5 · skill 没 run.py 就自己干（2026-05-19）

**触发**：同上资产事故的连带根因。

**经过**：
1. art-asset-pipeline 是 markdown skill，没有 run.py 一键入口
2. main agent 决策："没 run.py = 这 skill 不能用 = 我自己用 image_gen 替代"
3. 跳过 spawn `art-director` agent 走完整评审流程
4. 直接用 image_gen → AP-10 翻车

**根因**：把"skill 是否有 run.py"当作"是否该用 skill"的判断标准——错误。skill 没 run.py 也可以通过 spawn 对应 agent 走 SOP。

**修法（已落地）**：
- engineer HANDBOOK § 历史教训："SOP 没 run.py 入口 ≠ 不该用 SOP，应 spawn 对应 agent"
- art-asset-pipeline SKILL.md 明示"无独立 run.py，本 skill 是协调者，按场景调用 timiai-image / art-director"

---

## §A6 · 文档 ≠ 启用（2026-05-19）

**触发**：session-start.sh 写得很完整（86 行 anti-patterns 注入），但**从未触发过**。

**经过**：
1. session-start.sh 是 bash 脚本（Windows 上 bash 不可靠）
2. settings.json 里**没有挂载** SessionStart hook 到 IDE 事件链
3. 整个"启动注入 anti-patterns"设计 = 空中楼阁

**根因**：把"写好 hook 文件"当作"hook 完成"，没确认挂到 IDE 触发链路。

**修法（已落地）**：
- 改写为 session-start.py（Windows 友好）+ 加 `sys.stdout.reconfigure(encoding="utf-8")` 防中文乱码
- settings.json 添加 SessionStart 事件配置 + matcher
- 验证：通过 stdin 模拟测试 hook 输出 + 启动新 session 验证 additionalContext 注入
- engineer HANDBOOK § 历史教训："文档 ≠ 启用，必须挂到 IDE 触发链路才算完成"

---

## 决议词汇演化

- v1.0（2026-05-19 combo-B 改造）：新增 `IMPL-COMPLETE` / `IMPL-PARTIAL` / `IMPL-BLOCKED`

---

## 修订历史

- 2026-05-20 v1.0 初始版本（从 HANDBOOK §历史教训分离落 ARCHIVE）
