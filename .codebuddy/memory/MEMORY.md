# 工作室长期记忆 · MEMORY.md

> 跨会话稳定事实。短期/日常工作笔记请写到 `YYYY-MM-DD.md` 而非这里。

## 用户偏好与原则

- **AI 估时原则**（已并入 update_memory ID 59617001）：
  按"改动行数 + 不确定性"评估，不要用人类工时直觉。模板化重构 100-500 行 ≈ 几秒，文件数 ≠ 复杂度。
- **不接受硬上限**（lint 阈值设计反馈）：
  分级提醒（safe/notice/review/approval）优于硬上限——硬上限会反向激励"凑到上限"且不能预测未来。
- **不喜欢"留 backlog 当收尾"**：如果剩下任务几分钟可做完，直接做完。"分阶段确认"在模板化任务里是浪费。
- **关注"是否真在工作"而不是"是否完整"**：偏向用证据/数据评估系统，反感百科全书式堆砌。

## xiuxian 美术风格基因（2026-06-18 用户定调，v2 完成）

- **统一走水墨写意风**（不是二次元日漫，不是卡通）。
- **canonical 基准 6 张全部就位**：`projects/xiuxian/art/style-anchors/`
  - `anchor-char-master.png`（门主立绘，水墨写意脸基准——细长墨眼、最简笔意五官、衣袂大块墨晕带飞白）
  - `anchor-char-disciple.png`（弟子立绘 v2，与 master 同谱系）
  - `anchor-sect-overview.png`（宗门全景，建筑笔触基准——屋顶墨色晕染 + 飞白 + 融入山水）
  - `anchor-building.png`（聚灵塔 v2，与 sect-overview 建筑同笔触）
  - `anchor-expedition-map.png`（历练地图，含朱砂洞穴 boss 标识）
  - `anchor-ui-panel.png`（UI 面板，回纹墨边 + 朱砂印章 + 山青进度条）
- **长期红线：后续所有生成图必须同系列同风格**——每次量产新资产前，art-director 必须拿这 6 张做对比基准，跑偏即重抽。**画风一致性是项目视觉基因的红线**。
- **风格修订 prompt 工程要诀**（v2 沉淀）：① 显式锚定参考画家/作品（齐白石/蒋兆和/傅抱石）比抽象风格词有效 10 倍 ② 把"水墨写意"拆为具体笔法（"眼睛是细长墨点不是日漫大眼"/"屋顶墨色浓淡晕染不是卡通块"）③ 必带禁忌列表（"不要 X / Y / Z"）— AI 对禁忌的执行比对正向描述更稳。

## 用户协作偏好（2026-06-18 定调）

- **程序实现细节用户不关心**：纯代码实现（service / 数据结构 / 接口 / 单测）AI 自主推进到底，**不要逐步汇报代码细节**。只在以下时刻停下找用户：① 需要用户做设计/方向判断 ② 有"实际可见现状"可看（美术成品 / 可运行 demo / 玩法手感）③ 遇到取舍。
- **需要用户确认的文件（含图片）必须给出基于项目根目录 `d:\AI\GameStudio` 的相对路径**（如 `projects\xiuxian\art\style-anchors\anchor-char-master.png`），这样用户才能直接点开。不要只写文件名不带路径。

## 项目级架构约定

- **四层架构**：`.codebuddy/`（能力层）+ `studio/`（工作室层）+ `engine/`（引擎层 gitignored）+ `projects/`（项目层）
- **不在根目录建文件**（除 README.md）
- **路径不引用 `analysis-report/` 或 `my-game/`**（历史遗留，已迁走）
- **新建项目前必须** `read_file studio/docs/project-structure-full.md`
- **延后细节存档模式**（2026-06-09 xiuxian M1 沉淀）：跨里程碑内容延后用 `projects/<name>/docs/m{N}-deferred-details.md`——主章节保持"当前里程碑必需 only"，延后内容仅留思路骨架到此存档，展开时搬回主章节再删存档对应条目。避免主章节膨胀 + M{N+1} 启动时遗忘思路。
- **架构重构三步**（2026-06-09 xiuxian GDD-02 沉淀）：加迁移指针 → 验证（用户审 PASS）→ 删除原内容。不一步删干净，避免回滚成本高。
- **ADR amendment 命名**：v1.0 → v1.1（接口扩充 / 增补，向后兼容）/ v2.0（schema 不兼容变更，需 migration）。amendment 附在原 ADR 文件末尾，不另起新文件。
- **里程碑收尾 AI 预审模式**（2026-06-18 xiuxian M1 沉淀）：用户审多章 GDD/ADR 工作量大，AI 应提前出三件套——① cross-章一致性扫描（数值/命名/接口签名机械检查）② 删除/重构预案（精确行号 + 特殊处理标注）③ 审阅报告 + verdict 模板（让用户填空式反馈）。把"逐字读 5000 行"降为"看报告 + 填模板"。
- **删除前先写预案而非直接删**（2026-06-18 沉淀）：写删除/重构预案本身就是审阅过程，逐项过一遍会发现"原本以为该删的其实是契约"（如 GDD-02 §7 buff 清单是 buff_id 集中登记，不该搬走）。**永远先 plan 再 execute**。

## Godot headless 开发约定（2026-06-18 xiuxian M2 沉淀）

- **Godot 二进制路径**：`engine/Godot/Godot_v4.6.2-stable_win64.exe`（gitignored，用户本机放置）。AI 用前先 `Test-Path` 确认。
- **autoload 路径**：`--path` 指向 `game/`，故 `res://` 根 = game/，autoload/脚本路径写 `res://scripts/...` **不带 game/ 前缀**。
- **新增 class_name 文件后必须先扫描**：直接 headless 跑会报 "Could not find type X"，因为 global_script_class_cache 未更新。先跑 `--headless --editor --quit` 触发 first_scan 注册 class_name，再跑验证。
- **headless 自检方式**：autoload 在 `--script`（SceneTree）模式**不挂载** → 必须建主场景（main_check.tscn）+ 普通 Node 的 _ready 跑断言，命令 `cmd /c "Godot.exe --headless --path X res://scenes/main_check.tscn > log 2>&1"`（用 cmd 重定向，PowerShell `&` 调用 CLIXML 污染输出 + 拿不到干净 exit code）。日志写文件再 read_file。
- **autoload 跨 service 时序**：autoload 顺序保证实例存在，但**不保证 _ready 逻辑完成**。依赖方查询前用 public `is_loaded()` 守卫（如 BuffService 查 DataRegistry 前判断）。
- **GDScript 类型推断陷阱**：`var x := null`（推不出）→ 写 `var x: Variant = null`；`var x := untyped_node.method()`（untyped 返回推不出）→ 显式 `var x: int =`。
- **autoload .gd 不写 class_name**（与单例名冲突）；纯数据类（RefCounted/Resource）可写 class_name。

## 文件 / 文档分层（渐进披露三层架构）

> 来源：D 系列改造（2026-05-20~21），见 `studio/docs/progressive-disclosure-architecture.md`

每个 rule / skill / agent 三层：
- **CORE**（`RULE.mdc` / `SKILL.md` / `AGENT.md`）：身份 + 红线 + 索引（每次注入 / spawn 必带）
- **MANUAL / PLAYBOOK / HANDBOOK**：详细 SOP / 模板（按需 read_file）
- **ARCHIVE**：历史判例（仅 RCA / postmortem 时查）

文件改动有 lint 分级提醒（不硬上限）：
- 30/40 行 → notice（写日志不阻塞）
- 50/60 行 → review（必须加 `<!-- OVER_LIMIT_REASON: ... -->` 自审）
- 80/100 行 → approval（commit msg 加 `[layer-override]` 表示用户已审批）

`.codebuddy/scripts/check_progressive_disclosure.py` 是 lint 工具，已挂到 commit-msg hook。

## 项目状态（2026-05-23）

### 当前项目
- **xiuxian**（修仙宗门搜打撤退，2026-05-23 启动）
  - 类型：单机 2D 沙盒经营 + 选项式 extraction（潜水员戴夫 × 鬼谷八荒 × Tarkov-lite）
  - 引擎：Godot 4.6.2-stable，平台：Steam PC
  - 核心循环：宗门内务（50%）⇄ 外出历练（50%）+ 角色境界成长贯穿
  - 双层时钟：外层月历（1 月 = 1 回合）+ 内层历练百分比
  - 节奏：前期 20 min / 中期 35 min / 后期 60 min（一个完整循环）
  - 角色统一系统：门主 / 弟子 / 长老（State 字段切换），门主死可传位
  - 战斗 VS1 = 数值模拟，但**必须**抽象 `BattleResolver` 接口
  - 美术：水墨写意（鬼谷参考），AI 辅助 + 修绘
  - **用户最强约束**："框架必须为后续内容留足开放性"——数据驱动 / 接口抽象 / 状态机 / 时间总线 / 存档版本号 6 条工程纪律已写入 GDD-01 §6
  - **里程碑纪律**（2026-05-23 用户定调，二次精修）：
    - M1 = GDD 全章节框架穷尽 + **风险预知 + 解耦设计**（不是"封闭"M2+ 加系统，而是"先验关卡"——加新系统走 5 步预案：ADR / GDD-10 / 存档兼容 / 依赖矩阵 / 接口检查）
    - M2 = 框架搭建，**4 接口（BattleResolver / EventResolver / ProductionRule / WorldEventTrigger）+ 存档结构 + 数据位置**一次到位（GDD-01 §6.7 5 点必做）
    - M3 = 垂直切片，含基础商业化美术达标 + 5 件基本功能（主菜单/开始/结束/存档/读档）+ 战斗用 StatSimulator 数值对拼
    - M4 内容扩展（宗门+大地图）/ M5 主线剧情 **+ 战斗系统升级**（回合制 + 技能 + 装备 + 状态效果衍生）/ M6 Beta / M7 Release
  - **战斗系统纪律**：M3 数据结构必须含 skills/equipped/status_effects 字段（即使为空），M5 升级回合制时不爆存档；5 个战斗接入点 M1 列全（历练挑战 / 宗门被攻击 / 派遣遭遇 / 主线 boss / 仙宗大比）
  - **系统解耦纪律**：通信只走 3 通道（EventBus / Service 接口 / 只读 data），禁止直读他系统内部；GDD-10 必含依赖矩阵；跨 3+ 系统改动 commit 加 `[cross-system]` tag
  - **角色三维度数据结构**（v3.1 关键架构决策）：
    - Identity（身份）：MASTER_CURRENT / DISCIPLE / ELDER / NON_SECT —— 长期、互斥
    - ActionState（行动状态）：IDLE / IN_CLOSED_DOOR / RECOVERING / DEFECTED / DEAD —— 每月可刷新、互斥
    - Buffs（修饰器）：由 BuffService 管理 —— 可叠加，不互斥
    - **Character 实现 IBuffable 接口**；**injury_level 字段已删除**（受伤值是 buff 查询结果）
  - **通用 Buff 系统**（ADR-0005 v2）：
    - **双表注册**：BuffType 定义表（大类 / 小类 / 数值 schema / 适用 target）+ BuffInstance 模板表（具体 buff_id + 默认值）
    - **IBuffable 接口**：任意实体可挂 buff（CHARACTER / SECT / MAP / REGION）
    - 各系统通过 `apply_by_id("buff_xxx", target)` 直接挂 buff，不硬编码字段
    - **InjuryService = buff 消费者**，不持有数据；通过订阅 buff signal + 累计查询实现受伤逻辑
  - **宗门数据结构**（ADR-0006）：
    - Sect 是独立实体，实现 IBuffable
    - SectService 是 Sect 数据唯一入口；InventoryService / BuildingService / ReputationService 做领域逻辑，通过 SectService 读写
    - 宗门可挂 SECT 类型 buff（灵气加速 / 邻宗来袭 / 弟子骚动等）
  - GDD-01 v5 + ADR-0001/0003v3.1/0005v2/0006 已落地
  - M1 待建：gdd-02 ~ gdd-10 + ADR-0002（战斗）+ ADR-0004（存档）

### 历史项目（已不再处理）
- **bolt-1-1**：M6.2 完成，已归档
- **platformer-2**：vertical slice 实玩崩教训沉淀为 AP-10/11 后归档（2026-05-21 入库）

### 正在用的基础设施
- **挂载工作的 hook**（4 个）：
  - SessionStart → `session-start.py`（精简引导）
  - UserPromptSubmit → `user-prompt-route.py`（7 条关键词路由）
  - PreToolUse → `pre-tool-bash.py`（拦危险操作 + auto-allow）
  - git commit-msg → `pre-commit-discipline.py`（强制 [tag] + 渐进披露 lint）

### 关键反模式（11 条 AP）
速读：`studio/docs/anti-patterns-digest.md` (CORE)
完整 SOP：`studio/docs/anti-patterns.md` (MANUAL)
历史判例：`studio/docs/anti-patterns-archive.md` (ARCHIVE)

最严重的 3 条：
- **AP-10** 自嗨循环：AI 自己宣布质量 PROVEN（必须有用户实玩反馈）
- **AP-11** 渲染层陷阱：transform 链断裂 / @export 缺失 → 资产 OK 但游戏内不渲染
- **AP-04** 凭直觉清理：看到"不被引用"就删，没看用途

## 已知严重缺陷（截至 2026-05-22）

> 详见 `studio/reports/system-health-2026-05-22.md`

1. **可执行 skill 仅 12%**：18/25 个 skill 是纯文档（main agent 只能 read 模仿）
2. **三层化只覆盖 5 核心 agent**：剩余 26 个 agent 没经过 D 系列改造
3. **零度量**：`.codebuddy/logs/` 只有 PreToolUse 日志，没有 agent spawn / skill 调用记录 → **不知道系统真实利用率**

## CodeBuddy IDE 环境约定

- **禁止用 shell 命令做文件操作**：用 IDE 工具 `read_file` / `write_to_file` / `replace_in_file` / `delete_file`
- **PowerShell 中文 + emoji 易触发 GBK 编码错误**：用 `$env:PYTHONIOENCODING="utf-8"` 或重定向到文件读取
- **commit msg 含中文 / 多行**：必须用 `git commit -F file.txt`，不能用 `-m`
- **CodeBuddy 高危关键词扫描**：`Remove-Item` / `rm` / `del` / `git reset --hard` 弹窗 hook 之前拦——绕过见 `.codebuddy/PERMISSIONS.md`

### CodeBuddy 插件管理

- **本地路径**：`C:\Users\<user>\.codebuddycn\extensions`（中文版）或 `.codebuddy\extensions`
- **没有独立的 codebuddy CLI**，但 VSCode 的 `code` CLI 兼容：
  ```powershell
  & code --install-extension <publisher.id> --extensions-dir C:\Users\<user>\.codebuddycn\extensions
  ```
  装完重启 CodeBuddy 生效。CodeBuddy 用 VSCode marketplace，所有 VSCode 扩展可用。
- **xiuxian 项目数据编辑栈**（已装于 .codebuddycn）：
  - `mechatroner.rainbow-csv` — CSV 列着色
  - `grapecity.gc-excelviewer` — Excel/CSV 网格视图（最强，已自带）
  - `janisdd.vscode-edit-csv` — CSV 网格编辑
  - `tamasfe.even-better-toml` — schema sidecar 文件高亮
  - `redhat.vscode-yaml` — YAML 高亮
