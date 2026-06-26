# Y_音频事件配置表-英雄.xlsx 知识卡片

## 基本信息

| 项目 | 值 |
|------|-----|
| 文件路径 | `xls/Share/Y_音频事件配置表-英雄.xlsx` |
| 主 Sheet | 英雄音频事件配置表 |
| 列数 | 56（id + 中文名 + 53 项音频事件名 + 1 个备份 sheet） |
| convert | `ResAudioClient.proto, table_AudioRoleEventInfo, AudioHeroEventInfo.pbin` |
| Row 1 Col2 标记 | `LIST_FIEXED_LENGTH` |
| 仅客户端导表 | ✅ |

## 表头结构

| Row | 含义 |
|-----|------|
| Row 1 | convert 指令（仅 Col1） |
| Row 2 | 中文字段名 |
| Row 3 | proto path（id + names[1] ~ names[55]，列宽固定 55 项音频事件） |
| Row 4 起 | 数据 |

## 字段总览

| Col | row3 path | 含义 | 备注 |
|-----|-----------|------|------|
| 1 | id | 武将 ID | ✅ 主键，与英雄表 Col1 id 直接对应 |
| 2 | （无 path）武将名称 | 中文名（辅助列） | |
| 3 | names[1] | 武将英文名 | 与 Y_英雄表 Col8 sortName 同源 |
| 4-56 | names[2] ~ names[55] | 53 项音频事件名 | 由音频同学维护 |

## 跨表英文名一致性约束

> 新英雄的英文名必须**所有需要它的字段都填同一个值**：
> - Y_英雄表 Col8 `sortName` = 英文名
> - Y_音频表 Col3 `names[1]` = 英文名

## AI 配新英雄时的填法

| Col | 字段 | 配法 |
|-----|------|------|
| 1 | id | 英雄 id |
| 2 | 武将名称 | 中文名 |
| 3 | names[1] | 英文名（策划提供） |
| 4-56 | 音频事件 | **全部留空**，由音频同学补 |

> ⚠️ **AI 不要尝试推命名规则**——观察现有英雄，Col3 风格混乱（如 `Jeanne`/`NobunagaOda`/`HuaMulan` vs `WuZeTian`/`HYY`/`LSC`/`ZY`/`QQ` 缩写），且最近几个英雄连 Col3 都没填。**英文名必须由策划主动提供**，AI 不可猜测拼音/缩写。

## 写入规则

- 追加到末尾（最后一条数据行之后）
- 严禁修改已有行
- 必须使用 win32com 操作

## 注意事项

- 仅客户端导出（`AudioHeroEventInfo.pbin`），不导服务器
- 同时注意附带的 BNK 对应表 `Y_音频事件BNK对应表.xlsx`（导表时一同处理）

## 关联表

| 关联表 | 关联方式 | 说明 |
|--------|---------|------|
| `Y_英雄配置表.xlsx` 英雄 | 同 id | 英雄主表 |

## 项目专用决策（独立段）

> 以下决策与具体项目相关，详见对应项目的 SOP skill：
> - **SLGX/SFK** 项目：详见 `hero-config` skill
>   - 新英雄登记时 names[2-55] 的填空策略（SFK 完全不关注，由音频同学补）
