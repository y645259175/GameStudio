#!/usr/bin/env python3
"""
smoke-check run.py · Sprint 末冒烟

用法:
  python .codebuddy/skills/smoke-check/run.py --project <name>
  python .codebuddy/skills/smoke-check/run.py --project <name> --sprint N
"""

from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path

SCRIPT_DIR = Path(__file__).resolve().parents[2] / "scripts"
sys.path.insert(0, str(SCRIPT_DIR))
from skill_lib import (  # type: ignore
    force_utf8, find_workspace_root, find_project, list_projects,
    list_stories, load_story, print_section, emit_skill_call_log,
)

SKILL_NAME = "smoke-check"


def velocity_5_summary(stories: list[dict]) -> dict:
    """统计 velocity 五数：planned / done / carry-over / blocked / abandoned"""
    counters = {"planned": 0, "done": 0, "carry-over": 0, "blocked": 0,
                "abandoned": 0, "in-progress": 0, "draft": 0, "ready": 0}
    for s in stories:
        st = s["status"]
        counters[st] = counters.get(st, 0) + 1
    counters["planned"] = sum(counters.get(k, 0) for k in ("done", "in-progress", "ready"))
    return counters


def main():
    force_utf8()
    p = argparse.ArgumentParser(description="smoke-check skill")
    p.add_argument("--project", help="项目名")
    p.add_argument("--sprint", type=int, help="sprint 编号（用于报告命名）")
    p.add_argument("--json", action="store_true")
    args = p.parse_args()

    ws = find_workspace_root()
    emit_skill_call_log(SKILL_NAME, vars(args), ws)
    proj = find_project(args.project, ws)
    if not proj:
        print(f"[ERROR] 找不到项目", file=sys.stderr)
        return 1

    stories_files = list_stories(proj)
    stories = [load_story(sf) for sf in stories_files]

    # 1. velocity 5 数
    velocity = velocity_5_summary(stories)

    # 2. consistency-check 路由提示
    consistency_hint = (f"python .codebuddy/skills/consistency-check/run.py --project {proj.name}")

    # 3. 检查 in-progress 阻塞情况
    in_progress = [s for s in stories if s["status"] == "in-progress"]
    blocked = [s for s in stories if s["status"] == "blocked"]

    # 4. abandoned / blocked 阈值 → 触发 retrospective 提示
    retro_trigger = (velocity.get("abandoned", 0) >= 1) or (velocity.get("blocked", 0) >= 2)

    result = {
        "project": proj.name,
        "sprint": args.sprint,
        "velocity": velocity,
        "in_progress_count": len(in_progress),
        "in_progress_ids": [s["id"] for s in in_progress],
        "blocked_ids": [s["id"] for s in blocked],
        "consistency_check_hint": consistency_hint,
        "retrospective_recommended": retro_trigger,
    }

    if args.json:
        print(json.dumps(result, ensure_ascii=False, indent=2))
        return 0

    print_section(f"Smoke Check · {proj.name}" + (f" · sprint {args.sprint}" if args.sprint else ""))
    print(f"  velocity 5 数:")
    for k in ("planned", "done", "in-progress", "blocked", "abandoned"):
        print(f"    {k:13s}: {velocity.get(k, 0)}")
    print()

    if in_progress:
        print(f"--- in-progress story ({len(in_progress)}) ---")
        for s in in_progress:
            print(f"  - {s['id']}")
        print()

    if blocked:
        print(f"--- blocked story ({len(blocked)}) ---")
        for s in blocked:
            print(f"  - {s['id']}")
        print()

    print("--- 下一步建议 ---")
    print(f"  1. 跑 consistency-check:")
    print(f"     {consistency_hint}")
    if retro_trigger:
        print(f"  2. ⚠️  abandoned 或 blocked 偏多 → 建议跑 retrospective")
        print(f"     spawn pm + designer + engineer 一起做 sprint 复盘")
    else:
        print(f"  2. 全员状态正常，可进入下一 sprint 规划（spawn pm + sprint-plan）")

    return 0


if __name__ == "__main__":
    sys.exit(main())
