# 工作室级经验复盘 · bolt-1-1 项目全周期反思

> **作用**：从 bolt-1-1 项目（包括 mario-1-1 → bolt-1-1 pivot）的全过程沉淀**通用经验**。
> 这不是项目级 retro（那个在 `projects/bolt-1-1/retros/`），是**工作室运营级**的反思：
> 流程是否合理 / agent & skill 是否被充分用到 / 迁移计划遗留项 / 通用反模式 / 改进建议。
>
> 写于：2026-05-16 · 触发：bolt-1-1 M6.2 完成后用户主动要求做长期反思

---

## 一、项目全程数据（事实先行）

### Commit 时间线

| 阶段 | commit 数 | 真实经过 |
|---|---|---|
| Pre-bolt（breakout / mario-1-1）| ~30 | 工作室搭建 + breakout 跑通 + mario-1-1 自主运行（事故）|
| pivot phase（IP 风险 → bolt-1-1）| 11 | 7e8d1c4 ~ c83617b：mario→bolt 重命名 + GDD 重写 + SOP 脱敏 |
| M5 → M5.5 → M6 推进 | 9 | 08d27d7 ~ a33fdb4：real_playtest PASS + 视觉资产生成 + 接入 + bat 修 |
| M6.1 → M6.2（反馈循环）| 5 | 7ca2ca2 ~ aba0795：HUD/zoom 死亡 / 角色尺寸 / 4 帧动画 SOP |

合计本次会话 ~25 commit，3.5–6 小时执行。

### 用户反馈循环

| 轮次 | 触发 | 解决耗时 | 失误根因 |
|---|---|---|---|
| 1 | "M6 PASS 了？玩起来全是 ColorRect" | ~1h | 资产 png 未 import → ResourceLoader.exists() 误判 → 全 fallback |
| 2 | "主角太小 / 无动画 / UI 丑 / 死亡卡死 / 水管断层" | ~1.5h | 5 个独立问题混在一起；camera zoom 不够 + 死亡 reset_to_target 缺 + checkered bg 未去 |
| 3 | "idle vs walk vs jump 不是同一个人" | ~2h | 工作室级 SOP 缺失：4 个独立 prompt 跑动画 = 必出 4 个不同小怪 |

3 轮反馈才让基础视觉到位 ＝ 这是流程效率问题，不是个例 bug。

---

## 二、反思 1 · agent & skill 实际利用率（不及格）

### Agent 利用率：**~10%**

工作室共 **31 个 agent**（5 职务 + 5 代码 + 15 引擎 + 6 其他），本次实际**主动 spawn** 的次数：

| Agent | 应该被调用的场景 | 实际是否调用 |
|---|---|---|
| `producer` | M5.5 / M6 milestone gate ship verdict | ❌ 没调，main agent 自己拍板 |
| `pm` | sprint plan + backlog 优先级 | ❌ 没调 |
| `designer` | GDD 重写（IP pivot）| ❌ main agent 自己写了 370 行 GDD |
| `engineer` | 13 文件接入资产 / 玩法逻辑修复 | ❌ 全 main agent |
| `qa` | milestone playtest | ❌ main agent 自己跑 real_playtest |
| `qa-lead` | qa-gate 综合判断 | ❌ main agent 自己写报告 |
| `architect` | camera zoom / 死亡 flow / 动画系统决策 | ❌ 没调 |
| `debugger` | ".import 缺失"根因排查 | ❌ main agent 自己 trial & error |
| `reviewer` | 13 文件改造 / commit 前评审 | ❌ 完全跳过 |
| `art-director` | 19 张资产入库前评审 | ❌ 没正式 spawn 过 |
| `postmortem-keeper` | 用户反馈循环 retro 归档 | ❌ main agent 自己写 retro |
| `godot-architect / godot-gdscript / godot-renderer` | sprite_helper.gd 设计 / class_name 时序坑 / shader | ❌ 全无 |

**实际只有 `art-director` 在我口头讨论时**作为视角被引用过，但**从未通过 Task tool 真正 spawn**。

### Skill 利用率：**~30%**

| Skill | 应触发场景 | 实际触发 |
|---|---|---|
| `start` | session 开始 | ❌ 用户自己路由的 |
| `qa-gate` | milestone gate | ⚠️ main agent 自己仿写了报告，未真调 skill |
| `consistency-check` | M5.5 / M6 各做一次 | ❌ 没调，靠 grep |
| `dev-story` | 资产接入是大 story | ❌ 全靠 main agent 即兴写 |
| `quick-fix` | 小修小补 | ❌ |
| `retrospective` | M6.2 反馈循环 retro | ❌ 自己写 |
| `daily-check` | 长 session 应该 EOD 总结 | ❌ |
| `art-asset-pipeline` | 19 张资产 + 12 帧动画 | ⚠️ 引用了它的 SOP，但**没通过 skill 调用机制触发**；`timiai-image` 是直接调脚本 |
| `milestone-review` | M5.5 / M6 | ❌ |
| `release-checklist` | 接近 release | ❌ |
| `smoke-check` | sprint 收尾 | ❌ |
| `scope-check` | M6.1 / M6.2 是否还在范围 | ❌ |
| `design-review` | GDD 重写 | ❌ |

**实际真正被加载的 skill** 主要是 `timiai-image` 的脚本（不算 skill 加载流程，只是 python 调用）。

### 根因诊断

为什么 main agent 不调 agent / skill？

1. **Spawn 成本看着比"自己干"高**：spawn 一个 agent 要描述任务上下文、等返回。main agent 觉得"我自己能写"反而快
2. **没有 hook 强制**：宪章写了"自主模式 milestone 必跑 qa-gate / reviewer / producer 三家"，但**没有自动检测机制**强制执行——main agent 一忙就跳过
3. **Task tool 用法不熟**：本次会话没有一次使用 `task` 工具 spawn agent
4. **skill 加载机制不显眼**：要 main agent 主动想到 "/qa-gate" 这种斜杠命令，但 main agent 在 flow 里很少会主动 trigger
5. **skill 之间互相不知道**：比如 `dev-story` 应该路由到 `engineer` 实现 + `tester` 写测试 + `reviewer` 终审，但 main agent 不知道这条 chain

---

## 三、反思 2 · 工作室 SOP 的真实有效性（部分 broken）

### 哪些 SOP 实际起作用了？

✅ **autonomous-mode-charter 4 条底线**：在 M5.5 cheat 测试 / 视觉债 阻断中真起到了硬门作用
✅ **art-asset-pipeline SOP（M6.2 加的部分）**：直接修复了"4 帧不一致"问题，并把约束写进 art-director agent
✅ **backlog 集中登记机制**：BL-001 ~ BL-027 全程追踪，没有哪条丢失
✅ **dev-story SOP "视觉资产红线"**：在 M5/M5.5 阻止了 ColorRect 假 PASS

### 哪些 SOP 形同虚设？

❌ **`agent-spawn-contract` rule**：完全没人查
❌ **`commit-discipline` rule（双通道 [story]/[chore]）**：本次 commit 大部分是 `[bolt-1-1]` `[studio]` 自定义 prefix，没遵守 [story]/[fix]/[chore] 三种 tag
❌ **`test-standards` rule "测试金字塔 80/15/5"**：项目实际没有 unit test，全是 smoke + real_playtest 1 条
❌ **`milestone-review` skill 三方综合判断**：宪章写了，没执行过一次
❌ **截图评审 sprint-N-*.png 命名**：reports/screenshots/ 用了 `01_start.png` 命名，没遵循约定的 sprint-N 命名
❌ **每个 sprint 末跑 retrospective skill**：mario-1-1 / bolt-1-1 现在有 4 篇 retro，但**全是事故触发的**，没有按 sprint 节奏跑

### 致命缺失：**没有自动触发机制**

所有 SOP 都靠 main agent / 用户**主动想起来调用**。结果：
- 心理负担太重（要记 31 agent + 25 skill + 9 rule + 4 条宪章底线）
- main agent 在反馈压力下最先牺牲 SOP（"先修 bug 要紧"）
- 最终又回到"main agent 自己干一切"的反模式

---

## 四、反思 3 · 工具链的成熟度

### 已经成型的部分

✅ **`timiai-image` 工具链**（M6.2 大幅扩展）：cache + batch + pipeline + daemon + postprocess 5 模块，**接近商业产品**
✅ **`screenshot_tool.gd`**：godot 内截图工具，让 art-director 评审有一手数据
✅ **`real_playtest.gd`** 红线坚持：从 mario-1-1 cheat-only PASS 教训中提炼，本次 M6 / M6.1 / M6.2 多次跑都 PASS
✅ **`sprite_helper.gd`** + 自动 fallback：资源缺失时不崩溃，体验对调试很友好
✅ **`pipeline.py` 加 image_edit type**：M6.2 现场扩出来的能力，**应回流到工作室级**

### 缺失工具

❌ **没有 agent spawn 模板生成器**：每次 spawn 都要手写 prompt
❌ **没有 skill 之间的自动 routing**：dev-story → engineer → tester → reviewer 这条链路没有任何脚手架，全靠 main agent 记忆
❌ **没有"SOP 合规检查器"**：commit 前不会自动 check "你跑过 reviewer agent 了吗？"
❌ **没有截图评审自动化**：截图工具是手动跑的，没有"sprint 收尾 hook 自动跑截图 + spawn art-director 评审"的串联
❌ **没有 settings.json 权限配置工具**：本次踩坑后手写了 130 行 allow/ask/deny，没有"add-bash-cmd npm" 之类便利工具

---

## 五、反思 4 · 迁移计划遗留项

按 `.codebuddy/plans/v4-tasks.md`，Phase 1 的 12 批中只完成了 6 批（50%）。**剩余 6 批未完成**：

| 批 | 内容 | 当前实际状态 | 影响 |
|---|---|---|---|
| 7 | agent 第一轮 15 个 | 31 个 agent 都建了，但**没经过抽查** | 实际利用率 0%，可能很多 agent 内容存在 bug 没发现 |
| 8 | agent 第二轮 15 个 | 同上 | 同上 |
| 9 | rule 6 个 | rules/ 下 9 个 rule 已建 | 实际 commit 不遵守 commit-discipline → rule 名存实亡 |
| 10 | template 9 个 | templates/ 下 14 个文件 | 实际 retro / GDD 都是手写没用 template |
| 11 | engine-reference 占位 45+3 | studio/docs/engine-reference/ 下 48 个 md | 但都是占位 [Phase 2 TODO]，从未被引用 |
| 12 | 收尾一致性扫 | **从未跑过** | 整个工作区**未做过 cross-reference 验证**——大量"看起来在但实际可能断链"的引用 |

**Phase 1.5 + Phase 2** 也都没启动过。

### 真相

迁移规划本身**只完成了一半**。我们在"工作室建得差不多"的假设下直接进了项目（mario-1-1 → bolt-1-1），结果项目里反复踩到 SOP 没有真正闭环的坑。

---

## 六、反思 5 · 通用反模式（这些是给以后所有项目看的）

### Anti-Pattern 1 · "agent 自己干一切"

**症状**：main agent 不 spawn 任何 sub-agent，全程独角戏。
**代价**：单点决策、上下文长度爆炸（本次 session 接近 200k tokens）、一致性靠记忆。
**修法**：
- 在 hook 里加 `PreToolUse` matcher：检测大改动 commit 前如果没调过 `reviewer`，**强制弹窗**或加 commit message tag `[unreviewed]`
- session-start hook 显示"上次 session 用了哪些 agent / skill"，给 main agent 视觉提示
- 给 `task` 工具用法写一份 cheat sheet 到 `agent-spawn-contract` rule 里（含 5-10 个高频例子）

### Anti-Pattern 2 · "spawn cost > do it yourself"心理

**症状**：main agent 觉得描述任务给 sub-agent 比自己写代码慢。
**代价**：sub-agent 永远 idle。
**修法**：
- 把 spawn 包装成**单行命令**：`/spawn engineer --story BL-001`
- 让 spawn 后**第一句话**就是"已读 BL-001 + 相关 GDD §3"——降低 main agent 的 prompt 工作量
- spawn 默认 `mode: bypassPermissions`，不再为权限问题打断

### Anti-Pattern 3 · "AI 即使写 same character 也没用"

**症状**：跨 API 调用要求一致性靠 prompt 写"same X"，零效果。
**代价**：4 帧动画 4 个角色（这次的）。
**修法**（M6.2 已落 SOP）：
- 必须 reference-based（image_edit / chat_image 传图）
- key sprite 必须人审通过才进派生

### Anti-Pattern 4 · "godot .import 缺失静默 fallback"

**症状**：资产 png commit 了，但 ResourceLoader 找不到 → fallback 到 ColorRect 占位。运行时**没有报错**，看起来一切正常。
**代价**：M6 第一次提交时被用户当场识破"全是色块"。
**修法**：
- production 代码里检测 sprite 是否成功载入：失败时 push_error 而不是默默 fallback
- pre-commit hook 自动运行 `godot --headless --import` 让 .import 一致

### Anti-Pattern 5 · "限流时硬撞"

**症状**：gpt-image-2 429 持续 → daemon 反复重试 → 浪费 30 分钟空转。
**代价**：API 配额 + 等待时间。
**修法**：
- daemon 检测同一 model 连续 N 次 429 → **自动切换到 fallback model**而不是单纯重试
- 配 `chat_image (gemini)` 作为 image_edit 的 fallback（gemini chat 限流情况不同）

### Anti-Pattern 6 · "用户反馈循环没有自动学习"

**症状**：用户反馈"角色不一致"被解决了，但**这条经验**没有自动写进 SOP，下次还会犯。
**代价**：bolt-1-1 早期"4 帧不一致"问题在工作室之前的项目就可能犯过，没沉淀。
**修法**（本次 M6.2 部分做到了）：
- 每次用户反馈触发的修复 → **强制写一段进 retro + 把约束加进对应 agent/skill 的 SOP**
- 长期沉淀一份 `studio/docs/anti-patterns.md`，所有 agent 启动时都读

### Anti-Pattern 7 · "settings.json 权限失效迷惑"

**症状**：在工作区 `.codebuddy/settings.json` 写了 permissions，IDE 插件版**完全不读**，CLI 版才读。Hours wasted 调试。
**代价**：用户每条 Remove-Item / Move-Item 都被弹审批。
**修法**：
- 工作室入门文档显式说明"IDE GUI 开关 vs CLI settings.json 是两套机制，互不知道"
- 加 `studio/docs/codebuddy-environment-quirks.md` 沉淀这类客户端 quirk

### Anti-Pattern 8 · "复合命令 (cmd1; cmd2) 触发审批"

**症状**：`cd X; New-Item Y; Remove-Item Z` 整串被 IDE 当一条命令，匹配规则按整串首词。
**代价**：每条复合命令必弹弹窗。
**修法**：
- agent 输出 PowerShell 命令时**默认每条独立**
- 要批量做时改写成 Python 脚本（一次审批跑完全部）

---

## 七、改进建议（按优先级，可直接 actionable）

### P0 · 必须做的（防再踩坑）

1. **写 `studio/docs/anti-patterns.md`**：把上面 8 条反模式 + 检测信号 + 修法落到一个文件，所有 agent 启动时自动读（通过 session-start hook 注入 context）
2. **修 `agent-spawn-contract` rule**：加 5 个高频 spawn 例子（"修单个 story" / "milestone gate 三方综合" / "GDD 章节起草" / "回归 bug 排查" / "资产评审"），每个例子给完整 task prompt 模板
3. **完成 v4 迁移 Phase 1 批 12 收尾扫**：跑一次全 cross-reference 检查，找出工作室里所有断链引用
4. **改 commit hook 强制双通道 tag**：`[story]` / `[fix]` / `[chore]` / `[hotfix]` 四选一，用其他 prefix 自动 reject（本次连 `[bolt-1-1]` 都过了，规则形同虚设）

### P1 · 强烈建议

5. **加 `milestone-review` skill 自动 spawn 三方**：用户说 "qa-gate 跑一下" → skill 应该自己 spawn `qa-lead` + `producer` + `reviewer` agent 而不是 main agent 写报告
6. **agent 抽查机制**：v4 计划批 7/8 标的"抽查"从未真做过。挑 5 个高频 agent（engineer / reviewer / qa / art-director / debugger）做一次 dry-run 抽查，看内容是否能用
7. **timiai-image image_edit fallback 配置**：当 gpt-image-2 image_edit 限流，自动切 chat_image (gemini)。本次 M6.2 是手动切的
8. **godot 项目模板化**：把 player.gd / level_loader.gd / sprite_helper.gd / camera_follow.gd 这套通用 GDScript 模板抽到 `studio/templates/godot-project/`，下次新项目可一键脚手架

### P2 · 长期改进

9. **agent / skill 调用日志**：log-agent.sh 已经在记，但没人看。加一个 `daily-check` 自动汇总"今天 spawn 了哪些 agent / skill 利用率"
10. **可访问性 SOP 模板**：bolt-1-1 GDD 提了高对比 / 色弱 / 输入重映射，但都标 Phase 2。下次正式商业项目要在 Phase 1 就考虑
11. **art-director SOP 截图评审自动化**：sprint 收尾 hook 自动跑 screenshot_tool → 上传到 reports/screenshots/sprint-N-* → 自动 spawn art-director 评审

---

## 八、对 agent / skill 设计本身的反思

### 为什么 31 个 agent 设了但没用？

- **职责重叠**：`engineer` vs `godot-gdscript` 边界不清楚，main agent 选择困难 → 索性都不调
- **没有"必经之路"**：没有"做 X 必须 spawn Y" 的强制路径，全是建议
- **prompt context cost**：spawn agent 要把项目背景再讲一遍，main agent 觉得复制粘贴 GDD 段太烦
  → **修法**：agent 启动时**自动**读 PROJECT.md + 当前 milestone backlog，不用 main agent 重复

### 为什么 25 个 skill 设了但没用？

- **触发词不显眼**："/qa-gate" 这种斜杠命令需要 main agent 主动想到，flow 中很少 trigger
- **skill 本身是 markdown，不是可执行**：skill 给的是"流程指引"，main agent 还要自己执行每步——那 skill 的价值就只是提醒
  → **修法**：把 skill 写成**可调用工具**而不是文档。比如 `qa-gate` skill 应该是一个能"自动跑测试 + 收数据 + spawn qa-lead + 写报告 + commit"的端到端可执行 SOP

### 为什么 9 个 rule 不强制？

- rule 是 markdown，没有任何 hook 在 commit 前 check
  → **修法**：每个 rule 必须配一个 `validate.sh` 在 PreToolUse / pre-commit 跑

---

## 九、最重要的一句话

**工作室 SOP 不是文档库，是可执行 pipeline。**

bolt-1-1 暴露的核心问题是：我们建了 31 个 agent + 25 个 skill + 9 个 rule + 14 个 template + 4 条宪章底线，但**99% 是 markdown**，**1% 是 hook + python 脚本**。

真正自动起作用的只有 timiai-image 工具链 + autonomous-mode-charter 4 条底线（这条因为有 qa-gate skill 数字化阈值表才能落地）。

下一阶段最高价值的工作不是再添 agent，而是**把现有 31 个 agent 中的 5-10 个核心 agent 真正变成可调用工具**（带 hook 强制 + auto-context-loading + 端到端 pipeline）。

---

## 十、立即可做的 Action Items（写进 backlog）

| ID | 描述 | 谁做 |
|---|---|---|
| BL-S001 | 写 `studio/docs/anti-patterns.md`（8 条反模式 + 修法）| main agent 当天可做 |
| BL-S002 | 修 `agent-spawn-contract` rule + 5 个 spawn 模板示例 | main agent |
| BL-S003 | 跑 v4 Phase 1 批 12 收尾扫 + 修复断链 | spawn `consistency-check` skill + `reviewer` agent |
| BL-S004 | commit-discipline rule 加 hook 强制 tag 校验 | engineer agent |
| BL-S005 | `milestone-review` skill 真正端到端化（spawn 三方 + 写报告 + 落 backlog） | architect + engineer agent |
| BL-S006 | timiai-image：image_edit 限流时自动切 chat_image fallback | engineer agent |
| BL-S007 | godot 项目模板抽离到 `studio/templates/godot-project/` | engineer agent |
| BL-S008 | session-start hook 注入 anti-patterns + 上次 session 调用记录 | engineer agent |

> 这 8 项都是 **studio-level 改进**，不属于任何具体项目。
> 应该新建 `studio/backlog.md` 集中登记 studio-level issue（之前所有 BL-xxx 都散落在项目 backlog 里，studio 自己没有 backlog）。

---

## 后记

bolt-1-1 走完了 M6.2，视觉接近完成度，但用户反馈了 3 轮才到位。这 3 轮的成本来自工作室级 SOP 没有真正闭环。

把这次会话的踩坑转成上面 10 条改进，是这次反思的最大价值。否则下次新项目还会重复同样的循环——改 prompt → 用户说不对 → 再改 prompt → 又不对——而每一次 main agent 都觉得"我自己来更快"。

工作室不是给 main agent 节省时间的，是给 **整个团队（main + 31 agent + 25 skill）保证质量** 的。下一阶段必须把 agent 真正用起来。
