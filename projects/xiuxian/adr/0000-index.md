# ADR Index · xiuxian

> Architecture Decision Records 索引。新增 ADR 时在本文件加一行。

| ID | 标题 | 状态 | 日期 | 关联 GDD |
|---|---|---|---|---|
| [0001](./0001-double-clock.md) | 双层时钟（月历 + 历练百分比，大世界连续推进） | accepted | 2026-05-26 | gdd-01 §2.3 / §6.4 |
| [0002](./0002-battle-resolver-interface.md) | 战斗系统接口抽象（M3 数值对拼 / M5 回合制） | 待建 | — | gdd-01 §6.2 / §6.8 |
| [0003](./0003-character-state-machine.md) | 角色统一数据结构与三维度状态（身份 / 行动 / Buff，v3.2） | accepted | 2026-05-26 | gdd-01 §6.3 |
| [0004](./0004-save-architecture.md) | 存档架构（版本号 / 数据分区 / 兼容策略） | 待建 | — | gdd-01 §6.5 / §6.7 |
| [0005](./0005-buff-system.md) | 通用 Buff 系统（双表注册 + IBuffable 任意实体挂载，v2） | accepted | 2026-05-26 | gdd-01 §6.10 |
| [0006](./0006-sect-data-structure.md) | 宗门数据结构（实体 + IBuffable + 子领域服务边界，v1.1） | accepted | 2026-05-26 | gdd-01 §6.11 |

## 状态语义

- **proposed**：草稿，待用户评审
- **accepted**：用户批准，进入实现
- **deprecated**：已过时但未被替代
- **superseded**：被新 ADR 替代（在 `supersedes` 字段标明被替代者）

## 编号规则

- 4 位零填充递增：0001, 0002, ...
- 0000 保留给本索引文件
- 文件名：`<id>-<kebab-slug>.md`

## M1 阶段必建 ADR

按 GDD-01 §7.3 / §6 技术架构原则，M1 退出条件包含 6 个 ADR：

1. ✅ ADR-0001 双层时钟（v2 大世界连续推进）
2. ⏳ ADR-0002 战斗接口（GDD-03 起草前）
3. ✅ ADR-0003 角色三维度（v3.1 删除 injury_level 字段）
4. ⏳ ADR-0004 存档架构（GDD 全章完成后）
5. ✅ ADR-0005 通用 Buff 系统（v2 双表注册 + IBuffable）
6. ✅ ADR-0006 宗门数据结构

## ADR 之间的依赖关系

```
ADR-0001 时钟 ──── month_advanced ─────┐
                                      ↓
ADR-0005 Buff ── tick_monthly ──→  各 IBuffable 实体
   ↑                              ┌────┴─────┐
   │                              ↓          ↓
   │                          ADR-0003   ADR-0006
   │                          Character    Sect
   │                              ↑          ↑
   │                              └────┬─────┘
   │                                   │
   └─────── ADR-0004 存档 ──────────────┘
              ↑
              │
          ADR-0002 战斗（消费 buffs / 写 buffs）
```


