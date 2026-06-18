---
gdd_id: 10
gdd_title: 主线与世界观
status: drafting
last_review: 2026-06-09
sections_complete: [设计精神, 大世界骨架, 派系骨架, 主线钩子目录, WorldEventTrigger接口, 漫画CG接口占位, M3范围, 风险扩展]
sections_pending: []
upstream_adr: [0001-double-clock]
upstream_gdd: [gdd-01, gdd-03]
verdict: drafting
---

# GDD-10 · 主线与世界观

> M1 起草纪律（用户定调 2026-06-09）：M3 不需要的内容**仅留思路骨架**，详细剧情 / 派系文化 / CG 脚本等 M5 启动时再展开（详见 `docs/m1-deferred-details.md`）。本章 M3 落地的实质内容 = **钩子目录 + WorldEventTrigger 接口**。
>
> 上游：GDD-01 §6.6 主线钩子预留 / GDD-03 §2 事件引擎（M5 主线复用）

---

## 1. 设计精神

### 1.1 本章在 M3 的最小职责

```
M3 实际产出：
  ├─ WorldEventTrigger autoload 接口（钩子可空但接口齐）
  ├─ 主线钩子 id 目录（列出 M5 可能触发的钩子）
  ├─ 大世界 / 派系 schema 骨架（id 列表 + 角色身份占位）
  └─ M3 不实装任何主线内容（剧情 M5 才填）
```

### 1.2 与其它系统的关系

- 主线**复用** GDD-03 §2 EventEngine（M5 加 `category=main_quest` 走 ADR）
- 派系数据**复用** Sect schema（GDD-01 §6.11）+ Sect.relations Dict
- 触发器**接入** TimeService（按月份/年份触发）+ EventBus（按 signal 触发）

### 1.3 M5 内容延后纪律

本章只列接口和钩子 id；剧情正文、CG 脚本、派系文化描述、关键 NPC 详细设定均延后到 M5。详细骨架占位见 `docs/m1-deferred-details.md` 的 **GDD-10** 段。

---

## 2. 大世界骨架（M3 schema 占位）

### 2.1 世界结构（高层）

```
青云大陆（M3 仅命名占位）
├─ 中央修真界（玩家宗门所在）
├─ 东海散修域
├─ 北疆妖兽荒原
├─ 西域古遗迹
└─ 南诏蛮荒
```

> 详细地理 / 历史背景 → M5 展开。M3 仅 region_id 列表。

### 2.2 Region schema 占位

```gdscript
class_name WorldRegion
extends Resource

@export var region_id: String                  # "central_xiuzhen" / "eastern_sea" / ...
@export var display_name_tid: String
@export var description_tid: String            # M3 一句话占位
@export var faction_ids: Array[String]         # 该区主导派系
@export var available_expedition_map_ids: Array[String]  # 该区可去的历练图
```

### 2.3 M3 仅 1 个 region 实装

`central_xiuzhen` — 玩家宗门所在区。M3 玩家不离开此区。其它 4 region 仅 schema 占位（M5 启用）。

---

## 3. 派系骨架（M3 schema 占位）

### 3.1 派系类型

| 类型 | 例 | M3 状态 |
|---|---|---|
| **玩家宗门** | 青云宗（玩家创建）| ✅ M3（GDD-05 / GDD-01 §6.11）|
| **正道大派** | 太华门 / 玉清观 / 万剑宗 | 📋 M3 仅 id 占位 |
| **魔道势力** | 血煞宫 / 万尸教 | 📋 M3 仅 id 占位 |
| **散修组织** | 散修盟 / 自由商会 | 📋 M3 仅 id 占位 |
| **特殊势力** | 上古宗门遗孤 / 妖族 | 📋 M3 仅 id 占位（M5）|

### 3.2 Faction schema（M3 schema）

```gdscript
class_name FactionDef
extends Resource

@export var faction_id: String                 # "central_taihua" / "blood_palace" / ...
@export var display_name_tid: String
@export var faction_type: String               # "righteous" / "demonic" / "rogue" / "special"
@export var home_region_id: String             # 主要活动区
@export var description_tid: String            # M3 一句话占位
@export var initial_relation_with_player: int = 0   # -100 ~ +100（M5 启用）

# 扩展占位（M5 启用）
@export var elder_npc_ids: Array[String] = []
@export var quest_hook_ids: Array[String] = []
@export var aesthetic_keywords: Array[String] = []   # 美术参考词
```

### 3.3 派系关系（M5 启用）

复用 Sect.relations Dict（GDD-01 §6.11）：

```gdscript
sect.relations = {
  "central_taihua": +20,      # 玩家与太华门关系
  "blood_palace": -50,        # 玩家与血煞宫关系
  ...
}
```

M3 仅初始化为 0，M5 主线推进改变。

---

## 4. 主线钩子目录（M3 核心交付）

> 这是 M3 必填的最重要内容。**列出 M5 可能触发的全部钩子 id**，M5 实装时挂剧情。M3 钩子可触发但无 effect。

### 4.1 钩子分类

```
[节奏钩子]   ─ 按月/年/境界进度触发
[成就钩子]   ─ 玩家达成里程碑触发
[选择钩子]   ─ 玩家关键决策点触发
[关系钩子]   ─ 与派系/NPC 关系变化触发
[随机钩子]   ─ 大世界随机事件触发
```

### 4.2 主线钩子 id 总表（M5 实装）

| 钩子 id | 类型 | 触发条件 | M5 用途 |
|---|---|---|---|
| `hook_first_month` | 节奏 | 游戏开始第 1 月 | 开场叙事 / 宗门介绍 |
| `hook_year_1_anniversary` | 节奏 | 第 12 月 | 第 1 年大事记 / 长老议事 |
| `hook_first_breakthrough` | 成就 | 玩家首次大境界突破 | 突破喜讯 / 宗门威望提升 |
| `hook_first_extraction` | 成就 | 玩家首次完成历练 | 历练心得 / 长老评价 |
| `hook_disciple_count_5` | 成就 | 弟子数达 5 | 宗门成形 |
| `hook_disciple_count_10` | 成就 | 弟子数达 10 | 宗门壮大 |
| `hook_realm_jindan` | 成就 | 玩家或弟子到金丹 | 金丹境界叙事 |
| `hook_realm_yuanying` | 成就 | 元婴 | 元婴境界叙事 |
| `hook_realm_huashen` | 成就 | 化神 | 化神境界叙事 |
| `hook_first_disciple_death` | 成就 | 首位弟子陨落 | 修仙残酷感叙事 |
| `hook_first_qi_deviation` | 成就 | 首次走火入魔 | 心魔系统引入（M5）|
| `hook_first_invasion` | 节奏 | 触发邻宗来袭 | 宗门保卫战引入（M4）|
| `hook_first_tournament` | 节奏 | 第 N 年仙宗大比 | 大比系统引入（M5）|
| `hook_relation_taihua_friendly` | 关系 | 与太华门关系≥+50 | 太华门主线分支开启 |
| `hook_relation_blood_palace_hostile` | 关系 | 血煞宫关系≤-30 | 魔道入侵分支 |
| `hook_choose_path_righteous` | 选择 | 玩家在某事件选"正道" | 正道结局分支 |
| `hook_choose_path_demonic` | 选择 | 玩家选"魔道" | 魔道结局分支 |
| `hook_ascension_threshold` | 成就 | 化神 9 层瓶颈 | 飞升前剧情 |
| `hook_ascension` | 成就 | 飞升成功 | 终局 CG |
| `hook_world_event_qi_tide` | 随机 | 灵气潮汐 | 全宗门修炼加速事件（M4）|
| `hook_world_event_demon_invasion` | 随机 | 妖族大举入侵 | 联合派系防御（M5）|

> 总计 ~20 个钩子。M5 启动时按本表挂剧情；M3 接口齐但 callback 都为空。

### 4.3 钩子命名约定

- 节奏：`hook_<时间锚点>` （如 `hook_year_1_anniversary`）
- 成就：`hook_<达成条件>` （如 `hook_first_breakthrough`）
- 选择：`hook_choose_<选项id>`
- 关系：`hook_relation_<faction>_<状态>`
- 随机：`hook_world_event_<事件>`

### 4.4 钩子激活范围

| 钩子类型 | 实际触发 | 是否多次触发 |
|---|---|---|
| 节奏（first_month / anniversary）| 月节拍检测 | 一次 / 周年重复 |
| 成就（first_*）| EventBus signal 监听 | **仅一次**（hook_triggered_flag 持久化）|
| 关系 | 关系阈值跨越 | 一次（每个方向）|
| 选择 | 选项事件 outcome | 每次玩家选 |
| 随机 | 月节拍 RNG | 多次（按概率）|

---

## 5. WorldEventTrigger 接口（M2 必落地，M3 钩子可空）

### 5.1 接口定义

```gdscript
# scripts/main_line/world_event_trigger.gd（autoload）
class_name WorldEventTrigger extends Node

# === 钩子注册 ===
# 子系统/剧情/M5 模块调用此接口挂监听
func register_hook(hook_id: String, callback: Callable, once: bool = false) -> void

# === 钩子触发 ===
# 各 service 检测到条件满足时调用
func trigger(hook_id: String, payload: Dictionary = {}) -> void

# === 内置触发器（M2 实装）===
func _ready():
    # 监听 TimeService.month_advanced → 触发 first_month / anniversary
    TimeService.connect("month_advanced", _check_rhythm_hooks)
    # 监听 GDD-04 突破 signal → 触发 first_breakthrough / realm_*
    EventBus.connect("breakthrough_succeeded", _check_achievement_hooks)
    # ... 其它内置触发器

# === 已触发查询（持久化）===
func is_triggered(hook_id: String) -> bool   # once=true 钩子用，存档
```

### 5.2 M3 行为：钩子触发但 callback 都为空

```
M3 期：WorldEventTrigger 内部正常检测条件 + trigger(hook_id)，但
       register_hook 未挂任何 callback → 实际啥也不发生。
       仅在 debug log 输出 "[WorldEventTrigger] hook X triggered (no listener)"

M5 期：主线模块按 §4.2 表逐个 register_hook 挂剧情 callback
```

> 这样 M3 接口完整 + 触发逻辑完整 → M5 加内容**零侵入**核心代码。

### 5.3 数据驱动配表（M5 启动时使用）

```
data/table/主线/钩子定义.xlsx     ← Sheet "MainLineHookDef"
   hook_id / 触发条件描述 / 类型 / once / 关联剧情事件 id（M5 填）
```

M3 仅落 §4.2 的钩子 id 清单，关联事件 id 为空。

### 5.4 存档

- `is_triggered(hook_id)` 状态进 `main_line` chunk（ADR-0004）
- M3 该 chunk 内容仅 `triggered_hooks: []`（空数组），不影响存档大小

---

## 6. 漫画 / CG 接口（M3 仅占位）

### 6.1 用途

主线关键节点（开场 / 突破 / 飞升 / 结局）会播放 CG 或漫画。M3 不实装内容，M5 由 GDD-07 美术配套生产。

### 6.2 接口占位

```gdscript
# scripts/ui/cg_player.gd（autoload，M2 stub / M5 实装）
class_name CGPlayer extends Node

func play_cg(cg_id: String) -> void   # M3 stub：仅 log "CG <id> would play"
func play_comic(comic_id: String, page_count: int) -> void   # M3 stub
```

### 6.3 配套数据（M5）

```
data/cg/<cg_id>/
  ├─ frames/      ← 序列帧
  ├─ audio.ogg    ← 配音 / 音乐
  └─ script.toml  ← 字幕 / 时间轴
```

M3 不创建任何 cg 内容。详见 `docs/m1-deferred-details.md` 的 GDD-07 / GDD-10。

---

## 7. M3 范围

| 内容 | M3 状态 |
|---|---|
| §2 大世界 5 region（schema）| ✅ schema 落盘，仅 `central_xiuzhen` 实质内容 |
| §3 派系 schema | ✅ schema 落盘，4-6 个 faction id 占位 |
| §4 主线钩子 ~20 个 id | ✅ 全表列出，关联事件 id 空 |
| §5 WorldEventTrigger autoload + 内置触发器 | ⏳ M2 必落地 |
| §5.2 钩子 callback | M5 才挂（M3 全空）|
| §6 CGPlayer autoload stub | ⏳ M2 必落地 |
| §6 CG 内容 | M5 |
| 主线剧情 / 派系文化 / 关键 NPC | M5（→ `docs/m1-deferred-details.md`）|

---

## 8. 风险与扩展点

### 8.1 风险

| 风险 | 缓解 |
|---|---|
| M5 启动发现 §4 钩子目录漏了某场景 | M5 按"加新钩子走 ADR"流程加，不破坏既有 |
| 钩子触发频繁污染存档 | once 钩子用 hook_triggered_flag，每个仅记 1 bit |
| M3 期 WorldEventTrigger log 噪音 | log 仅 debug 级，不进 release 日志 |
| M5 主线剧情与既有玩法冲突 | 剧情仅通过 EventTemplate 配置，complies GDD-03 §2 |

### 8.2 扩展点（详细 → `docs/m1-deferred-details.md`）

- 大世界详细设定 → M5
- 派系详细描述 → M5
- 主线剧情完整脚本 → M5
- 漫画 / CG 美术规格 → M5

---

## verdict

drafting · M3 必交付：§4 钩子目录 + §5 接口 + §6 CGPlayer stub。其余 M5 启动时展开。
