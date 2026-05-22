#!/usr/bin/env python3
"""
agent_metrics.py · 度量工具

用途：扫 .codebuddy/logs/ 给出 agent / skill / 工具调用统计
回答两类问题：
  1. 今天 / 本周 spawn 了哪些 sub-agent？
  2. 哪些 skill 真被调用过？哪些是死代码？

用法：
  python .codebuddy/scripts/agent_metrics.py            # 默认看今天
  python .codebuddy/scripts/agent_metrics.py --days 7   # 看最近 7 天
  python .codebuddy/scripts/agent_metrics.py --all      # 看全部历史
  python .codebuddy/scripts/agent_metrics.py --json     # 机器可读输出
"""

from __future__ import annotations

import argparse
import json
import sys
from collections import Counter, defaultdict
from datetime import date, datetime, timedelta
from pathlib import Path

WORKSPACE = Path(__file__).resolve().parents[2]
LOG_DIR = WORKSPACE / ".codebuddy" / "logs"


def _force_utf8():
    if sys.platform == "win32":
        try:
            sys.stdout.reconfigure(encoding="utf-8")  # type: ignore[attr-defined]
        except Exception:
            pass


def date_range(days: int | None) -> list[str]:
    """生成日期字符串列表（YYYY-MM-DD），days=None 表示全部历史。"""
    if days is None:
        return []  # 表示扫描所有匹配文件
    today = date.today()
    return [(today - timedelta(days=i)).isoformat() for i in range(days)]


def load_jsonl(prefix: str, dates: list[str]) -> list[dict]:
    """加载指定日期的 jsonl 文件。dates 为空列表 = 加载所有该 prefix 的文件。"""
    if not LOG_DIR.exists():
        return []
    rows: list[dict] = []
    if dates:
        files = [LOG_DIR / f"{prefix}-{d}.jsonl" for d in dates]
    else:
        files = sorted(LOG_DIR.glob(f"{prefix}-*.jsonl"))
    for f in files:
        if not f.exists():
            continue
        try:
            for line in f.read_text(encoding="utf-8").splitlines():
                if not line.strip():
                    continue
                try:
                    rows.append(json.loads(line))
                except Exception:
                    pass
        except Exception:
            pass
    return rows


def fmt_table(rows: list[tuple], headers: list[str]) -> str:
    if not rows:
        return "  (无记录)\n"
    widths = [max(len(str(h)), max(len(str(r[i])) for r in rows)) for i, h in enumerate(headers)]
    lines = []
    lines.append("  " + "  ".join(str(h).ljust(widths[i]) for i, h in enumerate(headers)))
    lines.append("  " + "  ".join("-" * widths[i] for i in range(len(headers))))
    for r in rows:
        lines.append("  " + "  ".join(str(r[i]).ljust(widths[i]) for i in range(len(headers))))
    return "\n".join(lines) + "\n"


def report_agents(spawns: list[dict]) -> dict:
    """统计 agent spawn 情况。"""
    agent_counter: Counter[str] = Counter()
    team_count = 0
    desc_samples: dict[str, list[str]] = defaultdict(list)
    for s in spawns:
        name = s.get("subagent_name", "unknown")
        agent_counter[name] += 1
        if s.get("team_mode"):
            team_count += 1
        desc = s.get("description", "")
        if desc and len(desc_samples[name]) < 3:
            desc_samples[name].append(desc)
    return {
        "total": sum(agent_counter.values()),
        "team_mode": team_count,
        "by_agent": dict(agent_counter.most_common()),
        "samples": {k: v for k, v in desc_samples.items()},
    }


def report_skills(calls: list[dict]) -> dict:
    """统计 skill 调用情况。"""
    skill_counter: Counter[str] = Counter()
    for c in calls:
        skill_counter[c.get("skill_name", "unknown")] += 1
    return {
        "total": sum(skill_counter.values()),
        "by_skill": dict(skill_counter.most_common()),
    }


def report_tools(tools: list[dict]) -> dict:
    """统计 PreToolUse 工具调用分布。"""
    tool_counter: Counter[str] = Counter()
    for t in tools:
        tool_counter[t.get("tool_name", "unknown")] += 1
    return {
        "total": sum(tool_counter.values()),
        "by_tool": dict(tool_counter.most_common()),
    }


def discover_inventory() -> dict:
    """扫 .codebuddy/agents 和 skills，给出"已注册"清单（用于对比"被调用"）。"""
    agents_dir = WORKSPACE / ".codebuddy" / "agents"
    skills_dir = WORKSPACE / ".codebuddy" / "skills"
    agents = sorted(d.name for d in agents_dir.iterdir() if d.is_dir()) if agents_dir.exists() else []
    skills = sorted(d.name for d in skills_dir.iterdir() if d.is_dir()) if skills_dir.exists() else []
    skills_with_runner = [s for s in skills if (skills_dir / s / "run.py").exists() or (skills_dir / s / "run.sh").exists()]
    return {"agents_total": len(agents), "skills_total": len(skills), "skills_executable": len(skills_with_runner),
            "agents": agents, "skills_executable_list": skills_with_runner}


def print_text_report(spawns_rep: dict, skills_rep: dict, tools_rep: dict, inv: dict, period_label: str):
    print(f"# Agent / Skill 度量报告 · {period_label}")
    print(f"工作区：{WORKSPACE.as_posix()}")
    print()

    # === 1. agent spawn ===
    print("=" * 70)
    print(f"1. Sub-Agent Spawn 统计 · {period_label}")
    print("=" * 70)
    print(f"  总 spawn: {spawns_rep['total']} 次  (team mode: {spawns_rep['team_mode']})")
    print(f"  注册 agent: {inv['agents_total']} · 真被 spawn 过: {len(spawns_rep['by_agent'])}")
    cov = (len(spawns_rep['by_agent']) / inv['agents_total'] * 100) if inv['agents_total'] else 0
    print(f"  agent 覆盖率: {cov:.0f}% (这个周期内被用过的 agent 占比)")
    print()
    if spawns_rep["by_agent"]:
        print(fmt_table(
            [(name, n) for name, n in spawns_rep["by_agent"].items()],
            ["agent", "spawn 次数"]
        ))
    else:
        print("  （无 spawn 记录 —— 检查 hook 是否真在跑：cat .codebuddy/logs/agent-spawn-*.jsonl）")
        print()

    # 哪些 agent 从来没被用过
    used = set(spawns_rep["by_agent"].keys())
    never_used = [a for a in inv["agents"] if a not in used]
    if never_used and spawns_rep["total"] > 0:
        print(f"  在该周期内从未被 spawn 的 agent ({len(never_used)} 个):")
        # 只显示前 10 个
        for a in never_used[:10]:
            print(f"    - {a}")
        if len(never_used) > 10:
            print(f"    ... 还有 {len(never_used)-10} 个")
        print()

    # === 2. skill 调用 ===
    print("=" * 70)
    print(f"2. Skill 调用统计 · {period_label}")
    print("=" * 70)
    print(f"  总调用: {skills_rep['total']} 次")
    print(f"  注册 skill: {inv['skills_total']} · 可执行（有 run.py）: {inv['skills_executable']}")
    print()
    if skills_rep["by_skill"]:
        print(fmt_table(
            [(name, n) for name, n in skills_rep["by_skill"].items()],
            ["skill", "调用次数"]
        ))
        # 可执行但从未被调用 = 死代码候选
        used = set(skills_rep["by_skill"].keys())
        dead = [s for s in inv["skills_executable_list"] if s not in used]
        if dead:
            print(f"  可执行但本周期未被调用的 skill ({len(dead)}):")
            for s in dead:
                print(f"    - {s}")
            print()
    else:
        print("  （无 skill 调用记录 —— skill 体系本周期内未被使用）")
        print()

    # === 3. 工具调用分布（参考）===
    print("=" * 70)
    print(f"3. PreToolUse 工具调用分布 · {period_label}")
    print("=" * 70)
    print(f"  总调用: {tools_rep['total']} 次")
    print()
    if tools_rep["by_tool"]:
        rows = [(name, n) for name, n in list(tools_rep["by_tool"].items())[:12]]
        print(fmt_table(rows, ["tool", "调用次数"]))


def main():
    _force_utf8()
    p = argparse.ArgumentParser(description="agent / skill 度量工具")
    p.add_argument("--days", type=int, default=1, help="统计最近 N 天（默认 1，今天）")
    p.add_argument("--all", action="store_true", help="统计所有历史日志")
    p.add_argument("--json", action="store_true", help="输出 JSON 格式")
    args = p.parse_args()

    if args.all:
        dates = []  # 加载所有
        period_label = "全部历史"
    else:
        dates = date_range(args.days)
        if args.days == 1:
            period_label = f"今天 ({dates[0]})"
        else:
            period_label = f"最近 {args.days} 天 ({dates[-1]} ~ {dates[0]})"

    spawns = load_jsonl("agent-spawn", dates)
    skills = load_jsonl("skill-call", dates)
    tools = load_jsonl("pre-tool-hook", dates)

    inv = discover_inventory()
    spawns_rep = report_agents(spawns)
    skills_rep = report_skills(skills)
    tools_rep = report_tools(tools)

    if args.json:
        out = {
            "period": period_label,
            "inventory": inv,
            "spawns": spawns_rep,
            "skill_calls": skills_rep,
            "tools": tools_rep,
        }
        print(json.dumps(out, ensure_ascii=False, indent=2))
    else:
        print_text_report(spawns_rep, skills_rep, tools_rep, inv, period_label)


if __name__ == "__main__":
    main()
