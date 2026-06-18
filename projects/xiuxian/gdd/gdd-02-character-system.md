---
gdd_id: 02
gdd_title: 角色与境界系统（契约层）
status: contract_clean_v3.2
last_review: 2026-06-18
sections_complete: [灵根契约, 境界契约, 属性维度契约, 弟子招收schema, 关系网schema, Buff类型扩展, NonSect schema, 玩法剥离完成]
sections_pending: []
upstream_adr: [0003-character-state-machine, 0005-buff-system, 0006-sect-data-structure]
upstream_gdd: [gdd-01]
verdict: GDD-PASS
---

# GDD-02 · 角色与境界系统（契约层）

> 本章承接 GDD-01 §6.3（角色三维度）+ §6.10（buff 系统）+ **§6.12（角色契约 vs 子系统玩法分离）**，定义角色的字段 schema、状态枚举、接口签名、Buff 数据结构、战斗力派生公式（接口）。
>
> 上游 ADR：0003 角色统一数据结构 / 0005 通用 Buff 系统 / 0006 宗门数据结构

---

## 0. v3.1 重构说明（**先读这一节再读下文**）

> 用户定调（2026-06-03，GDD-01 §6.12）：GDD-02 仅作"角色契约层"，不持有任何"怎么成长 / 怎么突破 / 怎么觉醒"的玩法逻辑。具体玩法由各子系统持有。

### 0.1 GDD-02 现状与目标的差距

GDD-02 v3.0 之前混入了大量**玩法层公式**（觉醒概率 / 突破成功率 / 修炼速度公式 / 寿元加成 / 招收概率 / 心境影响等）。按 GDD-01 §6.12 哲学，这些必须剥离。

### 0.2 剥离去向（v3.1 决议）

| GDD-02 现有内容 | 应去向 | 性质 |
|---|---|---|
| §1.2 灵根数据结构 / §1.3 元素注册表 | **留 GDD-02** | 契约 ✅ |
| §1.4 成长渠道 / §1.5 杂质语义 / §1.6 修炼速度公式 | **搬 GDD-04 成长系统** | 玩法 |
| §1.7 平衡假设 | **搬 GDD-06 经济与数值** | 数值 |
| §2.2 境界结构（5×9+飞升）| **留 GDD-02** | 契约 ✅ |
| §2.3 修炼值机制 / §2.4 突破检定公式 / §2.5 突破失败惩罚 | **搬 GDD-04 成长系统** | 玩法 |
| §2.6 寿元规则字段定义 | **留 GDD-02** | 契约 ✅ |
| §2.6 寿元加成 / §2.7 终结条件 | **搬 GDD-04 成长系统** | 玩法 |
| §3.2 显示属性字段定义 / §3.4 全局品质 / §3.5 战斗力派生**公式接口** | **留 GDD-02** | 契约 ✅ |
| §3.5 战斗力公式具体系数 / §3.6 功法战斗力具体系数 | **搬 GDD-06 经济与数值** | 数值 |
| §3.7 主修功法机制（接口语义）| **留 GDD-02** | 契约 ✅ |
| §5.2 角色生成器 schema / §5.3 模板字段 | **留 GDD-02** | 契约 ✅（Generator 接口）|
| §5.4 灵根两段式生成具体算法 / §5.6 招收来源具体规则 / §5.7 UI 信息密度 | **搬 GDD-05 宗门经营**（招收是宗门玩法）| 玩法 |
| §6.2 关系网数据结构 / §6.3 关系类型注册表 | **留 GDD-02** | 契约 ✅ |
| §6.4 ~ §6.5 M3 玩法 / 业务消费 | **搬 GDD-05 宗门经营** 或独立 GDD（M5）| 玩法 |
| §7 各类 buff 具体定义 | **搬 GDD-04 成长系统** | 玩法（成长机制干预手段）|
| §8 NonSect schema | **留 GDD-02** | 契约 ✅ |

### 0.3 重构落地方式（最小风险）

- **本文档保持章节结构**（不打乱编号），但**每个被剥离的玩法小节加迁移指针**：标记 `🔀 玩法已迁至 GDD-XX §Y.Z`，正文保留**契约定义**（字段 / 状态 / 接口签名）但删除**具体公式 / 数值 / 概率**
- **GDD-04 成长系统**（新建）承载所有被剥离的玩法内容，并增加新设计（M3 成长循环）
- **GDD-06 经济与数值**（原 GDD-04 后移）承载具体数值系数
- **GDD-05 宗门经营**（待起草）承载招收 / 关系玩法

### 0.4 子系统注册扩展点（M2 落地）

GDD-02 提供 `CharacterRegistry` 让子系统注册新状态 / 字段约束 / signal 监听，**不修改 GDD-02 源码**。具体接口：

```gdscript
# CharacterRegistry（autoload，M2 实装；正式签名见 ADR-0003 v3.3 amendment）
func register_state_mode(action_state: String, mode_id: String, handler: ICharacterStateHandler = null) -> void
func register_attribute(attribute_id: String, default_value: Variant, value_type: String = "auto") -> void
func register_attribute_modifier_source(source_id: String, modifier_targets: Array[String]) -> void
func register_signal_listener(signal_name: String, callback: Callable) -> void
```

详见 **ADR-0003 v3.3 amendment**（CharacterRegistry 注册扩展接口，2026-06-09 已 accepted）。

### 0.5 v3.1 / v3.2 重构进度（✅ 已完成）

| 状态 | 完成 |
|---|---|
| 顶部哲学说明（本节）| ✅ 2026-06-03 |
| 各小节加迁移指针 | ✅ 2026-06-09 |
| GDD-04 成长系统起草 | ✅ 2026-06-03（PASS 2026-06-18）|
| GDD-05 招收玩法承接 | ✅ 2026-06-03（PASS 2026-06-18）|
| GDD-06 数值标定承接 | ✅ 2026-06-05（PASS 2026-06-18）|
| **GDD-02 玩法部分实际删除** | ✅ **2026-06-18（v3.2 清理）**|

> **v3.2 清理结果（2026-06-18）**：GDD-04/05/06 用户审 PASS 后执行删除。被剥离的 11 处小节正文已替换为**合并迁移指针 stub**，正文仅保留契约层（字段 schema / 状态语义 / 接口签名 / 公式骨架）。具体清理映射见 `docs/gdd-02-cleanup-plan.md`。
>
> | 清理组 | 处理 | 净删 |
> |---|---|---|
> | §1.4-1.7 灵根成长/杂质/修炼速度/平衡假设 | 合并 stub，留 effective_root 契约 | ~85 行 |
> | §2.3-2.5 修炼值/突破检定/突破失败 | 合并 stub，留状态语义 | ~75 行 |
> | §2.6-2.7 寿元 | 部分删：字段/终态契约留，加成衰减玩法迁出 | ~35 行 |
> | §3.5-3.6 战斗力公式 | 删系数留接口（公式骨架 + schema 结构保留）| ~35 行 |
> | §5.6-5.7 招收 | 合并 stub，留 recruitable / template_id 字段契约 | ~35 行 |
>
> **保留不动**：§7 buff 类型清单（= buff_id 契约集中登记，非玩法，见 cleanup-plan 边界发现）。

---

## 1. 灵根系统（修仙资质起点）


### 1.1 设计精神

> 用户定调（2026-05-26）：
> - 五行系统（金 / 木 / 水 / 火 / 土）+ 兼容变异灵根
> - 灵根是 5 个值，每个 0-100，总和 ≤ 100（鬼谷八荒式）
> - 同灵根之间有质量差异（数值大小决定）
> - 灵根**通过功法系数**影响修炼速度，不是直接固定
> - 门主与弟子灵根分布无系统性区别（看招收 / 生成系统）

### 1.2 数据结构（M3 实现 · 用户定调 v2 离散点数 + 无硬上限）

```gdscript
# SpiritRoot.gd（数据类）
class_name SpiritRoot

var roots: Dict = {
    "metal": 0,    # 金 整数点数
    "wood":  0,    # 木
    "water": 0,    # 水
    "fire":  0,    # 火
    "earth": 0,    # 土
    # 变异灵根预留扩展（M3 不启用，但 schema 支持）：
    # "thunder": 0,  # 雷
    # "wind":    0,  # 风
    # ...
}

# 约束：
# - 单元素 ∈ [0, ∞)（无硬上限）
# - 初始随机生成时总和 ≤ 10（生成系统约束，非数据约束）
# - 运行时总和无上限（可通过血脉 / 丹药 / 顿悟 / buff 等突破 10）
```

> **关键设计哲学**（用户定调 v2）：
> - "10" **不是硬上限**，是**初始随机化上限**——平民起点
> - 后续可通过多种渠道突破 10：血脉天赋、洗髓丹、顿悟事件、突破副产物、临时 buff
> - 单元素也**无任何上限**——理论上"火 100"是可能的（顶级老怪物）
> - 这给游戏长线天花板感：10 是起点，不是终点

### 1.3 元素注册表（`data/elements/element_types.tres`）

| element_id | 类别 | 显示名 | 启用 milestone | 说明 |
|---|---|---|---|---|
| `metal` | 五行 | 金 | M3 | |
| `wood` | 五行 | 木 | M3 | |
| `water` | 五行 | 水 | M3 | |
| `fire` | 五行 | 火 | M3 | |
| `earth` | 五行 | 土 | M3 | |
| `thunder` | 变异 | 雷 | 后续 | 框架预留 |
| `wind` | 变异 | 风 | 后续 | 框架预留 |
| `ice` | 变异 | 冰 | 后续 | 框架预留 |
| `yin` | 变异 | 阴 | 后续 | 框架预留 |
| `yang` | 变异 | 阳 | 后续 | 框架预留 |

> 变异灵根 **框架支持但 M3 不启用**——元素表中有定义，但角色生成时不会分配变异灵根值。
> 后续启用 = 改 1 个开关 + 调整生成规则。

### 1.4 ~ 1.7 灵根成长 / 杂质 / 修炼速度 / 平衡假设（🔀 v3.2 已迁出）

> **v3.2 清理（2026-06-18）**：本组 4 小节的玩法内容已正式迁出 GDD-02（按 §6.12 契约/玩法分离哲学）。GDD-02 契约层仅保留：`SpiritRoot.roots[element]`（base 永久值，存档）+ `effective_root = base + Σ buff_boost` 查询语义 + `SpiritRootService.get_effective_root / adjust_base_root` 接口签名。
>
> | 原小节 | 迁出内容 | 去向 |
> |---|---|---|
> | §1.4 灵根成长渠道 | 4 渠道（初始/血脉/丹药/永久强化）+ 临时vs永久存储分离玩法 | **GDD-04 §5 灵根成长** |
> | §1.5 杂质语义 | B 无影响方案 + 设计含义 | **GDD-04 §5** |
> | §1.6 修炼速度公式 | `base_speed × (1 + Σaᵢ·effective_rootᵢ)` 骨架 + 设计示例 | **GDD-04 §2.2/§3.2**（骨架）+ **GDD-06 §6.2**（系数）|
> | §1.7 平衡假设 | a 系数区间 0.01~0.10 / Σa 0.05~0.20 | **GDD-06 §6.2/§10** |
>
> 契约层保留要点（M2 实装据此）：
> - `effective_root` = base_root + buff 加成（临时增益走 buff，永久属性走 base，§6.10 修饰器哲学）
> - 查询永远走 `SpiritRootService.get_effective_root(character, element)`
> - 数据字段：`SpiritRoot.roots[element]` 存档 / `Character.bloodline_id: String = ""` schema 预留

### 1.8 数据驱动落地

| 表 | 路径 | 内容 |
|---|---|---|
| 元素类型 | `data/elements/element_types.tres` | 见 §1.3 |
| 功法定义 | `data/cultivation_methods/*.tres` | 含 `root_coefficients: Dict[element_id, float]` 字段 |
| 角色生成模板 | `data/character/templates/*.tres` | 灵根分布权重（见 §5 弟子招收）|
| 血脉模板（后续）| `data/bloodlines/*.tres` | 血脉名 + 灵根加成 + 描述 |
| 灵根 buff 类型（后续）| `data/buffs/cultivation/root_boost.tres` | 临时灵根增益 buff |

### 1.9 实现要点

- `SpiritRoot.gd` 数据类（含 `roots: Dict[String, int]` + 序列化）
- `SpiritRootService.gd`（autoload 或合并到 CharacterService）：
  - `get_base_root(character, element_id) -> int`
  - `get_effective_root(character, element_id) -> int`（含 buff 加成）
  - `get_total_base(character) -> int`（基础灵根总和）
  - `adjust_base_root(character, element_id, delta, reason)`（永久变更）
  - `calculate_cultivation_speed(character, method) -> float`
- 校验：
  - 所有 element_id 必须在元素表中注册
  - delta 操作不能让单元素值 < 0
  - 初始生成系统执行 sum ≤ 10 约束（运行时不约束）
- 单元测试覆盖：
  - 离散点数序列化 / 反序列化
  - effective = base + buff 加成计算
  - buff 失效后 effective 自动恢复（不污染 base）
  - 永久强化（adjust_base_root）独立于 buff
  - 修炼速度公式（示例 4 个角色 × 3 个功法 = 12 用例）
  - 未注册 element_id 报错
  - 初始生成 sum ≤ 10 约束

---

## 2. 境界系统（修仙等级表 + 突破张力）

### 2.1 设计精神

> 用户定调（2026-05-26）：
> - 5 大境 × 9 小境 = 45 层 + 飞升（结构）
> - 小境界满即升；大境界突破需要"满 + 条件 + 概率检定"
> - 突破概率是**动态累积**的（继续修炼提升）+ **多维度叠加**（基础 + 修炼 + 灵根 + 悟性 + 增益）
> - 寿元不外显，濒死提示；用完直接死亡
> - 突破失败 = 反向进度（跌 1 小境 + 修炼分清零）

### 2.2 境界结构（5 × 9 + 飞升）

| 大境界 | 小境界 | 寿元加成（基础 80-100，可配）| 进入门槛 |
|---|---|---|---|
| **凡人** | —（默认起点）| 50-70 年随机（约 600-840 月）| 出生 |
| **炼气** | 1-9 层 | +80-100 年 | 凡人觉醒 → 炼气 1 层 |
| **筑基** | 1-9 层 | +80-100 年 | 炼气 9 层 → 突破 |
| **金丹** | 1-9 层 | +80-100 年 | 筑基 9 层 → 突破 |
| **元婴** | 1-9 层 | +80-100 年 | 金丹 9 层 → 突破 |
| **化神** | 1-9 层 | +80-100 年 | 元婴 9 层 → 突破 |
| **飞升** | —（终极目标）| ∞ / 离场 | 化神 9 层 → 突破 |

> 寿元增加量每境单独可配（GDD-04 平衡专章设定），M3 默认 80-100 年区间随机。

#### M3 范围

玩家在 M3 单次循环（前期 20 min / 后期 60 min）能体验：
- 炼气小境界递进 1-3 次
- **可能** 1 次大境界突破（炼气 9 层 → 筑基 1 层），让玩家亲历"突破紧张感"
- 全游戏（M4-M7）终极目标：飞升

### 2.3 ~ 2.5 修炼值机制 / 突破检定 / 突破失败（🔀 v3.2 已迁出）

> **v3.2 清理（2026-06-18）**：本组 3 小节的玩法公式已正式迁出 GDD-02。GDD-02 契约层仅保留：境界推进的**状态语义**（小境界自动升 / 大境界瓶颈进入 `IN_CULTIVATION` 的 bottleneck mode，详见 ADR-0003 state_data）。
>
> | 原小节 | 迁出内容 | 去向 |
> |---|---|---|
> | §2.3 修炼值机制 | 小境界自动 / 大境界瓶颈累积修为分玩法 | **GDD-04 §2 + §3** |
> | §2.4 突破检定 | 多维概率公式（基础/修炼/灵根/悟性/难度分）+ 演算示例 | **GDD-04 §4**（骨架）+ **GDD-06 §6.4**（系数）|
> | §2.5 突破失败惩罚 | 跌 1 小境 / 修为分清零 / 走火 buff | **GDD-04 §4.6** |
>
> 契约层保留要点：`IN_CULTIVATION` 含 bottleneck mode；突破检定由 CultivationSystem 发起，结果通过 `CharacterService.set_state` 写回（GDD-04 §4 调用契约）。

### 2.6 寿元规则（契约层 · 字段定义保留）

> **v3.2 清理（2026-06-18）**：寿元的**加成数值表 / 修饰渠道 buff / 衰减玩法**已迁出到 **GDD-04 §8 寿元加成**。GDD-02 仅保留下述**字段契约 + UI 不外显语义 + 死亡触发语义**。

#### 字段契约（Character schema）

| 字段 | 类型 | 语义 | 存档 |
|---|---|---|---|
| `lifespan_total_months` | int | 当前寿元总上限（月）| ✅ |
| `lifespan_remaining_months` | int | 剩余寿元（月），每月节拍 -1（衰减玩法在 GDD-04 §8.3）| ✅ |

> 寿元加成公式（突破 +N 月 / 血脉 / 延寿丹 / 禁术等修饰渠道）全部在 GDD-04 §8，**GDD-02 不持有具体数值**。

#### UI 不外显语义（契约 · 用户定调 C）

- **平时**：寿元不在 UI 显示具体数字
- **濒死警告**：剩余寿元 < 阈值（具体阈值 GDD-06）时状态栏出现"寿元将近"提示——CharacterService 广播 `lifespan_warning` signal
- **死亡触发**：`lifespan_remaining_months == 0` 时角色自动 `ActionState → DEAD`

### 2.7 寿元终结与游戏结束条件（契约层 · 终态语义保留）

> **v3.2 清理（2026-06-18）**：寿元衰减玩法迁至 GDD-04 §8.3；下述**终态语义 + 游戏结束判定**是契约层，保留。

#### 寿元用完处理（强制终态）

- 任何角色（门主 / 弟子 / 长老 / NonSect）寿元 → 0 → 直接 `ActionState → DEAD`（无坐化事件 / 无传位机会）
- 玩家须在濒死警告期间主动处理（突破 / 服延寿丹 / 传位）

#### 游戏结束条件（用户定调："门派没有一个人则游戏结束"）

```
all([member.action_state == DEAD for member in sect.members]) == True
→ 触发 GameOver
```

- 包括门主 + 所有弟子 + 所有长老都死亡，中间任意时刻满足即触发
- M3：简单 GameOver 界面（读档 / 退出）；M5+ 扩展总结回顾


### 2.8 数据驱动落地

| 表 | 路径 | 内容 |
|---|---|---|
| 全局突破常量 | `data/cultivation/breakthrough_constants.tres` | 单月基础修炼分 / MAX 保底 / 失败惩罚等级 / 寿元上下限 |
| 境界定义 | `data/cultivation/realms.tres` | 5 大境 × 9 小境 + 每境寿元增加上下限 |
| 功法 × 境界突破表 | `data/cultivation_methods/<method>.tres` 内 `breakthrough: { realm_id: {base_score, difficulty_score, required_items} }` | 每个功法在每个境界的基础分 / 难度分 / 必需道具 |
| 寿元修饰 buff | `data/buffs/lifespan/*.tres` | 长寿血脉 / 延寿丹 / 禁术 / 诅咒等 |
| 增益 buff | `data/buffs/cultivation/breakthrough_aid.tres` | 突破丹临时 buff |

### 2.9 实现要点

- **数据类**：
  - `Realm.gd`（大境界 / 小境界数据）
  - `BreakthroughAttempt.gd`（一次突破检定的快照：公式输入 / 结果 / reason）
- **服务类**：
  - `CultivationService.gd` autoload
    - `get_realm(character) → Realm`
    - `add_cultivation_value(character, delta)`（修炼值累积，满即升小境 / 进入瓶颈）
    - `is_at_bottleneck(character) → bool`
    - `get_bottleneck_months(character) → int`
    - `calculate_breakthrough_probability(character, method) → float`（执行公式）
    - `attempt_breakthrough(character, method, items) → BreakthroughResult`
- **修炼分计数**：
  - 进入瓶颈时初始化 = 0
  - 每月 TimeService.month_advanced + IN_CULTIVATION 时 +1
  - 突破失败时清零
  - 历练 / 其他行动状态时**不+但不清零**
- **寿元服务**：
  - `LifespanService.gd` autoload（或合并 CharacterService）
    - `get_remaining(character) → int`（含 buff 加成）
    - `tick_monthly(character)`：每月 -1
    - 监控 < 50 月 → 触发"寿元将近" UI signal
    - 监控 = 0 → 触发 `CharacterService.set_action_state(c, DEAD, "lifespan_zero")`
- **游戏结束监听**：
  - `GameOverService.gd` autoload
  - 订阅 `CharacterService.action_state_changed` signal
  - 任一角色死后检查 sect 全员状态
  - 全死 → 触发 GameOver
- **单元测试覆盖**：
  - 修炼值满 → 自动升小境
  - 修炼值满 9 层 → 进入瓶颈（不自动升）
  - 瓶颈后月数计数正确（含历练暂停 / 失败清零）
  - 突破概率公式 5 个场景（见 §2.4 示例表）
  - 突破成功 → 大境界进 1 + 寿元增加
  - 突破失败 → 跌 1 小境 + 修炼分清零
  - 寿元 < 50 触发 UI signal
  - 寿元 0 触发 DEAD
  - 全员死亡触发 GameOver

---

## 3. 属性维度（用户定调 · 精简 + 派生 + 全局品质）

### 3.1 设计精神

> 用户定调（2026-05-28）：
> - 属性结构必须有扩展性，但 M3 只实现少数核心
> - 角色面板**显示**的属性 5 个；底层"独立系统"如寿元等不显示但独立运作
> - 战斗力是**派生属性**（由基础属性 + 功法 + 装备 + 其他计算）
> - 删除心性 / 叛门设定（不要这两个概念）
> - 6 级全局品质规范（凡 / 黄 / 玄 / 地 / 天 / 仙 + 颜色），**所有可品质的对象**都用这套

### 3.2 显示属性（M3 共 5 个）

> 这些属性在角色面板可见，是玩家"看得见的能力"。
> 底层未显示的属性（寿元 / 修炼分 / 突破分等）由各自系统独立管理。

| 属性 | 范围 | 主要用途 | 增长来源（不限定，待各系统设计）|
|---|---|---|---|
| **悟性** | 0-200（基线 100）| 修炼速度 × 突破概率（§2.4 公式）| 初始随机 + 突破副产物 + 顿悟事件 + buff |
| **体魄** | 0+（预期常规 0-200）| 战斗力派生 / 抗伤病（M5+）| 体修功法 / 历练锻炼 / 丹药 / buff |
| **神识** | 0+（预期常规 0-200）| 战斗力派生 / 炼丹炼器精度（M4+）/ 探查能力（M4+）| 元婴境界后大幅提升 / 功法修炼 / buff |
| **炼丹** | 0-100 | 炼丹成功率 / 品质（GDD-05 宗门经营）| 实践累积 / 心法 / buff |
| **炼器** | 0-100 | 炼器成功率 / 品质（GDD-05 宗门经营）| 实践累积 / 心法 / buff |

> **属性来源不限定死**——具体增长公式由各自的子系统决定（炼丹系统 / 炼器系统 / 历练系统 / 突破系统 各自配置）。
> Character.attributes 用 Dict 存储，未来加新属性 = 加 1 个 key + 配置注册，schema 不变。

### 3.3 隐藏属性（独立系统）

> 这些属性玩家面板不直接显示，但底层独立运作，影响玩法。

| 属性 | 范围 | 系统归属 | 显示方式 |
|---|---|---|---|
| **寿元** | 月数 | LifespanService（§2.6）| 不显示，< 50 月触发"寿元将近"提示 |
| **修炼值** | 0 ~ 当前小境上限 | CultivationService（§2.3）| 进度条（不显示精确数值）|
| **修炼分** | 累积值 | CultivationService 瓶颈期（§2.4）| 不直接显示，UI 间接表达"打磨多久了" |
| 其他 | — | — | 后续按系统添加 |

### 3.4 全局品质规范（6 级 · 用户定调）

> 所有"可品质的对象"统一使用这套——功法 / 丹药 / 装备 / 法宝 / 材料 / 技能（M5+）等。

| 品质 | 名称 | 颜色 | 系数（默认）| 设计意图 |
|---|---|---|---|---|
| 1 | **凡** | 白 | 1 | 凡品 / 入门 / 大量产出 |
| 2 | **黄** | 绿 | 2 | 优良 / 常见 / 早期主力 |
| 3 | **玄** | 蓝 | 3 | 稀有 / 中期主力 |
| 4 | **地** | 紫 | 4 | 极品 / 中后期目标 |
| 5 | **天** | 橙 | 5 | 顶级 / 后期 / 罕见 |
| 6 | **仙** | 红 | 6 | 仙品 / 终极 / 极罕见 |

**品质参数（系数）的应用方式**：
- 功法：`功法战斗力 = 品质参数 × 功法自身战斗力公式`（详见 §3.5）
- 丹药：未来定义"突破丹"等时，品质参数影响增益数值（GDD-04）
- 装备：未来定义装备时，品质参数影响装备 atk/def（GDD-04 / GDD-05）
- 默认系数为 1-6 线性，每种对象可在自己的数据表中**调整非线性**（如 1/3/9/27/81/243 指数式）

#### 数据驱动配置

```
data/quality/quality_levels.tres
  - id: "fan"     | name: "凡" | color: white  | default_coef: 1
  - id: "huang"   | name: "黄" | color: green  | default_coef: 2
  - id: "xuan"    | name: "玄" | color: blue   | default_coef: 3
  - id: "di"      | name: "地" | color: purple | default_coef: 4
  - id: "tian"    | name: "天" | color: orange | default_coef: 5
  - id: "xian"    | name: "仙" | color: red    | default_coef: 6
```

每个对象类型（功法 / 丹药 / 装备 / ...）在自己的数据表中可覆盖默认系数。

### 3.5 派生属性 · 战斗力（用户定调公式）

> 战斗力是 M3 唯一的派生属性，作为 M3 战斗 StatSimulator 的核心输入。
> 详细的战斗系统（招式 / 技能 / 状态效果叠加）在 GDD-03 / ADR-0002 战斗接口展开。

#### 公式（v1）

```
战斗力 = 境界参数 × (a × 体魄 + b × 神识 + 功法战斗力) + 其他战斗力

其中：
  境界参数         = [1, 2, 4, 8, 16, ...] （指数递增，越级 ≥2 倍碾压）
  a, b             = 默认 1（可配超参）
  功法战斗力       = 功法品质参数 × 功法自身战斗力公式
  其他战斗力       = 丹药 / 装备 / 法宝 / buff 等"投放位"
```

#### 公式分项说明

| 分项 | 含义 | 数据来源 |
|---|---|---|
| **境界参数** | 大境界对应的乘数 | `data/cultivation/realms.tres` 配置 |
| **a, b** | 体魄 / 神识系数 | `data/balance/combat_constants.tres` 配置 |
| **功法品质参数** | 主修功法的品质系数（凡 1 / 黄 2 / ... / 仙 6）| `data/quality/quality_levels.tres` |
| **功法自身战斗力公式** | 功法定义的属性加权和 | 单个功法表配置（见 §3.6）|
| **其他战斗力** | 一切外部增益 | 装备表 / 丹药 buff / buff 系统 |

> **境界参数具体取值**（🔀 v3.2 已迁出）：境界参数的数值序列（凡人/炼气/筑基/金丹/元婴/化神 的乘数）已迁到 **GDD-06 §7.1 base_power 标定**（每境 5-7 倍跳变）。GDD-02 仅保留"境界参数是指数递增、越级碾压"的**设计语义**与公式中的占位符。

### 3.6 功法自身战斗力公式（契约 · 公式接口保留 / 系数迁出）

> **v3.2 清理（2026-06-18）**：本节保留**公式接口 + 数据表 schema 结构**（契约层），**具体系数取值与计算示例**已迁到 **GDD-06 §7.2 功法战斗力系数**。

#### 公式接口（契约）

```
功法自身战斗力 = Σ (coefᵢ × 属性ᵢ)

其中 coefᵢ 在功法数据表中配置，属性 ∈ {五行灵根, 体魄, 神识}
（基本逻辑由灵根、神识、体魄构成；神识和体魄可只存在一个或多个）
```

#### 数据表 schema（契约 · 字段结构，系数取值见 GDD-06）

```yaml
# data/cultivation_methods/<method_id>.tres
id: "fire_water_method_1"
display_name: "火水双修诀"
quality: "huang"                  # 品质 ID（引用 quality_levels.tres）

cultivation_root_coef:            # 修炼速度系数（§1 灵根章；具体值 GDD-06 §6.2）
  fire: <coef>
  water: <coef>

combat_power_coef:                # 战斗力公式系数（具体值 GDD-06 §7.2）
  fire: <coef>
  water: <coef>
  shenshi: <coef>
  # tipo: <coef>                  # 体魄（不参与本功法时不写）

breakthrough_table:               # 突破相关（公式 GDD-04 §4 / 系数 GDD-06 §6.4）
  qi_to_jichu:
    base_score: <int>
    difficulty_score: <int>
    required_items: ["breakthrough_pill_qi"]
```

> **设计语义保留**：功法系数决定"选合适的功法 vs 一味追高品质"的策略——低品质体修诀配高体魄角色可能比高品质功法更强。具体数值平衡与计算示例见 GDD-06 §7.2。

### 3.7 主修功法机制（用户定调 · "运转某功法"语义）

#### 数据结构（角色字段）

```gdscript
# Character.gd 新增字段
var learned_methods: Array = []        # Array[method_id]：已学功法列表
var current_method: String = ""        # 当前主修（"运转中"）功法 ID
```

#### "运转"功法语义

- 角色一次只能"运转"一个主修功法
- 切换主修需要执行"运转"动作（M3 简化：UI 一键切换；M5+ 可加切换冷却 / 切换损耗）
- 战斗力公式中的"功法战斗力"只算 `current_method`
- 修炼速度公式（§1.6）也只算 `current_method`（修炼时只走一种功法）

#### 设计含义

- 学多种功法 ≠ 战斗力叠加，玩家需要为不同场景"切运转"（战斗用爆发功法 / 修炼用契合灵根的功法）
- 防止"功法囤积"造成战斗力膨胀
- M5+ 可以加"双修"等特殊机制（同时运转 2 功法但有代价）

### 3.8 数据驱动落地

| 表 | 路径 | 内容 |
|---|---|---|
| 全局品质 | `data/quality/quality_levels.tres` | 6 级品质 + 颜色 + 默认系数 |
| 战斗常量 | `data/balance/combat_constants.tres` | 境界参数表 + a, b 系数 |
| 功法定义 | `data/cultivation_methods/<id>.tres` | 修炼系数 + 战斗力系数 + 突破表 + 品质 |
| 角色属性来源 | 各子系统数据表 | 不在本章定，由各子系统自定 |

### 3.9 实现要点

- **数据类**：
  - `Character.attributes: Dict` 存 5 个显示属性 + 未来扩展
  - `Character.learned_methods: Array[String]`
  - `Character.current_method: String`
- **服务类**：
  - `AttributeService.gd`（或合并到 CharacterService）
    - `get_attribute(character, attr_id) → Variant`（含 buff 加成）
    - `adjust_base_attribute(character, attr_id, delta, reason)`
  - `CombatPowerService.gd` autoload
    - `calculate(character) → int`（执行 §3.5 完整公式）
    - 订阅 buff_applied/removed 触发战斗力刷新 signal
- **品质系统**：
  - `QualityService.gd`（轻量）
    - `get_coef(quality_id) → int`
    - `get_color(quality_id) → Color`
- **单元测试覆盖**：
  - 属性增删改 + buff 加成
  - 战斗力公式 4-5 种角色 × 3 种功法 = 15 用例
  - 主修切换战斗力刷新
  - 境界突破后境界参数立即生效（战斗力跳跃）
  - 6 级品质常量正确加载

---

## 4. 寿元规则（已并入 §2.6 / §2.7）

> 寿元规则与境界系统耦合紧密（境界突破直接增加寿元 / 寿元用尽与全员死亡触发 GameOver），已整体并入 §2 章节：
> - §2.6 寿元规则（数值 / 修饰渠道 / 不外显 UI）
> - §2.7 寿元终结与游戏结束条件

---

## 5. 弟子招收与角色生成（用户定调 · 综合方案）

### 5.1 设计精神

> 用户定调（2026-05-29）：
> - 弟子是**完整角色**（非数值人）—— 数据 schema 完整，因为门主需要继承
> - M3 内容轻 —— 性格 / 成长轨迹 / 关系网 / 对话**全部 M5+ 才填**
> - 立绘 / 名字 **批量生成 + 标签匹配**
> - 灵根分布**两段式**（先抽总量 → 再抽数量），都支持配置
> - 其他属性的初始范围 / 分布也独立配置
> - 招收时玩家看到基础信息（名字 / 性别 / 立绘）+ 可展示属性（灵根 / 悟性 / 体魄 / 神识 / 炼丹 / 炼器）

### 5.2 角色生成器（独立子系统）

**任何"诞生新角色"都通过 `CharacterGenerator` 生成**，不仅是弟子招收。包括：
- 起始角色（开局门主）
- 弟子招收（自动来投 / 主动招收 / 历练带回）
- NonSect 角色（路人 / 敌人 / 异宗弟子）
- 未来主线 NPC

这是 §6.9 解耦原则的应用——一个生成器，多处复用。

#### CharacterGenerator API

```gdscript
CharacterGenerator.generate(template_id: String, overrides: Dict = {}) -> Character

# template_id 引用 data/character/templates/<id>.tres
# overrides 用于覆盖模板个别字段（如指定性别 / 指定年龄段等场景需求）
```

### 5.3 角色生成模板（数据驱动）

`data/character/templates/<id>.tres` 完整 schema：

```yaml
# 模板元数据
id: "passive_seeker"           # 自动来投模板示例
display_name: "求道者"
applicable_to_identity: "DISCIPLE"   # 生成出来的 identity（DISCIPLE / NON_SECT 等）

# 性别分布
gender_distribution:
  male: 0.5
  female: 0.5

# 年龄分布（年）
age_distribution:
  type: "uniform"              # uniform / normal / weighted
  min: 10
  max: 25

# 寿元分布（凡人初始范围 · 与境界系统配合）
lifespan_distribution:
  type: "uniform"
  min_years: 50
  max_years: 70

# === 灵根（两段式分布 · 用户定调）===
spirit_root_generation:
  total_distribution:          # 步骤 1：总点数 1-10 的权重
    type: "weighted"
    weights:
      1: 0.10
      2: 0.20
      3: 0.20
      4: 0.18
      5: 0.13
      6: 0.10
      7: 0.05
      8: 0.025
      9: 0.012
      10: 0.003
  count_distribution:          # 步骤 2：灵根数量 1-5 的权重（即点分布到几个元素）
    type: "weighted"
    weights:
      1: 0.30                 # 单灵根（含点数集中）
      2: 0.35                 # 双灵根
      3: 0.20                 # 三灵根
      4: 0.10                 # 四灵根
      5: 0.05                 # 五灵根（杂灵根）
  element_pool:                # 可分配到的元素（M3 仅五行）
    - "metal"
    - "wood"
    - "water"
    - "fire"
    - "earth"
  # 后续启用变异灵根：在 element_pool 加 "thunder" / "wind" / ...

# === 5 个面板属性（每个独立配置分布）===
attributes_distribution:
  悟性:
    type: "normal"
    mean: 100
    sigma: 15
    min: 60
    max: 140
  体魄:
    type: "normal"
    mean: 50
    sigma: 15
    min: 20
    max: 100
  神识:
    type: "normal"
    mean: 40
    sigma: 12
    min: 10
    max: 80
  炼丹:
    type: "uniform"
    min: 0
    max: 20
  炼器:
    type: "uniform"
    min: 0
    max: 20

# 名字 / 立绘配置
name_pool:
  surnames_resource: "data/character/names/surnames.txt"
  given_names_resource: "data/character/names/given_names.txt"
  # 名字按 gender 标签筛选（详见 §5.5）

portrait_pool:
  source: "data/portraits/disciples/"
  filter_tags: ["disciple"]    # 必须包含的标签
  # 还会按 gender / age_range 筛选

# 特性槽（M3 schema 就位 / 内容后续）
traits_pool: []                 # M3 不投放特性，留空

# === M3 占位字段（schema 就位但不展示 / 不投放）===
personality_pool: []            # M5+ 性格
origin_pool: []                 # M5+ 出身（农户 / 世家 / 孤儿等）
```

### 5.4 灵根两段式生成算法

```
def generate_spirit_root(template):
    # 步骤 1：抽取总点数 N（1-10，按权重）
    N = weighted_sample(template.total_distribution.weights)

    # 步骤 2：抽取灵根数量 M（1-5，按权重，但 M ≤ N）
    valid_counts = [c for c in template.count_distribution.weights if c <= N]
    M = weighted_sample({c: w for c, w in template.count_distribution.weights.items() if c in valid_counts})

    # 步骤 3：从 element_pool 随机选 M 个元素作为承载
    elements = random.sample(template.element_pool, M)

    # 步骤 4：N 个点随机分配到 M 个元素（保证每元素至少 1 点）
    # 简单方案：先给每个元素 1 点（保底），剩余 N-M 点随机分配
    roots = {e: 1 for e in elements}
    for _ in range(N - M):
        roots[random.choice(elements)] += 1

    return SpiritRoot(roots=roots)
```

#### 演算示例

| 抽 N | 抽 M | 选元素 | 分配 |
|---|---|---|---|
| 7 | 1 | [fire] | fire 7 |
| 7 | 2 | [fire, water] | fire 4 water 3（随机分配）|
| 10 | 1 | [fire] | fire 10（纯灵根）|
| 5 | 5 | [metal, wood, water, fire, earth] | 各 1（最杂灵根，强制保底）|
| 3 | 5 | clamp 为 3 | 三灵根，各 1 |

> M > N 时自动 clamp 为 N（按用户预想，5 行最多 = N=5）。

### 5.5 名字与立绘的标签匹配

#### 名字数据（`data/character/names/`）

```
# surnames.txt（姓库 · 中性）
李
王
张
陈
...

# given_names.txt（名库 · 带性别标签）
青云 | male
紫嫣 | female
道明 | male
若水 | unisex   # 男女通用
...
```

生成名字算法：
```
1. 随机抽 surname（无标签筛选，姓本身性别中立）
2. 按 character.gender 抽 given_name（标签 male / female / unisex 中匹配）
3. 拼接 → "李青云" / "王紫嫣"
```

#### 立绘资源（`data/portraits/`）

每张立绘资源带元数据（`.import` 文件 / 同名 `.json` / Resource 字段）：

```yaml
# 例：data/portraits/disciples/portrait_001.tres
id: "portrait_disciple_001"
file: "res://assets/portraits/disciple_male_youth_01.png"
gender: "male"
age_range: [12, 22]
style_tags: ["disciple", "youthful", "scholar"]    # 后续可加更多
mood_tags: []                                       # 后续扩展（happy / serious / mysterious）
quality_tags: []                                    # 后续扩展（common / rare / 立绘品质区分）
```

**立绘批量生成**（M3）：
- 走 `art-asset-pipeline` skill + `art-director` agent
- 目标：30-50 张通用立绘
- 覆盖：男 × 女 × 年龄段（少年 / 青年）× 气质（书生 / 武修 / 隐士）
- 每张人工审核标签

**抽取算法**：
```
1. 按 character.gender 筛选 portrait_pool
2. 按 character.age 落入 age_range 筛选
3. 按 template.portrait_pool.filter_tags 包含的 tag 筛选
4. 剩余池中随机抽 1 张
```

### 5.6 ~ 5.7 招收来源 / 招收 UI 信息密度（🔀 v3.2 已迁出）

> **v3.2 清理（2026-06-18）**：招收玩法（来源/频率/成本/UI 信息密度）已正式迁出到 **GDD-05 §8 弟子招收**（招收是宗门玩法）。GDD-02 仅保留 Character 招收相关**字段契约**：
>
> | 字段 | 语义 |
> |---|---|
> | `recruitable: bool` | 该角色是否可招收（生成器产出的候选）|
> | `template_id: String` | 引用的角色生成模板（`active_recruit` / `passive_seeker` / `expedition_rescue`，定义在 §5.3）|
>
> 招收的 3 条来源（自动来投 / 主动招收 / 历练带回）、频率、成本、UI 信息密度 → GDD-05 §8 / §8.4。


### 5.8 数据驱动落地

| 表 / 资源 | 路径 | 内容 |
|---|---|---|
| 角色生成模板 | `data/character/templates/<id>.tres` | 灵根 / 属性 / 年龄 / 寿元 / 名字 / 立绘 / 特性等分布配置 |
| 姓库 | `data/character/names/surnames.txt` | 中文姓（中性） |
| 名库 | `data/character/names/given_names.txt` | 中文名 + 性别标签（male / female / unisex）|
| 立绘资源 | `data/portraits/<category>/<id>.tres` | 文件路径 + 性别 / 年龄 / 风格标签 |
| 招收事件 | `data/events/recruit/*.tres` | 自动来投 / 主动招收 / 历练带回的事件触发与配置 |

### 5.9 实现要点

- **数据类**：
  - `CharacterTemplate.gd`（角色生成模板数据类）
  - `Distribution.gd`（通用分布工具：weighted / uniform / normal）
- **服务类**：
  - `CharacterGenerator.gd` autoload
    - `generate(template_id, overrides) → Character`
    - 内部依次：抽性别 → 抽年龄 → 抽寿元 → 抽灵根（两段式）→ 抽属性 → 抽名字 → 抽立绘
  - `PortraitService.gd`（立绘抽取）
    - `pick_portrait(filter: PortraitFilter) → portrait_id`
  - `NamingService.gd`（名字组合）
    - `generate_name(gender) → String`
- **招收子系统**（部分在 GDD-05 宗门经营展开）：
  - `RecruitmentService.gd` autoload
    - 月节拍订阅触发"自动来投"
    - "主动招收"由玩家 UI 发起
    - "历练带回"由 ExpeditionService 调用
- **单元测试覆盖**：
  - 灵根两段式生成（含 M > N 自动 clamp）
  - 各分布类型（weighted / uniform / normal）正确性
  - 名字 / 立绘按 gender 标签筛选
  - 模板覆盖（overrides）生效
  - 5000 次随机生成统计验证（落入预期分布范围 ±5%）
  - schema 完整性（包括 M3 不展示但已就位的字段：traits / personality / origin）

[待用户回答]

---

## 6. 关系网（M3 schema 占位 / M5+ 内容启用）

### 6.1 设计精神

> 用户定调（2026-05-29）：
> - M3 不做关系实际功能（schema 占位）
> - 师徒 / 同门通过 Sect.member_ids 隐式推导，不显式存
> - 关系如何影响玩法 **不限定死**——关系系统只提供"事实查询"，业务影响由消费方自己实现

设计哲学：**关系是事实层，不是规则层**。关系系统记录"A 对 B 是什么"，但不规定"A 见到 B 会发生什么"——后者由战斗 / 事件 / 修炼等系统按需消费。

### 6.2 数据结构

#### Relation（关系实例）

```gdscript
class_name Relation

var id: String                    # 全局唯一 instance id
var from_character_id: String
var to_character_id: String
var relation_type: String         # 引用 data/relations/types.tres
var value: int = 0                # 数值（推荐 -100 ~ 100，正面/负面）
var established_at_month: int     # 建立时的游戏月份
var history: Array = []           # 变化历史（M5+ 详细记录）
var tags: Array = []              # 扩展标签（"sealed" / "secret" / "renounced" 等）
```

#### RelationGraph 服务（用户定调 B 全局服务）

```gdscript
# RelationGraphService.gd autoload
class_name RelationGraphService

# === 写操作 ===
add(from_id, to_id, type, initial_value, source) -> Relation
remove(relation_id) -> bool
adjust_value(relation_id, delta, reason)
add_tag(relation_id, tag)
remove_tag(relation_id, tag)

# === 查操作（只回答事实，不做业务判断）===
get_relation(from_id, to_id, type) -> Relation
get_relations_from(character_id, type_filter = "") -> Array[Relation]
get_relations_to(character_id, type_filter = "") -> Array[Relation]
get_all_relations(character_id) -> Array[Relation]
has_relation(from_id, to_id, type) -> bool

# === 隐式关系（M3 即可用）===
get_implicit_sect_members(character_id) -> Array[character_id]
   # 同 Sect 成员（含弟子 / 长老 / 门主）—— 通过 SectService 查询，不进 RelationGraph
get_implicit_master(character_id) -> character_id
   # 当前 MASTER_CURRENT —— 通过 SectService 查询

# === Signal（消费方订阅）===
signal relation_added(relation)
signal relation_removed(relation, reason)
signal relation_value_changed(relation, old, new, reason)
signal relation_tag_added(relation, tag)
```

### 6.3 关系类型注册表（数据驱动）

`data/relations/types.tres`：M3 列 schema，**不投放具体关系数据**。

> 用户定调（2026-05-29）：删除复杂关系（救命之恩 / 杀亲之仇 / 因果纠葛 / 合作 / 竞争），M3-M5 阶段聚焦情感类。

| 大类 | 子类型 | 默认数值范围 | 是否双向 | 备注 |
|---|---|---|---|---|
| **师承**（M3 隐式推导，不存）| 师徒 / 同门 | — | — | 通过 Sect.member_ids 推导 |
| **情感** | friend（好友）| -100 ~ 100 | 双向 | M5+ |
| | romantic（道侣）| 0 ~ 100 | 双向 | M5+ |
| | confidant（知己）| 0 ~ 100 | 双向 | M5+ |
| | hostile（仇敌）| -100 ~ 0 | 双向 | M5+ |

> 4 种情感类 + 隐式师承 = M5+ 关系系统的起步范围。
> 修仙特色关系（救命之恩 / 杀亲之仇 / 因果纠葛）等更复杂关系**未来如需**通过 §6.9.4 加新系统流程引入，不在 M1 提前承诺。

> **数据 schema**（`data/relations/types.tres` 一行）：
> ```yaml
> id: "friend"
> display_name: "好友"
> category: "情感"
> value_range: [-100, 100]
> bidirectional: true
> default_initial_value: 30
> tags_allowed: ["sealed", "secret", "renounced"]
> ```

### 6.4 M3 实施范围

| 项 | M3 是否做 |
|---|---|
| RelationGraph schema | ✅ 数据类 + 服务接口 |
| RelationGraphService autoload | ✅ 写 / 查 API（含空实现）|
| 关系类型注册表 | ✅ schema + 9 种类型 schema 列入 |
| **实际关系数据投放** | ❌ M5+ |
| **关系 UI** | ❌ M5+ |
| **关系驱动事件 / 战斗影响** | ❌ M5+（消费方系统决定）|
| 师徒 / 同门隐式推导 | ✅ 通过 SectService 查询（无需 RelationGraph）|

### 6.5 未来扩展点（业务消费方 · 不限定死）

> 用户原则：关系系统提供**事实**，不提供**规则**。
> 下面列举消费方系统**可能**如何使用关系，但具体影响公式由各系统自定义。

| 消费方 | 可能消费方式 |
|---|---|
| BattleResolver | 查询 has_relation(A, B, "hostile") → 计算战斗加成 |
| EventResolver | 查询 get_relations_from(character) → 触发"故人来访" / "仇人寻仇"事件 |
| CultivationService | 查询 has_relation(A, B, "romantic") → 双修 buff |
| RecruitmentService | 查询 get_relations_to(character, "gratitude") → 报恩 NPC 主动来投宗 |
| ExpeditionService | 查询 get_implicit_sect_members → 派遣组队 |

**纪律**：
- 消费方**只调用查询 API**，不直接读 Relation 字段（§6.9.1）
- 消费方**自己定义**业务规则（如"仇敌相遇战斗力 +20%"是 BattleResolver 的事，不是 RelationGraph 的事）
- 加新关系类型 = 加 1 行 `data/relations/types.tres`，不改服务代码

### 6.6 数据驱动落地

| 表 / 资源 | 路径 | 内容 |
|---|---|---|
| 关系类型注册 | `data/relations/types.tres` | 9 种类型 schema（M3 列出，内容 M5+ 填）|
| 关系数据 | 运行时存 SaveService（`save.relations[]`）| M3 全空 |

### 6.7 实现要点（M3）

- `Relation.gd` 数据类
- `RelationGraphService.gd` autoload（含完整 API，部分查询 M3 永返空）
- `data/relations/types.tres` schema 文件就位
- 单元测试覆盖：
  - 添加 / 删除 / 查询 API
  - 双向关系约束（如 friend 添加时自动建立 B → A 反向关系）
  - 隐式关系查询（通过 SectService）
  - 序列化 / 反序列化（M3 空数据测试）

---

## 7. M3 默认 buff 类型清单（汇总各章节定义的 buff）

> 本节是收尾汇总——把 §1-§5 设计中提及的 buff 类型整理成 M3 必须实现的清单。
> 详见 ADR-0005 通用 Buff 系统的双表注册机制。
>
> 下面所有 buff 都遵循 ADR-0005 的双表格式：
> - **表 A（BuffType 定义）**：声明大类 / 小类 / 数值字段 / 适用 target / handler
> - **表 B（BuffInstance 模板）**：具体的 buff_id 实例 + 默认数值 + 时长

### 7.1 角色相关 buff（M3 启用 ✅）

#### 受伤（综合伤害）

```yaml
# 表 A · BuffType
category: "injury"                # 大类：伤病
subtype:  "general_wound"         # 小类：综合外伤
display_name_cn: "受伤"
description_cn: "角色受到的综合伤害，0-100，达到 100 触发死亡"
applicable_targets: [CHARACTER]
attributes_schema:
  level: {type: int, min: 0, max: 100, default: 0}   # 受伤等级 0-100
tags: ["debuff", "cleansable"]
default_stack_policy: "stack"     # 同类叠加（多次受伤累加）
monthly_tick_handler: "InjuryService.on_general_wound_tick"  # 每月可恢复 / 加重
```

```yaml
# 表 B · BuffInstance（M3 默认）
buff_id: "buff_injury_general_default"
type_subtype: "general_wound"
default_attributes: {level: 10}     # 默认轻伤
default_duration_months: -1          # 永久（直到 InjuryService 治愈或死亡）
description_override: "受伤"
source_tag: "battle_default"
```

> 用法：战斗 / 历练事件中受伤时调用 `BuffService.apply_by_id("buff_injury_general_default", c, override={"level": 30})`。
> InjuryService 监听该 buff 的 level 变化，达到 100 → ActionState DEAD。

#### 灵气加速（修炼加速）

```yaml
# 表 A
category: "cultivation"           # 大类：修炼
subtype:  "qi_acceleration"       # 小类：灵气加速
display_name_cn: "灵气加速"
description_cn: "修炼速度提升 X%（百分比）"
applicable_targets: [CHARACTER, SECT]   # 角色 或 全宗门
attributes_schema:
  percent: {type: int, min: 0, max: 500, default: 10}    # 加速百分比，10 表示 +10%
tags: ["buff", "cultivation"]
default_stack_policy: "stack"     # 多个来源累加（灵泉 + 阵法 = 累加加速）
monthly_tick_handler: ""           # 不主动 tick，由消费方查询
```

```yaml
# 表 B · 角色短期版
buff_id: "buff_qi_acceleration_minor"
type_subtype: "qi_acceleration"
default_attributes: {percent: 10}
default_duration_months: 1
description_override: "微弱灵气加速"

# 表 B · 宗门级（灵气潮汐事件用）
buff_id: "buff_qi_acceleration_sect_tide"
type_subtype: "qi_acceleration"
default_attributes: {percent: 30}
default_duration_months: 6
description_override: "宗门灵气浓郁"
```

> 用法：CultivationService 在计算修炼速度时查 `BuffService.sum_attribute(c, "cultivation", "qi_acceleration", "percent")`，结果累加到 base_speed × (1 + 总和%)。
> 宗门挂的 buff 由 ProductionService 监听后 fan-out 到全弟子。

#### 闭关边际递减

```yaml
# 表 A
category: "cultivation"
subtype:  "closed_door_decay"     # 小类：闭关边际递减
display_name_cn: "闭关疲态"
description_cn: "连续闭关产生的边际效应衰减（§2.4 边际递减原则）"
applicable_targets: [CHARACTER]
attributes_schema:
  consecutive_months: {type: int, min: 1, max: 999, default: 1}  # 第几个月连续闭关
tags: ["debuff", "cultivation"]
default_stack_policy: "replace"   # 同类替换（一个角色只有一个连续闭关 buff）
monthly_tick_handler: "CultivationService.on_closed_door_tick"   # 每月递增 consecutive_months
```

```yaml
# 表 B
buff_id: "buff_closed_door_decay_default"
type_subtype: "closed_door_decay"
default_attributes: {consecutive_months: 1}
default_duration_months: -1        # 永久（直到角色离开闭关状态自动移除）
```

> 用法：角色进入 IN_CULTIVATION 时挂上；CultivationService 计算修炼收益时查 consecutive_months 应用衰减系数（如 1=100%、2=50%、3=25%）。
> 角色离开闭关 → 移除 buff，重置计数。

### 7.2 角色相关 buff（M3 schema 就位 / 内容 M5+ 启用 ⏳）

#### 战斗虚弱

```yaml
# 表 A
category: "battle"
subtype:  "wounded_aftermath"     # 小类：战后虚弱
display_name_cn: "战斗虚弱"
description_cn: "战斗后短期内属性下降 X%"
applicable_targets: [CHARACTER]
attributes_schema:
  percent: {type: int, min: 0, max: 100, default: 20}   # 下降百分比
tags: ["debuff", "battle"]
default_stack_policy: "refresh"   # 多次战败刷新时长，不叠加
```

```yaml
# 表 B（M5+ 投放）
buff_id: "buff_battle_aftermath_default"
type_subtype: "wounded_aftermath"
default_attributes: {percent: 20}
default_duration_months: 2
```

#### 灵根临时增益（短期丹药用）

```yaml
# 表 A
category: "cultivation"
subtype:  "root_boost"            # 小类：灵根临时增益
display_name_cn: "灵根感应"
description_cn: "短期内某灵根 +X 点（不污染 base，到期自动移除）"
applicable_targets: [CHARACTER]
attributes_schema:
  element: {type: str, default: "fire"}   # 哪个元素（metal/wood/water/fire/earth/...）
  amount:  {type: int, min: 1, max: 50, default: 3}    # +X 点
tags: ["buff", "cultivation"]
default_stack_policy: "stack"
```

```yaml
# 表 B（M5+ 投放，举例）
buff_id: "buff_root_boost_fire_3m"
type_subtype: "root_boost"
default_attributes: {element: "fire", amount: 3}
default_duration_months: 3
description_override: "火灵丹"
```

#### 突破丹（突破概率增益）

```yaml
# 表 A
category: "cultivation"
subtype:  "breakthrough_aid"      # 小类：突破辅助
display_name_cn: "突破之兆"
description_cn: "下次突破时基础概率 +X%"
applicable_targets: [CHARACTER]
attributes_schema:
  percent: {type: int, min: 0, max: 100, default: 10}
tags: ["buff", "cultivation"]
default_stack_policy: "stack"
```

```yaml
# 表 B（M5+ 投放）
buff_id: "buff_breakthrough_aid_minor"
type_subtype: "breakthrough_aid"
default_attributes: {percent: 10}
default_duration_months: 6
description_override: "凡品突破丹"
```

#### 走火入魔（突破失败惩罚 · 可选）

```yaml
# 表 A
category: "injury"
subtype:  "qi_deviation"          # 小类：走火入魔
display_name_cn: "走火入魔"
description_cn: "突破失败导致经脉受损，无法修炼"
applicable_targets: [CHARACTER]
attributes_schema:
  severity: {type: int, min: 1, max: 10, default: 3}   # 严重程度
tags: ["debuff", "injury", "blocks_cultivation"]   # blocks_cultivation 标签让 CharacterService.can_do(c, "cultivate") 返回 false
default_stack_policy: "refresh"
```

```yaml
# 表 B
buff_id: "buff_qi_deviation_default"
type_subtype: "qi_deviation"
default_attributes: {severity: 3}
default_duration_months: 2
```

### 7.3 寿元相关 buff（M3 schema / 内容 M5+ ⏳）

```yaml
# 表 A · 长寿血脉（永久）
category: "lifespan"
subtype:  "longevity_bloodline"
display_name_cn: "长寿血脉"
description_cn: "血脉天赋带来永久寿元 +X 月"
applicable_targets: [CHARACTER]
attributes_schema:
  months: {type: int, min: 0, max: 99999, default: 240}    # +月数
tags: ["buff", "lifespan", "permanent"]
default_stack_policy: "stack"
```

```yaml
# 表 A · 延寿丹（永久）
category: "lifespan"
subtype:  "elixir_extension"
display_name_cn: "延寿丹之效"
description_cn: "服用延寿丹永久 +X 月"
attributes_schema:
  months: {type: int, default: 60}
```

```yaml
# 表 A · 禁术（损寿换战力）
category: "lifespan"
subtype:  "forbidden_art"
display_name_cn: "禁术反噬"
description_cn: "修炼禁术，损寿 X 月换取战斗力提升"
attributes_schema:
  months_lost: {type: int, default: 24}            # 损失寿元
  combat_power_boost_pct: {type: int, default: 30} # 战斗力 +%
```

```yaml
# 表 A · 诅咒（持续损寿）
category: "lifespan"
subtype:  "cursed"
display_name_cn: "诅咒"
description_cn: "中诅咒每月寿元持续 -X"
attributes_schema:
  months_per_tick: {type: int, default: 1}
monthly_tick_handler: "LifespanService.on_curse_tick"
```

### 7.4 宗门相关 buff（M3 schema / 内容 M5+ ⏳）

```yaml
# 表 A · 灵气浓郁（宗门所在地，长期）
category: "environment"
subtype:  "qi_richness"
display_name_cn: "灵气浓郁"
description_cn: "宗门所在地灵气浓度 X 等级（影响修炼 / 招收）"
applicable_targets: [SECT]
attributes_schema:
  tier: {type: int, min: 1, max: 5, default: 2}
```

```yaml
# 表 A · 邻宗来袭（debuff）
category: "external"
subtype:  "under_attack"
display_name_cn: "外敌来袭"
description_cn: "宗门处于被攻击状态，影响声望 / 阻止建设"
applicable_targets: [SECT]
attributes_schema:
  intensity: {type: int, min: 1, max: 5, default: 1}
```

```yaml
# 表 A · 主线大事件加成
category: "external"
subtype:  "imperial_blessing"
display_name_cn: "天降福泽"
description_cn: "重大主线事件触发的资源 / 声望加成"
applicable_targets: [SECT]
attributes_schema:
  resource_bonus_pct: {type: int, default: 20}
```

```yaml
# 表 A · 士气低落（占位 · 触发条件 M5+ 待定）
category: "internal"
subtype:  "morale_low"
display_name_cn: "士气低落"
description_cn: "弟子士气过低（具体触发条件 GDD-05 平衡时定）"
applicable_targets: [SECT]
attributes_schema:
  level: {type: int, min: 1, max: 5, default: 1}
```

### 7.5 特性相关 buff（M3 schema / 内容 M5+ ⏳）

特性（trait）本质是"永久 buff 包"——挂上特性 = 自动应用对应永久 buff。
M3 schema 就位，**不投放任何特性**。M5+ 启用时按需配置。

举例（M5+ 占位）：
```yaml
buff_id: "buff_trait_diligent"          # 勤奋特性
display_name_cn: "勤奋"
attributes: {qi_acceleration_percent: 5}
duration_months: -1                      # 永久

buff_id: "buff_trait_red_flame_root"    # 赤焰血脉特性
display_name_cn: "赤焰血脉"
attributes: {fire_root_amount: 5}
duration_months: -1                      # 永久（火灵根 +5 突破 10 上限）
```

### 7.6 M3 实施清单

#### 必做（✅）

| buff_id | 中文名 | 用途 |
|---|---|---|
| `buff_injury_general_default` | 受伤 | 战斗 / 历练受伤的载体（替代旧 injury_level 字段）|
| `buff_qi_acceleration_minor` | 微弱灵气加速 | 灵泉 / 闭关道场等给加速 |
| `buff_qi_acceleration_sect_tide` | 宗门灵气浓郁 | 宗门级 buff，灵气潮汐事件用 |
| `buff_closed_door_decay_default` | 闭关疲态 | §2.4 边际递减实现 |

#### 可选（M3 视开发节奏 ⚠️）

| buff_id | 中文名 | 用途 |
|---|---|---|
| `buff_qi_deviation_default` | 走火入魔 | 突破失败惩罚（§2.5）|
| `buff_battle_aftermath_default` | 战斗虚弱 | M3 战斗简化版可不做 |

#### 仅 schema（M5+ 启用 ⏳）

- `buff_root_boost_*` 灵根临时增益
- `buff_breakthrough_aid_*` 突破丹
- 所有 lifespan 类
- 所有 SECT 类（除 qi_acceleration_sect_tide）
- 所有 trait 类

---

## 8. 宗外角色（NonSect）·  schema 复用确认

### 8.1 §8 在解决什么问题

游戏中除了"本宗角色"（门主 / 弟子 / 长老），还有大量**不属于本宗的角色**：

- 历练时打的怪物 / 妖兽
- 历练里遇到的路人 NPC（求救者 / 商人 / 隐士）
- 招收前的"求道者"（招进来才变成弟子）
- 未来的异宗弟子 / 主线 BOSS

**问题**：这些"宗外角色"需不需要单独的数据结构？还是和本宗角色共用一套？

### 8.2 结论：共用一套 Character 数据结构

> **本节核心结论**：所有宗内 / 宗外角色都用同一个 Character 数据结构。
> 区别只在两个字段：
> - `identity = NON_SECT`（标识"宗外人"）
> - `non_sect_role = "妖兽" / "路人" / "商人" / "异宗弟子"`（细分类型）

#### 实例对照

| 用例 | identity | non_sect_role | 数据结构 |
|---|---|---|---|
| 本宗弟子 | DISCIPLE | "" | Character |
| 历练打的妖兽 | NON_SECT | "妖兽" | Character |
| 路过的商人 | NON_SECT | "商人" | Character |
| 招收前的求道者 | NON_SECT | "求道者" | Character |
| 未来的异宗弟子（M5+）| NON_SECT | "异宗弟子" | Character |
| 主线 BOSS（M5+）| NON_SECT | "邪修" | Character |

#### 招收转身份示例

```
玩家招收一个求道者：
  Character{ identity=NON_SECT, non_sect_role="求道者" }
        ↓ 玩家选了招进来
  Character{ identity=DISCIPLE, non_sect_role="" }   # 不创建新对象，只改字段
```

### 8.3 字段复用情况

所有 Character 字段在宗外角色都有用：

| 字段 | 本宗用途 | 宗外用途 |
|---|---|---|
| 名字 / 性别 / 立绘 / 年龄 | 玩家界面显示 | 历练 UI 显示敌人信息 |
| 灵根 / 5 个属性 | 修炼 / 培养 | 战斗时计算妖兽 / 邪修战力 |
| 境界 / 寿元 | 突破 / 老死 | 妖兽也有境界（化形 / 妖丹），有寿元 |
| 主修功法 / 装备 | 玩家可操作 | 战斗 BattleResolver 消费（M5+）|
| buffs | 中毒 / 加速等 | 怪物也能中毒 / 受伤 |

唯一差别：**玩家不能操作宗外角色**（不能让他们闭关 / 派遣）。
通过 `CharacterService.can_do(c, action)` 综合校验：
```
if action in ["cultivate", "expedition_dispatch"] and c.identity == NON_SECT:
    return false
```

### 8.4 NonSect 也走 CharacterGenerator

按 §5.2 的统一生成机制，宗外角色也通过 CharacterGenerator 生成，使用不同 template：

| 用例 | template 示例 | 资质偏好 |
|---|---|---|
| 历练敌人（妖兽）| `data/character/templates/expedition_beast_<level>.tres` | 按地图等级配 |
| 历练 NPC | `data/character/templates/expedition_npc.tres` | 偏低 |
| 求道者 | `data/character/templates/passive_seeker.tres`（即 §5.6 自动来投）| 偏低 |
| 异宗弟子（M5+）| `data/character/templates/foreign_disciple.tres` | 偏中 |
| 主线 NPC（M5+）| 单角色单 template + override | 高度定制 |

### 8.5 §8 的设计含义

这一节其实在文档上**明确告诉未来的人**：宗外角色不需要造一套新的"敌人系统" / "NPC 系统"，全部复用 Character。

这是 §6.9 解耦原则的实证：**一套数据结构，多种身份用法**。
未来加新身份（如 M5+ 加"客卿" / "魔修"）只是再多一个 identity 枚举值，不需要新数据类型。

### 8.6 实现要点（M3）

- Character schema 不增字段（已通过 §5 / ADR-0003 修订完整）
- CharacterGenerator 支持 `identity` 通过 template 配置
- `CharacterService.can_do` 集成 identity 校验
- 单元测试：NonSect 角色尝试调用宗门内功能 → 返回 false 并 log

---

## verdict

**GDD-CHANGES → 进入用户审视**：

§1-§8 全部就位：
- ✅ §1 灵根（5 行 + 变异预留 + 离散点数 + 无硬上限 + 双段式分布）
- ✅ §2 境界与寿元（5×9 + 飞升 + 突破公式 + 不外显寿元 + GameOver）
- ✅ §3 属性维度（5 个面板属性 + 战斗力派生 + 6 级品质 + 主修功法）
- ✅ §4 寿元规则（已并入 §2）
- ✅ §5 弟子招收与角色生成（CharacterGenerator + 灵根两段式 + 立绘 / 名字标签）
- ✅ §6 关系网（schema 占位 / 内容 M5+）
- ✅ §7 M3 默认 buff 类型清单（汇总）
- ✅ §8 NonSect schema 完整性审视

待用户审：
- 关系类型清单（§6.3）是否需要增减？
- §7 M3 启用清单（4 个 ✅ buff）是否合适？
- §8 NonSect 字段是否漏了什么？
- 是否启动下一章（GDD-03 历练 + 战斗系统）？
