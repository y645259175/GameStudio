#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
qa-gate · run.py · 命令行可执行版

把 qa-gate skill 从"流程文档"升级为"可执行 pipeline"。

行为：
1. 收集 7 项 quality 指标（来自 SKILL.md 阈值表）
2. 按 scope (sprint / milestone / release) 查阈值
3. 给出 verdict (GATE_PASSED / CONDITIONAL_PASS / GATE_FAILED)
4. 生成符合 agent-spawn-contract 4 契约的 qa-lead spawn-prompt
5. 写 metrics.json + spawn-prompt.md 到 .codebuddy/temp/
6. 输出"请用 task 工具 spawn qa-lead，prompt 见 ↑"

设计决策（详见 plan）：
- run.py 不直接调 LLM，只生成结构化 prompt 让 main agent 拾取
- stdlib only，无外部依赖
- I/O 失败优雅降级（指标标 N/A，不让脚本崩）

用法：
    python .codebuddy/skills/qa-gate/run.py \
        --project bolt-1-1 \
        --scope milestone \
        --milestone M6
"""

from __future__ import annotations

import argparse
import datetime
import io
import json
import os
import re
import subprocess
import sys
from pathlib import Path

# 强制 stdout/stderr 用 UTF-8（Windows 默认 GBK 会炸 emoji / 中文）
if sys.platform == "win32":
    try:
        sys.stdout.reconfigure(encoding="utf-8", errors="replace")  # type: ignore[attr-defined]
        sys.stderr.reconfigure(encoding="utf-8", errors="replace")  # type: ignore[attr-defined]
    except Exception:  # noqa: BLE001
        # 老 Python 没 reconfigure，回退到 wrap
        sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8", errors="replace")
        sys.stderr = io.TextIOWrapper(sys.stderr.buffer, encoding="utf-8", errors="replace")

# ---------------------------------------------------------------------------
# 常量 · 阈值表（与 SKILL.md 的"阈值按场景分级"表保持同步）
# ---------------------------------------------------------------------------

THRESHOLDS = {
    "sprint": {
        "test_pass_rate": 0.80,
        "engine_check": "EXIT_0",
        "consistency": ["CLEAN", "MINOR"],
        "p0_bug_max": 1,
        "gdd_p0_coverage": 0.80,
        "visual_debt_max": 5,
        "real_playtest_required": False,
    },
    "milestone": {
        "test_pass_rate": 0.90,
        "engine_check": "EXIT_0",
        "consistency": ["CLEAN"],
        "p0_bug_max": 0,
        "gdd_p0_coverage": 1.00,
        "visual_debt_max": 2,
        "real_playtest_required": True,
    },
    "release": {
        "test_pass_rate": 0.95,
        "engine_check": "EXIT_0",
        "consistency": ["CLEAN"],
        "p0_bug_max": 0,
        "gdd_p0_coverage": 1.00,
        "visual_debt_max": 0,
        "real_playtest_required": True,
    },
}

# 工作区根（脚本位于 .codebuddy/skills/qa-gate/run.py）
WORKSPACE = Path(__file__).resolve().parents[3]
TEMP_DIR = WORKSPACE / ".codebuddy" / "temp"


# ---------------------------------------------------------------------------
# 工具函数
# ---------------------------------------------------------------------------

def _now() -> str:
    return datetime.datetime.now().strftime("%Y-%m-%d_%H%M%S")


def _today() -> str:
    return datetime.datetime.now().strftime("%Y-%m-%d")


def _project_dir(project: str) -> Path:
    return WORKSPACE / "projects" / project


def _safe_run(cmd: list[str], cwd: Path | None = None, timeout: int = 60) -> tuple[int, str, str]:
    """运行命令，永不抛异常（异常时返回 exitcode=-1 + stderr）"""
    try:
        result = subprocess.run(
            cmd,
            cwd=cwd,
            capture_output=True,
            text=True,
            timeout=timeout,
            encoding="utf-8",
            errors="replace",
        )
        return result.returncode, result.stdout, result.stderr
    except FileNotFoundError as e:
        return -1, "", f"FileNotFoundError: {e}"
    except subprocess.TimeoutExpired:
        return -1, "", f"Timeout after {timeout}s"
    except Exception as e:  # noqa: BLE001
        return -1, "", f"Unexpected: {e}"


# ---------------------------------------------------------------------------
# 7 项指标采集
# ---------------------------------------------------------------------------

def metric_test_pass_rate(project_dir: Path) -> dict:
    """指标 1 · 测试通过率"""
    test_runner = project_dir / "qa" / "run-tests.ps1"
    if not test_runner.exists():
        return {"value": None, "status": "N/A", "reason": "qa/run-tests.ps1 缺失"}

    code, stdout, stderr = _safe_run(
        ["pwsh", "-NoProfile", "-File", str(test_runner)],
        cwd=project_dir,
        timeout=300,
    )
    # 简单启发式：从输出中找 "PASS"/"FAIL" 计数
    pass_count = len(re.findall(r"\bPASS\b", stdout, re.I))
    fail_count = len(re.findall(r"\bFAIL\b", stdout, re.I))
    total = pass_count + fail_count

    if total == 0:
        return {
            "value": None,
            "status": "N/A",
            "reason": f"无法从输出解析测试结果 (exitcode={code})",
            "raw_excerpt": stdout[-500:] if stdout else stderr[-500:],
        }
    rate = pass_count / total
    return {
        "value": rate,
        "raw": f"{pass_count}/{total} PASS",
        "exitcode": code,
    }


def metric_engine_check(project_dir: Path) -> dict:
    """指标 2 · godot --headless --check-only EXIT 状态"""
    godot = WORKSPACE / "engine" / "Godot" / "Godot_v4.6.2-stable_win64.exe"
    game_dir = project_dir / "game"
    if not godot.exists():
        return {"value": None, "status": "N/A", "reason": f"Godot 不存在: {godot}"}
    if not game_dir.exists():
        return {"value": None, "status": "N/A", "reason": f"game 目录不存在: {game_dir}"}

    code, _, stderr = _safe_run(
        [str(godot), "--headless", "--check-only", "--path", str(game_dir), "--quit"],
        timeout=60,
    )
    return {
        "value": "EXIT_0" if code == 0 else f"EXIT_{code}",
        "exitcode": code,
        "stderr_excerpt": stderr[-400:] if stderr else "",
    }


def metric_consistency(project_dir: Path) -> dict:
    """指标 3 · 最近 consistency-check verdict"""
    reports_dir = project_dir / "reports"
    if not reports_dir.exists():
        return {"value": None, "status": "N/A", "reason": "reports/ 不存在"}

    candidates = sorted(reports_dir.glob("consistency-*.md"), reverse=True)
    if not candidates:
        return {"value": None, "status": "N/A", "reason": "未找到 consistency-*.md 报告"}

    latest = candidates[0]
    content = latest.read_text(encoding="utf-8", errors="replace")
    # 寻找 verdict：CLEAN / MINOR / MAJOR
    m = re.search(r"\bverdict\b[^\n]*?\b(CLEAN|MINOR|MAJOR)\b", content, re.I)
    if not m:
        return {"value": None, "status": "N/A", "reason": f"{latest.name} 中未找到 verdict 字段"}
    return {"value": m.group(1).upper(), "report": str(latest.relative_to(WORKSPACE))}


def metric_p0_bugs(project_dir: Path) -> dict:
    """指标 4 · 已知 P0 bug 数（来自 backlog）"""
    backlog = project_dir / "stories" / "backlog.md"
    if not backlog.exists():
        return {"value": 0, "raw": "backlog.md 缺失，按 0 计（warning）"}

    content = backlog.read_text(encoding="utf-8", errors="replace")
    # 简单匹配："P0 ... open" 行
    p0_open = 0
    for line in content.splitlines():
        if "|" not in line:
            continue
        if "P0" in line and re.search(r"\bopen\b|\bin-progress\b", line, re.I):
            # 排除标题 / 分隔行
            if re.match(r"\s*\|\s*-+", line):
                continue
            p0_open += 1
    return {"value": p0_open, "raw": f"backlog 中 P0 open/in-progress 行数 = {p0_open}"}


def metric_gdd_p0_coverage(project_dir: Path) -> dict:
    """指标 5 · GDD §8 P0 验收覆盖率（启发式）"""
    gdd_dir = project_dir / "gdd"
    if not gdd_dir.exists():
        return {"value": None, "status": "N/A", "reason": "gdd/ 不存在"}

    p0_total = 0
    p0_done = 0
    for md in gdd_dir.glob("*.md"):
        text = md.read_text(encoding="utf-8", errors="replace")
        # 简单启发式：找形如 "DoD-NN" 或 "[ ] / [x] P0" 的行
        for line in text.splitlines():
            if re.search(r"\bP0\b", line) and re.search(r"\[[ x]\]", line):
                p0_total += 1
                if re.search(r"\[x\]", line):
                    p0_done += 1
    if p0_total == 0:
        return {"value": None, "status": "N/A", "reason": "GDD 中未找到 P0 复选框（启发式）"}
    return {"value": p0_done / p0_total, "raw": f"{p0_done}/{p0_total}"}


def metric_visual_debt(project_dir: Path) -> dict:
    """指标 6 · VISUAL_DEBT 计数（来自 backlog）"""
    backlog = project_dir / "stories" / "backlog.md"
    if not backlog.exists():
        return {"value": 0, "raw": "backlog.md 缺失，按 0 计"}
    content = backlog.read_text(encoding="utf-8", errors="replace")
    count = 0
    for line in content.splitlines():
        if "VISUAL_DEBT" in line and re.search(r"\bopen\b", line, re.I):
            if re.match(r"\s*\|\s*-+", line):
                continue
            count += 1
    return {"value": count, "raw": f"backlog 中 VISUAL_DEBT open 行数 = {count}"}


def metric_real_playtest(project_dir: Path) -> dict:
    """指标 7 · 真实玩家路径测试（非 cheat-only）"""
    tests_dirs = [project_dir / "qa" / "tests", project_dir / "game" / "tests"]
    found_files: list[Path] = []
    for d in tests_dirs:
        if d.exists():
            found_files.extend(d.rglob("*.gd"))

    if not found_files:
        return {"value": False, "raw": "未找到任何 .gd 测试文件"}

    has_real_input = False
    matched_file = None
    for f in found_files:
        try:
            text = f.read_text(encoding="utf-8", errors="replace")
        except Exception:  # noqa: BLE001
            continue
        # 必须含 InputMap.action_press 或 Input.action_press
        if re.search(r"\b(Input|InputMap)\.action_press\b", text):
            has_real_input = True
            matched_file = f.relative_to(WORKSPACE)
            break

    return {
        "value": has_real_input,
        "raw": f"含 action_press 的测试: {matched_file}" if has_real_input else "无真实输入测试",
    }


# ---------------------------------------------------------------------------
# 评估 & 聚合
# ---------------------------------------------------------------------------

def collect_metrics(project_dir: Path) -> dict:
    return {
        "test_pass_rate": metric_test_pass_rate(project_dir),
        "engine_check": metric_engine_check(project_dir),
        "consistency": metric_consistency(project_dir),
        "p0_bugs": metric_p0_bugs(project_dir),
        "gdd_p0_coverage": metric_gdd_p0_coverage(project_dir),
        "visual_debt": metric_visual_debt(project_dir),
        "real_playtest": metric_real_playtest(project_dir),
    }


def evaluate(metrics: dict, scope: str) -> dict:
    """对照阈值表给出 verdict + 未达项清单"""
    thr = THRESHOLDS[scope]
    items = []
    fail_count = 0
    na_count = 0

    # 1. 测试通过率
    m = metrics["test_pass_rate"]
    if m.get("value") is None:
        items.append({"name": "测试通过率", "actual": "N/A", "threshold": f"≥{thr['test_pass_rate']:.0%}", "status": "N/A", "reason": m.get("reason", "")})
        na_count += 1
    elif m["value"] >= thr["test_pass_rate"]:
        items.append({"name": "测试通过率", "actual": f"{m['value']:.0%} ({m.get('raw','')})", "threshold": f"≥{thr['test_pass_rate']:.0%}", "status": "PASS"})
    else:
        items.append({"name": "测试通过率", "actual": f"{m['value']:.0%} ({m.get('raw','')})", "threshold": f"≥{thr['test_pass_rate']:.0%}", "status": "FAIL"})
        fail_count += 1

    # 2. 引擎校验
    m = metrics["engine_check"]
    if m.get("value") is None:
        items.append({"name": "引擎校验", "actual": "N/A", "threshold": "EXIT 0", "status": "N/A", "reason": m.get("reason", "")})
        na_count += 1
    elif m["value"] == "EXIT_0":
        items.append({"name": "引擎校验", "actual": "EXIT 0", "threshold": "EXIT 0", "status": "PASS"})
    else:
        items.append({"name": "引擎校验", "actual": m["value"], "threshold": "EXIT 0", "status": "FAIL", "stderr": m.get("stderr_excerpt", "")})
        fail_count += 1

    # 3. consistency
    m = metrics["consistency"]
    if m.get("value") is None:
        items.append({"name": "consistency-check", "actual": "N/A", "threshold": " or ".join(thr["consistency"]), "status": "N/A", "reason": m.get("reason", "")})
        na_count += 1
    elif m["value"] in thr["consistency"]:
        items.append({"name": "consistency-check", "actual": m["value"], "threshold": " or ".join(thr["consistency"]), "status": "PASS", "report": m.get("report", "")})
    else:
        items.append({"name": "consistency-check", "actual": m["value"], "threshold": " or ".join(thr["consistency"]), "status": "FAIL"})
        fail_count += 1

    # 4. P0 bug
    m = metrics["p0_bugs"]
    if m["value"] <= thr["p0_bug_max"]:
        items.append({"name": "P0 bug 数", "actual": m["value"], "threshold": f"≤{thr['p0_bug_max']}", "status": "PASS"})
    else:
        items.append({"name": "P0 bug 数", "actual": m["value"], "threshold": f"≤{thr['p0_bug_max']}", "status": "FAIL"})
        fail_count += 1

    # 5. GDD P0
    m = metrics["gdd_p0_coverage"]
    if m.get("value") is None:
        items.append({"name": "GDD P0 验收覆盖", "actual": "N/A", "threshold": f"≥{thr['gdd_p0_coverage']:.0%}", "status": "N/A", "reason": m.get("reason", "")})
        na_count += 1
    elif m["value"] >= thr["gdd_p0_coverage"]:
        items.append({"name": "GDD P0 验收覆盖", "actual": f"{m['value']:.0%} ({m.get('raw','')})", "threshold": f"≥{thr['gdd_p0_coverage']:.0%}", "status": "PASS"})
    else:
        items.append({"name": "GDD P0 验收覆盖", "actual": f"{m['value']:.0%} ({m.get('raw','')})", "threshold": f"≥{thr['gdd_p0_coverage']:.0%}", "status": "FAIL"})
        fail_count += 1

    # 6. visual debt
    m = metrics["visual_debt"]
    if m["value"] <= thr["visual_debt_max"]:
        items.append({"name": "视觉债（VISUAL_DEBT）", "actual": m["value"], "threshold": f"≤{thr['visual_debt_max']}", "status": "PASS"})
    else:
        items.append({"name": "视觉债（VISUAL_DEBT）", "actual": m["value"], "threshold": f"≤{thr['visual_debt_max']}", "status": "FAIL"})
        fail_count += 1

    # 7. real playtest
    m = metrics["real_playtest"]
    required = thr["real_playtest_required"]
    if not required:
        items.append({"name": "真实玩家路径测试", "actual": "PASS" if m["value"] else "MISSING", "threshold": "推荐", "status": "PASS" if m["value"] else "WARNING"})
    else:
        if m["value"]:
            items.append({"name": "真实玩家路径测试", "actual": m.get("raw", "PASS"), "threshold": "必须 ≥ 1", "status": "PASS"})
        else:
            items.append({"name": "真实玩家路径测试", "actual": "MISSING", "threshold": "必须 ≥ 1", "status": "FAIL"})
            fail_count += 1

    # 综合 verdict
    # AP-10 修法：所有 AI 自动 verdict 后缀强制 _MECHANISM
    # 表明只是"机制层"判定，不等同于"质量经用户实玩验证"
    if fail_count == 0 and na_count == 0:
        verdict = "GATE_PASSED_MECHANISM"
    elif fail_count == 0 and na_count > 0:
        verdict = "CONDITIONAL_PASS_MECHANISM"
    elif fail_count == 1 and scope == "sprint":
        verdict = "CONDITIONAL_PASS_MECHANISM"
    else:
        verdict = "GATE_FAILED"

    return {
        "verdict": verdict,
        "items": items,
        "fail_count": fail_count,
        "na_count": na_count,
        "scope": scope,
    }


# ---------------------------------------------------------------------------
# Spawn-prompt 生成（agent-spawn-contract 4 契约）
# ---------------------------------------------------------------------------

SPAWN_PROMPT_TEMPLATE = """你是 qa-lead agent。本次任务：基于 qa-gate run.py 自动采集的指标数据，给出 {scope} gate 的最终质量裁决。

## 任务模式（agent-spawn-contract）
- Mode: REVIEW（只读评审 + 写最终报告）
- Output path: {report_path}
- Output mode: new_file

## 现状注入（数据已自动采集）

run.py 采集到的 metrics（也已保存到 {metrics_json_rel}）：

```json
{metrics_json_inline}
```

run.py 的初步评估：

- **Verdict 建议**: {verdict_hint}
- **fail count**: {fail_count} · **N/A count**: {na_count}
- **scope**: {scope}

各项明细：

{items_table}

## 你要做什么

1. **read_file** {metrics_json_rel} 获取完整原始数据（含 stderr / 报告路径等细节）
2. **read_file** 项目 PROJECT.md 校验 milestone / stage 字段
3. **如有 N/A 项**：判断"无数据"是该项确实不需要还是项目缺该项设施。后者必须明确建议补齐
4. **如有 FAIL 项**：列必修清单 + 修复建议
5. **写最终报告** 到 {report_path}（参考 SKILL.md 中的报告模板）
6. **综合 verdict** 三选一（AP-10 修法：AI 给的 verdict 都带 _MECHANISM 后缀，表明只是机制层判定，不等同于用户实玩验证的质量）：
   - **GATE_PASSED_MECHANISM** — 全部 PASS，机制层通过，可进 playtest_pending 阶段（不允许直接进 done）
   - **CONDITIONAL_PASS_MECHANISM** — 有 1 项轻微未达 / N/A，带条件推进
   - **GATE_FAILED** — 必须修复后重审
   - **禁止**：自宣 `QUALITY_PROVEN` / `PRODUCTION_READY` 等含"用户实玩验证"语义的 verdict。这类 verdict 只能由用户实玩反馈触发，AI 无权宣布。
   - GATE_FAILED — 关键项未达，禁止推进

## 交付协议

1. 自己 write 落盘 {report_path}
2. read_file 验证存在 + 内容非空
3. send_message(type="message", content="qa-gate {scope} verdict: <YOUR_VERDICT>; report: {report_path}; <未达项数>; <核心建议 1 句>")
4. 等 main agent 确认
5. send_message(type="shutdown_response", approve=true, reason="qa-gate 评审完成")

## 不允许
- "看起来没问题"（必须给具体指标 + 数值 + 阈值对照）
- 跳过 N/A 项的根因分析
- 把报告内容塞到 shutdown reason 里
"""


def render_items_table(items: list[dict]) -> str:
    lines = ["| # | 指标 | 实际 | 阈值 | 状态 |", "|---|---|---|---|---|"]
    for i, it in enumerate(items, 1):
        status = it["status"]
        emoji = {"PASS": "✅", "FAIL": "❌", "N/A": "⚠️", "WARNING": "⚠️"}.get(status, status)
        lines.append(f"| {i} | {it['name']} | {it.get('actual','')} | {it.get('threshold','')} | {emoji} {status} |")
    return "\n".join(lines)


def generate_spawn_prompt(eval_result: dict, project: str, scope: str, milestone_label: str) -> tuple[str, Path, Path]:
    """返回 (prompt 文本, prompt 文件路径, metrics.json 路径)"""
    TEMP_DIR.mkdir(parents=True, exist_ok=True)
    ts = _now()

    metrics_json_path = TEMP_DIR / f"qa-gate-metrics-{project}-{milestone_label}-{ts}.json"
    metrics_json_path.write_text(
        json.dumps(eval_result, ensure_ascii=False, indent=2, default=str),
        encoding="utf-8",
    )

    report_path_rel = f"projects/{project}/reports/qa-gate-{milestone_label}-{_today()}.md"
    metrics_json_rel = str(metrics_json_path.relative_to(WORKSPACE)).replace("\\", "/")

    items_table = render_items_table(eval_result["items"])
    metrics_inline = json.dumps(eval_result, ensure_ascii=False, indent=2, default=str)
    if len(metrics_inline) > 4000:
        metrics_inline = metrics_inline[:3800] + "\n... (truncated, see " + metrics_json_rel + " for full data)\n"

    prompt = SPAWN_PROMPT_TEMPLATE.format(
        scope=scope,
        report_path=report_path_rel,
        metrics_json_rel=metrics_json_rel,
        metrics_json_inline=metrics_inline,
        verdict_hint=eval_result["verdict"],
        fail_count=eval_result["fail_count"],
        na_count=eval_result["na_count"],
        items_table=items_table,
    )

    prompt_path = TEMP_DIR / f"qa-gate-spawn-prompt-{project}-{milestone_label}-{ts}.md"
    prompt_path.write_text(prompt, encoding="utf-8")
    return prompt, prompt_path, metrics_json_path


# ---------------------------------------------------------------------------
# CLI
# ---------------------------------------------------------------------------

def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(
        prog="qa-gate run.py",
        description="qa-gate 可执行版：采集 7 项指标 + 生成 qa-lead spawn-prompt",
    )
    parser.add_argument("--project", required=True, help="项目名（projects/<name>/）")
    parser.add_argument("--scope", choices=["sprint", "milestone", "release"], required=True, help="门控严格等级")
    parser.add_argument("--milestone", default=None, help="里程碑标签，例如 M6（用于报告文件名）")
    parser.add_argument("--dry-run", action="store_true", help="只采集 + 评估 + 输出 verdict，不生成 spawn-prompt")
    parser.add_argument("--json", action="store_true", help="只输出 JSON 评估结果到 stdout")
    args = parser.parse_args(argv)

    project_dir = _project_dir(args.project)
    if not project_dir.exists():
        print(f"[error] 项目不存在: {project_dir}", file=sys.stderr)
        return 2

    print(f"[qa-gate] 采集指标 · project={args.project} · scope={args.scope}", file=sys.stderr)
    metrics = collect_metrics(project_dir)
    eval_result = evaluate(metrics, args.scope)
    eval_result["metrics_raw"] = metrics

    if args.json:
        print(json.dumps(eval_result, ensure_ascii=False, indent=2, default=str))
        return 0

    # 人类可读输出
    print()
    print(f"===== QA Gate · {args.project} · {args.scope} =====")
    print()
    print(render_items_table(eval_result["items"]))
    print()
    print(f"VERDICT (run.py 初判): {eval_result['verdict']}")
    print(f"  fail: {eval_result['fail_count']}  N/A: {eval_result['na_count']}")
    print()

    if args.dry_run:
        print("[dry-run] 跳过 spawn-prompt 生成")
        return 0

    milestone_label = args.milestone or args.scope
    prompt, prompt_path, metrics_path = generate_spawn_prompt(eval_result, args.project, args.scope, milestone_label)

    rel_prompt = prompt_path.relative_to(WORKSPACE)
    rel_metrics = metrics_path.relative_to(WORKSPACE)
    print(f"[ok] metrics 已写入: {rel_metrics}")
    print(f"[ok] spawn-prompt 已写入: {rel_prompt}")
    print()
    print("=" * 60)
    print("下一步（main agent 操作）：")
    print(f"  使用 task 工具 spawn `qa-lead` agent，prompt 见: {rel_prompt}")
    print("  契约要点：REVIEW mode / 落盘 report / 先 send_message 再 shutdown")
    print("=" * 60)

    return 0


if __name__ == "__main__":
    sys.exit(main())
