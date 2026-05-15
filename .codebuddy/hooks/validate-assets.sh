#!/usr/bin/env bash
set -euo pipefail

# pre-commit hook · 校验美术/音频资产规范
# 触发：git commit 前（与 pre-commit-lite 同事件，可独立启用或合并）
# 检查项：
#   1. 命名规范（snake_case + 类别前缀）
#   2. 文件尺寸（图片 ≤ 4MB / 音频 ≤ 10MB）
#   3. 图片必须 .png 或 .webp（不接受 .jpg / .gif 进 game/assets/）
#   4. 路径合规（必须在 projects/<name>/game/assets/ 或 art/ 下）

EXIT_CODE=0
WARNINGS=0
ERRORS=0

# 命名规范：<category>_<desc>_<timestamp>?.png
NAME_PATTERN='^[a-z]+(_[a-z0-9]+)+\.[a-z0-9]+$'

# 仅扫描 staged 文件
STAGED=$(git diff --cached --name-only --diff-filter=AM | grep -E '\.(png|jpg|jpeg|webp|gif|wav|mp3|ogg)$' || true)

if [ -z "$STAGED" ]; then
    exit 0
fi

echo "[validate-assets] checking $(echo "$STAGED" | wc -l | tr -d ' ') asset(s)..."

while IFS= read -r file; do
    [ -z "$file" ] && continue

    # 1. 路径合规
    if [[ ! "$file" =~ ^projects/[^/]+/(game/assets|art)/ ]]; then
        echo "  WARN: $file not in projects/<name>/(game/assets|art)/" >&2
        WARNINGS=$((WARNINGS + 1))
        continue
    fi

    # 2. 文件名规范
    basename=$(basename "$file")
    if ! [[ "$basename" =~ $NAME_PATTERN ]]; then
        echo "  WARN: $file - filename should match snake_case pattern" >&2
        WARNINGS=$((WARNINGS + 1))
    fi

    # 3. 扩展名白名单（仅 game/assets/ 严格检查）
    if [[ "$file" =~ ^projects/[^/]+/game/assets/ ]]; then
        ext="${basename##*.}"
        case "$ext" in
            png|webp|wav|ogg) ;;
            jpg|jpeg|gif|mp3)
                echo "  ERROR: $file - extension .$ext not allowed in game/assets/ (use png/webp/wav/ogg)" >&2
                ERRORS=$((ERRORS + 1))
                ;;
            *)
                echo "  WARN: $file - unknown extension .$ext" >&2
                WARNINGS=$((WARNINGS + 1))
                ;;
        esac
    fi

    # 4. 文件大小
    if [ -f "$file" ]; then
        size=$(stat -c%s "$file" 2>/dev/null || stat -f%z "$file" 2>/dev/null || echo 0)
        case "$basename" in
            *.png|*.jpg|*.jpeg|*.webp|*.gif)
                # 图片 4MB
                if [ "$size" -gt 4194304 ]; then
                    echo "  WARN: $file - image > 4MB ($((size/1024/1024))MB), consider compression" >&2
                    WARNINGS=$((WARNINGS + 1))
                fi
                ;;
            *.wav|*.mp3|*.ogg)
                # 音频 10MB
                if [ "$size" -gt 10485760 ]; then
                    echo "  WARN: $file - audio > 10MB ($((size/1024/1024))MB), consider format optimization" >&2
                    WARNINGS=$((WARNINGS + 1))
                fi
                ;;
        esac
    fi
done <<< "$STAGED"

echo "[validate-assets] done: $ERRORS error(s) / $WARNINGS warning(s)"

# 错误阻塞 commit；警告不阻塞
if [ "$ERRORS" -gt 0 ]; then
    echo "[validate-assets] BLOCKED due to errors. Fix and re-commit." >&2
    exit 1
fi

exit 0
