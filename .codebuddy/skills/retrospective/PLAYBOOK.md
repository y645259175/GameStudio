---
name: retrospective
type: skill
status: active
description: Sprint retrospective facilitator that produces a postmortem capturing what went well, what hurt, and action items.
---

# Retrospective · Sprint 复盘

## 何时使用

sprint 结束后或重大事故后，用于沉淀经验、回写工作室级 postmortem。对应 v4 §6.1.1 工作室级 8。

典型触发：
- sprint 末（紧跟 `smoke-check` 之后）
- 出现严重 bug / 阻塞 / 返工后
- 用户主动调用："做个复盘"

## 输入 / 触发条件

- 当前项目根
- sprint 范围（如 sprint 末）或事故时间窗
- 相关 commits / stories / daily-reports / smoke-check 报告

## 流程步骤

1. **触发判断**：是 sprint retro 还是事故 retro？两类模板不同
2. **数据收集**：拉相关 commits / stories / 报告，AI 列出"事实清单"
3. **三问引导**（中文交互）：
   - 哪些做得好？
   - 哪些卡住了 / 痛？
   - 下一阶段要改什么（≤ 3 条 action items）
4. **回填模板**：按 `templates/retro.md.tpl` 填空
5. **双层落盘**：
   - 项目级：`projects/<name>/retros/sprint-N-retro.md`
   - 工作室级：如经验跨项目复用，**用户确认后**抽提到 `studio/postmortems/YYYY-MM-DD-<topic>.md`
6. **action items 路由**：每条 action 路由到具体 skill / rule 修订计划
7. **agent 知识总结（combo-B M5 新增）**：
   识别本阶段触发的核心 agent（engineer / reviewer / designer / art-director / qa-lead），对每个 agent：
   - 扫描其 `playbook.md` 待消化素材区
   - 如有素材 → 发起知识总结流程（见下 §知识总结 SOP）
   - 如无素材 → 跳过

## 知识总结 SOP（combo-B M5 新增）

> **触发**：retrospective 流程 §7 或 main agent 判断"阶段性任务完成"时手动触发
> **目的**：把 playbook 临时缓冲区的原始素材精炼为可复用知识，并入 AGENT.md 本体

### 流程

1. **读 playbook.md 待消化素材区** → 列出所有条目
2. **逐条筛选**（subagent + main agent 共同判定，不确定问用户）：
   - ✅ 可复用（不依赖特定项目细节）？
   - ✅ 非特定场景（在新项目也适用）？
   - ✅ 不与 AGENT.md 已有知识 / 其他 agent 产出契约矛盾？
   - 3 条全过 → 进入精炼步骤
   - 任一不过 → 删除该条目（或保留但标注"项目特定 · 不并入"）
3. **精炼措辞**：把原始素材改写为：
   - 1-3 句话的通用规则
   - 含"触发条件"（什么时候适用）
   - 含"做法"（怎么做）
   - 不含项目名 / sprint 编号 / 具体日期
4. **并入 AGENT.md 本体**：
   - 写入 AGENT.md 的合适段落（如 §历史教训 / §视觉资产红线 / 新建段落）
   - 确保与已有内容不重复、不矛盾
5. **清理 playbook**：
   - 已并入的条目从待消化区**删除**
   - 在"已并入 AGENT.md 本体的条目"区追加记录（日期 + 一句话 + 位置）
6. **验证**：
   - read_file AGENT.md 确认新内容已存在
   - 确认 playbook 待消化区已清空（或仅剩未通过筛选的标注条目）

### 筛选决策示例

| 原始素材 | 筛选结果 | 理由 |
|---|---|---|
| "platformer-2 的 jump_height 200px 在 144fps 下不稳" | ❌ 不并入 | 项目特定数值 |
| "帧率无关跳跃公式应使用 delta-time 而非固定值" | ✅ 并入 | 通用规则 |
| "bolt-1-1 M6.2 的 4 帧用了 text2image 导致不一致" | ❌ 不并入 | 项目特定事件 |
| "多帧资产必须先 AD-CHAR-KEY 评审通过再派生" | ✅ 并入 | 通用 SOP |

### 不确定时的升级路径

- subagent 不确定"是否通用" → 问 main agent
- main agent 也不确定 → 问用户（简短提问："`<条目摘要>` 这条经验是否通用到值得永久并入 agent 知识？"）
- 用户说 yes → 并入
- 用户说 no → 删除或标注"项目特定"

## 输出

- 项目级 retro 报告
- 可选：工作室级 postmortem
- action items 清单（带责任 skill / rule）

## 引用

- 上游规划：v4 §6.1.1、`studio/postmortems/`
- 相关 skill：`smoke-check` `consistency-check`
- 相关 template：`templates/retro.md.tpl`

## Known Limitations / Phase 2 Review Points

- [Phase 2 TODO] "经验是否跨项目复用"的判据靠用户拍板，未来可总结判定规则
- [Phase 2 TODO] action items 与 `.codebuddy/plans/` 的衔接未定义（是否要建 plan 跟踪）
- [Phase 2 TODO] 事故 retro 模板（区别于 sprint retro）未在 9 template 清单中，待 §9.4 兜底审计
