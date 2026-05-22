#!/usr/bin/env python3
"""
story-done run.py · Story 完成验收

用法:
  python .codebuddy/skills/story-done/run.py --project <name> --story <story-id>
  python .codebuddy/skills/story-done/run.py --project <name> --story <story-id> --update-status  # 真改 frontmatter
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

SKILL_NAME = "story-done"


def update_status_in_file(story_file: Path, new_status: str) -> bool:
    """改 story frontmatter 的 status 字段。"""
    text = story_file.read_text(encoding="utf-8")
    if not text.startswith("---"):
        return False
    # 替换 status: xxx 行（在 --- 之间）
    parts = text.split("---", 2)
    if len(parts) < 3:
        return False
    fm_text = parts[1]
    if re.search(r"^status:\s*", fm_text, re.MULTILINE):
        new_fm = re.sub(r"^status:\s*.*$", f"status: {new_status}", fm_text, count=1, flags=re.MULTILINE)
    else:
        # 加一行
        new_fm = fm_text.rstrip() + f"\nstatus: {new_status}\n"
    new_text = "---" + new_fm + "---" + parts[2]
    story_file.write_text(new_text, encoding="utf-8")
    return True


def check_done_readiness(story: dict) -> tuple[bool, list[str]]:
    """检查 story 是否可标记 done。"""
    blockers = []
    if story["status"] not in ("in-progress", "ready", "implementing", "reviewing", "playtest_pending"):
        blockers.append(f"当前 status='{story['status']}'，不在可关闭状态")
    if story["ac_count"] < 3:
        blockers.append(f"AC 数量 {story['ac_count']} (< 3)，应在 dev-story 阶段补完")
    if not story["gdd_anchors"]:
        blockers.append("缺 GDD 锚点引用")
    return len(blockers) == 0, blockers


def main():
    force_utf8()
    p = argparse.ArgumentParser(description="story-done skill")
    p.add_argument("--project", help="项目名")
    p.add_argument("--story", required=True, help="story id")
    p.add_argument("--update-status", action="store_true", help="实际改 frontmatter 为 done")
    p.add_argument("--skip-consistency", action="store_true", help="跳过 consistency-check 提示")
    p.add_argument("--json", action="store_true")
    args = p.parse_args()

    ws = find_workspace_root()
    emit_skill_call_log(SKILL_NAME, vars(args), ws)
    proj = find_project(args.project, ws)
    if not proj:
        print(f"[ERROR] 找不到项目（可用: {', '.join(list_projects(ws)) or '无'}）", file=sys.stderr)
        return 1

    matches = [sf for sf in list_stories(proj) if args.story in sf.name]
    if not matches:
        print(f"[ERROR] 找不到匹配 '{args.story}' 的 story", file=sys.stderr)
        return 1
    if len(matches) > 1:
        print(f"[ERROR] 'arg.story' 匹配多个: {[m.name for m in matches]}", file=sys.stderr)
        return 1

    story_file = matches[0]
    story = load_story(story_file)
    can_done, blockers = check_done_readiness(story)

    consistency_hint = (f"python .codebuddy/skills/consistency-check/run.py --project {proj.name} --story {args.story}")

    result = {
        "project": proj.name,
        "story_id": story["id"],
        "current_status": story["status"],
        "can_done": can_done,
        "blockers": blockers,
        "ac_count": story["ac_count"],
        "consistency_check_hint": consistency_hint,
        "commit_template": f"[story] done {story['id']}: <短描述>",
    }

    # 如果 OK + 用户要求真改
    if can_done and args.update_status:
        ok = update_status_in_file(story_file, "done")
        result["status_updated"] = ok
        result["new_status"] = "done" if ok else story["status"]

    if args.json:
        print(json.dumps(result, ensure_ascii=False, indent=2))
        return 0 if can_done else 2

    print_section(f"Story-Done · {story['id']}")
    print(f"  当前状态: {story['current_status'] if False else story['status']}")
    print(f"  AC 数量:   {story['ac_count']}")
    print()
    if can_done:
        print("  [PASS] 可以标记 done")
        if args.update_status:
            print(f"         frontmatter 已改 status: done -> {story_file.relative_to(ws).as_posix()}")
        else:
            print(f"         未真改 frontmatter（加 --update-status 真改）")
    else:
        print("  [BLOCK] 不能标记 done，原因:")
        for b in blockers:
            print(f"    - {b}")
    print()
    if not args.skip_consistency:
        print("  下一步建议:")
        print(f"    1. 跑 consistency-check:")
        print(f"       {consistency_hint}")
        print(f"    2. critical = 0 后 commit:")
        print(f"       {result['commit_template']}")

    return 0 if can_done else 2


if __name__ == "__main__":
    sys.exit(main())
