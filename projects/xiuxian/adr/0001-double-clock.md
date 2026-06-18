---
adr_id: 0001-double-clock
status: accepted
date: 2026-05-23
accepted_at: 2026-05-26
deciders: [用户, codebuddy]
supersedes:
related_gdd: gdd-01 §2.3 双层时钟 / §6.4 时间总线
---

# ADR 0001 · 双层时钟（月历 + 历练百分比）

## 上下文

xiuxian 的核心循环是"宗门内务（主世界）⇄ 外出历练（小世界）"，两者节奏不同：

- **宗门内务**是回合制（一月一回合），玩家做月度决策（修炼 / 建设 / 培养），月末结算
- **外出历练**是连续推进（事件 / 选项 / 移动逐步消耗时间），玩家在限定时间内决定何时撤退

这两种节奏不能用单一时钟表达：
- 用纯回合制 → 历练失去"时间紧迫"的张力
- 用纯连续制 → 月度结算没法干净地触发

游戏内还有大量系统订阅时间事件：
- 修炼边际递减（连续闭关月数 → 收益衰减）
- 弟子寿元（每月 -1）
- 大世界 / 主线触发（特定月份触发事件）
- 历练事件 / 选项消耗（百分比单位）

如果每个系统自己读时间状态，会产生**关联 bug**（A 系统改了月份但 B 系统没刷新）。
按 §6.9 解耦原则，需要单一时间总线。

## 决策

采用 **双层时钟 + 单一 TimeService autoload + signal 总线** 架构。

```
TimeService (singleton autoload)
├─ 状态
│   ├─ current_month: int            # 外层时钟，从 1 开始，连续推进（历练中也推进）
│   ├─ expedition_active: bool
│   ├─ expedition_progress: float    # 内层时钟，0.0 - 1.0
│   └─ expedition_max_months: int    # 历练图最大月数（1/2/3...）
│
├─ signal month_advanced(month: int)              # 任何月份变化都广播（历练中也会触发）
├─ signal expedition_started(map_id, max_months: int)
├─ signal expedition_progress_changed(progress: float, delta: float)
├─ signal expedition_ended(reason: ExpeditionEndReason, months_consumed: int)
└─ signal world_event_triggered(event_id: String, payload: Dict)
```

**核心规则（用户定调 2026-05-23 v2）**：

1. **大世界月份是唯一节拍**——历练中途也按百分比映射到月份，并广播 `month_advanced`：
   - 1 月图：100% 完成 → +1 月（历练结束时一次推进）
   - 2 月图：50% 时广播进入第 2 个月 → 100% 时再 +1 月
   - 3 月图：33% / 67% 各广播一次 → 100% 时再 +1 月
   - 通用公式：每跨过 `1/N` 进度阈值（N 为图月数）即广播下一月开始

2. **历练中途撤退月份计算**：消耗月数 = `ceil(progress * max_months)`（向上取整，不让玩家用"49% 撤退算 0 月"占便宜，但 50% 撤退算 1 月）
   - 备选公式：`floor(progress * max_months) + 1`（首月即 +1）—— **待用户确认**
   - 详见"理由"节

3. **历练期间宗门系统也在推进**——这是用户明确要求：
   - 弟子寿元每月 -1（即使门主在外）
   - 宗门建设 / 加工产出按月结算
   - 大世界事件按月触发（M5 才有内容，M3 接口在线）
   - 玩家在历练中可能收到"宗门来信"类消息（M4+ 实现，M3 接口预留）

4. 所有系统**只通过 signal 订阅**时间，不直接读 `current_month` 做月度逻辑。

5. 历练内事件 / 选项消耗百分比通过 `TimeService.consume_expedition(percent)` 调用：
   - 内部根据百分比检查是否跨过下一月阈值，跨过则触发 `month_advanced`
   - 道具加速由调用方传入折扣，TimeService 不感知道具

6. **存档约束**（用户定调）：
   - **只能在大世界阶段（非历练中）存读档**
   - **亲自历练出发前自动存档**（玩家可在历练失利后回到出发点重试）
   - 派遣弟子历练**不**触发自动存档（因为派遣本身是黑盒消息流，玩家仍在大世界）
   - 详细落 ADR-0004 存档架构

## 候选方案

| # | 方案 | 优点 | 缺点 | 结论 |
|---|---|---|---|---|
| A | 双层时钟 + 历练期间宗门冻结 | 实现最简 / 边界清晰 | "我离开 3 个月宗门什么都没变"违和感 / 撤退时不知用了几个月 | ❌ 放弃（用户否决）|
| **B** | **双层时钟 + 历练中途按百分比广播 month_advanced，宗门同步推进**（本 ADR）| 大世界月份连续 / 撤退时精确知道几个月过去 / 弟子寿元等月度结算正常 | 实现复杂度中等 / 多月图阈值边界要测 | ✅ 选择 |
| C | 单层时钟（全部用"日"为单位）| 实现简单 | 历练事件细化到日不自然 / 月度结算和历练混杂 | ❌ 放弃 |
| D | 完全独立两套（不共享 TimeService）| 解耦彻底 | 月份和历练状态可能漂移 / 存档复杂 | ❌ 放弃 |

## 理由

- **B 选择理由**：用户原话"大世界的所有内容都按照月为单位进行推进"——历练只是玩家的注意力切换到小世界，但宗门 / 弟子 / 邻宗 / 寿元等大世界状态**不应该停摆**。这也回答了"撤退时用了几个月"的关键问题。
- **A 放弃理由**：用户最早接受过"历练期间月份不前进"的方案，但二次审视后否决——理由是离开 3 个月回来发现宗门毫无变化的违和感太大。
- **C 放弃理由**：把"事件消耗"细化到"日"会让事件 schema 冗余；玩家也不需要"今天是 4 月 23 日"这种粒度。
- **D 放弃理由**：两套时钟相互监听 + 同步 = 引入 bug 温床。

### 关键设计点：撤退月数计算公式（待用户最终确认）

| 公式 | 25% 撤退 | 50% 撤退 | 99% 撤退 | 适合心智 |
|---|---|---|---|---|
| `ceil(progress * max_months)` | 1 月 | 1 月（2 月图）| 2 月（2 月图）| "进了就花了 1 月"，惩罚性 |
| `floor(progress * max_months)` | 0 月 | 1 月（2 月图）| 1 月（2 月图）| 鼓励早期撤退，免费侦察 |
| `round(progress * max_months)` | 0 月 | 1 月 | 2 月 | 中庸 |

**AI 推荐 `ceil`**：
- 哪怕只用了 1% 也算 1 月，避免"试探性进入秒撤退"的免费侦察 bug
- 配合"进入历练即自动存档"，玩家可读档绕过损失
- 强制玩家"决定要不要去就要付出 1 月成本"的张力

待用户决定。

## 影响

### 正面

- 大世界月份连续推进，"离开 N 月回来"无违和感
- 撤退时月数清晰（按 ceil 公式精确）
- 系统间通过 signal 解耦，加新系统订阅时间不需要改 TimeService 代码
- 双层节奏保留游戏感（历练紧迫感 + 宗门月度决策）
- 存档约束（仅大世界 + 出发前自动）大幅简化恢复逻辑
- 历练中途收到"宗门来信"类消息有了时间锚点（M4+ 实现）

### 负面

- 多月图百分比阈值跨越判定要谨慎写测试（边界条件多）
- "历练中宗门也产出"意味着加工 / 建设系统 M2 就要正确响应历练中的月节拍
- 道具加速逻辑分散在调用方（不是 TimeService 一处），需要规范调用习惯

### 风险

| 风险 | 概率 | 缓解 |
|---|---|---|
| 历练中触发月节拍时，月度结算系统访问历练相关状态导致冲突 | 中 | 月度结算系统**禁止**读历练状态；如必须，通过 TimeService 提供的 read-only API |
| 一次 consume_expedition 跨多个月份（例如 3 月图一次消耗 70% 跨 2 月）| 中 | 内部循环逐月触发 month_advanced（不是一次性跳）|
| signal 顺序依赖（A 监听月份后 B 也监听，A 处理引发 B 状态错乱）| 中 | 不设计跨 signal 的隐式依赖；如必须用明确的 priority 机制 |
| 历练中途暂停 → 状态丢失 | 中 | "只能大世界存档"约束已规避；历练中只支持暂停 UI（程序内存态） |
| 派遣弟子历练 vs 门主亲征的时钟差异 | 中 | 派遣是月度结算的子系统（每月推进一格），不走 expedition_progress；ADR-0002/0003 明确边界 |
| 撤退时月数计算公式误差（off-by-one）| 中 | 单元测试覆盖 0%/33%/50%/67%/99% 五个边界点 |

## 实现要点（M2 任务）

- `TimeService.gd` autoload 单文件，~150 行
- 6 个 signal（如上）
- `consume_expedition(percent)` 内部跨月循环逻辑
- 撤退月数公式：`ceil(progress * max_months)`（待用户最终确认）
- 单元测试覆盖：
  - 月度推进 → month_advanced 触发
  - 历练开始 / 推进 / 超时 / 主动撤退 4 路径
  - 多月图（2 月 / 3 月）阈值跨越广播
  - 单次 consume_expedition 跨多个月份正确逐月广播
  - 撤退月数计算 5 边界点（0% / 33% / 50% / 67% / 99%）
  - 历练中宗门月度结算系统正常响应 month_advanced
  - 存档恢复时状态正确（仅大世界状态，依赖 ADR-0004）

---

## Amendment v1.1（2026-06-09 · 接口扩充）

> 触发：GDD-03 §3.4 / §4.5 / GDD-04 §9 都引用 `TimeService.advance_progress` / `advance_outer` 接口，但 v1.0 ADR 未明示。本 amendment 把接口正式列入契约。

### 公开接口清单（M2 必落地）

```gdscript
# scripts/services/time_service.gd（autoload）
class_name TimeService extends Node

# === 大世界（月节拍）===
func get_current_month() -> int                   # 全局月份累加器
func get_current_year() -> int                    # 月 / 12 派生
func advance_outer(months: int) -> void           # 推进 N 月（含逐月广播）
                                                  # 触发：撤离回宗 / debug 跳月

# === 历练内层（百分比时钟）===
func enter_expedition(initial_percent: int = 100) -> void
func exit_expedition() -> void
func get_expedition_remaining_percent() -> int
func advance_progress(percent: int) -> void       # 推进 N% 进度
                                                  # 触发：节点进入 / 选项 cost_time / 事件 action 消耗
                                                  # 内部检查：跨月阈值则广播 month_advanced
                                                  # 内部检查：percent ≤ 0 → 标记 timeout_pending（GDD-03 §4.3）

# === Signal ===
signal month_advanced(new_month: int, year: int, month_of_year: int)
signal progress_advanced(new_remaining_percent: int, just_consumed: int)
signal year_advanced(new_year: int)
signal expedition_time_warning(threshold: String)  # "warning"(30%) / "critical"(10%)
                                                  # GDD-03 §4.3.3
```

### 调用方约定（v3.1 v1.1）

| 调用方 | API | 场景 |
|---|---|---|
| GDD-03 §3.4 OptionDef | `advance_progress(option.cost_time_percent)` | 选项消耗历练时间 |
| GDD-03 §4.5 ExtractionService | `advance_outer(return_days_to_months)` | 撤离回宗推进月份（注：M3 实际按天，需另加 `advance_outer_by_days`，或将天数四舍五入到月）|
| GDD-04 §2.2 闭关 | 订阅 `month_advanced` | 月节拍涨经验 |
| GDD-04 §8.3 寿元衰减 | 订阅 `month_advanced` | 每月 -1 寿元 |
| GDD-05 月俸 / 建造 / 炼丹 | 订阅 `month_advanced` | 各种月节拍推进 |
| 历练事件 wait_months action（M5）| `advance_outer(months)` | 事件链中"暂停 N 月再继续"|

### 待解小细节（M2 实装时定）

- 撤离回宗天数 1/3/7 天（GDD-06 §7.5）→ 是否在 TimeService 加 `advance_outer_by_days(days)` API？还是调用方按 30 天 = 1 月四舍五入？
  → **决议**：加 `advance_outer_by_days(days)`，内部累计满 30 天广播一次 month_advanced（避免精度丢失）
- progress_advanced signal 是否含具体哪个 action 消耗的 → 不含（保持 signal 精简，调用方自记日志）

### 影响

- GDD-03 / GDD-04 / GDD-05 引用此 API 的位置无需改文，amendment 是补 ADR 不是改 GDD
- M2 TimeService 实装时按此清单实现 + 单元测试覆盖

## 关联

- GDD：gdd-01 §2.3（双层时钟设计）/ §6.4（时间总线）
- Stories：M2-S001 TimeService 实现（待建）
- 其他 ADR：
  - ADR-0004 存档架构（决定时间状态如何序列化）
  - ADR-0002 战斗接口（战斗也通过 TimeService 计费？或独立？需在 0002 决定）
