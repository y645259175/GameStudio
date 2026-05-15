# [NOT APPLICABLE] This hook was designed for Claude Code (upstream CCGS).
# CodeBuddy does not support session/tool lifecycle hooks.
# Retained for reference only; will not be triggered by git or CodeBuddy.

#!/usr/bin/env bash
# log-agent.sh · AI 会话事件审计（骨架）
# 用途：记录 skill / agent 调用事件到 jsonl 日志
# 触发：由 AI 框架在 skill / agent 启动时调用（非 git hook）
# 退出码：0 通过 / 2 配置错误
# 上游来源：抄上游 my-game/（[Phase 1.5+ 从 reference/my-game/ 抄完整版]）
#
# Phase 1 状态：仅骨架，实质日志写入逻辑待 Phase 1.5+ 从上游抄完整版

set -uo pipefail

trap 'echo "[log-agent] 异常退出" >&2; exit 2' ERR

# ===== 输入参数 =====
EVENT_TYPE="${1:-unknown}"      # skill_start / skill_end / agent_call / error / ...
EVENT_NAME="${2:-unknown}"      # 具体 skill / agent 名
EVENT_PARAMS="${3:-{}}"         # JSON 字符串，参数摘要

# ===== 输出位置 =====
LOG_DIR=".codebuddy/logs"
LOG_FILE="$LOG_DIR/agent-$(date +%Y-%m-%d).jsonl"

mkdir -p "$LOG_DIR"

# ===== 写一条 jsonl =====
timestamp=$(date -u +%Y-%m-%dT%H:%M:%SZ)
printf '{"ts":"%s","type":"%s","name":"%s","params":%s}\n' \
  "$timestamp" "$EVENT_TYPE" "$EVENT_NAME" "$EVENT_PARAMS" \
  >> "$LOG_FILE"

exit 0

# [Phase 1.5+ TODO] 从 reference/my-game/ 抄完整版，含：
# - 多种事件类型支持（pre / post / error / metric）
# - 日志轮转（按大小 / 按日期）
# - 与 .codebuddy/plans/ 的关联（log → plan 反查）

