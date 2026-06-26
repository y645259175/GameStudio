# Z_战斗配置表.xlsx 知识卡片

## 基本信息

| 项目 | 值 |
|------|-----|
| 文件路径 | `xls/Main/Z_战斗配置表.xlsx` |
| 总 Sheet 数 | 20 |
| 主 Sheet（含英雄相关） | 战斗士兵 |
| 关联 proto | `ResBattleCore.proto` |

## 战斗士兵 Sheet

### 基本信息
- convert：`ResBattleCore.proto, table_SoldierConf, SoldierConf.pbin`
- 列数：69
- Sheet 内部分段：普通士兵/野怪/Boss、真英雄段、其它 type='英雄' 行（迷雾关卡 boss / 流寇英雄 / 集结 / 卫队等）

### 真英雄段识别规则
- type 字段 = `英雄`
- mapType 字段 = `战场`
- id 范围（参考 AOEM）：1003001001 ~ 1003001216

### 关键字段表（69 列，仅列示英雄相关）

| Col | row3 path | 含义 | 备注 |
|-----|-----------|------|------|
| 1 | id | 战斗士兵 ID | ✅ 主键 |
| 2 | type | 兵种 | 取值 剑士/弓兵/枪兵/骑兵/野怪类/英雄 |
| 3 | civilType | 文明 | |
| 4 | level | 等级 | 通常 1.0 |
| 5 | （无 path）索引标签 | 辅助列 | 如 普通 |
| 6 | genre | 兵种类型 | 如 普通 |
| 7 | monstertype | 是否野怪 | 如 普通 |
| 8 | canBeHitedFly | 是否需要击飞表现 | |
| 9 | specialSoldierType | 特殊兵种类型 | |
| 10 | detailName | 名称 | 中文名 |
| 11 | mapType | 所属地图类型 | 取值 战场 / 大地图 |
| 12 | isopen | 是否开放 | |
| 13 | isTraining | 能否训练 | |
| 14 | modelScaleMulti | 模型缩放乘数 | |
| 15 | formationConfigId | 士兵队形参数 | |
| 16-19 | attackValue / fixAttackPower / defenceValue / hpValue | 服务端属性 4 字段 | 英雄通常填 0（数值由 Y_英雄表管） |
| 20-21 | curePower / recoverPower | 治疗力 / 复原力 | |
| 22-24 | attack / defence / hp | 客户端属性 3 字段 | 英雄通常填 0 |
| 25 | movespeedinmap | 大地图移动速度 | |
| 26 | collectload | 采集负重 | |
| 27 | buildSpeed | 建造联盟建筑速度 | |
| 28 | fightvalue | 战斗力 | 通常 1.0 |
| 29 | clientmovespeed | 攻击速度（客户端） | 通常 1.25 |
| 30-44 | desc/cost*/treatcost*/needbuilding*/promoterate | 训练/治疗/晋升等 13 字段 | 普通士兵填，英雄全空 |
| 45-46 | model / skill | 模型 / 技能 | |
| 47-48 | attackadd / defendadd | 全兵种加成 | |
| 49-50 | arealength / areawidth | 长度 / 宽度 | |
| 51 | name | 名称 TID | |
| 52 | soldierskills | 士兵技能 | |
| 53-58 | preTechId/preTechLevel/3 个 moveSpeed/createHorseModel | 前置科技 + 移速 + 坐骑 | |
| **59** | **`marchModel.default`** | 不区分文明的野外行军模型 ID | ⚠️ **关键字段**：关联 `Z_资源路径配置.xlsx` 野外角色模型配置表 的 id |
| 60-63 | marchModel.id[1] / id[2] / id[3] / id[4] | 法兰克 / 中国 / 拜占庭 / 罗马 各文明独立模型 | |
| 64-65 | skinModel[1] / skinModel[2] | 异形坐骑英雄皮肤 | |
| 66-68 | MilitaryExploitDeadBase / InjureBase / HurtBase | 战功击杀/重伤/轻伤基础值 | |
| 69 | needAge | 需求时代 | |

### 跨表依赖（B 类资源路径关联链路的中间环节）

```
Y_英雄配置表 主表 Col59 soldierId
    → Z_战斗配置表 战斗士兵 Col1 id
        → Z_战斗配置表 战斗士兵 Col59 marchModel.default
            → Z_资源路径配置 野外角色模型配置表 Col1 id
                → Col2 path（B 类资源路径）
```

### 写入约定
- 训练士兵 sheet 与战斗士兵 sheet 是**两个独立的 sheet**，新增英雄时只动战斗士兵 sheet
- 数据起始行为 row4

## 注意事项

- 必须使用 win32com 操作，禁止用 openpyxl 保存
- 该表导出客户端 + 服务器双 pbin
- Col59 marchModel.default 易混淆：Col60 是 `marchModel.id[1]`（法兰克备选模型），不是 default

## 关联表

| 关联表 | 关联方式 | 说明 |
|--------|---------|------|
| `Y_英雄配置表.xlsx` 英雄 | Col59 soldierId | 英雄关联战斗数据 |
| `Z_资源路径配置.xlsx` 野外角色模型配置表 | Col59 marchModel.default → 资源表 Col1 id | B 类资源路径间接关联 |

## 项目专用决策（独立段）

> 以下决策与具体项目相关，详见对应项目的 SOP skill：
> - **SLGX/SFK** 项目：详见 `hero-config` skill
>   - 新英雄 soldierId 公式（基于 SFK 英雄 id 段）
>   - marchModel.default 使用的 id 段约定
>   - 新英雄填写所采用的模板（如赵云模板的固定值）
