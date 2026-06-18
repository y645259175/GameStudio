---
gdd_id: 05
gdd_title: 宗门经营
status: drafting
last_review: 2026-06-03
sections_complete: [设计精神, 宗门拓扑极简版, 建筑系统5建筑, 建设链, 炼丹, 炼器M4占位, 培养子系统, 弟子招收, 关键事件接口, 接触面, 风险扩展, M3实装]
sections_pending: []
upstream_adr: [0006-sect-data-structure, 0005-buff-system, 0003-character-state-machine]
upstream_gdd: [gdd-01, gdd-02, gdd-03, gdd-04]
verdict: drafting
---

# GDD-05 · 宗门经营

> 承接 GDD-01 §6.11 宗门数据结构（Sect 实体 + IBuffable）+ §6.12 角色契约 vs 玩法分离。本章定义"玩家在宗门内的所有玩法"——建筑布局、生产、培养、招收、宗门事件接口。
>
> 上游：GDD-01 §6.11 / §6.12，GDD-02（角色契约），GDD-03（历练 / 战斗）, GDD-04（成长系统）, ADR-0006

---

## 1. 设计精神

### 1.1 哲学定位

宗门经营是 M3 玩家循环的另一半——历练（GDD-03）让玩家"出门挣资源"，宗门让玩家"在家把资源转化为长期实力"。两者形成"出去 → 回来 → 再出去"的张力闭环（GDD-01 §2 三柱循环）。

### 1.2 与 GDD-04 成长系统的边界（v3.1 哲学）

> 用户定调（2026-06-03）：建筑作 modifier 接入 GDD-04 成长公式，**宗门不持有"怎么成长"的玩法逻辑**。

| 责任 | 归属 |
|---|---|
| "弟子怎么涨经验 / 怎么突破" | GDD-04 成长系统 |
| "建筑提供哪些 modifier" | GDD-05 本章 |
| "建筑数据结构 / 等级 / 升级链" | GDD-05 本章 |
| "宗门资源怎么消耗 / 月俸" | GDD-06 经济与数值 |
| "宗门 buff 数据结构" | GDD-01 §6.10 / GDD-02 buff schema（仅契约）|

**形象比喻**：宗门 = 修仙者的"道场基础设施"，建筑像 IDE 插件——给玩家提供加速 / 便利 / 自动化能力，但**修炼这件事本身的规则**在 GDD-04。

### 1.3 M3 玩法循环

```
回宗
  ├─ 看建筑当前等级 + 资源库存
  ├─ 调度弟子（分配到建筑 / 进入闭关 / 派遣历练）
  ├─ 升级建筑 / 建造新建筑（消耗资源 + 月数）
  ├─ 启动炼丹（消耗药材 → 等月节拍 → 出货）
  ├─ 招收新弟子（自动来投 / 主动开门）
  ├─ 月节拍推进
  │    ├─ 闭关弟子涨经验（modifier 由建筑提供）
  │    ├─ 炼丹进度推进 + 丹房月产药材
  │    ├─ 建造进度推进
  │    └─ 资源消耗（月俸 / 灵石维护）
  └─ 出门历练（GDD-03）
```

---

## 2. 宗门拓扑（用户定调 Q1=A 预设槽位）

### 2.1 模型选择理由

**预设槽位**（鬼谷八荒式）：固定 N 个建筑位，每位预定义可建什么。理由：

- M3 实现复杂度最低（不需要网格碰撞 / 自由布局算法）
- 玩家心智清晰（"演武区有个槽位空着"）
- 配表可控（设计师精控每个槽位的语义）
- 后期可演化为"功能区"或"网格"（M5+ 不挡路）

### 2.2 M3 槽位规模（极简版 · 用户定调 2026-06-05）

> 用户定调：M3 初版建筑**极简**——只保留 5 个真正有不可替代价值的建筑，但**保持可扩展性**（预留空槽 + allowed_building_ids 机制，M4+ 加新建筑不改结构）。

```
M3 默认 8 个建筑位，分 3 个功能区：

内务区（3 槽）│ 主殿（预建）/ 弟子居所（预建）/ [扩展空槽 ×1]
修炼区（3 槽）│ 修炼塔 / 藏书阁 / [扩展空槽 ×1]
丹器区（2 槽）│ 丹房（含药圃功能）/ [扩展空槽 ×1]
```

**5 个 M3 实建建筑** + **3 个扩展空槽**（M4+ 解锁，用于聚灵阵 / 演武场 / 炼器房 / 厨房等）。

| 决策 | 取值 | 理由 |
|---|---|---|
| 建筑数量 | 5（方案 A 极简）| 每个建筑都有不可替代价值；避免 M3 选择疲劳 |
| 扩展空槽 | 3 | 保留"中后期有新建筑可造"的成长感 + M4+ 不改布局结构 |
| 建筑等级 | **3 级**（lv1 基础 / lv2 进阶 / lv3 满级）| 5 级数值差异玩家难感知；3 级心智清晰 |
| 建造时长 | **1-2 月**（M3 上限 2 月）| 30-60 分钟单局，1-2 次月节拍可感知 |

**功能区**仅是 UI 分组，不强制玩法约束（设计师将来可在槽位加 `requires_zone` 约束）。

> **可扩展性保障**：空槽的 `allowed_building_ids` 在 M4+ 填入新建筑 id 即可解锁，不需要改 SectLayoutTemplate 结构；也可加 `default_sect_v2` 布局（更多槽位）。

### 2.3 数据结构

```gdscript
# scripts/sect/sect_layout_template.gd
class_name SectLayoutTemplate
extends Resource

@export var layout_id: String                  # M3 = "default_sect_v1"
@export var slots: Array[BuildingSlotDef]      # M3 = 8 个（5 实建 + 3 扩展空槽）

# scripts/sect/building_slot_def.gd
class_name BuildingSlotDef
extends Resource

@export var slot_id: String                    # "training_zone_1" / "alchemy_zone_1" ...
@export var zone: String                       # "training" / "alchemy" / "combat" / "internal"
@export var allowed_building_ids: Array[String]    # 允许建造的建筑模板 id 集合
@export var pre_built_building_id: String      # M3 默认已建好的建筑（如主殿）；空 = 空槽
@export var unlock_condition: String           # 解锁条件 expr（默认空 = 一开始就可建）
```

> M3 仅用 `default_sect_v1` 一套布局；M5 可加多套（如"门派传承不同布局"）。

### 2.4 `default_sect_v1` 槽位明细表（M3 完整定义）

8 个槽位的配表内容。`pre_built` 列空 = 开局空槽；`unlock` 空 = 开局即可建。

| slot_id | zone | allowed_building_ids | pre_built | unlock_condition | M3 用途 |
|---|---|---|---|---|---|
| `internal_1` | internal | `main_hall` | `main_hall` | — | 主殿（固定预建，不可换）|
| `internal_2` | internal | `disciple_dorm` | `disciple_dorm` | — | 弟子居所（固定预建）|
| `internal_3` | internal | `kitchen`（M4）| — | `building_lv('main_hall') >= 2` | 扩展空槽 → M4 厨房 |
| `training_1` | training | `cultivation_tower` | — | — | 修炼塔（开局可建）|
| `training_2` | training | `library` | — | — | 藏书阁（开局可建）|
| `training_3` | training | `qi_array`（M4）/ `training_field`（M4）| — | `building_lv('main_hall') >= 2` | 扩展空槽 → M4 聚灵阵/演武场 |
| `alchemy_1` | alchemy | `alchemy_room` | — | — | 丹房（开局可建）|
| `alchemy_2` | alchemy | `forge_room`（M4）| — | `building_lv('main_hall') >= 3` | 扩展空槽 → M4 炼器房 |

**设计说明**：

- **固定预建槽**（internal_1/2）的 `allowed_building_ids` 只含 1 个，玩家不可拆换——保证宗门基本盘
- **开局可建槽**（training_1/2 + alchemy_1）unlock 为空，开局直接可建 3 大核心建筑
- **扩展空槽**（internal_3 / training_3 / alchemy_2）当前 allowed 列里写的是 M4 建筑 id，但 unlock 条件挡住——M3 玩家看得到槽位但建不了（灰色锁定 + "需主殿 LvN" 提示），形成成长预期
- 扩展性：M4 加新建筑只需把 building_id 填入对应槽的 `allowed_building_ids`，调 unlock 条件即可

### 2.5 宗门主界面 UI 布局

M3 宗门主界面采用**三区横向分栏**，每区纵向排槽位卡片：

```
┌──────────────────────────────────────────────────────────────┐
│  门派名「青云宗」   灵石 1240  药材 36  弟子 6/10   月份 第14月 │ ← 顶栏：资源 + 时间
├──────────────┬──────────────┬──────────────┬──────────────────┤
│   内务区      │    修炼区     │    丹器区      │   弟子列表（右侧）  │
│ ┌──────────┐ │ ┌──────────┐ │ ┌──────────┐ │ ┌──────────────┐ │
│ │主殿  Lv1 │ │ │修炼塔 Lv2│ │ │丹房  Lv1 │ │ │李四 炼气3 闭关 │ │
│ │[收徒]    │ │ │2/3 闭关中│ │ │炼丹中 1月│ │ │王五 炼气1 闲置 │ │
│ └──────────┘ │ └──────────┘ │ └──────────┘ │ │赵六 筑基1 历练 │ │
│ ┌──────────┐ │ ┌──────────┐ │ ┌──────────┐ │ │...           │ │
│ │居所  Lv1 │ │ │藏书阁 Lv1│ │ │🔒炼器房  │ │ │              │ │
│ │6/6 已满  │ │ │1/3 研读  │ │ │需主殿Lv3 │ │ │[拖弟子到建筑] │ │
│ └──────────┘ │ └──────────┘ │ └──────────┘ │ └──────────────┘ │
│ ┌──────────┐ │ ┌──────────┐ │              │                  │
│ │🔒空槽    │ │ │🔒空槽    │ │              │  [出门历练] 按钮  │
│ │需主殿Lv2 │ │ │需主殿Lv2 │ │              │                  │
│ └──────────┘ │ └──────────┘ │              │                  │
└──────────────┴──────────────┴──────────────┴──────────────────┘
```

**交互流**：

```
点建筑卡片 → 弹「建筑详情面板」
  ├─ 已建：显示当前等级 modifier / 容量 / 已分配弟子 / [升级] / [+分配弟子]（修炼塔/藏书阁）/ [炼丹] (丹房)
  ├─ 空槽可建：显示可建建筑列表 + 各自 lv1 成本 → [建造]
  └─ 空槽锁定：灰色 + 解锁条件提示（"需主殿 Lv2"）

点弟子（右侧列表）→ 弹「弟子详情」→ 可拖到建筑卡片 / 派遣历练 / 闭关
```

### 2.6 槽位 UI 状态（5 态）

每个槽位卡片在 UI 上有 5 种视觉状态：

| 状态 | 触发 | 视觉 | 可操作 |
|---|---|---|---|
| **空槽-可建** | 槽 unlock 满足 + 无建筑 | 虚线框 + "可建造" | 点击选建筑建造 |
| **空槽-锁定** | 槽 unlock 不满足 | 灰色 🔒 + 条件提示 | 仅看条件，不可建 |
| **建造中** | BuildingInstance.current_level=0, progress<target | 进度条 + "建造中 N 月" | 不可操作（M3 不可取消）|
| **已建-可升级** | current_level < max_level + 升级 unlock 满足 | 正常 + [升级] 角标 | 升级 / 使用 |
| **已建-满级** | current_level == max_level | 正常 + "满级" 标 | 仅使用 |

> 升级中（已建但正在升下一级）复用"建造中"进度条，但底层 modifier 仍按当前 level 生效（§4.2）。

### 2.7 数据驱动落地

```
data/table/宗门/
├─ 宗门布局.xlsx          ← Sheet "SectLayoutTemplate"（1 行 default_sect_v1）/ "BuildingSlotDef"（8 行，见 §2.4）
└─ proto/sect_layout.schema.toml
```

---

## 3. 建筑系统

### 3.1 数据结构

```gdscript
# scripts/sect/building_template.gd
class_name BuildingTemplate
extends Resource

@export var building_id: String                # "cultivation_tower" / "alchemy_room" / ...
@export var display_name_tid: String
@export var description_tid: String
@export var category: String                   # "training" / "production" / "internal"
@export var max_level: int = 3                 # M3 默认 3 级（lv1 基础 / lv2 进阶 / lv3 满级），可配
@export var is_predefined: bool = false        # true = 开局已建好（主殿 / 弟子居所），不可拆
@export var levels: Array[BuildingLevel]       # 等级数据 1..max_level


# scripts/sect/building_level.gd
class_name BuildingLevel
extends Resource

@export var level: int
@export var build_cost: ResourceCost           # 建造 / 升级到此级的资源消耗
@export var build_months: int                  # 建造 / 升级耗时
@export var capacity: int                      # 容量（如修炼塔可同时容纳几个弟子闭关）
@export var modifiers: Dictionary              # 此级提供的 modifier（key=modifier_id, value=数值）
@export var unlock_condition: String           # 进入此级的额外条件 expr
```

```gdscript
# scripts/sect/building_instance.gd（运行态）
class_name BuildingInstance
extends RefCounted

var slot_id: String                            # 装在哪个槽
var building_id: String                        # BuildingTemplate id
var current_level: int                         # 当前等级（0 = 未建 / 建造中）
var construction_progress_months: int          # 已积累建造月数（建造中时用）
var construction_target_level: int             # 建造完成后的等级（首次建造 = 1，升级 = current+1）
var assigned_character_ids: Array[String]      # 当前在该建筑的弟子 id（修炼塔 / 藏书阁用）
```

### 3.2 M3 建筑清单（5 个 · 极简版）

| building_id | 类别 | 一句话定位 | 交互类型 | M3 状态 |
|---|---|---|---|---|
| `main_hall` | internal | 宗门中枢：招收入口 + 槽位解锁器 + 主线 NPC 容器 | 行为入口 | ✅ 预建 |
| `disciple_dorm` | internal | 弟子居所：宗门人口上限硬约束 | 被动 | ✅ 预建 |
| `cultivation_tower` | training | 修炼塔：核心成长引擎，闭关加速 | 弟子分配 | ✅ |
| `library` | training | 藏书阁：资质提升 + M5 功法学习入口 | 弟子分配 | ✅ |
| `alchemy_room` | production | 丹房（含药圃）：炼丹 + 月产药材自给 | 任务式 + 被动 | ✅ |

> **被砍/推迟的建筑**（M4+ 通过扩展空槽加回）：聚灵阵 `qi_array`（M4，全宗门被动加速）/ 演武场 `training_field`（M4，战训）/ 炼器房 `forge_room`（M4，装备系统到位后）/ 厨房 `kitchen`（其月俸折扣 M3 直接并入数值，不单独建）/ 静室 / 悟道厅 / 比武台等（M5）。

### 3.2.1 主殿 `main_hall`

| 项 | 内容 |
|---|---|
| **设定** | 宗门核心大殿，门主居所与威望象征。修仙宗门的"中枢"——所有对外决策（招收 / 主线接洽）在此发生。 |
| **开局状态** | `is_predefined = true`，开局已建好 lv1，**不可拆除** |
| **核心功能** | ① 招收入口（"开门收徒"，§8.3）② **槽位解锁器**（main_hall 等级决定可用扩展空槽数）③ 主线 NPC 容器（M5）④ 宗门威望基准 |
| **modifier** | `sect_reputation_base`（影响自动来投概率，§8.2）；`recruit_quality_cap`（招收资质上限）|
| **使用方式** | 点击主殿 → 弹操作菜单：开门收徒 / 查看宗门概况（人口 / 资源 / 威望）|

**升级数据（3 级）**：

| 等级 | 解锁内容 | recruit_quality_cap | 升级条件 | 建造时长 |
|---|---|---|---|---|
| lv1（预建）| 基础 3 槽（修炼塔 / 藏书阁 / 丹房）可建 | 中 | — | — |
| lv2 | +1 扩展空槽可用 + 招收质量上限↑ | 中上 | `disciple_count() >= 3` | 2 月 |
| lv3 | +2 扩展空槽可用 + 招收质量上限↑ | 高 | `realm_max() >= 2`（有人筑基）| 2 月 |

> 主殿是"宗门成长的节奏闸门"——玩家想造更多建筑必须先升主殿，主殿升级又需要弟子数 / 境界达标，形成正循环。

### 3.2.2 弟子居所 `disciple_dorm`

| 项 | 内容 |
|---|---|
| **设定** | 弟子起居之所。宗门能容纳多少弟子的硬上限。 |
| **开局状态** | `is_predefined = true`，开局已建好 lv1 |
| **核心功能** | 提供 `housing_capacity`——宗门弟子总数不能超过所有居所容量之和（§8.5）|
| **modifier** | `housing_capacity: +N` |
| **使用方式** | 被动，无交互。玩家在宗门概况看"当前 6/10 弟子"。容量满时招收按钮置灰。 |

**升级数据（3 级）**：

| 等级 | housing_capacity | 升级条件 | 建造时长 |
|---|---|---|---|
| lv1（预建）| 6 人 | — | — |
| lv2 | 10 人 | 当前人数 ≥ 5（住满才值得扩）| 1 月 |
| lv3 | 15 人 | `building_lv('main_hall') >= 2` | 2 月 |

### 3.2.3 修炼塔 `cultivation_tower`

| 项 | 内容 |
|---|---|
| **设定** | 聚灵闭关之地，宗门最核心的成长建筑。弟子在此打坐修炼，加速突破。 |
| **开局状态** | 开局空槽，**玩家通常第一个建造的建筑** |
| **核心功能** | ① 闭关加速 `cultivation_speed_bonus`（接入 GDD-04 闭关公式）② `capacity` 限制同时闭关人数 |
| **modifier** | `cultivation_speed_bonus: +X%`（通过 BuffService 挂到分配的弟子，§3.3）|
| **使用方式** | 玩家把弟子分配进修炼塔 → 弟子转 `cultivating` 状态 → 挂 buff → GDD-04 闭关公式自动读取加速 → 月节拍涨经验 |

**升级数据（3 级）**：

| 等级 | cultivation_speed_bonus | capacity（同时闭关）| 升级条件 | 建造时长 |
|---|---|---|---|---|
| lv1 | +20% | 2 人 | 开局可建 | 1 月 |
| lv2 | +35% | 3 人 | `resources_at_least('spirit_stone', N)` | 2 月 |
| lv3 | +50% | 5 人 | `building_lv('main_hall') >= 2` | 2 月 |

> 数值占位，具体 GDD-06 平衡。设计意图：修炼塔是玩家"灵石投资 → 全员修炼提速"的主回路。

### 3.2.4 藏书阁 `library`

| 项 | 内容 |
|---|---|
| **设定** | 功法典籍与悟道之所。弟子在此研读，提升悟性资质。M5 是功法学习的入口。 |
| **开局状态** | 开局空槽，需 `main_hall lv1` 即可建（基础 3 槽之一）|
| **核心功能** | ① 资质提升 `insight_per_month`（驻留弟子每月加悟性，接入 GDD-04 §5.5）② `capacity` 限驻留人数 |
| **modifier** | `insight_per_month: +N`（月节拍给驻留弟子加悟性属性）|
| **使用方式** | 玩家把弟子分配进藏书阁 → 月节拍 `CharacterService.get_attribute('insight') += N` → 提升突破概率（悟性是突破公式分项，GDD-04 §4.2）|

**升级数据（3 级）**：

| 等级 | insight_per_month | capacity | 升级条件 | 建造时长 |
|---|---|---|---|---|
| lv1 | +1 / 月 | 3 人 | 开局可建 | 1 月 |
| lv2 | +2 / 月 | 6 人 | `resources_at_least('spirit_stone', N)` | 2 月 |
| lv3 | +3 / 月 | 10 人 | `building_lv('main_hall') >= 2` | 2 月 |

> **修炼塔 vs 藏书阁的策略分流**：修炼塔加"闭关速度"（短期涨经验快），藏书阁加"悟性"（长期提突破率）。玩家按弟子定位选——主力冲境界进修炼塔，潜力弟子养悟性进藏书阁。
>
> **M5 扩展**：藏书阁 lv2+ 解锁"功法学习"——驻留弟子可研习宗门藏书的功法（功法系统 M5 实装，schema 占位 `learnable_method_ids`）。

### 3.2.5 丹房 `alchemy_room`（含药圃功能）

| 项 | 内容 |
|---|---|
| **设定** | 炼丹之所，兼药材种植（M3 把"药圃"功能并入丹房，减少建筑数）。宗门消耗品的自给中心。 |
| **开局状态** | 开局空槽，需 `main_hall lv1` 即可建（基础 3 槽之一）|
| **核心功能** | ① 解锁炼丹（5 配方，§5）② 月产药材自给（喂炼丹材料）③ `alchemy_concurrent` 并发炼丹任务数 ④ `alchemy_efficiency_bonus` 炼丹成功率/速度加成 |
| **modifier** | `herb_yield_per_month`（月产药材）/ `alchemy_efficiency_bonus` / `alchemy_concurrent` |
| **使用方式** | ① 任务式：玩家投配方 + 指派弟子 → 等月节拍 → 出货（§5）② 被动：月节拍自动产药材 |

**升级数据（3 级）**：

| 等级 | 并发炼丹 | 月产药材 | alchemy_efficiency | 升级条件 | 建造时长 |
|---|---|---|---|---|---|
| lv1 | 1 个任务 | 2 株 | 基础 | 开局可建 | 1 月 |
| lv2 | 1 个任务 | 4 株 | +20% | `resources_at_least('spirit_stone', N)` | 2 月 |
| lv3 | 2 个任务 | 6 株 | +40% | 某弟子炼丹值 ≥ N（`max_disciple_skill('alchemy') >= N`）| 2 月 |

> 合并药圃的理由：M3 极简下"药圃"单独成建筑价值太薄（只月产药材）。并入丹房后，丹房成为"自给自足的炼丹链"——种药 + 炼丹一体，玩家心智更完整。M4 真要拆分（大规模种植）再独立 `herb_garden`。

### 3.3 modifier 注入 GDD-04 的机制（关键）

按 GDD-01 §6.10 / §6.12 哲学，建筑通过 BuffService 写 SECT 级 buff，**不直接改 character 字段**：

```gdscript
# 修炼塔 lv3 启动 / 玩家把弟子拖入修炼塔
BuildingService._on_disciple_assigned(building, character):
    BuffService.apply(character, BuffData.new({
        buff_id = "cultivation/sect_tower_aid",
        source = building.slot_id,        # 弟子离开建筑时按 source 移除
        duration = INFINITE,
        modifiers = building.template.levels[current_level].modifiers
    }))

# 弟子离开时
BuildingService._on_disciple_unassigned(building, character):
    BuffService.remove_by_source(character, building.slot_id)
```

GDD-04 的闭关公式 `monthly_gain × cultivation_multiplier(character)` 自动读到这些 buff——**GDD-05 不需要知道公式怎么算**，只负责挂 buff。

### 3.4 SECT 级 buff（fan-out 责任在消费方 · M4 扩展范式预留）

> M3 的 5 建筑都是 character 级 buff（分配弟子时挂在弟子身上）。**SECT 级 buff 在 M3 不实装**，但本节预留范式——M4 加聚灵阵 `qi_array` 时按此实现。

未来聚灵阵的 buff 挂在 **Sect** 实体上（GDD-01 §6.11 IBuffable）：

```
qi_array lv2 启动（M4）
  └─ BuffService.apply(sect, "cultivation/sect_qi_field", { qi_density_bonus: +20% })
      └─ ProductionService 监听 sect.buff_applied signal
          └─ 找到所有 sect.member_ids 中处于 cultivating 的弟子
              └─ 给每个弟子挂相应的 character 级 buff（fan-out 实现）
```

**纪律**：BuffService 不知道 fan-out；fan-out 由 ProductionService（生产领域）实现。这与 GDD-01 §6.10 一致。

### 3.5 升级链与前置依赖

```
建筑 A 升级到 lv N 的解锁条件由 BuildingLevel.unlock_condition 表达：

M3 实例（见 §3.2.1-3.2.5 各建筑升级表）：
  cultivation_tower lv3  unlock = "building_lv('main_hall') >= 2"
  library           lv3  unlock = "building_lv('main_hall') >= 2"
  alchemy_room      lv3  unlock = "max_disciple_skill('alchemy') >= N"
  main_hall         lv2  unlock = "disciple_count() >= 3"
  main_hall         lv3  unlock = "realm_max() >= 2"
```

**M3 解锁链全景**（节奏闸门）：

```
开局：主殿 lv1（预建）+ 弟子居所 lv1（预建）
  ├─ 可立即建：修炼塔 / 藏书阁 / 丹房（基础 3 槽）
  └─ 升主殿 lv2（需弟子≥3）→ 解锁 1 个扩展空槽 + 各建筑可升 lv3
      └─ 升主殿 lv3（需有人筑基）→ 解锁 2 个扩展空槽（M4 内容预留）
```

`unlock_condition` 用 ConditionEvaluator（GDD-03 §2.7 复用）。M3 谓词清单：

- `building_lv(id)` 某建筑当前等级
- `realm_max()` 当前宗门所有弟子境界最大值
- `member_count_min(realm_id, n)` 某境界以上人数
- `resources_at_least(type, amount)` 资源量
- `disciple_count() >= n` 弟子总人数
- `max_disciple_skill(skill_id) >= n` 某项资质（如 alchemy 炼丹值）的全宗门最高值

### 3.6 建筑实例状态机

每个 `BuildingInstance` 的生命周期状态（运行态 + 存档）：

```
        [empty]                    空槽（无 BuildingInstance，或 current_level=0 且未建造）
           │ 玩家发起建造 + 扣资源
           ▼
     [constructing]               建造中（current_level=0, target=1, progress 累积）
           │ progress >= build_months
           ▼
        [built]  ◄──────┐         已建（current_level≥1，modifier 生效）
           │            │
           │ 玩家发起升级 │ progress >= build_months
           ▼            │
      [upgrading] ──────┘         升级中（current_level=N, target=N+1, 旧级 modifier 仍生效）
           │ current_level == max_level
           ▼
       [maxed]                    满级（不再可升）
```

**状态字段映射**（BuildingInstance，§3.1）：

| 状态 | current_level | target_level | progress_months | modifier 是否生效 |
|---|---|---|---|---|
| empty | 0 | 0 | 0 | 否 |
| constructing | 0 | 1 | 0..build_months | 否 |
| built | ≥1 | == current | 0 | **是**（当前级）|
| upgrading | N | N+1 | 0..build_months | **是**（仍按 N 级）|
| maxed | max_level | == current | 0 | 是（满级）|

**纪律**：

- 升级中 modifier **按当前级生效不停摆**（§4.2）——避免"升级期间弟子白闭关"
- 状态转移只由 ProductionService（建造/升级）和 BuildingService 驱动；UI 只读状态渲染（§2.6）
- 存档粒度：BuildingInstance 全字段序列化，含 progress_months（中途存档恢复继续建造）

---

## 4. 建设链

### 4.1 建造流程

```
玩家在 UI 选空槽 + 建筑 A
  ├─ 校验 BuildingSlotDef.allowed_building_ids 包含 A
  ├─ 校验 unlock_condition
  ├─ 校验 InventoryService.has(level_1.build_cost)
  ├─ InventoryService.consume(level_1.build_cost)
  ├─ 创建 BuildingInstance（current_level=0, target=1, progress=0）
  └─ 月节拍推进：progress_months += 1
      └─ if progress_months >= build_months:
            current_level = target_level
            progress = 0
            broadcast signal building_level_up(slot, building, lv)
            激活该级 modifiers（§3.3）
```

### 4.2 升级流程

同建造，但：
- 校验 current_level < max_level
- 消耗 levels[current+1].build_cost
- target_level = current + 1
- 升级期间**保持当前 level modifier 生效**（不停摆）

### 4.3 建造取消（M4+）

M3 不支持中途取消（玩家必须等完）。M4+ 加 `cancel_construction()` 退还 50% 资源。

### 4.4 建造 / 维护资源

| 资源类型 | 来源 | 消耗位置 |
|---|---|---|
| 灵石 | 历练战利品 / 弟子月俸 | 建造 / 升级 / 炼丹消耗 |
| 木材 / 石料 | 历练拾取 / 主动派遣 | 建造 |
| 药材 | 丹房月产 / 历练 | 炼丹 |
| 矿石 | 历练 / 派遣 | 炼器（M4 炼器房）|

> 具体数值 GDD-06 平衡。M3 默认主殿不消耗（已建），其它建筑 lv1 100-500 灵石 / 1-2 月。

### 4.5 建筑总表（5 建筑 × 3 级 · M3 占位数值）

> 数值为 M3 占位参考，最终标定在 GDD-06 平衡章。`build_cost` 单位灵石（部分含木材/石料）。预建建筑 lv1 不计建造成本。

#### 主殿 `main_hall`

| lv | build_cost | build_months | 解锁内容 | unlock |
|---|---|---|---|---|
| 1 | 预建（0）| — | 基础 3 槽 + 招收质量=中 | — |
| 2 | 800 灵石 + 20 石料 | 2 | +1 扩展空槽 + 招收质量=中上 + 各建筑可升 lv3 | `disciple_count()>=3` |
| 3 | 2500 灵石 + 50 石料 | 2 | +2 扩展空槽 + 招收质量=高 | `realm_max()>=2` |

#### 弟子居所 `disciple_dorm`

| lv | build_cost | build_months | housing_capacity | unlock |
|---|---|---|---|---|
| 1 | 预建（0）| — | 6 | — |
| 2 | 300 灵石 + 15 木料 | 1 | 10 | 当前人数≥5 |
| 3 | 1000 灵石 + 30 木料 | 2 | 15 | `building_lv('main_hall')>=2` |

#### 修炼塔 `cultivation_tower`

| lv | build_cost | build_months | cultivation_speed_bonus | capacity | unlock |
|---|---|---|---|---|---|
| 1 | 200 灵石 | 1 | +20% | 2 | 开局可建 |
| 2 | 600 灵石 | 2 | +35% | 3 | `resources_at_least('spirit_stone',600)` |
| 3 | 1800 灵石 | 2 | +50% | 5 | `building_lv('main_hall')>=2` |

#### 藏书阁 `library`

| lv | build_cost | build_months | insight_per_month | capacity | unlock |
|---|---|---|---|---|---|
| 1 | 200 灵石 | 1 | +1 | 3 | 开局可建 |
| 2 | 600 灵石 | 2 | +2 | 6 | `resources_at_least('spirit_stone',600)` |
| 3 | 1800 灵石 | 2 | +3 | 10 | `building_lv('main_hall')>=2` |

#### 丹房 `alchemy_room`（含药圃）

| lv | build_cost | build_months | 并发炼丹 | herb_yield/月 | alchemy_efficiency | unlock |
|---|---|---|---|---|---|---|
| 1 | 250 灵石 | 1 | 1 | 2 | 基础 | 开局可建 |
| 2 | 700 灵石 | 2 | 1 | 4 | +20% | `resources_at_least('spirit_stone',700)` |
| 3 | 2000 灵石 | 2 | 2 | 6 | +40% | `max_disciple_skill('alchemy')>=N` |

> **总投资概览**（全 5 建筑升满 lv3 总成本）：约 14000+ 灵石 + 木石材料。对应 M3 玩家需多次历练积累——形成"历练挣资源 → 升建筑 → 修炼更快 → 打更深历练"的核心循环驱动力。

---

## 5. 炼丹子系统（用户定调 Q2=D · M3 极简 + schema 留扩展位）

### 5.1 M3 极简形态（方案 A）

> 玩家点 → 等月节拍 → 出货。无玩家参与过程。

```
玩家在 alchemy_room UI 选配方 + 投药材
  ├─ 校验 RecipeDef.required_materials 充足
  ├─ 校验 RecipeDef.required_alchemy_skill 弟子炼丹值 ≥ N
  ├─ 校验 alchemy_room 等级 >= RecipeDef.required_room_level
  ├─ InventoryService.consume(materials)
  ├─ 创建 AlchemyTask（recipe_id, assigned_disciple, started_month, expected_months）
  └─ 月节拍推进
      └─ if month >= started + duration:
            滚 RNG 决定 success / fail
            if success: InventoryService.add(recipe.output)
            if fail:    给 50% 部分残料退回（保底）
            broadcast signal alchemy_task_completed(task, result)
```

### 5.2 数据结构（M3）

```gdscript
# scripts/sect/recipe_def.gd
class_name AlchemyRecipeDef
extends Resource

@export var recipe_id: String
@export var display_name_tid: String
@export var required_materials: Dictionary     # {"herb_a": 3, "herb_b": 1}
@export var required_alchemy_skill: int        # 弟子"炼丹"属性最低
@export var required_room_level: int           # alchemy_room 等级最低
@export var duration_months: int               # 炼制时长（M3 默认 1-3 月）
@export var success_rate: float                # 0.0-1.0（M3 默认 0.6-0.95）
@export var output: Dictionary                 # 成功产物 {"pill_a": 1}
@export var fail_recovery_rate: float = 0.5    # 失败退回比例

# 扩展位（M3 schema 占位 / M4+ 启用）
@export var firing_curve: Array[float] = []    # 火候曲线（B/C 方案用，M3 留空）
@export var process_steps: Array[String] = []  # 工序步骤（C 方案小游戏用）

# scripts/sect/alchemy_task.gd（运行态）
class_name AlchemyTask
extends Resource

@export var task_id: String
@export var recipe_id: String
@export var assigned_disciple_id: String
@export var started_at_month: int
@export var expected_completion_month: int
@export var status: String                     # "in_progress" / "completed" / "failed"
@export var result: Dictionary                 # status=completed 时的实际产物
```

### 5.3 M3 配方清单（5 个 · 含数值占位）

| recipe_id | 输出 | 材料 | 炼丹值≥ | 房≥ | 时长 | 成功率 | 用途 |
|---|---|---|---|---|---|---|---|
| `recipe_qi_pill` | 聚气丹 ×3 | 灵草×2 | 10 | lv1 | 1 月 | 0.90 | 挂 `cultivation/qi_acceleration` 闭关 +20% buff |
| `recipe_healing_pill` | 疗伤丹 ×2 | 灵草×1 兽血×1 | 20 | lv1 | 1 月 | 0.80 | 治疗"重伤"buff（GDD-04 §7.4）|
| `recipe_breakthrough_pill` | 突破丹 ×1 | 灵草×3 妖丹×1 | 40 | lv2 | 2 月 | 0.60 | 突破成功率 +10%（GDD-04 §4.2 增益）|
| `recipe_root_boost_fire` | 火灵根丹 ×1 | 火精×2 妖丹×2 | 60 | lv3 | 2 月 | 0.45 | 灵根 fire base +1（GDD-04 §5.2 永久强化）|
| `recipe_lifespan_pill` | 寿元丹 ×1 | 千年灵芝×1 妖丹×3 | 80 | lv3 | 3 月 | 0.30 | 寿元 +5 年（M4 启用，M3 schema only）|

> 难度梯度：聚气丹（易，新手即可炼）→ 寿元丹（极难，需丹房 lv3 + 高炼丹值弟子）。成功率与所需炼丹值由 GDD-06 平衡章最终标定。失败按 `fail_recovery_rate=0.5` 退回半数材料。

### 5.4 schema 留扩展位（用户定调 Q2=D）

| 扩展位 | 何时启用 | 用途 |
|---|---|---|
| `firing_curve` | M4 方案 B（材料/火候组合）| 玩家选材料 → 系统按曲线模拟 → 影响成功率 |
| `process_steps` | M5 方案 C（小游戏）| 玩家逐步操作影响最终成品品质 |
| `quality_tiers` | M5 | 同配方不同品质（普通 / 上品 / 极品）|

M3 schema 字段就位，运行时**忽略**这些字段。

### 5.5 炼丹 UI 流程

```
点丹房卡片 → 弹「丹房面板」
┌────────────────────────────────────────┐
│  丹房 Lv1   药材库存：灵草 12 / 兽血 3    │
│  炼丹位 1/1（lv3 解锁第 2 位）            │
├────────────────────────────────────────┤
│  [配方列表]                              │
│  ✅ 聚气丹  灵草×2  1月  90%  [炼制]      │ ← 材料够+条件满足，可炼
│  ✅ 疗伤丹  灵草×1 兽血×1  1月 80% [炼制] │
│  🔒 突破丹  需丹房 Lv2                    │ ← 房等级不足，灰
│  🔒 火灵根丹 需弟子炼丹值≥60              │ ← 无弟子达标，灰
├────────────────────────────────────────┤
│  [进行中任务]                            │
│  聚气丹  指派：王五  剩余 1 月  ▓▓▓░ 75%  │ ← 任务进度
└────────────────────────────────────────┘

点 [炼制] → 选配方 → 指派弟子（炼丹值最高者默认）→ 确认
  ├─ 扣材料
  ├─ 占用 1 个炼丹位（lv1/lv2 = 1 位，lv3 = 2 位）
  └─ 月节拍推进进度 → 到期滚成功率 → 弹结果（出货 / 失败退料）
```

**规则细则**：

- 炼丹位被占满时，新配方的 [炼制] 灰（"炼丹位已满"）
- 指派的弟子在炼丹期间**不占建筑分配位**（炼丹是任务，不是常驻），但 idle 弟子才能被指派（cultivating / 历练中的不行）
- 弟子炼丹值影响**可炼配方上限**（required_alchemy_skill），M3 不影响成功率（成功率由配方固定）；M4 方案 B 起弟子炼丹值才参与成功率计算
- 炼丹中途不可取消（同建造，M3 限制）

### 5.6 月产药材（药圃合并功能）

丹房自带药圃，月节拍自动产药材，无需玩家操作：

```
月节拍：
  └─ InventoryService.add("herb_common", building.herb_yield_per_month)
     # lv1=2 / lv2=4 / lv3=6 株（§4.5）
```

> 月产的是**通用灵草** `herb_common`（聚气丹 / 疗伤丹的主料）。高级材料（妖丹 / 火精 / 千年灵芝）只能靠历练获取——形成"基础丹自给 + 高级丹依赖历练"的资源结构，呼应核心循环。

---

## 6. 炼器子系统（M4 推迟 · schema 占位保留）

> 用户定调（2026-06-05）：M3 极简版**不实装炼器房 `forge_room`**——装备 / 法宝系统 M5 才到位，M3 炼器产物（武器 / 储物戒）无消费场景。本节保留 schema 占位 + 共享工厂设计，M4-M5 实装。

### 6.1 为什么 M4 才做

| 原因 | 说明 |
|---|---|
| 装备系统未到位 | 武器 / 法宝的 base_power 加成依赖 M5 装备槽（装备系统列为 M5 扩展点，见 GDD-11）|
| 矿石资源链未建 | M3 历练产物以灵石 / 药材为主，矿石供给不足 |
| 建筑数极简 | 方案 A 砍到 5 建筑，炼器房进扩展空槽（M4 解锁）|

### 6.2 共享工厂设计（M3 已为 M4 预留）

炼器与炼丹**共享 `ProductionService` 生产任务结构**——M3 实装炼丹时，工厂骨架就按"可容纳多种 task_kind"设计，M4 加炼器只需注册新 task_kind：

```gdscript
# ProductionService（M3 实装，支持 alchemy / build；M4 加 forge）
ProductionService.start_task(task_kind: "alchemy"|"build", ...)   # M3
ProductionService.start_task(task_kind: "forge", ...)             # M4 加
ProductionService.tick_month(current_month: int)
ProductionService.cancel_task(task_id: String)  # M4+
```

> **可扩展性纪律**：M3 的 ProductionService 不能写死只处理 alchemy——必须按 `task_kind` 分发，M4 加 forge handler 即可，不改骨架。

### 6.3 ForgeRecipeDef schema（M4 占位）

```gdscript
# M4 实装；与 AlchemyRecipeDef 同构
class_name ForgeRecipeDef
extends Resource

@export var recipe_id: String
@export var required_materials: Dictionary     # 矿石 / 妖兽材料
@export var required_forge_skill: int          # 弟子"炼器"属性
@export var required_room_level: int           # forge_room 等级（M4 建筑）
@export var duration_months: int
@export var success_rate: float
@export var output: Dictionary                 # 法宝 / 兵器 / 装备
@export var firing_curve: Array[float] = []    # 同 alchemy schema 占位
@export var quality_tiers: Array = []          # M5 品质分级占位
```

**M4 计划配方**（占位，不实装）：凡铁剑 / 灵气剑 / 储物戒等。

---

## 7. 培养子系统（用户定调 Q3=C 哲学版）

### 7.1 哲学（强调）

**GDD-05 不持有"怎么培养"的玩法逻辑——所有成长机制在 GDD-04**。本节仅定义"建筑作为修炼场所提供哪些 modifier"。

### 7.2 弟子分配 = modifier 来源

```
玩家把弟子 X 拖入修炼塔
  ├─ 校验 X.state in ["idle", "cultivating"]
  ├─ 校验 building.assigned_character_ids.size() < building.template.levels[lv].capacity
  ├─ building.assigned_character_ids.append(X.id)
  ├─ X.state → "cultivating"  (GDD-02 状态机；GDD-04 §3 接管闭关玩法)
  └─ BuffService.apply(X, building level modifiers)  ← 见 §3.3

# 玩家结束分配
BuildingService.unassign(building, X)
  ├─ X.state → "idle"
  ├─ BuffService.remove_by_source(X, building.slot_id)
  └─ broadcast signal disciple_unassigned(X, building)
```

### 7.3 M3 培养路径（玩家心智）

```
弟子在修炼塔 → cultivation_speed_bonus（GDD-04 闭关公式自动读，短期涨经验快）
弟子在藏书阁 → insight_per_month +N / 月（资质提升，长期提突破率）
弟子无分配 = idle → 不涨任何东西，月俸照扣
（M4 加：演武场战训 / 比武台互训）
```

**关键设计**：分配建筑 = 玩家"投资"行为；不分配 = 资源浪费 → 推动玩家管理弟子。修炼塔（速度）vs 藏书阁（悟性）形成"冲境界 vs 养潜力"的策略分流。

### 7.4 与 GDD-04 接触

| GDD-05 行为 | GDD-04 接收侧 |
|---|---|
| 把弟子分配到修炼塔 → 挂 `cultivation/sect_tower_aid` buff | GDD-04 §3.2 闭关 modifier 来源表自动包含此 buff |
| 弟子在藏书阁月节拍 → CharacterService.get_attribute("insight") += N | GDD-04 §5.5 资质提升渠道 |

GDD-05 不直接调 GDD-04 函数，仅通过 BuffService / CharacterService 接口。

### 7.5 容量约束

每个建筑 `BuildingLevel.capacity` 定义最多容纳几个弟子（M3 = 3 级）：

| 建筑 | lv1 | lv2 | lv3 |
|---|---|---|---|
| 修炼塔 | 2 | 3 | 5 |
| 藏书阁 | 3 | 6 | 10 |
| 弟子居所 | 6 | 10 | 15（容纳总弟子人数）|

> 弟子总数受弟子居所容量限制（住宿是硬约束）。修炼塔 / 藏书阁容量是"同时分配上限"。丹房不分配弟子常驻（炼丹任务临时指派，§5）。

---

## 8. 弟子招收（继承 GDD-02 §5）

### 8.1 招收来源（M3 实装 2 条 + 1 条挂钩）

> 招收玩法 SoT 在本章（v3.2 后从原 GDD-02 §5.6 迁入；GDD-02 仅留 recruitable / template_id 字段契约）。

| 来源 | 触发 | 频率 | 成本 | 模板偏好 |
|---|---|---|---|---|
| **自动来投** | 系统按月概率触发 | 平均 3-6 月 1 次 | 0 | `passive_seeker`（资质偏低）|
| **主动招收** | 玩家在主殿发起"开门收徒" | 玩家主动 | 灵石 + 1 月时间 | `active_recruit`（资质中偏上）|
| **历练带回** | 历练事件 outcome 含 `recruit(template_id)` | 看玩家历练频率 | 历练时间 | `expedition_rescue`（资质偏高 / 偶尔出 9-10 天才）|

### 8.2 自动来投触发

```
月节拍：
  └─ if rng.randf() < auto_recruit_chance(sect_reputation):
        offer = CharacterGenerator.generate(template="passive_seeker")
        broadcast signal recruit_offer_arrived(offer)
        UI 弹"有人前来求收"，玩家选择接收 / 拒绝
```

`auto_recruit_chance` 受宗门声望（reputation）影响——GDD-06 平衡。

### 8.3 主动招收

```
玩家在主殿点"开门收徒"
  ├─ 校验灵石充足
  ├─ 进入 recruiting 月（1 月不出门 / 1 月不能再发起）
  └─ 月节拍推进：
        └─ 月末：CharacterGenerator.generate(template="active_recruit")
                 → 给 1-3 个候选 → 玩家挑 1 个收下 / 全拒
```

### 8.4 招收 UI 信息密度（v3.2 从原 GDD-02 §5.7 迁入）

玩家招收时**可见**：名字 / 性别 / 立绘 / 灵根（5 行 + 总量）/ 悟性 / 体魄 / 神识 / 炼丹 / 炼器 / 年龄

**M3 不显示**：装备 / 法宝 / 主修功法 / 寿元 / 性格 / 出身 / 关系网 / 特性

### 8.5 容量约束（依弟子居所）

```
sect.member_ids.size() < dorm_total_capacity()
不满足 → 主动招收按钮置灰；自动来投失败（"宗门已满" UI 提示）
```

`dorm_total_capacity()` = 所有 disciple_dorm 实例的 capacity 之和。

### 8.6 角色生成器（CharacterGenerator）

继承 GDD-02 §5.2 接口（生成器属于"角色契约层"的工厂，留 GDD-02）。GDD-05 仅调用：

```gdscript
CharacterGenerator.generate(template_id: String) -> Character
```

模板配置（`active_recruit` / `passive_seeker` / `expedition_rescue`）的具体属性分布在 GDD-02 §5.3。

---

## 9. 关键事件接口（用户定调 Q4=D · M3 仅留接口）

### 9.1 哲学

宗门事件（建造完成 / 弟子突破成功 / 月俸不足 / 灵气潮汐 / 邻宗来袭等）M3 不实装具体事件库，**仅留接口**——M4-M5 时复用 GDD-03 §2 的 EventEngine 三幕模型。

### 9.2 接口设计（M3 占位）

```gdscript
# scripts/sect/sect_event_router.gd（M3 stub，M4 实装）
class_name SectEventRouter
extends Node

# 监听各 service 的 signal，路由到 EventEngine
func _ready():
    BuildingService.connect("level_up", _on_building_level_up)
    CultivationSystem.connect("breakthrough_succeeded", _on_breakthrough)
    InventoryService.connect("resource_below_threshold", _on_resource_low)
    TimeService.connect("month_advanced", _on_month_advanced)

func _on_building_level_up(slot, building, lv):
    # M4 触发"建筑落成"事件（EventEngine.resolve_event with category="sect_event"）
    pass  # M3 stub

func _on_breakthrough(c, new_realm):
    # M4 触发"弟子突破"宗门事件
    pass  # M3 stub
```

### 9.3 复用 GDD-03 EventEngine（M4 实装）

宗门事件 = `EventTemplate.category = "sect_event"`（在 GDD-03 §2.2.1 的 9 类白名单已含 `sect_event` 占位类，本章正式使用）。

> 注：GDD-03 §2.2.1 当前的 9 类是 `battle / encounter / treasure / story / trial / extraction / leave / rest / quest`。`sect_event` 是 M4 走 ADR 加入第 10 类的占位。

### 9.4 M3 schema 占位

```
data/table/宗门/宗门事件.xlsx     ← M3 表存在但仅 1 行示例（建筑落成）
```

**M3 实装内容**：

- SectEventRouter autoload 注册（stub）
- 表 schema 落盘（含 1 个示例事件）
- 不在游戏中触发任何宗门事件

### 9.5 M4-M5 计划事件清单（占位）

| 事件 | M4 / M5 | 触发 |
|---|---|---|
| 建筑落成庆典 | M4 | building_level_up signal |
| 弟子突破喜讯 | M4 | breakthrough_succeeded signal |
| 月俸不足危机 | M4 | inventory.resource_below_threshold |
| 灵气潮汐 | M4 | TimeService 季节循环 |
| 邻宗来袭 | M5 | invasion roll |
| 宗门大比 | M5 | 年度事件 |
| 弟子叛宗 | M5 | 弟子忠诚度过低（关系系统）|

---

## 10. 与其它系统接触面

### 10.1 上下游接触

| 系统 | 通信 | 内容 |
|---|---|---|
| `TimeService` | 监听 month_advanced | 推进所有任务（建造 / 炼丹）/ 丹房月产药材 / 月俸扣除 / 自动来投滚 RNG |
| `CharacterService`（GDD-02） | 调 set_state / get_attribute | 弟子分配建筑时切状态；读悟性等属性 |
| `BuffService` | apply / remove | 建筑 modifier 挂 buff |
| `InventoryService` | consume / add | 建造扣资源 / 炼丹扣材料加产物 / 丹房月产药材 |
| `CultivationSystem`（GDD-04） | 仅通过 buff 间接接触 | 不直接调 GDD-04 |
| `EventEngine`（GDD-03） | M4 触发 sect_event | 月节拍 / signal 钩子 |
| `SectService` | Sect 数据 CRUD 入口 | 所有 sect.buildings / member_ids 读写经它 |
| `SaveService` | serialize / deserialize | 建造进度 / 炼丹任务 / 弟子分配状态 |

### 10.2 GDD-05 提供的 signal

| signal | 谁监听 | 用途 |
|---|---|---|
| `building_level_up(slot, building, lv)` | SectEventRouter / UI | 建筑升级完成 |
| `building_constructed(slot, building)` | SectEventRouter / UI | 新建筑落成 |
| `disciple_assigned(c, building)` | UI / 数据分析 | 弟子调度 |
| `disciple_unassigned(c, building)` | UI | 同上 |
| `alchemy_task_completed(task, result)` | UI / SectEventRouter | 炼丹完成 |
| `forge_task_completed(task, result)` | UI / SectEventRouter | 炼器完成（M4）|
| `recruit_offer_arrived(offer)` | UI | 招收候选弹窗 |

### 10.3 数据驱动落地总表

```
data/table/宗门/
├─ 宗门布局.xlsx           ← SectLayoutTemplate（default_sect_v1，8 槽）/ BuildingSlotDef
├─ 建筑模板.xlsx           ← BuildingTemplate（5 个）/ BuildingLevel（每个 3 级）
├─ 炼丹配方.xlsx           ← AlchemyRecipeDef（5 个 M3 配方）
├─ 炼器配方.xlsx           ← ForgeRecipeDef（M4 占位，M3 不填）
├─ 招收模板.xlsx           ← active_recruit / passive_seeker / expedition_rescue（继承 GDD-02 §5.3）
├─ 宗门事件.xlsx           ← M3 占位 1 行
└─ proto/sect_*.schema.toml
```

---

## 11. 风险与扩展点

### 11.1 风险

| 风险 | 提前安排 |
|---|---|
| 5 建筑 + 8 槽过少 → 后期玩法乏力 | 3 个扩展空槽 M4+ 解锁（聚灵阵 / 演武场 / 炼器房）；M5 加 SectLayoutTemplate v2 走 ADR |
| 极简后宗门玩法太薄 | M3 靠"建筑升级 + 弟子分配策略（修炼塔 vs 藏书阁）+ 炼丹链"撑玩法；深度内容 M4 通过空槽逐步加 |
| 建筑 modifier 叠加爆炸 | 同类 buff 用 BuffService 饱和（取最大 / 求和按 buff schema 配） |
| 炼丹 M3 极简没玩法 | 用户定调：M3 用极简 + schema 留扩展位（firing_curve / process_steps），M4-M5 加深度 |
| 弟子分配 UI 复杂（拖拽 / 拖错）| M3 用建筑详情面板的"+ 添加弟子"按钮替代拖拽 |
| 宗门事件 M3 不实装 → 玩家觉得宗门"死气沉沉" | M3 通过其它系统的 signal 让 UI 展现变化（建造进度 / 突破喜讯弹窗等），M4 加完整事件 |
| 招收太频繁 → 弟子膨胀 | 容量硬约束（dorm 总容量）+ auto_recruit_chance 按月低概率（GDD-06 平衡）|
| 月俸压力过小 → 玩家不需要历练 | GDD-06 平衡：月俸 + 维护费 > 自然产出，倒逼玩家出门 |

### 11.2 预留扩展点

| 扩展（M4 / M5）| 位置 |
|---|---|
| 多套 SectLayoutTemplate（不同门派传承）| §2.3 schema 已支持 |
| 炼丹 B/C 方案（火候 / 工序）| §5.2 schema 字段已留 |
| 炼器房 `forge_room` | M4 填扩展空槽（§6 schema 已占位）|
| 聚灵阵 `qi_array`（全宗门被动加速）| M4 填扩展空槽（§3.4 SECT 级 buff fan-out 范式已预留）|
| 演武场 `training_field`（战训）| M4 填扩展空槽（combat_training_bonus modifier）|
| 厨房 `kitchen`（月俸折扣）| M4 填扩展空槽（M3 折扣直接并入月俸数值）|
| 炼器装备品质分级 | §6 schema 留 quality_tiers 占位 |
| SectEventRouter 完整事件库 | §9 接口就位 |
| 宗门保卫战（接入点 2，GDD-03 §7.2.2）| BuildingService 提供"宗门战力"聚合 API |
| 多宗门交互 | Sect schema（GDD-01 §6.11）已含 relations: Dict |
| 建筑特技 / 工艺师 | BuildingTemplate 加 `master_disciple_id` 字段（M5）|
| 比武台 / 弟子互训 | M5 加 BuildingTemplate lv2+ 容量 + 互动 modifier |
| 长老阁突破指点（GDD-04 §7.2 占位）| M5 在主殿加"长老指点"行为，给指定弟子挂突破 buff |
| 藏书阁功法学习 | M5 藏书阁 lv2+ 解锁，schema 占位 `learnable_method_ids` |

---

## 12. M3 实装清单

| # | 内容 | 状态 |
|---|---|---|
| 1 | §2 SectLayoutTemplate `default_sect_v1`（8 槽 = 5 实建 + 3 扩展空槽）| ✅ M3 |
| 2 | §3 5 个建筑模板 + 每个 3 级数据（main_hall / disciple_dorm / cultivation_tower / library / alchemy_room）| ✅ M3 |
| 3 | §3.2.1-3.2.5 各建筑设定 / 升级表 / 使用方式 | ✅ M3 |
| 4 | §3.3 modifier→BuffService 接入（character 级）| ✅ M3 |
| 5 | §3.4 SECT 级 buff fan-out 范式 | ⏳ M4（M3 不实装）|
| 6 | §4 建造 / 升级流程 + 月节拍推进（建造时长 1-2 月）| ✅ M3 |
| 7 | §5 5 个炼丹配方 + 极简流程 + 丹房月产药材 | ✅ M3 |
| 8 | §5.4 schema 扩展位字段就位（firing_curve / process_steps / quality_tiers）| ✅ M3（占位）|
| 9 | §6 炼器子系统 | ⏳ M4（schema 占位 + ProductionService 工厂预留）|
| 10 | §7 弟子分配 / 解除接口（修炼塔 / 藏书阁）| ✅ M3 |
| 11 | §8.1-8.3 自动来投 + 主动招收 | ✅ M3 |
| 12 | §8.1 历练带回（GDD-03 事件挂钩）| ✅ M3（GDD-03 已支持）|
| 13 | §9 SectEventRouter autoload stub | ⏳ M3 stub only |
| 14 | §9.4 宗门事件表 1 行示例 | ✅ M3 schema 落盘 |
| 15 | UI：宗门主界面（8 槽位 + 资源显示 + 弟子列表 + 建筑详情面板）| ✅ M3 |
| 16 | ProductionService 按 task_kind 分发（M3 支持 alchemy/build，M4 加 forge）| ✅ M3 |

---

## verdict

drafting · 等用户审。

主要待解决：
- 各建筑 / 配方 / 招收的具体数值（消耗 / 时长 / 概率）→ GDD-06 平衡章节
- §9 宗门事件 M4 实装时正式加入 EventTemplate.category 第 10 类（走 ADR）
- M3 UI 设计细节（拖拽 vs 按钮，布局）→ 需 ux-designer + art-director 介入
