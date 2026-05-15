---
name: quick-design
type: skill
status: active
description: Lightweight design facilitator for small decisions outside the formal 8-section GDD process.
---

# Quick-Design · 轻量级设计

## 何时使用

不需要走完整 GDD 8 节流程的小决策（UI 微调 / 数值微调 / 临时实验功能）。区别于 `design-review`：
- `design-review` = 重量级 GDD 8 节，影响系统级
- `quick-design` = 轻量级局部决策，单点调整

典型触发：
- "/quick-design 调一下伤害公式"
- "我想加个临时排行榜"
- "改改主菜单按钮位置"

## 输入 / 触发条件

- 当前在项目根
- 决策范围（小，不跨系统）
- 可选：相关 GDD 章节引用

## 流程步骤

1. **范围判断**：AI 评估是否真的"轻量"——如发现影响 ≥ 2 个系统则路由到 `design-review`
2. **三段式起草**：
   - 现状（中文 1-2 句）
   - 提议变更（中文 + 必要数值）
   - 影响范围（哪些 stories / 代码 / 配置受影响）
3. **快速验证**：交互问"接受 / 修改 / 升级到 design-review"
4. **落盘**：`projects/<name>/quick-designs/YYYY-MM-DD-<topic>.md`
5. **追溯**：在受影响的 GDD 章节末尾加链接（"见 quick-designs/..."）
6. **commit 建议**：`[quick] design <topic>`（轻通道 tag）

## 输出

- `projects/<name>/quick-designs/YYYY-MM-DD-<topic>.md`
- 受影响 GDD 章节的反向链接

## 引用

- 上游规划：v4 §6.1.1（项目级纯流程 9 之一）
- 相关 skill：`design-review` `quick-fix`
- 相关 rule：`commit-discipline`（双通道）

## Known Limitations / Phase 2 Review Points

- [Phase 2 TODO] "轻量"判据靠 AI 主观，未来可加阈值（影响系统数 / 代码行数）
- [Phase 2 TODO] 反向链接维护未自动化，依赖人工 / consistency-check 兜底
- [Phase 2 TODO] quick-design 数量增多时是否合并到 GDD 章节末尾"变更日志"小节
