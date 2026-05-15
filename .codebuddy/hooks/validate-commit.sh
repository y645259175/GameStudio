#!/usr/bin/env bash
# validate-commit.sh · 重通道 commit 校验
# 用途：每次 commit 前校验 GDD 最小覆盖维度 + JSON 文件合法性
# 触发：git pre-commit hook（需在 Phase 2 git init 后启用）
# 退出码：0 通过 / 1 critical 阻塞 / 2 配置错误
# 上游来源：v4 §4 Q7-A（原创）；2026-05-15 改为最小 5 维度（design-authoring rule v2）

set -euo pipefail

# ===== 配置区 =====
# 最小覆盖维度：所有 GDD 必须至少匹配以下 5 个之一的多个标题（按维度判定）
# 见 rules/design-authoring/RULE.mdc
GDD_DIMENSION_PATTERNS=(
  "概述|项目定位"                    # 维度 1
  "玩法循环|核心机制|核心玩法"       # 维度 2
  "系统设计|子系统"                  # 维度 3
  "视觉与美术|美术方向|美术 bible"   # 维度 4
  "交付与验收|DoD|验收标准"          # 维度 5
)

# ===== fail-safe =====
trap 'echo "[validate-commit] 异常退出，请检查脚本" >&2; exit 2' ERR

# ===== dry-run 模式 =====
DRY_RUN=0
if [ "${1:-}" = "--dry-run" ]; then
  DRY_RUN=1
  echo "[validate-commit] dry-run 模式，不会阻塞 commit"
fi

# ===== 1. GDD 最小覆盖维度校验 =====
critical=0
warn=0

# 找出本次 commit 涉及的 gdd/*.md 文件
gdd_files=$(git diff --cached --name-only --diff-filter=AM 2>/dev/null | grep -E '^projects/[^/]+/gdd/.*\.md$' || true)

if [ -n "$gdd_files" ]; then
  while IFS= read -r f; do
    [ -z "$f" ] && continue
    # 排除草稿 / 概念对话 / 偏差说明等辅助文件
    case "$f" in
      */draft/*|*/concept-dialogue.md|*/gdd-skeleton-rationale.md) continue ;;
    esac
    missing=()
    idx=0
    for pat in "${GDD_DIMENSION_PATTERNS[@]}"; do
      idx=$((idx + 1))
      if ! grep -qE "^##.*($pat)" "$f"; then
        missing+=("dim-$idx[$pat]")
      fi
    done
    if [ ${#missing[@]} -gt 0 ]; then
      echo "[critical] $f 缺少 GDD 最小覆盖维度：${missing[*]}" >&2
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
