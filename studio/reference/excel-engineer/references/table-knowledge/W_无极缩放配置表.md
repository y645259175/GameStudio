# W_无极缩放配置表.xlsx 知识卡片

> ⚠️ **文件名前缀 `W_` 并不代表文本表**！此表位于 `xls/Main/` 而非 `xls/Text/`，属于 **🔢 数值类配置表**，修改后**必须导表**（`export_one_for_ai.py`）、**必须提交 pbin/txt**。
> SKILL.md「文本类改动」判定标准是**目录**，不是文件名前缀。

## 基本信息

| 项目 | 值 |
|------|-----|
| 文件路径 | `xls/Main/W_无极缩放配置表.xlsx` |
| 关联 proto | `ResInfiniteZoom.proto` |
| 总 Sheet 数 | 10 |
| 客户端/服务端 | **大部分 Sheet 双端导表**（部分 Sheet 单端，详见各 Sheet 说明） |
| 导出产物（客户端+服务端共计） | SceneInfiniteLayerConf / InfiniteLayerData / InfiniteLayerData2D / InfiniteEntityShowData（仅客户端）/ InfiniteZoomEntitySyncConf（仅服务端）/ InfiniteEntityResource / InfiniteEntityData / InfiniteZoomProvinceName（仅客户端）/ ViewMiscConfData（仅服务端） |

## Sheet 一览

| Sheet 名 | 用途 | 导出目标 | 端别 |
|---|---|---|---|
| 层级配置表new | 无极缩放分层（当前使用） | `SceneInfiniteLayerConf.pbin` | 双端 |
| 层级配置表(废弃，用new) | 废弃，保留原样 | `InfiniteLayerData.pbin` | 双端 |
| 层级配置表2D | 2D 场景分层 | `InfiniteLayerData2D.pbin` | 双端 |
| Entity显示样式 | 显示样式定义 | `InfiniteEntityShowData.pbin` | **仅客户端** |
| Entity数据裁减 | 服务端下发字段裁剪 | `InfiniteZoomEntitySyncConf.pbin` | **仅服务端** |
| Entity显示资源 | 样式引用的资源（prefab/icon） | `InfiniteEntityResource.pbin` | 双端 |
| **Entity显示配置表** | **Entity 类型 → 各缩放层级的显示样式 + 行军线开关** | `InfiniteEntityData.pbin` | 双端 |
| 州名表现配置 | 州名视图表现 | `InfiniteZoomProvinceName.pbin` | **仅客户端** |
| #TID_base_up | 以 `#` 开头，**导表跳过** | — | — |
| 视野杂项配置 | 视野相关杂项 | `ViewMiscConfData.pbin` | **仅服务端** |

## 「Entity显示配置表」Sheet 详解

这是本表最常改动的 Sheet。

### 基本信息

- convert：`ResInfiniteZoom.proto, table_InfiniteEntity, InfiniteEntityData.pbin`
- proto message：`InfiniteEntity`
- **主键**：`(entityType, subType, level)` **三元组**（`option (resKey) = "entityType,subType,level"`）
- 行数参考：截至 r1287515 为 153 行

### 关键字段表

| Col | 中文名 | row3 path | proto 类型 | 说明 |
|---|---|---|---|---|
| 1 | Entity类型 | entityType | `WorldEntityType`（枚举） | **⚠️ 表里填的是中文名**，导表工具按中文映射到枚举数值（见下） |
| 2 | 备注 | — | — | 非导出列，人类注释 |
| 3 | 等级 | level | int32 | 主键之一 |
| 4 | 子类型 | subType | int32 | 主键之一 |
| 5 | **是否显示行军线** | **showMoveLine** | **bool** | **空 = 不显示 / 代码硬编码兜底；TRUE = 显示**。见下方「行军线显示规则」 |
| 6 | 战场层 | viewData[1]{showType-showResource-dataSyncType} | `InfiniteEntityViewData` | 格式 `showType-showResource-dataSyncType` |
| 7 | 宏观战场层-2 | viewData[2]{...} | 同上 | |
| 8 | 沙盘层-3 | viewData[3]{...} | 同上 | |
| 9 | 城市沙盘层-4 | viewData[4]{...} | 同上 | |
| 10 | 州沙盘层-5 | viewData[5]{...} | 同上 | |
| 11 | 国家层-6 | viewData[6]{...} | 同上 | |

### entityType 中英映射（**关键踩坑点**）

**A 列填的是中文名**（如 `部队`/`城镇`/`名城主城`），但图纸/代码/Lua 里用的都是英文枚举（如 `WET_Army`/`WET_BigWorldCity`/`WET_MingChengMainBuilding`）。**改表前必须先做中英映射**，否则定位不到行。

**映射表权威来源**：

```
AOE3D/Assets/Scripts/.Lua/Cfg/Gen/Completion/ResKeywords_proto_enum.lua
```

格式示例：

```lua
CfgNs.WorldEntityType.WET_Army = 4  --[(name) = "部队"]
CfgNs.WorldEntityType.WET_BigWorldCity = 11  --[(name) = "城镇"]
```

其中 `(name) = "部队"` 就是 Excel A 列对应的中文。**注释里的 name 才是映射依据，不是字段枚举名本身的中文翻译。**

常见易错：
- `WET_NpcArmyMonster` ≠ "NPC 部队怪"，正确中文是 **"皇城战NPC野怪"**
- `WET_Ladder` 中文是 **"云梯"**，不是字面翻译
- `WET_CampGroup` 中文是 **"卫队"**，不是 "营地组"

**工具方法**：改表前用下列片段一把生成全量映射（Python/grep）：

```powershell
Select-String -Path "AOE3D/Assets/Scripts/.Lua/Cfg/Gen/Completion/ResKeywords_proto_enum.lua" `
  -Pattern 'WorldEntityType\.(WET_\w+)\s*=\s*(\d+)\s*--\[\(name\)\s*=\s*"([^"]+)"\]'
```

### 行军线显示规则（showMoveLine 字段）

- **proto 类型**：`bool`
- **当前数据态**：截至 r1287515，153 行里 9 行为 `TRUE`，其余全为空
- **代码侧兜底**：客户端 `HasArmyLineEntityType` 表（Lua）对每个 entityType **硬编码了白名单**，显式列出哪些类型显示行军线（true）、哪些不显示（false）
- **空 vs FALSE**：当前表里空值是默认态，代码侧会走硬编码兜底；TRUE 则让此类 entity 显示行军线
- **新增类型的处理**：图片里 Lua 白名单里的某些 `WET_*` 类型在 Excel 里**并没有对应行**（主键三元组压根没配）。这些类型当前完全走代码硬编码。要用配置表接管时必须补 `viewData[1..6]` 字段，**不能只填 showMoveLine**

### 主键三元组注意事项

- `(entityType, subType, level)` 任一组合唯一
- 同一 `entityType` 可以有多行（不同 subType/level），改单一字段时**必须把所有相关行都改**（如 `名城主城` 有十几行）
- 表里 `level` / `subType` 为空时，按枚举默认 0 处理

## 注意事项

- **文件名前缀 `W_` 并不代表文本表**（见开头红字）
- 修改必须使用 win32com 保存，禁用 openpyxl 保存
- A 列 entityType 写中文，不是 `WET_*` 枚举，也不是整数
- 主键是三元组，同一 entityType 可多行
- 大部分 Sheet 双端导出，提交时需同时包含 `client/` 和 `server/` 下的 pbin/txt
- 被 `#` 前缀的 Sheet（如 `#TID_base_up`）自动跳过，不参与导表

## 关联表 / 关联代码

| 关联目标 | 关联方式 | 说明 |
|---|---|---|
| `ResKeywords_proto_enum.lua` | A 列中文 ↔ WorldEntityType 枚举 | **改表前必读**的映射表 |
| 客户端 `HasArmyLineEntityType` Lua 表 | 与 showMoveLine 字段互补 | Excel 空值时的硬编码兜底白名单 |
| `ResInfiniteZoom.proto` | 字段定义 | 各 Sheet 的 proto message 入口 |

## 历史改动记录

| 日期 | revision | 改动 | bug/story |
|---|---|---|---|
| 2026-05-07 | r1287515 | Entity显示配置表 8 行 showMoveLine 由空 → TRUE（集结部队/联盟投石车/侦察队伍/护送玩法野怪/战鼓车/云梯/冲车/卫队）| `--bug=157661654` |
