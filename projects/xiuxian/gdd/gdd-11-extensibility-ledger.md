---
gdd_id: 11
gdd_title: 系统扩展性总账 + 依赖矩阵
status: drafting
last_review: 2026-06-09
sections_complete: [设计精神, 依赖矩阵, 扩展点汇总, 加新系统五步流程, 接口契约清单, M3扩展占位检查表]
sections_pending: []
upstream_adr: [0001, 0002, 0003, 0004, 0005, 0006]
upstream_gdd: [gdd-01, gdd-02, gdd-03, gdd-04, gdd-05, gdd-06]
verdict: drafting
---

# GDD-11 · 系统扩展性总账 + 依赖矩阵

> 本章是**M2 写代码的地图**——把项目所有"未来可扩展点"汇总，画依赖矩阵，定加新系统流程。承接 GDD-01 §6.9 系统解耦原则。
>
> 用户最强约束（GDD-01 §7.1）："M1 阶段尽量将 GDD 的所有章节和框架约定出来，提前安排好可扩展性，至少要提前知道可能出现的问题点。"

---

## 1. 设计精神

### 1.1 本章的作用

```
设计期：列全"未来可能加的系统"     ──→ 提前规划架构边界
M2 期：写代码时按依赖矩阵分模块    ──→ 避免随意耦合
M3 期：实装时检查扩展位是否预留    ──→ 不挖坑给 M4
M4-M5：加新系统走 5 步预案         ──→ 不破坏 M1 框架
```

### 1.2 三条总纪律

1. **任何新增系统先来本章登记** —— 加扩展点表 + 更依赖矩阵 + 写 ADR
2. **依赖矩阵是 ground truth** —— 写代码前先看矩阵确认调用边界
3. **扩展位不挖坑** —— M3 实装时只用接口稳定的部分，M4+ 内容靠 schema 占位 + service stub 预留

---

## 2. 系统依赖矩阵（M3 ground truth）

> 行 = 调用方系统；列 = 被调用方系统。单元格 = 调用方式 / 内容。**写代码前查此表**。

|  | TimeService | EventBus | CharacterService | SectService | BuffService | InventoryService | BattleService | SaveService | EventEngine | CultivationSystem | BuildingService | ProductionService |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| **历练系统**（GDD-03）| 订阅 month/progress | broadcast expedition_ended | 读 Character 接口 | 读 Sect 接口 | 读/写 buff（事件 outcome）| 写资源（通过 SectService）| 调 resolve | 通过它存档 | **是接口本身** | — | — | — |
| **宗门经营**（GDD-05）| 订阅 month_advanced | broadcast building/disciple signals | 调 set_state / get_attribute | **是 Sect 数据归口** | apply 建筑 modifier | 读/写资源 | — | 通过它存档 | M4 触发 sect_event | — | **是接口本身** | **是接口本身** |
| **战斗系统**（GDD-03 §6+）| — | broadcast battle_resolved | 读 Character.power 接口 | — | 读 Character.buffs / 写战斗状态 | 写战利品（通过 SectService）| **是接口本身** | 通过它存档 | 通过 start_battle action 接入 | — | — | — |
| **Buff 系统**（ADR-0005）| 订阅 month_advanced（tick）| broadcast buff_applied/removed | 读 Character.buffs | 读 Sect.buffs | **是接口本身** | — | — | 通过它存档 | — | — | — | — |
| **成长系统**（GDD-04）| 订阅 month_advanced（闭关 tick）| broadcast breakthrough_succeeded/failed | 调 add_experience / set_state / get_effective_root | — | 读修炼 modifier / 写突破 buff | 突破扣资源 | — | 通过它存档 | — | **是接口本身** | — | — |
| **InventoryService** | — | broadcast resource_below_threshold | — | 通过 SectService 读写 sect.resources | — | **是领域规则**（不持有数据） | — | 通过 SectService 存档 | — | — | — | — |
| **InjuryService** | — | broadcast actor_defeated | 写 ActionState DEAD / hp | — | 订阅 buff signal + 查累计 | — | — | 不持有数据 | — | — | — | — |
| **EventEngine**（GDD-03 §2）| — | broadcast event_resolved | 读 actor 字段 | — | apply / remove buff（actions）| 写资源（give_loot/give_resource）| 调 resolve（start_battle action）| 通过它存档 EventContext | **是接口本身** | — | — | — |
| **CultivationSystem**（GDD-04）| 订阅 month_advanced | broadcast breakthrough_xxx / enlightenment | 调 add_experience / set_state | — | 通过 BuffService 聚合 modifier | 突破扣资源 | — | 通过它存档 | 无 | **是接口本身** | — | — |
| **BuildingService**（GDD-05）| 订阅 month_advanced（建造进度）| broadcast building_level_up | 调 set_state（弟子分配）| 读写 sect.buildings | apply 建筑 modifier 到弟子 | 扣建造资源 | — | 通过它存档 | — | — | **是接口本身** | 调 start_task |
| **ProductionService**（GDD-05）| 订阅 month_advanced（任务推进）| broadcast alchemy/forge_task_completed | — | 写产物到 sect.resources | — | 扣材料 / 加产物 | — | 通过它存档 | — | — | — | **是接口本身** |
| **DispatchService**（GDD-03 §5 · M4）| 订阅 month_advanced | broadcast dispatch_completed | M4 拟合应用 hp/exp | — | apply 派遣 buff | 落袋拟合产物 | **不调 resolve**（拟合）| 通过它存档 task | — | — | — | — |

### 2.1 关键观察

- **SectService / BattleService / BuffService / CultivationSystem / EventEngine / BuildingService / ProductionService / DispatchService = 8 个领域服务**——M2 必落地的核心模块
- **InventoryService / InjuryService = 领域规则**，不持有数据，写时通过 SectService / CharacterService
- **TimeService + EventBus = 系统纽带**——所有跨系统通信经它们
- 无任何"X 直接读 Y 的内部字段"——满足 GDD-01 §6.9.1 解耦纪律

### 2.2 矩阵维护规则

- 加新系统 → 在矩阵加新行 + 列
- 改既有调用 → 更对应单元格
- 删系统 → 删行列 + 检查其他系统是否还引用
- 走 PR `[cross-system]` tag 自动触发本表 review（GDD-01 §6.9.3）

---

## 3. 扩展点汇总（按系统分组）

> 每条扩展点 = "M3 留接口/schema，M4-M5 加内容"。带 🔌 = M3 已留代码层接口；带 📋 = M3 仅 schema 占位。

### 3.1 历练与战斗（GDD-03）

| 扩展点 | 何时启用 | M3 准备 |
|---|---|---|
| 🔌 派遣弟子拟合算法 | M4 | DispatchTask/Strategy/Result/Service 类文件就位，stub |
| 📋 EventTemplate.category 新增类（如 sect_event）| M4 | schema enum 加值走 ADR |
| 📋 action_type 新增（wait_months / trigger_quest）| M5 | schema 占位，handler 未实装 |
| 📋 战斗 BattleResult.version=2 | M5 | BattleResult schema 含 version 字段 |
| 🔌 BattleResolver 新实现（TacticalSimulator）| M5 | 接口抽象就位 |
| 📋 5 战斗接入点逐个实装 | 接入点 1 M3 / 2-3 M4 / 4-5 M5 | trigger_source 标签就位 |
| 📋 撤离节点危险/安全比例配表 | M4 | preferred_template_pool 单池支持 |
| 📋 同图重复历练递减 | M4 | GDD-06 §4 已登记曲线 |

### 3.2 成长系统（GDD-04）

| 扩展点 | 何时启用 | M3 准备 |
|---|---|---|
| 📋 走火入魔（突破失败极端分支）| M5 | §4.6 schema 占位 buff `injury/qi_deviation` |
| 📋 心境 / 顿悟 | M5 | §6 整段 schema 占位 |
| 📋 长老阁突破指点 | M5 | §7.2 buff 占位 |
| 📋 道侣双修 | M5 | §7.2 buff 占位 |
| 📋 寿元丹 | M4 | §8.4 schema 占位 |
| 📋 血脉觉醒 | M5 | §5.2 schema 占位 |
| 📋 异常修炼路径（魔修 / 体修）| M5+ | CharacterRegistry register_state_mode 扩展 |

### 3.3 宗门经营（GDD-05）

| 扩展点 | 何时启用 | M3 准备 |
|---|---|---|
| 📋 聚灵阵 `qi_array`（SECT 级 buff fan-out）| M4 | 扩展空槽 + §3.4 fan-out 范式预留 |
| 📋 演武场 `training_field` | M4 | 扩展空槽 |
| 📋 炼器房 `forge_room` + 装备系统 | M4-M5 | 扩展空槽 + §6 schema 占位 + ProductionService 按 task_kind 分发 |
| 📋 厨房 `kitchen` | M4 | 扩展空槽 |
| 📋 多套 SectLayoutTemplate（门派传承）| M5 | schema 已支持，加 default_sect_v2 |
| 📋 炼丹方案 B/C（火候 / 工序小游戏）| M4-M5 | AlchemyRecipeDef.firing_curve / process_steps 已占位 |
| 📋 同配方品质分级 | M5 | quality_tiers 占位 |
| 📋 建筑维护费 | M4 | GDD-06 §5.3 占位 |
| 📋 SectEventRouter 完整事件库 | M4 | M3 stub + 表 1 行示例 |
| 📋 招收"历练带回"挂钩深度内容 | M4 | recruit action 已支持，模板 expedition_rescue 已就位 |
| 📋 关系网 / 弟子忠诚度 / 叛宗链 | M5 | GDD-02 §6 schema 已占位 |
| 📋 长老阁 / 工艺师 / 建筑特技 | M5 | BuildingTemplate.master_disciple_id 待加 |
| 📋 比武台 / 弟子互训 | M5 | 扩展空槽 |
| 📋 藏书阁功法学习 | M5 | library 占位 `learnable_method_ids` |
| 📋 多人小队历练 | M4 | EventContext.actor 字段就位（M5 改 actors 数组）|

### 3.4 经济与数值（GDD-06）

| 扩展点 | 何时启用 | M3 准备 |
|---|---|---|
| 📋 卖物 / 坊市经济 | M4 | §3.2 产出源占位 |
| 📋 建筑维护费机制 | M4 | §5.3 占位 |
| 📋 派遣弟子拟合产出 | M4 | §3.2 占位 |
| 📋 欠俸→忠诚度→叛宗链 | M5 | §5.2 占位 |
| 📋 技能修正注入战斗力 | M5 | §7.1 公式槽 `(1+Σbuff_mod)` 预留 |
| 📋 矿石 → 炼器经济链 | M4 | §2.1 ore 已囤积 |

### 3.5 角色契约（GDD-02 · v3.1 注册扩展）

| 扩展点 | 何时启用 | M3 准备 |
|---|---|---|
| 🔌 CharacterRegistry.register_state | M2 实装 | ADR-0003 amendment 已写 |
| 🔌 CharacterRegistry.register_attribute | M2 实装 | 同上 |
| 🔌 CharacterRegistry.register_signal_listener | M2 实装 | 同上 |
| 📋 mental_state 字段 | M5 心境 | 注册扩展可即时加 |
| 📋 装备 / 法宝 / 主修功法字段 | M5 | 占位字段就位 |

### 3.6 主线与世界观（GDD-10）

| 扩展点 | 何时启用 | M3 准备 |
|---|---|---|
| 📋 主线钩子目录激活 | M5 | M2 期 WorldEventTrigger 接口就位 |
| 📋 派系系统玩法（外交 / 仇隙）| M5 | Sect.relations Dict 已占位 |
| 📋 大世界事件 | M5 | EventEngine 已支持 |
| 📋 开场漫画 / CG | M5 | UI 接口预留 |
| 📋 结局分支 | M5 | 主线 flag 系统已支持（GDD-03 §2.6 expedition/permanent 层）|

### 3.7 美术与音频（GDD-07/08）

| 扩展点 | 何时启用 | M3 准备 |
|---|---|---|
| 📋 战斗演出资产（动画/特效）| M5 | GDD-07 §X 占位 |
| 📋 BGM 动态混音 | M5 | GDD-08 总线就位 |
| 📋 配音 / 旁白 | M5 | 接口预留 |
| 📋 i18n 多语言 | M6 | TEXT 表已 TID 化（data/table/TEXT）|

### 3.8 交付（GDD-09）

| 扩展点 | 何时启用 | M3 准备 |
|---|---|---|
| 📋 Steam EA / 正式上线流程 | M7 | 接口预留 |
| 📋 多存档槽 | M4 | M3 单槽，SaveService 接口已支持 slot_id |
| 📋 平衡测试自动化 | M6 | 数值已配表化 |
| 📋 反馈 / 补丁 / DLC 机制 | M7 | — |

---

## 4. 加新系统五步流程（GDD-01 §6.9.4 落地）

任何 M1 之后加的新系统**必走**以下流程：

```
Step 1 · 写 ADR
  ├─ 决策动机 / 设计取舍 / 影响的现有系统（参照本章 §2 矩阵）
  ├─ 兼容性策略：是否破坏既有接口 / 存档迁移方案
  └─ 提交评审：标签 [new-system]，至少 1 名 reviewer 同意

Step 2 · 更新 GDD-11（本章）
  ├─ §2 依赖矩阵加行 + 列
  ├─ §3 对应分组加扩展点条目
  └─ 标注 "M? 启用 / M3 准备 ?"

Step 3 · 存档兼容（ADR-0004 5 点验证）
  ├─ 新字段独立分区？
  ├─ default 是否兼容老存档？
  ├─ 未知字段保留？
  ├─ 模板 vs 实例分离？
  └─ 版本号是否需要提升？

Step 4 · 接口检查
  ├─ 不破坏既有 4 接口（GDD-01 §6.2）契约
  ├─ 通信只走 EventBus / Service / 数据共享
  └─ 不引入跨系统全局静态可变状态

Step 5 · 写测试
  ├─ 至少 1 个单元测试覆盖新系统的核心接口
  └─ 1 个集成测试覆盖与既有系统的交互
```

> **执行机制**（M2 后期）：`.codebuddy/hooks/pre-commit-discipline.py` 检测 commit 中包含新 service 文件 → 强制提示走 5 步流程，未满足拒绝合并。

---

## 5. 接口契约清单（GDD-01 §6.2 落地）

> M1 列定，M2 实装。任何修改走 ADR。

| 接口 | 文件 | 关键签名 | 上游 |
|---|---|---|---|
| **BattleResolver** | `scripts/battle/battle_resolver.gd` | `resolve(ctx: BattleContext) -> BattleResult` | ADR-0002 |
| **EventResolver / EventEngine** | `scripts/expedition/event_engine.gd` | `resolve_event(event_id, ctx) -> void` / `process_node(N, ctx)` | GDD-03 §2.4 |
| **SaveService** | `scripts/data/save_service.gd` | `serialize() -> Dict` / `deserialize(d: Dict) -> void` + 版本兼容 | ADR-0004 |
| **WorldEventTrigger** | `scripts/main_line/world_event_trigger.gd` | `trigger(hook_id, payload) -> void` | GDD-10 |

> 这 4 接口 M2 必落地，是后续所有功能的根。

---

## 6. M3 扩展位检查表

> M3 提交前必跑：检查所有 M4-M5 用到的扩展位是否预留就位。

| 检查项 | 验证方式 | M3 状态 |
|---|---|---|
| EventTemplate.category 9 类白名单 | schema enum 校验 | ✅ GDD-03 §2.2.1 |
| EventAction param 变长槽 | schema dynamic type_resolver | ✅ GDD-03 §2.9.2 |
| Character schema 含 skills/equipped/status_effects | 类字段定义 | ✅ ADR-0003 |
| BattleResult.version 字段 | schema | ✅ ADR-0002 |
| BattleContext.env Dict | schema | ✅ GDD-03 §7.4 |
| SaveService 分区独立加载 | 单元测试 | ⏳ M2 |
| WorldEventTrigger 接口注册 | autoload + 钩子表 | ⏳ M2 |
| SectLayoutTemplate 多套支持 | schema layout_id 字段 | ✅ GDD-05 §2 |
| BuildingSlotDef.allowed_building_ids | schema 数组字段 | ✅ GDD-05 §2 |
| AlchemyRecipeDef.firing_curve / process_steps | schema 占位 | ✅ GDD-05 §5.4 |
| ProductionService 按 task_kind 分发 | 接口设计 | ✅ GDD-05 §6.2 |
| CharacterRegistry 注册接口 | autoload | ⏳ M2（ADR-0003 amendment）|
| TimeService.advance_progress / advance_outer | API | ⏳ M2（ADR-0001 amendment）|
| BuffService 双表注册 + IBuffable | autoload | ⏳ M2 |
| EventBus 全局 | autoload | ⏳ M2 |
| DispatchTask/Strategy/Result/Service 类就位 | 类文件 | ⏳ M3 stub |
| SectEventRouter 类就位 | autoload stub | ⏳ M3 stub |
| TEXT/i18n 框架 TID 化 | TEXT 表 | ✅ data/table/TEXT |

---

## 7. 风险与扩展点（自指）

| 风险 | 缓解 |
|---|---|
| 依赖矩阵脱离实际代码 | §2.2 维护规则 + commit 触发 review |
| 加新系统不走 5 步流程 | §4 hook 强制 + reviewer agent 检查 |
| 扩展位太多无人维护 | §6 检查表 M3 提交前强制跑 |
| M5 主线启动时发现 M3 接口不够 | M1 GDD-10 钩子目录列全 + M2 WorldEventTrigger 必落地 |

### 自身的扩展点

| 扩展 | 何时启用 |
|---|---|
| 系统依赖矩阵可视化工具 | M4-M5（项目变大时） |
| 自动检测扩展位是否实装 | M2 期 hook 实装 |

---

## verdict

drafting · M2 写代码前用户审。本章是 M2 设计阶段的核心参考。

> M3 不需要的扩展细节（M4-M5 才详细展开）→ 见 `docs/m1-deferred-details.md`
