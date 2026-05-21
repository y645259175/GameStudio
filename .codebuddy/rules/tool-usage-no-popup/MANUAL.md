# tool-usage-no-popup · MANUAL

> CORE 见 `RULE.mdc`。本文是按场景的详细 SOP。
> 历史触发事件见 `ARCHIVE.md`。

## §long-session · Long Session 卫生（BL-S024）

session 持续越长，main agent 对文件状态的"心理模型"越不准确，`replace_in_file` 失败率显著上升。

### 常见失败模式

| 失败原因 | 现象 | 修法 |
|---|---|---|
| 上下文过时 | "old_str not found"（文件已被多次修改） | 调 `replace_in_file` 前 `read_file` 重读关键段 |
| old_str 不唯一 | "found multiple times" | 增加 2-3 行上下文使其唯一；尤其避免 `---` / `## ` 等通用分隔符 |
| 编码 / BOM | 不可见字符不匹配 | 用 `read_file` 看 raw 输出确认；PowerShell 写入的 utf8 文件含 BOM 需 `lstrip("\ufeff")` |

### 强制规则

- 任何文件**被本 session 修改过 ≥ 2 次** → 下次 `replace_in_file` 前必须先 `read_file` 重读
- old_str 长度 < 50 字符或仅含通用 token（如 `---` / `##` / 空行）→ **拒绝**，加上下文重写
- 单 session 同一文件 `replace_in_file` 失败 ≥ 2 次 → **改用 `write_to_file` 重写整段**

### 需要命令行删除时的绕过

1. `cmd /c "del /f path"`（不弹窗，cmd 的 del 不被特殊拦截）
2. `python -c "import os; os.remove('path')"`
3. 封装成 `cleanup.py` 后 `python cleanup.py`

---

## §flow-discipline · 流程逃逸禁令（BL-S025）

**禁止**：sub-agent 在 dev-story 状态机外**自重写已交付内容**。

### 具体场景

- engineer 在 story-N 之外修改 story-(N-1) 已 done 的代码 → 必须先把 story-(N-1) 状态回退到 implementing 或 spawn 新 hotfix story
- reviewer / qa-lead 直接改实现而非给 critical_issues → 必须 spawn engineer
- art-director 直接改 .gd 而非给 reject_remediation → 必须 spawn engineer

### 例外（允许的"小修"，无需新 story）

- ≤ 5 行的拼写 / 注释修复
- 跟随当前任务必须的临时调试（结束前必须删除）

---

## §value-consistency · 数值一致性回路（BL-S026）

发现 GDD §3 / story AC / data/*.json / 代码 4 处中**任意两处数值不一致**时：

1. 不允许某一方"私自决定"取哪个值
2. 必须走三方共识：designer + engineer + reviewer
3. 共识结果落 `projects/<name>/adr/` 或 retro
4. 一方修改后另两方在 24h 内确认
5. designer 同步更新 GDD 版本号 + 落 retro

---

## §shadow-team-mode · Shadow Review 必须 team mode（BL-S030）

`dev-story --shadow` 生成的 shadow prompt **不允许**用 batch task 模式 spawn。

### 原因

- batch task 模式下两个 agent **共享 main agent 的同一上下文**，shadow 会"看到"主 reviewer 的 verdict，丧失独立性
- team 模式（带 `name` + `team_name` 参数）才真正隔离

### 强制规则

- spawn shadow agent 必须用 task 工具的 `name` + `team_name` 参数
- 主 reviewer 用普通 task spawn，shadow 用 team 模式 spawn
- shadow 看不到主 verdict → 给出真正独立的判断 → 比对 disagreement

---

## §godot-headless · Godot Headless 测试限制（BL-S027）

`_physics_process` 在 godot --headless --script 单帧模式下不会执行 → 物理行为测试只能 SMOKE。

### 应对

- 不能跑物理的测试用 `_skip()` + 注释说明 headless 限制（现有做法 OK）
- M3+ 引入 GUT 框架（multi-frame 测试）
- 验收 vertical slice 必须**真人实玩**而非依赖 headless 测试结果（已是 AP-10 修法 / playtest_pending 状态机的核心）
