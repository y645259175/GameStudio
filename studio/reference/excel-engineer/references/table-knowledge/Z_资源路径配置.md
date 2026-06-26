# Z_资源路径配置.xlsx 知识卡片

## 基本信息

| 项目 | 值 |
|------|-----|
| 文件路径 | `xls/Main/Z_资源路径配置.xlsx` |
| 总 Sheet 数 | 25 |
| 英雄相关 Sheet | 2 个：英雄模型配置表（A 类）、野外角色模型配置表（B 类） |
| 关联 proto | `ResResourcePathCfg.proto` |

## 概念分层：A 类 vs B 类

| 类型 | 含义 | Sheet | 关联方式 |
|------|------|-------|---------|
| **A 类** | 城内英雄大模型 | 英雄模型配置表 | **直接关联**：英雄 ID 即此 Sheet 的主键 id |
| **B 类** | 野外行军模型 | 野外角色模型配置表 | **间接关联**：4 张表 3 次跳转（详见下方"B 类多表关联链路"） |

## A 类「英雄模型配置表」

### 基本信息
- convert：`ResResourcePathCfg.proto, table_HeroModelPathConf, HeroModelPathConf.pbin`
- 列数：5（实际只用 3 列）
- 仅客户端导表

### 关键字段表

| Col | row3 path | 含义 | 备注 |
|-----|-----------|------|------|
| 1 | id | 英雄 ID（**与英雄表 Col1 id 直接对应**） | ✅ 主键 |
| 2 | path | A 类 prefab 完整资源路径（**全小写**） | 命名规则见下 |
| 3 | （无 path）备注 | 英雄中文名 | 可选 |

### A 类路径命名规则（项目通用）

```
assets/bundleresources/characters/a/hero/p_ah_<英雄英文名>.prefab
```

- 前缀：`p_ah_`（A 类 Hero）
- 英雄英文名：全小写
- 无 `_p_anim` 后缀

## B 类「野外角色模型配置表」

### 基本信息
- convert：`ResResourcePathCfg.proto, table_OutsideRoleConf, OutsideRoleConf.pbin`
- 列数：10
- 仅客户端导表

### 关键字段表

| Col | row3 path | 含义 | 备注 |
|-----|-----------|------|------|
| 1 | id | marchModel ID（**不是英雄 id**） | ✅ 主键，需走链路关联 |
| 2 | path | B 类 prefab 完整资源路径（**全小写**） | 命名规则见下 |
| 3 | path2d | 2D 路径 | 通常空 |
| 4 | pathPC | PC 端路径 | 通常空 |
| 5 | （无 path）备注（不导表） | 英雄/角色中文名 | 可选 |

### B 类路径命名规则（项目通用）

```
assets/bundleresources/characters/b/hero/p_bh_<英雄英文名>_p_anim.prefab
```

- 前缀：`p_bh_`（B 类 Hero）
- 英雄英文名：全小写
- 有 `_p_anim` 后缀（带动画的行军模型）

## B 类多表关联链路（4 张表、3 次跳转）

```
Y_英雄配置表 (Y_英雄配置表.xlsx → 英雄 Sheet)
    │  Col1: id（英雄 ID）
    │  Col59: soldierId（出征英雄对应的战斗士兵 ID）
    ▼
Z_战斗配置表 (Z_战斗配置表.xlsx → 战斗士兵 Sheet)
    │  Col1: id（= 上一步的 soldierId）
    │  Col59: marchModel.default（野外行军模型 ID）
    ▼
Z_资源路径配置 (Z_资源路径配置.xlsx → 野外角色模型配置表 Sheet)
    │  Col1: id（= 上一步的 marchModel.default 值）
    │  Col2: path（B 类 prefab 路径 ← 写入目标）
    ▼
最终：path 字段就是 B 类资源路径
```

### 易混淆字段提醒

| Sheet | 易混淆字段 | 正确字段 |
|-------|-----------|---------|
| Y_英雄表 | Col11 buffSoldierTypes（兵种名称） | Col59 soldierId（实际关联） |
| Z_战斗士兵 | Col60 marchModel.id[1]（法兰克备选模型） | Col59 marchModel.default（默认） |

## 路径规范

- **所有路径必须全小写**（Unity 资源路径大小写敏感，项目统一使用小写避免平台差异）
- 写入前务必执行 `.lower()` 转换

## 写入工作流（标准）

1. **A 类**：直接按英雄 id 定位 row → 修改 Col2 path + Col3 备注 → 保存
2. **B 类**：
   - 先确认或追加 marchModel id 在野外角色模型配置表中的行
   - 写入 Col2 path
   - **同步修改** Z_战斗配置表 战斗士兵 sheet 中对应 soldierId 行的 Col59 marchModel.default

## 注意事项

- 必须使用 win32com 操作，禁止用 openpyxl 保存
- 仅导客户端 pbin（`HeroModelPathConf.pbin` / `OutsideRoleConf.pbin`），不导服务器
- A 类与 B 类是两个完全独立的 Sheet，分开维护
- B 类 marchModel id 段如果选择追加新行而非覆盖，要先校验 id 段空闲（避免破坏其他场景借用）

## 关联表

| 关联表 | 关联方式 | 说明 |
|--------|---------|------|
| `Y_英雄配置表.xlsx` 英雄 | Col48 model（A 类）+ Col59 soldierId（B 类入口） | 英雄主表 |
| `Z_战斗配置表.xlsx` 战斗士兵 | Col59 marchModel.default | B 类链路中间环节 |

## 项目专用决策（独立段）

> 以下决策与具体项目相关，详见对应项目的 SOP skill：
> - **SLGX/SFK** 项目：详见 `hero-config` skill
>   - A 类 id 段约定（与 SFK 英雄 id 段对应）
>   - B 类 marchModel id 段约定（项目专用公式）
>   - 旧 marchModel id 段废弃记录（避免重蹈覆辙）
