# 工作室通用反模式 · MANUAL

> **本文是 MANUAL 层**——agent 中招时按需 read_file。每次会话注入的精简版见 `anti-patterns-digest.md`（CORE）；历史触发事件见 `anti-patterns-archive.md`。
>
> 渐进披露设计见 `progressive-disclosure-architecture.md`。

## 反模式索引

| ID | 标题 | 关联 rule / skill | 关联 BL |
|---|---|---|---|
| AP-01 | agent 自己干一切 | `agent-spawn-contract` | BL-S001/S002/S008/S017 |
| AP-02 | spawn cost > do it yourself 心理 | `agent-spawn-contract` 模板库 | BL-S002/S017 |
| AP-03 | 跨 LLM 调用一致性靠 prompt 写"same X" | `art-asset-pipeline` / `art-director` | BL-S006 |
| AP-04 | 资源缺失静默 fallback | `qa-gate` 真路径测试门 | BL-S004 |
| AP-05 | API 限流时硬撞 | `timiai-image` daemon | BL-S006/S016 |
| AP-06 | 用户反馈循环没有自动学习 | `retrospective` skill | BL-S014 |
| AP-07 | settings.json 权限失效迷惑 | `tool-usage-no-popup` rule | BL-S012/S013 |
| AP-08 | 复合命令 cmd1;cmd2 触发整串审批 | session-start 注入 | BL-S013 |
| AP-09 | sub-agent 声称 PASS 但文件截断 | `agent-spawn-contract` §防截断 | BL-S023/S024 |
| AP-10 | AI 自嗨循环：机制全 PASS 但产品不能玩 | `dev-story` playtest_pending + TPL-09 | BL-S031/S033/S035 |
| AP-11 | Godot 渲染层陷阱（transform / @export / z_index）| `art-director` TPL-05 v2 | BL-S038/S039 |

> 历史触发事件、来源 retro、详细演化过程 → 见 `anti-patterns-archive.md`

---

## AP-01 · agent 自己干一切

**症状**：main agent 不 spawn 任何 sub-agent，从设计到 review 全程自己做。31 agent 与 25 skill 利用率接近 0。

**检测信号**：
- 主上下文 token 接近 100k 但本次 session 调过 `task` < 2 次
- 用户反馈"这个不对"→ main agent 立即自己改而不 spawn `debugger` / `reviewer`
- 一个 milestone 完整走完（plan → dev → playtest → gate）未触发任何 sub-agent
- `git log` 大改动 commit 前没有 `[reviewer-pass]` / `[qa-gate-pass]` 标记

**修法**：
1. 复制 `agent-spawn-contract` rule 末尾"高频 spawn 模板库"对应模板（修 story → engineer / milestone → qa-lead+producer+reviewer / GDD → designer / bug → debugger / 资产 → art-director）
2. session-start hook 显示"上次 session 用了哪些 agent / skill"
3. PreToolUse hook 检测大改动 commit 前若没调过 reviewer → 强制弹窗或加 `[unreviewed]` tag

---

## AP-02 · "spawn cost > do it yourself" 心理

**症状**：AP-01 的心理根因。main agent 觉得"描述任务给 sub-agent + 等返回 + 再 review"比自己写慢。

**检测信号**：
- main agent 出现内心独白："我自己写更快"/"spawn 一遍还要把上下文重讲"/"改动小不值得 spawn"
- sprint 内 spawn 次数 < commit 数 / 5
- `task` prompt > 1000 字符（说明在重复粘贴上下文）

**修法**：
1. spawn 包装成单行命令（写入 spawn 模板库），prompt 工作量为零
2. spawn 默认 `mode: bypassPermissions`
3. sub-agent 启动自动读 `PROJECT.md` + 当前 milestone backlog（BL-S017）
4. spawn prompt 第一句固定"已读 BL-XXX + GDD §N"，降低输入成本

---

## AP-03 · 跨 LLM 调用一致性靠 prompt 写"same X"

**症状**：跨多次 API 调用要求一致（角色 / 风格 / 配色）只在 prompt 里写"same character"——LLM 跨调用无记忆，零效果。

**检测信号**：
- 资产"看起来差不多但不一致"（4 帧动画 4 个角色）
- 用户反馈"这个 X 和那个 X 不像同一个"
- pipeline 里只有 text2image，没有 image_edit / chat_image
- prompt 里出现"same"/"consistent"/"matching previous"且未传参考图

**修法**：
1. **必须 reference-based**：用 `image_edit.py`（多参考图）或 `chat_image.py`（多轮迭代），前一次产物作为输入图
2. **key sprite 必须人审通过**才进入派生流程，禁止 key sprite 未确认就批量产出
3. 调用 `art-asset-pipeline` skill，pipeline 内置 reference 链
4. 命名规范：`{character}_key.png` 是基准帧，派生必须 `image_edit --ref {character}_key.png`

---

## AP-04 · 资源缺失静默 fallback

**症状**：资产已 commit 但元数据（`.import`/`.meta`）未生成 → 运行时走 fallback（占位色块）→ 无 error 日志。

**检测信号**：
- playtest 脚本 PASS 但人工跑游戏全是占位
- 用户反馈"全是 ColorRect / 默认贴图"
- 代码出现 `if exists(): load else: fallback` 而 fallback 分支无 `push_error`
- 仓库有 `.png` 但无同名 `.import` / `.meta`（或时间戳早于 png）

**修法**：
1. production 代码检测载入失败时 `push_error`，**不** 默默 fallback；fallback 仅 dev_mode 生效
2. pre-commit hook 自动跑 `godot --headless --import`
3. `qa-gate` 加"真路径资产测试门"，禁止 mock / cheat 通过
4. 资产入库前 `art-director` 必须确认 `.import` 已生成

---

## AP-05 · API 限流时硬撞

**症状**：API 返回 429 → 反复重试同一 model → 浪费数十分钟空转 + 配额耗尽。

**检测信号**：
- 同一进程日志连续 ≥ 3 次 429 / "rate limit" / "quota exceeded"
- 单次任务耗时 > 预期 5 倍
- 代码出现 `while True: try call() except RateLimit: sleep(1)` 死循环

**修法**：
1. **N 次 429 自动切 fallback model**：不同 provider 限流计数独立
2. fallback chain 写进 `timiai-image` daemon：`primary → fallback_1 → fallback_2 → fail-fast`
3. 限流冷却时间写 cache，下次提交先查（BL-S016）
4. 切换 fallback 必须日志标 `[fallback-triggered model=X reason=429]`

---

## AP-06 · 用户反馈循环没有自动学习

**症状**：用户反馈"X 不对"被解决了但没沉淀进 SOP，下个项目又会犯。修一次只对一次。

**检测信号**：
- 同一类问题在不同项目 / sprint 反复出现（grep retro 关键词重复）
- 反馈解决后没有 commit 修改 anti-patterns / agent SOP / rule
- retro 中出现"这个之前似乎也踩过"
- backlog 里同一类 issue ≥ 3 个

**修法**：
1. 每次用户反馈触发的修复后强制流程：(a) 写进项目 retro → (b) 是否通用 → 是则升级到本文 → (c) 改对应 agent / skill 的 SOP
2. session-start hook 注入 `anti-patterns-digest.md`，main agent 必须在响应中体现"已读"
3. `retrospective` skill 末尾固定一步："本次 retro 是否需要新增 AP-XX？"
4. 长 session（> 4h / > 20 commit）必须跑一次 `daily-check`

---

## AP-07 · settings.json 权限失效迷惑

**症状**：`.codebuddy/settings.json` 里写了 `permissions` allow/ask/deny **以及** `hooks` 字段，**IDE 插件版完全不读这两个字段**。同时 CodeBuddy 对 `Remove-Item` / `rm` 等删除命令有内置硬保护（不在配置层）。

**检测信号**：
- `Remove-Item` / `Move-Item` 反复弹审批，明明 settings.json 写了 allow
- 配 `PreToolUse` hook 后 `.codebuddy/logs/` 从未被自动创建
- 切换"IDE GUI 开关 vs settings.json"得到不同行为
- 重启 IDE 后行为依然不变

**修法（强制约束）**：
1. **不要往 settings.json 加 `permissions` / `hooks`**——纯装饰
2. **agent 删文件 → 必须用 `delete_file` 工具**，永远禁止 `Remove-Item` / `rm` / `del`
3. 文件读写改名 → 优先 IDE 工具（`read_file` / `write_to_file` / `replace_in_file` / `delete_file`），不用 PowerShell / bash
4. 批量任务 → Python 脚本一次审批跑完
5. spawn sub-agent 时 prompt 显式约束"文件操作必须用工具调用，禁止 Remove-Item / rm / del"

> 实测铁证（含重启复测）见 `anti-patterns-archive.md` §AP-07

---

## AP-08 · 复合命令触发整串审批

**症状**：`cd X; cmd1; cmd2` 整串被当作一条命令处理，权限按整串首词匹配。即使每条单独都在 allow 列表，整串依然每次弹审批。

**检测信号**：
- agent 输出 `cmd1; cmd2; cmd3` 或 `cmd1 && cmd2` 被审批拦截
- 同一条 `cd && do_something` 反复弹窗，但单独执行 `cd` 或 `do_something` 都不弹
- session 中审批次数 > commit 次数

**修法**：
1. agent 输出 PowerShell / bash 命令时**默认每条独立**——禁止 `;` `&&` `||` 复合，分多次 tool call
2. 需要批量执行时改写成 Python 脚本（一次审批，脚本内部跑完）
3. 文件操作优先 IDE 工具，不用 shell

---

## AP-09 · sub-agent 声称 PASS 但未验证落盘完整性

> 根因已修复（hook bug，2026-05-19）。本条作为防御性保留——核心教训"交付前验证落盘完整性"仍通用。

**症状**：sub-agent 用 write_to_file 写长文件，返回成功但实际内容被截断到 ~40 行。agent 声称 self_rubric PASS 但没 read_file 验证。

**检测信号**：
- agent 声称写了 N 行但 read_file 显示 ≤ N×0.3
- 代码文件在函数体中间截断（最后一行是 `_` 或半截标识符）
- agent 声称 self_rubric 7/7 PASS 但实际不完整
- engine_check EXIT 0 但代码明显不完整

**修法**：
1. **写完后 read_file 验证行数**：< 80% 视为截断，用 replace_in_file 追加补全
2. schema self_rubric 加 [防截断] 条目（5 核心 agent 已加）
3. reviewer 检查"文件末尾在函数中间"→ critical_issue
4. engine_check EXIT 0 ≠ 实现完整——必须对照 AC 逐条验证

---

## AP-10 · AI 自嗨循环：机制全 PASS 但产品实际不能玩

**症状**：所有自动化质检通过（self_rubric 7/7 / reviewer APPROVE / shadow QA-PASS / headless EXIT 0 / 测试 16/18 PASS），但用户首次实玩 < 1 分钟发现 ≥ 3 个严重问题（画面糟糕 / 镜头不动 / 走出屏幕）。

**检测信号**：
- 所有 verdict 全 PASS / APPROVE 但用户首次试用 < 1 分钟发现 ≥ 3 个问题
- agent 产出文件总数与"完整产品所需"不匹配（如有 player + level 但没 Camera2D）
- 测试覆盖率高但用例不模拟真实玩家路径
- AC 列表只覆盖代码层契约不覆盖体验维度
- session 全程 0 用户介入 + 自动声明 `QUALITY_PROVEN`
- GDD §4/§5/§6 写了但 engineer 实现时没真读

**根因**：
1. schema 是"代码契约"不是"产品契约"
2. reviewer / shadow 都是同代 LLM，共享盲区
3. 资产生成 ≠ 资产合用（image_gen 缩到 32x32 必然糊）
4. 没有 playtest gate
5. GDD 与实现脱钩

**修法**：
1. **dev-story 加 playtest_pending 状态**：reviewing → playtest_pending → done，必须真人实玩 ≥ 1 分钟
2. **AC 必须含玩家体验维度**：每涉及玩家可见行为的 story，AC ≥ 1 条"玩家能看到 / 感受到 X"
3. **vertical slice 强制 5 项清单**（TPL-09）：camera follow / 屏幕边界 / 主角辨识度 / 死亡反馈 / 完成反馈，任一缺失 REQUEST_CHANGES
4. **资产评审强制 in-context 渲染**（TPL-05 v2）：必须看资产放进 level 截图后的样子
5. **GDD ↔ 实现一致性 grep**：每个 story 完成时 grep GDD 关键词（camera/boundary/feedback/death/win）
6. **不允许 AI 自宣 QUALITY_PROVEN**：AI verdict 加 `_MECHANISM` 后缀，`QUALITY_PROVEN` 仅用户实玩反馈触发

---

## AP-11 · Godot 渲染层陷阱（transform / @export / z_index）

**症状**：代码 / 测试 / headless check 全 PASS 但资产在游戏画面里看不到 / 在错误位置 / 旋转错误。`.import` 齐全、Sprite2D 配置正确，但实际渲染时资产消失或在 (0,0)。

**检测信号**：
- in-context 截图中某资产在应该出现的位置空白
- 节点位置计算正确但 sprite 不见
- scene 配置 `@export var X = 2` 但运行时 X 为默认值 0
- 多帧旋转 / 缩放后 sprite 跑到屏幕外
- 父节点是 `Node` 而非 `Node2D`

**根因清单**：
1. **transform 链断裂**：`Node` 不是 CanvasItem 子类，不传播 transform。例：`PuzzleArea(Node2D) → SignalNetwork(Node) → PipeA(Area2D)` → PipeA 渲染在 (0,0)。**修法**：所有 2D 父节点链必须 `extends Node2D`
2. **@export 缺失**：GDScript 中 `var X = 0` 没标 `@export`，scene tscn 设的值在运行时被脚本默认值覆盖。**修法**：所有想在 inspector / tscn 配置的字段必须 `@export`
3. **`_ready()` 未同步配置**：例如 `rotation_steps` 是 export 但 `rotation_degrees` 没在 `_ready()` 同步。**修法**：`_ready()` 末尾把 export 字段同步到 godot 内置属性
4. **z_index 错误**：sprite 在地形 / 背景下层。**修法**：关键交互元素 z_index ≥ 1，背景 ≤ 0
5. **CanvasLayer 误用**：UI / HUD 子节点位置按屏幕坐标，与世界坐标混淆

**修法**：
1. **强制 in-context 渲染评审**（TPL-05 v2）：raw 资产 OK 不代表渲染 OK
2. **screenshot 工具常驻**：`studio/templates/godot-screenshot/`
3. **资产应出现但没出现 → 立即诊断**（顺序：node 类型 → @export → z_index → scene/script 覆盖关系）
4. reviewer 在 TPL-09 vertical slice 评审中含"资产应出现位置实际是否可见"

---

## 维护约定

- **新反模式发现路径**：先在某次 retro / postmortem 触发记录，再升级到本文。禁止凭空创作
- 每条 AP-XX 编号一旦分配不可重用，废弃改 `[deprecated]` 但保留编号
- 修订须更新 `anti-patterns-archive.md` 修订历史段
- 每次本文修订必须**同步更新** `anti-patterns-digest.md`（CORE 层）
- 新增 AP 必填：症状 / 检测信号 ≥ 3 条 / 修法 ≥ 2 条可执行 / archive 关联
- **进化检查**：用 `python .codebuddy/scripts/check_progressive_disclosure.py` 验证本文未触红线（safe ≤150 / notice 250 / review 400）

## 关联文档

- 速读 CORE：`anti-patterns-digest.md`（session-start hook 注入）
- 历史 ARCHIVE：`anti-patterns-archive.md`（仅 RCA / postmortem 时查）
- 工作室 backlog：`studio/backlog.md`
- 渐进披露架构：`progressive-disclosure-architecture.md`
