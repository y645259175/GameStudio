#!/usr/bin/env python3
"""pre-commit-discipline · 检查 commit message tag + 基础 lint

BL-S004 修法：commit message 必须带以下任一前缀 tag：
  [story] / [fix] / [chore] / [hotfix] / [VISUAL_DEBT] / [spawn:TPL-NN]
  / [feat] / [refactor] / [docs] / [test] / [perf]
  / [merge] / [revert]

退出码：
  0 = 通过
  1 = tag 缺失或不在白名单（阻塞 commit）
  2 = 其他错误

用法：
  git commit -m "[story] story-007: 实现双跳"   ✅
  git commit -m "update player.gd"             ❌ 阻塞
"""
from __future__ import annotations
import os
import re
import sys
import subprocess
from pathlib import Path

if sys.platform == "win32":
    try:
        sys.stdout.reconfigure(encoding="utf-8")  # type: ignore[attr-defined]
        sys.stderr.reconfigure(encoding="utf-8")  # type: ignore[attr-defined]
    except Exception:
        pass

ALLOWED_TAGS = [
    "story", "fix", "chore", "hotfix",
    "VISUAL_DEBT", "feat", "refactor",
    "docs", "test", "perf",
    "merge", "revert",
]
# 兼容 commit-discipline rule + 工作室约定
TAG_RE = re.compile(
    r"^\s*(?:\[(?:" + "|".join(ALLOWED_TAGS) +
    r")(?::[^\]]+)?\]\s*)+",
    re.IGNORECASE,
)


def get_commit_msg() -> str | None:
    """git 在 pre-commit 时把 message 放在 .git/COMMIT_EDITMSG"""
    # 优先 arg[1]（标准 commit-msg hook 入参）
    if len(sys.argv) >= 2:
        p = Path(sys.argv[1])
        if p.exists():
            txt = p.read_text(encoding="utf-8", errors="replace")
            # 去除 BOM（Windows PowerShell utf8 写入会加 BOM）
            return txt.lstrip("\ufeff")
    # 回退到 .git/COMMIT_EDITMSG
    git_dir = Path(".git")
    if not git_dir.exists():
        return None
    msg_file = git_dir / "COMMIT_EDITMSG"
    if msg_file.exists():
        return msg_file.read_text(encoding="utf-8", errors="replace").lstrip("\ufeff")
    return None


def main() -> int:
    msg = get_commit_msg()
    if msg is None:
        print("[pre-commit-discipline] 找不到 commit message（跳过检查）", file=sys.stderr)
        return 0

    # 跳过 git 自动生成的 message（merge / revert / fixup / squash）
    first_line = msg.strip().splitlines()[0] if msg.strip() else ""
    if not first_line:
        print("[pre-commit-discipline] 空 commit message（跳过）", file=sys.stderr)
        return 0

    if first_line.lower().startswith(("merge ", "revert ", "fixup!", "squash!")):
        return 0

    # 检查 tag
    has_valid_tag = bool(TAG_RE.match(first_line))

    if not has_valid_tag:
        # 阻塞
        print("=" * 60, file=sys.stderr)
        print("[pre-commit-discipline] ❌ COMMIT BLOCKED", file=sys.stderr)
        print("", file=sys.stderr)
        print(f"  Commit message 必须以 tag 开头，当前第一行:", file=sys.stderr)
        print(f"    {first_line}", file=sys.stderr)
        print("", file=sys.stderr)
        print(f"  允许的 tag: {', '.join('[' + t + ']' for t in ALLOWED_TAGS)}", file=sys.stderr)
        print("  也支持组合: [story][spawn:TPL-01] story-007: 描述", file=sys.stderr)
        print("", file=sys.stderr)
        print("  来源：BL-S004 commit-discipline rule", file=sys.stderr)
        print("  绕过（不推荐）：git commit --no-verify", file=sys.stderr)
        print("=" * 60, file=sys.stderr)
        return 1

    # ---- 渐进披露 lint（D-M1 修法）----
    # 调用 check_progressive_disclosure.py，把 commit msg 文件路径传入，让它检查 [layer-override]
    workspace = Path(__file__).resolve().parents[2]
    lint_script = workspace / ".codebuddy" / "scripts" / "check_progressive_disclosure.py"
    msg_file_arg = sys.argv[1] if len(sys.argv) >= 2 else str(workspace / ".git" / "COMMIT_EDITMSG")
    if lint_script.exists():
        try:
            r = subprocess.run(
                [sys.executable, str(lint_script), "--commit-msg", msg_file_arg, "--quiet"],
                capture_output=True, text=True, encoding="utf-8", timeout=10
            )
            if r.returncode == 2:
                # 用户审批区且无 [layer-override]
                print("=" * 60, file=sys.stderr)
                print("[pre-commit-discipline] ❌ 渐进披露 lint 阻塞", file=sys.stderr)
                print(r.stdout, file=sys.stderr)
                print("", file=sys.stderr)
                print("  原因：有 CORE 文件超 review 阈值进入用户审批区", file=sys.stderr)
                print("  解法（任选）：", file=sys.stderr)
                print("    1. 精简文件（推荐）", file=sys.stderr)
                print("    2. 拆到 MANUAL.md / ARCHIVE.md", file=sys.stderr)
                print("    3. 在 commit msg 加 [layer-override] tag 表示用户已审批", file=sys.stderr)
                print("=" * 60, file=sys.stderr)
                return 1
            elif r.returncode == 1:
                # 打回自审区且无 OVER_LIMIT_REASON
                print("=" * 60, file=sys.stderr)
                print("[pre-commit-discipline] ❌ 渐进披露 lint 阻塞", file=sys.stderr)
                print(r.stdout, file=sys.stderr)
                print("", file=sys.stderr)
                print("  原因：有 CORE 文件在打回自审区，但缺 OVER_LIMIT_REASON 注释", file=sys.stderr)
                print("  解法（任选）：", file=sys.stderr)
                print("    1. 精简文件（推荐）", file=sys.stderr)
                print("    2. 拆到 MANUAL.md", file=sys.stderr)
                print("    3. 在文件头部加 <!-- OVER_LIMIT_REASON: 具体理由 -->", file=sys.stderr)
                print("=" * 60, file=sys.stderr)
                return 1
            elif r.stdout and ("notice" in r.stdout.lower()):
                # 仅提醒，不阻塞但写日志
                pass  # 静默通过，详情可手动跑 lint 看
        except subprocess.TimeoutExpired:
            print("[pre-commit-discipline] ⚠ 渐进披露 lint 超时（跳过）", file=sys.stderr)
        except Exception as e:
            print(f"[pre-commit-discipline] ⚠ 渐进披露 lint 错误（跳过）: {e}", file=sys.stderr)

    return 0


if __name__ == "__main__":
    sys.exit(main())
