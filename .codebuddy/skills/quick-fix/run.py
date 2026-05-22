#!/usr/bin/env python3
"""
quick-fix run.py · 轻通道路由 + tag 推荐

接收一段改动描述，给出：
  1. 是否够格走轻通道（vs 应升级到 dev-story）
  2. 推荐的 commit tag
  3. 测试要求

用法:
  python .codebuddy/skills/quick-fix/run.py --description "修一个 player 死亡卡顿 bug"
  python .codebuddy/skills/quick-fix/run.py --files-changed 3 --type fix
"""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

SCRIPT_DIR = Path(__file__).resolve().parents[2] / "scripts"
sys.path.insert(0, str(SCRIPT_DIR))
from skill_lib import force_utf8, find_workspace_root, print_section, emit_skill_call_log  # type: ignore

SKILL_NAME = "quick-fix"

KEYWORDS = {
    "fix": ["bug", "fix", "修", "崩", "crash", "error", "wrong"],
    "refactor": ["refactor", "重构", "rename", "extract", "整理", "拆分"],
    "quick": ["typo", "格式", "format", "config", "依赖", "version", "升级", "upgrade", "comment", "注释"],
    "perf": ["perf", "优化", "速度", "性能", "lag", "卡"],
}

UPGRADE_HINTS = [
    ("跨多文件", "如改动跨 ≥ 3 文件 → 应走 dev-story"),
    ("新增功能", "新增功能（不是修复）→ 应走 dev-story"),
    ("影响多 system", "改动跨多个系统 → 应走 dev-story"),
    ("大于 200 行", "改动 > 200 行 → 应走 dev-story"),
]


def detect_tag(desc: str) -> tuple[str, list[str]]:
    """根据描述识别 tag 候选。"""
    desc_lower = desc.lower()
    matched = []
    for tag, words in KEYWORDS.items():
        if any(w.lower() in desc_lower for w in words):
            matched.append(tag)
    if not matched:
        return "quick", ["（未匹配关键词，默认 [quick]）"]
    # 优先级：fix > refactor > perf > quick
    for t in ("fix", "refactor", "perf", "quick"):
        if t in matched:
            return t, [f"匹配关键词 → [{t}]"]
    return matched[0], [f"匹配 → [{matched[0]}]"]


def assess_scope(files_changed: int | None, lines_changed: int | None) -> tuple[str, list[str]]:
    """评估改动规模 → quick / dev-story 路由。"""
    reasons: list[str] = []
    upgrade = False
    if files_changed is not None and files_changed >= 3:
        upgrade = True
        reasons.append(f"改动跨 {files_changed} 文件 (≥ 3) → 推荐升级 dev-story")
    if lines_changed is not None and lines_changed > 200:
        upgrade = True
        reasons.append(f"改动 {lines_changed} 行 (> 200) → 推荐升级 dev-story")
    return ("dev-story" if upgrade else "quick-fix"), reasons


def test_requirement(tag: str) -> str:
    if tag == "fix":
        return "必须加回归测试（test-standards rule）"
    if tag == "refactor":
        return "必须跑既有测试套件（refactor 不应破坏行为）"
    if tag == "perf":
        return "必须有 before/after 数据（不是凭感觉说快了）"
    return "建议加 smoke 验证不破坏既有路径"


def main():
    force_utf8()
    p = argparse.ArgumentParser(description="quick-fix skill")
    p.add_argument("--description", "-d", default="", help="改动描述")
    p.add_argument("--files-changed", type=int, help="预计改动文件数")
    p.add_argument("--lines-changed", type=int, help="预计改动行数")
    p.add_argument("--type", choices=["fix", "refactor", "quick", "perf"], help="强制指定 tag")
    p.add_argument("--json", action="store_true")
    args = p.parse_args()

    ws = find_workspace_root()
    emit_skill_call_log(SKILL_NAME, vars(args), ws)

    # tag 决策
    if args.type:
        tag, tag_reasons = args.type, [f"用户显式指定 → [{args.type}]"]
    elif args.description:
        tag, tag_reasons = detect_tag(args.description)
    else:
        tag, tag_reasons = "quick", ["未提供描述，默认 [quick]"]

    # 路由决策
    route, route_reasons = assess_scope(args.files_changed, args.lines_changed)

    # 测试要求
    test_req = test_requirement(tag)

    # 建议 commit msg 格式
    commit_template = f"[{tag}] <短描述>"
    if args.description:
        # 截取前 50 字
        short = args.description[:50] + ("..." if len(args.description) > 50 else "")
        commit_template = f"[{tag}] {short}"

    result = {
        "tag": tag,
        "tag_reasons": tag_reasons,
        "route": route,
        "route_reasons": route_reasons,
        "test_requirement": test_req,
        "commit_template": commit_template,
        "should_upgrade": route == "dev-story",
    }

    if args.json:
        print(json.dumps(result, ensure_ascii=False, indent=2))
        return 0

    print_section(f"Quick-Fix 决策")
    print(f"  推荐 tag:    [{tag}]")
    for r in tag_reasons:
        print(f"    {r}")
    print()
    print(f"  路由:        {route}")
    for r in route_reasons:
        print(f"    {r}")
    print()
    print(f"  测试要求:    {test_req}")
    print()
    print(f"  commit 模板: {commit_template}")
    print()
    if result["should_upgrade"]:
        print("  ⚠️  改动规模偏大，建议升级到 dev-story 重通道：")
        print("      python .codebuddy/skills/dev-story/run.py --action plan ...")

    return 0


if __name__ == "__main__":
    sys.exit(main())
