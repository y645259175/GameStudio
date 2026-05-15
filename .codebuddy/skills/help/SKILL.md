---
name: help
description: Capability catalog and "what can I do" guide. Use when the user asks "有哪些 skill / 能做什么 / how do I / 这个 skill 是干嘛的 / 列一下能力 / list capabilities / show commands". Reads current phase, lists relevant skills/agents/rules, distinguishes REQUIRED vs OPTIONAL next steps.
allowed-tools: read_file, list_dir, search_content
disable: false
---

# help · 能力索引与说明书

## 何时加载

- 用户问"有哪些能力 / 能做什么 / 怎么用"
- 用户想了解某个具体 skill / agent / rule 的用途
- 用户卡在流程中不知道下一步该用什么

**不加载场景**：用户已经知道要做什么（直接走那个 skill）；用户问"开始吧"（走 `start`）。

## 输入契约

| 输入 | 来源 |
|---|---|
| 用户的查询关键词（可选）| 当前消息 |
| 当前项目 phase | `projects/<name>/PROJECT.md` |
| 已有产物清单 | 项目目录扫描 |

## 流程

### Step 1 · 范围识别

判断用户问的是：
- **A 全局清单**：列出所有 22 skill / 30 agent / 6 rule
- **B 阶段相关**：根据当前 phase（concept/design/dev/test/release）筛选
- **C 单项详情**：解释某个具体 skill/agent/rule 用法

### Step 2 · 信息组织

按下表输出（中文）：

| 类别 | 数量 | 关键代表 |
|---|---|---|
| skill | 22 | start / new-project / design-review / dev-story / smoke-check |
| agent | 30 | producer / pm / architect / engineer / qa-lead |
| rule | 6 | project-structure / commit-discipline / language-policy |
| template | 9 | gdd-skeleton / sprint-plan / retro / adr |

### Step 3 · REQUIRED vs OPTIONAL 区分

读 `projects/<name>/PROJECT.md` 的 `phase`，按 `studio/docs/workflow-guide.md` 给出：
- **REQUIRED 下一步**（流程必须走的）
- **OPTIONAL 加分项**（推荐但非必须）

### Step 4 · 输出

- 用 markdown 表格给出能力清单
- 每个能力一句话描述 + 触发关键词
- 必要时给一个最小调用示例

## 输出契约

| 字段 | 内容 |
|---|---|
| `verdict` | `INFO_DELIVERED` |
| `phase` | 当前项目所处 phase（若有项目）|
| `required_next` | REQUIRED 下一步 skill 列表 |
| `optional_next` | OPTIONAL 加分项 |

## 调用的 agent / rule

- agent：无
- rule：`project-structure`（识别工作区结构）

## 失败 / 降级

| 异常 | 策略 |
|---|---|
| 用户询问不存在的 skill | 模糊匹配 + 推荐最相近的 3 个 |
| `studio/docs/workflow-guide.md` 不存在 | 仅给静态清单，不做阶段化推荐 |

## 验收标准

- 用户查询后能在 1 轮内拿到清单 + 推荐
- 推荐的"REQUIRED 下一步"准确反映流程文档

## Known Limitations

- 当前清单写在 SKILL.md 中，新增能力需手动同步（Phase 2 评估自动扫描 `.codebuddy/` 生成）
