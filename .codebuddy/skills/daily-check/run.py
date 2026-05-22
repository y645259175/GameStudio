#!/usr/bin/env python3
"""
daily-check run.py · 每日末检查 + agent/skill 利用率汇总

用法:
  python .codebuddy/skills/daily-check/run.py                # 今天
  python .codebuddy/skills/daily-check/run.py --days 7       # 本周
  python .codebuddy/skills/daily-check/run.py --project <name>  # 含项目级检查
"""

from __future__ import annotations

import argparse
import subprocess
import sys
from pathlib import Path

SCRIPT_DIR = Path(__file__).resolve().parents[2] / "scripts"
sys.path.insert(0, str(SCRIPT_DIR))
from skill_lib import force_utf8, find_workspace_root, find_project, list_projects, print_section, emit_skill_call_log  # type: ignore

SKILL_NAME = "daily-check"


def run_metrics(ws: Path, days: int) -> str:
    """调用 agent_metrics.py 返回输出。"""
    metrics_script = ws / ".codebuddy" / "scripts" / "agent_metrics.py"
    if not metrics_script.exists():
        return "(agent_metrics.py 不存在，跳过度量)"
    try:
        r = subprocess.run(
            [sys.executable, str(metrics_script), "--days", str(days)],
            capture_output=True, text=True, encoding="utf-8", timeout=30,
            cwd=str(ws),
        )
        return r.stdout if r.returncode == 0 else f"(metrics 异常: exit={r.returncode})\n{r.stderr}"
    except Exception as e:
        return f"(metrics 跑失败: {e})"


def run_lint(ws: Path) -> str:
    """调用 check_progressive_disclosure.py --quiet 看 lint 状态。"""
    lint_script = ws / ".codebuddy" / "scripts" / "check_progressive_disclosure.py"
    if not lint_script.exists():
        return "(渐进披露 lint 不存在)"
    try:
        r = subprocess.run(
            [sys.executable, str(lint_script), "--quiet"],
            capture_output=True, text=True, encoding="utf-8", timeout=15,
            cwd=str(ws),
        )
        return f"渐进披露 lint: {'PASS' if r.returncode == 0 else 'BLOCK'} (exit={r.returncode})"
    except Exception as e:
        return f"(lint 跑失败: {e})"


def run_consistency(ws: Path, project: str | None) -> str:
    """如果指定了项目，跑 consistency-check。"""
    if not project:
        return ""
    cc_script = ws / ".codebuddy" / "skills" / "consistency-check" / "run.py"
    if not cc_script.exists():
        return "(consistency-check run.py 不存在)"
    try:
        r = subprocess.run(
            [sys.executable, str(cc_script), "--project", project, "--no-report"],
            capture_output=True, text=True, encoding="utf-8", timeout=30,
            cwd=str(ws),
        )
        return r.stdout
    except Exception as e:
        return f"(consistency-check 跑失败: {e})"


def main():
    force_utf8()
    p = argparse.ArgumentParser(description="daily-check skill")
    p.add_argument("--days", type=int, default=1, help="度量统计天数（默认 1）")
    p.add_argument("--project", help="可选：指定项目跑 consistency-check")
    args = p.parse_args()

    ws = find_workspace_root()
    emit_skill_call_log(SKILL_NAME, vars(args), ws)

    print_section(f"Daily Check · {args.days} day(s)")

    # 1. agent / skill 度量
    print()
    metrics_output = run_metrics(ws, args.days)
    print(metrics_output)

    # 2. 渐进披露 lint
    print()
    lint_result = run_lint(ws)
    print(lint_result)

    # 3. 项目级 consistency-check（可选）
    if args.project:
        print()
        print_section(f"Consistency Check · {args.project}")
        cc_output = run_consistency(ws, args.project)
        print(cc_output)

    # 4. 建议
    print()
    print("--- 建议 ---")
    avail = list_projects(ws)
    if avail:
        print(f"  活跃项目: {', '.join(avail)}")
        print(f"  深度检查: python .codebuddy/skills/daily-check/run.py --project <name> --days 7")
    print(f"  度量详情: python .codebuddy/scripts/agent_metrics.py --all --json")

    return 0


if __name__ == "__main__":
    sys.exit(main())
