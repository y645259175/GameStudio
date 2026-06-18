---
adr_id: 0004-save-architecture
status: accepted
date: 2026-06-09
accepted_at: 2026-06-09
deciders: [用户, codebuddy]
supersedes:
related_gdd: gdd-01 §6.5 / §6.7 存档前瞻
---

# ADR 0004 · 存档架构（版本号 + 数据分区 + 兼容策略）

## 上下文

> 用户特别强调（GDD-01 §6.7）："M2 必做"——存档结构 / 数据位置一次性敲定，避免 M4-M5 加内容时老存档崩。

游戏全生命周期会持续加内容：M3 仅历练 + 宗门 + 5 建筑 / M4 加派遣 + 演武场 + 炼器 / M5 加主线 + 技能 + 装备 / M6 平衡微调 / M7 EA。每次都可能加字段、改 schema、加新系统。

如果不在 M2 期把存档架构想透：
- M4 加派遣弟子 → 老存档没 `dispatch_tasks` 字段 → 加载崩
- M5 加技能系统 → Character schema 多 `skills` 字段 → 老存档默认为空崩 NullRef
- M6 改某数值 → 玩家保存的实例值 vs 模板值冲突 → 行为异常

需要一套"未来 5 年内不爆"的存档架构。

## 决策

采用 **5 点决策综合架构**：

1. **版本号** —— save_version 标记 schema 版本，加载时按版本路由
2. **数据分区** —— 按领域拆 chunk，独立加载，新 chunk 不破坏老存档
3. **get + default 兼容** —— 读字段一律 `dict.get(key, default)`，缺字段 = default
4. **未知字段保留** —— 加载时遇到不认识的字段不报错，保留原样写回
5. **模板 vs 实例分离** —— 模板（不变 schema）和实例（玩家状态）分开存

### 1. 版本号

```gdscript
# save_data.json 顶层
{
  "save_version": 2,           # 整数递增
  "game_version": "0.3.0",     # 游戏版本（信息）
  "saved_at": "2026-06-09T15:00:00",
  "chunks": { ... }            # 分区数据
}
```

**升级规则**：

- schema 兼容变更（加字段 + 默认值）→ save_version 不动
- schema 不兼容变更（删字段 / 改类型 / 改语义）→ save_version +1
- 加载时遇到 `saved.save_version > current.save_version` → 报错"存档来自更新版本"
- 加载时遇到 `saved.save_version < current.save_version` → 跑 migration 链升级

**migration 链**：

```gdscript
# scripts/data/save_migrations/migration_v1_to_v2.gd
class_name MigrationV1ToV2
extends SaveMigration

func apply(old_data: Dictionary) -> Dictionary:
    # 例：M5 把 character.skills 从 Array 改为 Dict
    for c in old_data.chunks.characters:
        if "skills" in c and c.skills is Array:
            c.skills = _array_to_dict(c.skills)
    old_data.save_version = 2
    return old_data
```

SaveService 启动时按版本顺序串行跑所有 migration。

### 2. 数据分区

存档**按领域拆 chunk**，每个 chunk 独立加载 / 独立 schema：

```
save_data.chunks = {
  "world":            { current_month: 14, current_year: 1, ... },           # GDD-01 §6.4 时钟
  "sect":             { resources: {...}, buildings: [...], reputation, ... },# GDD-01 §6.11 宗门
  "characters":       [ Character × N ],                                      # GDD-02 角色
  "buff_instances":   [ BuffInstance × N ],                                   # GDD-01 §6.10 / ADR-0005
  "expedition":       { current_map?, current_node_id?, ... },                # GDD-03 历练运行态
  "cultivation":      { breakthrough_attempts: [...], ... },                  # GDD-04 成长记录
  "production_tasks": [ AlchemyTask / BuildingTask × N ],                     # GDD-05 生产任务
  "main_line":        { active_hooks: [...], world_flags: {...} },            # GDD-10 主线（M5）
  "dispatch_tasks":   [ DispatchTask × N ],                                   # GDD-03 §5 派遣（M4）
  "settings":         { ui_prefs: {...}, ... }                                # 玩家偏好
}
```

**纪律**：

- 加新系统 = 加新 chunk key，**不动现有 chunk schema**
- 老存档加载新版本时：缺的 chunk = 空 default（用 5 点规则 3）
- 各系统的 service 只读写自己的 chunk，**不跨 chunk 直读**（与 GDD-01 §6.9 一致）

### 3. get + default 兼容

```gdscript
# ❌ 直接访问：缺字段崩
var skills = c["skills"]

# ✅ 始终 get + default
var skills = c.get("skills", [])
var equipped = c.get("equipped", {})
var lifespan = c.get("lifespan_remaining_months", 0)
```

适用于：

- 老存档没有的新字段
- 可选字段（如 status_effects）

review 红线：所有反序列化代码必须 `dict.get(...)`，pre-commit hook 静态检查（M2 实装）。

### 4. 未知字段保留

存档可能被外部工具 / mod 加自定义字段。加载时**不认识不报错，保留写回**：

```gdscript
func deserialize(data: Dictionary):
    self.known_field_a = data.get("known_field_a", default_a)
    self.known_field_b = data.get("known_field_b", default_b)
    self._unknown_fields = {}                  # 保留未知
    for key in data:
        if not key in KNOWN_KEYS:
            self._unknown_fields[key] = data[key]

func serialize() -> Dictionary:
    var d = { "known_field_a": self.known_field_a, "known_field_b": self.known_field_b }
    for key in self._unknown_fields:
        d[key] = self._unknown_fields[key]    # 写回
    return d
```

这让"M4 mod 加字段 → M5 玩家覆盖更新游戏 → mod 字段不丢"成为可能。

### 5. 模板 vs 实例分离

存档**只存实例数据**（玩家的运行态），不存模板（静态配置）：

```
模板（不存档，每次启动从 data/baked/ 加载）：
  - 建筑模板 (cultivation_tower 各级 build_cost / capacity)
  - 配方模板 (recipe_qi_pill 材料 / 时长)
  - 事件模板 (event_yuyu_yanquan 三幕 actions)
  - 战斗模板 / loot 模板 / 角色生成模板

实例（存档）：
  - 玩家的 BuildingInstance（哪个槽建了什么 lv 几）
  - 玩家的 AlchemyTask（哪个配方在哪月开始）
  - 玩家的 Character（属性 / 状态 / hp）
  - 玩家的 ExpeditionState（哪张图哪个节点）
```

**好处**：

- 数值平衡调整（改 build_cost）→ 加载老存档自动用新值，无需 migration
- 存档体积小（不存重复数据）
- 模板版本独立于存档版本

**例外**：玩家自定义内容（M5 mod）的"实例化模板"需另存（M5 决定路径）。

### SaveService 接口

```gdscript
# scripts/data/save_service.gd（autoload）
class_name SaveService extends Node

func save(slot_id: int = 0) -> bool                    # 写到 user://saves/slot_<id>.json
func load(slot_id: int = 0) -> bool                    # 读 + migration + 反序列化
func list_slots() -> Array[SaveMetadata]               # M4 多存档槽用
func delete_slot(slot_id: int) -> bool                 # M4 多存档槽用

# 各系统注册自己的 chunk 序列化
func register_chunk(chunk_id: String, serializer: ChunkSerializer)
```

**ChunkSerializer 接口**：

```gdscript
class_name ChunkSerializer
extends RefCounted

func serialize() -> Dictionary: pass               # 各 service 实装
func deserialize(data: Dictionary) -> void: pass   # 各 service 实装，必须 get+default
func default_data() -> Dictionary: pass            # 老存档缺 chunk 时用
```

## 影响

### 正面

- M4-M5 加内容**零迁移痛**（90% 情况下加 chunk + 加字段就行）
- 数值平衡调整不需要 migration（模板分离）
- 5 点规则形成强约束，新人写 service 不会挖坑
- 单存档结构兼容多存档（M4 加 slot_id）

### 负面

- 反序列化必须 `dict.get` 增加心智负担（用 hook 强制）
- migration 链多版本后变长（每加一个不兼容变更 +1 migration）
- 未知字段保留可能让无效数据滞留（M5 加"清理工具"）

### 风险

| 风险 | 缓解 |
|---|---|
| 某 service 直接读 character["xxx"] 没用 get | pre-commit hook 静态扫描 `\[\"\w+\"\]` 模式 |
| migration 写错丢数据 | 跑 migration 前自动备份原文件到 user://saves/backups/ |
| chunk 之间隐式依赖（加载顺序）| SaveService 按拓扑序加载，service 必须声明依赖 |
| 模板版本与存档版本不一致 | 启动时检测：模板 schema 哈希存到 save_data.template_hash 作信息字段 |

## 替代方案（已否决）

### A. 单一大 JSON 不分区

❌ 加任何字段都要全档迁移，违反 5 点规则 3-4。

### B. 二进制存档（更小更快）

❌ M3 阶段不必要；JSON 调试友好 + 跨平台一致；性能在 M6 优化时评估。

### C. SQL 数据库

❌ 单机单玩家场景过重；M3 不需要查询能力。

## 实施清单

| # | 内容 | 里程碑 |
|---|---|---|
| 1 | SaveService autoload + 5 点接口 | M2 |
| 2 | ChunkSerializer 接口 + 各 service 实装 | M2 |
| 3 | save_version=1 + migration 框架 | M2 |
| 4 | 单元测试：跨版本加载 / 缺字段 / 未知字段保留 / 模板更新不破存档 | M2 |
| 5 | pre-commit hook 静态扫描 dict["x"] 模式 | M2 后期 |
| 6 | 手工跨版本测试（M3-7 验收）| M3 |
| 7 | M4 多存档槽 slot_id 启用 | M4 |
| 8 | M4-M5 加 chunk（dispatch / main_line / skills）| M4-M5 |
| 9 | M5+ 跨版本迁移工具 / 清理工具 | M5 → docs/m1-deferred-details.md |

## 关联

- 上游：GDD-01 §6.5 存档基础原则 / §6.7 存档前瞻设计（5 点）
- 下游：所有 service 的 ChunkSerializer 实装
- 派生：M4-M5 跨版本迁移详细方案 → docs/m1-deferred-details.md
