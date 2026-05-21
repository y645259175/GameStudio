#!/usr/bin/env bash
# session-start.sh · AI 会话启动检查（骨架）
# 用途：新会话开始时打印工作室元信息 + 警告未完成事项
# 触发：由 AI 框架在 session 启动时调用
# 退出码：0 通过（仅打印，不阻塞）
# 上游来源：抄上游 my-game/（[Phase 1.5+ 从 reference/my-game/ 抄完整版]）

# 不用 set -e / -u / -o pipefail：
# - hook 是"打印信息"性质，单条命令失败不应阻塞会话启动
# - grep 在没匹配时返回 1 会与 pipefail 联动触发 trap，体验糟糕
# 改用单条命令显式 || 兜底，让脚本总是 exit 0

echo "===== Session Start ====="
echo "时间：$(date 2>/dev/null || echo unknown)"
echo "工作区：$(pwd 2>/dev/null || echo unknown)"

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
project_count=$(find projects -maxdepth 2 -name 'PROJECT.md' 2>/dev/null | wc -l 2>/dev/null | tr -d ' ' 2>/dev/null || echo 0)
echo "活跃项目数：${project_count:-0}"

echo "========================="

# ===== Anti-Patterns 速读注入（v1.1+，combo-A 进化）=====
# 来源：studio/docs/anti-patterns-digest.md（由 docs-writer 维护）
# 作用：每次会话启动让 main agent 看到 8 条反模式速读，避免重复踩坑
DIGEST_FILE="studio/docs/anti-patterns-digest.md"
if [ -f "$DIGEST_FILE" ]; then
  echo ""
  echo "===== Anti-Patterns 速读（每次启动注入） ====="
  cat "$DIGEST_FILE"
  echo "===== /Anti-Patterns 速读 ====="
else
  echo "[warn] $DIGEST_FILE 缺失，跳过反模式注入" >&2
fi

# ===== 上次会话 agent / skill 利用率统计 =====
# 来源：.codebuddy/logs/agent-YYYY-MM-DD.jsonl（由 log-agent.sh 写入）
# 作用：让 main agent 看到 "上次 session 用了几次 task / skill"，触发 AP-01 自检
echo ""
echo "===== 上次会话 agent/skill 利用率 ====="
LOG_DIR=".codebuddy/logs"
if [ -d "$LOG_DIR" ]; then
  # 找最近一天的 jsonl（不一定是今天）
  LATEST_LOG=$(ls -1t "$LOG_DIR"/agent-*.jsonl 2>/dev/null | head -n 1 || true)
  if [ -n "$LATEST_LOG" ] && [ -f "$LATEST_LOG" ]; then
    log_date=$(basename "$LATEST_LOG" | sed -E 's/^agent-([0-9-]+)\.jsonl$/\1/')
    total_lines=$(wc -l < "$LATEST_LOG" 2>/dev/null | tr -d ' ' || echo 0)
    skill_count=$(grep -c '"type":"skill_start"' "$LATEST_LOG" 2>/dev/null || echo 0)
    agent_count=$(grep -c '"type":"agent_call"' "$LATEST_LOG" 2>/dev/null || echo 0)
    error_count=$(grep -c '"type":"error"' "$LATEST_LOG" 2>/dev/null || echo 0)
    echo "最近日志：$log_date（共 $total_lines 条事件）"
    echo "  skill 调用：$skill_count"
    echo "  agent spawn：$agent_count"
    echo "  错误：$error_count"
    if [ "$total_lines" -gt 0 ] && [ "$agent_count" -lt 3 ]; then
      echo "  [!] agent spawn < 3，警惕 AP-01（agent 自己干一切）"
    fi
  else
    echo "暂无历史日志（首次会话或日志未启用）"
  fi
else
  echo "日志目录 $LOG_DIR 未创建（首次启用）"
fi
echo "本次目标：agent 利用率 ≥ 50% · spawn 至少 3 次"
echo "==============================================="

exit 0

# [Phase 1.5+ TODO] 从 reference/my-game/ 抄完整版，含：
# - 上次 session 未完成事项扫描
# - 阻塞 / 风险快照
# - skill / agent 推荐（基于上下文）
