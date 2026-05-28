---
adr_id: 0003-character-state-machine
status: accepted
date: 2026-05-23
accepted_at: 2026-05-26
deciders: [用户, codebuddy]
supersedes:
related_gdd: gdd-01 §2.5 失败死亡处理 / §6.3 角色统一状态机 / §6.8 战斗系统框架
---

# ADR 0003 · 角色统一数据结构与三维度状态

## 上下文

xiuxian 的核心设定：**门主 / 弟子 / 长老 / 宗外人物 在角色层面是同一种数据**，区别只在状态。

用户定调（GDD-01 §2.5 + 2026-05-23 v3 三维度拆分）：
- **身份**（identity）和**行动状态**（action state）是**两个独立维度**——之前混在一个 enum 是设计错误
- 中毒 / 受伤 / 灵气加速等**临时修饰**走通用 buff 系统（详见 ADR-0005），不是 Character 上的字段
- 长老阁是"主动卸任的奖励状态"，被动死亡不进长老阁

如果不统一处理：
- "门主能不能炼丹" / "弟子能不能闭关" / "长老能不能出战" 会散落成几十处 if 判断
- 加新状态 / 新身份时要改全局
- 存档结构会因角色身份不同而分裂
- 中毒 / 受伤等"叠加状态"放在一个 enum 里互斥，导致"不能既受伤又中毒"

## 决策

采用 **三维度独立 + 通用 Buff 系统 + 服务层操作** 架构。

### 三维度拆分

| 维度 | 性质 | 值域 | 变化频率 | 互斥性 |
|---|---|---|---|---|
| **Identity** 身份 | 长期稳定 | MasterCurrent / Disciple / Elder / NonSect | 重大事件触发（继位 / 传位 / 招收）| 互斥（一个角色只有一种身份）|
| **ActionState** 行动状态 | 即时，每月刷新 | Idle / InCultivation / Dead（M3）| 每月节拍或事件触发 | 互斥（一个角色当前只有一种行动状态）|
| **Buffs** 修饰器 | 多个并存 | 由 BuffService 统一管理（ADR-0005）| 时长到期 / 主动解除 | 不互斥（多个 buff 同时存在）|

### Character 数据结构（M3 必须有，部分字段可空）

```gdscript
class_name Character

# === 实现 IBuffable 接口（详见 ADR-0005）===
var target_type: TargetType = TargetType.CHARACTER
var target_id: String                # 全局唯一角色 id（同 self.id）
var buffs: Array = []                # Array[Buff]，由 BuffService 管理

# 身份（长期）
enum Identity {
    MASTER_CURRENT,    # 现任门主
    DISCIPLE,          # 本宗弟子
    ELDER,             # 长老阁（仅主动传位的前门主）
    NON_SECT,          # 宗门外人物（路人 / 敌人 / 异宗弟子 / 神秘 NPC...）
                       # 未来可在 NonSectRole 子枚举或标签中细分
}

# 行动状态（即时，每月可刷新）
enum ActionState {
    IDLE,              # 空闲（默认，可被指派任务）
    IN_CULTIVATION,    # 修炼中（含闭关 / 普通修炼，由 state_data 区分子状态）
    DEAD,              # 死亡（终态）
    # 未来按系统扩展（参考 Identity 同纪律）：
    # IN_EXPEDITION（历练中，待 GDD-03 历练系统讨论后加入或不加）
    # 其他系统引入时按需新增，每加 1 个状态走 ADR 增订
}

# 核心字段
var id: String
var name: String
var identity: Identity
var action_state: ActionState
var non_sect_role: String = ""       # 当 identity = NON_SECT 时填（"路人" / "异宗" / "敌人" 等扩展点，M3 占位）

# 修仙属性
var spirit_root: SpiritRoot
var realm: Realm                     # 境界
var lifespan_remaining: int          # 寿元（月）
var attributes: Dict                 # atk / def / spd / 灵力 / 心性 ...

# 战斗衍生字段（M3 占位 / M5 启用）
var skills: Array = []               # Array[SkillId]
var equipped: Dict = {}              # Dict[Slot, ItemId]

# 各状态附加数据（按 action_state 不同语义）
var action_state_data: Dict = {}     # 例：IN_CULTIVATION → {mode: "closed_door", since_month: 5, consecutive_count: 3}
                                     #      DEAD → {died_at_month: 27, cause: "injury_overflow"}
                                     # 受伤恢复期已通过 buff 表达（injury/general_wound），不需要独立行动状态
```

> **关键修正（v3.1 · 2026-05-25）**：
> 删除了旧版 `injury_level: float` 字段。
> 受伤值是 buff 的查询结果（`InjuryService.get_injury_level(character)` 内部走 `BuffService.sum_attribute`），**不是 Character 上的字段**。
> 这避免了"修饰器又造一个独立字段"的架构倒退，符合 §6.10 buff 系统精神。
>
> 受伤系统（InjuryService）成为 buff 的**消费者 + 监控者**：订阅 buff signal，在 injury_level 累计 ≥ 100 时触发 ActionState DEAD。详见 ADR-0005 §4。

### Identity 转移规则（数据驱动 · `data/character/identity_transitions.json`）

```json
{
  "DISCIPLE":        ["MASTER_CURRENT", "NON_SECT"],
  "MASTER_CURRENT":  ["ELDER"],
  "ELDER":           [],
  "NON_SECT":        ["DISCIPLE"]
}
```

> 注：身份转移**不**包含 DEAD，因为死亡是 action_state 维度。
> NON_SECT → DISCIPLE 是"招收"路径；DISCIPLE → NON_SECT 是"叛门后离宗"路径（叛门事件触发 identity 直接转 NON_SECT，不需要独立的 DEFECTED action 状态——叛门后角色就不再是本宗成员）。

### ActionState 转移规则

ActionState 转移相对宽松，由各系统按场景调用：
- 任何 action_state 都可在角色死亡时转 DEAD（终态）
- IDLE ↔ IN_CULTIVATION（自由切换，由场景控制）
- M3 仅 3 状态，未来按系统扩展（参考 Identity 同纪律 · 走 ADR 增订）
- 死亡触发条件：injury 累计 ≥ 100（由 InjuryService 监听 buff 触发）/ 寿元为 0 / 战斗死亡 outcome / 主动赐死等

### 门主继位的两种路径（用户定调 v2，未变）

| 路径 | 老门主结局 | 触发场景 | 实现要点 |
|---|---|---|---|
| **a · 被动死亡（紧急继位）** | identity 不变 + action_state → DEAD（**不进长老阁**）| 历练战死 / 寿元耗尽 / 走火入魔 | 系统强制弹"必须指定弟子继任"UI；继任者 identity DISCIPLE → MASTER_CURRENT |
| **b · 主动传位（荣养）** | identity MASTER_CURRENT → ELDER（保留所有属性）| 玩家在宗门界面主动选"传位" | 老门主进 ELDER 后保留属性 / 装备 / 技能 / 行动状态 |

**关键纪律**：
- `MASTER_CURRENT → ELDER` 的 identity 转移**只能**由 `reason="master_abdicated"` 调用，service 层强制
- 门主 action_state 进 DEAD 时**必须**先解决继位（否则游戏数据非法）

### 核心 API 规则

1. 所有"X 角色能不能做 Y"的判断走 `CharacterService.can_do(character, action)` ——内部综合查询 identity + action_state + buffs
2. 身份转移走 `CharacterService.change_identity(character, new_identity, reason)` ——禁止外部直改 `character.identity`
3. 行动状态转移走 `CharacterService.set_action_state(character, new_state, data)` ——禁止外部直改 `character.action_state`
4. Buff 操作走 `BuffService`（ADR-0005），不直接改 `character.buffs`
5. **伤病值变化走 `InjuryService.apply_wound(character, level_delta, source)`** ——内部走 BuffService 操作 injury buff，监控累计值，到 100 时触发 ActionState DEAD（详见 ADR-0005 §4）

## 候选方案

| # | 方案 | 优点 | 缺点 | 结论 |
|---|---|---|---|---|
| 旧 A | 单一 enum 混合身份 + 行动 + 临时（旧版 ADR）| 实现最简 | 互斥语义错（不能"门主在闭关中"）/ 加临时状态炸 enum / buff 没法叠加 | ❌ 放弃（用户否决）|
| **新 A** | **三维度独立 + 通用 Buff（本 ADR）** | 各维度正交 / buff 任意叠加 / 加新身份 / 行动 / buff 都不互相影响 | 三个维度的 service 调用规范要培养 | ✅ 选择 |
| B | 继承层级（Master extends Disciple extends Character）| 类型安全 | 不能"实例转换身份"（门主退位无法变成 Elder 实例）/ Godot 类继承换身份痛苦 | ❌ 放弃 |
| C | Tag 系统（角色挂多个 tag，无显式枚举）| 灵活 | 互斥关系无法表达 / 类型不安全 / 容易脏数据 | ❌ 放弃 |
| D | 多张表（disciples 表 / masters 表 / elders 表）| 关系数据库友好 | 不适合单机存档 / 身份转换跨表搬运 | ❌ 放弃 |

## 理由

- **新 A 选择理由**：身份 / 行动 / 修饰器是三个**正交维度**——门主可以闭关也可以中毒，弟子也可以受伤也可以灵气加速。把它们并入一个 enum 是逻辑错误。三维度独立后：
  - 加新身份（如 M5 的"客卿"）只动 Identity enum + 转移规则
  - 加新行动状态（如 M5 的"渡劫中"）只动 ActionState enum
  - 加新 buff 类型（如 M5 的"心魔"）只动 buff 数据，不改 Character schema
- **旧 A 放弃理由**：用户审 v2 时指出"维度有问题"——这是设计错误而非细节调整
- **B/C/D**：理由同前 ADR

## 影响

### 正面

- 三维度正交：加新身份 / 行动 / buff 都不互相影响
- Buff 系统从一开始就内建（M3），M5 加技能 / 装备 / 状态效果时复用
- NonSect 身份让敌人 / 路人共享 Character schema，符合 §6.9 解耦
- 配合 ADR-0004 存档分区，character 段独立可迁移
- 伤病系统简化为单一 injury_level（0~100），未来可拆细而不破坏 schema

### 负面

- 三个维度的 service 调用规范要团队培养（不能直接改字段）
- BuffService（ADR-0005）必须先于 M3 实现（多了一个前置 ADR）
- 旧版本 ADR 中"INJURED 是状态"的心智模型需要刷新（受伤是 buff `injury/general_wound`，不是行动状态字段）

### 风险

| 风险 | 概率 | 缓解 |
|---|---|---|
| 开发者绕过 service 直接改字段 | 中 | code review + linter 规则（M2 后期）+ 单元测试 |
| 三维度组合出现非法状态（如 NON_SECT + IN_CULTIVATION 用本宗修炼资源）| 中 | service 层 can_do 综合校验；非法组合通过单元测试枚举 |
| BuffService 设计延迟 → M3 没有 buff 框架 | 中 | 立即建 ADR-0005（已建）+ 优先级提到 M2 早期 |
| NonSect 子分类（路人/敌人/异宗）未来扩展时 schema 不够 | 中 | M3 用 `non_sect_role: String` 字符串占位；未来可升级为枚举 / 子类型 |
| 伤病系统简化版 → 复杂版升级路径 | 中 | 旧版已删 injury_level 字段；走 buff 路径，未来加中毒/外伤等 subtype 自然累加 |
| 衍生字段 M5 实现时发现 schema 不够 | 中 | M2 GDD-02 完成后请 architect agent review schema 完整性 |

## 实现要点（M2 任务）

- `Character.gd`（数据类，实现 IBuffable 协议）+ `CharacterService.gd` autoload
- `data/character/identity_transitions.json`
- `change_identity(character, new_identity, reason)` / `set_action_state(character, new_state, data)` 双 API
- `can_do(character, action)` 综合查询（含 buff 影响）
- 单元测试覆盖：
  - Identity 4 种合法转移
  - 至少 5 种非法 identity 转移被拒绝
  - **门主双路径继位**：
    - 被动死亡 → action_state DEAD + 强制继位
    - 主动传位 → identity ELDER 只能由 reason=master_abdicated 触发
  - 三维度组合非法状态被拒绝（如 NON_SECT + IN_CULTIVATION 占用本宗修炼资源）
  - 序列化 / 反序列化（含 buffs / skills / equipped 占位字段）
  - **伤病通过 buff 触发死亡**：累计 buff `injury/general_wound` level 到 100 → 角色 ActionState 自动转 DEAD（由 InjuryService 监听 buff signal 实现）

## 关联

- GDD：gdd-01 §2.5 / §6.3 / §6.8
- 待建：GDD-02 角色与境界系统（本 ADR 是其前置）
- 其他 ADR：
  - **ADR-0005 通用 Buff 系统**（必读前置；伤病 / 修炼 / 战斗状态等都走 buff）
  - ADR-0002 战斗接口（消费 Character.attributes / skills / equipped / buffs 字段）
  - ADR-0004 存档架构（character 数据如何分区序列化）
