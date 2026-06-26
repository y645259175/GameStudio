# D_道具配置.xlsx 知识卡片

## 基本信息

| 项目 | 值 |
|------|-----|
| 文件路径 | `xls/Main/D_道具配置.xlsx` |
| 主 Sheet | 道具配置表 |
| convert 声明 | `convert(ResItem.proto, table_ItemConfData, ItemConfData.pbin)` |
| 对应文本表 | `xls/Text/W_文本表_Excel_道具.xlsx` |

## 表头结构（关键列）

| 列 | 英文字段名 | 中文名 | 说明 |
|----|-----------|--------|------|
| Col 1 | id | 道具ID | 主键 |
| Col 2 | commodityID | 商城商品ID | |
| Col 3 | （无） | 策划 | 填写策划名/来源标记 |
| Col 4 | （无） | 备注 | 道具中文名备注 |
| Col 5 | debugDesc | 简略描述 | **TID 列**：道具名称 TID |
| Col 6 | （无） | 简略描述中文 | Col 5 对应的中文 |
| Col 8 | useNow | 自动使用 | |
| Col 9 | OwnedNumShow | 显示拥有数量 | 默认填 1 |
| Col 12 | display | 界面类型 | |
| Col 13 | jumpID | 跳转ID | |
| Col 14 | type | 道具类型 | 如 IT_Common、IT_RewardPackage 等。详见下方「type 决定字段语义对照表」 |
| Col 15 | subType | 道具子类型 | 含义由 type 决定，多数 type 留空 |
| Col 16 | contentType | 内容字段类型 | 描述 content 字段的语义类型，常见值：`纯数字` / `时间秒` / `比例` |
| Col 17 | strParams[;] | 客户端额外参数 | 分号分隔（[;] 表示分隔符） |
| Col 18 | extraParam1 | 程序额外参数 | |
| Col 19 | content | 内容 | **关键字段**：含义由 type 决定（数量 / 比例 / 时长 / 关联 id 等） |
| Col 26 | compensate.coinNum | 补偿帝国币 | 装扮类道具的重复获得补偿 |
| Col 27 | buffList.buffId | 关联 BUFF id | type 走 BUFF 路线时使用 |
| Col 28 | buffList.buffValue[;]{} | BUFF 值 | 分号分隔的键值对结构 |
| Col 33 | typeTxtId | 类型文本 | **TID 列**：通常复用名称 TID |
| Col 34 | （无） | 类型文本中文 | Col 33 对应的中文 |
| Col 37 | detailTxtId | 详情文本 | **TID 列**：通常复用名称 TID |
| Col 38 | （无） | 详情文本中文 | Col 37 对应的中文 |
| Col 39 | descTxtId | 描述文本 | **TID 列**：道具描述 TID |
| Col 40 | （无） | 描述文本中文 | Col 39 对应的中文 |
| Col 41 | displayTxtId | 属性值文本 | **TID 列**：按需填写 |
| Col 42 | （无） | 属性值文本中文 | Col 41 对应的中文 |
| Col 52 | quality | 品级 | **直接填中文字符**：`白` / `绿` / `蓝` / `紫` / `橙` / `红` / `金`（现网 4628 行 quality 取值实证，不是英文枚举也不是数字） |
| Col 54 | icon | icon | **一般与 id 相同** |
| Col 59 | pageNum | 页签 | **默认填 4**，除非有特殊要求，不填不进入背包 |

## TID 列汇总（共 5 列）

| 列 | 字段 | TID 命名规则 | 文本内容 |
|----|------|-------------|---------|
| Col 5 | debugDesc | `TID_ItemConfData_{id}_debugDesc_CN_Main` | 道具名称 |
| Col 33 | typeTxtId | 同 debugDesc TID（名称复用） | 道具名称 |
| Col 37 | detailTxtId | 同 debugDesc TID（名称复用） | 道具名称 |
| Col 39 | descTxtId | `TID_ItemConfData_{id}_descTxtId_CN_Main` | 道具描述 |
| Col 41 | displayTxtId | `TID_ItemConfData_{id}_displayTxtId_CN_Main` | 属性值（按需） |

> Col 5、33、37 通常使用同一个 TID（名称复用），Col 39 使用独立的描述 TID。

## IT_Common 类型必填字段清单

新增一个 IT_Common 道具时，以下字段必须填写：

| 列 | 字段 | 填写规则 |
|----|------|---------|
| Col 1 | id | 道具 ID |
| Col 3 | 策划 | 默认填 `AI填表` |
| Col 4 | 备注 | 道具中文名 |
| Col 5 + Col 6 | debugDesc | 名称 TID + 中文 |
| Col 9 | OwnedNumShow | 1 |
| Col 14 | type | 默认`IT_Common` |
| Col 33 + Col 34 | typeTxtId | 同名称 TID + 中文 |
| Col 37 + Col 38 | detailTxtId | 同名称 TID + 中文 |
| Col 39 + Col 40 | descTxtId | 描述 TID + 描述文本 |
| Col 54 | icon | = id |
| Col 59 | pageNum | 默认为4 |

## type 决定字段语义对照表

`type` 字段决定 `subType`、`content`、`compensate.coinNum`、`buffList.buffId` 等的含义。**新增道具前必须先确认目标 type 对应的字段语义**，否则字段填错代码读不到、或者读到非预期值。

| type | subType 含义 | content 含义 | 备注 |
|------|------------|-------------|------|
| `IT_Common` | 留空 | 留空 | 通用道具，无特殊处理逻辑 |
| `IT_HeroTowerGrid` | 留空 | 地格 id | 使用后解锁对应地格 |
| `IT_OldCreedMagic` | magicId | level | 旧教魔法解锁 |
| `IT_MarchSpeedUp` | **留空** | **剩余行军时间减少比例（0~1，如 0.25=减 25%）** | 行军加速。客户端用 content×100 拼描述 `剩余行军时间减少{0}%` |
| `IT_ChooseRewardBox` | **关联奖励 id**（指向 J_奖励配置） | （依赖宝箱定义） | 自选宝箱。⚠️ 会触发奖励表交叉校验，subType 指向的奖励 id 必须在 J_奖励配置.xlsx 中存在并合法 |
| `IT_VipPoint` | 留空 | 增加的贵族经验值 | 服务器仅用 content 字段 |
| `IT_LordStamina` | 留空 | 君主体力数量 | |
| `IT_DressUp*`（皮肤系） | 留空 | 装扮有效时间秒（≤0 表示永久） | 需配合 `compensate.coinNum`（已有装扮的补偿帝国币） |

> 💡 **数据来源**：本表由 `ResKeywords.proto` 中各枚举的注释 + `D_道具配置.xlsx` 内 `#道具类型枚举说明` sheet 共同维护。新增 type 时两处都要写。

## `#道具类型枚举说明` Sheet 维护

D_道具配置.xlsx 内有一张 `#道具类型枚举说明` sheet（**`#` 开头不导出 pbin**，纯策划/AI 文档）。每新增一种 type，必须在此 sheet 末尾追加一行规则说明。

**表头 7 列**：

| Col | 字段 | 说明 |
|----|------|------|
| 1 | 道具类型 | type 枚举值，如 `IT_MarchSpeedUp` |
| 2 | 子类型描述 | subType 含义描述（留空表示不使用） |
| 3 | 数据字段类型 | content 字段类型，常见 `纯数字` / `时间秒` / `比例` |
| 4 | 内容 | content 字段含义说明 |
| 5 | 程序道具检测逻辑 | 程序处理该类型的核心逻辑 |
| 6 | 高级自带按钮1 | 客户端自动按钮跳转（按需） |
| 7 | 高级自带按钮2 | 同上 |

**表头说明（Row 2）原文**：
> 1. 如果道具可以使用，则可以正常使用和消耗
> 2. 如果配置了 BUFF 则使用道具会获得对应 BUFF，此时 content 为持续时间
> 3. 如果道具配置无法使用或者背包隐藏，则无法直接使用，可能用于活动判断进度等

## 对应文本表

文本表路径：`xls/Text/W_文本表_Excel_道具.xlsx`

每个道具需要新增 **2 条** key（zh_CN + zh_GL）：
- `TID_ItemConfData_{id}_debugDesc_CN_Main` → 道具名称
- `TID_ItemConfData_{id}_descTxtId_CN_Main` → 道具描述

## 注意事项

- **必须使用 win32com 操作**，禁止用 openpyxl 保存（会导致大量格式变动）
- icon 字段必须与 id 一致
- pageNum 默认为 4，除非用户明确要求其他值
- 该表同时导出客户端和服务器的 pbin

## id 段冲突排查（新增道具前必做）

道具 id 段**不是按 type 严格分段**的，多个系统都会从同一 id 段抢号；4628 行现网数据靠"最大 id+1"远不足以避免冲突。

**新增道具前的 id 检查清单**：

1. 拿到目标 id（用户指定 / 策划文档 / 自己规划）后，**先用 win32com 或 openpyxl 全表扫一遍 id 列查重**，发现冲突立即向用户报告
2. 用户给的 id 段如 `7243/7244` 也不能盲信——本次实战：7243 已被「帝国之星 IT_RoadOfHonorStar」占用（Row 4718），用户手动让顺延为 7244/7245
3. id 重复会导致 proto 解析时后写入的覆盖前者（或导出报错），属高风险错误，必须在写入前阻断

**最大 id 仅作为参考**：现网最大 id ~50,500,000+（含巨量保留段），但中段 1000~50000 范围被各种系统瓜分，**只能扫表查重**才靠谱。

## 关联表

| 关联表 | 关联方式 | 说明 |
|--------|---------|------|
| `W_文本表_Excel_道具.xlsx` | TID key 引用 | 道具名称和描述的多语言文本 |
| `H_获取途径.xlsx` | Col 70 `ShowGetWayId` / Col 71 `getPathId` | 道具的获取途径跳转配置 |
