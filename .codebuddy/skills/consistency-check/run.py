#!/usr/bin/env python3
"""
consistency-check run.py · 跨产物一致性扫描

可执行版：扫 GDD 完整度 + GDD↔stories 锚点 + stories↔代码 grep + 输出 critical/warn/info 报告

用法:
  python .codebuddy/skills/consistency-check/run.py --project <name>
  python .codebuddy/skills/consistency-check/run.py --project <name> --json
  python .codebuddy/skills/consistency-check/run.py --project <name> --story <story-id>

无 --project 时从 cwd 推断；无法推断则列出可选项。
"""

from __future__ import annotations

import argparse
import json
import re
import sys
from datetime import datetime
from pathlib import Path

# 加载共享库
SCRIPT_DIR = Path(__file__).resolve().parents[2] / "scripts"
sys.path.insert(0, str(SCRIPT_DIR))
from skill_lib import (  # type: ignore
    force_utf8, find_workspace_root, find_project, list_projects,
    list_stories, load_story, gdd_completeness, print_section,
    emit_skill_call_log,
)

SKILL_NAME = "consistency-check"


def check_consistency(proj: Path, only_story: str | None = None) -> dict:
    issues: list[dict] = []

    # 1. GDD 完整性
    gdd = gdd_completeness(proj)
    if gdd["missing"]:
        for sec in gdd["missing"]:
            issues.append({"level": "warn", "category": "gdd-completeness",
                           "msg": f"GDD 缺章节: {sec}", "fix": f"补 gdd/<n>-{sec}.md"})
    if not gdd["files"]:
        issues.append({"level": "critical", "category": "gdd-completeness",
                       "msg": "GDD 目录为空", "fix": "spawn designer agent 起草 GDD"})

    # 2. stories 解析
    stories = list_stories(proj)
    if only_story:
        stories = [s for s in stories if only_story in s.name]
    if not stories and not only_story:
        issues.append({"level": "warn", "category": "stories",
                       "msg": "stories/ 目录无 story 文件", "fix": "spawn pm 加 backlog → create-stories"})

    # 3. 每个 story 检查
    story_summaries = []
    gdd_files_lower = [f.lower() for f in gdd["files"]]
    for sf in stories:
        s = load_story(sf)
        story_summaries.append(s)
        # 3a. GDD 锚点存在性
        if not s["gdd_anchors"]:
            issues.append({"level": "warn", "category": "story-gdd-anchor",
                           "msg": f"{s['id']} 没有 GDD 锚点引用", "fix": "story body 加 gdd/X.md 引用"})
        else:
            for anchor in s["gdd_anchors"]:
                target_file = anchor.split("#")[0].lower().split("/")[-1]
                if target_file and target_file not in gdd_files_lower:
                    issues.append({"level": "critical", "category": "story-gdd-anchor",
                                   "msg": f"{s['id']} 引用 {anchor} 但 GDD 中无该文件",
                                   "fix": f"补 gdd/{target_file} 或修正 story 锚点"})
        # 3b. AC 数量
        if s["status"] != "draft" and s["ac_count"] < 3:
            issues.append({"level": "warn", "category": "story-ac",
                           "msg": f"{s['id']} 验收标准只有 {s['ac_count']} 条 (< 3)",
                           "fix": "补充 AC 至少 3 条"})

    # 4. done story → 代码改动 grep
    code_dir = proj / "game"
    if code_dir.exists():
        all_code = ""
        for ext in ("*.gd", "*.cs", "*.cpp", "*.py", "*.js", "*.ts"):
            for f in code_dir.rglob(ext):
                try:
                    all_code += f.read_text(encoding="utf-8", errors="ignore") + "\n"
                except Exception:
                    pass
        for s in story_summaries:
            if s["status"] == "done":
                story_id = s["id"]
                # 在代码 / commit msg 中找 story id 痕迹
                if story_id and story_id not in all_code:
                    # 不强报，只 info（commit msg 已 grep 过的就可以）
                    issues.append({"level": "info", "category": "story-code-link",
                                   "msg": f"{story_id} done 但代码中未找到引用",
                                   "fix": "确认代码 commit msg 含 story-id（commit-discipline rule）"})

    # 5. GDD ↔ 实现一致性 grep（BL-S034 · AP-10 修法）
    # 扫 GDD 中提到的关键概念，检查代码中是否有对应实现
    GDD_KEYWORDS = ["camera", "boundary", "feedback", "death", "win", "spawn",
                    "kill_zone", "goal", "score", "health", "damage", "level"]
    gdd_dir = proj / "gdd"
    if code_dir.exists() and gdd_dir.exists():
        # 收集 GDD 中实际出现的关键词
        gdd_text = ""
        for gf in gdd_dir.rglob("*.md"):
            try:
                gdd_text += gf.read_text(encoding="utf-8", errors="ignore").lower() + "\n"
            except Exception:
                pass
        mentioned_in_gdd = [kw for kw in GDD_KEYWORDS if kw in gdd_text]
        if mentioned_in_gdd and all_code:
            code_lower = all_code.lower()
            missing_in_code = [kw for kw in mentioned_in_gdd if kw not in code_lower]
            for kw in missing_in_code:
                issues.append({"level": "warn", "category": "gdd-impl-gap",
                               "msg": f"GDD 提到 '{kw}' 但代码中未找到对应实现",
                               "fix": f"确认 '{kw}' 相关功能是否已实现（可能命名不同）或尚在 backlog"})

    # 6. data-driven 红线扫（魔法数字检测）—— 只在显式启用时跑
    # （此处简化跳过；可由用户后续手动 grep）

    # 汇总
    counts = {"critical": 0, "warn": 0, "info": 0}
    for i in issues:
        counts[i["level"]] = counts.get(i["level"], 0) + 1

    return {
        "project": proj.name,
        "scanned_stories": len(stories),
        "gdd_present": gdd["present"],
        "gdd_missing": gdd["missing"],
        "issues": issues,
        "counts": counts,
    }


def write_report(result: dict, proj: Path) -> Path:
    report_dir = proj / "reports"
    report_dir.mkdir(exist_ok=True)
    ts = datetime.now().strftime("%Y-%m-%d-%H%M")
    rf = report_dir / f"consistency-{ts}.md"
    lines = [f"# Consistency Check · {proj.name} · {ts}\n"]
    c = result["counts"]
    lines.append(f"**critical: {c['critical']}** · warn: {c['warn']} · info: {c['info']}")
    lines.append(f"扫描 {result['scanned_stories']} 个 story · GDD 完整度: "
                 f"{len(result['gdd_present'])}/8 ({', '.join(result['gdd_present']) or '空'})\n")
    if result["gdd_missing"]:
        lines.append(f"GDD 缺章节: {', '.join(result['gdd_missing'])}\n")
    lines.append("## Issues\n")
    for level in ("critical", "warn", "info"):
        items = [i for i in result["issues"] if i["level"] == level]
        if items:
            lines.append(f"### {level.upper()} ({len(items)})\n")
            for i in items:
                lines.append(f"- [{i['category']}] {i['msg']}")
                lines.append(f"  - **修法**: {i['fix']}")
            lines.append("")
    rf.write_text("\n".join(lines), encoding="utf-8")
    return rf


def main():
    force_utf8()
    p = argparse.ArgumentParser(description="consistency-check skill")
    p.add_argument("--project", help="项目名（默认从 cwd 推断）")
    p.add_argument("--story", help="只扫某个 story id")
    p.add_argument("--json", action="store_true", help="JSON 输出")
    p.add_argument("--no-report", action="store_true", help="不写 reports/ 文件")
    args = p.parse_args()

    ws = find_workspace_root()
    emit_skill_call_log(SKILL_NAME, vars(args), ws)
    proj = find_project(args.project, ws)
    if not proj:
        avail = list_projects(ws)
        print(f"[ERROR] 找不到项目（可用: {', '.join(avail) or '无'}）", file=sys.stderr)
        return 1

    result = check_consistency(proj, args.story)

    if args.json:
        print(json.dumps(result, ensure_ascii=False, indent=2))
        return 0 if result["counts"]["critical"] == 0 else 2

    print_section(f"Consistency Check · {proj.name}")
    c = result["counts"]
    print(f"  critical: {c['critical']}  warn: {c['warn']}  info: {c['info']}")
    print(f"  GDD 完整度: {len(result['gdd_present'])}/8 ({', '.join(result['gdd_present']) or '空'})")
    print(f"  扫描 story: {result['scanned_stories']} 条")
    print()
    if result["issues"]:
        for level in ("critical", "warn", "info"):
            items = [i for i in result["issues"] if i["level"] == level]
            if not items:
                continue
            print(f"--- {level.upper()} ({len(items)}) ---")
            for i in items[:10]:
                print(f"  [{i['category']}] {i['msg']}")
                print(f"    fix: {i['fix']}")
            if len(items) > 10:
                print(f"  ... 还有 {len(items)-10} 条，详见报告")
            print()

    if not args.no_report:
        rf = write_report(result, proj)
        print(f"报告: {rf.relative_to(ws).as_posix()}")

    return 0 if c["critical"] == 0 else 2


if __name__ == "__main__":
    sys.exit(main())
