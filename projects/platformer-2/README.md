# platformer-2

> 蒸汽朋克世界观下的 2D 平台跳跃 + 拼图（pipe puzzle）小品级项目。
>
> 同时承担工作室 **combo-A 进化方案** 端到端验证职责：所有 GDD / README / 关卡 / 代码 / 测试由 sub-agent spawn 产出，main agent 不允许独角戏。

## 当前阶段

`stage: pre-production / phase: M0`

M0 阶段产物以文档为主，`game/` 目录尚未生成。详细元数据见 `PROJECT.md`。

## 快速开始

### M0（当前）

M0 阶段还没有可运行的 Godot 工程，先阅读以下文档：

1. `PROJECT.md` — 项目元数据 / 核心约束
2. `gdd/` — 设计文档（由 designer agent 产出，M0 完成）
3. `studio/backlog.md` BL-S001-S008 — combo-A 验证 backlog
4. `studio/docs/retro-bolt-1-1-experience.md` — 进化方案上下文

### M1+（待 prototype 落地后启用）

启动 Godot 编辑器：

```
d:\AI\GameStudio\engine\Godot\Godot_v4.6.2-stable_win64.exe --path projects\platformer-2\game
```

或在 PowerShell 中：

```powershell
& "d:\AI\GameStudio\engine\Godot\Godot_v4.6.2-stable_win64.exe" --path "d:\AI\GameStudio\projects\platformer-2\game"
```

## 项目结构

```
projects/platformer-2/
├── PROJECT.md          # 项目元数据 + combo-A 约束
├── README.md           # 本文档
├── gdd/                # 设计文档（M0 由 designer agent spawn 产出）
├── stories/            # 用户故事 / backlog（dev-story 流程消费）
│   └── backlog.md
├── qa/                 # 测试与验收
│   └── run-tests.ps1   # 测试入口（M1+ 起可执行）
├── game/               # Godot 4.6.2 工程（M1 创建）
└── art/                # 美术 style guide / 参考（M2 充实）
```

> M0 阶段以上目录可能仍为空，按 milestone 推进逐步落地。

## 当前 milestone 状态

里程碑定义见 `PROJECT.md` § 当前 milestone：

- **M0** — GDD + 项目骨架（**进行中**）
- **M1** — 核心循环 prototype
- **M2** — vertical slice（1 个完整 level + 视觉资产）

阶段流转必须通过 `studio/skills/milestone-review/run.py` 触发三方评审，不允许 main agent 自行宣告达标。

## 如何运行测试

```powershell
pwsh -NoProfile -File projects\platformer-2\qa\run-tests.ps1
```

- M0：脚本可能仅做静态检查，无 godot 用例
- M1+：脚本应调用 `godot --headless --check-only` + 单元测试
- M2+：脚本需覆盖 `real_playtest` 端到端用例

## Smoke Checklist

发布或 milestone 推进前，按当前 phase 勾选可执行项：

- [ ] [M0] `PROJECT.md` + `README.md` + `gdd/` 三件套齐全
- [ ] [M0] `studio/skills/consistency-check` 报告无 ERROR
- [ ] [M1] `godot --headless --check-only --path game` 退出码 0
- [ ] [M1] `pwsh -NoProfile -File qa\run-tests.ps1` PASS
- [ ] [M1] 主菜单能正常打开
- [ ] [M1] 主角能左右移动 + 跳跃
- [ ] [M2] 完成 1 个完整 level（从开始到通关）
- [ ] [M2] `real_playtest` 测试用例 PASS
- [ ] [M2] art style guide 与 `assets/` 实际产出一致

## 进化项目的特殊性

platformer-2 不是普通项目，它同时是 **combo-A 进化方案** 的验证载体。与既有项目（bolt-1-1 / breakout）相比的硬约束：

| 约束 | 落地要求 |
|---|---|
| **C-1 · 0 main-agent-only artifact** | GDD / README / 关键代码 / 测试 / art review **必须** 由 sub-agent spawn 产出，main agent 仅做分发与裁决 |
| **C-2 · 100% 走 spawn 模板** | 每次 spawn 必须引用 `agent-spawn-contract` rule 中的 TPL-XX 模板，禁止自由发挥 prompt |
| **C-3 · 100% 走 run.py** | `dev-story` / `qa-gate` / `milestone-review` 必须通过对应 skill 的 `run.py` 触发，禁止 main agent 仿写报告 |
| **C-4 · 反模式自检** | 每次 milestone gate 触发 `studio/docs/anti-patterns.md` digest 自检 |

具体上下文：

- 所有 GDD 8 节由 `designer` agent 通过 TPL-03 起草
- 所有代码任务由 `studio/skills/dev-story/run.py` 驱动
- milestone gate 由 `studio/skills/milestone-review/run.py` 触发三方（designer / engineer / qa-lead）评审
- main agent 越权撰写产物即视为本项目验证失败信号

## Known Limitations

当前 phase 为 M0，下列内容尚未存在或未生效：

- `gdd/` 8 节文档：等待 designer agent spawn 产出
- `game/` Godot 工程目录：M1 创建
- `qa/run-tests.ps1`：脚本骨架已在，真实用例 M1+ 补齐
- `art/` style guide：M2 充实
- 验证报告 `studio/reports/evolution-combo-a-validation.md`：M2 里程碑后产出

随 milestone 推进，本 README 的 Smoke Checklist 与项目结构会同步更新。

## 关联文档

- 项目元数据：`projects/platformer-2/PROJECT.md`
- 设计文档：`projects/platformer-2/gdd/`（M0 完成后）
- backlog：`projects/platformer-2/stories/backlog.md`
- 工作室 backlog（含 BL-S001-S008 验证项）：`studio/backlog.md`
- 进化方案上下文：`studio/docs/retro-bolt-1-1-experience.md`
- 反模式知识库：`studio/docs/anti-patterns.md`
- spawn 模板库：`.codebuddy/rules/agent-spawn-contract/RULE.mdc`
- 验证报告（待 M2 后生成）：`studio/reports/evolution-combo-a-validation.md`
