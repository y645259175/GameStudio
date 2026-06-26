# Y_英雄配置表.xlsx 知识卡片

## 基本信息

| 项目 | 值 |
|------|-----|
| 文件路径 | `xls/Main/Y_英雄配置表.xlsx` |
| 总 Sheet 数 | 32 |
| 配新英雄相关 Sheet | 4 个：英雄 / 新英雄开放控制表 / 海外英雄额外配置表 / 英雄进阶 |
| 对应文本表 | `xls/Text/W_文本表_Excel_英雄&技能.xlsx`（旧）+ `xls/Text/W_文本表_Excel_英雄和战斗SFK.xlsx`（新） |

## 通用 Row 约定（4 个 sheet 都遵守）

| Row | 含义 |
|-----|------|
| Row 1 | proto convert 指令（仅 Col1） |
| Row 2 | 中文字段名 |
| Row 3 | proto path（**仅有 path 的列才会被导出到 pbin**） |
| Row 4 起 | 数据 |

> **关键潜规则**：row3 为 path 的列才参与导出。row3 为空的列是辅助列（公式索引/策划备注/分组标题/验证列），不影响游戏逻辑。

## Sheet 1：「英雄」主表

### 基本信息
- convert：`ResHero.proto, table_HeroConfigData, HeroConfigData.pbin`
- 列数：104
- 真英雄段定义：id ≤ 216（128 个真英雄，5 个 id 段断号）

### 关键字段表

| Col | row3 path | 含义 | 备注 |
|-----|-----------|------|------|
| 1 | id | 英雄 ID | ✅ 主键 |
| 2 | detailName | 英雄名（中文，备注用） | |
| 4 | qualityLevel | 品级 | 取值 S/A/B/C/SS（与 Col10 quality 配对：橙→S、金→SS、紫→A 等） |
| 7 | name | **英雄名 TID**（引用文本表） | 命名参考：`TID_Hero_name_<id>`（新规） / `TID_HeroConfigData_<id>_name_CN_Main`（旧规） |
| 8 | sortName | 名称排序用（英文名） | **必须由策划提供英文名，AI 不可猜测** |
| 9 | gender | 性别 | 取值 男 / 女 |
| 10 | quality | 英雄品质 | 取值 橙 / 紫 / 金 |
| 11 | buffSoldierTypes[\|] | 兵种特性 | 取值 剑士 / 枪兵 / 弓兵 / 骑兵（多个用 \| 分隔） |
| 12 | battleStyle | 战斗风格 | 取值 勇武 / 统率 / 智谋 |
| 13 | inherentSkill | 固有技（**字段名标"废弃"**） | 老英雄仍填，新项目按需 |
| 14 | inherentSkillList[;] | 固有技列表（实际生效） | 多个用 ; 分隔 |
| 15 | generalSkill | 主将技 | |
| 18-21 | baseForce / baseDefence / baseStrategy / baseDeCity | 武力/守备/谋略/摧城 4 维基础值 | |
| 22-25 | incForcePerLv / incDefencePerLv / incStrategyPerLv / incDeCityPerLv | 4 维成长值 | |
| 26-31 | baseHpHeroTower / incHpPerLevelHeroTower / baseAtkHeroTower / incAtkPerLevelHeroTower / baseDefHeroTower / incDefPerLevelHeroTower | 塔防 6 项（HP/Atk/Def 基础+成长） | 部分项目不上线塔防 |
| 32-36 | （无 path）武力/守备/谋略/摧城/总值 | "满级属性验证"分组下 5 列 | **公式列，AI 不要碰**，策划手算 |
| 38 | isBigSceneUse | 是否大地图使用 | 真英雄统一 1.0 |
| 39 | isHero | 英雄类型 | 真英雄统一 True |
| 40 | sacredObjectId | 英雄圣物（专属信物 = 碎片道具 id） | 关联 D_道具配置 |
| 41 | sacredObjectExchange[\|]{key:value} | 通用→专属信物兑换 | 普遍样例：`123002:1` |
| 42 | expId | 经验表 ID | |
| 43 | expIncStrategy | 经验升级策略 | |
| 44 | propertylvUpStrategy | 属性升级策略 | 关联 Sheet "英雄属性升级策略" |
| 46 | voicePrefix | 语音前缀 | 老英雄字段（96% 留空） |
| 47 | comeFrom | 英雄籍贯 | 老英雄字段 |
| 48 | model | 英雄模型 ID | A 类资源路径的引用 id |
| 49 | advanceModel | 典藏英杰模型 | 老英雄字段 |
| 50-53 | heroListAtlasPath / heroListNameIcon / heroListAtlasPathS / heroListNameIconS | 半身像 4 字段（普通版+S 版） | |
| 55 | animation | Spine 动画路径 | 全表唯一值 `Hero/Hero_Joan/skeleton_SkeletonData` |
| 57-58 | HeroHeadIconAtlas / HeroHeadIcon | 英雄头像 2 字段 | |
| 59 | soldierId | 出征英雄模型（关联战斗士兵 ID） | 关联 Z_战斗配置表 战斗士兵 |
| 65/78/88 | （无 path）"横屏镜头"/"竖屏镜头"/"镜头终止" | 分组标题列 | 留空 |
| 66-77 | cameraStory / cameraStar / cameraProperty / cameraTalent / cameraGearType1-4 / cameraLotter / cameraDefault / cameraMainList / cameraFull | 横屏 12 个镜头字段 | 格式 x\|y\|z\|rx\|ry\|rz |
| 79-86 | cameraStroyPor / cameraFullPor / cameraStarPor / cameraPropertyPor / cameraTalentPor / cameraLotterPor / cameraDefaultPor / cameraMainListPor | 竖屏 8 个镜头字段 | 同上 |
| 87 | heroEyeModelWorldPosXY[\|] | 英雄眼睛坐标 | 格式 x\|y |
| 89 | cameraLotterTime | 抽奖镜头切换时长 | |
| 90 | lotteryVideoName | 招募视频路径 | 命名参考：`heroCompose_<id>_gl` |
| 91 | isActivity | 是否活动英雄 | 真英雄统一 0.0 |
| 92 | shareCdn | 分享用 CDN | |
| 93 | storyId | 赛季 | 真英雄取值 1.0/10000.0/99999.0 |
| 94 | sortIndex | 排序 | 通常用 Excel 公式 |
| 95 | defaultSkillList[:] | 默认技能（**字段名标"废弃"**） | |
| 96-97 | heroItemAtlsPthOvrsea / heroItemIconOversea | 海外合成碎片预览图 2 字段 | |
| 98-100 | talentPicAtlas / talentPicSpriteLock / talentPicSprite | 天赋入口 3 字段 | 命名带 id |
| 101 | inbornAbilityTreeId | 天赋树 ID | 关联 Sheet 19「海外英雄新天赋树」 |
| 102 | lockGetPath | 解锁前信物跳转 ID | |
| 103 | version | 版本号（不兼容修改时变更） | |
| 104 | portraitSpinePath | 英雄信息界面 Spine 路径 | |

## Sheet 2：「新英雄开放控制表」

### 基本信息
- convert：`ResHero.proto, table_NewHeroOpenControl, NewHeroOpenControl.pbin`
- 列数：22

### 关键字段表

| Col | row3 path | 含义 | 备注 |
|-----|-----------|------|------|
| 1 | id | 英雄 ID | ✅ 主键 |
| 2 | （无 path）英雄名备注 | 中文名 | |
| 3 | isOpen | 是否开放 | 1.0 = 开 / 0.0 = 关 |
| 4 | openTimeHour | 开服后多少小时开放 | 0.0 = 立即 |
| 5 | enableSvr[;]{beginZone~endZone} | 开放区服 | 例：`1~4000;5001~99999`（默认全区） |
| 6 | groupId | 属于哪个额外开放控制组 | 关联 Sheet 2「英雄额外开放控制」 |
| 7 | （无 path）开放标注 | 赛季标记 | 如 S1 / S2 |
| 8-22 | （扩展配置区） | | 通常不用 |

## Sheet 3：「海外英雄额外配置表」

### 基本信息
- convert：`ResHero.proto, table_OvrseaHeroTagsData, OvrseaHeroTags.pbin`
- 列数：8

### 关键字段表

| Col | row3 path | 含义 | 备注 |
|-----|-----------|------|------|
| 1 | id | 英雄 ID | ✅ 主键 |
| 2 | （无 path）英雄名备注 | 中文名 | |
| 3 | heroTags[\|] | **真正生效的标签字段** | 引用 Sheet 16「英雄标签词条」的 id；多个用 \| 分隔 |
| 4 | heroAttrRecom[\|]{attrType:showPercent} | 英雄推荐加点 | 取值 OHAT_Force / OHAT_Defence / OHAT_Strategy / OHAT_DeCity |
| 5 | （无 path）标签1 | 中文备注 | 对应 Col3 第 1 项 |
| 6 | （无 path）标签2 | 中文备注 | 对应 Col3 第 2 项 |
| 7 | （无 path）标签序号1 | 数字备注 | 对应 Col3 第 1 项 id |
| 8 | （无 path）标签序号2 | 数字备注 | 对应 Col3 第 2 项 id |

### Sheet 16「英雄标签词条」全表（heroTags 字段引用源）

| id | 中文名 | TID | icon |
|----|--------|-----|------|
| 1 | 暴击 | TID_OvrseaHeroTagDesc_10_showTextKey_GL_Main | icon_herobattle_01 |
| 2 | 被动 | TID_OvrseaHeroTagDesc_6_showTextKey_GL_Main | icon_herobattle_02 |
| 3 | 攻击 | TID_OvrseaHeroTagDesc_1_showTextKey_GL_Main | icon_herobattle_03 |
| 4 | 恢复 | TID_OvrseaHeroTagDesc_5_showTextKey_GL_Main | icon_herobattle_04 |
| 5 | 回怒 | TID_OvrseaHeroTagDesc_12_showTextKey_GL_Main | icon_herobattle_05 |
| 6 | 连击 | TID_OvrseaHeroTagDesc_9_showTextKey_GL_Main | icon_herobattle_06 |
| 7 | 破甲 | TID_OvrseaHeroTagDesc_13_showTextKey_GL_Main | icon_herobattle_07 |
| 8 | 护卫 | TID_OvrseaHeroTagDesc_3_showTextKey_GL_Main | icon_herobattle_08 |
| 9 | 主将 | TID_OvrseaHeroTagDesc_16_showTextKey_GL_Main | icon_herobattle_09 |
| 10 | 辅助 | TID_OvrseaHeroTagDesc_4_showTextKey_GL_Main | icon_herobattle_10 |
| 11 | 增益 | TID_OvrseaHeroTagDesc_15_showTextKey_GL_Main | icon_herobattle_11 |
| 12 | 指挥 | TID_OvrseaHeroTagDesc_8_showTextKey_GL_Main | icon_herobattle_12 |
| 13 | 主动 | TID_OvrseaHeroTagDesc_11_showTextKey_GL_Main | icon_herobattle_13 |
| 14 | 追击 | TID_OvrseaHeroTagDesc_7_showTextKey_GL_Main | icon_herobattle_14 |
| 15 | 准备 | TID_OvrseaHeroTagDesc_14_showTextKey_GL_Main | icon_herobattle_15 |
| 16 | 反击 | TID_OvrseaHeroTagDesc_2_showTextKey_GL_Main | icon_herobattle_16 |
| 17 | 采集 | Text_Hero_OvrseaHeroTagDesc_showText_1_Noun | icon_herobattle_17 |
| 18 | 主将技 | Text_Hero_OvrseaHeroTagDesc_showText_2_Noun | icon_herobattle_18 |

## Sheet 4：「英雄进阶」

### 基本信息
- convert：`ResHero.proto, table_HeroStarConfigData, HeroStarConfigData.pbin`
- 列数：27
- **行内继承结构**：每个英雄占多行，但只有第 1 行填 Col1 heroId 和 Col2 角色，后续行留空靠位置归属

### 关键字段表

| Col | row3 path | 含义 | 备注 |
|-----|-----------|------|------|
| 1 | heroId | 英雄 ID | 仅每英雄首行填 |
| 2 | （无 path）角色 | 中文名 | 仅每英雄首行填 |
| 3 | starConfig.starLv{key;value} | 新星级对应（起始;终止） | 一段星级范围 |
| 4 | starConfig.id | 星阶数（1-5） | 整星行才填 |
| 5 | starConfig.needHeroSacredObjectCnt | 升级所需碎片数 | |
| 6 | starConfig.power | 战斗力 | |
| 7 | starConfig.starLevelName | 阶等名称（TID） | |
| 8 | （无 path）阶等名称中文 | | |
| 9 | starConfig.giveAttrPoint | 赠送的属性点数 | |
| 10 | starConfig.addAttrPointType[;] | 赠送属性点类型（1武力2守备3谋略4催城） | |
| 11-12 | starConfig.iconAtlas / iconSprite | 展示的 buff icon 图集/精灵 | |
| 13 | （无 path）英雄品质 | 辅助列 | |
| 14 | （无 path）增加的属性类型 | 辅助列 | |
| 15 | starConfig.replaceGeneralSkill | 主将技替换 id | 升星替换主将技 |
| 16 | starConfig.replaceInherentSkill | 固有技替换 id（**字段名标"废弃"**） | 部分项目不再使用 |
| 17 | starConfig.replaceInherentSkillList[;] | 固有技替换 id 列表（实际生效） | |
| 18 | starConfig.defaultReplaceSkill | 优先展示的技能 ID（0 固有技 1 主将技） | |
| 19-22 | starConfig.buff.buffId / valueB / buffTarget / showInboardType | 升星 buff 4 字段 | |
| 23 | starConfig.newDesc | 新增特性 TID | |
| 24 | （无 path）备注 | | |
| 25-27 | incHpPerStarHeroTower / incAtkPerStarHeroTower / incDefPerStarHeroTower | 塔防每星级 3 字段 | |

## 关联表

| 关联表 | 关联方式 | 说明 |
|--------|---------|------|
| `Z_战斗配置表.xlsx` 战斗士兵 | 主表 Col59 soldierId → 战斗士兵 Col1 id | 战斗数据 |
| `Z_资源路径配置.xlsx` 英雄模型配置表 | 主表 Col48 model → A 类 path | 城内大模型（A 类） |
| `Z_资源路径配置.xlsx` 野外角色模型配置表 | 主表 Col59 soldierId → 战斗士兵 Col59 marchModel.default → 野外模型 path | 野外行军模型（B 类，多表关联） |
| `D_道具配置.xlsx` | 主表 Col40 sacredObjectId → 道具 id | 英雄碎片专属信物 |
| `Y_音频事件配置表-英雄.xlsx` | 同 id | 英雄音频事件 |

## 注意事项

- 必须使用 win32com 操作，禁止用 openpyxl 保存
- 主表 Col55 animation 全表唯一，照抄即可
- 主表 Col32-36 是公式列，AI 不要碰
- 字段名标"废弃"的列（如 Col13/Col49/Col95），新项目应跳过
- row3 为空（无 path）的列是辅助列，不影响 pbin

## 项目专用决策（独立段，列表形式不展开）

> 以下决策与具体项目相关，详见对应项目的 SOP skill：
> - **SLGX/SFK** 项目：详见 `hero-config` skill
>   - id 段约定（如 SFK 英雄 id ∈ [1001, 2000]）
>   - 字段默认值（如 isHero=True 必填、quality=橙、heroAttrRecom 统一填 OHAT_Force:0.96 等）
>   - 永久不做的字段清单（如 Col66-87 镜头组、Col98-100 talentPic 等）
>   - 进阶 sheet 写法约定
>   - heroTags 标签使用习惯
