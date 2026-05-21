"""渐进披露 lint：分级提醒，不硬上限。

设计原则（2026-05-20，用户决策）：
- 不设硬上限，避免反向激励 agent 凑数到上限
- 分 4 段：安全 / 提醒 / 打回自审 / 用户审批
- 文件头部 `<!-- OVER_LIMIT_REASON: ... -->` 可让 agent 自审通过 Y-Z 区
- 超 Z 强制用户 ack（在 commit msg 加 [layer-override] tag）

退出码：
- 0：全过 / 仅提醒
- 1：≥1 文件在打回自审区且无 OVER_LIMIT_REASON
- 2：≥1 文件在用户审批区且 commit msg 无 [layer-override]

Usage:
  python check_progressive_disclosure.py                    # 扫全部，输出报告
  python check_progressive_disclosure.py --strict           # 提醒区也算 fail
  python check_progressive_disclosure.py --commit-msg X.txt # commit hook 模式（Z 区检查 [layer-override]）
"""
from __future__ import annotations
import argparse
import sys
from dataclasses import dataclass
from pathlib import Path
from typing import Iterable

if sys.platform == "win32":
    try:
        sys.stdout.reconfigure(encoding="utf-8")  # type: ignore[attr-defined]
        sys.stderr.reconfigure(encoding="utf-8")  # type: ignore[attr-defined]
    except Exception:
        pass

WORKSPACE = Path(__file__).resolve().parents[2]


@dataclass(frozen=True)
class LayerSpec:
    """每类文件的分级阈值"""
    name: str
    safe: int     # ≤ safe → 安全
    notice: int   # ≤ notice → 提醒（write log）
    review: int   # ≤ review → 打回自审（必须 OVER_LIMIT_REASON）
    # > review → 用户审批


# 阈值约定（2026-05-20 v1.0）
SPECS: dict[str, LayerSpec] = {
    "rule_core":   LayerSpec("rule CORE (RULE.mdc)",   safe=30,  notice=50,  review=80),
    "skill_core":  LayerSpec("skill CORE (SKILL.md)",  safe=30,  notice=50,  review=80),
    "agent_core":  LayerSpec("agent CORE (AGENT.md)",  safe=40,  notice=60,  review=100),
    "manual":      LayerSpec("MANUAL/PLAYBOOK/HANDBOOK", safe=150, notice=250, review=400),
    # archive 不参与 lint，只做体积统计
}


@dataclass
class Finding:
    path: Path
    spec: LayerSpec
    lines: int
    has_override_reason: bool

    @property
    def zone(self) -> str:
        if self.lines <= self.spec.safe:
            return "safe"
        if self.lines <= self.spec.notice:
            return "notice"
        if self.lines <= self.spec.review:
            return "review"
        return "approval"

    @property
    def severity(self) -> int:
        """0 safe, 1 notice, 2 review-without-reason, 3 approval-without-reason"""
        z = self.zone
        if z == "safe":
            return 0
        if z == "notice":
            return 1
        if z == "review":
            return 1 if self.has_override_reason else 2
        # approval 区：有 reason → 自审通过（与 review 等同）；无 reason → 必须用户 ack
        return 1 if self.has_override_reason else 3


def _read_lines(p: Path) -> int:
    try:
        return len(p.read_text(encoding="utf-8").splitlines())
    except Exception:
        return -1


def _has_override(p: Path) -> bool:
    """检查文件头部 100 字符内是否含 OVER_LIMIT_REASON 注释"""
    try:
        head = p.read_text(encoding="utf-8")[:500]
        return "OVER_LIMIT_REASON" in head
    except Exception:
        return False


def collect_targets() -> Iterable[tuple[Path, str]]:
    """枚举所有要 lint 的文件 + 它们对应的 spec key"""
    cb = WORKSPACE / ".codebuddy"

    # rules CORE
    for p in (cb / "rules").glob("*/RULE.mdc"):
        yield p, "rule_core"

    # skills CORE
    for p in (cb / "skills").glob("*/SKILL.md"):
        yield p, "skill_core"

    # agents CORE
    for p in (cb / "agents").glob("*/AGENT.md"):
        yield p, "agent_core"

    # MANUAL / PLAYBOOK / HANDBOOK 任意层级
    for name in ("MANUAL.md", "PLAYBOOK.md", "HANDBOOK.md"):
        for base in [cb / "rules", cb / "skills", cb / "agents"]:
            for p in base.glob(f"*/{name}"):
                yield p, "manual"


def lint(strict: bool = False, commit_msg: str | None = None) -> tuple[int, list[Finding]]:
    findings: list[Finding] = []
    for path, spec_key in collect_targets():
        n = _read_lines(path)
        if n < 0:
            continue
        spec = SPECS[spec_key]
        f = Finding(path=path, spec=spec, lines=n, has_override_reason=_has_override(path))
        findings.append(f)

    # 是否有 commit msg 的 [layer-override] 放行
    has_user_ack = False
    if commit_msg:
        try:
            msg = Path(commit_msg).read_text(encoding="utf-8", errors="replace").lstrip("\ufeff")
            has_user_ack = "[layer-override]" in msg
        except Exception:
            pass

    # 决定 exit code
    exit_code = 0
    for f in findings:
        sev = f.severity
        if sev == 3 and not has_user_ack:
            exit_code = 2
        elif sev == 2 and exit_code < 1:
            exit_code = 1
        elif strict and sev >= 1 and exit_code == 0:
            exit_code = 1

    return exit_code, findings


def render_report(findings: list[Finding]) -> str:
    by_zone: dict[str, list[Finding]] = {"safe": [], "notice": [], "review": [], "approval": []}
    for f in findings:
        by_zone[f.zone].append(f)

    lines = [
        "渐进披露 lint 报告",
        "=" * 70,
        f"总文件数: {len(findings)}",
        f"  🟢 safe:     {len(by_zone['safe'])}",
        f"  🟡 notice:   {len(by_zone['notice'])}  (写多了一点，不阻塞)",
        f"  🟠 review:   {len(by_zone['review'])}  (需 OVER_LIMIT_REASON 自审)",
        f"  🔴 approval: {len(by_zone['approval'])} (需用户 [layer-override] commit tag)",
        "",
    ]

    for zone, emoji, label in [
        ("approval", "🔴", "用户审批区（必须 [layer-override] commit tag）"),
        ("review", "🟠", "打回自审区（必须 OVER_LIMIT_REASON 注释）"),
        ("notice", "🟡", "提醒区（建议精简但不阻塞）"),
    ]:
        if not by_zone[zone]:
            continue
        lines.append(f"{emoji} {label}:")
        for f in sorted(by_zone[zone], key=lambda x: -x.lines):
            rel = f.path.relative_to(WORKSPACE)
            ack = "✓ has OVER_LIMIT_REASON" if f.has_override_reason else "✗ no reason"
            lines.append(
                f"  {f.lines:5d} lines  [{f.spec.name}]  {rel}"
                + (f"  ({ack})" if zone in ("review", "approval") else "")
            )
        lines.append("")

    return "\n".join(lines)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--strict", action="store_true", help="提醒区也算 fail")
    parser.add_argument("--commit-msg", default=None, help="commit msg 文件路径（hook 模式）")
    parser.add_argument("--quiet", action="store_true", help="仅在有问题时输出")
    args = parser.parse_args()

    exit_code, findings = lint(strict=args.strict, commit_msg=args.commit_msg)

    if not args.quiet or exit_code != 0:
        print(render_report(findings))

    if exit_code == 2:
        print("[FAIL] 有文件超 review 阈值进入用户审批区，commit msg 需含 [layer-override] tag", file=sys.stderr)
    elif exit_code == 1:
        print("[FAIL] 有文件在打回自审区但缺 OVER_LIMIT_REASON 注释，请精简或加注释说明理由", file=sys.stderr)

    return exit_code


if __name__ == "__main__":
    sys.exit(main())
