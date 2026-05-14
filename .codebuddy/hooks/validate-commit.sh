#!/usr/bin/env bash
# validate-commit.sh · 重通道 commit 校验
# 用途：每次 commit 前校验 GDD 8 节完整性 + JSON 文件合法性
# 触发：git pre-commit hook（需在 Phase 2 git init 后启用）
# 退出码：0 通过 / 1 critical 阻塞 / 2 配置错误
# 上游来源：v4 §4 Q7-A（原创）

set -euo pipefail

# ===== 配置区 =====
GDD_REQUIRED_SECTIONS=(
  "## 概述"
  "## 玩法循环"
  "## 系统设计"
  "## 数值与平衡"
  "## UX"
  "## 美术"
  "## 音频"
  "## 交付与验收"
)

# ===== fail-safe =====
trap 'echo "[validate-commit] 异常退出，请检查脚本" >&2; exit 2' ERR

# ===== dry-run 模式 =====
DRY_RUN=0
if [ "${1:-}" = "--dry-run" ]; then
  DRY_RUN=1
  echo "[validate-commit] dry-run 模式，不会阻塞 commit"
fi

# ===== 1. GDD 8 节完整性校验 =====
critical=0
warn=0

# 找出本次 commit 涉及的 gdd/*.md 文件
gdd_files=$(git diff --cached --name-only --diff-filter=AM 2>/dev/null | grep -E '^projects/[^/]+/gdd/.*\.md$' || true)

if [ -n "$gdd_files" ]; then
  while IFS= read -r f; do
    [ -z "$f" ] && continue
    missing=()
    for sec in "${GDD_REQUIRED_SECTIONS[@]}"; do
      if ! grep -qF "$sec" "$f"; then
        missing+=("$sec")
      fi
    done
    if [ ${#missing[@]} -gt 0 ]; then
      echo "[critical] $f 缺少 GDD 必备小节：${missing[*]}" >&2
      critical=$((critical + 1))
    fi
  done <<< "$gdd_files"
fi

# ===== 2. JSON 文件合法性校验 =====
json_files=$(git diff --cached --name-only --diff-filter=AM 2>/dev/null | grep -E '\.json$' || true)
if [ -n "$json_files" ]; then
  if ! command -v jq >/dev/null 2>&1; then
    echo "[warn] 未安装 jq，跳过 JSON 校验（建议 Phase 2 装上）" >&2
    warn=$((warn + 1))
  else
    while IFS= read -r f; do
      [ -z "$f" ] && continue
      if ! jq empty "$f" >/dev/null 2>&1; then
        echo "[critical] $f JSON 格式非法" >&2
        critical=$((critical + 1))
      fi
    done <<< "$json_files"
  fi
fi

# ===== 3. 退出 =====
echo "[validate-commit] critical=$critical warn=$warn"
if [ "$DRY_RUN" -eq 1 ]; then
  exit 0
fi
if [ "$critical" -gt 0 ]; then
  echo "[validate-commit] 阻塞 commit，请修复 critical 项" >&2
  exit 1
fi
exit 0
