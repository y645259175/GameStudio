# MVS+ v4 工作室孵化器迁移规划

> **文档元信息**
> - 版本：v4（工作室孵化器架构）
> - 创建时间：2026-05-13
> - 状态：**支柱 1/2/3 已锁 / §8.1 LFS 已锁 / §8.3 仓库结构已锁 / §6 Phase 1 范围已锁（含 art 生产管线）/ §9 迁移工程规约已锁 / Phase 1.5 归位 + git init 推迟到 Phase 2 已锁**
> - 定位：防遗忘锚点，记录对话中已对齐的结论
> - ⚠️ **本文档描述的目录结构为规划，非当前仓库实际结构**
> - ⚠️ **路径约定**：所有 `studio/reference/...` 路径在 **Phase 1.5 归位后生效**。Phase 1 期间 `analysis-report/` 和 `my-game/` 仍在工作区根目录原位，不动。

---

## 1. 背景与定位

### 1.1 文档血缘

```text
CCGS 原始分析（164 资产）          ← studio/reference/analysis-report/ 00-05
      ↓
v2 修订报告（MVS = 46 资产极简档）  ← .codebuddy/plans/analysis-report-v2-revision_08399d50.md
      ↓
MVS+ v3（52 资产，单项目档）        ← 本次对话前期结论
      ↓
MVS+ v4（工作室孵化器架构）          ← 本文档
```

### 1.2 工作室新目标

**一句话**：小型工作室，但目标对标 Steam 上小型团队的商业作品（《潜水员戴夫》《鬼谷八荒》水准）。

**衍生需求**：

1. **原型构建能力** — 快速验证玩法点子
2. **长周期反复打磨** — 支持商业品质所需的迭代深度
3. **双通道流程** — 重通道（原型/大改 story）走完整流程；轻通道（打磨期小改）仅需"有记录、易回退"
4. **多项目孵化器** — 工作室应能同时/前后孵化多个游戏项目，而非绑定单项目仓

### 1.3 新目标 4 维度 + 孵化维度

| 维度 | 含义 | v4 覆盖状态 |
|---|---|---|
| 1. 发行 | Release 流程、上架审查、运营 | ❌ **TODO**（P0 Release 4 skill 暂未加） |
| 2. 长周期反复打磨 | sprint / retro / velocity / balance 迭代 | ✅✅（含 `studio/postmortems/` 跨项目沉淀） |
| 3. 商业品质 | 一致性、架构决策、数值深度 | ⚠️ 部分（balance 靠 GDD + `game/data/`，未单设目录） |
| 4. 双通道 | 重 `/dev-story` + 轻 `/quick-fix` | ✅ |
| **新：孵化能力** | 多项目容器 + 跨项目经验复用 | ✅（v4 新增） |

---

## 2. 支柱 1 锁定结论（能力覆盖面 v4）

> **锁定摘要**
> - **总量**：21 必装 skill + 5 hook + 5-6 rule + 9 template + 9-10 agent
> - **相对 v1 MVS（46）**：+5 skill（含 1 升必装）+1 hook +1 rule
> - **拍板要点**：双通道通过 skill 显式分流 / commit tag 软建议 / 判据双轨（工作室默认 + 用户 override）
>
> ⚠️ **以下数字为支柱 1 锁定时的能力清单基线**。Phase 1 实际起草数量见 §6.1.1（22 skill / 30 agent / 6 rule，含 art 管线扩张和 engine-specialist 全备）。本节保留原始锁定数字作为决策痕迹。

### 2.1 资产清单

| 类别 | 数量（支柱 1 基线） | Phase 1 起草数（§6.1.1）| 备注 |
|---|---|---|---|
| Skill 必装 | 21 | **22** | v1 MVS 17 + 新增 4 + quick-fix 1；Phase 1 增 art-asset-pipeline |
| Skill 可选 | 2 | — | `adopt` / `quick-design`（保留为可选） |
| Hook | 5 | 5 | v1 MVS 4 + 新增 `validate-commit.sh`（仅校验 GDD 8 节完整性 + JSON 合法性，**不管 tag**） |
| Rule | 5-6 | **6** | 含新增 `commit-discipline.md`（alwaysApply，软建议） |
| Template | 9 | 9 | 不变 |
| Agent | 9-10 | **30** | Phase 1 含 engine-specialist 15 全备 + art-director 1（档 7 工作室能力库视角） |

### 2.2 关键新增资产

#### Skill（5 个新增/升级）

- **`sprint-plan`**：基于既有 epic + velocity 历史规划下一 sprint，产出 `production/sprints/sprint-N/plan.md`
- **`architecture-decision`**：lead-programmer 主导 ADR 流程，输出 `docs/architecture/ADR-XXX-<slug>.md`
- **`balance-design`**：数值支柱，产出内容并入 GDD 一节（不单设 balance 目录）
- **`consistency-check`**：由可选升为必装，扫 `design/gdd/` 检测跨文档冲突，输出 `production/consistency-reports/*.md`
- **`quick-fix`**：轻通道入口，lead-programmer 直接改代码不 spawn 其他 agent，引导写 `[quick]/[fix]/[refactor]` tag

#### Hook

- **`validate-commit.sh`**：pre-commit 校验 GDD 8 节完整性 + JSON 合法性；**不校验 tag**（tag 由 rule 软建议管）

#### Rule

- **`commit-discipline.md`**：alwaysApply，规定 commit message 必须含 4 类 tag；含工作室默认判据；agent **软建议**（D1 强制度），用户最终拍板

### 2.3 双通道路由规则

| 通道 | 入口 skill | 判据（工作室默认） | Commit tag |
|---|---|---|---|
| **重** | `/dev-story` | 改 GDD **∨** 引入新 system **∨** 跨 ≥3 文件 | `[story]` |
| **轻** | `/quick-fix` | 以上三条**都不满足** | `[quick]` / `[fix]` / `[refactor]` |

**判据双轨**：工作室默认判据（agent 软建议）+ 用户 commit message override（最终决定权）

**Commit tag 4 类**：`[story]` `[quick]` `[fix]` `[refactor]`

### 2.4 P0 Release（暂缺，已入 TODO）

4 个 release skill（release-prep / release-checklist / qa-gate / post-launch）暂未纳入 v4，待支柱 3 确定后再补。**这是 v4 维度 1（发行）未覆盖的原因**。

---

## 3. 支柱 2 锁定结论（产物形态 v4 = 工作室孵化器）

> **锁定摘要**
> - **顶层模型**：工作室孵化器（多项目母仓），`.codebuddy/` + `studio/` 全工作室共享，`projects/` 容纳多个游戏
> - **项目内模型**：`game/`（交付物）/ `design/`（设计，不含 balance）/ `production/`（过程产物）/ `docs/`（技术文档）清晰分离
> - **拍板要点**：`studio/` 最小版；项目内原型放 `production/prototypes/`；GDD 小节示意非强制

### 3.1 顶层结构（工作室级）

```text
GameStudio/                      ← 工作室根
├── .codebuddy/                  ← AI 工作空间（全工作室共享）
│   ├── skills/                  ← 21 必装 skill
│   ├── hooks/                   ← 5 hook
│   ├── rules/                   ← 5-6 rule
│   ├── templates/               ← 9 template
│   ├── agents/                  ← 9-10 agent
│   └── plans/                   ← 历史规划 / 对话快照
│
├── studio/                      ← 跨项目沉淀层（最小版）
│   ├── docs/
│   │   ├── studio-handbook.md   ← 工作室运作手册（workflow-heavy/light 可后补）
│   │   ├── acceptance-standards.md  ← §4 6 条底线落地（§6.1.1 扩展）
│   │   ├── language-policy.md   ← §9.1 中英策略（§6.1.1 扩展）
│   │   └── engine-reference/    ← 45 文件 3 引擎全备（§6.1.1 扩展）
│   ├── reference/               ← 只读参考区（Phase 1.5 由用户 mv 填充）
│   ├── postmortems/             ← 跨项目复盘
│   └── README.md
│
├── projects/                    ← 所有游戏项目容器
│   ├── <project-a>/             ← 例如 diver-dave/
│   ├── <project-b>/             ← 例如 ghost-valley/
│   └── _archived/               ← 已停项目归档
│
├── README.md                    ← 工作室门面 + 项目索引
└── .gitignore
```

**拍板记录**：
- **Q1（studio/ 初期规模）= B 最小版**：仅 `studio/docs/studio-handbook.md` + `studio/postmortems/`，tools 等按需建
- `.codebuddy/` 全工作室共享，一套 skill 服务多个项目

### 3.2 单项目结构（`projects/<name>/`）

```text
projects/<project-name>/
│
├── game/                        ← 真实交付物（"复制出来即可独立打包上架"）
│   ├── src/                     ← 代码
│   ├── assets/                  ← 美术 / 音效 / 资源
│   ├── data/                    ← 配表（CSV/JSON/Excel）
│   ├── engine/                  ← 引擎工程文件（Unity/Godot/...）
│   ├── tools/                   ← 项目内工具（导表器等）
│   ├── tests/                   ← 测试代码
│   └── build/                   ← 构建产物（gitignore）
│
├── design/                      ← 设计文档（不含 balance）
│   ├── gdd/                     ← 主 GDD
│   │   │
│   │   │   > ⚠️ 小节划分为**示意，非强制**
│   │   │   > 项目真正落地时再根据游戏类型决定小节数量与主题
│   │   │   > 下列 8 节仅为参考模板：
│   │   │   >   01-vision / 02-pillars / 03-loops / 04-systems
│   │   │   >   05-content / 06-progression / 07-economy / 08-narrative
│   │   │
│   │   └── ...
│   ├── world/                   ← 世界观 / 剧情设定
│   ├── ux/                      ← UI/UX 草图
│   └── references/              ← 参考资料 / 竞品分析
│
├── production/                  ← 过程产物（不进交付包）
│   ├── stories/                 ← 重通道 story 文档
│   ├── sprints/                 ← sprint 规划与回顾
│   │   └── sprint-N/plan.md + retro.md
│   ├── consistency-reports/     ← consistency-check 输出
│   ├── retros/                  ← 独立复盘文档
│   └── prototypes/              ← 项目内原型（Q2=C 落点）
│
├── docs/                        ← 技术文档
│   ├── architecture/
│   │   ├── README.md            ← ADR 索引（手动维护）
│   │   ├── ADR-001-*.md
│   │   └── ADR-002-*.md
│   ├── api/                     ← 接口文档
│   └── runbooks/                ← 运维 / 调试手册
│
├── PROJECT.md                   ← 项目元信息（阶段 / 标准覆盖 / velocity 历史）
└── README.md
```

**拍板记录**：
- **Q2（原型归属）= C**：项目内原型放 `projects/<p>/production/prototypes/`；未立项的工作室级探索暂不单独建目录
- **Q3（GDD 小节）= A 示意非强制**：文档描述的 8 节仅为参考模板，项目落地时自行决定

### 3.3 产物 4 Tier 分层

| Tier | 含义 | 典型位置 | 示例 |
|---|---|---|---|
| **A 核心必产物** | 每个项目必有 | `projects/<p>/` 各处 | GDD、PROJECT.md、`game/src/`、`game/data/` |
| **B 阶段性产物** | 走流程才产生 | `production/` | story、sprint plan、retro、ADR、consistency report |
| **C 背景产物** | 参考 / 沉淀 | `design/references/`、`studio/postmortems/` | 竞品分析、跨项目经验 |
| **D 隐性产物** | 不落文件 | `.git/` | `[story]/[quick]/[fix]/[refactor]` commit history |

### 3.4 目录分离原则

| 目录 | 是否进交付包 | 备注 |
|---|---|---|
| `game/` | ✅ 进 | 真实交付物 |
| `design/` | 视情况 | 一般不进，但可选随发型 |
| `production/` | ❌ 不进 | 纯过程产物 |
| `docs/` | 视情况 | API 文档可能公开，其他不进 |
| `.codebuddy/` `studio/` | ❌ 不进 | 工作室级，不属于项目 |

---

## 4. 支柱 3 锁定结论（验收机制 v4）

> **锁定摘要**
> - **粒度**：混合分层（工作室级 6 条底线 + 项目级加码）
> - **时机**：A 极简 pre-commit + E 手动 `/daily-check` 日终 + C sprint 末 + D 里程碑 4 级（pre-push 暂不开）
> - **双通道差异**：重通道完整验收 / 轻通道仅基础校验
> - **度量**：5 数据并列（[story]/[quick]/[fix]/[refactor]/总 commit），不加权
> - **拍板要点**：单人 + 异地 + 1-2 commit/天 的工作模式下，重决策点（sprint 末 / 里程碑）手动触发，日常自动且极轻

### 4.1 决策摘要表

| 编号 | 决策项 | 锁定结论 |
|---|---|---|
| Q1 | 验收粒度 | **混合分层** — 工作室级定 6 条底线，项目级在底线上加码 |
| Q2 | 验收时机 | **A 极简 pre-commit + E `/daily-check` 日终 + C sprint 末 + D 里程碑**（B pre-push 暂不开） |
| Q3 | 双通道差异 | **轻通道仅基础校验**（validate-commit + 语法/编译），不跑 consistency-check / smoke-check |
| Q4 | velocity 度量 | **5 数据并列**：[story] / [quick] / [fix] / [refactor] / 总 commit 数；不加权，不算单一分数 |
| Q5 | consistency 触发 | **`/dev-story` 内 + sprint 末** 两处（写 story 必跑 + sprint 末兜底） |
| Q6 | 里程碑分级 | **4 级**：demo-ready / alpha / beta / release；每级 AI 出报告 + 用户拍板 |
| Q7 | 工作室底线 | **6 条全要**（A-F 详见 §4.2） |

### 4.2 验收粒度：混合分层（Q1）

**结论**：工作室级 `studio/docs/acceptance-standards.md` 定一条「最小底线」，所有项目自动套用；项目级 `projects/<p>/PROJECT.md` 可在底线之上加码（如 RPG 项目要求 `design/gdd/` 必含 narrative.md）。

**理由**：单人多项目场景下，纯工作室级太僵，纯项目级会让每个项目重复决策。混合分层兼顾复用和灵活。

#### 4.2.1 工作室级 6 条底线（Q7，A-F 全选）

| 编号 | 底线 | 防什么问题 |
|---|---|---|
| **A** | 必须过 `validate-commit.sh`（GDD 8 节完整 + JSON 合法） | GDD 残缺 / 配置 JSON 写坏 |
| **B** | `PROJECT.md` 必须存在且声明 stage（prototype/alpha/beta/release） | 半年后回看不知道项目处境，无法决策"继续/砍/加码" |
| **C** | `design/gdd/` 必须存在（哪怕只有 1 节） | 设计意图全在脑子里，AI agent 没法基于 GDD 工作 |
| **D** | 每 sprint 必须有至少 1 份 retro 文档 | 埋头干 N 周从不回看，跑偏不自知 |
| **E** | 里程碑前必须有完整 consistency-report | 进入下一阶段前没做体检，bug 累积爆发 |
| **F** | 项目首次 commit 必须包含 README + .gitignore + .gitattributes | 漏 .gitignore 把 build 产物提进 git；漏 .gitattributes 后面切 LFS 麻烦 |

**底线分类**：
- A/B/C = **结构底线**（项目长得像不像合规项目）
- D = **节奏底线**（项目有没有在持续推进 + 复盘）
- E = **质量底线**（关键节点有没有体检）
- F = **初始化底线**（项目从第一天就规范）

#### 4.2.2 项目级加码示例（非强制，按项目类型决定）

- 叙事重项目 → 加码"design/gdd/ 必含 08-narrative.md"
- 数值重项目 → 加码"每次 [quick] 改 game/data/ 必须更新 production/balance-notes/"
- 多人协作项目（未来） → 加码"开 pre-push 验收"

### 4.3 验收时机（Q2 + Q3）

**结论**：4 个时机分两类：自动（A）+ 手动（E/C/D）。pre-push（B）暂不开。

| 时机 | 触发方式 | 频率 | 跑什么 | 预期耗时 |
|---|---|---|---|---|
| **A. pre-commit 极简** | Git hook 自动 | 每次 commit | JSON/YAML 语法 + commit message tag 软提醒 | 秒级 |
| **E. `/daily-check` 日终** | 手动（agent skill） | 每天 1 次 | 完整验收 + 生成日报 | 分钟级 |
| **C. sprint 末** | 手动（`/smoke-check` 或 `/validate-sprint`） | 1-2 周 1 次 | consistency-check + velocity 5 数 + 集成/冒烟 | 分钟级 |
| **D. 里程碑** | 手动（`release-checklist`） | 整个项目 4 次 | 全套验收 + 加码（性能/包体/合规） | 小时～天级 |

#### 4.3.1 A. pre-commit 极简版

**只做**：
- JSON / YAML 语法合法性检查
- commit message tag 软提醒（缺 tag 时给提示，不阻塞）

**不做**：
- ❌ consistency-check（费时）
- ❌ 编译 / 单元测试
- ❌ 完整 GDD 8 节扫描

**理由**：单人 1-2 commit/天 + 异地开发，pre-commit 卡几秒就会让人按 `--no-verify` 绕过。极简化保证它永远不挡路。

#### 4.3.2 E. `/daily-check` 日终（新增时机）

**触发**：每天结束前手动调用 `/daily-check` skill。

**跑什么**：
- 完整 validate-commit（GDD 8 节 + JSON）
- 编译 / 单元测试
- 当日 commit tag 分布统计
- 生成日报到 `production/daily-checks/YYYY-MM-DD.md`

**理由**：用户工作模式 = 1-2 commit/天 + 异地切换电脑。pre-commit 极简后，需要一个时机做"今日完整体检"。手动触发好过 Windows 计划任务（不依赖电脑常开 + 异地切换不丢）。

#### 4.3.3 C. sprint 末

**触发**：sprint 结束开 retro 之前，手动 `/smoke-check` 或 `/validate-sprint`。

**跑什么**：
- 完整 consistency-check（扫整个 GDD 找矛盾）
- velocity 5 数汇总（详见 §4.4）
- 集成 / 冒烟测试
- 产出 `production/sprints/sprint-N/acceptance-report.md`，retro 时用

**作用**：retro 的客观依据，避免凭感觉聊。

#### 4.3.4 D. 里程碑 4 级（Q6）

详见 §4.6。

#### 4.3.5 为什么不开 pre-push（Q2-B 暂不开）

单人工作室下 commit 和 push 基本连着做（push 等于 commit），pre-push 与 pre-commit 收益重复 + 烦躁度叠加。**未来引入协作者时再开**。

#### 4.3.6 双通道差异（Q3）

| Commit tag | 走哪条验收链 |
|---|---|
| `[story]` | pre-commit 极简 + `/daily-check` 完整 + sprint 末完整（重通道完整流程） |
| `[quick]` | pre-commit 极简 + `/daily-check` 完整（**不跑 consistency-check / 不跑 smoke-check**） |
| `[fix]` | 同 [quick]（仅基础校验） |
| `[refactor]` | 同 [quick]（仅基础校验） |

**理由**：双通道的初衷就是"轻通道不被重 story 级检查拖慢"。如果轻通道也跑完整 consistency-check，双通道设计就失效。轻通道改了重要的东西时，由用户主动升级到 [story] 走重通道。

### 4.4 度量：双指标并列（Q4）

**结论**：sprint 末 / `/daily-check` 报告里固定输出 5 个数，**并列展示，不加权**：

```
本 sprint（或本日）数据：
  - [story] 数：N1
  - [quick] 数：N2
  - [fix] 数：N3
  - [refactor] 数：N4
  - 总 commit 数：N5
```

**不做**：
- ❌ 不算 velocity 单一分数
- ❌ 不主观加权（[story]=3 / [quick]=1 这种）
- ❌ 不和 story point 挂钩（单人工作室估点没意义）

**用途**：
1. **retro 客观依据**：让"这周状态如何"有数据可看
2. **阶段切换信号**：连续 N sprint `[story]→0 + [quick]→主导` = 该考虑 alpha-ready
3. **AI agent 输入**：`/daily-check` / `/retrospective` / `/milestone-check` 读取 tag 分布作为输入；这是双通道设计真正落地的支点

**解读权留给人 / AI**：5 个数并列报，retro 时基于上下文自行判断（如"[quick] 升高"在打磨期是好事、在原型期是坏信号）。

### 4.5 关键 skill / hook 触发矩阵（Q5）

| 检查项 | 触发时机 | 备注 |
|---|---|---|
| `validate-commit.sh` | A pre-commit（自动）+ E `/daily-check`（手动） | hook + skill 双重保险 |
| `consistency-check` | **`/dev-story` 内自动 + C sprint 末手动** 两处（Q5=D） | 写 story 必跑，sprint 末兜底；不进 hook（避免每次 commit 卡住） |
| 语法 / 编译 / 测试 | A pre-commit（极简版仅语法）+ E `/daily-check`（完整） | / |
| velocity 5 数统计 | E `/daily-check` + C sprint 末 + D 里程碑 | / |
| `smoke-check` | C sprint 末（重通道）+ D 里程碑 | 轻通道不触发（Q3） |
| `release-checklist` | D 里程碑（4 级各跑一次） | / |

### 4.6 里程碑 4 级（Q6=A）

每级判据 + 拍板规则：

| 级别 | 判据 | AI 产出 | 拍板人 |
|---|---|---|---|
| **demo-ready** | 第一次能给别人玩的 demo（核心循环跑通） | 完整 consistency-report + 已知 issue 列表 + demo 操作说明 | 用户 |
| **alpha** | 功能基本齐全，开始集中修 bug | alpha-checklist 报告（功能完成度 + 体验流畅度 + velocity 趋势） | 用户 |
| **beta** | 进入封闭 / 公开测试 | beta-checklist 报告（性能 / 包体 / 兼容性 / 测试覆盖） | 用户 |
| **release** | 上架前最后一关 | release-checklist 报告（合规 / 商店素材 / 隐私政策 / release note） | 用户 |

**规则**：
- 每级**必有**完整 consistency-report（对应 Q7-E 底线）
- 每级 AI 跑一遍 `release-checklist`（或对应级别的 skill）出报告
- 用户基于报告拍板"过 / 不过 / 修哪些再看"
- 通过后更新 `PROJECT.md` 的 stage 字段（对应 Q7-B 底线）

### 4.7 未决 TODO（支柱 3 范围内）

- [ ] `/daily-check` skill 的具体实现细节（产出格式、与现有 skill 的复用关系）→ Phase 1 落地时定
- [ ] `acceptance-standards.md` 工作室级文档模板 → Phase 1 创建 `studio/docs/` 时一并起草
- [ ] 项目级加码的"声明语法"（在 PROJECT.md 哪一节、用什么格式）→ Phase 2 首个项目落地时实践后定
- [ ] retro 跨项目合并节奏（项目级 retro → `studio/postmortems/` 的沉淀触发条件）→ 第 2 个项目立项时讨论

---

## 5. 已锁 TODO 队列（不在本期范围）

### 5.1 P0 Release（维度 1 发行能力）
- [ ] `release-prep` skill
- [ ] `release-checklist` skill
- [ ] `qa-gate` skill
- [ ] `post-launch` skill

### 5.2 质量校验扩展
- [ ] `validate-push.sh` hook
- [ ] `validate-assets.sh` hook

### 5.3 能力改造（6 项）
- [ ] `dev-story` 双通道分流强化
- [ ] `quick-fix` 边界澄清（不得改 GDD / 不引入新 system）
- [ ] `/help` 双通道指引补全
- [ ] `retrospective` 跨 sprint 能力
- [ ] `scope-check` 支柱漂移检测
- [ ] `smoke-check` 分级（重/轻通道差异）

### 5.4 开放点（3 项）
- [ ] 引擎选择（Unity / Godot / Unreal / 其他）
- [ ] Discovery 剩余 2 skill 是否启用（`adopt` / `quick-design`）
- [x] `producer` agent 是否装（已确定 Phase 1 装，详见 §6.1.1 职务 5 列表）

### 5.5 结构改造（源自 xsfk-designer，暂不做）
- [ ] PATCHES 自我迭代机制（skill 迭代 + archive 归档 + P0-P3 分级）
- [ ] PromptX-style SubAgent 机制（`.codebuddy/agents/` 下 YAML front matter 声明）
- [ ] 项目初始化引导 skill（README.md 作 AI 执行清单）

---

## 6. 迁移路径（Phase 1 已锁）

> **轮 A 锁定**：Phase 0-5 骨架 + Phase 1 完整展开（档 7 · 工作室能力库中心论）
> 详见 §6.1

```text
Phase 0：现状盘点 + 迁移 baseline（已完成）
  ├─ 产出 studio/reference/analysis-report/current-state-inventory.md（Phase 1.5 归位后路径）
  ├─ 用户完成工作区整体压缩快照（存工作区外，物理回滚保险）
  └─ 锁定现有内容处理原则：Phase 1 期间 analysis-report/ / my-game/ / .codebuddy/plans/ 保持原位不动

Phase 1：建工作室能力库（本规划主战场，档 7 + art 管线）
  详见 §6.1
  ⚠️ Phase 1 期间 **无 git 管理**（无 .git / 无 commit / 无 tag）
  ⚠️ Phase 1 产出**不引用** analysis-report/ 和 my-game/ 原路径；如必须引用，直接写未来位置 studio/reference/...

Phase 1.5：现有资产归位（用户手动 mv）
  ├─ 建 studio/reference/ 目录 + README.md（定位为只读参考区）
  ├─ mv analysis-report/ → studio/reference/analysis-report/
  ├─ mv my-game/ → studio/reference/my-game/（注意 my-game 是独立 git 仓，mv 不影响其自身 git 状态）
  └─ AI 扫一遍所有文档里的 studio/reference/... 路径，确认全对齐（详见 §6.1.4）

Phase 2：git init + 首个项目落地（共仓策略 §8.3）
  ├─ 工作室首次 git init（根目录）
  ├─ 新建 .gitignore（含 studio/reference/my-game/ 嵌套仓隔离）+ .gitattributes（含 LFS 预置 §8.1.2）
  ├─ 首次大 commit：完整 studio/ + .codebuddy/ + studio/reference/ 一次性成为基线
  ├─ git tag v4-foundation（Phase 2+ 每次回滚的原点）
  ├─ 运行 /new-project，用 PROJECT.md 模板初始化 projects/<first>/
  ├─ 运行 /setup-engine，选定引擎（Godot / Unity / Unreal 之一）
  │   └─ 工作室已备齐 3 引擎 specialist 与 engine-reference，只需声明 Engine: X
  ├─ 运行 /design-system 或 /quick-design，产出首份 GDD
  ├─ 跑一次 /dev-story 重通道（validate 骨架）
  ├─ 跑一次 /quick-fix 轻通道（validate 快速路径）
  ├─ 产出首份 consistency-report / ADR / sprint plan
  └─ 首次里程碑 demo-ready 体检（/release-checklist）

Phase 3：验收机制实战打磨
  ├─ 根据 Phase 2 实战反馈，调整 §4 验收机制细节
  ├─ 各 skill 的 "Known Limitations / Phase 2 Review Points" 逐条消化
  └─ smoke-check / retrospective 在真实 sprint 中落地

Phase 4：P0 Release 4 skill 消化
  ├─ 4 个 release skill 上线（release-checklist 完整 4 级）
  ├─ validate-push.sh / validate-assets.sh 按需启用
  └─ 维度 1 发行能力闭环

Phase 5：第二个项目 / 仓库拆分决策
  ├─ 若工作室稳定 + 开新项目：按 §8.3 锁定条件评估是否拆仓
  └─ 若不拆：新项目直接 projects/<second>/，复用同仓
```

---

### 6.1 Phase 1 完整展开

**目标**（用户定义）：Phase 1 跑完后，三大支柱（能力 / 产出 / 验证）**理论上都能落实**，首个项目**知道怎么落地**，缺的只是实践。

**档位**（轮 A 拍板 + 本轮补充）：**档 7 · 工作室能力库中心论 + 美术资产管线**
- skill 全流程自洽（**22 skill**，新增 `art-asset-pipeline`）+ agent 含 engine-specialist 全备（**30 agent**，新增 `art-director`）+ engine-reference 3 引擎全 copy（45 文件）
- 工作室 = **能力库**（不管用不用，常备）；项目 = 能力库的**调用实例**
- 美术资产生产：`art-asset-pipeline` skill 调用**已接入的** `.codebuddy/skills/timiai-image`（工作室级能力，本规划不重建、不改造）
- 每件产出遵守"流程完全自洽 + 引用闭合 + 引擎/代码知识用占位路由 + 缺失引导"原则
- 每件产出标 `## Known Limitations / Phase 2 Review Points`，接受实战调整

#### 6.1.1 Phase 1 产出清单（约 125 件）

```
d:/AI/GameStudio/
├── .gitignore / .gitattributes / README.md     ← 3 件
│
├── .codebuddy/（扩充，保留 plans/ 不动）
│   ├── agents/                                  ← 30 件
│   │   ├── 职务 5：producer / creative-director / game-designer / qa-lead / release-manager
│   │   ├── 代码 5：gameplay-programmer / engine-programmer / ai-programmer
│   │   │        / network-programmer / ui-programmer
│   │   ├── engine-specialist 15：
│   │   │   ├── Godot 5：godot-specialist / gdscript / csharp / shader / gdextension
│   │   │   ├── Unity 5：unity-specialist / ui / shader / dots / addressables
│   │   │   └── Unreal 5：unreal-specialist / blueprint / gas / umg / replication
│   │   └── 其他 5：ux-designer / prototyper / tools-programmer / qa-tester / art-director（新）
│   │
│   ├── skills/                                  ← 22 件（v4 MVS 必装集，流程全实）
│   │   ├── 工作室级 8：start / daily-check（新）/ smoke-check / retrospective
│   │   │        / consistency-check / release-checklist / new-project（新）/ help
│   │   ├── 项目级纯流程 9：create-stories / create-epics / sprint-plan
│   │   │        / design-review / review-all-gdds / story-readiness
│   │   │        / quick-design / milestone-review / story-done
│   │   ├── 项目级带占位路由 4：dev-story / quick-fix（新）/ architecture-decision
│   │   │        / setup-engine
│   │   └── 美术资产 1：art-asset-pipeline（新，调用 .codebuddy/skills/timiai-image）
│   │
│   ├── hooks/                                   ← 5 件
│   │   ├── validate-commit.sh（GDD 8 节 + JSON，§4 Q7-A）
│   │   ├── pre-commit-lite.sh（极简版，§4 Q2-A）
│   │   ├── log-agent.sh（审计，抄上游）
│   │   ├── session-start.sh（抄上游）
│   │   └── detect-gaps.sh（抄上游，可选）
│   │
│   ├── rules/                                   ← 6 件
│   │   ├── commit-discipline.md（双通道 tag 软建议，v4 §2）
│   │   ├── design-authoring.md（GDD 8 节规范，§4 Q7-C）
│   │   ├── language-policy.md（**薄壳** · 一句话指向 studio/docs/language-policy.md，§9.1）
│   │   ├── project-structure.md（项目目录规范，v4 §3）
│   │   ├── data-driven.md（数值不硬编码，抄上游）
│   │   └── test-standards.md（测试规范，抄上游）
│   │
│   └── templates/                               ← 9 件
│       ├── PROJECT.md.tpl（含 stage 字段，§4 Q7-B）
│       ├── gdd-8-sections.md.tpl
│       ├── retro.md.tpl（§4 Q7-D）
│       ├── consistency-report.md.tpl（§4 Q7-E）
│       ├── adr.md.tpl
│       ├── sprint-plan.md.tpl
│       ├── ux-spec.md.tpl
│       ├── hud.md.tpl
│       └── accessibility.md.tpl
│
├── studio/                                      ← 工作室层
│   ├── docs/
│   │   ├── studio-handbook.md                   ← 工作室宪法
│   │   ├── acceptance-standards.md              ← §4 6 条底线落地
│   │   ├── language-policy.md                   ← §9.1 中英策略（人类可读版）
│   │   └── engine-reference/                    ← 45 文件（工作室知识库）
│   │       ├── godot/  12 files（copy from upstream）
│   │       ├── unity/  16 files（copy from upstream）
│   │       └── unreal/ 17 files（copy from upstream）
│   ├── reference/                               ← 只读参考区（Phase 1.5 由用户 mv 填充）
│   │   ├── README.md                            ← 定位说明：只读、不被运行时依赖
│   │   ├── analysis-report/                     ← Phase 1.5 mv 后落位（Phase 1 期间为空）
│   │   └── my-game/                             ← Phase 1.5 mv 后落位（Phase 1 期间为空）
│   └── postmortems/   .gitkeep
│
└── projects/                                    ← 项目层
    ├── _archived/   .gitkeep
    └── .gitkeep
```

**合计**：3 根 + 30 agent + 22 skill + 5 hook + 6 rule + 9 template + 3 studio/docs + 45 engine-reference + 2 占位目录 ≈ **125 件**

> **注**：`art-asset-pipeline` 调用的 `.codebuddy/skills/timiai-image/` 已存在，**不计入 Phase 1 新建产出**。

#### 6.1.2 工作量分布（轮 A 分析 + 本轮微调）

| 类型 | 数量 | 单件工作量 |
|---|---|---|
| 纯 copy 上游（改 frontmatter / 路径）| ~65 | 极低（engine-specialist 15 + engine-reference 45 + template 部分 + agent 抄改）|
| copy + 轻改（工作室化 / v4 术语对齐）| ~35 | 低（skill 多数 + rule 部分）|
| 原创（/daily-check / /quick-fix / /new-project / art-asset-pipeline / art-director / acceptance-standards / language-policy / 3 条新 rule / PROJECT.md 模板）| ~12 | 中-高 |
| 深度改造（validate-commit.sh 拆极简版 / pre-commit-lite.sh 新版）| 2 | 中 |

→ **真正要动脑的 ~14 件**，其余机械性抄改。

#### 6.1.3 Phase 1 分步 step 清单

> ⚠️ Phase 1 期间**无 git 管理**。每 Step 完成后**不 commit**，改为在 `.codebuddy/plans/v4-migration-log.md` 追加一条完成记录（时间 / 自检结果 / 产出文件数）。

| Step | 内容 | 完成标志 |
|---|---|---|
| 1 | 建空目录骨架（studio/ projects/ .codebuddy/ 下 4 子目录）| 目录树符合 §6.1.1 |
| 2 | 起草 3 份工作室级文档（handbook / acceptance-standards / language-policy）| 3 文件存在、内容完整 |
| 3 | 起草 9 份 template | 全 9 份存在 |
| 4 | 起草 6 份 rule | 全 6 份存在 |
| 5 | 起草 22 份 skill（按"工作室级 8 → 项目级纯流程 9 → 带占位路由 4 → 美术资产 1"顺序）| 全 22 份存在，流程自洽 |
| 6 | 起草 30 份 agent（按"职务 5 → 代码 5 → engine-specialist 15 → 其他 5"顺序）| 全 30 份存在 |
| 7 | 起草 5 个 hook 脚本 | 全 5 份可跑 |
| 8 | copy 45 份 engine-reference 到 studio/docs/ | 全 45 份存在 |
| 9 | 起草根 README.md | 文件存在，含项目索引占位 |
| 10 | Phase 1 自检：跑 §9.2.1 通用 + 类型特异 checklist；扫所有产出确认无 `analysis-report/` `my-game/` 原路径引用；扫 `studio/reference/...` 引用全部就位等待 mv | 无引用悬空、无原路径引用、自检日志写入 v4-migration-log.md |

#### 6.1.4 Phase 1.5 现有资产归位操作手册

Phase 1 全部 10 个 Step 完成后，由**用户手动执行**以下操作（AI 不执行 mv）：

**Step A · 建参考区目录**（AI 在 Phase 1 Step 1 已建好 `studio/reference/` 空目录 + README.md，本步用户 verify）

**Step B · 移动 analysis-report**
```powershell
# Windows PowerShell
Move-Item -Path d:/AI/GameStudio/analysis-report -Destination d:/AI/GameStudio/studio/reference/analysis-report
```

**Step C · 移动 my-game**（注意它是独立 git 仓，mv 后 .git/ 一同移动，仓本身不受影响）
```powershell
Move-Item -Path d:/AI/GameStudio/my-game -Destination d:/AI/GameStudio/studio/reference/my-game
```

**Step D · 用户告诉 AI "已 mv"，AI 执行 verify**：
- AI 跑 `list_dir d:/AI/GameStudio/studio/reference/` 确认两个子目录就位
- AI 跑 `list_dir d:/AI/GameStudio/` 确认根目录无 `analysis-report/` 和 `my-game/` 残留
- AI 用 `search_content` 扫所有 Phase 1 产出，确认所有 `studio/reference/...` 引用现在都能命中实际文件
- AI 在 `.codebuddy/plans/v4-migration-log.md` 追加 Phase 1.5 完成记录

**Step E · Phase 1.5 完成 → 进入 Phase 2 第一个动作 git init**（详见 §8.3.2）

---

## 6.x（原 §6 粗描保留于此作为历史）

```text
（v2/v3 历史粗描，路径 / 数量 / Phase 划分均已被 §6 / §6.1 覆盖，仅供追溯）

Phase 1：工作室骨架
  ├─ 建 .codebuddy/（skills/hooks/rules/templates/agents 占位）
  ├─ 建 studio/ 最小版（docs/studio-handbook.md + postmortems/）
  ├─ 建 projects/ 空目录 + _archived/
  └─ 写工作室 README.md（含项目索引占位）

Phase 2：首个项目落地
  ├─ projects/<first>/ 按 §3.2 结构初始化
  ├─ 跑一次 /dev-story 重通道（validate 骨架）
  ├─ 跑一次 /quick-fix 轻通道（validate 快速路径）
  └─ 产出首份 consistency-report / ADR / sprint plan

Phase 3：支柱 3 定稿后补件
  ├─ 展开支柱 3（验收机制）
  ├─ 补 smoke-check 分级 / retrospective 跨 sprint
  └─ 根据验收机制调整 hook 严格度

Phase 4：P0 Release TODO 消化
  ├─ 4 个 release skill 上线
  ├─ validate-push.sh / validate-assets.sh
  └─ 维度 1 发行能力闭环
```

---

## 7. 附录：与 v1 / v2 / v3 的关键差异速查

| 项 | v1 MVS | v2 修订 | v3 单项目档 | **v4 孵化器**（本文档） |
|---|---|---|---|---|
| 资产总量 | 46 | 52 方案 | 52 | **125**（Phase 1 起草，含 engine-reference 45 + studio 扩展） |
| 必装 skill | 17 | 21 | 21 | **22**（v3 21 + art-asset-pipeline）|
| Hook | 4 | 5 | 5 | 5 |
| Rule | — | — | 5-6 | **6**（含 commit-discipline + language-policy）|
| Agent | — | — | 9-10 | **30**（含 engine-specialist 15 全备 + art-director）|
| 顶层模型 | 单项目 | 单项目 | 单项目 | **多项目孵化器** |
| `.codebuddy/` 位置 | 项目根 | 项目根 | 项目根 | **工作室根**（共享） |
| `studio/` 层 | 无 | 无 | 无 | **新增**（含 docs / reference / postmortems） |
| `projects/` 容器 | 无 | 无 | 无 | **新增** |
| `game/` 交付物聚合 | 无（src 散在根） | 无 | 无 | **新增** |
| `design/balance/` | 可选 | 可选 | 标配 | **取消**（并入 GDD + game/data） |
| GDD 小节强制性 | 8 节模板 | 8 节模板 | 8 节标配 | **示意非强制** |
| 双通道 | 无 | 无 | 有 | 有（不变） |
| Commit tag 4 类 | 无 | 无 | 有 | 有（不变） |
| 跨项目经验沉淀 | 无 | 无 | 无 | **新增**（studio/postmortems/） |
| 美术资产管线 | 无 | 无 | 无 | **新增**（art-asset-pipeline 调用 timiai-image） |

---

## 8. 工程基础设施决策

> **章节定位**
> - 本章收纳"非孵化器架构本身、但影响所有项目"的基础设施决策
> - 当前已锁：8.1 Git LFS 策略
> - 占位待展开：8.2 引擎选择 / 8.3 GitHub 仓库结构

### 8.1 Git LFS 策略（已锁）

**结论**：v4 阶段**不启用 LFS**，但 `projects/<p>/.gitattributes` 预置 LFS pattern；触发条件命中后再启用。

#### 8.1.1 为什么暂不开

| 因子 | 用户状况 | 对 LFS 的影响 |
|---|---|---|
| 团队规模 | 单人为主 | LFS 协作痛点不存在 |
| 异地开发 | 经常换电脑 | 多一道 LFS 安装步骤 |
| commit 频率 | 1-2 次/天 | 低频，二进制累积慢 |
| 引擎 | 未定 | 引擎选定前不预设 LFS 策略 |
| GitHub 计费 | 免费 1GB 存储 + 1GB/月流量 | 早开早烧钱（50GB 套餐 $5/月） |

#### 8.1.2 .gitattributes 预置内容（不立即启用）

每个 `projects/<p>/.gitattributes` 初始化时写入（写好但**先不 `git lfs install`**）：

```text
# 留作 LFS 候选，触发条件命中后 git lfs track + 启用
*.psd  filter=lfs diff=lfs merge=lfs -text
*.fbx  filter=lfs diff=lfs merge=lfs -text
*.wav  filter=lfs diff=lfs merge=lfs -text
*.mp3  filter=lfs diff=lfs merge=lfs -text
*.png  filter=lfs diff=lfs merge=lfs -text
# 注意：UI 小图标也是 png，开 LFS 后所有 png 都会走 LFS
```

#### 8.1.3 启用触发条件（任一命中即开）

1. 仓库 `.git/` 目录 > **500MB**
2. 单文件 > **50MB**
3. 选定 **Unity 引擎**（Unity 的 .asset / .meta 二进制 + 大美术几乎注定要 LFS）
4. GitHub 报警告（仓库 > 1GB）

#### 8.1.4 美术超 5GB 的替代方案

如果美术资源量级超过 5GB（GitHub LFS 计费会很痛），考虑替代方案：

```
projects/<p>/game/assets/    ← 软链接到 D:\GameAssets\<p>\
                                真实文件在工作室云盘 / 移动硬盘
```

- git 只管代码 + 数据 + 小图标
- 美术走另一条同步链路（OneDrive / 百度网盘 / 自建 S3）
- 适合：单人 + 美术包很大 + 不想付 LFS 费
- 不适合：多人协作（链路会乱）

具体方案触发时再讨论。

### 8.2 引擎选择（占位）

> **TODO（决策时机：Phase 2 第一个项目立项前）**
>
> 候选：
> - Unity（生态最大，美术/插件最丰富，但订阅 / 商业政策有变数；几乎注定要开 LFS）
> - Godot（开源免费，2D 极强；3D 与商业级品质有距离）
> - Unreal（视觉天花板；但学习曲线陡，单人工作室难驾驭）
> - 自研 / 轻框架（极致掌控，但拖慢原型速度）
>
> 决策需考量：项目类型 / 美术风格 / 团队技能 / LFS 联动（Unity → 必开 LFS）

### 8.3 仓库结构（已锁 · 轮 A）

**结论**：**方案 A 单 monorepo** — 在 `d:/AI/GameStudio/` 根目录直接 `git init`，首个项目和工作室能力升级**共用此仓**。开第二个项目时再评估是否拆仓。

#### 8.3.1 为什么选方案 A

| 因子 | 用户状况 | 对方案 A 的影响 |
|---|---|---|
| 项目数量 | 当前 0 个真实项目，1 年内预期 1 个 | 拆仓是过度设计 |
| 工作室能力迭代 | 与首个项目共同演化（新 skill / 新 rule 在项目实战中产生）| 同仓 commit 历史真实反映这种共演 |
| 协作者 | 单人 | 无跨仓同步压力 |
| LFS 计费 | Phase 2 选 Unity 才开 LFS | 单仓 LFS 计费集中管理更简单 |
| 现有 `my-game/` 嵌套 git 仓 | origin = CCGS 上游 | 通过 `.gitignore my-game/` 隔离，保留 upstream 拉取能力 |

#### 8.3.2 实施要点（Phase 2 第一个动作执行）

> ⚠️ **Phase 1 + Phase 1.5 期间无 git 管理**。git init 推迟到 Phase 1.5 归位完成后、Phase 2 启动时统一执行。理由：让 Phase 1 不被 commit 节奏打扰，让首次 commit 落到一个**已经包含 reference/ 归位结果**的最终结构上，避免基线不完整。

```bash
cd d:/AI/GameStudio/
git init
# .gitignore 至少包含：
#   studio/reference/my-game/      ← 嵌套 git 仓隔离（my-game 是独立仓，origin = CCGS 上游）
#   node_modules/
#   *.log
#   # studio/reference/analysis-report/ 是否纳入：默认纳入（参考资料随仓走）
git add .
git commit -m "[story] v4 工作室基线建立（含 reference 归位）"
git tag v4-foundation   # Phase 2+ 每次回滚的原点
```

> **回滚原点变更**：原 `pre-v4-migration` tag 概念废弃，新原点为 `v4-foundation`。Phase 1 和 Phase 1.5 期间的回滚靠用户压缩快照（详见 §9.2.5）。

#### 8.3.3 未来拆仓触发条件

当以下任一条件命中时，重新评估是否拆成 `studio-base` + `project-X` 多仓：

1. 开第二个真实项目时
2. 仓库 `.git/` 超过 2GB（即使开了 LFS 也过大）
3. 引入协作者（不同项目不同协作范围）
4. 单项目要独立发版 / 独立授权

### 8.4 未决 TODO（§8 范围内）

- [ ] §8.2 引擎选择（待 Phase 2 立项前）
- [x] §8.3 GitHub 仓库结构（已锁 · 方案 A 单 monorepo）
- [ ] CI/CD 策略（GitHub Actions 还是本地脚本？Phase 3-4 再定）
- [ ] 备份策略（除 GitHub 外是否做异地备份？用户已建立压缩快照习惯）

---

---

## 9. 迁移工程规约

> **章节定位**
> - 本章不是"架构决策"也不是"能力清单"，而是**迁移过程本身的纪律**
> - 目的：让迁移过程**稳定、可验证、风格统一**，避免跑到一半才发现文档风格乱、流程不自洽
> - 当前状态：9.1 / 9.2 / 9.3 全部已锁定

### 9.1 语言策略（已锁定 · v2）

> **来源**：用户迁移期要求 1
> **状态**：已锁定，Phase 1 轮 B 落盘到 `studio/docs/language-policy.md`（只落一份，同时服务人和 AI）
> **适用范围**：工作室全部产出物（skill / hook / rule / agent / template / plan / doc / GDD / ADR / retro / PROJECT.md / README）

#### 9.1.1 核心原则

**按 token 性质划分，不按文件类型划分**。一份文件内部中英自由混写：流程 / 产品 / 项目管理向 token 用中文；代码 token、AI 交接结构化 token、易错 token 用英文。

#### 9.1.2 七条规则

**规则 1 · 必须中文（流程 / 产品 / 项目管理向）**
- 叙述性文本：skill 说明 / 决策引导 / 避坑要点 / 场景描述 / 理由阐述
- 产品向内容：GDD 正文、玩法描述、用户故事叙述
- 项目管理向内容：ADR 正文、retro 记录、story 描述段落、automation 业务描述
- 面向人的标题、小节名、表格列标题
- 代码 / 命令的**中文注释**（注释服务于理解，中文优先）

**规则 2 · 必须英文（代码 / 结构化 / 易错 token）**
- 文件名、目录名：`dev-story/SKILL.md`、`engine-reference/godot/`
- 代码标识符：函数名、变量名、类名、参数名、hook 名、event 名
- 命令与路径：`git commit`、`npm run build`、`d:/AI/GameStudio/`
- 配置 key 与字段：frontmatter 的 `name` / `description` / `location`；JSON / YAML / TOML 的 key
- commit tag：`[story]` `[quick]` `[fix]` `[refactor]`
- HTTP / API / 错误码：`HTTP 429`、`ECONNRESET`、`/api/v3/images`
- Git 概念术语：`commit` `rebase` `tag` `HEAD` `merge`（有中文译法但易歧义，强制英文）
- AI 交接的结构化字段值：frontmatter enum 必须英文（`location: project` 而非 `location: 项目`）
- 模型名 / 产品代号 / 版本号：`gpt-image-2`、`Godot 5`、`Unreal 5.6`
- 代码向技术术语：`regex` `diff` `stdout` `stderr` `pipeline` `callback` `async` `await`（精度不够，强制英文、不翻译、不加释义）
- 易错字符串：ID、key、hash、UUID、版本号、时间戳格式

**规则 3 · 产品 / PM 术语的中英处理**
- 产品 / PM 术语：**中文优先，首次出现可加英文备注**
  - 例：`游戏设计文档（GDD）`、`架构决策记录（ADR）`、`最小可行产品（MVP）`
  - 之后段落直接用中文或纯英文缩写均可
- 代码向术语：**英文优先、不解释**
  - 例：`hook`、`skill`、`agent`、`subagent`、`frontmatter`、`glob`、`regex`
  - 禁止写"hook（钩子）"这种冗余释义
- `story` 作为通道 tag 保留英文；作为叙述名词（"这个用户故事是…"）用中文

**规则 4 · 中英混写的格式约束**
- 英文 token 用反引号包裹：`` `git commit -m "[story] xxx"` ``
- 中英之间用**半角空格**分隔：`这里调用 engine-specialist agent 完成` ✅ / `这里调用engine-specialist agent完成` ❌
- 标点切换：中文段落用中文标点（，。："）；英文代码块或英文短句内部用英文标点
- 表格列标题用中文；表格单元格内部 token 按规则 1 / 2 判断
- 列表项开头：中文主导段用中文引导（"要求：…"），纯代码清单用英文（`- frontmatter fields:`）

**规则 5 · 反模式清单（明确禁止）**
- ❌ 把 frontmatter 字段名翻译成中文（`description:` → `描述:`）
- ❌ 给代码向术语加冗余中文释义（`hook（钩子）`、`agent（代理）`）
- ❌ 按**文件类型**强制统一语言（"所有 skill 必须全中文" / "所有 agent 必须全英文"）
- ❌ 在 frontmatter 的 enum 字段里写中文值（`location: 项目`）
- ❌ 反复给 Git / HTTP / 代码向概念加中文释义（首次释义可以，之后段落不要重复）
- ❌ 中英之间漏空格（机器分词 / Markdown 渲染会歧义）

**规则 6 · 只落一份 policy**
- 落盘位置：`studio/docs/language-policy.md`
- 同时服务人和 AI，**不拆双版**
- 这份 policy 本身遵守自己的规则（中文主导、代码 token 英文），做自举示范
- `.codebuddy/rules/` 下**不再**放独立的 language-policy；相关 rule 只用一句 `> 本规则遵循 studio/docs/language-policy.md` 引用

**规则 7 · 门面文件纯中文主导**
以下文件面向人、阅读量最大，除必要代码 token 外尽量纯中文：
- `README.md`（工作室根 / 项目根）
- `studio/docs/studio-handbook.md`（工作室总览）
- `projects/*/PROJECT.md`（项目门面）
- `.codebuddy/plans/*.md`（迁移规划类文档）

这些文件里的代码 token、命令、文件路径照样英文（规则 2），但叙述必须纯中文，不出现整段英文技术描述。

#### 9.1.3 实施节奏

- **Phase 1 轮 B**：起草 `studio/docs/language-policy.md` 完整版（把 9.1.2 七条规则扩为可读文档 + 正反例）
- **Phase 1 所有产出**：起草时直接对齐本规范，不等 policy 文档落盘
- **Phase 2+**：新增产出同样遵循；违反规范在 retro 中记录并修正

### 9.2 迁移稳定性保障（已锁定 · v1）

> **来源**：用户迁移期要求 2
> **状态**：已锁定，Phase 1 轮 B 直接按本节执行
> **适用范围**：Phase 1 所有 10 个 Step + 轮 B 的 11.5 轮起草批次

#### 9.2.0 已落地的部分（不再讨论）

- ✅ Phase 0 现状盘点已产出（`studio/reference/analysis-report/current-state-inventory.md`，Phase 1.5 归位后路径）
- ✅ Pre-migration baseline 已由用户建立（工作区整体压缩快照，存工作区外 — Phase 1 + Phase 1.5 期间唯一回滚原点）
- ✅ Phase 1 期间现有内容"保持原位不动、Phase 1.5 由用户手动 mv 归位"原则已锁定
- ✅ git init 推迟到 **Phase 2 第一个动作**；首次大 commit + `git tag v4-foundation` 作为 Phase 2+ 每次回滚的原点

#### 9.2.1 Step 级自检 checklist

Phase 1 共 10 个 Step。每 Step 结束必须跑自检，通过后才能进入下一 Step。

**通用 checklist（每 Step 都跑）**
- [ ] 文件新增位置正确：只在 `.codebuddy/`、`studio/`、`projects/` 下新建，**绝不动** `analysis-report/` / `my-game/` / `.codebuddy/plans/`
- [ ] 命名规范：目录 / 文件名全英文小写 + hyphen，无空格、无中文文件名
- [ ] frontmatter 完整：`name` / `description` / `location` 齐，enum 符合规范
- [ ] 语言规范：对 §9.1 七条规则做一次粗扫（中英空格、反引号、无翻译 frontmatter）
- [ ] **Phase 1 路径约束 1**：本批产出**无**直接引用 `analysis-report/` 或 `my-game/` 原路径（用 `search_content` 扫两个字符串）
- [ ] **Phase 1 路径约束 2**：如必须引用，路径已写成未来位置 `studio/reference/analysis-report/...` 或 `studio/reference/my-game/...`
- [ ] **Phase 1 路径约束 3**：所有 `studio/reference/...` 引用点已标注 `[Phase 1.5 归位后生效]`（可在引用后加括号注释，或集中在文件末尾的 Known Limitations 里说明）
- [ ] Phase 1 期间**不 commit**：自检通过后在 `.codebuddy/plans/v4-migration-log.md` 追加一条记录（Step N / 时间 / 自检结果 / 产出文件数），**不**执行 `git commit`

**起草 skill 时额外检查**
- [ ] SKILL.md 有 description（说清"什么情况下加载本 skill"）
- [ ] 流程向 skill：流程闭环、有明确退出条件
- [ ] 引擎绑定 skill：Phase 1 只建流程骨架 + 引擎路由表，引擎具体知识放 `studio/docs/engine-reference/` 占位
- [ ] 对外引用的 skill / agent / rule 名称必须在清单内存在

**起草 hook 时额外检查**
- [ ] hook 脚本可执行（Windows 用 `pwsh`，跨平台用 `bash` + `.sh`）
- [ ] hook 不阻塞主流程超过 2 秒
- [ ] validate-commit.sh 类 hook 双通道逻辑正确（`[story]` vs `[quick]` `[fix]` `[refactor]`）

**起草 rule 时额外检查**
- [ ] rule 有明确适用范围（全工作室 / 单项目 / 某类 agent）
- [ ] rule 不与已有 rule 冲突

**起草 agent 时额外检查**
- [ ] agent 的 `subagent` 字段和调用方的 Task 参数一致
- [ ] agent 有明确的输入 / 输出格式约定
- [ ] 引擎类 agent 有对应的 `engine-reference/<engine>/` 占位路径

**起草 template 时额外检查**
- [ ] template 占位符用 `{{variable}}` 统一格式
- [ ] template 有使用说明（哪个 skill / agent 会消费它）

#### 9.2.2 批次级交叉引用闭合验证

Phase 1 每跑完 1 个 Step 或每批 4-6 件产出，跑一次引用闭合扫描。

**扫描对象**
1. skill 互引：skill A 说明里提到"调用 skill B"，B 必须存在
2. agent 互引：agent A 委托 agent B，B 必须存在
3. rule 引用：`> 本规则遵循 xxx.md` 的 xxx.md 必须存在或标为 Phase 2
4. template 消费：被某 skill / agent 引用，消费方必须存在
5. engine-reference 占位路由：路由到 `engine-reference/<engine>/<topic>.md` 的占位文件必须已创建
6. commit tag 引用：hook / rule 提到的 commit tag 必须在双通道定义内

**扫描手段**
- Phase 1 骨架期：AI 粗扫 + 人工抽查（产出量 125 件，可承受）
- Phase 2+：建 `/self-check` skill 自动扫（见 §9.2.4）

**悬空引用处理**
- **A 类 · Phase 1 范围内的**：立即补建
- **B 类 · Phase 2 才建的**：引用点标 `[Phase 2 TODO]`，占位文件写"Phase 2 待建"
- **C 类 · 无必要的**：从引用方删除

#### 9.2.3 轮 B 起草工作流（方案 B · 关键批 3 步回写）

> **概念澄清**：本节讲的是 Phase 1 轮 B **密集新建产出时的协作节奏**，不是 my-game → studio 的移植方案（移植方案见 §6）。

**分批节奏**

| 批次 | 起草产物 | 单轮时长 | 回写方式 |
|---|---|---|---|
| 批 1 · 目录骨架 | 空目录 + README 占位 | 0.5 轮 | AI 自主落盘 |
| 批 2 · language-policy | `studio/docs/language-policy.md` 完整版 | 1 轮 | **3 步回写**（是门面文件，用户全文 review）|
| 批 3-5 · skill 骨架 | 22 个 skill 的 SKILL.md（含 art-asset-pipeline）| 3 轮（前两轮 7 个，末轮 8 个） | AI 自主落盘 + 用户抽查 2-3 个 |
| 批 6 · hook 实现 | 5 个 hook（含可执行脚本） | 1 轮 | **3 步回写**（有代码风险，本地跑验证）|
| 批 7-8 · agent 骨架 | 30 个 agent（含 art-director）| 2 轮（每轮 15 个） | AI 自主落盘 + 用户抽查 5 个 |
| 批 9 · rule | 6 个 rule | 0.5 轮 | **3 步回写**（影响全工作室规则，用户全文 review）|
| 批 10 · template | 9 个 template | 0.5 轮 | AI 自主落盘 |
| 批 11 · engine-reference 占位 | 45 个占位文件 + 3 个引擎 README | 1 轮 | AI 自主落盘 |
| 批 12 · 收尾一致性扫 | 引用闭合扫描 + 修复 + Phase 1.5 归位准备 | 1 轮 | **3 步回写**（用户确认后写入 v4-migration-log.md 封版，**不 commit**，等 Phase 2 统一 init）|

共 ~11.5 轮。**3 步回写只用于 4 个关键批**（批 2 / 6 / 9 / 12），其余 7 个机械批 AI 自主落盘 + 事后抽查。

**3 步回写法**
1. AI 先出清单（本批要起草的文件列表 + 每个的 1 句话定位）
2. AI 逐一起草，起草完**不直接写文件**，先放在回复里
3. 用户确认 / 调整后，AI 用 write_to_file 批量落盘，然后在 `.codebuddy/plans/v4-migration-log.md` 追加批次完成记录（**Phase 1 期间不 commit，git init 在 Phase 2 才做**）

**AI 自主落盘法**
1. AI 出清单 → 直接落盘 → 在 `.codebuddy/plans/v4-migration-log.md` 追加批次记录 → 1 句话 summary
2. 用户事后抽查（建议每批抽 2-5 个）
3. 发现问题在下一轮开头说明，AI 立即修正

#### 9.2.4 工作室内部一致性 self-check

**Phase 1 不建独立 `/self-check` skill，推迟到 Phase 2**。

理由：
- Phase 1 产出量固定 ~125 件，人工 + AI 粗扫可承受
- self-check 本身依赖"已有完整产出清单"，Phase 1 结束才有
- Phase 1 用 "AI 读 §6.1.1 清单 + search_content" 粗扫即可

**Phase 1 的轻量扫描项**（AI 每批次级扫描时执行）
1. `search_content` 扫全部新产出里的 skill / agent / rule 名字，对照 §6.1.1 清单找悬空引用
2. `search_content` 扫 frontmatter enum 字段（`location:` `type:`），确认全英文
3. `search_content` 扫 `[Phase 2 TODO]` 标记，收集未来待建清单
4. `search_content` 扫 `analysis-report/` 和 `my-game/` 字符串出现位置（违反 §9.2.1 路径约束的产出立即修正）
5. `search_content` 扫 `[Phase 1.5 归位后生效]` 标记的引用点是否都改成 `studio/reference/...` 路径

**Phase 2 建 `/self-check` skill 时的职责**（预告，Phase 1 不实施）
- 跑完整引用闭合扫
- 跑语言规范静态检查（中英空格、反引号、frontmatter enum）
- 跑双通道 commit 分布统计（`[story]` / `[quick]` / `[fix]` / `[refactor]` 比例，**Phase 2 之后才有数据**）
- 输出一致性报告到 `studio/reference/analysis-report/self-check-YYYYMMDD.md`（Phase 1.5 归位后路径）

#### 9.2.5 紧急回滚触发条件

**通用触发条件**（任一命中即暂停迁移）：

1. **污染红线**：意外改到 `analysis-report/` / `my-game/` / `.codebuddy/plans/` 的已有文件
2. **悬空引用超过 10%**：某批产出后扫出的悬空引用占本批 >10%（起草时系统性缺参考）
3. **路径约束破例**：Phase 1 产出中出现直接引用 `analysis-report/` 或 `my-game/` 原路径（违反 §9.2.1 路径约束 1）
4. **内部矛盾严重**：连续 2 批扫出同类矛盾（规则本身有 bug）

**回滚方式按阶段不同**：

| 阶段 | 是否有 git | 回滚方式 |
|---|---|---|
| Phase 1（无 git） | 无 | **手动 + 快照恢复**：根据 `v4-migration-log.md` 反推动了哪些文件，手动删；严重时由用户解压 pre-migration 快照覆盖工作区 |
| Phase 1.5（无 git） | 无 | 同 Phase 1：归位失误时由用户手动 mv 回原位，或解压快照 |
| Phase 2+（已 git init） | 有 | `git reset --hard v4-foundation`（重回基线）；或 `git revert <批次 commit>`（只撤某一批） |

**Phase 1 / 1.5 回滚的额外注意**：
- 因为没有 git，AI 必须**严格**按 §9.2.1 通用 checklist 的"位置正确"条款执行，不允许跨界改文件
- 每 Step 完成后的 `v4-migration-log.md` 是手动反推的**唯一线索**，必须写清"本 Step 新建了哪些文件 / 修改了哪些已有文件"
- 用户的压缩快照是**最终保险**，迁移期间不要删除

### 9.3 现状盘点（已完成）

> 详见 `studio/reference/analysis-report/current-state-inventory.md`（Phase 1.5 归位后路径）
> Phase 1 期间该文件仍在 `analysis-report/current-state-inventory.md` 原位（不动）

**关键事实**（Phase 1 实施时必须记住）：
- F1：`d:/AI/GameStudio/` 根目录**无 `.git/`** — git init 推迟到 **Phase 2** 第一个动作
- F2：`my-game/` 是**独立 git 仓**（origin = CCGS 上游 Donchitos/Claude-Code-Game-Studios）— Phase 1.5 mv 到 `studio/reference/my-game/` 后 `.gitignore` 隔离
- F3：`my-game/` 无用户自己的 commit — 它等于纯净 CCGS v1.0 模板
- F4：CCGS 框架本体在 `my-game/.claude/` — Phase 1 是抄改源头（Phase 1 期间访问 `my-game/.claude/`，Phase 1.5 后访问 `studio/reference/my-game/.claude/`）
- F5：`analysis-report/` 是最珍贵的原创资产（v1 → v2 已修订，22 份 md）— Phase 1.5 归位到 `studio/reference/analysis-report/`
- F6：`.codebuddy/plans/` 已存 5 份 plan artifact — Phase 1 只在 `.codebuddy/` **同级加新子目录**（agents/ skills/ hooks/ rules/ templates/），**绝不动 plans/**
- F7（新）：Phase 1 期间 `analysis-report/` 和 `my-game/` **保持原位不动**，但 Phase 1 产出**不引用**这两个原路径，必要引用直接写 `studio/reference/...` 未来位置

### 9.4 未决 TODO（§9 范围内）

- [x] §9.1 语言策略（2026-05-13 锁定 v2，7 条规则 + 只落一份 policy）
- [x] §9.2 迁移稳定性保障（2026-05-13 锁定 v1，Step/批次/工作流/self-check/回滚五节）
- [x] §9.3 现状盘点（含 Phase 1.5 归位事实 F7）
- [x] 轮 B 密集起草的分批节奏（已在 §9.2.3 定稿：11.5 轮 / 12 批 / 方案 B 关键批 3 步回写）

---

**文档结束**。支柱 1/2/3 + §8.1 LFS + §8.3 仓库结构 + §6 Phase 0-5（含 Phase 1.5 归位）+ §6.1 Phase 1 范围（125 件 + art 管线）+ §9 迁移工程规约（9.1 / 9.2 / 9.3）已全部锁定。后续展开方向：Phase 1 轮 B 密集起草（约 11.5 轮，无 git，写 v4-migration-log.md）→ Phase 1.5 用户手动 mv 归位 → Phase 2 git init + tag v4-foundation。
