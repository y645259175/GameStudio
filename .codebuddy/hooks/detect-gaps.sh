# [NOT APPLICABLE] This hook was designed for Claude Code (upstream CCGS).
# CodeBuddy does not support session/tool lifecycle hooks.
# Retained for reference only; will not be triggered by git or CodeBuddy.

#!/usr/bin/env bash
# detect-gaps.sh · 缺口检测（骨架）
# 用途：consistency-check skill 的 cli 包装入口，可被定时任务或 CI 调用
# 触发：手动或定时（非 git hook）
# 退出码：0 通过 / 1 发现 critical 缺口 / 2 配置错误
# 上游来源：抄上游 my-game/（[Phase 1.5+ 从 reference/my-game/ 抄完整版]）
#
# Phase 1 状态：仅骨架，实质功能由 .codebuddy/skills/consistency-check/ 提供
# 本 hook 是给非交互场景（CI / cron）用的入口，提示用户调用 skill。

set -uo pipefail

trap 'echo "[detect-gaps] 异常退出" >&2; exit 2' ERR

PROJECT_NAME="${1:-}"

if [ -z "$PROJECT_NAME" ]; then
  echo "用法：detect-gaps.sh <project-name>"
  echo "提示：本 hook 是 consistency-check skill 的非交互入口"
  echo "      Phase 1 期间请直接调用 skill：/consistency-check"
  exit 2
fi

PROJECT_DIR="projects/$PROJECT_NAME"
if [ ! -d "$PROJECT_DIR" ]; then
  echo "[critical] 项目不存在：$PROJECT_DIR" >&2
  exit 1
fi

echo "[detect-gaps] 项目 $PROJECT_NAME 的实质扫描功能由 consistency-check skill 提供"
echo "[detect-gaps] Phase 1 期间，请在 AI 会话中调用 /consistency-check"
echo "[detect-gaps] [Phase 1.5+ TODO] 从 reference/my-game/ 抄完整版，含 jq / awk 实现的扫描逻辑"

exit 0

