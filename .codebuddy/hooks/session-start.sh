#!/usr/bin/env bash
# session-start.sh · AI 会话启动检查（骨架）
# 用途：新会话开始时打印工作室元信息 + 警告未完成事项
# 触发：由 AI 框架在 session 启动时调用
# 退出码：0 通过（仅打印，不阻塞）
# 上游来源：抄上游 my-game/（[Phase 1.5+ 从 reference/my-game/ 抄完整版]）

set -uo pipefail

trap 'echo "[session-start] 异常退出" >&2; exit 2' ERR

echo "===== Session Start ====="
echo "时间：$(date)"
echo "工作区：$(pwd)"

# ===== 工作室元信息 =====
if [ -f "studio/docs/studio-handbook.md" ]; then
  echo "工作室宪法：✓ 存在"
else
  echo "工作室宪法：✗ 缺失（建议补 studio/docs/studio-handbook.md）"
fi

# ===== Phase 状态识别（Phase 1 / 1.5 / 2+）=====
if [ -d ".git" ]; then
  echo "Git 状态：已 init（Phase 2+）"
else
  echo "Git 状态：未 init（Phase 1 / 1.5）"
fi

# ===== 进行中迁移日志 =====
if [ -f ".codebuddy/plans/v4-migration-log.md" ]; then
  echo "v4 迁移日志：✓ 存在（建议查看进度）"
fi

# ===== 当前活跃项目 =====
project_count=$(find projects -maxdepth 2 -name 'PROJECT.md' 2>/dev/null | wc -l | tr -d ' ')
echo "活跃项目数：$project_count"

echo "========================="

exit 0

# [Phase 1.5+ TODO] 从 reference/my-game/ 抄完整版，含：
# - 上次 session 未完成事项扫描
# - 阻塞 / 风险快照
# - skill / agent 推荐（基于上下文）
