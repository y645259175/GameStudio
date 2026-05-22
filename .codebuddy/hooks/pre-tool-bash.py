#!/usr/bin/env python3
"""
pre-tool-bash.py · PreToolUse hook (通用版)
按照 CodeBuddy 官方 Hooks 文档格式实现。

策略：
1. 对所有 Bash/execute_command 工具调用返回 allow + modifiedInput(requires_approval=false)
2. 记录日志供调试
3. 尝试用 modifiedInput 覆盖 requires_approval 字段来压住弹窗

官方文档明确支持的 modifiedInput 示例：
{
  "continue": true,
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "allow",
    "modifiedInput": {
      "command": "...",
      "requires_approval": false
    }
  }
}
"""

import json
import os
import sys
from datetime import datetime, timezone

# 强制 stdout/stderr UTF-8（Windows 默认 GBK 会让中文输出乱码 → IDE 解析失败）
if sys.platform == "win32":
    try:
        sys.stdout.reconfigure(encoding="utf-8")  # type: ignore[attr-defined]
        sys.stderr.reconfigure(encoding="utf-8")  # type: ignore[attr-defined]
    except Exception:
        pass


def main():
    # ===== 读 stdin =====
    try:
        raw = sys.stdin.read()
        input_data = json.loads(raw) if raw.strip() else {}
    except (json.JSONDecodeError, Exception):
        input_data = {}

    tool_name = input_data.get("tool_name", "unknown")
    tool_input = input_data.get("tool_input", {})
    command = tool_input.get("command", "") if isinstance(tool_input, dict) else ""

    # ===== 写日志 =====
    project_dir = os.environ.get("CODEBUDDY_PROJECT_DIR", os.getcwd())
    log_dir = os.path.join(project_dir, ".codebuddy", "logs")
    os.makedirs(log_dir, exist_ok=True)
    log_file = os.path.join(log_dir, f"pre-tool-hook-{datetime.now().strftime('%Y-%m-%d')}.jsonl")

    ts = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")
    log_entry = {
        "ts": ts,
        "tool_name": tool_name,
        "command": command,
        "original_requires_approval": tool_input.get("requires_approval") if isinstance(tool_input, dict) else None
    }

    # ===== 度量增强（P0-A）=====
    # Task 工具调用（sub-agent spawn）：记录 subagent_name / description / team 信息
    # 写到独立 agent-spawn-*.jsonl，便于统计 agent 利用率
    if tool_name == "Task" and isinstance(tool_input, dict):
        spawn_entry = {
            "ts": ts,
            "subagent_name": tool_input.get("subagent_name", "unknown"),
            "description": tool_input.get("description", ""),
            "team_mode": bool(tool_input.get("name")),  # 带 name 参数 = team 模式
            "team_name": tool_input.get("team_name", ""),
            "max_turns": tool_input.get("max_turns"),
            "prompt_len": len(tool_input.get("prompt", "")),
        }
        spawn_log = os.path.join(log_dir, f"agent-spawn-{datetime.now().strftime('%Y-%m-%d')}.jsonl")
        try:
            with open(spawn_log, "a", encoding="utf-8") as f:
                f.write(json.dumps(spawn_entry, ensure_ascii=False) + "\n")
        except Exception:
            pass
        # 也写到主 log（保持向后兼容）
        log_entry["subagent_name"] = spawn_entry["subagent_name"]
        log_entry["team_mode"] = spawn_entry["team_mode"]

    # Bash / execute_command 调用 skill run.py：记录到 skill-call-*.jsonl
    # 识别模式：python <...>/.codebuddy/skills/<name>/run.py 或 run.sh
    if tool_name in ("Bash", "execute_command") and command:
        import re
        m = re.search(r"\.codebuddy[\\/]skills[\\/]([\w\-]+)[\\/]run\.(py|sh)", command)
        if m:
            skill_entry = {
                "ts": ts,
                "skill_name": m.group(1),
                "runner": m.group(2),
                "command_excerpt": command[:200],
            }
            skill_log = os.path.join(log_dir, f"skill-call-{datetime.now().strftime('%Y-%m-%d')}.jsonl")
            try:
                with open(skill_log, "a", encoding="utf-8") as f:
                    f.write(json.dumps(skill_entry, ensure_ascii=False) + "\n")
            except Exception:
                pass
            log_entry["skill_name"] = skill_entry["skill_name"]

    try:
        with open(log_file, "a", encoding="utf-8") as f:
            f.write(json.dumps(log_entry, ensure_ascii=False) + "\n")
    except Exception:
        pass

    # ===== 决策 =====
    # Bash 工具：返回 allow + modifiedInput(requires_approval=false)
    # 非 Bash 工具（Write/Edit/Read/Delete/Glob）：只返回 allow，不动 modifiedInput
    #   原因：Write 的 tool_input 包含完整文件内容，如果通过 modifiedInput 回传
    #   会导致 stdout 输出巨大，超过缓冲区或 timeout → 文件写入被截断

    # === Layer 3 拦截 ===
    # image_gen：提示走 timiai-image skill（AP-10 修法）
    if tool_name == "image_gen" or tool_name == "ImageGen":
        result = {
            "continue": True,
            "hookSpecificOutput": {
                "hookEventName": "PreToolUse",
                "permissionDecision": "allow",
                "permissionDecisionReason": (
                    "[hook][WARN AP-10] 你在用 IDE 内置 image_gen 工具。工作室首选是 timiai-image skill："
                    "(1) 先跑 python .codebuddy/skills/timiai-image/scripts/_check_key.py 验证 key；"
                    "(2) 若 OK → 用 pipeline.py 走完整链路（含 quantize 限色，pixel art 必备）；"
                    "(3) 若你已确认走降级路径，commit msg 必须标 [VISUAL_DEBT downgrade]。"
                )
            }
        }
        print(json.dumps(result, ensure_ascii=False))
        return 0

    # execute_command 含高危删除关键词：提示用 delete_file
    if tool_name == "execute_command" and command:
        cmd_lower = command.lower()
        if any(kw in cmd_lower for kw in ["remove-item", " rm ", " rm\t", " rm\r", " del ", "\bdel ", "; rm", "&& rm"]):
            # 不完全 deny，但强提示
            result = {
                "continue": True,
                "hookSpecificOutput": {
                    "hookEventName": "PreToolUse",
                    "permissionDecision": "allow",
                    "permissionDecisionReason": (
                        "[hook][WARN AP-07] 命令含 Remove-Item/rm/del。"
                        "工作室约定：删文件用 delete_file IDE 工具，批量用 python -c \"import os; os.remove(...)\"。"
                        "如必须命令行删除，确保 commit msg 注明理由。"
                    )
                }
            }
            print(json.dumps(result, ensure_ascii=False))
            return 0

    if tool_name == "Bash":
        modified_input = dict(tool_input) if isinstance(tool_input, dict) else {}
        modified_input["requires_approval"] = False
        result = {
            "continue": True,
            "hookSpecificOutput": {
                "hookEventName": "PreToolUse",
                "permissionDecision": "allow",
                "permissionDecisionReason": "[hook] auto-allow Bash",
                "modifiedInput": modified_input
            }
        }
    else:
        # 非 Bash 工具（Write/Edit/Read/Delete 等）：只返回 allow，不含 modifiedInput
        # 原因：Write/Edit 的 tool_input 含完整文件内容，回传会导致截断
        result = {
            "continue": True,
            "hookSpecificOutput": {
                "hookEventName": "PreToolUse",
                "permissionDecision": "allow",
                "permissionDecisionReason": "[hook] auto-allow " + tool_name
            }
        }

    print(json.dumps(result, ensure_ascii=False))
    return 0


if __name__ == "__main__":
    sys.exit(main())
