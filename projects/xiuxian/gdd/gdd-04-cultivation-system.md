---
gdd_id: 04
gdd_title: 成长系统
status: drafting
last_review: 2026-06-03
sections_complete: [设计精神, 经验修为境界, 闭关机制, 突破机制, 灵根成长, 心境与顿悟占位, Buff库, 寿元加成, 接触面, 风险扩展]
sections_pending: []
upstream_adr: [0003-character-state-machine, 0005-buff-system]
upstream_gdd: [gdd-01, gdd-02]
verdict: drafting
---

# GDD-04 · 成长系统

> v3.1 新增章节（2026-06-03 用户定调）。承接 GDD-01 §6.12 角色契约 vs 玩法分离哲学：**GDD-02 仅定义角色契约（字段 / 状态 / 接口）**，**GDD-04 持有所有"怎么成长"的玩法逻辑**——闭关公式、突破规则、灵根觉醒、心境顿悟、寿元加成、Buff 库等。
>
> 上游：GDD-01 §6.10 / §6.12，GDD-02（角色契约），ADR-0003 / ADR-0005

---

## 1. 设计精神

### 1.1 哲学定位

成长系统是**玩家投入资源 / 时间 → 角色属性变化**的所有玩法的归口章节。它不是契约（契约在 GDD-02），不是数值（数值在 GDD-06），是**行为规则**——"投入 X 类资源 N 个月会得到什么"。

### 1.2 子系统的职责

```
GDD-04 成长系统
├─ 经验/修为/境界转换体系（§2）
├─ 闭关机制（§3）：cultivating 状态的具体玩法
├─ 突破机制（§4）：大境界跨越的概率公式 + 失败惩罚
├─ 灵根成长（§5）：永久强化 / 临时增益的渠道
├─ 心境 / 顿悟（§6）：M5 占位
├─ Buff 库与触发规则（§7）：成长干预手段
├─ 寿元加成（§8）：境界提升给寿元
├─ 与角色契约的接触面（§9）
└─ 风险与扩展（§10）
```

### 1.3 与其它系统的关系

```
玩家亲跑历练（GDD-03）── 写经验 / 资源 ──► CharacterService（GDD-02）
派遣弟子（GDD-03 §5）── 拟合写经验 ──► CharacterService
宗门建筑（GDD-05）── modifier 注入 ──► GDD-04 闭关公式
经济资源（GDD-06）── 突破丹 / 灵石消耗 ──► GDD-04 突破公式
                                           │
                                           ▼ 调 GDD-02 接口
                                       character.add_experience(N)
                                       character.set_state("breakthrough_pending")
                                       character.add_buff(buff)
```

**关键纪律**：

- 成长系统**不直接读写** `character.experience` 字段——必须通过 GDD-02 的 `add_experience` / `try_breakthrough` / `set_state` 等接口
- 任何"加 modifier"行为通过 BuffService 实现（不是 character 字典塞自定义字段）
- 跨系统调用走 EventBus signal（如 `breakthrough_succeeded`）

---

## 2. 经验 / 修为 / 境界转换体系

### 2.1 三层概念

| 概念 | 含义 | 字段（在 GDD-02）|
|---|---|---|
| **经验**（experience） | 角色当前小境界的修炼进度 | `character.experience` |
| **修为分**（cultivation_score） | 大境界瓶颈后累积的"突破投入分" | `character.cultivation_score` |
| **境界**（realm + sub_realm）| 修仙等级 5×9+飞升 | `character.realm` / `character.sub_realm` |

> 经验和修为分是两个独立累加器：经验跨小境界涨 → 满即升小境界 + 清零；修为分仅在大境界 9 层瓶颈后累积，作为突破检定的一项加成。

### 2.2 小境界推进规则

```
角色处于 cultivating 状态
  └─ 月节拍触发：character.add_experience(monthly_gain)
      └─ if experience >= experience_threshold(realm, sub_realm):
            character.add_experience(-experience_threshold)  # 扣阈值
            character.advance_sub_realm()                    # 升小境界
            broadcast signal sub_realm_advanced
```

**`monthly_gain` 公式**（核心）：

```
monthly_gain = base_speed                                      ← 主修功法基础速度（功法 × 境界 表）
             × (1 + Σ aᵢ × effective_rootᵢ)                    ← 灵根加成（§5）
             × cultivation_multiplier(character)               ← buff / 建筑 / 心境 modifier 总和
             × diminishing_factor(continuous_months)           ← 边际递减（GDD-01 §2.3）
```

**`experience_threshold(realm, sub_realm)` 公式**：

```
experience_threshold = base_threshold(realm) × growth_curve(sub_realm)

  base_threshold(realm)：5 大境每境基础阈值（GDD-06 平衡）
  growth_curve(sub_realm)：1-9 层递增曲线（如 sub_realm^1.5）
```

> 具体系数 GDD-06 平衡章定。本章只列公式骨架。

### 2.3 大境界瓶颈机制

```
角色 sub_realm == 9 + experience >= experience_threshold
  └─ 不再自动升大境界
      └─ 进入"瓶颈"状态：cultivating_mode = "bottleneck"
          ├─ 月节拍：cultivation_score += monthly_score_gain  (§2.4)
          ├─ 玩家可在 UI 主动发起 try_breakthrough()  (§4)
          └─ 持续打磨 → 突破成功率提升
```

### 2.4 修为分（cultivation_score）累积公式

```
monthly_score_gain = base_monthly_score                          ← 全局常量（GDD-06）
                   × (insight / 100)                              ← 悟性加成
                   × bottleneck_diminishing(months_in_bottleneck) ← 边际递减
```

**`bottleneck_diminishing` 设计要点**：

- 第 1-12 月：1.0（鼓励玩家立刻冲，让"刚瓶颈就突破"是可行策略）
- 第 13-36 月：0.7（次年开始衰减）
- 第 37+ 月：0.4（避免无限累积）

> 用户定调"瓶颈是策略选择，不是无脑磨"——递减让"立即冲"和"打磨" 各有适用场景。具体曲线 GDD-06 平衡。

---

## 3. 闭关机制

### 3.1 闭关状态语义

闭关 = 角色处于 `cultivating` 状态（GDD-02 状态机）。本节定义该状态的**玩法规则**。

```
玩家发起闭关：CharacterService.set_state(c, "cultivating", { mode: "normal" or "bottleneck" })
  ├─ 角色不可参与历练 / 派遣 / 宗门内务
  ├─ 月节拍持续触发 monthly_gain 经验或 monthly_score_gain 修为分
  ├─ 闭关效率受多个 modifier 加成：
  │    建筑（修炼塔 / 聚灵阵）
  │    Buff（突破丹 / 灵气潮汐 / 心境）
  │    心境状态（M5）
  │    Σa × effective_root
  └─ 玩家随时可结束闭关：CharacterService.set_state(c, "idle")
```

### 3.2 闭关效率 modifier 来源

| 来源 | modifier 类型 | 例 |
|---|---|---|
| 主修功法 | base_speed × root_coefficient | 见 §2.2 公式 |
| 宗门建筑 | `cultivation_speed_bonus` | 修炼塔 lv1=+20% / lv2=+35% / lv3=+50%（SoT: GDD-05 §3.2.3）|
| 灵气环境 | `qi_density_bonus` | 灵泉 buff +20% |
| 突破丹（buff）| `cultivation_speed_bonus` | 临时 +50% / 30 天 |
| 心境（M5）| `insight_bonus` | 顿悟时 +100% / 7 天 |
| 边际递减 | `diminishing_factor` | 详见 §2.2 |

**纪律**：所有 modifier 走 BuffService（GDD-01 §6.10），不直接修改 character 字段。`cultivation_multiplier` 由 BuffService 聚合所有作用于角色的"修炼速度"类 buff 求和。

### 3.3 边际递减实现（GDD-01 §2.3 闭关曲线）

```gdscript
# 闭关连续月数越长 → 单月收益越低
func diminishing_factor(continuous_months: int) -> float:
    return pow(0.5, max(0, continuous_months - 12) / 12.0)
    # 前 12 月：1.0（满）
    # 24 月：0.5
    # 36 月：0.25
    # 这条曲线由 GDD-06 平衡章节确认（占位 (1/2)^t/12）
```

> 此曲线设计意图（GDD-01 §2.3）：让"持续闭关"边际收益快速衰减，倒逼玩家"出关 → 历练 → 再闭关"循环。

### 3.4 状态枚举扩展（注册到 GDD-02）

GDD-04 启动时注册 `cultivating` 状态的子模式：

```gdscript
# CultivationSystem._ready
CharacterRegistry.register_state_mode("cultivating", "normal")     # 普通闭关
CharacterRegistry.register_state_mode("cultivating", "bottleneck") # 瓶颈期（修为分累积）
CharacterRegistry.register_state_mode("cultivating", "deep_retreat")# 深闭关 M5（不响应外部事件）
```

GDD-02 仅定义 `cultivating` 状态枚举存在，子模式语义在 GDD-04 注册。

---

## 4. 突破机制

### 4.1 触发条件

满足以下全部条件玩家才能发起突破（UI 按钮可点）：

- `character.realm < REALM_MAX` 且 `character.sub_realm == 9`
- `character.experience >= experience_threshold(realm, 9)`
- `character.state in ["cultivating:bottleneck", "idle"]`
- 资源足够（GDD-06 定义具体消耗）

### 4.2 突破检定公式（v1，全参数可配）

```
最终突破概率 = clamp(基础概率 + 增益叠加, 0, 1)

────────────────────────────────────
基础概率
────────────────────────────────────
基础概率 = (base_score + MAX(cultivation_score, 10) + root_score + insight_score) / difficulty_score

  base_score        : 该功法在该境界的"突破基础分"（功法 × 境界 表）
  cultivation_score : 角色当前修为分（瓶颈后累积，§2.4）
  MAX(.., 10)       : 保底；瓶颈一刻就能冲，不被锁死
  root_score        : Σ effective_root_i (i ∈ 功法绑定灵根)
  insight_score     : (insight - 100) / 10
  difficulty_score  : 该功法在该境界的"难度系数"（功法 × 境界 表）

────────────────────────────────────
增益叠加（来自 buff / 道具 / 顿悟 / 长老指点）
────────────────────────────────────
+ Σ "突破成功率" 类 buff 的加成（如 buff_id="breakthrough/aid_pill"）
+ 顿悟 buff 加成（M5）
+ 宗门长老阁指点（M5）

────────────────────────────────────
clamp 到 [0, 1]
────────────────────────────────────
- 用户定调 A：无 95% 上限，允许玩家通过极致投入做到 100%
- < 0 视为 0（理论不发生）
```

### 4.3 公式分项说明

| 分项 | 来源 | 设计意图 |
|---|---|---|
| `base_score` | 功法 × 境界 表 | 功法对该境界的"友好度"——高级功法基础分高 |
| `cultivation_score` | 瓶颈月数 × monthly_score_gain | 时间投入 + 悟性加成，瓶颈越久越容易 |
| `MAX(., 10)` | 常量 10（可配）| 保底；瓶颈即刻冲不锁死 |
| `root_score` | 灵根总点数（绑定 i） | 灵根直接影响突破概率 |
| `insight_score` | 悟性属性 | 悟性高 → 突破友好 |
| `difficulty_score` | 功法 × 境界 表 | 高境界 / 低端功法 → 难度大 |
| 增益叠加 | buff / 道具 / 顿悟 | 玩法干预手段 |

### 4.4 突破执行流程

```gdscript
func try_breakthrough(c: Character) -> BreakthroughResult:
    # 1. 校验前置条件（§4.1）
    if not _check_preconditions(c): return BreakthroughResult.PRECOND_FAIL
    
    # 2. 扣资源（GDD-06 定义具体）
    InventoryService.consume(_breakthrough_cost(c.realm))
    
    # 3. 计算最终概率
    var p = _compute_breakthrough_chance(c)
    
    # 4. 设置 breakthrough_pending 状态（UI 演出期）
    CharacterService.set_state(c, "breakthrough_pending")
    
    # 5. 滚 RNG
    var rng = RNG.from_seed(c.seed_breakthrough_offset())
    var roll = rng.randf()
    
    # 6. 应用结果
    if roll < p:
        return _on_breakthrough_success(c)
    else:
        return _on_breakthrough_failure(c)
```

### 4.5 突破成功路径

```
character.realm += 1                           # 升大境界
character.sub_realm = 1                        # 重置小境界为 1
character.experience = 0
character.cultivation_score = 0
CharacterService.add_lifespan(c, lifespan_bonus(realm))   # §8 寿元加成
CharacterService.set_state(c, "idle")
broadcast signal breakthrough_succeeded(c, new_realm)
# 触发宗门事件（GDD-05）/ 弟子身份变化 / 长老阁等级变更等
```

### 4.6 突破失败惩罚（用户定调 · 反向进度）

```
跌 1 小境：character.sub_realm = 8（如果是 9 → 8）
修炼分清零：character.cultivation_score = 0
经验保留：character.experience 不动（玩家已投入的不浪费小境界经验）
挂 buff："injury/breakthrough_failed"（重伤 30 天，闭关效率 -50%）
极小概率走火入魔（M5）：触发 deep_injury 路径，需事件解决
broadcast signal breakthrough_failed(c, old_realm)
CharacterService.set_state(c, "injured")
```

> **走火入魔（M5 占位）**：当突破概率 < 0.10 强行尝试时，失败有 5% 概率触发"走火入魔"——`buff_id = "injury/qi_deviation"`（重伤 + 修炼速度 × 0.2 / 永久至治愈），需通过特殊事件 / 长老治疗解除。M3 不实装，schema 占位。

### 4.7 资源消耗

每次突破检定**无论成败**消耗：

| 资源 | 例（M3 默认）| 配置位置 |
|---|---|---|
| 灵石 | 炼气→筑基 100 / 筑基→金丹 1000 / ... | GDD-06 |
| 突破丹（可选）| 1 颗 = +10% 概率（buff） | GDD-06 |
| 灵气消耗 | 宗门聚灵阵临时降低 -20%（M5）| GDD-05 |

资源不足 → UI 按钮置灰，无法发起。

---

## 5. 灵根成长

### 5.1 灵根作为成长资源

GDD-02 §1 定义灵根字段（`Dict[element_id, int]` 离散点数无硬上限）。本节定义**怎么让灵根成长**。

### 5.2 永久强化渠道（M3 启用）

| 渠道 | 触发 | 效果 |
|---|---|---|
| **奇遇事件** | 历练事件 outcome 包含 `adjust_base_root(c, "fire", +1)` | base 永久 +1 |
| **血脉觉醒** | 主线事件触发（M5）| base × bloodline_multiplier |
| **顿悟**（M5）| cultivating 期间小概率事件 | base 某属性 +1-3 |
| **特殊丹药**（M4+）| 服食"灵根丹"消耗物品 | base 某属性 +1，每境上限 1 次 |

### 5.3 临时增益渠道（buff）

| Buff 类型 | 来源 | 时长 | 效果 |
|---|---|---|---|
| `cultivation/root_boost` | 灵气浓郁 buff | 30 天 | effective +2 某属性 |
| `cultivation/qi_acceleration` | 宗门聚灵阵 | 永久（建筑在）| effective × 1.2 全属性 |
| `cultivation/awakening_bloodline` | 主线（M5）| 永久至触发条件 | effective +5 主属性 |

### 5.4 effective vs base（GDD-02 §1.4 接口）

成长系统通过 BuffService 增加临时 effective：

```gdscript
# 加临时灵根 buff
BuffService.apply(character, BuffData.new({
    buff_id = "cultivation/root_boost_fire",
    duration_months = 30,
    modifiers = { "spirit_root.fire": +2 }
}))
# CharacterService.get_effective_root(c, "fire") 返回 base + buff 总加成
```

GDD-02 提供 `get_effective_root` 接口，BuffService 持有 modifier 聚合，CharacterService 只看接口结果。

### 5.5 资质提升 vs 灵根强化

GDD-02 §3 定义"资质 = 5 显示属性"（悟性 / 体魄 / 神识 / 炼丹 / 炼器）。资质提升与灵根强化机制并行：

| 维度 | 渠道 | 频次 |
|---|---|---|
| 灵根 | 奇遇 / 血脉 / 丹药 / 顿悟 | 稀有（每年 < 1 次）|
| 资质（悟性等）| 修炼塔月加 / 装备 / 突破副产物 | 缓慢累积 |

> 资质提升公式：`monthly_attribute_gain = building_modifier + buff_modifier + diminishing_curve`，类似 §3.2 闭关效率公式。M3 简化：建筑挂 modifier，不做月固定加。GDD-05 详细。

---

## 6. 心境与顿悟（M5 占位）

### 6.1 心境（mental_state）

修仙文学经典概念："心魔" / "心境" / "道心" 影响修炼。M5 实装。M3 schema 占位：

```gdscript
# GDD-02 注册新字段
CharacterRegistry.register_attribute("mental_state", default = "calm")
# 取值：calm / agitated / enlightened / haunted（心魔）
```

### 6.2 顿悟事件（M5）

cultivating 期间小概率触发 "顿悟" 事件（GDD-03 事件引擎），效果：

- mental_state → "enlightened"（持续 7-30 天）
- 闭关效率 ×2-5
- 突破概率 +5-15%
- 可能一次性升小境界

### 6.3 心魔（M5）

突破失败 / 长期重伤 / 主线事件可能触发心魔：

- mental_state → "haunted"
- 闭关效率 × 0.5
- 突破概率 -10%
- 需通过特殊事件 / 道侣 / 长老治疗解除

### 6.4 M3 schema 占位

| 占位 | 内容 |
|---|---|
| Character 字段 | mental_state（GDD-02 注册）|
| Buff 类型 | `cultivation/insight_aura`（顿悟 buff）/ `injury/qi_deviation`（走火入魔 / 心魔 debuff）|
| Event action | M3 已支持 `apply_buff` 可用于 M5 心境系统 |

> M5 详细 GDD-04 amendment 或独立 GDD（视复杂度）。

---

## 7. Buff 库与触发规则

> 本节定义所有"成长干预手段"的 buff。继承 GDD-02 §7 已有 buff 列表，按"成长系统的责任"重新归类。

### 7.1 修炼速度类 buff（M3 ✅）

| buff_id | target | 时长 | 效果 |
|---|---|---|---|
| `cultivation/qi_acceleration` | character | 30 天 | 闭关效率 +20% |
| `cultivation/breakthrough_aid` | character | 7 天 | 突破成功率 +10% |
| `cultivation/root_boost_<element>` | character | 30 天 | 单灵根 effective +2 |
| `cultivation/sect_qi_field` | character | 永久（建筑在）| 闭关效率 +20%（宗门聚灵阵 fan-out）|

### 7.2 突破类 buff（M3 ✅）

| buff_id | 时机 | 效果 |
|---|---|---|
| `breakthrough/elder_guidance` | M5 长老阁指点 | 临时 +15% 突破率 |
| `breakthrough/dao_companion_aid` | M5 道侣双修 | 临时 +10% 突破率 |

### 7.3 心境类 buff（M5 schema 占位）

| buff_id | 时机 | 效果 |
|---|---|---|
| `cultivation/insight_aura` | 顿悟事件 | 闭关效率 ×2-5、突破率 +5-15% |
| `injury/qi_deviation` | 走火入魔 | 修炼效率 × 0.2 / 永久至治愈 |
| `mental/haunted` | 心魔触发 | 突破率 -10% / 闭关效率 × 0.5 |

### 7.4 寿元类 buff（M3 schema / 内容 M5+）

| buff_id | 时机 | 效果 |
|---|---|---|
| `lifespan/realm_bonus` | 突破成功（系统挂）| 永久增寿 |
| `lifespan/elixir_aid` | M5 服食寿元丹 | 一次性增寿 |

### 7.5 注册纪律

所有 GDD-04 buff 在 CultivationSystem 启动时注册到 BuffService（详见 GDD-01 §6.10）：

```gdscript
# CultivationSystem._ready
BuffRegistry.register_buff_definition("cultivation/qi_acceleration", load("res://data/buffs/cultivation/qi_acceleration.tres"))
# ... 其它 buff 同
```

### 7.6 数据驱动落地

```
data/table/成长/
├─ 修炼曲线.xlsx         ← Sheet "BaseSpeedByRealm" / "ExperienceThreshold" / "BottleneckDiminishing"
├─ 突破规则.xlsx         ← Sheet "BreakthroughBaseScore" / "BreakthroughDifficulty" / "BreakthroughCost"
├─ 灵根成长.xlsx         ← Sheet "BaseRootChannel" / "BloodlineDef"
└─ proto/cultivation_system.schema.toml

data/buffs/cultivation/      ← buff 定义文件（每个一个 .tres，§7.1-7.4 列举）
```

---

## 8. 寿元加成

### 8.1 字段（GDD-02 契约）

```gdscript
character.lifespan_remaining_months : int   # 剩余寿元（月）
character.lifespan_total_months : int       # 总寿元（含突破加成累计）
```

### 8.2 突破成功的寿元加成（GDD-04 玩法）

```
突破成功 → CharacterService.add_lifespan(c, lifespan_bonus(new_realm))

  lifespan_bonus(realm):
    炼气：+80-100 年（=960-1200 月，随机）
    筑基：+80-100 年
    金丹：+80-100 年
    元婴：+80-100 年
    化神：+80-100 年
    飞升：∞（脱离寿元约束）
```

每境的寿元加成范围 GDD-06 平衡章节定。M3 默认 80-100 年区间随机。

### 8.3 寿元终结（用户定调）

```
月节拍触发：character.lifespan_remaining_months -= 1
  └─ if lifespan_remaining_months == 12: 
        broadcast signal lifespan_critical(c)  ← UI 提示"濒死"
  └─ if lifespan_remaining_months <= 0:
        CharacterService.set_state(c, "dead")
        broadcast signal lifespan_ended(c)
```

寿元不外显（无具体年数 UI），仅濒死时提示——保持修仙叙事的沧桑感。

### 8.4 寿元 buff（增寿手段）

| 来源 | 效果 |
|---|---|
| 突破成功（系统）| 永久 +N 月（§8.2）|
| 寿元丹（M4+）| 一次性 +M 月 |
| 血脉觉醒（M5）| 永久 ×倍率 |
| 心境境界提升（M5）| 永久 +X 月 |

---

## 9. 与角色契约的接触面（GDD-02 接口调用清单）

> 所有 GDD-04 玩法逻辑通过下列 GDD-02 公开接口与角色交互。**禁止直接读写 character 字段**。

| 接口（GDD-02 提供） | GDD-04 调用场景 |
|---|---|
| `add_experience(c, amount)` | 月节拍闭关 / 历练事件 give_experience |
| `add_cultivation_score(c, amount)` | 瓶颈月节拍 |
| `try_advance_sub_realm(c)` | 经验满 → 自动升小境界 |
| `set_state(c, state, mode_data)` | 闭关 / 突破 / 重伤状态切换 |
| `get_effective_root(c, element)` | 公式计算（§2.2 / §4.2）|
| `get_attribute(c, "insight")` | 公式计算 |
| `add_lifespan(c, months)` | 突破成功加寿元 |
| `decay_lifespan(c, 1)` | 月节拍衰减寿元 |
| `apply_buff(c, buff_data)` | 修炼速度 buff / 突破 buff / 心境 buff |
| `remove_buff(c, buff_id)` | buff 到期 / 主动解除 |
| `register_signal_listener(name, cb)` | 监听 GDD-02 signal（如 `state_changed`）|

### 9.1 GDD-04 监听的 GDD-02 signal

| signal | GDD-04 行为 |
|---|---|
| `state_changed(c, old, new)` | 进入 cultivating 时启动月节拍订阅；退出时停止 |
| `experience_added(c, amount)` | 检查是否超阈值 → 触发 advance_sub_realm |
| `lifespan_critical(c)` | 触发"濒死"成长事件机会（M5 拼命突破激励）|
| `breakthrough_failed(c)` | 触发心魔检定（M5）|

### 9.2 GDD-04 提供的 signal（让其它系统监听）

| signal | 谁监听 | 用途 |
|---|---|---|
| `breakthrough_succeeded(c, new_realm)` | GDD-05 宗门 / GDD-10 主线 | 触发宗门长老阁等级变更 / 主线节点开启 |
| `breakthrough_failed(c, old_realm)` | GDD-05 宗门 | 触发"弟子重伤"事件 |
| `enlightenment_triggered(c, type)` | M5 GDD-10 | 主线"机缘"系统钩子 |
| `lifespan_ended(c)` | GDD-02 / GDD-05 / SaveService | 角色死亡善后 |

### 9.3 子系统注册扩展（M2 启动期）

```gdscript
# CultivationSystem._ready (M2 实装)
CharacterRegistry.register_state_mode("cultivating", "normal")
CharacterRegistry.register_state_mode("cultivating", "bottleneck")
CharacterRegistry.register_state_mode("cultivating", "deep_retreat")  # M5
CharacterRegistry.register_attribute("mental_state", default = "calm")  # M5

BuffRegistry.register_buff_definition_dir("res://data/buffs/cultivation/")
BuffRegistry.register_buff_definition_dir("res://data/buffs/breakthrough/")
BuffRegistry.register_buff_definition_dir("res://data/buffs/lifespan/")
```

---

## 10. 风险与扩展点

### 10.1 风险

| 风险 | 提前安排 |
|---|---|
| 闭关公式系数过强 → 玩家无脑闭关 | §3.3 边际递减曲线（连续 12 月后衰减）+ GDD-06 平衡 |
| 突破概率公式参数过多 → 数值难调 | M3 默认所有系数全在配表 + 单元测试覆盖 5 个角色 × 3 个境界突破样本 |
| 走火入魔机制 M5 实装时挡住 M3 | M3 schema 已留 buff 占位，M5 加事件即可，不动 GDD-04 公式 |
| 灵根永久强化太频繁 → 数值膨胀 | 每境最多 1 次"灵根丹"消耗（§5.2）+ 主线血脉觉醒慢节奏（M5）|
| 寿元数值不外显 → 玩家挫败 | §8.3 濒死信号让玩家有"还剩 1 年"的心理预期 |
| 多个 modifier 叠加未饱和 | BuffService 内部按 buff_id 类型饱和（同类 buff 取最大 / 求和 / 替换 见 GDD-01 §6.10）|
| 派遣弟子的拟合公式与亲跑闭关漂移 | GDD-03 §5 派遣兼容性纪律——拟合用同一套 §3.2 / §4.2 公式 |

### 10.2 预留扩展点

| 扩展（M4 / M5）| 实现位 |
|---|---|
| 走火入魔机制 | §4.6 / §6.3 schema 占位 → M5 加事件 |
| 心境与顿悟玩法 | §6 整段 → M5 写完 |
| 长老阁指点突破 | §7.2 buff 占位 → M5 GDD-05 加 |
| 道侣双修 | §7.2 buff 占位 → M5 单独 GDD（关系系统）|
| 寿元丹 | §8.4 → M4 GDD-06 加资源 |
| 血脉觉醒 | §5.2 / §7.4 占位 → M5 GDD-10 主线 |
| 异常修炼路径（魔修 / 体修）| §3.4 register_state_mode 扩展 → M5+ |

### 10.3 设计哲学留痕

> v3.1 决议留痕（2026-06-03）：
> - GDD-04 是 GDD-01 §6.12 哲学的具体落地——所有"怎么成长"的玩法在此章
> - GDD-02 仅持有契约（字段 / 状态 / 接口），不写公式
> - 子系统通过 CharacterRegistry 注册新状态 / 新字段，不修改 GDD-02 源码

---

## 11. M3 实装清单

| # | 内容 | 状态 |
|---|---|---|
| 1 | §2 经验/修为分公式 | ✅ M3 实装（base curve from GDD-06）|
| 2 | §3 闭关机制（含边际递减）| ✅ M3 |
| 3 | §4 突破检定公式（不含 M5 增益）| ✅ M3 |
| 4 | §4.6 失败惩罚（不含走火入魔）| ✅ M3 |
| 5 | §5.2 永久强化（仅奇遇事件触发）| ✅ M3 |
| 6 | §5.3 临时增益 buff | ✅ M3（部分）|
| 7 | §6 心境 / 顿悟 schema 占位 | ⏳ M3 schema only |
| 8 | §7 Buff 库（M3 启用部分）| ✅ M3 |
| 9 | §8 寿元加成 + 终结 | ✅ M3 |
| 10 | §9 接触面（GDD-02 接口）| ✅ M3 |
| 11 | CharacterRegistry 扩展接口 | ⏳ ADR-0003 amendment 待写 |

---

## verdict

drafting · 等用户审。

主要待解决：
- 各公式具体系数（base_speed / experience_threshold / lifespan_bonus 等）→ GDD-06 平衡章节
- ADR-0003 amendment 落地 CharacterRegistry 接口
- §6 心境 / 顿悟 M5 详细设计
