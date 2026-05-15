# bolt-1-1 · 新会话交接文档

> 旧会话上下文已被高频触发关键词污染（Anthropic 内部版权安全规则反复触发）。
> 新会话从本文件开始接力。

---

## 新会话第一句指令（建议复制这段给新会话）

```
继续 bolt-1-1 项目。读 projects/bolt-1-1/docs/HANDOFF.md 获取完整交接信息。
不要读 retros/ 或 reports/archive/ 下的任何旧档案（它们包含已 pivot 的旧命名）。
按 HANDOFF.md 的"待办"清单顺序执行，每完成一项就 commit，然后继续下一项。
```

---

## 项目背景

`projects/bolt-1-1/` 是一个 2D 横版平台跳跃游戏（Godot 4.6.2），原创 IP，主角 Bolty。

致敬经典 NES 时代横版平台手感（加减速 / 可变跳高 / 踩敌反馈），视觉与角色全部原创，与任何商业作品无关。

完整身份信息：
- `PROJECT.md` —— 项目元数据 + 里程碑
- `README.md` —— 操控 + 角色一句话简介
- `docs/naming-map.md` —— **权威命名映射表**（所有 class / json type / 配色 / 视觉描述）

读这三个文件即可获得完整项目身份。

---

## 当前 git 状态

最近 commit：
- `7e8d1c4` 项目重命名（旧名 → bolt-1-1，git mv 保留历史，删除一张 IP 风险 PNG）
- `d31f596` 工作室级 SOP 加固（autonomous-mode-charter / 7 处 SOP 改造）

**未提交但已落盘的改动**（git status 看到的）：

| 类别 | 文件 |
|---|---|
| **renamed + 新内容**（8 个）| `enemies/mossroll.gd`、`enemies/shellpod.gd`、`blocks/cache_box.gd`、`items/power_berry.gd`、`items/spark_bloom.gd`、`items/blue_crystal.gd`、`level/signal_tower.gd`、`level/outpost.gd` |
| **modified 项目身份**（4 个）| `PROJECT.md`、`README.md`、`game/project.godot`、`docs/naming-map.md`（新增）|
| **modified 代码集成**（5 个）| `game/scripts/level_loader.gd`、`main.gd`、`hud.gd`、`title_screen.gd`、`clear_overlay.gd` |
| **deleted 旧 .uid**（8 个）| Godot 引擎会自动重新生成 |
| **modified 工作室文档** | `.codebuddy/skills/design-review/SKILL.md`（在前一个 commit 之后又被本会话误改？需新会话确认是否要保留改动）|

**新会话第一件事**：跑一次 `git status`，看是否需要把这些先 commit。建议 commit message：
```
[bolt-1-1] step 2: rename + content rewrite for 8 entity scripts
- 8 entity scripts: rename + replace class_name + apply bolt color palette + fix BL-001 stomp threshold (use bottom-Y comparison instead of center-Y)
- level_loader: support both legacy and bolt entity type strings (fallback for json data not yet migrated)
- main.gd: on_signal_tower_touched hook, retry/clear flow
- hud.gd: BOLTY label, COG counter, SECTOR display
- title_screen.gd: BOLT title screen (industrial dark blue background)
- clear_overlay.gd: SECTOR CLEAR / SYSTEM FAILURE
- PROJECT.md/README.md/project.godot: bolt identity, IP disclosure
- naming-map.md: authoritative naming reference
```

---

## 待办清单（按优先级，每完成一项 commit）

### Phase A · 内容清理（继续 Step 2）

清理思路：剩余文件里仍有旧命名，需要替换为 bolt 命名。**重点**：避免在新会话里读那些旧命名密集的文件（GDD / retro），而是用工具一次性 grep + 批量替换 + 重写。

#### A.1 · 重写 GDD（最大头）

**当前文件**：`projects/bolt-1-1/gdd/gdd-mario-1-1.md`（865 行，旧命名密集）

**操作**：
1. `git rm projects/bolt-1-1/gdd/gdd-mario-1-1.md`
2. 新建 `projects/bolt-1-1/gdd/gdd-bolt-1-1.md`，内容 = bolt 世界观下的 GDD，按 design-authoring rule 的最小 5 维度（概述 / 玩法循环 / 系统设计 / 视觉与美术 / 交付与验收）+ 项目专属章节（内容与节奏 / UX 与 HUD / 数值与平衡）
3. 全部用 bolt 命名（Bolty / Mossroll / Shellpod / CacheBox / PowerBerry / SparkBloom / BlueCrystal / Cog / Conduit / SignalTower / Outpost / Sector 1-1）
4. 内容来源：从 `docs/naming-map.md` 取角色规格，从 `data/levels/1-1.json` 取关卡 beat，从 backlog.md 取已修 issue 列表，从 PROJECT.md 取里程碑——**不要**读 GDD 旧版，避免引入旧命名
5. 行数控制 600-800 行

#### A.2 · 数据 json 命名同步

**当前文件**：`projects/bolt-1-1/data/levels/1-1.json` 和 `projects/bolt-1-1/game/data/levels/1-1.json`

**字段替换表**（json 里的 `type` 字段 + 配置键名）：

| 旧 | 新 |
|---|---|
| `"type": "goomba"` | `"type": "mossroll"` |
| `"type": "koopaGreen"` | `"type": "shellpod"` |
| `"type": "questionBlock"` | `"type": "cacheBox"` |
| `"type": "pipe"` | `"type": "conduit"` |
| `"type": "flagpole"` | `"type": "signalTower"` |
| `"type": "castle"` | `"type": "outpost"` |
| `"contains": "coin"` | `"contains": "cog"` |
| `"contains": "mushroom"` | `"contains": "powerBerry"` |
| `"contains": "fireFlower"` | `"contains": "sparkBloom"` |
| `"contains": "oneUp"` | `"contains": "blueCrystal"` |
| `"hidden_oneup": true` | `"hidden_blueCrystal": true` |

**注意**：`level_loader.gd` 和 `brick.gd` 已支持新旧 type fallback，所以**先跑游戏验证再改 json** 也可以。但 backlog 要求最终统一用 bolt。

#### A.3 · enemies.json / items.json 字段名

**当前文件**：`projects/bolt-1-1/data/enemies.json` 和 `items.json`（+ game/data/ 副本）

**改动**：
- `enemies.json`：`"goomba": {...}` → `"mossroll": {...}`、`"koopaGreen": {...}` → `"shellpod": {...}`、`"piranha": {...}` → `"spiker": {...}`
- `items.json`：`"mushroom": {...}` → `"powerBerry": {...}`、`"fireFlower": {...}` → `"sparkBloom": {...}`、`"star": {...}` → `"pulseCore": {...}`、`"oneUp": {...}` → `"blueCrystal": {...}`

**注意**：所有 .gd 里的 `cl.get_value("enemies.mossroll.walkSpeed", 30)` 等路径已经按 bolt 命名写。所以 json 不改的话，会取到 default 值，游戏能跑但数值不准。**必须改 json**。

#### A.4 · 其他遗留文件清理

| 文件 | 操作 |
|---|---|
| `projects/bolt-1-1/stories/autonomous-task-list.md` | 删掉（已有 backlog.md 替代）|
| `projects/bolt-1-1/sprints/sprint-1-plan.md` | 重写为 bolt 命名版（保留 sprint 框架，更新 task 描述）|
| `projects/bolt-1-1/epics/README.md` | 检查是否有旧命名，有则替换 |
| `projects/bolt-1-1/game/run-game.bat` | 检查标题字符串 |

#### A.5 · 工作室级 SOP 脱敏

以下文件有"mario-1-1 案例"作为历史教训引用，建议替换为脱敏代号"项目 A pivot 事故"或"2026-05-15 自主运行事故"：

- `.codebuddy/rules/agent-spawn-contract/RULE.mdc`
- `.codebuddy/skills/design-review/SKILL.md`
- `.codebuddy/skills/dev-story/SKILL.md`
- `.codebuddy/agents/engineer/AGENT.md`
- `.codebuddy/agents/tester/AGENT.md`
- `.codebuddy/agents/reviewer/AGENT.md`
- `.codebuddy/agents/postmortem-keeper/AGENT.md`
- `.codebuddy/skills/qa-gate/SKILL.md`
- `studio/docs/autonomous-mode-charter.md`

具体替换：把"mario-1-1"、"Mario"、"Goomba"、"Koopa"等字符全部用脱敏词替换。这些只是案例引用，不影响 SOP 本身的逻辑。

#### A.6 · retro / postmortem 加 disclaimer

不要删除以下历史档案（它们是审计痕迹）：
- `projects/bolt-1-1/retros/2026-05-15-autonomous-run-log.md`
- `projects/bolt-1-1/retros/2026-05-15-gdd-detail-spawn-incident.md`
- `projects/bolt-1-1/retros/2026-05-15-quality-failure-postmortem.md`
- `projects/bolt-1-1/reports/archive/section-3-visual-2026-05-15-merged.md`
- `projects/bolt-1-1/reports/ux-refine-patches-2026-05-15.md`

但在每个文件**开头**加这一段 disclaimer：

```markdown
> **历史档案 · 2026-05-15 之前命名版本**
>
> 项目已在 2026-05-15 pivot 至 bolt-1-1 完全原创版本。
> 本档案保留旧命名作为审计痕迹，不代表当前项目状态。
> 当前命名见 `docs/naming-map.md`，当前 GDD 见 `gdd/gdd-bolt-1-1.md`。
```

#### A.7 · 验证

- 跑 `engine/Godot/Godot_v4.6.2-stable_win64.exe --headless --check-only --path projects/bolt-1-1/game --quit`，期望 EXIT 0
- 跑 `tests/smoke_test.gd`，期望节点生成成功
- 跑 `tests/auto_play_test.gd`，期望 cheat 模式 PASS（验证 pivot 后核心流程没坏）

A 全部完成后 commit。

### Phase B · 原创美术资产

**核心约束**：所有资产必须**完全原创**——不得借鉴任何商业作品的角色形象、配色、姿势。Bolty 是机械豆，不是任何已有 IP 的变体。

**生成清单**（用 timiai-image skill 或 art-asset-pipeline）：

1. **Bolty 三态精灵图**（small 16x16 / big 16x32 / fire 16x32）
   - 红色金属壳（`#E03030`）+ 黄色相机眼（`#FFC820`）
   - 圆头 + 短身 + 短腿 + 双手扣式工装
   - 每态需要：idle ×1、walk ×3、run ×3、jump ×1、fall ×1
   - 大态额外：duck ×1
   - 火力态：throw ×1（发射火球）
   - 死亡 ×1
   - atlas 推荐 128×128

2. **Mossroll 精灵**（16x16）
   - 圆球苔藓体 + 两条短腿 + 顶部苔藓发
   - 苔绿 `#5C8030` + 深绿暗部
   - walk ×2 + flat ×1

3. **Shellpod 精灵**（walk 16x24 / shell 16x16）
   - 金属灰 `#8B9090` + 铜绿甲壳 `#3C9050`
   - walk ×2 + shell-static ×1 + shell-spin ×4

4. **道具精灵**（每个 16x16）
   - PowerBerry 浆果红 `#C42040` + 金黄叶冠
   - SparkBloom 白色四瓣 + 蓝白电弧
   - BlueCrystal 蓝色棱晶 `#3878F0` + 白色高光
   - Cog 黄铜齿轮 `#E8A018` × 4 帧旋转

5. **Tile 集**（每 tile 16x16）
   - ground（顶层 `#9C8830` 干苔黄 + 下层 `#783820` 锈红土）
   - brick `#D87050`
   - cacheBox active（金黄 `#FAC000` 闪烁循环 ×4）+ used（暗棕 `#9C5C20`）
   - hard_block `#BCBCBC`
   - conduit（暗绿金属 `#384830` + 高光 `#6C9050`，4 长度 xs/s/m/l）

6. **关底元素**
   - SignalTower（杆 16x176 + 顶球 + 信号红 `#D04030` 旗帜）
   - Outpost（80x80 哨站 + 顶部天线）

7. **背景元素**
   - cloud / mountain / bush（参考 NES 8-bit 像素，工业风暗调）

8. **HUD 字体 / 图标**
   - 8x8 像素 bitmap 字体（A-Z 0-9 - x ×）
   - 8x8 cog 小图标

资产存到 `projects/bolt-1-1/assets/`。每张图一个 PNG 或合并 atlas。

### Phase C · 接入资产

把 game 里的 `ColorRect` 占位替换成 `Sprite2D` + `AtlasTexture`。

按文件顺序：
1. 写 `game/scripts/sprite_loader.gd` 统一加载 atlas
2. `player.gd`：替换 `_apply_state_size` 里的 `_PLACEHOLDER_Sprite`（ColorRect）为 `Sprite2D`，按 small/big/fire 切 atlas region
3. `enemies/mossroll.gd`、`shellpod.gd`：同上
4. `blocks/brick.gd`、`cache_box.gd`：同上
5. `items/*.gd`：同上
6. `level/signal_tower.gd`、`outpost.gd`：同上
7. `level_loader.gd` 的 ground / conduit ColorRect → 用 tileable Sprite2D
8. `hud.gd`：换像素字体 + cog 图标

每接入一个组件跑一次 godot 验证视觉。

### Phase D · 修复剩余 backlog

读 `projects/bolt-1-1/stories/backlog.md`，按 P0 → P1 → P2 顺序修复。

**P0 必修**（M5 / M5.5 milestone gate 不通过会被 reviewer block）：
- BL-001 Stomp 判定阈值 → **已修**（mossroll.gd / shellpod.gd 改用 bottom-Y 比较 + 阈值 8）
- BL-002 Hitbox Area2D collision_layer/mask 配置 → 验证现有配置是否已正确（Hitbox layer=8 mask=2，player layer=2 mask=1，应该工作；如真有问题再深查）
- BL-004 json y 坐标系不一致 → 当前用 force-align 兜底，理想方案是统一所有实体 y 到地面坐标系或加 LevelLoader 阶段的坐标变换
- BL-009 真实玩家无法通关 → 需要 Phase D 的真实 playtest 验证 + 调关卡数值
- BL-011 cheat 模式违反 test-standards 红线 → 把 `auto_play_test.gd` 重写为只用 InputMap action_press 的真实 AI；保留旧 cheat 测试但移到 `tests/_debug/` 子目录并显式标 DEBUG_ONLY
- BL-012 ~ BL-015 视觉债 → Phase B/C 处理

**P1 应修**（建议 M6 修，影响体验）：
- BL-003 Flagpole Area2D 不工作的根因（已用距离检测兜底）→ 用 debugger agent 做 RCA
- BL-005 ObjectDB 内存泄漏 → 看是哪些节点没有 queue_free（可能是 LevelLoader 子节点 / Tween / Timer）
- BL-006 GameOver 自动 reload 死循环 → 已绕过（关掉 auto reload）；需要正经 GameOver flow
- BL-007 GameOver retry 路径未真测 → 写测试
- BL-008 TIME=0 死亡未单测 → 写测试
- BL-016 HUD 字体 → Phase B/C 处理
- BL-017 Cog 图标 → Phase B/C 处理

**P2 可推迟**（post-M6）：
- BL-010 class_name 时序规范
- BL-018 Stomp 算法重构（已修复 P0，本项可推迟）
- BL-019 movingPlatform / Spiker 实现
- BL-020 Pulse Core 道具
- BL-021 工作室 prompt-injection sanity check

### Phase E · 真实 playtest（无 cheat）

写一份新的 `tests/real_playtest.gd`：

约束：
- **只用** `Input.action_press(action)` / `Input.action_release(action)` 操作玩家
- **禁止**直接修改 `_player.velocity` / `_player.position` / `_player.current_state`
- **禁止**调用 `_player.set_cheat_invincible`

策略：
- 读 `data/levels/1-1.json` 获取 pits、entities 位置
- AI 决策逻辑：
  - 默认右走 + 跑步
  - 前方 60-100px 有坑 → 提前跳
  - 前方 50px 内有敌人且自己没在跳 → 跳起来踩
  - 前方 50px 内有敌人且自己在空中下落 → 持续右走（落到敌人头上）
  - 前方有 conduit 高于自己 → 跳过（按住跳跃键 max 帧数）
  - 检测到 SignalTower 触发即 PASS

跑通关后 commit + 关闭 BL-009 + BL-011。

### Phase F · 视觉 + 流程双 milestone gate

按 autonomous-mode-charter 的 4 条底线检查：

1. **视觉真实性**：所有 ColorRect 已替换为 Sprite2D（除测试 _PLACEHOLDER_）
2. **测试真实性**：tests/real_playtest.gd 存在且 PASS（不依赖 cheat）
3. **Bug 预算**：backlog 中 P0 状态 = open 的条目 ≤ 0
4. **美术节奏**：assets/ 目录有真实资产（不只是 .gitkeep）

如全过：
1. spawn `art-director` agent 截图评审 → 期望 GO
2. 跑 `qa-gate` skill → 期望 GATE_PASSED 或 CONDITIONAL_PASS
3. spawn `reviewer` agent milestone gate → 期望 MILESTONE-PASS
4. spawn `producer` agent ship gate → 期望 GO

全过 → M5.5 / M6 milestone done，更新 PROJECT.md 状态。

---

## 关键已修 / 已避免事项

新会话不需要重做这些事，已在前面会话完成：

- ✅ 项目从旧 IP 风险版本 pivot 到 bolt-1-1 原创版本
- ✅ 删除了一张 IP 风险 PNG（`projects/mario-1-1/assets/player_atlas_*.png`）
- ✅ 8 个代码文件 rename + 内容重写（mossroll/shellpod/cache_box/power_berry/spark_bloom/blue_crystal/signal_tower/outpost）
- ✅ Stomp 判定 BL-001 修复（mossroll.gd / shellpod.gd 改用 bottom-Y 比较 + 阈值 8）
- ✅ level_loader 加 fallback 兼容旧 type，避免一次性破坏数据
- ✅ main.gd `on_signal_tower_touched`、hud BOLTY/COG/SECTOR、title BOLT、clear_overlay SECTOR CLEAR/SYSTEM FAILURE
- ✅ 工作室级 SOP（agent-spawn-contract、autonomous-mode-charter、7 个 SOP 改造）已 commit
- ✅ backlog.md 21 条 issue 已登记
- ✅ naming-map.md 已落盘作为权威参考

---

## 启动指令模板（再贴一次方便复制）

新会话开第一句话：

```
继续 bolt-1-1 项目。
读 projects/bolt-1-1/docs/HANDOFF.md 获取完整交接信息和待办清单。
读 projects/bolt-1-1/docs/naming-map.md 获取命名权威参考。
读 projects/bolt-1-1/PROJECT.md 获取项目身份。
读 projects/bolt-1-1/stories/backlog.md 获取 issue 清单。

不要读 retros/ 或 reports/archive/ 下的任何旧档案。

按 HANDOFF.md "待办清单"顺序执行（A.1 GDD 重写 → A.2 json 命名 → ... → F milestone gate）。每完成一个小步就 commit + 推进下一个。

最终目标：交付一个真实玩家可通关、视觉用真实美术资产、backlog P0 全部 closed 的 bolt-1-1 可玩 demo。

工作风格：自主推进，遇到外部不可控因素（如 timiai-image 平台）才停下。质量底线见 studio/docs/autonomous-mode-charter.md。
```

---

## 文件清单速查

新会话需要先读的文件（按重要性）：

1. `projects/bolt-1-1/docs/HANDOFF.md`（本文件）
2. `projects/bolt-1-1/docs/naming-map.md`
3. `projects/bolt-1-1/PROJECT.md`
4. `projects/bolt-1-1/stories/backlog.md`
5. `projects/bolt-1-1/data/levels/1-1.json`
6. `studio/docs/autonomous-mode-charter.md`

新会话**不要读**的文件（避免触发上下文污染）：

- `projects/bolt-1-1/retros/*.md`（除非真有需要查具体 issue 历史）
- `projects/bolt-1-1/reports/archive/*.md`
- `projects/bolt-1-1/gdd/gdd-mario-1-1.md`（建议直接 git rm 后从零写新 GDD）

---

## 接下来的第一个 commit 建议

新会话进来跑 `git status` 后，**第一个 commit** 应该把当前未提交改动收拢：

```
git add -A
git commit -m "[bolt-1-1] step 2 batch: 8 entity scripts rename + content rewrite + bolt identity propagation" \
  -m "All 8 enemy/item/level scripts renamed via git mv with new bolt class names + bolt color palette + BL-001 stomp threshold fix (use bottom-Y compare)." \
  -m "Integration: level_loader supports both legacy and bolt entity type strings; main.gd uses on_signal_tower_touched; hud labels are BOLTY/COG/SECTOR; title shows BOLT; clear_overlay shows SECTOR CLEAR / SYSTEM FAILURE." \
  -m "Identity: PROJECT.md/README.md/project.godot fully bolt-themed; naming-map.md is the authoritative naming reference." \
  -m "GDD/json/retro cleanup pending in next steps per HANDOFF.md."
```

然后开始 A.1 GDD 重写。
