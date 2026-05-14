# Current State Inventory — d:/AI/GameStudio

> **目的**：v4 迁移规划落地前的"事实底座"。盘点当前工作区**有什么 / 是什么 / 对迁移的归宿建议**。
> **生成时间**：2026-05-13
> **生成方式**：扫描目录树 + 抽样关键文件 + 检查 git / 远端
> **状态**：草稿，等待用户对每条"归宿建议"拍板（A1 仓库结构 / A5 `.codebuddy/` 保留策略两轮讨论的输入）

---

## 0. 一图看懂

```
d:\AI\GameStudio\                  ← workspace 根，无 .git（关键事实）
├── .codebuddy/                    ← CodeBuddy IDE 工作区（plans + 记忆）
│   └── plans/                     ← 5 份 plan artifact（含本次 v4 主文档）
│
├── analysis-report/               ← 5 册 CCGS 深度分析 + v1 归档 + 修订过程产物
│   ├── 00_README.md ~ 05_*.md     ← v2 现行版（5 册 + 总索引 + 1b 差距分析）
│   ├── v1-archive/                ← v1 全套归档（只读）
│   └── _revision-tmp/             ← 修订期 consistency-check 过程产物
│
└── my-game/                       ← 独立 git 仓（origin = Donchitos/Claude-Code-Game-Studios）
    ├── .git/                      ← 真正的 git 仓在这里
    ├── .claude/                   ← CCGS 框架本体（agents/skills/hooks/rules/...）
    ├── design/   docs/   src/     ← CCGS 模板项目骨架（CLAUDE.md 指引为主，几乎没真实代码）
    ├── production/                ← 几乎空（仅 session-state/）
    ├── CCGS Skill Testing Framework/  ← CCGS 自带的 meta 测试框架（127 文件）
    └── README.md / CLAUDE.md / UPGRADING.md / LICENSE
```

---

## 1. 关键事实（影响迁移策略的硬条件）

| # | 事实 | 对迁移的影响 |
|---|---|---|
| **F1** | **`d:/AI/GameStudio/` 根目录无 `.git/`** | 当前工作区**不是一个 git 仓**。`analysis-report/` 和 `.codebuddy/` 完全未受版本控制 |
| **F2** | **`my-game/` 是独立 git 仓**，origin 指向 `github.com/Donchitos/Claude-Code-Game-Studios.git` | `my-game/` 是 CCGS 上游模板的 fork/clone，**不是用户自己的项目仓**。用户对它做的修改若 push 会推到 CCGS 上游（除非改 origin） |
| **F3** | `my-game/` 最近 commit 全是上游修复（`Fix architecture-decision skill...` #45 等） | 用户在 `my-game/` 上**没有自己的提交**。当前 `my-game/` ≈ 纯净的 CCGS v1.0 模板 |
| **F4** | `my-game/.claude/` 完整存在（agents/skills/hooks/rules/docs/agent-memory + settings.json + statusline.sh） | CCGS 框架本体**就在这里**，是 §4 / §8 反复引用的"目标态参照" |
| **F5** | `analysis-report/` 是用户自己产出的 22 份 md，已通过 v1 → v2 修订流程，**有完整的 v1-archive/ 备份惯例** | 这套资产**最有价值**也最不容许丢失。v4 迁移要继承这种"修订前先归档"的做法 |
| **F6** | `.codebuddy/plans/` 已存 5 份 plan artifact | 这些是 CodeBuddy IDE 自己管理的会话产物，**重建 `.codebuddy/` 时不能动** |

---

## 2. 逐目录盘点

### 2.1 `d:/AI/GameStudio/.codebuddy/`（IDE 工作区，**保留**）

| 子项 | 内容 | 用途 | 归宿建议 |
|---|---|---|---|
| `plans/analysis-report-v2-revision_08399d50.md` | 已完成（v1→v2 修订）| 历史 plan | **保留**（IDE 管理） |
| `plans/ccgs-deep-analysis-report_6aec7e96.md` | 已完成（5 册分析）| 历史 plan | **保留** |
| `plans/studio-incubator-migration-v4_b275834d.md` | 主 plan 早期版 | 历史快照 | **保留**（追溯用） |
| `plans/studio-incubator-migration-v4_4b2c7a91.md` | **本轮主文档**（v4 plan，含 §1-§8） | 当前活跃决策记录 | **保留 + 持续编辑** |
| `plans/studio-incubator-migration-v4-pillar3_48b87f73.md` | 支柱 3 落盘子 plan | 已完成 | **保留** |

**结论**：整个 `.codebuddy/` **不动**。Phase 1 即使重建工作室骨架，也只是在工作区**加** `studio/` `projects/` 等同级目录，不替换 `.codebuddy/`。

⚠️ A5 待决：本工作区会不会**新建一个** `.codebuddy/agents/` `.codebuddy/skills/` 等（v4 工作室级 skill / agent 安装位置）？这些**新加**的子目录与现有 `plans/` 共存即可，但要在 §9 显式写明"不动 plans/，只在 .codebuddy/ 下加 agents/skills/hooks/rules/ 等子目录"。

---

### 2.2 `d:/AI/GameStudio/analysis-report/`（用户原创知识产物，**保留 + 长期引用**）

| 文件 / 目录 | 性质 | 字符 | 归宿建议 |
|---|---|---|---|
| `00_README.md` ~ `05_*.md`（共 7 份现行 v2 文档） | 用户原创：CCGS 深度分析 + CodeBuddy 移植建议 | 决策依据 | **保留原位**，作为 v4 plan 长期引用源 |
| `v1-archive/` | v1 完整归档（7 文件 + README） | 历史只读 | **保留** |
| `_revision-tmp/` | 修订期过程产物（6 份 consistency-check + final report）| 过程性 | **建议归档**：迁后挪到 `studio/postmortems/2026-05-analysis-report-v2-revision/` 或保留原位标 archive |
| `current-state-inventory.md`（本文件） | 迁移 baseline | 长期参考 | **保留原位** |

**结论**：`analysis-report/` 是**最珍贵的资产**，必须有显式的备份机制（详见 §3 baseline）。

⚠️ 命名问题：`analysis-report/` 这个目录名相对未来 v4 工作室骨架是"非标位置"。**v4 落地后，建议挪到 `studio/research/ccgs-analysis-v2/` 或 `studio/docs/ccgs-analysis/`，但不在 Phase 1 做**（避免一上来就动核心资产）。

---

### 2.3 `d:/AI/GameStudio/my-game/`（CCGS 上游模板的 clone，**保留但定位调整**）

| 子项 | 内容 | 是否用户原创 | 归宿建议 |
|---|---|---|---|
| `.git/` + remote = Donchitos/CCGS | 上游 fork | ❌ 上游 | **保留**，但**不要 push**（除非改 origin 到自己的仓）。**永远不在 my-game/ 里写自己的项目代码** |
| `.claude/` | CCGS 框架本体（agents/skills/hooks/rules）| ❌ 上游 | **保留作为"参照样本"**，不动 |
| `CLAUDE.md` / `README.md` / `UPGRADING.md` / `LICENSE` | 上游 | ❌ | **保留** |
| `design/` | 仅含 `CLAUDE.md` 指引（说明 GDD 8 节规范），无真实 GDD | ❌ | **保留作为模板参考**。v4 项目自己的 GDD 写在 `projects/<p>/design/gdd/` |
| `docs/` | engine-reference/（46 文件，引擎 API 参考）+ examples/（11 文件）+ COLLABORATIVE-DESIGN-PRINCIPLE.md / WORKFLOW-GUIDE.md | ❌ 上游 | **保留**。其中 `engine-reference/` 在选定引擎后**可能复用**到项目 |
| `src/` | 仅含 `CLAUDE.md` 指引，无真实代码 | ❌ | **保留** |
| `production/session-state/` | 几乎空 | ❌ | **保留** |
| `CCGS Skill Testing Framework/` | 127 文件，meta 测试框架（agents/skills 的行为规格）| ❌ 上游 | **保留作为参考**，自建 skill 时可借鉴 quality-rubric |

**关键定位**：
- ✅ `my-game/` = **「CCGS 模板参考库」**，类似 `node_modules/` 的角色——可以读、可以抄、不在里面写业务
- ❌ 不要把它当成"我的第一个项目"——它是上游模板
- 用户的真实项目要建在新位置（详见 §4 仓库结构候选）

⚠️ 命名问题：`my-game/` 这名字会误导人以为是某个具体游戏。**v4 落地后建议改名为 `_ccgs-reference/` 或 `vendor/ccgs/`，明确"参考库"性质**。改名时机：A1 仓库结构敲定时一并定。

---

## 3. 迁移 baseline（Pre-migration 必做的固化动作）

为满足"迁移过程稳定性"要求（§9.2 核心议题），以下动作建议在 **Phase 1 第一步之前**完成：

| # | 动作 | 目标 | 何时做 |
|---|---|---|---|
| **B1** | 把 `d:/AI/GameStudio/` 整体打 zip 快照（含 `.codebuddy/` `analysis-report/` `my-game/`），存到工作区**外**位置（如 `D:\Backup\GameStudio-pre-v4-20260513.zip`）| 物理回滚保险 | A1 拍板后立即做 |
| **B2** | 在 `analysis-report/` 创建一份 `migration-baseline.md`，记录：当前 7 份 md 的字数 / md5 / git log 末位 commit | 数据保真 baseline | 同 B1 |
| **B3** | 决定 `d:/AI/GameStudio/` 是否要变成 git 仓（A1 议题）| 让 `.codebuddy/` `analysis-report/` 也被版本管理 | A1 讨论时定 |
| **B4** | 若 B3 = 是，在仓建立后立即 `git tag pre-v4-migration`，作为后续每批迁移的"原点" | 提供精确回滚锚点 | B3 决策后立即 |

---

## 4. A1 仓库结构候选（基于盘点的事实重新审视）

§8.3 原 3 候选（A 单 monorepo / B 每项目独立仓 + 基座 / C monorepo + sparse checkout）需要**结合事实 F1-F6 重新看**：

### 候选 A · 单 monorepo（在 d:/AI/GameStudio/ 直接 git init）

```
d:/AI/GameStudio/         ← 新建 .git
├── .codebuddy/           ← 已存（保留）
├── studio/               ← 新建（工作室级文档 + skill）
├── projects/             ← 新建（每个项目一个子目录）
│   └── _archived/
├── vendor/
│   └── ccgs/             ← 由 my-game/ 改名而来（CCGS 参考库）
├── studio/research/
│   └── ccgs-analysis-v2/ ← 由 analysis-report/ 迁移而来（**Phase 后期**做，不 Phase 1 做）
└── README.md
```

**优点**：
- 与 `my-game/` 的子仓嵌套问题可以通过 git submodule **或** 干脆删掉它的 `.git/`（vendor 化）来解决
- `analysis-report/` `.codebuddy/` 自动纳管
- 单仓最简单，符合单人工作流

**缺点 / 决策点**：
- `my-game/.git` 怎么处理？保留 submodule 还是吃成普通目录？
- `analysis-report/` 22 份 md 的字数不小，影响仓库初始大小（但都是文本，不是问题）

### 候选 B · 每项目独立仓 + 基座仓

```
d:/AI/GameStudio/                  ← 不 git init，仅作工作区文件夹
├── studio-base/                   ← 独立仓（工作室基座 + .codebuddy/ + studio/）
├── projects/
│   ├── projectA/                  ← 独立仓
│   └── projectB/                  ← 独立仓
└── vendor/ccgs/                   ← 现 my-game/，保持现状或改名
```

**优点**：项目仓体积可控
**缺点**：基座更新要同步推到所有项目仓；`analysis-report/` 不知道挂哪
**评分**：在"单人 + 当前只有 0 个真实项目"的场景下，**收益小于成本**

### 候选 C · monorepo + sparse checkout

复杂度对单人过高，不展开。

### 候选 D（新增）· 双仓：工作室仓 + my-game 保持独立

```
d:/AI/GameStudio/                  ← git init（工作室仓）
├── .codebuddy/
├── studio/
├── projects/
├── analysis-report/
└── README.md

d:/AI/GameStudio/my-game/          ← 保持独立仓（gitignored 在工作室仓里）
```

**优点**：
- `my-game/` 完全保留 CCGS upstream 拉取能力（git remote = Donchitos）
- 工作室仓干净，不背 CCGS 模板代码
- 实施最简单：工作室仓的 `.gitignore` 加 `my-game/` 一行即可

**缺点**：
- `my-game/` 本质是参考资产，不被工作室仓追踪意味着"贡献者拿到工作室仓后还要单独 clone CCGS"——对单人不是问题
- 心智上要记住"两个仓不是一个东西"

**我的初步偏好**：**候选 D**。理由：
1. 它最尊重事实（`my-game/` 已经是独立仓 + upstream，硬合并反而破坏可追踪性）
2. 它最便宜（工作室仓 git init + .gitignore my-game/ = 5 分钟）
3. 它最稳（不动 my-game 一根毫毛）
4. 它最灵活（未来要不要把 my-game vendor 化随时再决定）

但这是 A1 的议题，留给下一轮讨论时你拍板。

---

## 5. 对 v4 plan §6 迁移路径的影响

§6 原 Phase 1 = "建立 studio/ 骨架"，但盘点后发现还得加 Phase 0：

| 阶段 | 原计划 | 盘点后修订建议 |
|---|---|---|
| **Phase 0**（新增）| 无 | **Pre-migration baseline**：B1-B4 + A1 拍板 + 现状盘点签字（即本文件 review 通过）|
| **Phase 1** | 建 studio/ 骨架 | 不变，但前置 Phase 0 |
| **Phase 2** | 首个项目落地 | 不变 |
| Phase 3-5 | … | 不变 |

---

## 6. 待用户拍板的清单（A 类阻塞项）

| ID | 议题 | 何时拍 |
|---|---|---|
| **A1** | 仓库结构（候选 A/B/C/D 选一）+ my-game/ 改名与否 | 下一轮 |
| **A4** | 本盘点报告是否准确？是否还要补哪些事实？ | 阅读本文件后立即反馈 |
| **A5** | `.codebuddy/` 加新子目录（agents/skills 等）的策略：是直接加还是先备份？plans/ 子目录是否绝对禁止改动？ | 下一轮，与 A1 一起 |
| **A2** | 迁移稳定性详细机制（B1-B4 是否够 + 每批节点验证 checklist）| 单开一轮 §9.2 |
| **A3** | 语言策略 §9.1 详细规约 | 单开一轮 §9.1 |

---

## 7. 现状一句话总结

> 当前 `d:/AI/GameStudio/` 是一个**"非 git 工作区"**，里面套了**一个独立 git 仓 `my-game/`（CCGS 上游 fork）**，加上**用户原创的 `analysis-report/`（v2 已修订）+ IDE 自管的 `.codebuddy/`（含本次 v4 plan）**。最珍贵的资产是 `analysis-report/`，最容易误判的事实是 "my-game 是上游 fork、不是我的项目"。
