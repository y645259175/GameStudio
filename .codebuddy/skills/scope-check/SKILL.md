---
name: scope-check
description: Project scope drift detection. Use when user says "范围跑偏 / scope check / 这个还在原计划里吗 / 是不是做太多了". Compares current implementation against GDD core pillars and PROJECT.md milestones. Catches feature creep early.
---

# scope-check · CORE

## 何时触发

- 用户说"范围跑偏 / scope check / 这个还在计划里吗 / 是不是做太多了"
- sprint plan 时怀疑要超出 milestone
- backlog 项数显著超出预算时的健康检查

## 红线

- **[1]** 必须基于 PROJECT.md `pillars` + 当前 milestone 目标判断（不是 AI 自己想象的"项目应该长什么样"）
- **[2]** verdict 三选一：IN-SCOPE / DRIFT-MINOR / DRIFT-MAJOR

## 流程概要

1. 读 PROJECT.md（pillars + milestones）
2. 扫 backlog + recently committed changes
3. 对照 milestone 目标找溢出项
4. 输出 verdict + 具体溢出清单

## 何时升级到 PLAYBOOK

- 详细 SOP / 输入清单 / 每条 milestone 的判断准则 → §详细流程
- 历史触发场景 → §案例
- 与 retrospective / sprint-plan 的协作 → §relations

详见 `PLAYBOOK.md`。
