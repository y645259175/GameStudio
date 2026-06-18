---
gdd_id: 09
gdd_title: 交付与验收
status: drafting
last_review: 2026-06-09
sections_complete: [设计精神, 里程碑总览, M1验收, M2验收, M3验收, 测试矩阵骨架, 存档兼容矩阵, 风险登记总表, M4-M7占位]
sections_pending: []
upstream_adr: [0001, 0002, 0003, 0004, 0005, 0006]
upstream_gdd: [gdd-01]
verdict: drafting
---

# GDD-09 · 交付与验收

> M1 起草纪律（用户定调 2026-06-09）：本章 M3 范围内**详细列**M1-M3 验收 + 测试矩阵 + 存档兼容；M4-M7 验收**仅留思路骨架**，详细标准 M4 启动时再展开（→ `docs/m1-deferred-details.md`）。

---

## 1. 设计精神

### 1.1 本章的作用

```
设计期：每个里程碑列"做完算做完"的清单 → 避免无限延期
开发期：按清单逐项打勾 → 验收门
测试期：测试矩阵 + 存档兼容矩阵 → 系统性发现问题
发布期：风险登记 + Steam checklist（M7 展开）
```

### 1.2 验收三原则

1. **每里程碑都有 verdict** —— `consistency-check` skill 跑通 + 用户审 + reviewer agent 同意
2. **验收前不进下个里程碑** —— M1 全 PASS 才进 M2；M3 完整循环跑通才进 M4
3. **存档兼容跨里程碑验证** —— 每次升级必跑"老存档加载新版本"测试

---

## 2. 里程碑总览（继承 PROJECT.md / GDD-01 §7.1）

| 里程碑 | 交付 | 主验收标准 | 状态 |
|---|---|---|---|
| **M1 概念固化** | GDD 11 章 + 6 ADR 全 PASS | §3 | `[~]` |
| **M2 框架搭建** | 11 核心 service + 配表骨架 | §4 | `[ ]` |
| **M3 垂直切片** | 1 历练 + 1 宗门 + 完整循环 + 美术达标 | §5 | `[ ]` |
| **M4 内容扩展** | 多建筑 / 多事件 / 派遣 / 多敌人 | §9（占位）| `[ ]` |
| **M5 主线 + 战斗升级** | 主线叙事 + 回合制战斗 + 技能/装备 | §9（占位）| `[ ]` |
| **M6 Beta 平衡** | 全局平衡 + 性能 + i18n | §9（占位）| `[ ]` |
| **M7 Steam Release** | EA / 正式上线 + 售后 | §9（占位）| `[ ]` |

---

## 3. M1 验收（概念固化）

### 3.1 必交付清单

| # | 内容 | 验证方式 | 状态 |
|---|---|---|---|
| M1-1 | GDD-01 ~ GDD-11 全部存在且各章 8 节框架就位 | `consistency-check` skill | ⏳ 即将完成 |
| M1-2 | 所有未来系统列入 GDD-11 扩展性总账 | `review-all-gdds` skill | ✅ GDD-11 已写 |
| M1-3 | 关键 ADR 全部 accepted（0001/0002/0003/0004/0005/0006）| ADR 索引 | ⏳ 0002/0004 + amendments 待用户审 |
| M1-4 | GDD-01 §6.12 角色契约 vs 子系统玩法分离哲学落地 | GDD-02 §0 + GDD-04 整章 | ✅ |
| M1-5 | 用户对全部章节 verdict 通过 | 用户审 | ⏳ |
| M1-6 | 数据驱动 / 双层时钟 / 接口抽象 / 存档前瞻 全部进 ADR | ADR 索引 | ✅ |

### 3.2 退出门

- 上 6 项全 ✅
- GDD-11 §6 M3 扩展位检查表全 ✅ 或 ⏳ M2
- `docs/m1-deferred-details.md` 已列出所有 M4-M7 延后细节

---

## 4. M2 验收（框架搭建）

> **M2 实装顺序参考**：先 TimeService + EventBus（最底层）→ SaveService + CharacterRegistry → 各 domain service → 配表烘焙管线。

### 4.1 必交付清单

| # | 内容 | 优先级 | 验证 |
|---|---|---|---|
| M2-1 | TimeService autoload + month / progress / year signals + advance_progress/outer API（ADR-0001 v1.1）| P0 | 单元测试 |
| M2-2 | EventBus autoload（GDD-01 §6.9）| P0 | 单元测试 |
| M2-3 | Character schema + 三维度状态机（ADR-0003 + amendment v3.3）| P0 | 单元测试 |
| M2-4 | CharacterRegistry autoload + 4 注册接口（ADR-0003 v3.3）| P0 | 单元测试 |
| M2-5 | BuffService 双表注册 + IBuffable + tick_monthly（ADR-0005）| P0 | 单元测试 |
| M2-6 | SectService + Sect 数据结构（ADR-0006）| P0 | 单元测试 |
| M2-7 | InventoryService（领域规则，通过 SectService 读写）| P0 | 单元测试 |
| M2-8 | BattleResolver 接口 + StatSimulator + ElementCalculator（ADR-0002）| P0 | 单元测试覆盖战力公式 + 五行加成 |
| M2-9 | EventEngine + ConditionEvaluator + 13 action handlers（GDD-03 §2）| P0 | 单元测试每个 action |
| M2-10 | CultivationSystem + 闭关 / 突破公式实装（GDD-04）| P0 | 单元测试公式 |
| M2-11 | BuildingService / ProductionService（GDD-05）| P0 | 单元测试 |
| M2-12 | SaveService + 5 点决策完整实装（ADR-0004）| P0 | 单元测试 + 跨版本加载 |
| M2-13 | WorldEventTrigger autoload + 内置触发器（GDD-10 §5）| P0 | 单元测试钩子触发 |
| M2-14 | CGPlayer autoload stub（GDD-10 §6）| P0 | 接口可调用 |
| M2-15 | DispatchService stub（GDD-03 §5）| P0 | 类文件就位 |
| M2-16 | SectEventRouter stub（GDD-05 §9）| P0 | autoload 注册 |
| M2-17 | 配表烘焙管线（tools/ 已有部分基础）| P0 | xlsx → .tres 跑通 |
| M2-18 | data/ 目录组织规范（GDD-06 §11 已定）| P0 | 目录建立 |
| M2-19 | 主线钩子目录在 EventBus 注册（钩子可空但接口齐）| P0 | 接口扫描 |
| M2-20 | pre-commit hook：dict["x"] 静态扫描 + [cross-system] tag 检查 | P1 | hook 跑通 |

### 4.2 测试覆盖率门

- 每个 service 至少 1 个核心单元测试 ≥ 通过
- SaveService 跨版本加载测试通过（M2-12）
- 集成测试：1 次完整月节拍跑通（TimeService → 各 service tick → 状态变化）

---

## 5. M3 验收（垂直切片 VS1）

### 5.1 玩法必交付

| # | 内容 | 优先级 | 验证 |
|---|---|---|---|
| M3-1 | 玩家能完成一次完整循环（宗门 → 历练 → 回宗 → 资源回流 → 修炼/建造）| P0 | 实玩 smoke |
| M3-2 | 5 件基本功能：主菜单 / 开始 / 结束 / 存档 / 读档 全可用 | P0 | 实玩 smoke |
| M3-3 | 至少 10 种数据驱动事件可触发（GDD-03 §2.9.5 M3 20-30 个）| P0 | smoke |
| M3-4 | 边际递减系统在第 3 月明显感知（GDD-01 §2.3 / GDD-04 §3.3 / GDD-06 §4）| P0 | 用户实玩反馈问卷 |
| M3-5 | UI 视觉达基础商业化标准 | P0 | art-director APPROVE |
| M3-6 | 主要立绘有 canonical key（门主 + 初始弟子 + 1-2 关键 NPC）| P0 | art-director gate |
| M3-7 | 存档跨"假装的版本升级"测试通过（手工改 save_version 模拟）| P0 | 单元测试 |
| M3-8 | 1 张历练图（含 ~20-30 节点 + 中途撤离 + 终点撤离）| P0 | 配表 |
| M3-9 | 5 建筑 + 5 炼丹配方 + 招收（自动来投 + 主动）跑通 | P0 | 配表 + smoke |
| M3-10 | 战斗（StatSimulator + 五行）+ 战利品落袋跑通 | P0 | smoke |
| M3-11 | 撤离 3 类（active / timeout / defeat）触发正确 | P0 | smoke |
| M3-12 | 数据驱动：所有平衡数值（GDD-06）全配表化（无硬编码）| P0 | review |

### 5.2 数值标定门

按 GDD-06 §10.4 平衡假设：

| 指标 | 目标 | 验证 |
|---|---|---|
| 单局时长 | 前期 ~20 / 后期 ~60 分钟 | 实玩计时 |
| 单局境界进度 | 炼气递进 1-3 级 + 可能 1 次大突破 | 实玩 |
| 自给经济转负 | 5-8 月（不出门）| 配表跑数 + 实玩 |
| 单次历练净收益 | 200-500 灵石 | smoke 实测 |
| 战斗胜率 | 同境界 ~50% / 高 1 大境界 ~碾压 | smoke 100 局 |

### 5.3 兼容性门

- M3 完工时跑 GDD-11 §6 扩展位检查表，全 ✅ 或 ⏳ M4
- M3 → M4 升级路径：模拟"加 dispatch_tasks chunk"老存档加载通过

---

## 6. 测试矩阵骨架

### 6.1 分层

```
单元测试（Unit）       ─ 每个 service 公共 API（M2-M3 持续维护）
集成测试（Integration）─ service 之间交互（M2 起）
冒烟测试（Smoke）      ─ 端到端核心循环（M3 起）
回归测试（Regression） ─ 已发现 bug 列表，每次升级跑（M4 起）
平衡测试（Balance）    ─ 数值/概率模拟，跑 100-1000 次取统计（M6）
```

### 6.2 M3 必跑测试清单

| 测试 | 频率 | 类型 |
|---|---|---|
| 月节拍跨各 service 推进正确 | 每 commit | 集成 |
| EventEngine 13 actions 各 1 用例 | 每 commit | 单元 |
| StatSimulator：碾压 / 势均 / 逃跑 3 场景 | 每 commit | 单元 |
| 五行加成：例 1（+50/+30）+ 例 2（+40/+20）固化测试 | 每 commit | 单元 |
| 闭关公式：4 角色 × 3 功法 = 12 用例（GDD-04 §2.2/§3.2 骨架 + GDD-06 §6.2 系数）| 每 commit | 单元 |
| 突破检定：3 月打磨 / 10 月打磨 锚点 | 每 commit | 单元 |
| SaveService 5 点：跨版本 / 缺字段 / 未知字段保留 / 模板独立 / 分区独立 | 每 commit | 单元 |
| 完整循环 smoke：宗门 → 历练 → 战斗 → 回宗 → 突破 | 每周 | 冒烟 |
| 撤离 3 类（active/timeout/defeat）| 每周 | 冒烟 |

### 6.3 测试工具

- Godot Test Framework（GDD-02 §1.9 已用）
- 配表数据 mock fixtures（M2 后期搭）
- AI agent `tester` 自动生成 + `qa-lead` 复审

---

## 7. 存档兼容矩阵

### 7.1 矩阵结构

| 老存档版本 ↓ \ 新版本 → | M3.0 | M3.1 | M4.0 | M5.0 | M6.0 | M7.0 |
|---|---|---|---|---|---|---|
| M3.0 | ✓ | ✓（无 migration）| 🔄 migration_v1_to_v2 | 🔄 链 | 🔄 链 | 🔄 链 |
| M3.1 | — | ✓ | 同上 | 同上 | 同上 | 同上 |
| M4.0 | — | — | ✓ | 🔄 | 🔄 | 🔄 |

> M3 期仅 M3.0 / M3.1 列实质内容；M4+ 列 → docs/m1-deferred-details.md

### 7.2 ADR-0004 5 点机制保证

- 加字段（M3.0 → M3.1）= 加 default，无 migration
- 加 chunk（M3 → M4 dispatch_tasks）= 自动空 default，无 migration
- 删字段 / 改类型 / 改语义 = migration_vN_to_vN+1（M2 期框架就位，M4+ 写具体）

### 7.3 M3 必跑兼容测试

| 场景 | 期望 |
|---|---|
| 手工改 save_version 模拟 M3 → M4 | 加载通过，dispatch_tasks 默认空数组 |
| 手工删 character.lifespan_remaining_months | 加载通过，default = 0 |
| 手工塞未知字段 character.foo = "bar" | 加载通过，下次保存 foo 仍在 |

---

## 8. 风险登记总表

> 收拢 GDD-01 §8.2 + 各章 §X 风险表的**全项目高优先级风险**。

| 风险 | 概率 | 影响 | 缓解 | 触发里程碑 |
|---|---|---|---|---|
| 范围爆炸（修仙题材内容欲望大）| 高 | 高 | M1 章节穷尽 + 走 ADR | M1-M5 |
| M1 偷工（跳 GDD-10/11 直接编码）| 高 | 高 | M1 退出条件 = 11 章全 PASS | M1 |
| 存档迁移痛（M4 加内容老存档崩）| 中 | 高 | ADR-0004 5 点机制 + M2 必做 | M4-M5 |
| 架构债（早期赶进度跳抽象）| 中 | 高 | §6.2 三接口 M2 必落地 + PR review 强制 | M2-M3 |
| 节奏失衡（内务/历练 50/50 跑偏）| 中 | 中 | M3 加用户实玩节奏问卷 | M3 |
| 战斗占位换正式版风险（M3→M5）| 中 | 中 | BattleResolver 接口测试覆盖 + version 字段 | M5 |
| AI 立绘风格不一致 | 中 | 中 | canonical key sprite gate 强制 | M3-M5 |
| M3 美术不达标拖期 | 中 | 中 | M1 GDD-07 起 art-director 给 key visual + style guide | M3 |
| 经济压力标定失准 | 中 | 中 | GDD-06 §10.4 假设 + M3 实玩校准 | M3 |
| 走火入魔 / 派遣 / 主线 M5 实装时挡住 | 低 | 中 | GDD-11 §6 扩展位检查 + 每次新增走 5 步流程 | M4-M5 |
| GDD-04 公式参数过多难调 | 低 | 中 | 每公式带校验样例（GDD-06 §6.2 / §6.4）| M3-M6 |
| 数值膨胀（化神 base_power=15万）| 低 | 低 | 用 int64 + 修仙感不是 bug | M5 |

---

## 9. M4-M7 验收（占位骨架）

> 详细标准 → `docs/m1-deferred-details.md` 的 **GDD-09** 段。M4 启动时展开。

| 里程碑 | 大方向 | 关键 |
|---|---|---|
| M4 | 内容铺满 + 派遣实装 + M3 扩展空槽内容 | 不引入新框架，仅扩 M1 已规划 |
| M5 | 主线叙事 + 回合制战斗升级 + 技能 / 装备 | 走 5 步流程 + WorldEventTrigger 钩子激活 |
| M6 | Beta 平衡 + 性能 + i18n | 不加新内容/系统 |
| M7 | Steam EA / 正式 + 售后 | Steam checklist 展开 |

---

## verdict

drafting · M3 完成后再做完整 PASS。本章 M3 范围已详细，M4-M7 延后骨架明确。
