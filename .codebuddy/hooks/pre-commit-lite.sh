#!/usr/bin/env bash
# pre-commit-lite.sh · 极简 commit 前置检查
# 用途：基础 lint（trailing whitespace / mixed line endings / 大文件警告）
# 触发：git pre-commit hook（与 validate-commit.sh 二选一）
# 退出码：0 通过（含 warn）/ 2 配置错误
# 上游来源：v4 §4 Q2-A（原创）
#
# 设计原则：本 hook **不阻塞 commit**，仅警告。强校验请用 validate-commit.sh。

set -uo pipefail

trap 'echo "[pre-commit-lite] 异常退出" >&2; exit 2' ERR

DRY_RUN=0
[ "${1:-}" = "--dry-run" ] && DRY_RUN=1

warn=0

# ===== 1. 大文件警告（> 10MB）=====
files=$(git diff --cached --name-only --diff-filter=AM 2>/dev/null || true)
if [ -n "$files" ]; then
  while IFS= read -r f; do
    [ -z "$f" ] && continue
    [ -f "$f" ] || continue
    # 跨平台取文件大小：优先 stat -c (Linux)，回退 wc -c (macOS/Win-bash)
    size=$(stat -c '%s' "$f" 2>/dev/null || wc -c < "$f")
    if [ "$size" -gt 10485760 ]; then
      echo "[warn] $f 超过 10MB（${size}B），考虑用 git-lfs 或 .gitignore" >&2
      warn=$((warn + 1))
    fi
  done <<< "$files"
fi

# ===== 2. trailing whitespace 警告 =====
text_files=$(git diff --cached --name-only --diff-filter=AM 2>/dev/null | grep -E '\.(md|sh|py|json|toml|yaml|yml|txt)$' || true)
if [ -n "$text_files" ]; then
  while IFS= read -r f; do
    [ -z "$f" ] && continue
    [ -f "$f" ] || continue
    if grep -nE ' +$' "$f" >/dev/null 2>&1; then
      echo "[warn] $f 含行尾空格" >&2
      warn=$((warn + 1))
    fi
  done <<< "$text_files"
fi

# ===== 3. CRLF 警告 =====
if [ -n "$text_files" ]; then
  while IFS= read -r f; do
    [ -z "$f" ] && continue
    [ -f "$f" ] || continue
    if grep -lU $'\r' "$f" >/dev/null 2>&1; then
      echo "[warn] $f 含 CRLF 行尾（建议统一 LF）" >&2
      warn=$((warn + 1))
    fi
  done <<< "$text_files"
fi

echo "[pre-commit-lite] warn=$warn（不阻塞）"
exit 0
