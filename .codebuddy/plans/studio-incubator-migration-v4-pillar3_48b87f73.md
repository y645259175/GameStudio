---
name: studio-incubator-migration-v4-pillar3
overview: 把支柱 3（验收机制）的 7 个锁定决策 + §8 工程基础设施决策（LFS 写实，引擎/仓库结构占位）一次性落盘到主文档 studio-incubator-migration-v4_4b2c7a91.md，替换原有 §4 占位，新增 §8。
todos:
  - id: reread-doc
    content: 读 §4 占位段和文档末尾，确认锚点行 + 当前 TOC 结构
    status: completed
  - id: draft-section-4
    content: 起草 §4 完整内容（4.1 摘要表 + 4.2-4.7 七小节，覆盖 Q1-Q7 决策卡片 + 简短理由）
    status: completed
    dependencies:
      - reread-doc
  - id: draft-section-8
    content: 起草 §8 完整内容（8.1 LFS 写实 + 8.2/8.3 占位 TODO）
    status: completed
    dependencies:
      - reread-doc
  - id: apply-edits
    content: 把 §4 改写 + §8 追加 + TOC 同步落盘到主文档
    status: completed
    dependencies:
      - draft-section-4
      - draft-section-8
  - id: verify-result
    content: 复核改后文档：章节齐整、Q1-Q7 全覆盖、未引入新决策、未碰其他章节
    status: completed
    dependencies:
      - apply-edits
---

## 用户诉求

将 v4 迁移文档「支柱 3：验收机制」整体落盘，并新建 §8「工程基础设施决策」章节。本轮已通过两批问答锁定 7 项决策 + LFS 归属，现需把决策结论写入主文档。

## 核心内容

- 改写 §4「验收机制 v4」：从占位状态升级为完整章节，覆盖 Q1-Q7 全部决策结论 + 简短理由
- 新建 §8「工程基础设施决策」：LFS 策略写实（含触发条件），引擎选择 / GitHub 仓库结构建占位标 TODO
- 文档目录 / 章节索引（如有）同步更新

## 落盘内容范围

### §4 必须覆盖

- Q1 混合分层（工作室底线 + 项目加码）
- Q2 4 个验收时机：A 极简 pre-commit / E 手动 /daily-check 日终 / C sprint 末 / D 里程碑（B pre-push 暂不开，注明理由）
- Q3 双通道差异：[story] 完整验收 / [quick] 仅基础校验 / [fix][refactor] 仅基础校验
- Q4 velocity 5 数并列（[story]/[quick]/[fix]/[refactor]/总 commit），不加权
- Q5 consistency-check 触发点：/dev-story 内 + sprint 末
- Q6 里程碑 4 级：demo-ready / alpha / beta / release，每级 AI 出报告 + 用户拍板
- Q7 工作室底线 6 条全列（A-F 逐条保留原文）

### §8 必须覆盖

- LFS 策略：v4 不启用 + .gitattributes 预置 pattern + 4 条触发条件 + 美术超 5GB 的替代方案
- 引擎选择 TODO：决策时机=Phase 2 第一个项目立项前
- GitHub 仓库结构 TODO：决策时机=Phase 1 落地前

## 边界

- §1/§2/§3/§5/§6/§7 全部不动
- plan artifact `_b275834d.md` 不动
- 落盘风格：中文为主，决策可追溯（保留为什么这样选），不展开成教程

## 任务类型

纯文档维护任务，无代码改动。目标文件为单一 markdown：

- `d:\AI\GameStudio\.codebuddy\plans\studio-incubator-migration-v4_4b2c7a91.md`（308 行，14.4 KB）

## 实施策略

### 修改方式

采用「定位锚点 + 局部替换 / 追加」的方式，最小化触动范围：

1. **§4 改写**：先 read_file 定位 §4 起止行号（含原 6 条 TODO 占位），用整段替换写入新内容
2. **§8 新增**：定位文档末尾（§7 之后），在合适位置追加 §8 整章
3. **目录同步**：若文档头部存在 TOC / 章节索引，同步把 §8 加入；不存在则跳过

### 内容组织原则

- **决策卡片格式**：每个 Q 用「锁定结论 / 理由 / 落地约束」三段式呈现，便于追溯
- **保留措辞一致性**：沿用原 v4 文档的"双通道""支柱""底线"等术语，不引入新词
- **TODO 显式化**：§8 占位项用 `> TODO（决策时机：xxx）` 块引格式，与原文档 TODO 风格一致
- **未决清单兜底**：§4 / §8 末尾若仍有未定项，列出 `### 未决 TODO` 小节

### §4 文档骨架（落盘后结构）

```
## §4 支柱 3：验收机制 v4

### 4.1 总览（决策摘要表，Q1-Q7 一行一条）

### 4.2 验收粒度：混合分层（Q1）
  - 工作室底线（6 条 A-F 全列）
  - 项目级加码示例

### 4.3 验收时机（Q2 + Q3）
  - A. pre-commit 极简版（每 commit 自动）
  - E. /daily-check 日终（手动，新增）
  - C. sprint 末（手动）
  - D. 里程碑（手动，4 级）
  - 双通道差异说明（Q3）
  - 为什么不开 pre-push（Q2-B）

### 4.4 度量：双指标并列（Q4）
  - 5 个数据并列：[story]/[quick]/[fix]/[refactor]/总 commit
  - 用途：retro 客观依据 / 阶段切换信号 / AI agent 输入

### 4.5 关键 skill 触发矩阵（Q5）
  - consistency-check：/dev-story + sprint 末
  - validate-commit：pre-commit
  - smoke-check：sprint 末
  - release-checklist：里程碑

### 4.6 里程碑 4 级（Q6）
  - demo-ready / alpha / beta / release，每级判据 + 拍板人

### 4.7 未决 TODO（如有）
```

### §8 文档骨架

```
## §8 工程基础设施决策

### 8.1 Git LFS 策略（已决）
  - 结论：v4 不启用，.gitattributes 预置 pattern
  - 4 条触发条件
  - 美术超 5GB 替代方案

### 8.2 引擎选择（占位）
  - TODO 决策时机：Phase 2 第一个项目立项前
  - 候选：Unity / Godot / Unreal / 自研

### 8.3 GitHub 仓库结构（占位）
  - TODO 决策时机：Phase 1 落地前
  - 候选：单 monorepo / 每项目独立仓
```

## 实施注意点

- **幂等性**：本轮落盘前应再 read_file 一次确认 §4 仍是占位状态，避免覆盖已有内容
- **行号漂移**：用文本锚点（如 `## §4` 或 `## §8` 标题行）定位，不用绝对行号
- **不引入新决策**：本次只做"已锁定结论 → 文档"的搬运 + 整理，不在写文档过程中创造新选项
- **结论可追溯**：每个决策保留"为什么这样选"的 1-2 行理由（来自前几轮讨论），便于半年后回看

## 目录结构（待修改）

```
d:\AI\GameStudio\
└── .codebuddy\
    └── plans\
        ├── studio-incubator-migration-v4_4b2c7a91.md  # [MODIFY] 主迁移文档
        │   ├── §4 验收机制 v4                          # [REWRITE] 占位 → 完整内容
        │   └── §8 工程基础设施决策                      # [NEW] 新增整章（LFS 实 + 2 项占位）
        └── studio-incubator-migration-v4_b275834d.md   # [UNTOUCHED] plan artifact，不动
```