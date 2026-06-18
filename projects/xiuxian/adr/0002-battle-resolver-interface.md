---
adr_id: 0002-battle-resolver-interface
status: accepted
date: 2026-06-09
accepted_at: 2026-06-09
deciders: [用户, codebuddy]
supersedes:
related_gdd: gdd-01 §6.2 / §6.8 / gdd-03 §6 战斗框架 / §7 5 接入点
---

# ADR 0002 · 战斗系统接口抽象（M3 数值对拼 / M5 回合制）

## 上下文

战斗会被 5 个不同场景调用（GDD-03 §7）：

1. 历练节点战斗事件（M3）
2. 宗门被攻击（M4）
3. 派遣弟子遭遇（M4，拟合）
4. 主线 boss 战（M5）
5. 仙宗大比 / 比武（M5）

M3 战斗形态简单：双方战力对比（含五行加成）+ RNG 判胜负，无演出。  
M5 升级为回合制 + 技能 / 装备 / 状态效果。

如果 M3 直接写一个 `BattleService.fight()` 函数，M5 升级时所有调用方都要改。需要**接口抽象**——M3 实现 = StatSimulator，M5 实现 = TacticalSimulator，调用方只看接口不看实现。

## 决策

定义 `BattleResolver` 抽象接口 + `BattleContext` 输入 + `BattleResult` 输出。M3 用 `StatSimulator`（GDD-03 §6 战力 + 五行公式），M5 升级时新增实现类替换。

### 核心接口

```gdscript
# scripts/battle/battle_resolver.gd
class_name BattleResolver
extends RefCounted

# 主接口（同步骨架）
func resolve(ctx: BattleContext) -> BattleResult:
    push_error("Override in subclass")
    return null

# M5 演出层包装（默认调 resolve 不演出）
func resolve_async(ctx: BattleContext) -> BattleResult:
    return resolve(ctx)
```

### BattleContext（输入契约）

```gdscript
class_name BattleContext
extends Resource

@export var attackers: Array              # Character 引用数组
@export var defenders: Array              # 同上
@export var env: Dictionary               # 开放扩展字段（GDD-03 §7.4 白名单）
@export var seed: int                     # 强制由调用方传入，可复现
@export var escape_allowed: bool          # 玩家是否能逃跑
@export var trigger_source: String        # "expedition_event" / "sect_invasion" / ...（GDD-03 §7.1）
```

### BattleResult（输出契约）

```gdscript
class_name BattleResult
extends Resource

@export var version: int = 1              # M3=1, M5=2（细颗粒度日志升级）
@export var winner: String                # "ATTACKERS" / "DEFENDERS" / "DRAW" / "ESCAPED"
@export var hp_changes: Dictionary        # actor_id → hp_delta
@export var status_changes: Array         # 战后挂的 buff/debuff
@export var loot: Dictionary              # 战利品（DEFENDERS 失败时给）
@export var log_entries: Array            # 战斗日志（version=1 仅 1 条总结；version=2 逐击）
@export var narrative_seed: int           # 给 UI 文本播报用的种子
```

### M3 实现：StatSimulator

```gdscript
class_name StatSimulator
extends BattleResolver

@export var element_calc: ElementCalculator
@export var power_ratio_dominate: float = 1.2

func resolve(ctx: BattleContext) -> BattleResult:
    var atk_power = _team_power(ctx.attackers, ctx.defenders)
    var def_power = _team_power(ctx.defenders, ctx.attackers)
    var rng = RNG.from_seed(ctx.seed)
    return _decide(atk_power, def_power, ctx, rng)
```

详细公式见 GDD-03 §6.3-6.4。

### 5 接入点的统一调用形式

所有接入点（除派遣拟合）走：

```gdscript
var ctx = BattleContext.new()
ctx.attackers = [...]; ctx.defenders = [...]
ctx.seed = my_rng.randi(); ctx.trigger_source = "expedition_event"
var result = BattleService.resolve(ctx)
# 按 result.winner / hp_changes / loot 处理
```

### 例外：派遣弟子拟合

`DispatchService` **不调** `resolve_async`，用拟合公式直接出胜率（GDD-03 §5.3）。但保持同一战力公式（§6.3）+ 同一系数（GDD-06 §7）→ 拟合结果与亲跑不漂移。

## 影响

### 正面

- M5 升级零侵入：换 BattleService 持有的 resolver 实例即可
- 5 接入点用法一致，trigger_source 标签便于战报归因 / 数据分析
- BattleContext.env 开放扩展（地形 / 天候 / 关卡 buff）+ schema 白名单约束
- 派遣拟合可复用战力公式，不重复定义

### 负面

- 接口包装多一层（Context / Result Resource）相比直接函数有 ~5% 开销，可忽略
- BattleResult.version 跨版本兼容增加复杂度（M5 兼容 M3 存档需读 version=1 简化结果）

### 风险

| 风险 | 缓解 |
|---|---|
| M5 实装时发现 BattleContext 缺字段 | env 字段为开放 Dictionary + schema 白名单——加 key 不破坏接口 |
| 拟合派遣 vs 亲跑结果漂移 | 单元测试：100 局拟合 vs 100 局 StatSimulator 真跑，胜率差 ≤ 5% |
| 技能系统（M5）破坏既有战力平衡 | GDD-06 §7.1 公式槽 `(1+Σbuff_mod)` 预留——技能作 buff 注入 |

## 替代方案（已否决）

### A. 直接写 BattleService.fight()，M5 重写

❌ 调用方需大改，违反 GDD-01 §6.2 接口稳定性纪律。

### B. M3 即实装回合制

❌ M3 范围爆炸，与"M3 战斗用数值对拼"用户定调冲突（GDD-01 §6.8）。

### C. 多个 BattleService（按接入点分）

❌ 战斗逻辑分散，平衡数值散落多处，违反 SoT。

## 实施清单

| # | 内容 | 里程碑 |
|---|---|---|
| 1 | BattleResolver / BattleContext / BattleResult 类定义 | M2 |
| 2 | StatSimulator 实装 + 单元测试 | M2 |
| 3 | ElementCalculator + 五行规则 | M2 |
| 4 | BattleService autoload 持 resolver 实例 | M2 |
| 5 | 5 接入点 trigger_source 标签 schema | M2 |
| 6 | 接入点 1（历练战斗）实装 + smoke 测试 | M3 |
| 7 | 接入点 2/3 实装 | M4 |
| 8 | TacticalSimulator + version=2 升级路径 | M5（详见 docs/m1-deferred-details.md）|

## 关联

- 上游：GDD-01 §6.2 接口抽象 / §6.8 战斗框架
- 下游：GDD-03 §6 战斗框架 / §7 5 接入点 / GDD-06 §7 战斗数值标定
- 派生：M5 BattleResult.version=2 升级详细方案 → 见 docs/m1-deferred-details.md
