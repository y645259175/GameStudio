# H_获取途径.xlsx 知识卡片

## 基本信息

| 项目 | 值 |
|------|-----|
| 文件路径 | `xls/Main/H_获取途径.xlsx` |
| 对应文本表 | `xls/Text/W_文本表_Excel_跳转&指引.xlsx` |

## Sheet 列表

| Sheet | convert 声明 | 说明 |
|-------|-------------|------|
| 获取途径组 | `convert(ResShowGet.proto, table_ShowGetGroupData, ShowGetGroupData.pbin)` | 获取途径分组 |
| 获取途径配置 | `convert(ResShowGet.proto, table_ShowGetData, ShowGetData.pbin)` | 单条获取途径配置 |
| 获取方式 | `convert(ResShowGet.proto, table_ItemFetchPortal, ItemFetchPortal.pbin)` | |
| 获取类别 | `convert(ResShowGet.proto, table_ItemFetchingGuide, ItemFetchingGuide.pbin)` | |
| 道具获取途径 | `convert(ResShowGet.proto, table_ItemGetGroupData, ItemGetGroupData.pbin)` | |
| 资源获取途径 | `convert(ResShowGet.proto, table_ResourceGetGroupData, ResourceGetGroupData.pbin)` | |
| 服务器差分获取途径组 | `convert(ResShowGet.proto, table_ShowGetGroupServerDiffData, ...)` | |
| 货币获取途径 | `convert(ResShowGet.proto, table_CoinGetGroupData, CoinGetGroupData.pbin)` | |

## 获取途径配置表（常用 Sheet）关键列

| 列 | 英文字段名 | 中文名 | 说明 |
|----|-----------|--------|------|
| Col 1 | id | id | 主键 |
| Col 2 | title | 描述标题 | **TID 列** |
| Col 3 | （无） | 描述标题中文 | Col 2 对应的中文 |
| Col 4 | desc | 描述文本 | **TID 列** |
| Col 5 | （无） | 描述文本中文 | Col 4 对应的中文 |
| Col 6 | JumpToId | 界面跳转id | 可为空 |
| Col 7 | （无） | 跳转关联文本 | |
| Col 8 | （无） | 跳转ID | |
| Col 9 | atlasName | icon图集名 | 默认 `icon_task` |
| Col 10 | spriteName | icon名称 | 默认 `icon_task_p3_05` |
| Col 16 | （无） | 备注 | 策划用 |

## TID 列汇总（获取途径配置表）

| 列 | 字段 | TID 命名规则 | 文本内容 |
|----|------|-------------|---------|
| Col 2 | title | `TID_ShowGetData_{id}_title_CN_Main` | 条目标题 |
| Col 4 | desc | `TID_ShowGetData_{id}_desc_CN_Main` | 条目描述 |

## 对应文本表

文本表路径：`xls/Text/W_文本表_Excel_跳转&指引.xlsx`

每条获取途径需要新增 **2 条** key（zh_CN + zh_GL）：
- `TID_ShowGetData_{id}_title_CN_Main` → 标题
- `TID_ShowGetData_{id}_desc_CN_Main` → 描述

## 注意事项

- 该表只导出客户端 pbin，不导出服务器（proto 未标记 `@useSvr`）
- `xls/Main/` 是 SVN external 目录，提交时需要与 `client/data/` 分开提交
- icon 相关字段（Col 9、Col 10）有默认值：`icon_task` / `icon_task_p3_05`

## 关联表

| 关联表 | 关联方式 | 说明 |
|--------|---------|------|
| `W_文本表_Excel_跳转&指引.xlsx` | TID key 引用 | 获取途径标题和描述的多语言文本 |
| `D_道具配置.xlsx` | 道具表 Col 70/71 引用获取途径 id | 道具通过 `ShowGetWayId`/`getPathId` 关联到本表 |
