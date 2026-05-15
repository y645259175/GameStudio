#!/usr/bin/env bash
set -euo pipefail

# Stop hook · AI 完成响应后检测一致性缺口
# 触发：每次 AI 完成一轮响应时（CodeBuddy Stop 事件）
# 功能：轻量检测本次响应是否可能导致 GDD ↔ 代码 不一致
# 输入：stdin JSON
# 输出：如检测到缺口，通过 systemMessage 提醒 AI 注意

INPUT=$(cat)
CWD=$(echo "$INPUT" | python3 -c "import sys,json; print(json.load(sys.stdin).get('cwd',''))" 2>/dev/null || echo "")

# 检查是否有 .gd 文件被修改但对应 GDD 章节未更新
# （轻量实现：看 git diff --name-only 中是否有 .gd 文件修改）
MODIFIED_GD=$(cd "$CWD" 2>/dev/null && git diff --name-only HEAD 2>/dev/null | grep "\.gd$" || true)

if [ -n "$MODIFIED_GD" ]; then
    # 有 GDScript 改动，提醒检查一致性
    cat <<EOF
{
    "continue": true,
    "hookSpecificOutput": {
        "hookEventName": "Stop",
        "additionalContext": "注意：本轮有 GDScript 文件被修改（${MODIFIED_GD%%$'\n'*}...），建议确认 GDD/数值表是否需要同步更新。"
    }
}
EOF
else
    echo '{"continue": true}'
fi

exit 0
