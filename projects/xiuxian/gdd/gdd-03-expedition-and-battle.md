---
gdd_id: 03
gdd_title: 历练与战斗系统
status: ready_for_review
last_review: 2026-06-02
sections_complete: [节点地图, 事件引擎, 选项DSL, 撤离超时, 派遣弟子, 战斗框架, 战斗接入点]
sections_pending: []
upstream_adr: [0001-double-clock, 0002-battle-resolver-interface, 0003-character-state-machine, 0005-buff-system]
upstream_gdd: [gdd-01]
verdict: pending_user_review
---

# GDD-03 · 历练与战斗系统

> 本章承接 GDD-01 §2.3（双层时钟）+ §6.8（战斗框架）+ §4.1（系统清单），细化外出历练的拓扑、事件流、撤离机制、战斗接入。
>
> 上游 ADR：
> - 0001 双层时钟（历练百分比作为内层时钟）
> - 0002 战斗接口（战斗只是节点事件之一，本章 §6 引用，不复述）
>
> 章节范围（GDD-01 §7.3 M1 清单）：
> 节点地图数据结构 + 事件引擎 schema + 选项→后果 DSL + 撤离/超时机制 + 派遣弟子黑盒流（M4 才实现）+ 战斗框架（引用 ADR-0002）+ 5 个战斗接入点列出

---

## 1. 节点地图

### 1.1 设计精神

> 用户定调（2026-06-01 v2 · 关键概念校准）：
> - **节点 = 地点**（不是事件触发器）。地点内可发生 1+ 个事件（事件序列）
> - 历练**双层结构**：外层 = 地图选下一个地点 / 内层 = 地点内事件流
> - 拓扑选 **B 有向图（DAG）**——杀戮尖塔同款，分支可汇合
> - **撤离 = 拓扑层的孤立节点**，可提前规划路线（不是按钮、不是逃跑）
> - 撤离行为通过**特殊"无选项撤离事件"**触发，跟其它事件类型对等
> - 战雾：进图后只能看清下 4 层，撤离点临近才显示
> - **撤离点 = 决策出口，不是奖励放大器**（用户 2026-06-01 v3 纠偏）：
>   收益由路上事件本身驱动（深处事件产物档次更高），撤离时**没有任何"硬继承倍率"**——撤了多少 = 路上拿了多少。撤离点本身**无 multiplier / bonus_pool 等收益字段**

历练地图的核心心智：「踏入秘境，前进、岔路、不能回头；撤与不撤，是路线规划，不是按钮」。

#### 三类"结束/离开"概念区分（本节最重要）

| 概念 | 作用域 | 由谁触发 | 结果 |
|---|---|---|---|
| **战斗逃跑**（escape） | 单次战斗内 | `BattleResolver`（ADR-0002 winner=ESCAPED）| 战斗结束，事件序列**继续**，玩家仍在节点内 |
| **离开此地**（leave_location）| 节点内事件序列 | 系统事件 `__sys_leave_location__`（普通节点末槽强制触发 / 或选项内 jump_to_event 触发）| 关闭当前节点，**回到地图层**选下一节点 |
| **撤离**（extraction）| 整局历练 | 系统事件 `__sys_extraction__`（撤离节点末槽强制触发）| **整局结束**，回宗结算（路上已落袋的资源原样返回，无加成、无折损）|

> 命名约定：`leave_location` / `extraction` 既是 **slot_kind 取值** 也是 **action_type 取值**——同名同义，不带 `_event` 后缀。系统事件 id 加 `__sys_` 前缀防与策划事件冲突。

**撤离的两层模型**（行为层 + 拓扑层）：

- **行为层** —— `extraction` 是一种 action_type，无选项，触发即结算。事件引擎按统一 schema 处理，不需要知道节点类型
- **拓扑层** —— "撤离节点" 是一种特殊节点（`is_extraction_node=true`），事件序列**最后一个槽**强制 `slot_kind=extraction`。生成算法 / 地图 UI 据此识别

撤离节点的种类：

| 类型 | 描述 | 例子 |
|---|---|---|
| **终点撤离** | 整张图唯一终点，所有主路径汇合于此 | 通关后回宗 |
| **中途撤离** | 从主路径上某节点的**侧边额外出边**引出的孤立叶节点 | 半路见好就收 |
| **危险撤离** | 撤离节点的事件序列中**包含战斗 / 选项事件**，最后才是撤离事件 | "妖兽追击，先打一场再撤" |
| **安全撤离** | 撤离节点的事件序列**只有撤离事件**，0 个铺垫 | 直接归途 |

> **撤离点设计哲学**（凡触碰撤离点 schema / ExtractionService 实现的代码必须遵循）：
> 1. 撤离点不持有任何资源 / 倍率 / 加成数据
> 2. 撤离点的"价值差异"只能通过**事件序列**表达（伏击战斗给战利品 / 捡宝事件给物品 / 路上事件给体力差异）
> 3. 越深越值钱的张力来自**节点池产物档次曲线**（GDD-06 平衡），不是撤离点的硬继承
> 4. ExtractionService 不读取资源系统，仅触发"整局结束"信号让 SaveService 做收尾

数据驱动的层级（从外到内）：

```
ExpeditionMap (一张地图配置)
 └─ Region[]            （区域 / 章节，1 张图通常 1-3 区域）
     └─ Node[]          （节点 = 地点，是 DAG 顶点）
         └─ EventSlot[] （事件槽 1-N 个，依次执行）
             └─ Event   （引用 EventTemplate，见 §2）
```

#### 概念分类轴速查（导航）

历练系统涉及 3 条独立的分类轴，初看容易混淆。先建立心智模型：

| 轴 | 字段 | 作用域 | 取值数 | 用途 |
|---|---|---|---|---|
| **事件分类** | `EventTemplate.category` | 事件 | 9（见 §2.2.1）| **系统耦合锚点**，幸运/体质/道具/难度系统按它接钩 |
| **事件槽类型** | `EventSlotDef.slot_kind` | 事件槽 | 3（见 §1.3）| 槽行为路由（候选池抽 / 系统保留槽）|
| **动作类型** | `EventAction.action_type` | 动作 | 13（见 §2.3）| handler 分发，事件内部由 actions 组合而成 |

**关键区分**：

- **节点风味由 `NodeTemplate.display_name` + `icon_id` 表达**（不再有 theme 字段，避免又一条分类轴）—— 一个节点的风味是"古洞" / "坊市" / "妖墓"等具体名字，不是抽象类目
- **slot_kind 与 action_type 的命名对偶** —— `slot_kind=extraction` 槽固定调系统事件，该事件 after_phase 含 `action_type=extraction` 动作。槽与动作同名表示同义，**没有 _event 后缀的差异**（v2 命名校准）



### 1.2 拓扑约束（不变量）

| # | 约束 | 校验时机 |
|---|---|---|
| **主路径不变量** | | |
| 1 | 唯一入口（`is_entry = true`，d=0），唯一终点（`is_extraction_node = true` 且 d=max_depth） | 生成后 |
| 2 | 任何普通节点必须可达终点（不能死胡同；撤离节点是合法叶节点） | 生成后 |
| 3 | 主路径上的边只能从 `depth=k` 指向 `depth=k+1`（不能跨层 / 不能回退）| 生成时 |
| 4 | 同一深度的普通节点之间不连边 | 生成时 |
| **撤离节点不变量** | | |
| 5 | 撤离节点是**叶节点**（`connections` 为空），不可再前进 | 模板校验 |
| 6 | 撤离节点的入边只来自**主路径上的普通节点**（其它撤离节点不互连） | 生成时 |
| 7 | 撤离节点的事件序列**最后一个事件槽**强制 `slot_kind = extraction` | 模板校验 |
| 8 | 普通节点的事件序列**最后一个事件槽**强制 `slot_kind = leave_location` | 模板校验 |
| 9 | d=0（入口）出边不可直接连撤离节点（防止"刚进图就撤"无玩法）| 生成时 |
| **数量与位置不变量** | | |
| 10 | 撤离点数量由地图配表硬填（含终点撤离），数量 ≥ 1 | 模板校验 |
| 11 | 终点撤离节点必须存在且唯一 | 模板校验 |
| 12 | 任何节点的非末槽**不得**为 `slot_kind = extraction` 或 `leave_location`（这两个槽类型只能出现在末槽）| 模板校验 |
| 13 | 撤离节点的中间槽（如果有）只能是 `slot_kind = weighted_pool`——表达"危险撤离"的伏击战斗等前置事件 | 模板校验 |

> 主路径继续保持"分层 DAG"（约束 3-4），但撤离节点是**侧边引出的孤立叶节点**，不参与分层约束——这跟你画的图一致。

### 1.3 数据结构（M3 实现）

```gdscript
# scripts/expedition/expedition_map.gd
class_name ExpeditionMap
extends Resource

@export var map_id: String              # "qiyun_valley" / "demon_swamp"
@export var display_name_tid: String    # 文本表 key
@export var max_depth: int              # 主路径节点最大深度（关卡长度）
@export var regions: Array[RegionDef]   # 区域配置
@export var extraction_strategy: ExtractionStrategy   # 撤离点配置（§1.6）
@export var generator_seed_strategy: String  # "random" / "fixed:<seed>" / "daily"
@export var fog_lookahead_layers: int = 4    # 战雾：可见的层数（默认 4）
                                              # 注意：max_depth ≤ fog+1 的小图实质=全图可见，配表权衡
```

```gdscript
# scripts/expedition/region_def.gd
class_name RegionDef
extends Resource

@export var region_id: String           # "shallow" / "deep" / "core"
@export var depth_range: Vector2i       # 该区域占哪几层
@export var node_pool: Array[NodePoolEntry]  # 候选节点池
@export var connections_per_layer: Vector2i  # 每层节点数量上下限
```

```gdscript
# scripts/expedition/extraction_strategy.gd
class_name ExtractionStrategy
extends Resource

# 注意：本 schema 仅描述"撤离点放在哪、放几个、放什么模板"
# 不持有任何收益相关字段（multiplier / bonus_pool 等）
# 撤离点的"价值差异"由模板的 event_slots 表达（见 §1.1 撤离点设计哲学）

@export var total_count: int            # 撤离点总数（含 1 个终点撤离），由设计师配表硬填
@export var min_layer: int = 1          # 最小可放层（默认 1，禁止 d=0）
@export var preferred_layers: Array[int]  # 偏好的中途撤离放置层
@export var preferred_template_pool: Array[String]  # 撤离节点模板池（危险/安全混排）
```

```gdscript
# scripts/expedition/node_pool_entry.gd
class_name NodePoolEntry
extends Resource

@export var template_id: String         # 节点模板 id
@export var weight: int                 # 抽取权重
@export var min_depth: int
@export var max_depth: int
```

```gdscript
# scripts/expedition/node_template.gd
class_name NodeTemplate
extends Resource

@export var template_id: String         # "wild_beast_lair" / "ancient_ruin" / "wandering_cultivator_camp"
@export var display_name_tid: String     # 节点显示名（玩家看到的"古洞" / "坊市" / "妖墓"等具体名字）
@export var icon_id: String              # 节点图标
@export var is_extraction_node: bool = false   # ← 拓扑标记，true 时强制最后槽是 slot_kind=extraction
@export var event_slots: Array[EventSlotDef]   # 事件序列
@export var time_cost_percent: int       # 进入节点消耗的历练百分比（撤离节点通常为 0）

# 注：v3.1 决议（2026-06-02）取消 theme 字段——节点风味由 display_name + icon_id 直接表达，
# 不引入第 4 条分类轴。BGM / 视觉风格如需变化，由 UI 层按 display_name 或 template_id 映射。
```

```gdscript
# scripts/expedition/event_slot_def.gd
class_name EventSlotDef
extends Resource

@export var slot_kind: String
# slot_kind 枚举：
#   "weighted_pool"   普通事件槽：从 candidates 加权抽 1 个（含"无"为合法候选）
#   "leave_location"  特殊：固定调系统事件 __sys_leave_location__；普通节点末槽必有
#   "extraction"      特殊：固定调系统事件 __sys_extraction__；撤离节点末槽必有
@export var candidates: Array[EventCandidate]   # weighted_pool 时填，详见 §2
@export var description_tid: String     # UI 上的"槽预告"，可空
```

```gdscript
# scripts/expedition/event_slot_state.gd
class_name EventSlotState
extends RefCounted

# 运行态：每个 NodeInstance 持 N 个 EventSlotState（与 NodeTemplate.event_slots 一一对应）
var slot_kind: String                   # 镜像 EventSlotDef.slot_kind
var resolved: bool                      # 是否已解析（事件已跑完）
var resolved_event_id: String           # 实际抽到 / 强制触发的 event_id；"" = 该槽被跳过（candidates 抽到空）
```

**运行时实例**（区分模板和实例）：

```gdscript
# scripts/expedition/expedition_state.gd
class_name ExpeditionState
extends RefCounted

var map_id: String
var seed: int                           # 本局种子（存档关键）
var nodes: Dictionary                   # node_instance_id → NodeInstance
var current_node_id: String
var visited_node_ids: Array[String]
var revealed_node_ids: Array[String]    # 已揭示（脱雾）的节点
var time_remaining_percent: int         # 内层时钟剩余百分比
```

```gdscript
# scripts/expedition/node_instance.gd
class_name NodeInstance
extends RefCounted

var node_id: String                     # 实例 uuid
var template_id: String
var depth: int
var connections: Array[String]          # 出边（撤离节点为空）
var is_extraction_node: bool            # 镜像模板字段，便于运行时快速判定
var event_slot_states: Array[EventSlotState]
var consumed: bool                      # 事件序列消费完毕
```

> **模板（Resource，进 git）vs 实例（RefCounted，进存档）分离**——遵循 ADR-0004 §6.7。
> M3 数据结构里 NodeInstance schema 必须完整（含 is_extraction_node），避免 M5 加内容时存档迁移痛。

### 1.4 生成算法（M3 实现）

进图时按以下步骤生成节点 DAG：

```
[Phase A · 主路径生成]
1. 取 ExpeditionMap.regions，按 depth_range 划分层
2. 对每一深度 d ∈ [0, max_depth):
   a. 按 region 的 connections_per_layer 决定本层节点数 n
   b. 从 region.node_pool 加权抽 n 个 NodeTemplate（满足 min_depth/max_depth 约束 + is_extraction_node=false）
   c. 创建 n 个 NodeInstance
3. 连主路径边（深度 d → d+1）：
   a. 对每个 d 层节点，从 d+1 层节点中按"距离权重"抽 1-2 条出边
   b. 保证 d+1 层每个节点至少有 1 条入边
4. 入口（d=0）只 1 个节点

[Phase B · 撤离点生成]
5. 终点撤离节点：在 d=max_depth 创建唯一撤离节点（从 extraction_strategy.preferred_template_pool 抽）
   - d=max_depth-1 层所有节点的出边都指向它
6. 中途撤离节点：根据 extraction_strategy 创建 (total_count - 1) 个
   - 候选层 = preferred_layers ∩ [min_layer, max_depth-1]
   - **烘焙时强校验**：如果 |候选层| < (total_count - 1)，烘焙报错并指出冲突（防止设计师配出无解策略）
   - 在每个选定层挑 1 个普通节点，给它**额外**加一条出边指向新建的撤离节点
   - 该撤离节点的 connections 为空（叶节点）
7. 校验 §1.2 不变量；失败 → 重试（最多 3 次）→ 仍失败 → 报错

[Phase C · 战雾初始化]
8. 标记 d=0 入口节点 + d=1 所有节点为 revealed
9. 玩家进入新节点时：揭示 [current_depth, current_depth + fog_lookahead_layers] 范围的所有节点
10. 撤离节点单独规则：当玩家所在节点连接到某中途撤离时，揭示该撤离节点（通常已在战雾范围内）
```

**为什么撤离点位置由设计师精控（Phase B 步 6 走 preferred_layers）**：搜打撤的节奏体验高度依赖撤离点分布——前期密集 = 鼓励试探，后期密集 = 放生胆怯玩家，分布不当直接破坏紧张感。把这个交给完全随机不行。

### 1.5 撤离点的位置示意（用户图形化定调）

```
                                              [中途撤离]
                                                ↑
[初始点]→[2节点]→[1节点]→[2节点]→[2节点]→[3节点]→[终点撤离]
                              ↓
                         [中途撤离]
```

- 矩形/平行四边形 = 撤离节点（拓扑标记 `is_extraction_node=true`）
- 圆形 = 普通节点
- 主路径横向流动（左→右），撤离节点是侧边引出的孤立叶节点
- 玩家走到任一撤离节点 → 末槽触发 `__sys_extraction__` 系统事件 → 整局结算

### 1.6 数据驱动落地

```
data/table/历练地图.xlsx
├─ Sheet "地图模板"          → ExpeditionMap[]（含 max_depth / fog_lookahead_layers）
├─ Sheet "区域配置"          → RegionDef[]
├─ Sheet "节点池"            → NodePoolEntry[]
├─ Sheet "节点模板"          → NodeTemplate[]（普通节点 + 撤离节点）
├─ Sheet "撤离点策略"        → ExtractionStrategy[]（每图一行：total_count + preferred_layers + 模板池）
└─ Sheet "事件槽配置"        → EventSlotDef[]

data/table/proto/expedition_map.schema.toml
└─ 6 张表的 schema 定义
```

**M3 必填**：1 张地图（`qiyun_valley` 气运谷），含：

- 3 区域 × 各 4 层 × 2-3 节点 = ~30 普通节点模板（M3 复用，模板数远少于实例数）
- 3-5 撤离节点模板（混搭安全/危险）
- ExtractionStrategy：total_count=3（含 1 终点 + 2 中途），preferred_layers=[3, 7]

### 1.7 实现要点（M3）

| 组件 | 路径 | 责任 |
|---|---|---|
| `ExpeditionService` | `game/scripts/expedition/expedition_service.gd`（autoload）| 进图 / 退图 / 节点切换 |
| `MapGenerator` | `game/scripts/expedition/map_generator.gd` | DAG 生成（§1.4 三阶段） |
| `ExtractionService` | `game/scripts/expedition/extraction_service.gd` | 处理 `extraction` action：广播 `expedition_ended` signal，触发 SaveService 收尾。**不读资源、不算倍率、不持有任何收益逻辑** |
| `LocationLeaveService` | `game/scripts/expedition/location_leave_service.gd` | 处理 `leave_location` action：广播 `location_left` signal，让 ExpeditionService 弹下一节点选择 UI |
| `NodeUI` | `game/scripts/ui/expedition_map_ui.gd` | 渲染节点图（按 depth 横向）+ 战雾遮罩 |
| `ExpeditionState` | `game/scripts/expedition/expedition_state.gd` | 内存运行态，被 SaveService 序列化 |

#### 节点切换信号链（关键流程）

```
玩家在节点 A 完成最后一槽（slot_kind = leave_location）
  └─ EventEngine 解析 __sys_leave_location__ 事件
      └─ leave_location action handler 调 LocationLeaveService.leave(ctx)
          └─ LocationLeaveService 广播 signal `location_left(from_node_id)`
              └─ ExpeditionService 监听 → 弹"下一节点选择 UI"
                  └─ 玩家选 next_node_id
                      └─ ExpeditionService.move_to(next_node_id)
                          └─ EventEngine.process_node(next_node, new_ctx)

玩家进入撤离节点
  └─ 撤离节点的事件序列正常解析（含可能的危险事件）
      └─ 末槽 slot_kind = extraction
          └─ EventEngine 解析 __sys_extraction__ 事件
              └─ extraction action handler 调 ExtractionService.settle(ctx)
                  └─ ExtractionService 广播 signal `expedition_ended(state)`
                      └─ ExpeditionService 监听 → 关历练 UI
                      └─ SaveService 监听 → 持久化结算
```

**纪律**：handler 不直接调 ExpeditionService（避免循环依赖）；走 signal 单向通知。

**与其他系统的接触面**（§6.9 解耦原则）：

| 接触系统 | 通信方式 | 内容 |
|---|---|---|
| `TimeService` | 订阅 `progress_advanced` signal；调用 `advance_progress(percent)` | 历练百分比推进；选项 cost_time_percent / 节点 time_cost_percent 调用此 API（待 ADR-0001 amendment 列入接口）|
| `EventEngine` | 调用 `resolve_event(event_id, ctx)` | 节点进入按 event_slots 顺序触发 |
| `BattleService` | 间接（EventEngine → BattleResolver） | 战斗事件触发 |
| `InventoryService` | 通过 `SectService` 写入资源 | **事件触发时**写入（战斗胜利掉落 / 拾荒事件 / 节点产物），路上即落袋；撤离时不再二次写入 |
| `SaveService` | `serialize() / deserialize()` | 进图后随时存档 |

**性能预期**：

- 1 张图 ~30 节点 + 5 撤离 = 35 节点上限，生成 < 5ms
- 全图渲染（含战雾）< 16ms
- 存档大小 < 5KB / 局

### 1.8 风险与扩展点

| 风险 | 提前安排 |
|---|---|
| **节点池产物档次没拉开** → 深处节点跟浅处节点产出差不多 → 玩家不愿深入 | 转交 GDD-06：必须做"节点池产物档次曲线"——浅层节点 LootTable 给低档资源、深层给高档；战斗事件的对手强度也按深度分层 |
| 中途撤离点过多 → 玩家不敢深入（每次见好就收）| 配表精控 preferred_layers；GDD-06 协同（深度产物档次拉开 = 撤早 = 亏） |
| 中途撤离点过少 / 位置不当 → 玩家不敢出门 | 同上；M3 后实玩反馈调 preferred_layers |
| 战雾下"看不清前方就乱走"挫败感 | fog_lookahead_layers 配置化（默认 4，看玩家反馈调）|
| 撤离点视觉跟普通节点混淆 | UI 强区分（图标 / 颜色 / 形状），借鉴用户图（普通=圆 / 中途撤=平行四边形 / 终点撤=矩形）|
| 设计师手动配 preferred_layers 配错（如全配 max_depth-1）| schema 校验：撤离点至少跨 2 个不同层，否则报错 |
| 后期有人想"给撤离点加 multiplier" | 设计哲学（§1.1）已明确禁止；任何撤离收益机制变更必须走 ADR 评审 |

**预留扩展点**（M4 / M5 实装）：

- **隐藏撤离点**：NodeTemplate 加 `visibility: visible/conditional`，特定 buff / 境界解锁
- **动态撤离点**：节点内事件后果可"召唤撤离点"（"你触发了禁制，雾气消散，你看到一条小径可立即返回"）
- **跨地图剧情链**：终点撤离 → 解锁下一张图（M5 主线）

> 注：原本占位的"撤离收益挂钩"扩展点已删除（v3 设计哲学纠偏：撤离点不放大收益，收益由路上事件本身驱动）

> v3.1 决议留痕（2026-06-02）：
> - 取消 `NodeTemplate.theme` 字段（节点风味由 display_name + icon_id 表达）
> - 危险/安全撤离点采用单池策略（`preferred_template_pool` 里模板自带风味，不拆双池），符合 §1.1 撤离设计哲学

---

## 2. 事件引擎

### 2.1 设计精神

> 用户定调（2026-06-02 v2 · 三幕模型纠偏）：
> - **选项不是事件类型**——是事件机制内部的某个时点动作
> - 每个事件分**三幕**：`before`（事件前）/ `during`（事件中）/ `after`（事件后）
> - 每幕是 **actions 列表**（按顺序执行）；actions 之间靠 **flag 系统** 联通
> - 事件之间影响：通过 flag（事件内 / 历练内）+ jump_to_event 动作
> - 用户原话举例（冰火森林·偶遇万年炎泉）：
>   - before：弹选项（在泉水中修炼 / 仔细勘察泉边 / 离开森林）
>   - during：选了"勘察"则 50% 宝物 / 10% 无 / 40% 战斗
>   - after：选了"勘察"则按火灵根值给修为 + 跳转下一事件

事件引擎的**心智模型**：

- **事件 = 一段三幕剧**（起承转合的微剧情，不是单一动作的触发器）
- **option / battle / loot / 撤离 都是 action 类型**——同一层级、自由组合，不再是事件 type
- **节点不直接触发事件**——节点的 EventSlot 按候选池抽 1 个 event_id，引擎按三幕顺序解析
- **数据驱动**——事件结构走配表（含部分用 .tres 装嵌套），引擎不写 if-else

> 这条纪律重要：BattleResolver / ExtractionService / LocationLeaveService 都是某些 action 的 handler 委派对象，**不能反过来**。任何系统想"触发一个事件"，必须通过 EventEngine.resolve_event(event_id)、走配表，不允许硬编码。

#### v1 → v2 演进留痕

v1 设计是"事件 8 种 type，按 type 分发到 handler"——这个模型已废弃。v2 翻转为"单一 EventTemplate × 三幕 actions"。  
理由：v1 不能表达"一个事件含选项 + 战斗 + 奖励"的组合（用户的炎泉例子），需要把"动作"层级降一级到事件内部。

### 2.2 事件结构（替代旧"事件类型清单"）

```gdscript
# scripts/expedition/event_template.gd
class_name EventTemplate
extends Resource

@export var event_id: String              # 全局唯一
@export var category: String              # 设计轴分类（系统耦合锚点，强制白名单见 §2.2.1）
@export var display_name_tid: String
@export var description_tid: String

@export var before_phase: EventPhase      # 可选（null = 跳过此幕）
@export var during_phase: EventPhase      # 可选
@export var after_phase: EventPhase       # 可选


# scripts/expedition/event_phase.gd
class_name EventPhase
extends Resource

@export var actions: Array[EventAction]   # 顺序执行
```

**重要约束**：

- `category` **不参与引擎分发**，但**是事件的稳定设计轴**——其它系统（幸运 / 体质 / 道具 / 难度）通过 category 接钩，详见 §2.2.1
- 三幕是**固定结构**（Q1 决议）；不允许设计师扩为 5 阶段或 mid-1/mid-2
- 三幕之间**没有特殊隔离**——共享 EventContext + flags（见 §2.6）
- 一个 phase 的 actions 可以为空（null phase 直接跳过）

#### 2.2.1 category：设计轴分类（系统耦合锚点）

> 用户定调（2026-06-02）：category 不只是 UI 标签，而是**未来系统挂钩的稳定锚点**。事件的内部 actions 可能反复迭代，但它的 category 几年内不变，这种稳定性让外部系统可以放心耦合。

**三层用途**（越往后玩法分量越重）：

| 层 | 用途 | 实际影响 |
|---|---|---|
| 元数据层 | 配表索引 / UI 图标 / 数据分析分桶 | 策划查表方便、玩家心智清晰 |
| 配置层 | 节点池可按 category 限定（"该节点只能抽 category=battle 的事件"）| 设计师精控节点风味 |
| **系统层** | 其它系统读 category 改行为 | **玩法耦合点** |

**系统层耦合的预期场景**（M3 不实装，但 schema 必须从一开始就稳）：

| 想做的扩展 | 怎么用 category |
|---|---|
| 幸运系统 | LuckService 在 `pick_candidate` 时按角色 luck 修改 category=battle 的权重 |
| 命格 / 体质 | "天煞孤星" 体质：category=encounter 出现率 -50% |
| 修仙特性 | "心魔劫期" 境界：category=story 强制必出 |
| 装备道具 | "聚宝铃" 道具：category=treasure 类的 give_loot 多滚一次 |
| 难度调节 | 低难度：category=battle 出现率 -20% |
| 成就 / 任务 | "完成 50 个 category=encounter 类事件" |

**白名单**（M3 初始 9 类，新增须走 ADR）：

| category | 语义 | 典型 actions |
|---|---|---|
| `battle` | 战斗为主体的事件 | start_battle 必含 |
| `encounter` | 路遇 NPC / 同道 / 招收 | show_options + 关系/招收相关 actions |
| `treasure` | 机缘拾宝 | give_loot / random_branch（宝物池）|
| `story` | 纯叙事 | show_text 为主，无玩法决策 |
| `trial` | 试炼 / 心境考验 | show_options + 条件分支 |
| `extraction` | 撤离整局（撤离节点末事件专用）| extraction action |
| `leave` | 离开此地（普通节点末事件专用）| leave_location action |
| `rest` | 休整 / 恢复 / 加 buff | M4+ 实装，schema 占位 |
| `quest` | 主线 / 支线节点 | M5+ 实装，schema 占位 |

**纪律**：

- schema TOML 中 category 字段为 `enum` 类型 + 上述白名单
- 烘焙时强校验，违反退出码非零
- 新增 category 必须走 ADR（影响所有挂钩系统）
- 一个事件**只能有一个 category**（防"既是 battle 又是 treasure"的语义模糊）

### 2.3 Action 类型清单

| action_type | 阶段倾向 | 描述 | M3 状态 |
|---|---|---|---|
| `show_text` | 任意 | 显示一段文本（叙事 / 描述场景）| ✅ |
| `show_options` | 通常 before | 弹选项面板，玩家选择（详见 §3）| ✅ |
| `random_branch` | 通常 during | 按权重抽分支（嵌套深度 ≤ 2）| ✅ |
| `start_battle` | 通常 during | 调用 BattleService.resolve()（ADR-0002）| ✅ |
| `give_loot` | 通常 during/after | 按 LootTable 给资源（带概率/数量范围）| ✅ |
| `give_resource` | 任意 | 直接给/扣资源。支持 `amount: int` 或 `formula: string`（用 ConditionEvaluator 求值，例 `"fire_root * 5"`）；正数=给，负数=扣 | ✅ |
| `apply_buff` | 任意 | 挂 / 解 buff（调 BuffService）| ✅ |
| `change_hp` | 任意 | 改 hp（调 InjuryService）| ✅ |
| `set_flag` | 任意 | 写 flag（事件内 / 历练内，见 §2.6）| ✅ |
| `jump_to_event` | 通常 after | 立即跳转执行另一事件，**绕过 EventSlot 候选池**（直接 resolve 目标 event_id）；目标事件以新 local namespace 进入，flag 隔离，详见 §2.6 | ✅ |
| `leave_location` | 仅 after | 离开此地（普通节点末槽对应的 `__sys_leave_location__` 系统事件 after_phase 含此 action）| ✅ |
| `extraction` | 仅 after | 撤离整局（撤离节点末槽对应的 `__sys_extraction__` 系统事件 after_phase 含此 action）| ✅ |
| `wait_months` | 任意 | M5+ 暂停 N 月再继续（事件链用）| ⏳ |
| `trigger_quest` | 任意 | M5+ 触发 / 推进任务 | ⏳ |

每种 action_type 对应一个 **ActionHandler**（实现 `execute(action, ctx)`）。引擎按 action_type 查 handler 表分发。

> 加新 action_type：写 ActionHandler 子类 → ActionRegistry.register(type, handler) → 在事件配表加该 type 的字段定义 → 烘焙 → 玩。**不需要改引擎核心**。

### 2.4 EventEngine 解析流程（核心）

```
节点进入（ExpeditionService._on_node_entered）
  └─ EventEngine.process_node(N, ctx)
      └─ for slot in N.event_slot_states:
          ┌─ slot.kind == "weighted_pool":
          │     1. 到达槽时即时过滤 candidates（按 condition_expr，可读到上一槽的副作用）
          │     2. 按 weight 抽 1 个 → event_id 或 ""
          │     3. event_id == "" → slot.resolved_event_id = "" 跳过，下一 slot
          │     4. 否则 → resolve_event(event_id, ctx)
          ├─ slot.kind == "leave_location":
          │     resolve_event("__sys_leave_location__", ctx)
          ├─ slot.kind == "extraction":
          │     resolve_event("__sys_extraction__", ctx)
          └─ 解析完 → ctx.recent_events.append(EventRecord)

resolve_event(event_id, ctx):
  # 调用栈检测（防 jump_to_event 死循环 A→B→A）
  if event_id in ctx.event_stack: 报错 "circular jump detected"
  ctx.event_stack.push(event_id)
  
  template = DataRegistry.get_event(event_id)
  ctx.enter_event(event_id)        # 创建独立事件级 flag namespace（与上层事件隔离）
  for phase in [before, during, after]:
      if phase == null: continue
      for action in phase.actions:
          # condition_expr 在到达 action 时即时估值，可读取上一 action 副作用 / 自动 flag
          if action.condition_expr != "" and not eval(action.condition_expr, ctx):
              continue
          handler = ActionRegistry.get(action.action_type)
          handler.execute(action, ctx)      # action 直接调 service 写副作用
                                            # 若是阻塞型（show_options / start_battle）则 await 玩家
  ctx.exit_event()                          # 销毁事件级 flag namespace
  ctx.event_stack.pop()
  emit signal event_resolved(event_id)
```

> **系统事件来源**：`__sys_leave_location__` 和 `__sys_extraction__` 也是**配表事件**（在事件主表里，event_id 加 `__sys_` 前缀，烘焙强校验存在）。它们的 after_phase 仅含 1 个 action（`leave_location` / `extraction`）。这样保持"事件全数据驱动"纪律——引擎不硬编码任何事件内容。策划禁修改 `__sys_*` 前缀事件。

**关键纪律**：

- **action 直接调 service**（不再走"返回 EventResult 引擎统一应用"）——颗粒细到 action 后，每个 handler 职责明确，集中应用反而绕路
- 但有 review 红线：`give_loot` handler 不能调 `BuffService`。每个 handler 可调用的 service 由 ADR / review 强制
- **阻塞型 action**：`show_options` / `start_battle` / `show_text`（如果走对话框）handler 内部 `await`；其它 action 同步执行
- **跨幕共享只通过 flags + recent_events**——never 用全局可变变量

### 2.5 EventSlot 候选池（保留 v1）

节点的 `event_slots` 仍按 §1 的方式抽事件。"无"作为合法候选不变。抽到 event_id 后送入 `resolve_event`。

```gdscript
# scripts/expedition/event_candidate.gd
class_name EventCandidate
extends Resource

@export var event_id: String          # 事件模板 id；空字符串 "" 代表"无事件"（跳过此槽）
@export var weight: int               # 抽取权重（整数，相对值）
@export var condition_expr: String    # 可选：满足条件才参与抽取
```

| 设计师想表达 | candidates 配置 |
|---|---|
| 100% 必有 | `[{event_X, 100}]` |
| 30% 战 / 20% 拾 / 50% 无（用户举例） | `[{battle_x, 30}, {loot_x, 20}, {"", 50}]` |
| 满足条件才出 | `[{X, 100, cond:"depth>=5"}, {"", 0}]` |

抽取走 `ctx.expedition_state.next_random_int(0, total_weight)`——RNG 从 ExpeditionState.seed 派生，可复现 + 派遣弟子可模拟。

> **估值时机**：candidate.condition_expr **在到达该槽时即时估值**（不是进入节点时一次性算完）。这意味着槽 N 的条件能读到槽 1 ~ N-1 的副作用（资源 / buff / hp / flag）——例如"槽 1 拾到药材后槽 2 的某个候选才能命中"是可表达的。

### 2.6 Flag 系统（M3 两层 · Q2 决议）

| 层 | 生命周期 | 写入语法（set_flag） | 读取语法（condition_expr） |
|---|---|---|---|
| **事件内**（local，默认）| `enter_event()` ~ `exit_event()` | `scope: "local", key: "choice"` | `flag('choice')` 或 `flag('local.choice')` |
| **历练内**（expedition）| ExpeditionState 期间 | `scope: "expedition", key: "<key>"` | `expedition_flag('<key>')` 或 `flag('exp.<key>')` |

**自动行为**：

某些 action 在执行后会**自动写入 local flag**——这是为了让"获取战斗结果 / 获取选项 / 获取拾荒物品"这种**运行时才能确定**的信息可以被后续 action 消费。每个 action_type 在 schema 中通过 `auto_writes_flags` 字段显式声明它写哪些 flag，**不允许隐式行为**。

**M3 自动 flag 速查表**（schema 强制声明，新增 action_type 必须填写此字段）：

| action_type | 自动写的 flag | 含义 | 后续 action 怎么用 |
|---|---|---|---|
| `show_options` | `local.choice` | 玩家选定的 option_id（字符串）| `flag('choice') == 'investigate'` |
| `start_battle` | `local.battle_won` | 战斗胜负（bool）| `flag('battle_won')` |
| `start_battle` | `local.battle_winner` | winner 枚举（ATTACKERS/DEFENDERS/DRAW/ESCAPED）| `flag('battle_winner') == 'ESCAPED'` |
| `give_loot` | `local.last_loot` | 实际滚出的物品（Dictionary）| `flag('last_loot').size() > 0` |
| `random_branch` | `local.branch_taken` | 命中的 branch_index（int，从 0 数）| `flag('branch_taken') == 0` |
| `change_hp` | `local.hp_died` | 该次扣血是否致死（bool）| `flag('hp_died')` |

**纪律**：

- 自动 flag 仅写入 `local`（事件内），事件 `exit_event()` 自动清空
- 跨事件传递信息必须用 `set_flag` 显式写 `expedition` 层
- schema TOML 中每个 action_type 必须列 `auto_writes_flags` 字段；策划写 condition_expr 时按本表查
- 事件 `exit_event()` 时**清空**所有 local flags
- **系统保留 flag key 禁止策划手写**：`choice` / `battle_won` / `battle_winner` / `last_loot` / `branch_taken` / `hp_died`——选项的 outcome_flags、set_flag action 都不允许写这些 key（烘焙静态校验）

#### 跨事件 flag 隔离规则（jump_to_event 关键语义）

`jump_to_event` 在 A.after_phase 里执行进入 B 时，A 与 B 的 local namespace **完全隔离**：

```
A.before:  local.choice = 'investigate'  ← A 的 show_options 自动写
A.during:  ...
A.after:   action[N] = jump_to_event(B)
             │
             ├─ 推 ctx.event_stack ['A', 'B']
             ├─ ctx.enter_event('B')      ← 创建新 local namespace（A 的 local 不可见）
             │   B.before / B.during / B.after 全程只能读自己的 local
             │   B 想读 A 的信息 → 只能通过 expedition 层 flag
             ├─ ctx.exit_event()           ← 清空 B 的 local
             └─ ctx.event_stack 弹回 ['A']
A.after 续: 后续 action 仍能读 A.local.choice（B 没污染）
A 末尾: ctx.exit_event() ← 清空 A 的 local
```

**纪律推论**：

- B 想要读 A 的玩家选择 / 战斗结果 → A 必须在 jump_to_event **之前**显式 `set_flag(scope=expedition, key="from_yanquan_choice", ...)`
- jump_to_event 适合"短切剧情"（如 `event_leave_forest_done`），**不适合** B 严重依赖 A 的运行态——这种情况应该用同一个事件内的多 phase / random_branch 表达，不要拆 jump




**示例**：

```yaml
during_phase:
  - action_type: random_branch
    condition_expr: "flag('choice') == 'investigate'"   # 读 local 自动写的 choice
    branches: [...]

after_phase:
  - action_type: jump_to_event
    condition_expr: "flag('exp.has_visited_yanquan')"   # 读历练内 flag
    event_id: event_yanquan_revisit
```

**M3 不实装永久 flag**（Q2 决议）；M5 可加。

### 2.7 Condition 表达式 DSL

condition_expr 是字符串，由 **ConditionEvaluator** 解析执行。

#### 2.7.1 支持的语法

```
# 字面量
'string' | 123 | 1.5 | true | false

# 比较与逻辑
==  !=  >  <  >=  <=
&&  ||  !

# 内置函数
flag(key)                          # 读 local flag
expedition_flag(key)               # 读历练 flag
has_skill(skill_id)                # 当前角色是否有此技能
realm_at_least(realm_id)           # 境界 >= X（炼气/筑基/...）
attribute(attr_name)               # 灵根值 / 五维属性
has_resource(item_id, count)       # 资源 >= count
recent_battle_won()                # ctx.recent_events 最近一战赢了
choice() == 'xxx'                  # flag('choice') 的语法糖
```

#### 2.7.2 不支持

- 任意 GDScript 表达式（防注入）
- 函数嵌套调用超过 2 层（防复杂度爆炸）
- 副作用函数（不能在 condition 里写 flag / 改 state）

#### 2.7.3 语法举例

```
"flag('choice') == 'investigate'"
"has_skill('fire') && realm_at_least('foundation')"
"attribute('fire_root') >= 50 && !flag('exp.cursed')"
"recent_battle_won() && has_resource('spirit_stone', 10)"
```

M3 实装递归下降解析器（约 200 行 GDScript）。M5 可扩到完整表达式树。

### 2.8 RandomBranch 规则（Q3 决议 · 嵌套深度 2）

```gdscript
class_name RandomBranchAction
extends EventAction
# action_type = "random_branch"

@export var condition_expr: String        # 整个 random_branch 是否执行
@export var branches: Array[BranchEntry]


class_name BranchEntry
extends Resource

@export var weight: int                   # 抽取权重
@export var actions: Array[EventAction]   # 命中后顺序执行
```

**嵌套约束**（烘焙时静态校验）：

- 外层 random_branch 的 branch.actions 内**允许**再有一个 random_branch（深度 2）
- 深度 2 的 branch.actions 内**禁止**再有 random_branch（违反 → 烘焙报错 `random_branch nesting depth > 2`）
- 复杂场景需要"深度 3+" 时，应拆成多个事件 + flag + jump_to_event

**为什么深度 2 够用**：修仙世界事件复杂度上限 ≈ "先大类后细类"两层；3+ 层基本是事件链结构（拆成多事件更可读）。

### 2.9 数据驱动落地（xlsx 多表 → .tres 烘焙）

> 用户定调（2026-06-02 v2 · 范式一致性）：所有设计端配置必须用 xlsx，烘焙脚本生成 .tres 给运行时读。**事件配置不在配表范式之外另起炉灶**（撤回 v1 的"嵌套结构用 .tres 直接编辑"混合策略）。

#### 2.9.1 xlsx 多表结构（策划主入口）

事件三幕嵌套深，但靠 **`<entity>_id` 引用链** 把嵌套展开为多张扁平表，每张表都符合配表范式 v1.0：

```
data/table/事件/
├─ 事件主表.xlsx              ← Sheet1 主表 / Sheet2 阶段索引
├─ 事件动作表.xlsx            ← Sheet1 动作主表 / Sheet2 动作扩展（按 type 拆字段）
├─ 事件选项表.xlsx            ← 选项明细
├─ 随机分支表.xlsx            ← random_branch 的分支明细
├─ 事件资源表.xlsx            ← Sheet1 LootTable / Sheet2 战斗模板 / Sheet3 候选池
└─ proto/event_system.schema.toml
```

**各表字段（关键列）**：

`事件主表 / Sheet "EventTemplate"`：

| 列 | type | 说明 |
|---|---|---|
| event_id | pkey | 全局唯一 |
| category | enum | §2.2.1 白名单 |
| display_name_tid | tid | 中文名 |
| description_tid | tid | 长描述 |
| before_phase_id | fkey | → 事件阶段表.phase_id（可空 = 跳过此幕）|
| during_phase_id | fkey | 同上 |
| after_phase_id | fkey | 同上 |

`事件主表 / Sheet "EventPhase"`：

| 列 | type | 说明 |
|---|---|---|
| phase_id | pkey | 阶段 id（可被多事件复用，也被 random_branch 的 sub_phase 引用） |
| description | string | 备注用 |

`事件动作表 / Sheet "EventAction"`：

| 列 | type | 说明 |
|---|---|---|
| action_id | pkey | 动作 id |
| phase_id | fkey | → EventPhase.phase_id（动作归属哪个阶段）|
| order | int | 同 phase 内的执行顺序（升序）|
| action_type | enum | §2.3 action 清单 |
| condition_expr | string | 可空，不满足则跳过该 action |
| param1..param5 | dynamic | 按 action_type 反查类型（参考 BUFF 配表的"变长参数槽"范式）|

`事件动作表 / Sheet "EventActionExt"`（少数 action 字段过多时溢出到此）：

| 列 | type | 说明 |
|---|---|---|
| action_id | fkey | → EventAction.action_id |
| field_key | string | 字段名 |
| field_value | string | 字段值（按 schema 解析）|

> 例：`show_options` 的 `prompt_tid` / `auto_pick_if_only_one` / `no_options_fallback_flag` 在 param1-3；options 数组靠**外键引用** option 表（field_key="options_table_id"），不直接塞 param。

`事件选项表 / Sheet "OptionDef"`：

| 列 | type | 说明 |
|---|---|---|
| option_table_id | string | 一组选项的容器 id（被某个 show_options action 引用）|
| option_id | string | 选项 id（事件内唯一即可）|
| order | int | 显示顺序 |
| text_tid | tid | 选项文本 |
| description_tid | tid | hover 长描述（可空）|
| condition_show | string | 不满足则隐藏 |
| condition_enable | string | 不满足则置灰 |
| cost_resources | string | JSON 字符串 `{"spirit_stone":10}` 或 csv `spirit_stone:10,herb:1` |
| cost_hp | int | 选项扣血 |
| cost_time_percent | int | 选项消耗历练百分比 |
| outcome_flags | string | csv `key:value,key:value` |

> `(option_table_id, option_id)` 复合主键。schema 校验：每个 option_table_id 下 ≤5 个 option。

`随机分支表 / Sheet "RandomBranch"`：

| 列 | type | 说明 |
|---|---|---|
| branch_table_id | string | 一组分支的容器 id（被某个 random_branch action 引用）|
| branch_index | int | 分支序号 |
| weight | int | 抽取权重 |
| sub_phase_id | fkey | → EventPhase.phase_id（命中后执行的子阶段）|

> 嵌套深度通过引用链表达：random_branch 的 sub_phase_id 指向另一个 phase，该 phase 内可再有 random_branch（深度 2，烘焙静态校验拒绝深度 3）。

`事件资源表 / Sheet "EventCandidate"`：

| 列 | type | 说明 |
|---|---|---|
| candidate_pool_id | string | 候选池 id（被节点的 event_slots 引用）|
| event_id | fkey | → EventTemplate.event_id；空字符串 "" 代表"无事件" |
| weight | int | 抽取权重 |
| condition_expr | string | 可空 |

`事件资源表 / Sheet "LootTable"`：被 give_loot action 通过 loot_table_id 引用（详细字段 GDD-06 平衡章节定义）。

`事件资源表 / Sheet "BattleTemplate"`：被 start_battle action 通过 battle_template_id 引用（详细字段 §6 战斗章节定义）。

#### 2.9.2 schema TOML（强约束）

`data/table/proto/event_system.schema.toml` 关键约束：

- `EventTemplate.category` = enum + §2.2.1 9 类白名单
- `EventAction.action_type` = enum + §2.3 action 清单
- `EventAction.param1..5` = dynamic + type_resolver `EventActionTypeMap[{action_type}].param{N}_type`（同 BUFF 范式）
- 主键 / 外键 / 跨字段约束（`applies_when`）全部走 schema 强校验

**烘焙时校验**（失败退出码非零）：

| 校验项 | 例 |
|---|---|
| 主外键完整 | EventTemplate.before_phase_id 必须存在于 EventPhase |
| category 白名单 | 不在 9 类内拒绝 |
| 选项数 ≤5 | option_table_id 下条数超 5 拒绝 |
| 候选池权重正数 | weight ≤ 0 拒绝 |
| random_branch 嵌套深度 ≤2 | 深度遍历 phase 引用链 |
| jump_to_event 目标存在 | param 中的 event_id 必须存在 |
| auto_writes_flags 一致 | 每个 action_type 必须在 schema 中显式列出（详见 §2.6）|
| condition_expr 解析通过 | 烘焙时调用 ConditionEvaluator 干跑解析（不求值，仅语法检查）|

#### 2.9.3 烘焙产物（运行时格式）

```
data/baked/events/
├─ event_template.tres        ← 全部 EventTemplate 索引（Dictionary[event_id]→EventTemplate）
├─ event_phase.tres           ← 全部 EventPhase 索引
├─ event_action.tres          ← 全部 EventAction 索引（按 phase_id 分组）
├─ option_def.tres            ← 选项索引（按 option_table_id 分组）
├─ random_branch.tres         ← 分支索引
└─ event_candidate.tres       ← 候选池索引
```

DataRegistry 启动时加载这 6 个 .tres 到内存，按 `event_id` / `phase_id` / `action_id` 等做 O(1) 查询。运行时拼装树形结构（EventTemplate → 三个 phase → 各自 actions → 嵌套 options/branches）通过引用链动态完成。

#### 2.9.4 为什么不是混合策略

历史上我（v1 草案）推过"事件主表用 xlsx + 三幕嵌套用 .tres 让 Godot Inspector 编辑"的混合方案。已撤回，理由：

| 维度 | 混合策略劣势 |
|---|---|
| 范式一致性 | 工作室通用范式 v1.0 已定"源表只能 xlsx"。开特例 → 范式溃堤 |
| 协作工具 | 改 .tres 必须开 Godot Inspector，没装 Godot 的策划无法改事件 |
| 校验集中度 | xlsx 多表全部走烘焙脚本统一校验；.tres 散开后校验路径分裂 |
| 配表范式延续性 | 配表范式 v1.0 在 BUFF 表证明"扁平多表 + 引用链 + 变长 param"能表达任意嵌套结构 |

**M3 配套工具**（M3 中后期实装，不阻塞 §2 落地）：事件配表脚手架——填写 event_id 自动生成 EventPhase / EventAction 关联表骨架行，降低多表填写心智负担。

#### 2.9.5 M3 必填

约 20-30 个事件，覆盖 qiyun_valley 地图节点池。分类（约）：

- battle：8-10 个
- encounter：3-5 个
- treasure：5-8 个
- story：3-5 个
- trial：2-3 个
- extraction / leave：每个撤离 / 普通节点末事件配 1 个



### 2.10 实现要点（M3）

| 组件 | 路径 | 责任 |
|---|---|---|
| `EventEngine` | `game/scripts/expedition/event_engine.gd`（autoload）| process_node / resolve_event / 三幕解析 |
| `ActionRegistry` | `game/scripts/expedition/action_registry.gd` | action_type → ActionHandler 映射 |
| `ActionHandler` | `game/scripts/expedition/actions/action_handler.gd`（接口）| 抽象基类 `execute(action, ctx)` |
| 12 个具体 ActionHandler | `actions/<action_type>_handler.gd` | 每个 action_type 一个，调对应 service |
| `FlagStore` | `game/scripts/expedition/flag_store.gd` | 维护 local / expedition flags + namespace 隔离 |
| `ConditionEvaluator` | `game/scripts/expedition/condition_evaluator.gd` | 表达式解析与求值（递归下降）|
| `EventContext` | `game/scripts/expedition/event_context.gd` | 运行态上下文：current_node / current_slot_index / recent_events / flag_store / expedition_state / **actor**（当前在场角色，M3=主角，M4 派遣时=该弟子）/ event_stack（jump_to_event 调用栈）|

**与其他系统的接触面**：

| 接触系统 | 通信方式 | 触发 action |
|---|---|---|
| `BattleService` | `start_battle` handler 调 `BattleService.resolve()` | start_battle |
| `InventoryService` | `give_loot` / `give_resource` handler 调 add/sub | give_loot / give_resource |
| `BuffService` | `apply_buff` handler 调 `apply_by_id()` | apply_buff |
| `InjuryService` | `change_hp` handler 调 | change_hp |
| `ExtractionService` | `extraction` handler 调 | extraction |
| `LocationLeaveService` | `leave_location` handler 调 | leave_location |
| `EventBus` | broadcast `event_resolved` | 解析完后 |
| `DataRegistry` | 启动时一次 load | 读 EventTemplate 表 + .tres 索引 |

### 2.11 风险与扩展点

| 风险 | 提前安排 |
|---|---|
| 嵌套深度突破 2 | 烘焙静态校验，违反退出码非零 |
| flag 命名冲突 | local flag 自动加事件 id 前缀做 namespace；exp.* 全局共享但要求 key 含模块前缀 |
| condition_expr DSL 注入风险 | 仅支持白名单函数 + 字面量 + 比较/逻辑运算；禁任意 GDScript eval |
| ActionHandler 越权调 service | review 红线 + 编码约定（每个 handler 文档明确 allowed services）|
| jump_to_event 死循环（A→B→A）| EventEngine 跟踪当前调用栈，检测同 event_id 二次进入即报错 |
| 事件用 .tres 散开后 diff 不友好 | .tres 文本格式（非 binary），git diff 可读；CI 校验所有 .tres 通过 schema |
| recent_events 跨节点泄漏 | 节点切换时 ctx.recent_events.clear() |

**预留扩展点**（M4 / M5）：

- **永久 flag**（M5）：scope=permanent，写入 SaveService，跨局保留。给主线 / 成就 / 角色记忆用
- **事件链 wait_months**（M5）：事件 after_phase 包含 `wait_months(N)` action，引擎挂起、N 月后由 TimeService 信号唤醒触发 follow-up
- **嵌套事件**（M5）：`jump_to_event` 不再是简单跳转，而是"先暂停当前事件，跑完跳转目标，再继续"——递归调用栈
- **condition 函数库**（M5）：扩 `relation_with(npc_id) >= 'friend'` / `weather() == 'rainy'` 等

---

## 3. 选项与后果 DSL

### 3.1 设计精神

`show_options` 是 §2.3 action 清单中**最重的一个**——它阻塞玩家、决定后续走向、消费资源、启用条件门。本节把它单独展开。

> 用户原话定调（2026-06-02）：
> - 选项可有**资源成本**（cost），消耗灵石 / 时间 / hp 等（Q4 决议 M3 实装）
> - 选项有**显示条件 + 启用条件**（前置不满足时隐藏，资源不足时置灰）
> - 选项后果 = 写 flag（local.choice = option_id）+ 自动扣 cost + 可选额外 flag

设计原则：

- **选项数量 ≤ 5**（schema 校验，UI 强约束）
- **选项的"后果"在选项之外表达**——不是在选项数据里写 reward，而是后续 actions 用 `flag('choice') == 'X'` 走分支
- **资源成本前置扣除**（玩家选定即扣，不允许"选了再判定不够"）

### 3.2 数据结构

```gdscript
# scripts/expedition/actions/show_options_action.gd
class_name ShowOptionsAction
extends EventAction
# action_type = "show_options"

@export var prompt_tid: String                 # 选项面板顶部提示文本
@export var options: Array[OptionDef]          # 1-5 个
@export var auto_pick_if_only_one: bool        # 仅有 1 项可选时自动选（不弹 UI）
@export var no_options_fallback_flag: String   # 全部选项都不可选时（condition_show 全失败），写此 flag


# scripts/expedition/option_def.gd
class_name OptionDef
extends Resource

@export var option_id: String                  # 选项 id（被自动写入 flag 'choice'）
@export var text_tid: String                   # 选项文本（中文）
@export var description_tid: String            # 选项 hover 长描述（可空）

@export var condition_show: String             # 不满足则**隐藏**该选项（表达"前置不达"）
@export var condition_enable: String           # 不满足则**置灰**该选项（表达"暂时不能选"）

@export var cost: ResourceCost                 # 资源消耗（可空）

@export var outcome_flags: Dictionary          # 选定后写入的额外 local flag {"key": "value"}
                                               # 默认会自动写 local.choice = option_id
                                               # 禁止写系统保留 key（choice / battle_won / battle_winner / last_loot / branch_taken / hp_died）
                                               # 烘焙时静态校验，违反退出码非零


# scripts/expedition/resource_cost.gd
class_name ResourceCost
extends Resource

@export var resources: Dictionary              # {"spirit_stone": 10, "herb_a": 1}
@export var hp: int = 0                        # 选项消耗 hp（>0 = 扣血）
@export var time_percent: int = 0              # 选项消耗历练百分比（>0 = 推进时钟）
```

### 3.3 选项面板 UI 规则

```
┌─ Prompt 文本 ──────────────────────────────┐
│  「面前是一汪沸腾的炎泉，热气蒸腾……」          │
├─────────────────────────────────────────┤
│  ▶ 在泉水中修炼  [需筑基期·火灵根] [-10%时间]  │  ← condition_show 满足 + condition_enable 满足，可点
│  ▶ 仔细勘察泉边                              │  ← 默认无条件，可点
│  ▶ 离开森林                                  │
│  ▶ ~~付灵石请同道帮忙(消耗灵石100)~~  [灵石不足] │  ← condition_enable 不满足，置灰
│                                             │  （condition_show 不满足的选项**完全不显示**）
└─────────────────────────────────────────┘
```

**显示规则**：

| condition_show | condition_enable + cost | 渲染 |
|---|---|---|
| 不满足 | — | **完全隐藏** |
| 满足 | 不满足 / cost 不足 | **置灰**，hover 显示原因 |
| 满足 | 满足 + cost 够 | 正常可点 |

**特殊情况**：

- 所有选项都 condition_show 不满足 → 写 `no_options_fallback_flag`，跳过此 action
- `auto_pick_if_only_one=true` 且仅有 1 项可选 → 不弹 UI，直接选

### 3.4 玩家选定后的流程

```gdscript
func on_option_picked(option: OptionDef, ctx: EventContext):
    # 1. 二次校验（防作弊；UI 已置灰过）
    assert(_check_show(option, ctx))
    assert(_check_enable(option, ctx))
    assert(_check_cost(option, ctx))
    
    # 2. 扣资源（先扣再写 flag，扣失败回滚不进 flag）
    InventoryService.consume(option.cost.resources)
    if option.cost.hp > 0:
        InjuryService.change_hp(ctx.actor, -option.cost.hp)
    if option.cost.time_percent > 0:
        TimeService.advance_progress(option.cost.time_percent)   # 接口待 ADR-0001 amendment 确认
    
    # 3. 写 flag（注意：option_id 自动写 local.choice；outcome_flags 仅允许写非保留 key）
    ctx.flag_store.set_local("choice", option.option_id)
    for k in option.outcome_flags:
        ctx.flag_store.set_local(k, option.outcome_flags[k])
    
    # 4. show_options action 完成，引擎进入下一 action
```

### 3.5 完整例子：偶遇万年炎泉（用户原案例 · xlsx 多表填法）

按 §2.9.1 的 xlsx 多表结构落地"冰火森林·偶遇万年炎泉"事件。下面是策划在每张表填什么。

#### 3.5.1 事件主表.xlsx

`Sheet "EventTemplate"`：

| event_id | category | display_name_tid | description_tid | before_phase_id | during_phase_id | after_phase_id |
|---|---|---|---|---|---|---|
| event_yuyu_yanquan | encounter | Text_event_yuyu_yanquan | Text_event_yuyu_yanquan_desc | yanquan_before | yanquan_during | yanquan_after |

`Sheet "EventPhase"`：

| phase_id | description |
|---|---|
| yanquan_before | 炎泉 · 起势（叙事 + 选项）|
| yanquan_during | 炎泉 · 主体（按选择走分支）|
| yanquan_after | 炎泉 · 收尾（按选择给奖励 + leave）|
| yanquan_inv_treasure | 勘察分支 · 获得宝物 |
| yanquan_inv_nothing | 勘察分支 · 一无所获 |
| yanquan_inv_battle | 勘察分支 · 触发战斗 |

#### 3.5.2 事件动作表.xlsx

`Sheet "EventAction"`（按 phase 分组排列方便查阅，order 控制顺序）：

| action_id | phase_id | order | action_type | condition_expr | param1 | param2 | param3 |
|---|---|---|---|---|---|---|---|
| a_yyq_intro | yanquan_before | 0 | show_text |  | Text_event_yuyu_yanquan_intro |  |  |
| a_yyq_options | yanquan_before | 1 | show_options |  | Text_yuyu_prompt | yyq_opt_pool | false |
| a_yyq_branch | yanquan_during | 0 | random_branch | flag('choice') == 'investigate' | yyq_branch_pool |  |  |
| a_yyq_cult_text | yanquan_during | 1 | show_text | flag('choice') == 'cultivate' | Text_cultivate_in_yanquan |  |  |
| a_yyq_inv_reward | yanquan_after | 0 | give_resource | flag('choice') == 'investigate' | cultivation_progress | fire_root * 5 |  |
| a_yyq_cult_reward | yanquan_after | 1 | give_resource | flag('choice') == 'cultivate' | cultivation_progress | fire_root * 12 |  |
| a_yyq_leave_jump | yanquan_after | 2 | jump_to_event | flag('choice') == 'leave' | event_leave_forest_done |  |  |
| a_yyq_leave_loc | yanquan_after | 3 | leave_location |  |  |  |  |
| a_yyq_b_loot | yanquan_inv_treasure | 0 | give_loot |  | yanquan_treasure_pool |  |  |
| a_yyq_b_nothing | yanquan_inv_nothing | 0 | show_text |  | Text_yuyu_nothing |  |  |
| a_yyq_b_battle | yanquan_inv_battle | 0 | start_battle |  | battle_fire_spirit_beast |  |  |

> param 列按 schema 的 `EventActionTypeMap[{action_type}]` 反查类型。例：`show_options` 的 param1=prompt_tid (tid) / param2=options_table_id (string) / param3=auto_pick_if_only_one (bool)；`random_branch` 的 param1=branches_table_id (string)。

#### 3.5.3 事件选项表.xlsx

`Sheet "OptionDef"`（option_table_id = `yyq_opt_pool`）：

| option_table_id | option_id | order | text_tid | condition_show | condition_enable | cost_resources | cost_hp | cost_time_percent | outcome_flags |
|---|---|---|---|---|---|---|---|---|---|
| yyq_opt_pool | cultivate | 0 | Text_option_cultivate_in_spring | has_skill('fire') && realm_at_least('foundation') |  |  | 0 | 10 |  |
| yyq_opt_pool | investigate | 1 | Text_option_investigate |  |  |  | 0 | 0 |  |
| yyq_opt_pool | leave | 2 | Text_option_leave_forest |  |  |  | 0 | 0 |  |

#### 3.5.4 随机分支表.xlsx

`Sheet "RandomBranch"`（branch_table_id = `yyq_branch_pool`）：

| branch_table_id | branch_index | weight | sub_phase_id |
|---|---|---|---|
| yyq_branch_pool | 0 | 50 | yanquan_inv_treasure |
| yyq_branch_pool | 1 | 10 | yanquan_inv_nothing |
| yyq_branch_pool | 2 | 40 | yanquan_inv_battle |

#### 3.5.5 事件资源表.xlsx

被本事件引用的资源条目（仅列出本事件用到的）：

`Sheet "LootTable"` → `yanquan_treasure_pool`（具体物品池配置见 GDD-06）  
`Sheet "BattleTemplate"` → `battle_fire_spirit_beast`（具体怪物组配置见 §6）  
`Sheet "EventCandidate"` → 例如某节点的 `event_slot_pool_yyq_zone` 把 `event_yuyu_yanquan` 加入候选池

#### 3.5.6 这个例子展示了什么

- 选项的 condition_show（cultivate 需筑基 + 火灵根）→ 选项表第 1 行
- 选项的 cost（cultivate 消耗 10% 历练时间）→ 选项表 cost_time_percent 列
- 三幕之间靠 `flag('choice')` 联通 → 动作表的 condition_expr 列
- random_branch 的实战配置（深度 1 完全够用）→ 随机分支表 + 子 phase
- after_phase 的多 action 条件分支（按 choice 给不同奖励）→ 动作表 a_yyq_inv_reward / a_yyq_cult_reward / a_yyq_leave_jump
- 末尾的 `leave_location` 让玩家回到地图层选下一节点 → 动作表 a_yyq_leave_loc

#### 3.5.7 烘焙后产物（参考 · 程序员视角）

事件烘焙后会变成 Godot 的 .tres 文本格式资源（运行时直接 `load()`）。**策划永远不直接面对此格式**，仅作 review / debug 参考。完整产物示例见**附录 A**。



### 3.6 实现要点（M3）

| 组件 | 路径 | 责任 |
|---|---|---|
| `ShowOptionsHandler` | `actions/show_options_handler.gd` | 解析 OptionDef 数组，过滤 → 调 UI → await 玩家点击 |
| `OptionPanelUI` | `game/scripts/ui/option_panel.gd` | 渲染面板，处理 hover/click，置灰逻辑 |
| `ResourceCostChecker` | `game/scripts/expedition/cost_checker.gd` | 二次校验 cost 是否足够 |
| `OptionEvaluator` | 复用 `ConditionEvaluator` | 评估 condition_show / condition_enable |

### 3.7 风险与扩展点

| 风险 | 提前安排 |
|---|---|
| 选项过多 UI 难看 / 玩家选择疲劳 | schema 校验 `options.size() <= 5` |
| 所有选项 condition_show 都失败 → 卡死 | `no_options_fallback_flag` 兜底 + 引擎检测 0 可见选项时强制跳过 |
| cost 多种资源时 UI 显示挤 | UI 规范：cost 主资源只显 1 项，hover 展开全部 |
| 玩家选定后中途死亡 / 撤离 | flag 不回滚（决策已成事实）；后续 actions 按 condition 自然跳过 |
| outcome_flags 滥用导致跨事件耦合失控 | review 红线：outcome_flags 只允许写 local；写 expedition 必须用 set_flag action 显式 |

**预留扩展点**（M4 / M5）：

- **选项的 outcome 含立即触发某 action**（M5）：`outcome_actions: Array[EventAction]`——选定即执行，比 jump_to_event 更紧凑
- **选项的"看似可选实则陷阱"**（M5）：`hidden_consequences` 让 condition_show 通过但选了之后才暴露后果（适合"假秘籍"等剧情）
- **选项的境界 / 灵根特化文本**（M5）：text_tid_override 按角色属性显示不同文案
- **选项历史记录**（M5）：写永久 flag，主线"你曾选过 X"

---

## 4. 撤离与超时机制

### 4.1 设计精神

§1 已经把"撤离"作为**主动决策**讲透——玩家走到撤离节点触发 `__sys_extraction__`。但一局历练并非只有"主动撤离"一种结局，还有两种**被动结局**需要处理：

| 结局 | 触发条件 | 玩家心智 |
|---|---|---|
| **主动撤离** | 走到撤离节点 | "我决定回家" |
| **超时强撤** | 历练百分比内层时钟耗尽 | "我磨蹭太久了，被迫回家" |
| **团灭收容** | 在场角色全员 hp=0 | "我被打败了，被宗门接回去" |

> 设计哲学（v3 贯穿）：**三种结局都遵循"路上落袋资源原样返回"原则**——超时和团灭**不额外扣资源**。区别只在于：
> - 超时 / 团灭会带回**伤势 buff**（GDD-04 §7 Buff 库挂"严重虚弱"等）
> - 超时 / 团灭后宗门日历推进的"回宗时间"更长（GDD-06 平衡数值）
> - 触发的事件钩子（成就 / 主线）不同

这条哲学避免了"撤离哲学"在边界情况被破坏：玩家不会因为"我打不过 boss 团灭了"就比"我撑到撤离点"亏得多——亏的是**时间和健康**，不是物质资源。

### 4.2 三个系统事件（与 §1 撤离对偶）

§2.4 已定义 `__sys_extraction__` / `__sys_leave_location__` 两个系统事件。本节再加 2 个：

| 系统事件 id | 触发方式 | after_phase 主要 action |
|---|---|---|
| `__sys_extraction__` | 撤离节点末槽 / 玩家主动 | `extraction(reason="active")` |
| `__sys_timeout__` | 时钟耗尽自动触发 | `extraction(reason="timeout")` + `apply_buff` 伤势 |
| `__sys_defeat__` | 全员 hp=0 自动触发 | `extraction(reason="defeat")` + `apply_buff` 重伤 |
| `__sys_leave_location__` | 普通节点末槽 | `leave_location` |

> **统一接口**：3 种结束历练的事件**最终都调 `extraction` action**，只是 reason 不同。ExtractionService 按 reason 路由不同收尾流程（伤势 buff / 回宗时间 / 钩子）。这跟"撤离机制纯粹"哲学一致——结束逻辑收敛在一个 action handler。

### 4.3 超时机制

#### 4.3.1 时钟来源与触发

历练内层时钟由 ADR-0001 双层时钟定义。`ExpeditionState.time_remaining_percent` 由 TimeService 推进：

- 进入节点：扣 `NodeTemplate.time_cost_percent`
- 选项消耗：扣 `OptionDef.cost.time_percent`（§3.4）
- 战斗 / 拾荒 / 叙事事件按动作消耗（具体值 GDD-06 平衡）

**触发时机**：

```
TimeService.advance_progress(amount)  ─┐
  └─ ExpeditionState.time_remaining_percent -= amount
      └─ 检查：if time_remaining_percent <= 0 → 标记 timeout_pending = true
                （不立即触发，等当前 action 跑完）

EventEngine 在每个 action 执行后检查 ctx.expedition_state.timeout_pending：
  └─ 若为 true 且当前不在阻塞型 action 内：
      └─ 中断当前事件序列
      └─ EventEngine.resolve_event("__sys_timeout__", ctx)
```

#### 4.3.2 不立即中断的原因

如果 time 在事件中途归零，**不允许打断阻塞型 action**：

| 阻塞型 action | 不打断的理由 |
|---|---|
| `show_options` | 玩家正在做决策，强行关 UI 体验差 |
| `start_battle` | 战斗中途强制结束破坏战斗逻辑 |
| `show_text` | 玩家正在读，可以等 |

**设计**：超时触发**总在 action 边界**，玩家"在事件中途就看到时钟见红"是 UI 提示，不是中断。事件跑完才结算超时。

#### 4.3.3 警告 UI 阈值

| 字段 | 配在哪 | 默认值 |
|---|---|---|
| `time_warning_threshold_percent` | ExpeditionMap | 30（剩余 30% 时弹一次警告）|
| `time_critical_threshold_percent` | ExpeditionMap | 10（剩余 10% 时弹"立即撤离"提示，UI 闪红）|

阈值只触发提示 signal（`expedition_time_warning` / `expedition_time_critical`），不影响玩法。

### 4.4 团灭机制

#### 4.4.1 触发条件

`ExpeditionState.actors_alive_count == 0`（M3 单人 = 主角 hp=0；M4+ 全队角色 hp=0）。

**写入时机**：

- `BattleResolver` 返回 `BattleResult.winner == DEFENDERS` 且 actor hp 已为 0 → BuffService/InjuryService 写 hp=0 → ExpeditionState 监听后标记 `defeat_pending`
- `change_hp` action 写 hp ≤ 0 → 同上

```
任何写 hp 到 0 的路径
  └─ InjuryService.set_hp(actor, 0)
      └─ broadcast signal `actor_defeated(actor)`
          └─ ExpeditionState 监听：
              └─ if actors_alive_count == 0:
                  └─ defeat_pending = true
```

EventEngine 在 action 边界检查 `defeat_pending` 同 timeout（4.3.1 一样的机制），优先级高于 timeout（同时触发时只走 defeat）。

#### 4.4.2 与角色状态机的关系

GDD-02 §6 角色状态机定义角色不会真死。M3 团灭走"重伤"分支：

- 触发 `__sys_defeat__` 系统事件
- 该事件 after_phase 含 `apply_buff(buff_id="severe_injury", target=all_actors)`
- 然后 `extraction(reason="defeat")`
- 回宗后 GDD-02 §6 的状态机自动转入"调养中"

战斗 ESCAPED 不算团灭——逃跑玩家仍然 hp>0，事件序列继续（§1.1 三概念表）。

### 4.5 撤离结算流程（统一入口）

`extraction` action handler 调 `ExtractionService.settle(ctx, reason)`：

```gdscript
func settle(ctx: EventContext, reason: String) -> void:
    # reason: "active" / "timeout" / "defeat"
    
    # 1. 固化路上落袋资源（实际上路上已经写 InventoryService 了，这里只 commit 不再加扣）
    SaveService.commit_inventory_to_persistent()
    
    # 2. 按 reason 应用伤势 buff（数据驱动，配在事件 after_phase 的 apply_buff action 里，不在 service 硬编码）
    #    M3 三种 reason 的事件都已配好 apply_buff，service 不重复处理
    
    # 3. 应用回宗时间（外层时钟推进）
    var return_days = _compute_return_days(reason, ctx.expedition_state.current_depth)
    TimeService.advance_outer(return_days)
    
    # 4. 广播 signal
    EventBus.emit("expedition_ended", {
        "map_id": ctx.expedition_state.map_id,
        "reason": reason,
        "depth_reached": ctx.expedition_state.current_depth,
        "visited_nodes": ctx.expedition_state.visited_node_ids.size(),
        "elapsed_percent": 100 - ctx.expedition_state.time_remaining_percent
    })
    
    # 5. 关闭 ExpeditionState
    ExpeditionService.close_state()
```

**关键纪律**：

- `settle` 是**幂等的**——重复触发只生效一次（防 timeout 和 defeat 同时触发）
- service 不读资源、不算倍率（v3 撤离设计哲学）
- 伤势 buff / 回宗时间这些**结局差异化的玩法效果**走配表（事件 after_phase 的 actions），不在 service 硬编码

### 4.6 边界情况清单

| 情况 | 处理 |
|---|---|
| 玩家在到达撤离节点的**同一时刻**时钟归零 | 优先级：撤离节点 > 超时（玩家走到了就算成功撤离）|
| 玩家在战斗中**逃跑**（ESCAPED）后时钟归零 | 战斗结束、ESCAPED 写 flag、当前事件继续 → action 边界检查 timeout → 触发 `__sys_timeout__` |
| 战斗中击败对手但 hp 也归零（同归于尽） | winner=ATTACKERS 但 actor hp=0 → 战斗结束后 actor_defeated signal → 标记 defeat_pending → action 边界触发 `__sys_defeat__`（优先于胜利后的 give_loot 等 actions）|
| 玩家选了消耗资源的选项后资源不足以继续 | 选项 cost 已前置扣除（§3.4），不会出现\"扣到负\"。其它资源不足靠 condition_enable 置灰 |
| 进入战斗时主角 hp 已经很低，战前 condition 没拦住 | M3 假设战斗事件 condition 已包含 hp 检查；不拦住团灭也是合法结局 |
| 存档加载到事件中途 | 序列化粒度 = 节点边界，**不存档事件中途**（§4.7）|
| 同时触发 timeout 和 defeat | defeat 优先（玩家死了再算超时没意义）|
| 玩家在撤离节点的危险事件序列中团灭 | 触发 `__sys_defeat__`，**不再**触发该撤离节点末槽的 `__sys_extraction__`（defeat 路径直接结算）|

### 4.7 存档粒度（与 SaveService 配合）

> 详细设计在 GDD-07 存档系统，本节只列与历练相关的**粒度纪律**：

- **存档点**：节点切换前后（`location_left` signal 时）+ 撤离结算后
- **不存档**：事件中途（show_options 阻塞、战斗中途）—— 玩家中途退游戏，下次进入回到**当前节点的最近一次稳定状态**
- **理由**：事件中途有阻塞型 action 等待玩家输入，序列化交互态非常复杂；节点边界存档使重进体验"重做当前节点"，可接受

### 4.8 配表落地

```
data/table/历练地图.xlsx
└─ Sheet "时钟配置"  → 时间警告阈值 / 团灭回宗惩罚天数 / 三种 reason 各自 return_days

data/table/事件/事件主表.xlsx
└─ 3 个系统事件配置：
   __sys_extraction__   after: extraction(reason="active")
   __sys_timeout__      after: apply_buff(severe_fatigue) → extraction(reason="timeout")
   __sys_defeat__       after: apply_buff(severe_injury) → extraction(reason="defeat")
```

**M3 必填**：

- 系统事件 3 条
- 伤势 buff 2 个（`severe_fatigue` 超时疲劳、`severe_injury` 严重伤势）—— 走 GDD-04 §7 Buff 库（继承 GDD-02 §7 buff 类型清单）
- 回宗天数表：active=1d / timeout=3d / defeat=7d（GDD-06 平衡可调）

### 4.9 实现要点（M3）

| 组件 | 路径 | 责任 |
|---|---|---|
| `ExtractionService` | （已在 §1.7） | 新增 `settle(ctx, reason)` API；幂等保护 |
| `TimeoutWatcher` | `game/scripts/expedition/timeout_watcher.gd` | 监听 TimeService.progress_advanced 标记 timeout_pending |
| `DefeatWatcher` | `game/scripts/expedition/defeat_watcher.gd` | 监听 InjuryService.actor_defeated 标记 defeat_pending |
| `EventEngine` | （已在 §2.10）| 在每个 action 边界检查 ctx 标记，触发对应系统事件 |

**与其他系统接触面**：

| 接触系统 | 通信方式 | 内容 |
|---|---|---|
| `TimeService` | advance_progress / advance_outer | 内层（历练百分比）/ 外层（宗门日历）推进 |
| `InjuryService` | broadcast `actor_defeated` | hp 归零时通知 |
| `BuffService` | apply 伤势 buff | 通过事件 after_phase 的 apply_buff action 调 |
| `SaveService` | commit_inventory_to_persistent | 撤离结算时持久化 |

### 4.10 风险与扩展点

| 风险 | 提前安排 |
|---|---|
| timeout 和 defeat 同时触发逻辑混乱 | 优先级硬编码：defeat > timeout > extraction（玩家身份重于时间重于位置）|
| 玩家"故意团灭刷快速回宗" | M3 配表回宗天数：defeat=7d 比 active=1d 长 7 倍，故意刷亏 |
| 阻塞型 action 等待时玩家关游戏 | 不存档中途，重进回节点边界，玩家用"看到下一节点"代价换取数据安全 |
| 撤离结算重复触发（race condition）| ExtractionService.settle 幂等保护 |
| timeout / defeat 触发时玩家正在选项面板 | UI 不强行关闭面板；玩家选完才会进入下一 action 边界 |
| 配表回宗天数失衡 | GDD-06 平衡章节负责数值；§4.8 给 M3 默认值 1/3/7 |

**预留扩展点**（M4 / M5）：

- **救援机制**（M5）：派遣弟子团灭时主角可发起救援（短距离历练支援）
- **超时分级**（M5）：剩余 0% / 剩余 -10%（透支）/ 剩余 -30% 不同惩罚梯度
- **意外撤离**（M5）：某些事件后果含 `force_extraction` action（"古阵被激活，强制传送回宗"），走与 timeout 不同的 reason 标签
- **多人队伍单人倒下**（M4）：actor_defeated 不立即团灭，其它角色继续；全员 hp=0 才触发 defeat

---

## 5. 派遣弟子（M3 仅 schema 占位 + 兼容性纪律）

### 5.1 设计精神

> 用户定调（2026-06-02）：派遣系统**本质是拟合，不是真跑图**。  
> 工程心智："拟合一个分布函数 `f(地图配置, 弟子属性, 策略) → DispatchResult`"，而不是让无头模拟器跑完整事件序列。

派遣弟子是修仙宗门玩法的标志机制——掌门坐镇宗门，遣弟子下山历练。**玩家心智**：

- "派李四去气运谷历练 3 个月" → 数月后弟子回宗，带回资源 / 经验 / 伤势 / 文本汇报
- 玩家**不亲自跑图**——本质是异步任务挂在外层时钟上推进
- 派遣失败 / 团灭 / 超时也按 §4 三种 reason 处理

**关键设计取向**：

派遣**不是简化版玩家历练**。它是另一种**玩法形态**：玩家亲历重在"决策与代入"，派遣重在"运营与权衡"——派几个人 / 派去哪 / 配什么策略 / 付出多少时间 / 接受多大风险。**两者共享地图与事件配置，但运行时机制不同**。

### 5.2 拟合 vs 真跑图（核心理念）

| 维度 | 真跑图（玩家亲历）| 拟合（派遣弟子）|
|---|---|---|
| 时长 | 实时 10-40 分钟内层时钟 | 异步 1-6 月外层时钟 |
| 决策粒度 | 玩家逐节点 / 逐选项 | 派遣前一次性配 strategy |
| 事件触发 | EventEngine 三幕完整解析 | **一次性概率推算**所有节点 |
| RNG | 即时滚（seed 派生）| 离线一次性算 |
| 表现 | 完整 UI / 动画 / 音效 | 文本日志汇报 |
| 性能 | 实时 60fps 限制 | 单次 < 100ms 可接受 |
| 玩家干预 | 全程可决策 | 派出后无法干预（M5 可加召回）|

> **不要把派遣做成"自动跑图"模式**——那只是把"亲跑模拟"包了一层 UI，浪费 EventEngine 的复杂度，且性能不如拟合。

### 5.3 拟合算法的工程心智（M4 实装方向）

仅作 M4 实施时的指导，**M3 不实装**：

```python
def simulate_dispatch(map: ExpeditionMap, actor: Character, strategy: DispatchStrategy) -> DispatchResult:
    # 1. 估算路径：根据 strategy.depth_target / risk_preference 选一条期望路径
    expected_path = sample_path(map, strategy, seed)
    
    # 2. 对路径上每个节点，按事件候选池抽样（用同一个 RNG seed）
    accumulator = ResultAccumulator(actor)
    for node in expected_path:
        for slot in node.event_slots:
            event_id = pick_candidate_offline(slot.candidates, ctx)
            if event_id != "":
                # 把事件的概率分布**直接转结果**，不跑 EventEngine
                # 例：start_battle action → 按 actor 战力 vs battle_template 难度算胜率 → 滚出胜负
                # 例：random_branch → 按 weights 直接抽分支
                # 例：give_loot → 按 loot_table 直接滚物品
                apply_event_distribution(event_id, accumulator)
        if hit_extraction_node(node) or accumulator.exhausted():
            break
    
    return accumulator.to_result()
```

**核心**：每个 action_type 都有"**分布版**"对应实现。`start_battle` 的分布版 = 战力胜率公式；`give_loot` 的分布版 = LootTable 期望抽样；`show_options` 的分布版 = 按 strategy 自动选。这与"真跑 EventEngine"是两套并列实现。

> **替代方案**（M5 可选）：不做拟合，直接让 EventEngine 跑无 UI 的"无头模式"。优势：行为与玩家亲跑完全一致。劣势：性能比拟合慢 10-100 倍，且 show_options/show_text 这种交互型 action 需要"虚拟决策器"代替玩家。M4 走拟合，M5 看需要再考虑切。

### 5.4 M3 必须保留的兼容性约束（核心）

派遣 M3 不实装，但 M3 的设计**不能挡住** M4 的实施。以下 6 条约束 §1-§4 已经满足，本节固化为派遣兼容性纪律：

| # | 约束 | 已落实在 |
|---|---|---|
| 1 | RNG 必须从 ExpeditionState.seed 派生（不准用全局 randomize）| §2.5 / §2.6 |
| 2 | EventEngine 不依赖 UI 单例（无头可运行）| §2.10 / 实现期 review 红线 |
| 3 | action 副作用通过 service 写（不通过 UI 反馈表达） | §2.4 关键纪律 |
| 4 | EventContext 含 `actor` 字段（区分主角 vs 派遣弟子）| §2.10 已加 |
| 5 | BattleResolver 同步骨架（不强依赖动画播放）| ADR-0002 §3 |
| 6 | Character 数据结构含完整 skills / equipped / status_effects（拟合算法读这些）| ADR-0003 §6.7 |

> **review 红线**：M3 实施期任何 commit 如果违反上述 6 条之一（如 EventEngine 直接调 UI 单例 / 用全局 RNG），自动拒收。这是"M3 不实装但 M3 不能挖坑"的纪律。

### 5.5 数据结构（M3 schema 占位）

类定义文件就位 + service stub，body 抛 `NotImplementedError`：

```gdscript
# scripts/expedition/dispatch/dispatch_task.gd
class_name DispatchTask
extends Resource

@export var task_id: String                    # 唯一 id
@export var map_id: String                     # 派遣到哪张图
@export var dispatched_actor_ids: Array[String]    # 派遣的弟子 id 列表（M3=1，M4=1-3）
@export var strategy: DispatchStrategy
@export var dispatched_at_month: int           # 外层时钟月份
@export var return_at_month: int               # 预计回宗月份
@export var status: String                     # "in_progress" / "completed" / "recalled"
@export var result: DispatchResult             # status=completed 时填


# scripts/expedition/dispatch/dispatch_strategy.gd
class_name DispatchStrategy
extends Resource

@export var depth_target: int                  # 期望深度（拟合算法决定走多深）
@export var risk_preference: String            # "conservative" / "balanced" / "aggressive"
@export var preferred_extraction_layer: int    # 偏好哪层撤离（实际由 strategy + 拟合决定）
@export var extra_strategy_flags: Dictionary   # 预留


# scripts/expedition/dispatch/dispatch_result.gd
class_name DispatchResult
extends Resource

@export var reason: String                     # 与 §4 三种 reason 对齐：active / timeout / defeat
@export var depth_reached: int
@export var visited_node_count: int
@export var resources_gained: Dictionary       # 通过 InventoryService 落袋的资源
@export var buffs_applied: Array[String]       # 弟子带回的 buff
@export var hp_changes: Dictionary             # actor_id → hp 变化
@export var narrative_log: Array[String]       # 文本汇报片段（"路上遭遇妖兽，李四苦战取胜，得灵石 50"）
@export var seed_used: int                     # 拟合用的 seed（debug / 复现用）
```

```gdscript
# scripts/expedition/dispatch/dispatch_service.gd
class_name DispatchService
extends Node
# autoload，M3 stub，M4 实装

func dispatch(task: DispatchTask) -> void:
    push_error("DispatchService.dispatch is not implemented in M3")

func tick_pending_dispatches(current_month: int) -> void:
    push_error("DispatchService.tick_pending_dispatches is not implemented in M3")
```

### 5.6 与既有系统的接触面（M4 实装预期）

| 接触系统 | 通信方式 | 内容 |
|---|---|---|
| `TimeService` | 监听外层 `month_advanced` signal | 检查 dispatch_at + duration 是否到期 |
| `DataRegistry` | 读 ExpeditionMap / EventTemplate / LootTable | 拟合算法的输入数据 |
| `InventoryService` | 拟合完成后调 add | 把 result.resources_gained 落袋 |
| `BuffService` | 拟合完成后调 apply_by_id | 把 result.buffs_applied 挂上 |
| `InjuryService` | 拟合完成后调 set_hp | 应用 hp_changes |
| `EventBus` | broadcast `dispatch_completed` | UI 弹"弟子归来"汇报 |
| `SaveService` | 序列化 / 反序列化 in_progress 任务 | 关游戏不丢派遣 |

### 5.7 M3 不实装但**必须做**的事

为保证 M4 拍下来即可启动，M3 仍要做：

1. **类定义文件就位**（DispatchTask / DispatchStrategy / DispatchResult / DispatchService 4 个 .gd 文件）
2. **DispatchService 在 autoload 注册**（M3 stub，调用即报错）
3. **§5.4 六条兼容性约束** review 期 enforce
4. **配表 schema 预留**：在 `历练地图.xlsx` 加一个 sheet `DispatchProfile`，描述每张图允许派遣 / 估算难度参数（M3 写 1 行示例）

不需要做：

- 拟合算法实现（M4）
- 派遣 UI（M4）
- 召回 / 救援机制（M5）

### 5.8 风险与扩展点

| 风险 | 提前安排 |
|---|---|
| M4 实装时发现某 §1-§4 设计挡住拟合（例：某 action 强依赖 UI）| §5.4 六条兼容性约束 + review 红线 |
| 拟合结果与玩家亲跑差异过大（"我自己跑能多 20%"）| 拟合算法以"中性中位数"为目标，玩家心智应该是"亲跑能争取更好结果，不是更多"|
| 派遣弟子团灭后玩家不爽 | 走 §4 defeat 路径，挂重伤 buff + 长回宗时间，跟玩家亲跑团灭对待一致 |
| 派遣过程不可干预 → 玩家流失感 | M5 加 force_recall（提前召回，损失部分预期收益）|
| 配表 DispatchProfile 错配（图不允许派遣却被派出去）| 烘焙静态校验：DispatchTask.map_id 必须在 DispatchProfile 中 allowed=true |

**预留扩展点**（M4 / M5）：

- **拟合参数曲线**（M4）：strategy.risk_preference 影响"事件触发概率分布偏移"——保守倾向避战，激进倾向触发更多 random_branch
- **召回机制**（M5）：force_recall(task) 立即结算，按已经过的预期时长比例给资源
- **救援队**（M5）：弟子团灭时主角组队短距离历练救回（改变 reason=defeat 为 reason=rescued）
- **多人小队派遣**（M4）：多 actor_id 协同；战斗按队伍战力算
- **派遣事件库**（M5）：某些事件**只能在派遣模式触发**（"弟子在外结识同道"），玩家亲跑不会遇到——区分"运营玩法专属"内容

---

## 6. 战斗框架

### 6.1 设计精神

> 用户定调（2026-06-02）：
> - **战斗框架要保留可扩展性**——未来可以加技能、状态、护盾、连招等规则
> - **M3 实装最简**——只比双方"战力数值"大小决定胜负
> - **战力计算包含五行相生相克加成**——这是修仙战斗的核心特色，M3 就要做

战斗系统的接口设计在 ADR-0002 已经定型（BattleResolver / BattleContext / BattleResult / 同步骨架 + M5 异步包装）。本节只补两件事：

1. **M3 的 BattleResolver 实现**（`StatSimulator`：基于战力对比 + 五行加成 + RNG）
2. **战力计算公式**（含五行规则，是修仙战斗的"DNA"）

### 6.2 接口（引用 ADR-0002，不复述）

```gdscript
class_name BattleResolver
extends Object

# 详见 ADR-0002 §3
func resolve(ctx: BattleContext) -> BattleResult:
    ...
```

- 输入：`BattleContext`（attackers / defenders / env / seed / escape_allowed / trigger_source）
- 输出：`BattleResult`（winner / hp_changes / status_changes / loot / log_entries / version=1 / narrative_seed）
- M3 同步直接返回；M5 加 `resolve_async` 演出包装层

### 6.3 战力公式（M3 核心）

```
final_power(actor, opponent_view)
    = base_power(actor)                                    ← 来自 actor 属性 / 装备 / 境界
    × (1 + sum(buff_modifiers))                            ← buff 加成（GDD-02 §7）
    × (1 + element_bonus(actor.elements, opponent.elements))  ← 五行加成（§6.4）
```

**胜负判定（M3 简化版）**：

```
attackers_power = sum(final_power(a, defenders) for a in attackers)
defenders_power = sum(final_power(d, attackers) for d in defenders)

# 胜负
if attackers_power > defenders_power × power_ratio_dominate(默认 1.2)
    → winner = ATTACKERS（碾压胜）
elif defenders_power > attackers_power × power_ratio_dominate
    → winner = DEFENDERS（碾压负）
else
    → 双方差距小，按 power 比例滚 RNG 决胜（含 ESCAPED 概率，仅 ctx.escape_allowed=true 时）
```

> **战力差**反映在 BattleResult.hp_changes：碾压胜方几乎不掉血；势均力敌双方都有损耗。具体公式 GDD-06 平衡。

### 6.4 五行相生相克规则（修仙战斗 DNA）

#### 6.4.1 五行枚举与关系

```
elements: [metal, wood, water, fire, earth]   # 金、木、水、火、土

# 相克（5 对，单向）
counter_pairs = [
    (metal, wood),    # 金克木
    (wood, earth),    # 木克土
    (earth, water),   # 土克水
    (water, fire),    # 水克火
    (fire, metal),    # 火克金
]

# 相生（5 对，单向）
generation_pairs = [
    (wood, fire),     # 木生火
    (fire, earth),    # 火生土
    (earth, metal),   # 土生金
    (metal, water),   # 金生水
    (water, wood),    # 水生木
]
```

#### 6.4.2 加成算法

```gdscript
func element_bonus(self_elements: Array, opp_elements: Array) -> float:
    var bonus = 0.0
    
    # 相克加成：每命中一组（自己一个属性 × 对方一个属性属于 counter_pairs）+ counter_bonus
    for s in self_elements:
        for o in opp_elements:
            if (s, o) in counter_pairs:
                bonus += counter_bonus_per_match    # 默认 0.20
    
    # 相生加成：自己功法内每命中一组（属于 generation_pairs）+ generation_bonus
    for s1 in self_elements:
        for s2 in self_elements:
            if (s1, s2) in generation_pairs:
                bonus += generation_bonus_per_match  # 默认 0.10
    
    return bonus
```

**两条加成**：

| 加成 | 来源 | 配置项 | 默认值 |
|---|---|---|---|
| 相克 | 自属性 × 对方属性 笛卡尔积 | `counter_bonus_per_match` | 0.20 |
| 相生 | 自属性 × 自属性 笛卡尔积 | `generation_bonus_per_match` | 0.10 |

两条加成**直接相加**（不是相乘）。同一组关系**多次命中按多次累加**（多属性功法的天然优势）。

> **schema 约束**（用户定调 v3.1）：
> - 一个角色**使用中的功法只有一个**（M3 不支持混用）—— element_bonus 仅按当前装备功法的属性集计算
> - **同一功法的属性数组无重复**（如不允许 [wood, wood, fire]）—— schema 烘焙时强校验，因此算法**不需要做去重处理**

#### 6.4.3 用户原例校验

**例 1**：A 功法=[fire, earth] / B 功法=[metal, water]

| 加成 | A | B |
|---|---|---|
| 相克 | fire×metal=fire 克 metal ✓ + earth×water=earth 克 water ✓ → 2 组 × 20% = **+40%** | water×fire=water 克 fire ✓ → 1 组 × 20% = **+20%** |
| 相生 | fire×earth=fire 生 earth ✓ → 1 组 × 10% = **+10%** | metal×water=metal 生 water ✓ → 1 组 × 10% = **+10%** |
| **合计** | **+50%** | **+30%** |

**例 2**：A 功法=[water, wood, fire] / B 功法=[earth]

| 加成 | A | B |
|---|---|---|
| 相克 | wood×earth=wood 克 earth ✓ → 1 组 × 20% = **+20%** | earth×water=earth 克 water ✓ → 1 组 × 20% = **+20%** |
| 相生 | water×wood=water 生 wood ✓ + wood×fire=wood 生 fire ✓ → 2 组 × 10% = **+20%** | 单属性，无相生 → **0** |
| **合计** | **+40%** | **+20%** |

### 6.5 数据结构（M3）

```gdscript
# scripts/battle/element_kind.gd
class_name ElementKind
extends Object

const METAL  = "metal"
const WOOD   = "wood"
const WATER  = "water"
const FIRE   = "fire"
const EARTH  = "earth"
```

```gdscript
# scripts/battle/element_calculator.gd
class_name ElementCalculator
extends RefCounted

# 配表读取（启动时由 DataRegistry 注入）
var counter_bonus_per_match: float = 0.20
var generation_bonus_per_match: float = 0.10
var counter_pairs: Array = []      # 从配表加载
var generation_pairs: Array = []   # 从配表加载

func bonus(self_elements: Array, opp_elements: Array) -> float:
    ...
```

```gdscript
# scripts/battle/stat_simulator.gd（M3 BattleResolver 的具体实现）
class_name StatSimulator
extends BattleResolver

@export var element_calc: ElementCalculator
@export var power_ratio_dominate: float = 1.2

func resolve(ctx: BattleContext) -> BattleResult:
    var atk_power = _team_power(ctx.attackers, ctx.defenders)
    var def_power = _team_power(ctx.defenders, ctx.attackers)
    var rng = RNG.from_seed(ctx.seed)
    return _decide(atk_power, def_power, ctx, rng)

func _team_power(self_team: Array, opp_team: Array) -> float:
    var sum = 0.0
    for actor in self_team:
        var base = actor.base_power
        var buff_mod = sum(actor.battle_buff_modifiers)
        var elem_mod = element_calc.bonus(actor.elements, _flatten_elements(opp_team))
        sum += base * (1.0 + buff_mod) * (1.0 + elem_mod)
    return sum
```

```gdscript
# scripts/battle/battle_template.gd（配表里的怪物组配置）
class_name BattleTemplate
extends Resource

@export var battle_template_id: String
@export var enemies: Array[EnemyDef]      # 怪物组（每个含 base_power / elements / hp / 战利品引用）
@export var environment_modifiers: Dictionary  # 地形/天候等 env 修正（M5 启用）
@export var loot_table_id: String         # 战胜后引用的 LootTable
```

### 6.6 数据驱动落地

```
data/table/战斗/
├─ 战斗模板.xlsx
│   ├─ Sheet "BattleTemplate"  → battle_template_id / 怪物组 / 战利品
│   └─ Sheet "EnemyDef"        → 单个敌人 base_power / elements / hp
├─ 战斗规则.xlsx
│   ├─ Sheet "ElementRule"     → 五行相生 + 相克对（默认值如 §6.4.1）
│   └─ Sheet "BattleConstants" → counter_bonus_per_match / generation_bonus_per_match / power_ratio_dominate
└─ proto/battle_system.schema.toml
```

**M3 必填**：

- 5-8 个 BattleTemplate（含妖兽 / 散修 / 古傀儡等）
- 战斗规则常数 1 行（默认 0.20 / 0.10 / 1.2）
- 五行相生相克 10 对（5 克 + 5 生，默认值见 §6.4.1）

**配表化的好处**：

- M5 加新元素（如 "yin / yang" 双修体系）只需在 ElementRule 表加新行
- 平衡测试可改 counter_bonus_per_match=0.15 → 烘焙 → 重测
- 不需要改任何 .gd 代码

### 6.7 实现要点（M3）

| 组件 | 路径 | 责任 |
|---|---|---|
| `BattleService` | `game/scripts/battle/battle_service.gd`（autoload）| 持 BattleResolver 实例（M3=StatSimulator）；提供 `resolve(ctx)` 给 EventEngine 调 |
| `BattleResolver`（接口）| `game/scripts/battle/battle_resolver.gd` | ADR-0002 抽象基类 |
| `StatSimulator` | `game/scripts/battle/stat_simulator.gd` | M3 唯一实现：战力对比 + 五行加成 + 简单 RNG 滚胜负 |
| `ElementCalculator` | `game/scripts/battle/element_calculator.gd` | 五行加成计算；从配表加载 pairs / 常数 |
| `BattleTemplate` / `EnemyDef` | `game/scripts/battle/*.gd` | Resource 类，配表数据载体 |

**与其他系统接触面**：

| 接触系统 | 通信方式 | 内容 |
|---|---|---|
| `EventEngine` | 通过 `start_battle` action handler 调 BattleService.resolve | 触发战斗 |
| `BuffService` | actor.battle_buff_modifiers 由它提供 | 战力 buff 加成 |
| `InjuryService` | BattleResult.hp_changes 由它应用 | 战后掉血 |
| `InventoryService` | BattleResult.loot 由 EventEngine 写入 | 战利品 |
| `DataRegistry` | 启动时一次 load | 战斗模板 / 五行规则 / 常数 |

### 6.8 风险与扩展点

| 风险 | 提前安排 |
|---|---|
| 五行齐全功法（5 属性）= 5 组相生 = +50% 加成 → 滚雪球 | 数值平衡：基础战力差距应远大于 +50% 加成才能保持挑战；GDD-06 平衡章节负责 |
| 单属性功法长期处于劣势 → 玩家放弃 | 单属性功法应在 base_power / 招式系数上有补偿（GDD-06） |
| 相生相克全配表后被策划改飞 | counter_bonus_per_match 上限 0.5（schema 校验，写更高烘焙报错） |
| RNG 不稳定 → 战斗结果不可复现 | seed 强制由调用方传入（ADR-0002 §3）|
| 多人战斗（M4）战力简单加和过粗 | M4 改进：考虑战力分布、暴击系数、buff 互补；M3 不优化 |
| 玩家通过功法切换刷克制 | M3 假设战斗中不能切功法；M5 切功法应有 cd / 代价 |

**预留扩展点**（M4 / M5）：

- **战斗规则插件化**（M4）：BattleResolver 可注册多个 implementation；StatSimulator 仅是 M3 默认。M4 加 `TacticalSimulator`（含技能 / 走位 / 状态）作为更精细版
- **环境修正**（M5）：BattleContext.env 字段（地形 / 灵气浓度 / 天候）影响战力修正；env 在 ADR-0002 已留 Dictionary 字段
- **境界压制**（M5）：境界差距大时（炼气 vs 金丹）追加战力倍率，可能直接判负
- **元素扩展**（M5）：阴阳 / 五雷 / 引气等修仙特化属性；配表加 ElementRule 行即可
- **战斗演出层**（M5 ADR-0002 已规划）：resolve_async 包装层接动画 / 镜头 / BGM 切换

> v3.1 决议留痕（2026-06-02）：
> - 相生加成**对所有 ≥2 属性的功法启用**（不区分双属性 / 多属性），按 §6.4.2 算法笛卡尔积计算（D-1=B）
> - 功法属性集无重复 + 单角色仅装一个功法 是 schema 硬约束（D-2 不存在去重场景）

---

## 7. 战斗 5 个接入点（系统耦合边界清单）

> 来源：GDD-01 §6.8.3 列明 5 个战斗调用场景；本节固化每个接入点的**触发路径 / BattleContext 装配方式 / trigger_source 标签 / 测试覆盖里程碑**。

战斗的"接入点"= 谁调 BattleService.resolve()。每多一个接入点 = 多一处耦合风险。**严守"全部走 BattleResolver 接口"**——不允许任何接入点绕过去走自己的私有战斗逻辑。

### 7.1 接入点总览

| # | 接入点 | 触发路径 | trigger_source | 实装里程碑 |
|---|---|---|---|---|
| 1 | **历练节点战斗事件** | EventEngine → start_battle action handler → BattleService.resolve | `expedition_event` | M3 ✅ |
| 2 | **宗门被攻击事件** | SectInvasionService → BattleService.resolve | `sect_invasion` | M4 |
| 3 | **派遣弟子遭遇战斗** | DispatchService（拟合分布版）→ 直接走 power 公式，**不调 resolve**（拟合范式）| `dispatch_simulated` | M4 |
| 4 | **主线 boss 战** | QuestService → BattleService.resolve | `main_quest_boss` | M5 |
| 5 | **仙宗大比 / 比武** | TournamentService → BattleService.resolve | `tournament` | M5 |

> **注**：派遣场景（接入点 3）按 §5.3 拟合范式**不调 BattleResolver.resolve**，而是用拟合算法的"分布版战斗"。但 trigger_source 标签依然存在（用于战报 / 数据分析归因）。这是**允许的例外**——因为派遣本身就是"绕过完整流程"的玩法形态。

### 7.2 各接入点详细约定

#### 7.2.1 历练节点战斗事件（M3）

| 项 | 内容 |
|---|---|
| **触发** | 节点的 EventSlot 抽到含 `start_battle` action 的事件 |
| **BattleContext 装配** | attackers = [ctx.actor]；defenders = BattleTemplate.enemies；env = {node_template_id, depth, region_id}；seed = ctx.expedition_state.next_random_int(...)；escape_allowed = true |
| **后果应用** | EventEngine 拿 BattleResult → 自动写 local.battle_won / battle_winner flag → 后续 actions 按 flag 分支 |
| **失败影响** | winner=DEFENDERS + actor hp=0 → §4.4 团灭路径 |
| **逃跑影响** | winner=ESCAPED → 事件序列继续（§1.1 三概念表）|
| **M3 测试** | 单元 + smoke：节点战斗 → 胜负 → BattleResult.hp_changes 应用 |

#### 7.2.2 宗门被攻击事件（M4）

| 项 | 内容 |
|---|---|
| **触发** | TimeService.month_advanced → SectInvasionService 检查"宗门威望-外敌仇恨"分布滚出 → 触发战斗 |
| **BattleContext 装配** | attackers = SectService.get_defenders()（玩家在宗弟子）；defenders = InvasionTemplate.enemies；env = {sect_buildings_status, weather}；escape_allowed = false（宗门保卫战不能跑） |
| **后果应用** | 战胜：建筑无损 + 战利品 / 战败：建筑被破坏 + 弟子伤亡 |
| **失败影响** | 走 GDD-05 宗门内务的"灾后重建"流程（不在本章范围）|
| **特殊点** | 涉及多个角色作为 attackers；M3 schema 已支持（CharacterRef 数组） |
| **M4 测试** | 集成：月节拍 → 攻击触发 → 多人战斗 → 后果落地 |

#### 7.2.3 派遣弟子遭遇战斗（M4，拟合范式）

| 项 | 内容 |
|---|---|
| **触发** | DispatchService 拟合算法在路径推算中遇到"事件含 start_battle action" |
| **战力计算** | **不调 BattleResolver.resolve**——直接用 §6.3 战力公式 + §6.4 五行加成 + simple win prob = atk_power / (atk_power + def_power) → 滚出胜负 |
| **后果应用** | 累积到 DispatchResult（hp_changes / resources_gained / buffs_applied）|
| **失败影响** | 弟子团灭 → DispatchResult.reason = "defeat" + 严重伤势 buff |
| **设计纪律** | 拟合分布版的战斗胜率公式**与 M3 StatSimulator 的胜负判定保持一致**（同公式 + 同常数）→ 玩家亲跑与派遣的预期胜率不漂移 |
| **M4 测试** | 拟合战斗 100 局 vs StatSimulator 真跑 100 局 → 胜率差距 ≤ 5% |

#### 7.2.4 主线 boss 战（M5）

| 项 | 内容 |
|---|---|
| **触发** | QuestService → 主线节点剧情进度 → 触发固定 BattleTemplate |
| **BattleContext 装配** | attackers = QuestParty（剧情指定的小队）；defenders = BossTemplate；env = {quest_chapter, ambient_buff}；escape_allowed = false（boss 战不能逃，强制完成）|
| **特殊点** | M5 BattleResult.version 升级为 2（细颗粒度日志，每一击一条）；战报留作主线纪念 |
| **失败影响** | M5 设计：主线失败回剧情存档点（不影响 SectService 永久状态）|
| **M5 测试** | 主线第一关 boss 战完整循环 |

#### 7.2.5 仙宗大比 / 比武（M5）

| 项 | 内容 |
|---|---|
| **触发** | 年度事件 / 玩家报名 → TournamentService 安排对战 |
| **BattleContext 装配** | attackers = 玩家选派弟子；defenders = 其它宗门 NPC（可能也是弟子级）；env = {tournament_round, audience_modifier}；escape_allowed = false |
| **特殊点** | 大量战斗短时间内连发；可能出现非主角人物作为 attackers；战报玩家旁观 |
| **后果** | 名次影响宗门威望 / 资源奖励（GDD-05 / GDD-06 协同） |
| **M5 测试** | 一届大比连跑 8 场，性能 + 内存稳定 |

### 7.3 接入点纪律

| # | 纪律 | 违反后果 |
|---|---|---|
| 1 | 所有接入点（除拟合派遣）必须走 `BattleService.resolve(ctx)`，不允许私有战斗实现 | review 拒收 |
| 2 | 每个接入点必须填正确的 trigger_source（用于战报归因 / 成就 / 数据分析）| schema 强校验 |
| 3 | BattleContext.env 字段允许接入点扩展，但**写入的 key 必须在 schema 列表内**（§7.4） | 烘焙报错 |
| 4 | escape_allowed 由接入点决定（玩家可逃跑 = true / 强制 = false）| 设计期 review |
| 5 | 拟合派遣的胜率公式与 StatSimulator 真跑保持一致，差异由 M5 派遣专属修正项独立表达 | 单元测试覆盖 |

### 7.4 BattleContext.env schema（开放字段强约束）

| key | 类型 | 哪个接入点用 | 含义 |
|---|---|---|---|
| `node_template_id` | string | 历练 | 当前节点模板 |
| `depth` | int | 历练 | 当前节点深度 |
| `region_id` | string | 历练 | 当前区域 |
| `sect_buildings_status` | dict | 宗门保卫 | 各建筑当前耐久 |
| `weather` | string | 历练 / 宗门保卫 | M5 天气系统 |
| `ambient_buff` | dict | 主线 boss | 关卡环境 buff |
| `quest_chapter` | string | 主线 boss | 第几章 |
| `tournament_round` | int | 比武 | 第几轮 |
| `audience_modifier` | float | 比武 | 观众影响 |

> M3 实装的接入点（仅历练）只用 `node_template_id / depth / region_id`。其它字段为 schema 占位，M4/M5 才填。

### 7.5 测试覆盖里程碑

| 里程碑 | 接入点覆盖 | 测试要求 |
|---|---|---|
| **M3** | 接入点 1（历练节点）| 单元 + smoke 各 1 条 |
| **M4** | 接入点 1 + 2 + 3 | 单元覆盖 100% / 集成 1 条 / 派遣胜率拟合误差 ≤ 5% |
| **M5** | 全部 5 个 | 完整集成；BattleResult.version=2 升级路径测试 |

---









## 附录 A · 烘焙产物 .tres 文本格式参考

> 仅供程序员 review / debug 参考。**策划永远不直接编辑此格式**，所有修改走 §3.5 的 xlsx 多表，由烘焙脚本生成。

§3.5 炎泉事件烘焙后产生的 .tres 片段（已简化，省略其它事件）：

```ini
; data/baked/events/event_template.tres
[gd_resource type="Resource" script_class="EventTemplateRegistry" load_steps=8 format=3]

[ext_resource type="Script" path="res://scripts/data/event_template_registry.gd" id="1"]

[sub_resource type="Resource" id="evt_yyq"]
script = preload("res://scripts/expedition/event_template.gd")
event_id = "event_yuyu_yanquan"
category = "encounter"
display_name_tid = "Text_event_yuyu_yanquan"
description_tid = "Text_event_yuyu_yanquan_desc"
before_phase_id = "yanquan_before"
during_phase_id = "yanquan_during"
after_phase_id = "yanquan_after"

[resource]
script = ExtResource("1")
events = {
    "event_yuyu_yanquan": SubResource("evt_yyq"),
    ; ... 其它事件
}
```

```ini
; data/baked/events/event_action.tres（按 phase_id 分组的索引）
[gd_resource type="Resource" script_class="EventActionRegistry" load_steps=12 format=3]

[ext_resource type="Script" path="res://scripts/data/event_action_registry.gd" id="1"]

[sub_resource type="Resource" id="a_intro"]
script = preload("res://scripts/expedition/event_action.gd")
action_id = "a_yyq_intro"
phase_id = "yanquan_before"
order = 0
action_type = "show_text"
condition_expr = ""
params = { "text_tid": "Text_event_yuyu_yanquan_intro" }

[sub_resource type="Resource" id="a_options"]
script = preload("res://scripts/expedition/event_action.gd")
action_id = "a_yyq_options"
phase_id = "yanquan_before"
order = 1
action_type = "show_options"
condition_expr = ""
params = {
    "prompt_tid": "Text_yuyu_prompt",
    "options_table_id": "yyq_opt_pool",
    "auto_pick_if_only_one": false
}

[sub_resource type="Resource" id="a_branch"]
script = preload("res://scripts/expedition/event_action.gd")
action_id = "a_yyq_branch"
phase_id = "yanquan_during"
order = 0
action_type = "random_branch"
condition_expr = "flag('choice') == 'investigate'"
params = { "branches_table_id": "yyq_branch_pool" }

[sub_resource type="Resource" id="a_inv_reward"]
script = preload("res://scripts/expedition/event_action.gd")
action_id = "a_yyq_inv_reward"
phase_id = "yanquan_after"
order = 0
action_type = "give_resource"
condition_expr = "flag('choice') == 'investigate'"
params = {
    "resource_type": "cultivation_progress",
    "formula": "fire_root * 5"
}

; ... 其它 action 略

[resource]
script = ExtResource("1")
actions_by_phase = {
    "yanquan_before": [SubResource("a_intro"), SubResource("a_options")],
    "yanquan_during": [SubResource("a_branch"), ...],
    "yanquan_after": [SubResource("a_inv_reward"), ...],
    "yanquan_inv_treasure": [...],
    "yanquan_inv_nothing": [...],
    "yanquan_inv_battle": [...]
}
```

```ini
; data/baked/events/option_def.tres
[gd_resource type="Resource" script_class="OptionDefRegistry" load_steps=5 format=3]

[ext_resource type="Script" path="res://scripts/data/option_def_registry.gd" id="1"]

[sub_resource type="Resource" id="opt_cult"]
script = preload("res://scripts/expedition/option_def.gd")
option_id = "cultivate"
order = 0
text_tid = "Text_option_cultivate_in_spring"
condition_show = "has_skill('fire') && realm_at_least('foundation')"
condition_enable = ""
cost_resources = {}
cost_hp = 0
cost_time_percent = 10
outcome_flags = {}

[sub_resource type="Resource" id="opt_inv"]
script = preload("res://scripts/expedition/option_def.gd")
option_id = "investigate"
order = 1
text_tid = "Text_option_investigate"

[sub_resource type="Resource" id="opt_leave"]
script = preload("res://scripts/expedition/option_def.gd")
option_id = "leave"
order = 2
text_tid = "Text_option_leave_forest"

[resource]
script = ExtResource("1")
options_by_pool = {
    "yyq_opt_pool": [SubResource("opt_cult"), SubResource("opt_inv"), SubResource("opt_leave")]
}
```

```ini
; data/baked/events/random_branch.tres
[gd_resource type="Resource" script_class="RandomBranchRegistry" load_steps=5 format=3]

[ext_resource type="Script" path="res://scripts/data/random_branch_registry.gd" id="1"]

[sub_resource type="Resource" id="br0"]
branch_index = 0
weight = 50
sub_phase_id = "yanquan_inv_treasure"

[sub_resource type="Resource" id="br1"]
branch_index = 1
weight = 10
sub_phase_id = "yanquan_inv_nothing"

[sub_resource type="Resource" id="br2"]
branch_index = 2
weight = 40
sub_phase_id = "yanquan_inv_battle"

[resource]
script = ExtResource("1")
branches_by_pool = {
    "yyq_branch_pool": [SubResource("br0"), SubResource("br1"), SubResource("br2")]
}
```

**运行时调用流程**（DataRegistry → EventEngine）：

```gdscript
# DataRegistry.gd 启动时
func _ready():
    var event_reg     := load("res://data/baked/events/event_template.tres")
    var action_reg    := load("res://data/baked/events/event_action.tres")
    var option_reg    := load("res://data/baked/events/option_def.tres")
    var branch_reg    := load("res://data/baked/events/random_branch.tres")
    # 索引化为 dict 备 O(1) 查询

# EventEngine.resolve_event(event_id, ctx) 时
func resolve_event(event_id: String, ctx: EventContext):
    var template = DataRegistry.get_event(event_id)        # 拿 EventTemplate
    for phase_id in [template.before_phase_id, template.during_phase_id, template.after_phase_id]:
        if phase_id == "": continue
        var actions = DataRegistry.get_actions_by_phase(phase_id)  # 拿 actions[]
        for action in actions:
            _execute_action(action, ctx)
            # 当 action_type == show_options 时
            #   options = DataRegistry.get_options_by_pool(action.params.options_table_id)
            # 当 action_type == random_branch 时
            #   branches = DataRegistry.get_branches_by_pool(action.params.branches_table_id)
            #   sub_phase_id = branches[picked].sub_phase_id
            #   _resolve_phase(sub_phase_id, ctx)   ← 递归解析子 phase（即嵌套的 actions）
```

**为什么烘焙产物用多张 .tres 而不是 1 张**：

- **拆分加载**：M5 大型主线事件可分包按需加载（lazy load）
- **索引平坦**：每张 .tres 是 `Dictionary[id]→Resource` 索引结构，运行时 O(1) 查询，无嵌套树遍历
- **Diff 友好**：改一个事件只改 event_template.tres + 相关 action.tres 条目，git diff 噪声小
- **类型安全**：每个 Registry 类有 GDScript 强类型，不是匿名 Dict


---
