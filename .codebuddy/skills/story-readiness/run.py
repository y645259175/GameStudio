#!/usr/bin/env python3
"""
story-readiness run.py · Definition-of-Ready 校验

用法:
  python .codebuddy/skills/story-readiness/run.py --project <name> --story <story-id>
  python .codebuddy/skills/story-readiness/run.py --project <name>  # 批量
"""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

SCRIPT_DIR = Path(__file__).resolve().parents[2] / "scripts"
sys.path.insert(0, str(SCRIPT_DIR))
from skill_lib import (  # type: ignore
    force_utf8, find_workspace_root, find_project, list_projects,
    list_stories, load_story, print_section, emit_skill_call_log,
)

SKILL_NAME = "story-readiness"

VALID_ESTIMATES = {"XS", "S", "M", "L", "XL"}


def check_story(story: dict) -> dict:
    """对一个 story dict 做 DoR 检查，返回 {ready, reasons}。"""
    reasons: list[str] = []

    # 1. AC ≥ 3
    if story["ac_count"] < 3:
        reasons.append(f"验收标准只有 {story['ac_count']} 条 (要求 ≥ 3)")

    # 2. GDD 锚点
    if not story["gdd_anchors"]:
        reasons.append("无 GDD 锚点引用（必须能追溯到 GDD 某节）")

    # 3. 估算
    est = story["estimate"]
    if not est:
        reasons.append("缺估算字段（XS/S/M/L/XL 之一）")
    elif est not in VALID_ESTIMATES:
        reasons.append(f"估算 '{est}' 不在 XS/S/M/L/XL 内")
    elif est == "XL":
        reasons.append("WARN: 估算 = XL，建议拆分（不阻塞 ready）")

    # 4. 用户视角描述
    if not story["has_user_story"]:
        reasons.append("缺用户视角描述（'作为 X，我想 Y，以便 Z' 格式）")

    # 5. 模糊词
    if story["fuzzy_hits"]:
        reasons.append(f"含模糊词: {', '.join(story['fuzzy_hits'])} → 量化")

    # 阻塞性 reason 才让 ready=False
    blocking = [r for r in reasons if not r.startswith("WARN:")]
    return {"id": story["id"], "ready": len(blocking) == 0, "reasons": reasons,
            "estimate": est, "ac_count": story["ac_count"]}


def main():
    force_utf8()
    p = argparse.ArgumentParser(description="story-readiness skill")
    p.add_argument("--project", help="项目名")
    p.add_argument("--story", help="单个 story id（不传则批量）")
    p.add_argument("--json", action="store_true")
    args = p.parse_args()

    ws = find_workspace_root()
    emit_skill_call_log(SKILL_NAME, vars(args), ws)
    proj = find_project(args.project, ws)
    if not proj:
        print(f"[ERROR] 找不到项目（可用: {', '.join(list_projects(ws)) or '无'}）", file=sys.stderr)
        return 1

    stories = list_stories(proj)
    if args.story:
        stories = [s for s in stories if args.story in s.name]
        if not stories:
            print(f"[ERROR] 找不到匹配 '{args.story}' 的 story", file=sys.stderr)
            return 1

    results = [check_story(load_story(sf)) for sf in stories]

    if args.json:
        print(json.dumps({"project": proj.name, "results": results}, ensure_ascii=False, indent=2))
        not_ready = sum(1 for r in results if not r["ready"])
        return 0 if not_ready == 0 else 2

    print_section(f"Story Readiness · {proj.name}")
    ready_count = sum(1 for r in results if r["ready"])
    print(f"  共 {len(results)} story · ready: {ready_count} · not-ready: {len(results)-ready_count}")
    print()

    # 打印每个 story 状态
    for r in results:
        marker = "[READY]" if r["ready"] else "[NOT-READY]"
        est = r["estimate"] or "-"
        print(f"  {marker} {r['id']} · est={est} · ac={r['ac_count']}")
        for reason in r["reasons"]:
            print(f"      - {reason}")
        if r["reasons"]:
            print()

    # 批量场景：列 not-ready 原因 top 3
    if len(results) > 1:
        from collections import Counter
        reason_counter: Counter[str] = Counter()
        for r in results:
            for reason in r["reasons"]:
                # 归一化（去掉 ID/数字后缀方便聚合）
                key = reason.split("（")[0].split(" → ")[0].split(": ")[0][:40]
                reason_counter[key] += 1
        print("--- not-ready 原因 top 3 ---")
        for reason, n in reason_counter.most_common(3):
            print(f"  {n}x  {reason}")

    not_ready = len(results) - ready_count
    return 0 if not_ready == 0 else 2


if __name__ == "__main__":
    sys.exit(main())
