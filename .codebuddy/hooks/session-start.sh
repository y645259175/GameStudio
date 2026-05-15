#!/usr/bin/env bash
set -euo pipefail

# SessionStart hook · 记录会话元信息
# 触发：每次新会话开始时（CodeBuddy SessionStart 事件）
# 输入：stdin JSON（含 session_id / cwd / hook_event_name）
# 输出：stdout JSON + 日志写入 .codebuddy/session-logs/

INPUT=$(cat)
SESSION_ID=$(echo "$INPUT" | python3 -c "import sys,json; print(json.load(sys.stdin).get('session_id','unknown'))" 2>/dev/null || echo "unknown")
CWD=$(echo "$INPUT" | python3 -c "import sys,json; print(json.load(sys.stdin).get('cwd',''))" 2>/dev/null || echo "")
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

# 确保日志目录存在
LOG_DIR="$CWD/.codebuddy/session-logs"
mkdir -p "$LOG_DIR"

# 写入会话日志
LOG_FILE="$LOG_DIR/session-$SESSION_ID.log"
echo "[$TIMESTAMP] SESSION_START id=$SESSION_ID cwd=$CWD" >> "$LOG_FILE"

# 检测当前项目 phase（如有 PROJECT.md）
PHASE="unknown"
for proj_dir in "$CWD"/projects/*/; do
    if [ -f "${proj_dir}PROJECT.md" ]; then
        PHASE=$(grep -m1 "^phase:" "${proj_dir}PROJECT.md" 2>/dev/null | cut -d: -f2 | tr -d ' ' || echo "unknown")
        echo "[$TIMESTAMP] PROJECT=$(basename "$proj_dir") PHASE=$PHASE" >> "$LOG_FILE"
    fi
done

# 输出（不阻塞，不注入消息）
echo '{"continue": true}'
exit 0
