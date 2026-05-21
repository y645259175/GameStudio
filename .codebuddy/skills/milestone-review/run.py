#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
milestone-review · run.py · 命令行可执行版

把 milestone-review skill 从"流程文档"升级为"可执行 pipeline"。
兑现 SKILL.md 中的 3 处 [Phase 2 TODO]：
  1. 各 stage 准入条件（硬编码到本脚本）
  2. "拆分"决策的执行机制（提供建议，由 producer agent 拍板）
  3. 趋势分析（最近 3 次 milestone-review 报告对比）

行为：
1. 读 PROJECT.md 校验当前 stage / target stage
2. 调 qa-gate/run.py 拿 verdict（subprocess）
3. 聚合最近 3 sprint smoke + 全部 retros action items + backlog due 检查
4. 生成 3 份 spawn-prompt（qa-lead 看测试 / reviewer 看代码 / producer 拍板，
   对应 agent-spawn-contract 模板库的 TPL-02a/2b/2c）
5. 写一份 driver report（草稿）等三方填充

设计决策：
- run.py 只准备数据 + 起草 prompt，**不直接调 LLM**，main agent 拾取后用 task spawn
- 3 个 prompt 必须独立落盘（main agent 可并行 spawn）

用法：
    python .codebuddy/skills/milestone-review/run.py \
        --project bolt-1-1 \
        --from production \
        --to polish
"""

from __future__ import annotations

import argparse
import datetime
import io
import json
import re
import subprocess
import sys
from pathlib import Path

if sys.platform == "win32":
    try:
        sys.stdout.reconfigure(encoding="utf-8", errors="replace")  # type: ignore[attr-defined]
        sys.stderr.reconfigure(encoding="utf-8", errors="replace")  # type: ignore[attr-defined]
    except Exception:  # noqa: BLE001
        sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8", errors="replace")
        sys.stderr = io.TextIOWrapper(sys.stderr.buffer, encoding="utf-8", errors="replace")

WORKSPACE = Path(__file__).resolve().parents[3]
TEMP_DIR = WORKSPACE / ".codebuddy" / "temp"
QA_GATE_RUN = WORKSPACE / ".codebuddy" / "skills" / "qa-gate" / "run.py"

# ---------------------------------------------------------------------------
# Stage 准入条件（兑现 SKILL.md 的 [Phase 2 TODO] 1）
# ---------------------------------------------------------------------------

STAGE_GATES: dict[tuple[str, str], dict] = {
    ("pre-production", "production"): {
        "required_qa_scope": "milestone",
        "required_artifacts": [
            "gdd/gdd-1-overview.md",
            "gdd/gdd-2-pillars.md",
        ],
        "checklist": [
            "8 节 GDD 完整（gdd-1 ~ gdd-8 至少有 5 节存在）",
            "核心玩法 prototype 通过（real_playtest PASS）",
            "引擎选定（PROJECT.md 含 engine 字段）",
        ],
    },
    ("production", "polish"): {
        "required_qa_scope": "milestone",
        "required_artifacts": [
            "stories/backlog.md",
        ],
        "checklist": [
            "所有 P0 epics done（backlog 无 P0 open）",
            "smoke-check 全过（最近 3 sprint 无 FAIL）",
            "核心 bug = 0（P0 bug count 0）",
            "核心 stories 全 done",
        ],
    },
    ("polish", "release"): {
        "required_qa_scope": "release",
        "required_artifacts": [
            "releases/release-checklist.md",
        ],
        "checklist": [
            "release-checklist 全部勾选",
            "consistency-check critical = 0",
            "视觉债 = 0",
            "release notes 草稿就绪",
        ],
    },
}


# ---------------------------------------------------------------------------
# 工具
# ---------------------------------------------------------------------------

def _now() -> str:
    return datetime.datetime.now().strftime("%Y-%m-%d_%H%M%S")


def _today() -> str:
    return datetime.datetime.now().strftime("%Y-%m-%d")


def _project_dir(project: str) -> Path:
    return WORKSPACE / "projects" / project


def _read_text_safe(path: Path) -> str:
    try:
        return path.read_text(encoding="utf-8", errors="replace")
    except Exception:  # noqa: BLE001
        return ""


# ---------------------------------------------------------------------------
# 数据聚合
# ---------------------------------------------------------------------------

def parse_project_md(project_dir: Path) -> dict:
    p = project_dir / "PROJECT.md"
    if not p.exists():
        return {"exists": False}
    text = _read_text_safe(p)
    m_stage = re.search(r"^\s*stage\s*[:=]\s*([\w\-]+)", text, re.M | re.I)
    m_phase = re.search(r"^\s*phase\s*[:=]\s*([\w\-\.]+)", text, re.M | re.I)
    m_engine = re.search(r"^\s*engine\s*[:=]\s*([\w\-\.\s]+)", text, re.M | re.I)
    return {
        "exists": True,
        "path": str(p),
        "stage": (m_stage.group(1) if m_stage else None),
        "phase": (m_phase.group(1) if m_phase else None),
        "engine": (m_engine.group(1).strip() if m_engine else None),
    }


def collect_sprint_reports(project_dir: Path, limit: int = 3) -> list[dict]:
    sprints_dir = project_dir / "sprints"
    if not sprints_dir.exists():
        return []
    smoke_files = sorted(sprints_dir.glob("sprint-*-smoke.md"), reverse=True)[:limit]
    out = []
    for f in smoke_files:
        text = _read_text_safe(f)
        # 启发式找 verdict
        m = re.search(r"\bverdict\b[^\n]*?\b(PASS|FAIL|CONDITIONAL)\w*\b", text, re.I)
        out.append({
            "file": str(f.relative_to(WORKSPACE)).replace("\\", "/"),
            "verdict": m.group(1).upper() if m else "UNKNOWN",
            "size_lines": len(text.splitlines()),
        })
    return out


def collect_retro_action_items(project_dir: Path) -> list[dict]:
    """从 retros/*.md 提取 open action items"""
    retros_dir = project_dir / "retros"
    if not retros_dir.exists():
        return []
    items: list[dict] = []
    for f in sorted(retros_dir.glob("*.md"), reverse=True):
        text = _read_text_safe(f)
        # 找 markdown 复选框未完成项
        for line in text.splitlines():
            m = re.match(r"\s*-\s*\[ \]\s*(.+)", line)
            if m:
                items.append({
                    "retro": f.name,
                    "item": m.group(1).strip()[:200],
                })
    return items


def check_backlog_due(project_dir: Path, current_milestone: str) -> dict:
    """检查 backlog 中 due ≤ 当前 milestone 的项是否全 done"""
    backlog = project_dir / "stories" / "backlog.md"
    if not backlog.exists():
        return {"exists": False, "blockers": []}

    text = _read_text_safe(backlog)
    blockers: list[str] = []
    # 简单解析表格行：寻找含 due milestone 列的行
    for line in text.splitlines():
        if "|" not in line:
            continue
        if re.match(r"\s*\|\s*-+", line):
            continue
        cells = [c.strip() for c in line.split("|")]
        if len(cells) < 6:
            continue
        # 找形如 M1/M2/.../M9 的 milestone 标识
        m_due = None
        for c in cells:
            mm = re.fullmatch(r"M\d+(\.\d+)?", c)
            if mm:
                m_due = c
                break
        if not m_due:
            continue
        # 状态列 — 最后几列里找 open / done
        status_cell = " ".join(cells[-3:]).lower()
        if "done" in status_cell or "closed" in status_cell:
            continue
        # 比较 milestone（简单字符串比较 M2 < M3）
        if _milestone_le(m_due, current_milestone):
            blockers.append(line.strip()[:200])

    return {
        "exists": True,
        "blockers": blockers,
        "count": len(blockers),
    }


def _milestone_le(a: str, b: str) -> bool:
    """比较 M1.2 <= M2 等"""
    def parse(x: str) -> tuple[int, int]:
        m = re.fullmatch(r"M(\d+)(?:\.(\d+))?", x)
        if not m:
            return (0, 0)
        return (int(m.group(1)), int(m.group(2) or 0))
    return parse(a) <= parse(b)


def trend_analysis(project_dir: Path) -> dict:
    """兑现 [Phase 2 TODO] 3：最近 3 次 milestone-review 对比"""
    reports_dir = project_dir / "reports"
    if not reports_dir.exists():
        return {"available": False}
    candidates = sorted(reports_dir.glob("milestone-*.md"), reverse=True)[:3]
    if len(candidates) < 2:
        return {"available": False, "reason": "历史 milestone 报告不足 2 次"}
    history = []
    for f in candidates:
        text = _read_text_safe(f)
        m = re.search(r"\b(GATE_PASSED|CONDITIONAL_PASS|GATE_FAILED|ADVANCE|HOLD)\b", text)
        history.append({"file": f.name, "verdict": m.group(1) if m else "UNKNOWN"})
    return {"available": True, "history": history}


def call_qa_gate(project: str, scope: str, milestone: str) -> dict:
    """调 qa-gate/run.py 拿 verdict（用 --json）"""
    if not QA_GATE_RUN.exists():
        return {"error": f"qa-gate run.py 不存在: {QA_GATE_RUN}"}
    try:
        result = subprocess.run(
            [sys.executable, str(QA_GATE_RUN),
             "--project", project, "--scope", scope, "--milestone", milestone, "--json"],
            capture_output=True, text=True, timeout=600, encoding="utf-8", errors="replace",
        )
        if result.returncode != 0:
            return {"error": f"qa-gate 退出 {result.returncode}", "stderr": result.stderr[-500:]}
        return json.loads(result.stdout)
    except Exception as e:  # noqa: BLE001
        return {"error": f"调用 qa-gate 失败: {e}"}


# ---------------------------------------------------------------------------
# 三方 spawn-prompt 生成
# ---------------------------------------------------------------------------

PROMPT_QA_LEAD = """你是 qa-lead agent。本次任务：为 {project} 的 {from_stage} → {to_stage} milestone gate 提供**测试维度**判断。

## 任务模式（agent-spawn-contract 契约）
- Mode: REVIEW
- Output path: projects/{project}/reports/milestone-{from_stage}-to-{to_stage}-qa-lead-{date}.md
- Output mode: new_file

## 现状注入

### qa-gate run.py 已自动跑出 verdict（详见 {qa_gate_metrics_rel}）
- Verdict: {qa_gate_verdict}
- fail: {qa_gate_fail} · N/A: {qa_gate_na}

### 最近 sprint smoke 报告（{sprint_count} 份）
{sprint_summary}

### 准入条件 checklist（{from_stage} → {to_stage}）
{checklist}

## 你要回答的 5 个问题
1. 测试通过率符合 milestone 阈值吗？（参见 qa-gate 阈值表）
2. P0 bug 数 = 0 吗？
3. 真实玩家路径测试（非 cheat）是否 ≥ 1 PASS？
4. 视觉债务（VISUAL_DEBT）是否 ≤ 2？
5. 综合 verdict: GATE_PASSED / CONDITIONAL_PASS / GATE_FAILED

## 交付协议
1. 落盘报告
2. read_file 验证
3. send_message(type="message", content="qa-lead milestone judgement: <verdict>; report: <path>; ...")
4. 等 main agent 确认
5. shutdown_response approve=true

## 不允许
- 跳过 N/A 项的根因分析
- 把内容塞 shutdown reason
"""

PROMPT_REVIEWER = """你是 reviewer agent。本次任务：从**代码质量维度**评估 {project} milestone gate（{from_stage} → {to_stage}）。

## 任务模式
- Mode: REVIEW
- Output path: projects/{project}/reports/milestone-{from_stage}-to-{to_stage}-reviewer-{date}.md
- Output mode: new_file

## 现状注入
1. git log 输出由 main agent 在 spawn 时 inject（用 `git log --oneline <FROM_TAG>..HEAD`）
2. read_file 关键代码文件清单：
{code_files_hint}

3. 关联 rule: `commit-discipline` / `code-standards`
4. 历史趋势：{trend_summary}

## 你要回答的 3 个问题
1. 本 milestone 期间 commit 是否遵守 commit-discipline rule？（[story]/[fix]/[chore]/[hotfix] tag）
2. 是否存在大改动未经 reviewer / 未 amend 的 commit？
3. 代码质量综合：CLEAN / MINOR_ISSUES / MAJOR_ISSUES

## 交付协议
（同 qa-lead）
"""

PROMPT_PRODUCER = """你是 producer agent。本次任务：综合 qa-lead 与 reviewer 的两份报告，对 {project} 的 milestone gate ({from_stage} → {to_stage}) 做**最终拍板**。

## 任务模式
- Mode: REVIEW（综合 + 写最终报告）
- Output path: projects/{project}/reports/milestone-{from_stage}-to-{to_stage}-{date}.md（顶层综合报告）
- Output mode: new_file

## 现状注入
1. read_file qa-lead 子报告: projects/{project}/reports/milestone-{from_stage}-to-{to_stage}-qa-lead-{date}.md
2. read_file reviewer 子报告: projects/{project}/reports/milestone-{from_stage}-to-{to_stage}-reviewer-{date}.md
3. read_file projects/{project}/PROJECT.md（验证 stage 字段）
4. read_file projects/{project}/stories/backlog.md（检查 due ≤ 当前 milestone 是否全 done）

## qa-gate 自动评估摘要
- Verdict: {qa_gate_verdict}
- 阻塞 backlog 项: {backlog_blockers_count}
- 历史趋势: {trend_summary}

## 你要决定的 3 件事
1. 综合 verdict（必须三选一，AP-10 修法）: ADVANCE_MECHANISM / CONDITIONAL_ADVANCE_MECHANISM / HOLD
   - **强制 _MECHANISM 后缀**：表明本 milestone gate 是机制层判定（self_rubric + 子报告聚合），不等同于"用户实玩验证质量"
   - **禁止**：自宣 `QUALITY_PROVEN` / `READY_FOR_RELEASE` 等含"用户实玩验证"语义。这类只能由用户实玩 / playtest_pending → done 转换触发
2. 如 HOLD：列阻塞项 + 修复 ETA + 复审日期
3. 如 ADVANCE_MECHANISM：是否更新 PROJECT.md stage（**只提建议，不擅自改 PROJECT.md**），且必须提醒"下一阶段开始前所有进行中的 vertical slice story 须经 playtest_pending → done"

## 决策原则
- 任意一方 GATE_FAILED → HOLD（不允许覆盖）
- qa-lead PASS + reviewer PASS + 无 backlog 阻塞 → ADVANCE_MECHANISM
- 部分 PASS + N/A → CONDITIONAL_ADVANCE_MECHANISM（允许带条件推进，必须列条件）

## 交付协议
（同 qa-lead）

## 不允许
- 不读 qa-lead / reviewer 子报告就拍板
- 修改 PROJECT.md（main agent 在用户确认后做）
- 跳过 backlog due 检查
"""


def write_prompt(name: str, content: str, project: str, label: str) -> Path:
    """落盘 spawn-prompt 并自动追加 combo-B 产出契约注入段"""
    # combo-B M3: 自动 inject 产出契约引用
    agent_dir = WORKSPACE / ".codebuddy" / "agents" / name
    schema_path = agent_dir / "output-schema.yaml"
    if schema_path.exists():
        content += f"""

## 你的产出契约与自检（combo-B 强制）
1. read_file `.codebuddy/agents/{name}/output-schema.yaml` — 你的产出字段定义 + self_rubric 自检清单
2. read_file `.codebuddy/agents/{name}/AGENT.md` § 自检步骤 + § 产出契约 — 你的交付前强制步骤
3. 交付前必须跑 self_rubric 逐条自查，全过后在 send_message 中标注 `self_rubric: N/N PASS`
4. 如工作中发现新经验 → 追加到 `.codebuddy/agents/{name}/playbook.md` 待消化素材区
"""
    TEMP_DIR.mkdir(parents=True, exist_ok=True)
    ts = _now()
    p = TEMP_DIR / f"milestone-review-{name}-{project}-{label}-{ts}.md"
    p.write_text(content, encoding="utf-8")
    return p


def write_driver_report(project: str, from_stage: str, to_stage: str,
                        gate_data: dict, sprints: list[dict], retros: list[dict],
                        backlog: dict, trend: dict, project_md: dict) -> Path:
    """生成 driver 报告（草稿），等三方 spawn 后填充结论"""
    report_dir = WORKSPACE / "projects" / project / "reports"
    report_dir.mkdir(parents=True, exist_ok=True)
    out_path = report_dir / f"milestone-{from_stage}-to-{to_stage}-driver-{_today()}.md"

    lines = [
        f"# Milestone Review (Driver) · {from_stage} → {to_stage}",
        "",
        f"> **草稿** · 由 milestone-review/run.py 生成 · {_today()}",
        f"> 待 3 方 agent (qa-lead / reviewer / producer) spawn 后填充最终结论",
        "",
        "## 项目元数据",
        f"- project: {project}",
        f"- 当前 stage: {project_md.get('stage')}",
        f"- engine: {project_md.get('engine')}",
        f"- phase: {project_md.get('phase')}",
        "",
        "## qa-gate 自动评估",
        f"- Verdict: **{gate_data.get('verdict', 'N/A')}**",
        f"- fail: {gate_data.get('fail_count', '?')}",
        f"- N/A: {gate_data.get('na_count', '?')}",
        "",
        "## 准入条件 checklist（必须三方核验）",
    ]

    gate_def = STAGE_GATES.get((from_stage, to_stage), {})
    for c in gate_def.get("checklist", []):
        lines.append(f"- [ ] {c}")
    lines.append("")

    lines.append("## 最近 sprint smoke")
    if not sprints:
        lines.append("- (无 sprint smoke 报告，建议按 sprint-N-smoke.md 命名补)")
    else:
        for s in sprints:
            lines.append(f"- {s['file']} · verdict: {s['verdict']}")
    lines.append("")

    lines.append("## 待办 retro action items")
    if not retros:
        lines.append("- 无 open action item")
    else:
        for r in retros[:20]:
            lines.append(f"- [{r['retro']}] {r['item']}")
        if len(retros) > 20:
            lines.append(f"- ... (省略 {len(retros) - 20} 条，详见各 retro 文件)")
    lines.append("")

    lines.append("## Backlog 阻塞项（due ≤ 当前 milestone 但未 done）")
    if not backlog.get("blockers"):
        lines.append("- 无")
    else:
        for b in backlog["blockers"]:
            lines.append(f"- {b}")
    lines.append("")

    lines.append("## 历史 milestone 趋势")
    if trend.get("available"):
        for h in trend["history"]:
            lines.append(f"- {h['file']}: {h['verdict']}")
    else:
        lines.append(f"- {trend.get('reason', '不可用')}")
    lines.append("")

    lines.extend([
        "---",
        "",
        "## 三方 spawn 结论汇总（待填）",
        "",
        "### qa-lead 子报告",
        "[待 spawn 后链接到 qa-lead 子报告]",
        "",
        "### reviewer 子报告",
        "[待 spawn 后链接]",
        "",
        "### producer 综合 verdict",
        "[待 producer agent 拍板]",
        "",
        "## Final verdict",
        "[ADVANCE / HOLD / CONDITIONAL_ADVANCE — 待 producer 给出]",
    ])

    out_path.write_text("\n".join(lines), encoding="utf-8")
    return out_path


# ---------------------------------------------------------------------------
# 主流程
# ---------------------------------------------------------------------------

def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(prog="milestone-review run.py")
    parser.add_argument("--project", required=True)
    parser.add_argument("--from", dest="from_stage", required=True,
                        help="当前 stage（pre-production / production / polish）")
    parser.add_argument("--to", dest="to_stage", required=True,
                        help="目标 stage")
    parser.add_argument("--milestone", default=None,
                        help="标识符（用于报告文件名 / qa-gate 调用），如 M6")
    parser.add_argument("--qa-scope", default=None,
                        help="覆盖默认 qa-gate scope（默认从 STAGE_GATES 取）")
    parser.add_argument("--current-milestone", default="M9",
                        help="用于 backlog due 比较（默认 M9 表示不限）")
    parser.add_argument("--dry-run", action="store_true")
    args = parser.parse_args(argv)

    project_dir = _project_dir(args.project)
    if not project_dir.exists():
        print(f"[error] 项目不存在: {project_dir}", file=sys.stderr)
        return 2

    print(f"[milestone-review] {args.project} · {args.from_stage} → {args.to_stage}", file=sys.stderr)

    # 1. 项目元数据
    project_md = parse_project_md(project_dir)
    if not project_md["exists"]:
        print(f"[warn] PROJECT.md 缺失：{project_dir}/PROJECT.md", file=sys.stderr)

    # 2. stage gate 定义
    gate_def = STAGE_GATES.get((args.from_stage, args.to_stage))
    if gate_def is None:
        print(f"[warn] 未定义的 stage 转换：{args.from_stage} → {args.to_stage}（按 milestone 默认走）", file=sys.stderr)
        gate_def = {"required_qa_scope": "milestone", "required_artifacts": [], "checklist": []}
    qa_scope = args.qa_scope or gate_def["required_qa_scope"]
    milestone_label = args.milestone or f"{args.from_stage}-to-{args.to_stage}"

    # 3. 调 qa-gate
    print(f"[milestone-review] 调用 qa-gate (scope={qa_scope})...", file=sys.stderr)
    gate_data = call_qa_gate(args.project, qa_scope, milestone_label)
    if "error" in gate_data:
        print(f"[warn] qa-gate 调用失败：{gate_data['error']}", file=sys.stderr)
        gate_data = {"verdict": "N/A", "fail_count": "?", "na_count": "?", "items": []}

    # 4. 聚合
    sprints = collect_sprint_reports(project_dir, limit=3)
    retros = collect_retro_action_items(project_dir)
    backlog = check_backlog_due(project_dir, args.current_milestone)
    trend = trend_analysis(project_dir)

    # 5. driver 报告
    driver_path = write_driver_report(args.project, args.from_stage, args.to_stage,
                                      gate_data, sprints, retros, backlog, trend, project_md)
    print(f"[ok] driver 报告草稿: {driver_path.relative_to(WORKSPACE)}")

    if args.dry_run:
        print("[dry-run] 跳过 spawn-prompt 生成")
        return 0

    # 6. 找 qa-gate 留下的 metrics 文件（作为 qa-lead inject）
    metrics_glob = sorted(TEMP_DIR.glob(f"qa-gate-metrics-{args.project}-{milestone_label}-*.json"), reverse=True)
    qa_metrics_rel = (str(metrics_glob[0].relative_to(WORKSPACE)).replace("\\", "/")
                      if metrics_glob else "(qa-gate metrics 未生成)")

    # 7. 生成三方 prompt
    sprint_summary = "\n".join([f"- {s['file']} · {s['verdict']}" for s in sprints]) or "- (无)"
    checklist_str = "\n".join([f"- [ ] {c}" for c in gate_def["checklist"]]) or "- (本 stage 转换无显式 checklist)"
    code_files_hint = (
        "  (main agent 在 spawn 时根据 git log 列出涉及代码文件)\n"
        f"  起步建议: read_file projects/{args.project}/game/scripts/*.gd 关键变更"
    )
    trend_summary = ", ".join([f"{h['file']}={h['verdict']}" for h in trend.get("history", [])]) or "无历史"

    common_vars = dict(
        project=args.project,
        from_stage=args.from_stage,
        to_stage=args.to_stage,
        date=_today(),
        qa_gate_verdict=gate_data.get("verdict", "N/A"),
        qa_gate_fail=gate_data.get("fail_count", "?"),
        qa_gate_na=gate_data.get("na_count", "?"),
        qa_gate_metrics_rel=qa_metrics_rel,
    )

    p_qa = write_prompt("qa-lead", PROMPT_QA_LEAD.format(
        sprint_count=len(sprints),
        sprint_summary=sprint_summary,
        checklist=checklist_str,
        **common_vars,
    ), args.project, milestone_label)

    p_rev = write_prompt("reviewer", PROMPT_REVIEWER.format(
        code_files_hint=code_files_hint,
        trend_summary=trend_summary,
        **common_vars,
    ), args.project, milestone_label)

    p_prod = write_prompt("producer", PROMPT_PRODUCER.format(
        backlog_blockers_count=backlog.get("count", 0),
        trend_summary=trend_summary,
        **common_vars,
    ), args.project, milestone_label)

    print()
    print("=" * 60)
    print(f"三方 spawn-prompt 已落盘到 {TEMP_DIR.relative_to(WORKSPACE)}/")
    print(f"  1. qa-lead    → {p_qa.name}")
    print(f"  2. reviewer   → {p_rev.name}")
    print(f"  3. producer   → {p_prod.name}（必须等 1+2 落盘后再 spawn）")
    print()
    print("Main agent 推荐 spawn 顺序（使用 team 模式）：")
    print("  Step A · 用 team 模式 spawn qa-lead + reviewer（name='qa-lead' / name='reviewer'）")
    print("           两者异步并行，互不可见对方 verdict（隔离保证独立性）")
    print("  Step B · 等 qa-lead + reviewer 通过 send_message 交付子报告")
    print("  Step C · spawn producer（name='producer'），注入两份子报告做最终拍板")
    print("  注意：不要用 batch task（无 name），那是串行等待模式。team 才能真正异步。")
    print()
    print(f"Driver 报告占位：{driver_path.relative_to(WORKSPACE)}")
    print("  3 方完成后 main agent 把子报告链接 + final verdict 填进 driver 报告即可")
    print("=" * 60)

    return 0


if __name__ == "__main__":
    sys.exit(main())
