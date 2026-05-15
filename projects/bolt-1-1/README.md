# Bolt: Sector 1-1

> 工业风像素平台跳跃。机械豆 Bolty 在被废弃的 Sector 1-1 中前进，目标激活信号塔召唤主基地。
>
> 致敬经典 NES 时代横版平台手感（加减速 / 可变跳高 / 踩敌反馈），视觉与角色全部原创。

## 当前阶段

`phase: dev / status: pivot-from-mario-1-1`

项目从 mario-1-1 IP 风险版本 pivot 为完全原创的 bolt-1-1。详见 `PROJECT.md` 与 `docs/naming-map.md`。

## 目录

- `gdd/` — 策划案（玩法 / 系统 / 视觉 / 数值 / 关卡 / UX / 验收）
- `docs/naming-map.md` — 命名映射权威参考
- `data/` — 数值表（player / enemies / items / level-1-1 / palette）
- `art/` — style guide / 参考图 / 美术 prompt
- `assets/` — 实际游戏资产（精灵图 / 字体 / 音效）
- `game/` — Godot 4.6.2 工程（运行时）
- `stories/backlog.md` — 未排期 issue / 视觉债 / 风险点
- `retros/` — 复盘档案

## 快速开始

```
cd game
godot --path . 
```

或双击 `game/run-game.bat`。

## 操控

| 输入 | 动作 |
|---|---|
| ← → / A D | 左右移动 |
| Z / Space | 跳跃（按住更高）|
| X / Shift | 跑步（更快 + 跳更远）|
| ESC | 暂停 |

## 主要角色

| 名字 | 描述 |
|---|---|
| **Bolty**（主角） | 红色机械豆形态的小机器人；3 态：small / big / fire |
| **Mossroll**（敌人） | 长腿苔藓滚子；巡逻；被踩压扁 |
| **Shellpod**（敌人） | 金属甲虫；被踩缩进甲壳；甲壳可弹射清杀其他敌人 |
| **Power Berry**（道具） | 红色发光浆果；small → big |
| **Spark Bloom**（道具） | 白蓝电花；任意 → fire，可发射火球 |
| **Blue Crystal**（道具） | 蓝色棱晶；+1 命 |
| **Cog**（金币） | 黄铜齿轮；100 个 → +1 命 |
| **Signal Tower**（关底） | 信号塔；触杆即触发通关流程，5 段计分 |
| **Outpost**（终点） | 基地哨站；通关动画 |

## IP 声明

本项目为完全原创作品。无第三方 IP 引用，与任天堂 Super Mario 系列或其他商业作品无相似之处。
