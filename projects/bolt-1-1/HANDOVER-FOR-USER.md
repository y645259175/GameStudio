# Bolt: Sector 1-1 · 验收交接

> **状态：M6 资产接入完成，可以打开游戏验收**
>
> 这是给你的最终验收指南。包含怎么跑游戏 / 看什么 / 已知问题清单。

## 一句话

机械豆 Bolty 的废墟 Sector 1-1 横版跳跃，**所有美术资产已生成 + 接入 + 验证可显示**，真实玩家路径测试 PASS in 37.4s 通关。

## 验收方式

### 方式 1：直接双击运行（推荐）

```
projects/bolt-1-1/game/run-game.bat
```

或者：

```bash
cd projects/bolt-1-1/game
"d:\AI\GameStudio\engine\Godot\Godot_v4.6.2-stable_win64.exe" --path .
```

游戏启动后进入 title 画面，按 SPACE / Z / Enter 进入游戏。

### 方式 2：在 Godot 编辑器里打开

启动 Godot 4.6.2，打开 `projects/bolt-1-1/game/project.godot`，按 F5 运行。

## 操控

| 输入 | 动作 |
|---|---|
| ← → / A D | 左右移动 |
| Z / Space | 跳跃（按住更高）|
| X / Shift | 跑步（按住更快 + 跳更远）|
| ESC | 暂停 |

## 关键看点（验收检查项）

### 视觉部分

✅ **必须看到的**（如果看不到说明资产 import 有问题）：
1. **标题画面**：「BOLT」红字 + 「Sector 1-1」副标题 + 提示按 SPACE 启动
2. **背景**：工业废墟夜景，远山轮廓，月亮，深蓝灰渐变天空
3. **地面**：苔黄草顶 + 锈红土底（双层视觉）
4. **Bolty**：左下角小红色机械豆角色，黄色相机眼
5. **Mossroll**：路上有苔绿色小怪物，会移动
6. **Cache Box**：金黄方块带闪烁的蓝色 ? 标志
7. **Brick**：橘红工业砖
8. **Conduit**：暗绿金属管道（4 根高度递增）
9. **Power Berry**：红色发光浆果（Cache Box 顶出）
10. **Cog**：黄铜齿轮（Cache Box 顶出 + 关卡内撒落）
11. **Signal Tower**：金属杆顶端红信号球（关底）
12. **Outpost**：金属哨站（最右侧，通关动画终点）
13. **HUD**：顶部一行 BOLTY 分数 / COG 数 / SECTOR 1-1 / TIME 倒计时

### 玩法部分

| 时刻 | 你应当感受到的 | 验证方式 |
|---|---|---|
| 0-3s | 控制响应灵敏 | 按 ← → 试试加速 |
| 3-8s | 跳跃手感有重量、可变高度 | 按一下 vs 按住 跳，比对高度 |
| 8-15s | 第一只 Mossroll 可踩死 | 跳起来踩它头顶 |
| 15-25s | Cache Box 顶后给奖励 | 跑步跳起顶 ?块 |
| 25-40s | Power Berry → 变大 | 吃浆果，Bolty 长高 |
| 40-60s | Conduit 必须跳过 | 跑步跳过暗绿管道 |
| 60s+ | 触杆通关，5 段计分 | 撞 Signal Tower |

### 关键 DoD 验证

| ID | 项 | 怎么验 |
|---|---|---|
| DoD-01 | 5s 内可控 | 双击 run-game.bat → 看到 title 画面 → 按 SPACE → 立即可移动 |
| DoD-02 | 不死亡通关 < 200s | 慢慢走也能在时间限制内到达 |
| DoD-03 | 3 种死亡 | (a) 掉坑 (b) 小态被敌人撞 (c) TIME=0 |
| DoD-04 | 死亡 < 1.5s 重生 | 死后等一会自动重生在出生点 |
| DoD-05 | 3 种状态 | small → 吃 Power Berry → big → 吃 Spark Bloom → fire（变白蓝色）|
| DoD-06 | 6 个 Beat | B1 出生 / B2 第一只敌人 / B3 Cache Box 群 / B4 大坑+Shellpod / B5 升降台占位 / B6 信号塔 |
| DoD-07 | HUD 实时 | 拾物时分数变 / 时间在倒数 |
| DoD-08 | 隐藏 Blue Crystal | 中段某个砖块顶出蓝色水晶（+1 命）|
| DoD-11 | ESC 暂停 | 按 ESC 游戏暂停，再按继续 |
| DoD-12 | 5 分钟无 crash | 跑几把不闪退 |
| DoD-13 | 数值与代码解耦 | 改 `data/player.json` 里 `walk.maxSpeed` 重启就能感觉到不同 |
| DoD-14 | 真实玩家路径 PASS | `tests/real_playtest.gd` EXIT 0（已自动验证）|
| DoD-15 | production 真实资产 | 看截图 `reports/screenshots/` ✅ 已确认 |

## 自动化截图（验证视觉资产已正确接入）

如果你打开游戏发现仍是色块（ColorRect 占位），那是 **godot 资产 import 缓存问题**。修复方法：

```bash
# 在 game 目录跑一次 godot 让它扫描贴图
cd d:\AI\GameStudio\projects\bolt-1-1\game
"d:\AI\GameStudio\engine\Godot\Godot_v4.6.2-stable_win64.exe" --headless --import --path .
```

跑完后再运行游戏。

`projects/bolt-1-1/reports/screenshots/` 下有 6 张我跑出来的实际游戏画面截图作为参考基线，你的截图应该看上去跟这些类似。

## 已知小瑕疵（不阻塞验收）

| 项 | 描述 | 影响 | 优先级 |
|---|---|---|---|
| 视觉 1 | Bolty 16×16 在 1280×720 偏小（屏幕宽 1.25%）| 复杂背景下找角色稍累 | 设计选择 - NES 时代风格本就如此 |
| 视觉 2 | Bolty 没有走/跳动画（单帧静态）| 跑跳动作不灵动 | post-M6（多帧 atlas）|
| 视觉 3 | HUD 用 Godot 默认字体，不是像素 bitmap 字体（BL-016）| 不够"像素感" | post-M6 接入 Press Start 2P |
| 玩法 1 | 5 个 Mossroll 中 1 个可能在 cliff 边走偏后掉下 | 自动死敌人不影响玩家 | 不修 |
| 玩法 2 | MovingPlatform B5 段被 noop 跳过（BL-019）| 关卡 B5 段是平地无难度 | post-M6 |
| 玩法 3 | Spiker / Pulse Core 未实现 | 1-1 设计本不需要 | post-M6 |

## 已知 P1 backlog（M6 后可单独修）

| ID | 描述 | 触发条件 |
|---|---|---|
| BL-003 | Signal Tower Area2D 触发不工作（已绕过为距离检测）| 不影响通关 |
| BL-005 | 关卡退出时 ObjectDB WARNING（内存泄漏）| 实际无 crash |
| BL-006 | _show_game_over 之前会触发死循环（已绕过）| 不影响 |
| BL-007 | GameOver SPACE retry 路径无回归测试 | 手动可验证 |
| BL-008 | TIME=0 死亡触发未做单元测试 | 手动可验证 |

## 数值调试技巧

如果觉得跳跃太弱 / 太强，改：

```
projects/bolt-1-1/data/player.json   # 主表
projects/bolt-1-1/game/data/player.json  # 程序副本
```

关键字段：
- `jump.initialV: -380` 起跳冲击（更负 = 跳更高，但太高会撞屋顶）
- `jump.maxHoldFrames: 24` 最长持跳帧数（24 = 0.4 秒）
- `walk.maxSpeed: 90` / `run.maxSpeed: 150`

改完直接重启游戏即可生效（数据驱动）。

## 文件结构（你需要知道的）

```
projects/bolt-1-1/
├── HANDOVER-FOR-USER.md    ← 你正在看
├── PROJECT.md              ← 项目元数据 / 里程碑
├── README.md               ← 项目级 README
├── gdd/gdd-bolt-1-1.md     ← 完整 GDD（370 行 8 节）
├── docs/naming-map.md      ← mario→bolt 命名映射
├── data/                   ← 数值表（策划主本）
├── game/                   ← Godot 工程（双击 run-game.bat 跑）
│   ├── project.godot
│   ├── run-game.bat        ← 双击启动游戏
│   ├── assets/             ← 19 张 png + .import（M6 已接入）
│   ├── data/               ← 程序副本
│   ├── scenes/             ← title.tscn / main.tscn
│   ├── scripts/            ← 18 个 gd（实体 / 主流程 / sprite_helper）
│   └── tests/              ← real_playtest.gd / smoke_test.gd / screenshot_tool.gd
├── art/                    ← 美术参考 + key visual + sprite reference
├── reports/                ← qa-gate 报告 + screenshots/
└── stories/backlog.md      ← 待办清单
```

## 跑测试（验证游戏没坏）

```bash
# 1. 引擎语法校验
"d:\AI\GameStudio\engine\Godot\Godot_v4.6.2-stable_win64.exe" --headless --check-only --path . --quit
# 期望：EXIT 0

# 2. 真实玩家路径测试（无 cheat）
"d:\AI\GameStudio\engine\Godot\Godot_v4.6.2-stable_win64.exe" --headless --path . -s res://tests/real_playtest.gd
# 期望：EXIT 0 + "[REAL] PASS in 37.4s"

# 3. 烟雾测试
"d:\AI\GameStudio\engine\Godot\Godot_v4.6.2-stable_win64.exe" --headless --path . -s res://tests/smoke_test.gd
# 期望：EXIT 0
```

## 验收流程建议

1. 双击 `run-game.bat` → 看到 title 画面（5s 内）
2. 按 SPACE → 看到游戏画面（背景 / 地面 / Bolty / Cache Box / Mossroll 等）
3. 玩一把试试操控（移动 / 跳跃 / 跑步 / 踩敌 / 顶 ?块）
4. 看看 `reports/screenshots/` 里的 6 张截图，对比一下实际游戏画面是否一致
5. 觉得没问题 → 验收通过；有问题 → 告诉我具体哪里不对

## 完工概要

| 维度 | 数字 |
|---|---|
| 总 commit 数（M5.5 + M6）| 13 个 |
| 生成美术资产 | 19 张 PNG（408 KB）|
| Production 代码改造 | 13 个文件（player / 8 实体 / level_loader / main / scenes）|
| 真实玩家路径测试 | PASS in 37.4s, score=14200 |
| 关闭 P0 backlog | 5 个（BL-012/013/014/015/017 视觉债 + BL-001/009/011/018 玩法 + BL-002 hitbox）|
| 工作室级改进 | timiai-image skill +5 模块（cache/postprocess/batch/pipeline/daemon）|

希望你打开游戏看到的画面，跟我自动跑出来的截图差不多——如果一致就是真的 done 了。如果有任何不对，请告诉我具体看到了什么。
