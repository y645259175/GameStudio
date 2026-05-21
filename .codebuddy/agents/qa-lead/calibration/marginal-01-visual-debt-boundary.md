# Calibration · qa-lead · MARGINAL-01

## 前置场景
- milestone gate M5 → M6（pre-production → production）
- 项目有 2 个 VISUAL_DEBT 条目（阈值 ≤2 为 PASS）
- 其余 6 项指标全 PASS

## 条件
- visual_debt_count = 2（恰好在阈值边界）
- 2 个 debt 都有 backlog ID + due milestone = M6
- 真实玩家路径测试 PASS

## 产出摘要
- **Verdict: QA-CONDITIONAL**
- reason: "visual_debt_count=2 恰好在阈值边界，虽技术上 PASS，但建议 CONDITIONAL 标注风险"
- recommendations: "M6 sprint 优先关闭这 2 个 VISUAL_DEBT 再确认 gate"

## 为什么是 MARGINAL（边界案例）
- 按 schema 严格定