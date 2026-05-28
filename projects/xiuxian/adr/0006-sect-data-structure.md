---
adr_id: 0006-sect-data-structure
status: accepted
date: 2026-05-25
accepted_at: 2026-05-26
deciders: [用户, codebuddy]
supersedes:
related_gdd: gdd-01 §6.11 宗门数据结构 / 待建 gdd-05 宗门经营
---

# ADR 0006 · 宗门数据结构（实体 + IBuffable）

## 上下文

用户定调（2026-05-25）：

> "除了角色属性，是不是也应该存在宗门的状态和属性？"

之前的设计只考虑了 Character 数据结构，忽略了**宗门本身也是一个有状态、有属性、有 buff 的实体**。

宗门承载：
- 玩家身份的"主世界容器"（玩家是宗主，玩家的宗门在世界中）
- 资源 / 建设 / 人员的归属
- 大世界事件的目标（被攻打 / 被赏赐 / 灵气潮汐覆盖 / ...）
- 跨角色的修饰器（"灵气浓郁"加成对全宗门弟子）

如果把宗门数据散落在多处（资源在 InventoryService，建筑在 BuildingService，声望在 ReputationService...），会导致：
- 没有统一"宗门"对象，加新维度（如未来"派系归属"）需要加新 service
- 大世界事件无法干净地"作用于宗门"
- 存档分区不清晰
- 宗门 buff 无处挂载

## 决策

采用 **统一 Sect 数据结构 + 实现 IBuffable + SectService autoload + 子领域服务读写 Sect 字段**。

### 1. Sect 数据结构

```gdscript
class_name Sect

# === 实现 IBuffable 接口 ===
var target_type: TargetType = TargetType.SECT
var target_id: String              # 全局唯一（玩家宗门固定为 "player_sect_main"）
var buffs: Array = []              # Array[Buff]

# === 基础信息 ===
var name: String                   # 宗门名（玩家可改名）
var founded_at_month: int          # 创立时间（游戏内月份）
var description: String

# === 派系 / 地位（M3 占位 / M5 用）===
var faction: String = "neutral"    # 正 / 邪 / 中立 / 自定义
var reputation: float = 0.0        # 声望值
var relations: Dict = {}           # 与各 NPC 派系的关系（faction_id → float）

# === 资源（数值，按月结算 / 按事件变动）===
var resources: Dict = {}           # {"spirit_stone": 1000, "herb_a": 50, ...}
                                   # 资源类型由 data/economy/resource_types.tres 定义

# === 建设（建筑列表）===
var buildings: Array = []          # Array[BuildingInstance]
                                   # 详见 GDD-05 宗门经营 / 建筑数据结构

# === 人员引用（不持有 Character 实例，只引用 ID）===
var member_ids: Array = []         # Array[character_id]
                                   # 实际 Character 数据在 CharacterRoster 中
                                   # member_ids 列表 = 本宗 Character.identity ∈ {MASTER_CURRENT, DISCIPLE, ELDER}

# === 大事记（M3 简化 / M5 扩展）===
var milestones: Array = []         # Array[Dict]，例：[{month: 5, event_type: "founded", ...}]

# === 元数据 ===
var save_version: int = 1
```

### 2. 子领域服务读写 Sect 字段（解耦）

按 §6.9 解耦原则，**SectService 是 Sect 数据的唯一入口**，子领域服务通过 SectService 读写：

```gdscript
# SectService.gd autoload
class_name SectService

# === 数据访问 ===
get_sect() -> Sect                          # 玩家自己宗门，唯一
get_resources(sect) -> Dict
get_buildings(sect) -> Array
get_member_ids(sect) -> Array

# === 资源操作（领域无关）===
add_resource(sect, type, amount, source) -> bool
remove_resource(sect, type, amount, reason) -> bool
sum_resources(sect, type) -> int

# === 成员管理 ===
add_member(sect, character_id) -> bool      # 招收弟子时调用
remove_member(sect, character_id, reason)   # 叛门 / 死亡 / 离宗时调用

# === 派系 / 声望 ===
adjust_reputation(sect, delta, source)
adjust_relation(sect, faction_id, delta, source)

# === 建设 ===
add_building(sect, building_def, location)
remove_building(sect, building_id)
upgrade_building(sect, building_id)

# === Signal ===
signal resource_changed(sect, type, old, new, source)
signal member_added(sect, character_id)
signal member_removed(sect, character_id, reason)
signal building_changed(sect, building_id, change_type)
signal reputation_changed(sect, old, new, source)
```

**子领域服务的角色**（领域逻辑层）：
- `InventoryService` —— 物品 / 资源的领域规则（背包上限 / 物品堆叠等），**不持有数据**，通过 SectService 读写 sect.resources
- `BuildingService` —— 建筑的领域规则（建造时间 / 升级条件 / 产出公式），通过 SectService 读写 sect.buildings
- `ReputationService` —— 声望计算公式，通过 SectService 读写 sect.reputation

> 这是 §6.9.1 的标准应用：所有数据归 SectService 管理，子服务做领域逻辑。

### 3. 宗门 Buff 用例（关键设计点）

宗门作为 IBuffable，可以挂以下类型 buff：

| Buff 大类 / 小类 | 触发场景 | 效果（领域逻辑） |
|---|---|---|
| `cultivation/qi_acceleration`（applicable: CHARACTER, SECT）| 灵气潮汐事件 / 阵法激活 | SectService 监听 buff，应用到所有本宗弟子的修炼速度 |
| `environment/qi_richness`（仅 SECT）| 宗门所在地灵气浓度 | 长期 buff，影响修炼 / 弟子招收 |
| `external/under_attack`（仅 SECT）| 邻宗来袭事件 | debuff，影响声望 / 阻止建设 |
| `external/imperial_blessing`（仅 SECT）| 主线大事件 | 加资源产出 / 加声望 |
| `internal/disciple_unrest`（仅 SECT）| 弟子心性平均值过低 | 加叛门概率 |

> 关键：**宗门 buff 是单实体级**，但效果可能"广播到所有成员"（如 qi_acceleration 加成所有弟子修炼）。这种 fan-out 由消费方（ProductionService 等）实现，不是 BuffService 的责任。

### 4. 范围（用户定调 · 聚焦玩家自己宗门）

> 用户定调（2026-05-26）："游戏中可能还是聚焦于自己宗门的，先把自己宗门做好。
> 至于是否存在多宗门以及其他宗门是不是只是需要部分数据，可以玩法设计上再决定。"

- **本 ADR 范围**：玩家自己的宗门（唯一）
- **其他派系 / 异宗**：通过 `Sect.relations` Dict（faction_id → float 关系值）+ `Character.identity = NON_SECT`（具体 NPC）表达，**不需要完整 Sect 实体**
- 是否未来给"邻宗"建立 Sect 实例 = 玩法设计决定，不在本 ADR 提前承诺

| 字段 | M3 用法 | 后续可能扩展（玩法决定）|
|---|---|---|
| `faction` | 占位（"neutral"）| 玩家选择 / 主线分支 |
| `reputation` | 占位（M3 不参与运算）| 后续叛门 / 主线触发条件 |
| `relations` | 空 Dict | 与 NPC 派系 / 异宗的关系值（仅数值，不需要异宗 Sect 实体）|
| `resources` | 完整使用（5-8 种基础资源）| 后续扩展资源类型 |
| `buildings` | 完整使用（5-8 个建筑位）| 后续扩展建筑链 |
| `member_ids` | 完整使用（门主 + 1-2 弟子）| 后续多弟子 |
| `milestones` | 仅记 `founded` | 后续主线大事记 |
| `buffs` | 至少支持 `qi_acceleration` 应用 | 后续大量扩展 |

## 候选方案

| # | 方案 | 优点 | 缺点 | 结论 |
|---|---|---|---|---|
| **A** | **统一 Sect 实体 + IBuffable + 子领域服务（本 ADR）** | 所有数据归口 / 加 buff 容易 / 大世界事件目标清晰 / §6.9 解耦 | 子领域服务的"读写权"边界要培养 | ✅ 选择 |
| B | 散落在各 service（InventoryService / BuildingService 各自存）| 看起来分工清晰 | 没有"宗门"对象 / buff 没法挂 / 大世界事件难表达 | ❌ 放弃 |
| C | Sect 是"全局单例"（用 const / static）| 实现最简 | 与"实体 + IBuffable"模式冲突 / 不能挂 buff | ❌ 放弃 |
| D | Sect 继承 Character | 复用 Character schema | 语义错误（宗门不是角色）/ 字段大量浪费 | ❌ 放弃 |

## 理由

- **A 选择理由**：宗门是真实的"实体"——有状态、有属性、有 buff、有大世界事件作用。统一为 Sect 数据结构 + IBuffable 是最自然的建模。子领域服务（Inventory / Building / Reputation）做领域逻辑，SectService 做数据归口，符合 §6.9 解耦。
- **B 放弃理由**：宗门 buff 无处挂、大世界事件作用目标不清
- **C 放弃理由**：与"实体 + IBuffable"统一模式冲突；buff 无法挂载到 const / static 上
- **D 放弃理由**：宗门和角色语义不同，强行继承导致字段污染

## 影响

### 正面

- 大世界事件可以干净地"作用于宗门"（"邻宗来袭"挂 buff `external/under_attack`）
- 宗门 buff 系统统一（§6.10 buff 系统 IBuffable 接口的实证）
- 存档分区清晰（sect 段独立，see ADR-0004）
- 子领域服务边界清晰（InventoryService 不再"自己持有数据"）

### 负面

- M2 必须实现 SectService（多 1 个 autoload）
- 子领域服务的"通过 SectService 读写"约定要培养（开发者可能直接读 sect 字段）

### 风险

| 风险 | 概率 | 缓解 |
|---|---|---|
| 子领域服务（InventoryService 等）绕过 SectService 直读 sect 字段 | 中 | code review 强制 + getter / setter 封装 + linter 规则（M2 后期）|
| 宗门 buff 与角色 buff 命名冲突 | 中 | buff_id 命名规范：`buff_sect_*` 前缀 / `applicable_targets` 强制声明 |
| 大世界事件 fan-out（"qi_acceleration" 加成所有弟子）实现复杂 | 中 | 消费方监听宗门 buff_applied，自己 fan-out；BuffService 不感知 |
| sect.resources 与未来"个人物品"混淆 | 低 | M3 物品仅在宗门层；后续如加"个人物品"通过 Character.inventory 字段 |

## 实现要点（M2 任务）

- `Sect.gd`（数据类）+ `SectService.gd` autoload
- `data/sect/initial_sect.tres`（初始宗门数据，玩家选择 / 默认）
- `data/economy/resource_types.tres`（资源类型定义，M3 5-8 种）
- 实现 IBuffable 协议（target_type=SECT，buffs 数组）
- 单元测试覆盖：
  - 资源增减 / signal 触发
  - 成员加入 / 移除
  - 建筑添加 / 升级
  - **宗门 buff 应用与查询**（cultivation/qi_acceleration 用例）
  - **applicable_targets 校验**：仅 CHARACTER 的 buff 类型挂 sect 应失败
  - 月度 tick 通过 BuffService.tick_monthly(sect) 正确触发
  - 序列化 / 反序列化（sect 段独立）

## 关联

- GDD：gdd-01 §6.11（待加）/ 待建 gdd-05 宗门经营
- 上游 ADR：
  - ADR-0001 双层时钟（month_advanced 驱动月度结算）
  - ADR-0005 通用 Buff 系统（IBuffable 接口）
- 下游 ADR：
  - ADR-0004 存档架构（sect 段如何分区）
- 待建 GDD：
  - GDD-05 宗门经营（建筑 / 加工 / 培养子系统的领域逻辑）
  - GDD-04 经济与数值（资源类型 + 边际递减公式）
