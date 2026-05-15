#!/usr/bin/env bash
set -euo pipefail

# PostToolUse hook · 记录 AI 工具调用日志
# 触发：每次 AI 调用工具完成后（CodeBuddy PostToolUse 事件）
# 输入：stdin JSON（含 session_id / tool_name / tool_input）
# 输出：stdout JSON + 日志追加到 .codebuddy/session-logs/

INPUT=$(cat)

SESSION_ID=$(echo "$INPUT" | python3 -c "import sys,json; print(json.load(sys.stdin).get('session_id','unknown'))" 2>/dev/null || echo "unknown")
CWD=$(echo "$INPUT" | python3 -c "import sys,json; print(json.load(sys.stdin).get('cwd',''))" 2>/dev/null || echo "")
TOOL_NAME=$(echo "$INPUT" | python3 -c "import sys,json; print(json.load(sys.stdin).get('tool_name',''))" 2>/dev/null || echo "")
# 提取工具输入的第一个关键字段（如文件路径）
TOOL_TARGET=$(echo "$INPUT" | python3 -c "
import sys,json
data = json.load(sys.stdin)
ti = data.get('tool_input', {})
# 尝试提取 filePath / path / command 等常见字段
target = ti.get('filePath', ti.get('path', ti.get('command', ti.get('target_directory', ''))))
if isinstance(target, str) and len(target) > 80:
    target = target[:80] + '...'
print(target)
" 2>/dev/null || echo "")

TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

# 写入日志
LOG_DIR="$CWD/.codebuddy/session-logs"
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/session-$SESSION_ID.log"
echo "[$TIMESTAMP] TOOL=$TOOL_NAME TARGET=$TOOL_TARGET" >> "$LOG_FILE"

# 不阻塞
echo '{"continue": true}'
exit 0
