# M1 自动审阅报告（AI 预审）

> 编制：2026-06-18 / 用户最终 verdict 前的 AI 预审

## 审阅范围

| 章节 | 行数 | 重点审 |
|---|---|---|
| GDD-01 v3.1 | 870+ | §6.12 哲学落地 / §7.3 章节清单 |
| GDD-02（含迁移指针）| 1635 | §0 重构说明 / 11 迁移指针 |
| GDD-03 历练战斗 | 1840+ | StatSimulator + 五行 + 撤离 |
| **GDD-04 成长系统** ⭐ | 470+ | 闭关 / 突破 / 灵根 / 寿元 |
| **GDD-05 宗门经营** ⭐ | 1010 | 5 建筑极简 + 槽位明细 + UI |
| **GDD-06 经济与数值** ⭐ | 480+ | 资源 / 月俸 / 修炼/战斗系数 / 核心循环 |
| GDD-07 美术 | 320+ | 风格基线 / canonical key |
| GDD-08 音频 | 220+ | 5 总线 / AudioService 接口 |
| GDD-09 交付与验收 | 240+ | M1/M2/M3 详细 / 测试矩阵 |
| GDD-10 主线与世界观 | 310+ | 钩子目录 ~20 / WorldEventTrigger |
| GDD-11 扩展性总账 | 280+ | 依赖矩阵 / 扩展点 8 分组 |
| ADR-0001 v1.1 | + amend | TimeService 接口扩充 |
| ADR-0002 战斗 | 全新 | StatSimulator 契约 |
| ADR-0003 v3.3 | + amend | CharacterRegistry 扩展 |
| ADR-0004 存档 | 全新 | 5 点决策 + migration |

## 一致性扫描发现 + 已修

| # | 不一致 | SoT | 修复 |
|---|---|---|---|
| 1 | 修炼塔 lv3 数值：GDD-04 写 +30%，GDD-05 §3.2.3 + GDD-06 校验都是 +50% | GDD-05 | ✅ 已修 GDD-04 §3.2 → 标 SoT |
| 2 | CultivationService（GDD-02 旧文）vs CultivationSystem（其他全章 + ADR）| ADR-0003 | ⏳ GDD-02 删除时自然消失（含在清理预案）|
| 3 | register_state vs register_state_mode：GDD-01 §6.12 + GDD-02 §0.4 用旧名，ADR-0003 v3.3 用新名 | ADR-0003 | ✅ 已修 GDD-01 + GDD-02 |

> 数值交叉一致 ✅（base_power / base_speed / base_threshold 全章统一）  
> 接口命名交叉一致 ✅（修复后）  
> WorldEventTrigger / save_version / qi_acceleration 等关键标识符统一 ✅

## 审阅建议优先级

### 🔴 重点审（M2 实施前必须 PASS）

#### 1. GDD-04 成长系统（哲学验证）

| 审阅点 | 问题 |
|---|---|
| §1.2 跨系统关系图 | GDD-04 是否真做到"通过 buff 接口被注入 modifier"？是否还有耦合代码？ |
| §2.2 修炼公式 | `monthly_gain = base_speed × (1+Σa·root) × cultivation_multiplier × diminishing` 是否符合你预期？ |
| §3.2 闭关 modifier 6 来源 | 是否完整？是否有遗漏的 M5 来源（如心境）？ |
| §4.2 突破多维概率 | base + cultivation + root + insight + difficulty 五项是否覆盖你想要的"赌早 vs 稳打磨"张力？ |
| §6 心境占位 | M5 占位接口是否预留充分？ |
| §8 寿元加成 | 突破 +80-100 年是否符合"修仙长寿感"预期？ |

#### 2. GDD-05 宗门经营（玩法节奏）

| 审阅点 | 问题 |
|---|---|
| §2.4 8 槽位明细 | 5 实建 + 3 扩展空槽是否符合"M3 极简 + 看得见建不了的成长预期"？ |
| §3.2 5 建筑设定 | 主殿/居所/修炼塔/藏书阁/丹房——每个建筑核心价值清晰吗？ |
| §3.6 建筑实例状态机 | empty→constructing→built→upgrading→maxed 是否完整？ |
| §4.5 建筑总表数值 | 全升满 ~12750 灵石（15-25 次历练）是否符合"M3 一次玩 30-60 分钟单局"的节奏？ |
| §5.3 5 配方梯度 | 聚气丹 0.90 → 寿元丹 0.30，难度梯度是否合适？ |
| §7 培养子系统 | 修炼塔 vs 藏书阁的"速度 vs 悟性"分流是否真有策略空间？ |

#### 3. GDD-06 经济与数值（系数标定）

| 审阅点 | 问题 |
|---|---|
| §5 月俸 5/15/50/150/400 | 5 境界月俸阶梯是否合适？高境界贵是否够"防囤"？ |
| §6.2 base_speed 15→1200 | 跨境界 80x 跳变是否符合修仙感？ |
| §6.4 突破概率公式 | 校验样例 3 月 ≈54% / 10 月接近必成 是否符合预期？ |
| §7.1 base_power 100→150000 | 化神 15万 是否过于膨胀？ |
| §10 经济临界 | 自给 5-8 月转负 → 倒逼出门，临界是否合适？ |
| §11 数据落地结构 | 各 domain 表分散 + GDD-06 集中标定 的双层结构是否合理？ |

#### 4. ADR-0002 战斗接口 + ADR-0004 存档

ADR 是 M2 写代码的契约。重点审：

- ADR-0002 §3 BattleResolver 接口签名（M3 用 StatSimulator / M5 切换实现）是否解耦充分？
- ADR-0004 §3 5 点决策（version / partition / 兼容 / migration / 模板）是否覆盖你之前担心的"老存档崩"风险？
- ADR-0004 §6 各系统存档分区清单是否完整？

### 🟡 中等审（架构哲学）

#### 5. GDD-01 §6.12 + ADR-0003 v3.3

CharacterRegistry 注册扩展机制是否真的能实现"加新成长玩法零侵入 GDD-02 / ADR-0003 源码"？

- 接口 4 件套：register_state_mode / register_attribute / register_attribute_modifier_source / register_signal_listener
- 子系统典型流程示例（CultivationSystem._ready）

#### 6. GDD-11 扩展点 + 依赖矩阵

§3 依赖矩阵实表 + §6 M3 扩展位检查表（18 项）是否就是你想要的"M2 写代码地图"？

### 🟢 轻量审（M3 不依赖）

#### 7. GDD-07/08/10 内容章

这些章在 M3 实质内容少（音频静默 / 主线钩子接口 only / 美术等 M3 期产出）。审阅重点是"接口接得上 + 钩子目录覆盖广"。

## verdict 模板

请就每章给出 verdict（任选）：

```
verdict 选项：
- GDD-PASS              ← 完全通过，进 M2
- GDD-CHANGES (推进)    ← 有小修改但不阻塞推进，AI 后续顺手改
- GDD-CHANGES (阻塞)    ← 有结构问题，必须先改完才进 M2
- GDD-REJECT            ← 重大方向错误，需重新设计
```

期望反馈格式：

```
GDD-04: PASS
GDD-05: CHANGES (推进) —— §3.2.3 修炼塔 lv3 容量 5 太多，改 4
GDD-06: CHANGES (阻塞) —— §6.2 base_speed 化神 1200 太低，重定
ADR-0002: PASS
ADR-0004: PASS
其他: PASS
```

## 通过后的下一步

```
verdict 全 ∈ {PASS, CHANGES(推进)}
  │
  ├─ AI 执行：GDD-02 玩法剥离（按 docs/gdd-02-cleanup-plan.md）
  │   ├─ 行数 1635 → ~900
  │   └─ git commit "GDD-02 v3.2: cleanup"
  │
  ├─ AI 执行：CHANGES(推进) 项的小修改
  │
  ├─ M1 退出 ✅
  │
  └─ 进 M2：按 GDD-09 §4.1 二十项实装清单起步
      └─ 起点：TimeService autoload + EventBus + EventEngine 骨架
```
