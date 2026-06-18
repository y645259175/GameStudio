---
doc_id: data-format-spec
version: 1.0
status: stable
last_updated: 2026-05-29
applies_to: 工作室所有 Godot 项目（首次落地：xiuxian）
related:
  - data-editing-guide.md
  - tools/excel_convert.py
---

# 工作室通用配表范式 v1.0

> **稳定范式**：所有未来新建的配置表 / 运行时数据加载 / 多语言机制都遵循本文。
> 本范式适用于工作室所有 Godot 项目，首批落地于 xiuxian。

---

## 1. 五条铁律（不可破）

任何违反以下铁律的代码都会被 review 拒掉：

1. **源表只能是 `.xlsx`**（多 sheet 容器） + 同名 `.schema.toml`（程序员维护的 schema）
2. **xlsx 表头两行制**：第 1 行中文表头（含「备注」列）、第 2 行英文字段名、第 3 行起数据
3. **运行时禁止读 .xlsx / .csv / 文本格式数据**——只能通过 `DataRegistry` 读 baked 后的 `.tres`
4. **任何 commit 前必须跑** `python tools/excel_convert.py --validate`，校验失败拒绝合并
5. **schema 与 xlsx 字段不一致 = 编译期错误**（导表脚本退出码非零，CI 拦截）

---

## 2. 四层数据架构

```
┌─────────────────────────────────────────────────────────┐
│  Layer 1 · 源表（人编辑，进 git）                         │
│  data/table/<TableName>.xlsx                             │
│  data/table/proto/<table_name>.schema.toml               │
│  data/table/TEXT/文本表_*.xlsx                            │
├─────────────────────────────────────────────────────────┤
│  Layer 2 · 烘焙（离线工具 tools/excel_convert.py）        │
│  · 加载 schema → 解析 xlsx → 类型转换 → 校验 → 写产物    │
│  · 增量优化（hash 比对，未变 skip）                       │
│  · 失败退出码非零 + 行号定位错误                           │
├─────────────────────────────────────────────────────────┤
│  Layer 3 · 烘焙产物（gitignore，运行时加载）              │
│  data/baked/<name>.tres   ← Godot Resource，主格式         │
│  data/debug/<name>.json   ← debug 格式，方便外部工具看     │
│  data/baked/_manifest.json ← 烘焙清单（含 hash + 表清单） │
├─────────────────────────────────────────────────────────┤
│  Layer 4 · 运行时（autoload DataRegistry）               │
│  · 启动时 _ready() 一次性 load 所有 tres，建主键索引      │
│  · 提供 get_row / get_table / get_field / text 4 个 API   │
│  · 业务代码绝不直接 load 配表 res                         │
└─────────────────────────────────────────────────────────┘
```

---

## 3. 源表规范（Layer 1）

### 3.1 目录与命名

```
data/table/
├── BUFF系统.xlsx                   ← 业务表，名字策划友好（中文）
├── 角色系统.xlsx
├── 灵根系统.xlsx
├── proto/                          ← schema 集中地
│   ├── buff_system.schema.toml      （← 与 BUFF系统.xlsx 配对）
│   ├── character_system.schema.toml
│   └── text_table.schema.toml      （文本表共用一个 schema）
└── TEXT/                           ← 多语言文本表，所有名为 文本表_*.xlsx
    └── 文本表_基础文本表.xlsx
```

**配对规则**：每个 `.schema.toml` 通过 `target_xlsx` 或 `target_xlsx_glob` 指向源表。导表脚本会显式做配对，不靠"猜"。

### 3.2 xlsx 表头两行制

每个 sheet **强制**第 1 行 + 第 2 行结构：

```
第 1 行 │ buff主类id  │ 备注  │ buff子类id │ 备注 │ 名称       │ buff参数1  │ ...
第 2 行 │ buff_main_id│       │buff_subtype_id│   │ buff_desc  │ buff_param1│ ...
第 3 行 │ buff_injury │ 受伤  │ buff_injury_main │ │ Text_xxx   │ injury     │ ...
（数据） │              │       │                  │ │            │            │ ...
```

**关键约定**：

- **第 1 行 = 中文表头**：策划阅读用。
- **第 2 行 = 英文字段名**：程序读这行（与 schema.toml 的 fields 对齐）。
- **「备注」列不导出**：第 1 行写「备注」的列被烘焙脚本自动剔除。第 2 行该列可留空。
- **第 3 行起 = 数据行**：直到第一个全空行结束。

### 3.3 schema.toml 文件规范

```toml
schema_version = 1
target_xlsx    = "BUFF系统.xlsx"            # 单 xlsx 配对
output_baked   = "buff_system.tres"          # data/baked/ 下产物名

# ---- 一个 sheet 对应一个 [tables.X] -----------------------------------------
[tables.BuffType]
sheet = "buff枚举"                           # 必须与 xlsx 的 sheet 名一致
pkey  = "buff_subtype_id"                    # 主键字段（必须存在于 fields 里）
cn    = "Buff 类型注册表"                     # 中文名（错误信息用）
desc  = "声明每个 buff 子类的参数 schema"     # 长描述
inherit_when_blank = ["buff_main_id"]        # 承上规则：列空白时沿用上一行（多 subtype 共享 main）

[tables.BuffType.fields.buff_main_id]
type = "string"
cn   = "buff主类id"

[tables.BuffType.fields.buff_subtype_id]
type = "string"
cn   = "buff子类id"

[tables.BuffType.fields.buff_desc]
type = "tid"                                 # 引用文本表的 key
fkey = "TextTable.key"
cn   = "中文描述key"
```

### 3.4 schema 字段类型

| type | 说明 | xlsx 单元格示例 | 烘焙后类型 |
|---|---|---|---|
| `string` | 字符串 | `injury` / `INT16` | `String` |
| `int` | 整数 | `10` / `-30` | `int` |
| `float` | 浮点数 | `1.5` | `float` |
| `bool` | 布尔（只接受 `0/1/true/false`） | `1` | `bool` |
| `enum` | 枚举（配 `enum = [...]`） | `INT16` | `String`（已校验） |
| `tid` | 文本表 key（配 `fkey="TextTable.key"`） | `Text_buff_injury_main` | `String` |
| `fkey` | 外键（配 `fkey="OtherTable.col"`） | `buff_injury` | 同源类型 |
| `dynamic` | 类型由其他字段反查决定（配 `type_resolver=...`） | `10,20,30` | 反查后的类型 |

**`dynamic` 用于变长参数**（例如 buff_param1-5 不同 buff 类型用法不同）：

```toml
[tables.BuffInstance.fields.buff_param1]
type          = "dynamic"
type_resolver = "BuffType[{buff_subtype_id}].buff_param1_type"
cn            = "buff参数1（实际值）"
```

含义：本字段的真实类型 = 在 `BuffType` 表中找 `buff_subtype_id == <本行的 buff_subtype_id>` 的那行，取它的 `buff_param1_type` 字段值。值为 `INT16` 就转 int、`ARRAY` 就转列表。

### 3.5 ARRAY 类型语法

xlsx 单元格里用半角逗号分隔：`10,20,30,40,50,60` → `[10, 20, 30, 40, 50, 60]`。元素全部尝试转 int → float → string。

### 3.6 文本表（多语言）

文本表是**唯一可以多文件共享一个 schema** 的表型：

```toml
schema_version    = 1
target_xlsx_glob  = "TEXT/文本表_*.xlsx"     # glob 匹配多文件
output_baked      = "text_cn.tres"            # 全部合并到一个产物

[tables.TextTable]
sheet = "文本"
pkey  = "key"

[tables.TextTable.fields.key]
type = "string"

[tables.TextTable.fields.content_cn]
type = "string"
```

**多个文本表分文件管理**（按业务模块），但烘焙后合并为一个 `text_cn.tres`，运行时 `DataRegistry.text("Text_xxx")` 统一查询。未来加 `content_en` / `content_jp` 列扩展多语言。

---

## 4. 烘焙工具（Layer 2）

```bash
python tools/excel_convert.py                  # 增量烘焙（推荐日常用）
python tools/excel_convert.py --force          # 强制全量
python tools/excel_convert.py --validate       # 仅校验（CI 用）
python tools/excel_convert.py BUFF系统         # 只烘焙某张表
python tools/excel_convert.py --list           # 列出已注册 schema

python tools/excel_convert_watch.py            # 开发期 watcher（自动触发）
```

### 4.1 烘焙流程

```
1. 加载 data/table/proto/*.schema.toml
2. 按 schema 配对 xlsx（target_xlsx 或 target_xlsx_glob）
3. hash 比对 _manifest.json，未变跳过（增量优化）
4. 收集所有文本表 key（供 tid 校验）
5. 第一遍：读 xlsx → 类型转换 → 主键唯一性校验 → 累积错误
6. 第二遍：fkey 完整性 + dynamic 类型反查
7. 写产物：data/baked/<name>.tres + data/debug/<name>.json
8. 更新 _manifest.json（含 source_hash）
```

### 4.2 退出码

| 码 | 含义 | CI 行为 |
|---|---|---|
| 0 | 成功 | 通过 |
| 1 | 校验失败（schema 不一致 / 主键重复 / fkey 缺失 / 类型错） | 拦截 |
| 2 | 其它错误（schema 文件缺失 / IO 错） | 拦截 |

### 4.3 错误定位

所有错误带源定位：

```
BUFF系统.xlsx [buff实例] row=8 field=buff_param2: expected ARRAY, got '10,abc,30'
```

策划照此可直接打开 xlsx 跳到第 8 行第 buff_param2 列修。

### 4.4 增量烘焙

`_manifest.json` 记录每个产物对应的 `source_hash = hash(schema + xlsx)`。下次跑：
- 当前 hash == manifest hash → skip
- 否则 → 重烘焙

`--force` 跳过 hash 检查。`--validate` 不写产物只校验。

---

## 5. 运行时（Layer 4）

### 5.1 autoload 注册

`Project Settings → Autoload` 添加：

| 名字 | 路径 | 单例 |
|---|---|---|
| `DataRegistry` | `res://game/scripts/data/data_registry.gd` | ✅ |

### 5.2 业务侧 API

```gdscript
# 取一行（按主键）
var row = DataRegistry.get_row("BuffInstance", 1)
# row = {"buffid": 1, "buff_main_id": "buff_injury", "buff_param1": 20, ...}

# 取整张表
var all_types = DataRegistry.get_table("BuffType")

# 取某字段（带默认值）
var dur = DataRegistry.get_field("BuffInstance", 1, "buff_param2", 0)

# 多语言文本（短手语）
var label = DataRegistry.text("Text_buff_injury_main")  # → "受伤"
```

### 5.3 业务侧禁止做的事

```gdscript
# ❌ 禁止：直接 load 烘焙产物
var res = load("res://data/baked/buff_system.tres")

# ❌ 禁止：直接读 xlsx / json / csv
var f = FileAccess.open("res://data/table/BUFF系统.xlsx", ...)

# ❌ 禁止：在 _ready() 之前调用 DataRegistry
# 解决：业务 autoload 顺序排在 DataRegistry 之后
```

### 5.4 性能预期

启动加载所有产物 → 建主键索引：
- 100 行：< 5ms
- 1000 行：< 30ms
- 10000 行：< 200ms

查询 O(1)（Dictionary 主键索引）。

---

## 6. 新增配置表 SOP（必读）

新策划想加一张表？必走以下 7 步：

### Step 1 · 决定表名

中文，策划友好。例：`装备系统.xlsx`。

### Step 2 · 设计 schema

在 `data/table/proto/` 新建 `equip_system.schema.toml`：

```toml
schema_version = 1
target_xlsx    = "装备系统.xlsx"
output_baked   = "equip_system.tres"

[tables.Equipment]
sheet = "装备主表"
pkey  = "equip_id"

[tables.Equipment.fields.equip_id]
type = "int"
cn   = "装备ID"

[tables.Equipment.fields.equip_name_tid]
type = "tid"
fkey = "TextTable.key"
cn   = "装备名（指向文本表）"

# ... 其它字段
```

### Step 3 · 创建 xlsx

新建 `data/table/装备系统.xlsx`，按两行表头制填：

```
A1: 装备ID    B1: 备注  C1: 装备名     D1: 备注  ...
A2: equip_id  B2:       C2: equip_name_tid D2:   ...
A3: 1001      B3: 木剑  C3: Text_equip_001 D3:   ...
```

### Step 4 · 写文本表条目

`data/table/TEXT/文本表_装备.xlsx`：

```
A1: 文本key       B1: 文本内容
A2: key           B2: content_cn
A3: Text_equip_001 B3: 木剑
```

### Step 5 · 跑校验

```bash
python tools/excel_convert.py --validate
```

通过即合规。失败按错误信息修。

### Step 6 · 跑烘焙

```bash
python tools/excel_convert.py
```

产生 `data/baked/equip_system.tres`。

### Step 7 · 业务侧消费

```gdscript
var equip = DataRegistry.get_row("Equipment", 1001)
var name = DataRegistry.text(equip.equip_name_tid)
```

**完成**。无需改 DataRegistry，无需改 autoload。

---

## 7. CI 集成（推荐）

`pre-commit` 或 GitHub Actions 添加：

```yaml
- name: Validate config tables
  run: python tools/excel_convert.py --validate
```

任何 schema/xlsx 不一致 → CI 红 → 拒绝合并。

---

## 8. 关键决策记录

| 决策 | 选择 | 理由（不展开理由） |
|---|---|---|
| 源表格式 | xlsx | 策划编辑工具完整、支持多 sheet、配套表头规范成熟 |
| schema 格式 | TOML（独立文件） | VSCode 原生高亮、注释友好、与 xlsx 解耦 |
| 运行时格式 | Godot .tres + JSON | tres 原生 load、JSON 给外部工具 |
| 序列化器 | 自研（Python 写 .tres 文本） | 不引入 protobuf 等重型工具链 |
| 多语言机制 | TID 引用 + 独立文本表 | 多语言扩展只需加列，业务代码无感 |
| 增量优化 | source_hash 比对 | 简单稳定，比 mtime 可靠 |
| 校验时机 | 烘焙时（强校验）+ CI（强校验） | 错误尽早 catch，运行时不重复校验 |

---

## 9. 不采纳方案备忘

| 候选 | 不采纳原因 |
|---|---|
| 纯 CSV | 多 sheet 表达力差；中文 / 长字段在 VSCode 文本视图里挤成一团 |
| 纯 JSON / YAML | 注释/对齐/diff 友好度都不如 xlsx；策划工具链支持差 |
| protobuf + .pbin | 引入 protoc 工具链，Godot 没有原生支持；工作室不需要这个复杂度 |
| 直接放 .tres 让策划在 Godot 编辑器里改 | 嵌套字段 OK，但批量改、多 sheet 表达不便；策划不一定开 Godot |
| LUA 表 | Godot 没 LUA，引入 LUA 解析器是增量负担 |
| 三行表头制（CSV 注释 r1/r2 + r3 header） | 网格视图工具把注释行当数据行干扰；废弃 |

---

## 10. 演进路线

| 版本 | 增量内容 | 触发条件 |
|---|---|---|
| **v1.0**（当前） | 单语言 / 单 dynamic resolver / hash 增量 | 已落地 |
| v1.1 | 多语言列（content_en / content_jp） | M5 海外考虑 |
| v1.2 | 复合主键（多列联合） | 出现需要的表 |
| v1.3 | 跨表批量约束（CHECK 表达式） | 数值平衡需要 |
| v1.4 | xlsx 内嵌 schema 反查（A1 单元格 convert 表头） | 表数 > 30 时 |
| v2.0 | 二进制 baked（.res，体积优化） | 总产物 > 5MB |

升级时**保持向后兼容**：旧 schema.toml 不动可继续用。

---

## 附录 A · 工具链清单

| 工具 | 路径 | 作用 |
|---|---|---|
| `excel_convert.py` | `tools/excel_convert.py` | 主导表脚本 |
| `excel_convert_watch.py` | `tools/excel_convert_watch.py` | 开发期 watcher |
| `lib/toml_schema.py` | `tools/lib/` | schema 解析 |
| `lib/xlsx_reader.py` | `tools/lib/` | xlsx 读取（openpyxl） |
| `lib/validator.py` | `tools/lib/` | 类型转换 + 校验 |
| `lib/writers.py` | `tools/lib/` | tres / json / manifest 写入 |
| `lib/errors.py` | `tools/lib/` | 错误类型 + 行号定位 |
| `data_registry.gd` | `game/scripts/data/` | 运行时入口 |

## 附录 B · 依赖

```
Python ≥ 3.11（自带 tomllib）
openpyxl ≥ 3.1
watchdog ≥ 3.0  （可选，watcher 用，没装会降级轮询）
```

`pip install openpyxl watchdog`
