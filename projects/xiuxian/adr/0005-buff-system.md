---
adr_id: 0005-buff-system
status: accepted
date: 2026-05-23
last_updated: 2026-05-25
accepted_at: 2026-05-26
deciders: [用户, codebuddy]
supersedes:
related_gdd: gdd-01 §6.8 战斗系统框架 / §6.9 系统解耦原则 / §6.10 buff 系统 / §6.11 宗门数据结构
---

# ADR 0005 · 通用 Buff 系统（双表注册 + IBuffable 任意实体挂载）

## 上下文

用户定调（2026-05-23 v1，2026-05-25 v2 双表 + 抽象 target）：

> v1（2026-05-23）：
> "做一个通用的 buff 系统，角色可以存在很多个 buff，buff 有大类和小类、持续时间、自己的属性。"
>
> v2（2026-05-25）：
> 1. injury_level 不应该是角色独立字段，应通过 BuffService 查询 + 受伤系统监控 buff 变化
> 2. buff 注册改为两张策划表：定义表（大类 / 小类 / 数值 schema）+ 实例表（具体 buff 模板）
> 3. 不只是角色，**宗门**也应该有 buff——意味着 BuffService 的 target 应抽象

跨切面修饰器（伤病 / 修炼 / 战斗 / 心境 / 因果 / 灵气环境 / ...）通过统一的 BuffService 处理：
- 不只是角色，宗门、历练地图、区域等都可挂 buff
- 各系统不自己造修饰器，而是注册 buff 类型（数据驱动）+ 通过 BuffService API 操作
- 月度推进、查询、清除等跨切面操作集中在 BuffService

## 决策

采用 **数据驱动双表注册 + IBuffable 接口（任意实体挂 buff）+ BuffService autoload + 各系统注册自己的 buff 类型**。

### 1. IBuffable 接口（任意实体可挂 buff）

```gdscript
# IBuffable.gd
class_name IBuffable

# target 实体类型枚举（用于序列化和 ID 命名空间）
enum TargetType {
    CHARACTER,    # 角色（门主 / 弟子 / 长老 / NonSect）
    SECT,         # 宗门
    MAP,          # 历练地图（实例化后的副本）
    REGION,       # 大地图区域（未来扩展）
}

# IBuffable 实现要求（duck-typed in GDScript）
var target_type: TargetType
var target_id: String          # 角色 id / 宗门 id / 地图实例 id ...
var buffs: Array = []          # Array[Buff]
```

实现 IBuffable 的实体：
- `Character`（ADR-0003）
- `Sect`（ADR-0006）
- `ExpeditionMapInstance`（ADR-0002 / GDD-03 起草时建）
- 未来可扩展 Region 等

> 注：Godot 4 的 GDScript 没有 interface 关键字，按 duck-typing 约定 + 单元测试检查。

### 2. 双表注册（用户定调 v2）

#### 表 A · BuffType 定义表（`data/buffs/buff_types.tres`）

| 字段 | 类型 | 说明 |
|---|---|---|
| `category` | String | 大类枚举（"injury" / "cultivation" / "battle" / "mood" / "environment" / ...）|
| `subtype` | String | 小类枚举，全局唯一（"poison" / "external_wound" / "qi_acceleration" / ...）|
| `display_name` | String | UI 显示名 |
| `description` | String | 描述 |
| `applicable_targets` | Array[TargetType] | 该 buff 类型可挂在哪些 target 上（CHARACTER / SECT / ...）|
| `attributes_schema` | Dict | 数值字段 schema：`{level: {type: int, min: 0, max: 100, default: 10}, ...}` |
| `tags` | Array[String] | `["debuff", "cleansable", "hidden", "stacking_allowed"]` 等 |
| `default_stack_policy` | String | `replace` / `stack` / `refresh` / `ignore`（同源同类时）|
| `monthly_tick_handler` | String | 注册函数路径（可空）：`"InjuryService.on_poison_tick"` |
| `icon` | String | UI 图标资源路径 |

**作用**：
- 系统启动时由 BuffService 加载本表，建立类型注册表
- 所有 buff 操作（apply / query / tick）都查这张表知道字段、handler、可挂 target
- 加新 buff 类型 = 加 1 行表 + 写 1 个可选 handler，**不改 BuffService 代码**
- 广播 / 访问 / 监控所有 buff 类型也通过这张表（"我想知道有哪些伤病 buff 类型" → 查表筛 category=injury）

#### 表 B · BuffInstance 模板表（`data/buffs/buff_instances.tres`）

| 字段 | 类型 | 说明 |
|---|---|---|
| `buff_id` | String | 全局唯一 ID（如 `buff_poison_event_jungle_001` / `buff_qi_closed_door_default`）|
| `type_subtype` | String | 引用表 A 的 subtype（如 `"poison"`）|
| `default_attributes` | Dict | 默认数值（如 `{level: 30}`）|
| `default_duration_months` | int | 默认时长，-1 永久 |
| `description_override` | String | 可选，覆盖表 A 描述（用于差异化此 instance）|
| `source_tag` | String | 来源标签，便于 debug / 清除（如 `"event_jungle_001"`）|
| `notes` | String | 策划备注 |

**作用**：
- 各系统调用 `BuffService.apply_by_id("buff_poison_event_jungle_001", target)` 直接挂 buff
- 系统不需要硬编码 buff 字段，只需要知道 buff_id 字符串
- 策划独立调整 buff 数值（中毒变 50 度）不需要程序改代码
- 同一种 type 可以有多个 instance（"轻度中毒" / "重度中毒" / "剧毒"）

### 3. BuffService API

```gdscript
# BuffService.gd autoload
class_name BuffService

# === 启动加载 ===
load_registry()                                # 启动时加载表 A + 表 B 到内存

# === 写操作 ===
apply(target: IBuffable, buff_type: BuffType, attributes: Dict, duration_months: int, source: String) -> Buff
apply_by_id(target: IBuffable, buff_id: String, override_attributes: Dict = {}) -> Buff   # 走表 B
remove(target: IBuffable, instance_id: String) -> bool
remove_by_subtype(target: IBuffable, category: String, subtype: String) -> int
clear_by_tag(target: IBuffable, tag: String) -> int       # 例：清除所有 "cleansable"

# === 查操作 ===
get_all(target: IBuffable) -> Array[Buff]
get_by_category(target: IBuffable, category: String) -> Array[Buff]
get_by_subtype(target: IBuffable, category: String, subtype: String) -> Array[Buff]
has(target: IBuffable, category: String, subtype: String) -> bool
sum_attribute(target: IBuffable, category: String, subtype: String, attr_key: String) -> Variant
sum_attribute_by_category(target: IBuffable, category: String, attr_key: String) -> Variant   # 跨小类累加（重要！）

# === 注册表查询（数据驱动）===
get_all_buff_types(category: String = "") -> Array[BuffType]
get_buff_type(subtype: String) -> BuffType
list_applicable_targets(buff_type: BuffType) -> Array[TargetType]

# === 时间推进 ===
tick_monthly(target: IBuffable)                # TimeService month_advanced 时调用，对所有 IBuffable 触发

# === Signal ===
signal buff_applied(target, buff)
signal buff_removed(target, buff, reason)        # reason: "expired" / "manual" / "cleansed"
signal buff_expired(target, buff)
signal buff_attribute_changed(target, buff, attr_key, old, new)
```

### 4. 受伤系统（InjuryService）作为 buff 消费者 + 监控者

> **关键修正（v2）**：`Character.injury_level` 不再是独立字段。受伤值是 buff 的查询结果。

```gdscript
# InjuryService.gd autoload
class_name InjuryService

# === 查询（计算属性）===
get_injury_level(character) -> float:
    # M3 简化版：仅看 injury/general_wound 的 level
    return BuffService.sum_attribute(character, "injury", "general_wound", "level")
    # 未来扩展：跨 injury 大类下所有 subtype 加权累加
    # return BuffService.sum_attribute_by_category(character, "injury", "level") * 加权系数

# === 监控（订阅 buff signal）===
_ready():
    BuffService.buff_applied.connect(_on_buff_changed)
    BuffService.buff_removed.connect(_on_buff_changed)
    BuffService.buff_attribute_changed.connect(_on_buff_changed)

_on_buff_changed(target, buff, ...):
    if buff.category != "injury": return
    if not target is Character: return
    var level = get_injury_level(target)
    if level >= 100.0:
        CharacterService.set_action_state(target, ActionState.DEAD, {"reason": "injury_overflow"})

# === 写操作（其他系统通过 InjuryService 调整伤病）===
apply_wound(character, level_delta: float, source: String):
    # 简化版 M3 实现：累加到 general_wound buff
    var existing = BuffService.get_by_subtype(character, "injury", "general_wound")
    if existing.size() > 0:
        BuffService.adjust_attribute(target=character, instance_id=existing[0].instance_id,
                                      attr_key="level", delta=level_delta)
    else:
        BuffService.apply_by_id(character, "buff_injury_general_default",
                                 override_attributes={"level": level_delta})
```

**精神**：InjuryService 不持有伤病数据，它只是**理解 buff 的领域逻辑层**：
- 怎么计算综合伤病值（M3 简单 / 未来加权）
- 100% 时怎么处理（→ ActionState DEAD）
- 怎么把"造成伤害"翻译成 buff 操作

### 5. 与其他系统的协作模式

| 系统 | 与 BuffService 的交互 |
|---|---|
| **TimeService**（ADR-0001）| month_advanced signal → BuffService.tick_monthly（对所有 IBuffable）|
| **CharacterService**（ADR-0003）| can_do() 时查询角色 buffs（如"中毒中能否突破"由 buff 标签决定）|
| **InjuryService** | 订阅 buff_applied/removed/attribute_changed → 维护伤病领域规则 |
| **SectService**（ADR-0006）| 宗门也是 IBuffable，挂"灵气浓郁" / "派系敌对"等 buff |
| **BattleResolver**（ADR-0002）| 战斗中读 buff（攻防修正）+ 写 buff（中毒 / 减速等战后留存）|
| **ProductionService**（炼丹 / 加工）| 闭关期间应用"灵气加速" buff 到角色 |
| **EventResolver**（事件引擎）| 事件 outcome 调用 BuffService.apply_by_id 给角色 / 宗门 / 地图加 buff |

## 候选方案

| # | 方案 | 优点 | 缺点 | 结论 |
|---|---|---|---|---|
| **新 A** | **双表注册 + IBuffable 接口（本 ADR v2）** | 策划改表加 buff / 任意实体可挂 / 跨系统统一 | 实现工作量略大 / 双表关系需要培养 | ✅ 选择 |
| 旧 A | 单表注册 + 仅角色可挂（旧 ADR v1）| 简单 | 宗门 / 地图 buff 没法表达 / 策划需要懂代码注册 | ❌ 放弃（用户否决）|
| B | 各系统自管修饰器 | 实现简单 | 跨系统查询难 / 月度 tick 易遗漏 / "清除所有 debuff"操作复杂 | ❌ 放弃 |
| C | Buff 内嵌入 Character 的 typed Dict | 类型安全 | 加新 buff 要改 schema → 存档迁移痛 / 不能挂宗门 | ❌ 放弃 |
| D | 第三方 buff 库 | 省工作量 | 锁定第三方设计 / 修仙特有需求适配难 | ❌ 放弃 |

## 理由

- **新 A 选择理由**：
  - 双表（定义 + 实例）是策划友好的标准设计——定义表保证类型安全，实例表保证数值灵活
  - IBuffable 接口让 BuffService 不绑死 Character——宗门 / 地图 / 区域都可复用，符合 §6.9 解耦
  - "InjuryService 是 buff 消费者"模式比"injury_level 是字段"更通用——未来可平滑加中毒 / 外伤等子类型
- **旧 A 放弃理由**：用户审视 v1 时指出三个问题——injury 字段化 / 注册不策划友好 / 宗门没考虑

## 影响

### 正面

- 策划改表加 buff，程序不需要改代码
- 宗门 / 地图 / 区域复用 buff 系统，避免造三套修饰器
- InjuryService 简化版可平滑升级到复杂版（不破坏 schema）
- 战斗系统的"状态效果" / 修炼系统的"加成" / 历练事件的"环境影响"全部统一
- 跨实体 buff 操作（"清除全宗门 debuff"）有统一接口

### 负面

- M2 必须实现 BuffService（多 1 个 autoload）+ IBuffable 约定
- 双表（定义 + 实例）的关系需要文档化清晰
- 策划需要学习"先定义类型再造实例"的两步流程

### 风险

| 风险 | 概率 | 缓解 |
|---|---|---|
| 各系统懒得用 BuffService，自己加字段 | 中 | code review 强制 + §6.9 解耦原则的"必走通道"|
| Buff stack_policy 设计不全 | 中 | 4 种 policy 覆盖常见场景；M2 单元测试覆盖 |
| 月度 tick 中 buff 互相影响产生顺序问题 | 中 | tick 时先快照列表，对快照逐个处理；buff 删除走"延迟移除队列"|
| Buff 数量过多导致性能 | 低 | 单 IBuffable 的 buff 数量上限（如 64）；超出按优先级或时长排序裁剪 |
| 永久 buff 越积越多 → 存档膨胀 | 中 | 永久 buff 必须有去重 / 替换语义 |
| Buff 副作用导致死循环 | 中 | tick 内禁止递归 apply；如必须，下一月再生效 |
| **applicable_targets 配错**（"灵气加速"挂到宗门是错的还是对的？）| 中 | 表 A 强制声明 + 单元测试枚举；apply 时校验 target_type |
| **InjuryService 简化版 → 复杂版升级路径不顺** | 中 | M3 实现时同时写"未来扩展点"注释；伤病值计算函数从一开始就抽象 |
| **buff_id 命名冲突** | 中 | 命名空间约定：`buff_<category>_<subtype>_<scenario>` |

## 实现要点（M2 任务）

- `IBuffable.gd` 接口约定 + duck-type 检查器
- `Buff.gd` 数据类
- `BuffType.gd`（描述表 A 一行）
- `BuffInstance.gd`（描述表 B 一行）
- `BuffService.gd` autoload
- `data/buffs/buff_types.tres`（表 A，M3 至少含 4 类型）
- `data/buffs/buff_instances.tres`（表 B，M3 至少含 6-8 实例）
- 默认注册 4 个最简 buff 类型（M3 用得到的）：
  1. `injury/general_wound`（适用：CHARACTER）—— 综合受伤
  2. `cultivation/qi_acceleration`（适用：CHARACTER, SECT）—— 灵气加速（角色或全宗门）
  3. `cultivation/closed_door_decay`（适用：CHARACTER）—— 闭关边际递减（§2.4）
  4. `battle/wounded_aftermath`（适用：CHARACTER）—— 战斗虚弱
- 单元测试覆盖：
  - 双表加载 + apply_by_id 正确实例化
  - apply / remove / 查询全 API
  - 月度 tick：remaining 递减、过期移除、handler 触发
  - 4 种 stack_policy 行为
  - 永久 buff 不递减
  - **IBuffable 多类型 target**：Character + Sect 至少各测一个用例
  - **applicable_targets 校验**：错误 target 类型挂 buff 应失败
  - 序列化 / 反序列化保留所有字段
  - 性能：单 target 64 个 buff tick 应在 < 1ms

## 关联

- GDD：gdd-01 §6.8 / §6.9 / §6.10 / §6.11
- 上游 ADR：
  - ADR-0001 双层时钟（month_advanced 驱动 tick）
  - ADR-0003 角色统一数据结构（Character 实现 IBuffable）
  - ADR-0006 宗门数据结构（Sect 实现 IBuffable）
- 下游 ADR：
  - ADR-0002 战斗接口（战斗状态效果走 buff）
  - ADR-0004 存档架构（buff 序列化策略 + 双表数据如何更新）
- 待建：GDD-02 §伤病系统 / GDD-04 §战斗状态效果 / GDD-05 §宗门 buff 等多处引用
