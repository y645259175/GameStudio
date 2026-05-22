#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
dev-story · run.py · 命令行可执行版

把 dev-story skill 从"流程文档"升级为"可执行 pipeline"。

Story 状态机：
    READY → IMPLEMENTING → TESTING → REVIEWING → DONE

每个 action 生成对应的 spawn-prompt：
    --action implement → engineer    (TPL-01)
    --action test      → tester      (TPL-07)
    --action review    → reviewer    (TPL-08)
    --action done      → 跑 consistency-check + 收尾

行为：
1. 解析 story md frontmatter 拿当前 status
2. 校验 status 转换合法（不允许跳级）
3. 自动注入 GDD 锚点 + 相关代码 + sister story 上下文
4. 生成符合 agent-spawn-contract 4 契约的 prompt
5. 落盘到 .codebuddy/temp/

用法：
    python .codebuddy/skills/dev-story/run.py \
        --story projects/bolt-1-1/stories/story-007.md \
        --action implement
"""

from __future__ import annotations

import argparse
import datetime
import io
import re
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

# 状态机定义（含起点）
# AP-10 修法：reviewing → playtest_pending → done
# playtest_pending 必须真人玩家实玩 ≥ 1 分钟才能 --action done，AI 不允许自跳
STATES = ["ready", "implementing", "testing", "reviewing", "playtest_pending", "done"]
TRANSITIONS = {
    "ready":            {"implement": "implementing"},
    "implementing":     {"test":      "testing"},
    "testing":          {"review":    "reviewing"},
    "reviewing":        {"playtest":  "playtest_pending"},
    "playtest_pending": {"done":      "done"},
    # done 状态无后继；允许从任何状态跳到 ready（重启）
}

ACTION_TO_NEXT = {
    "implement": ("ready", "implementing"),
    "test":      ("implementing", "testing"),
    "review":    ("testing", "reviewing"),
    "playtest":  ("reviewing", "playtest_pending"),
    "done":      ("playtest_pending", "done"),
}

ACTION_TO_AGENT = {
    "implement": "engineer",
    "test":      "tester",
    "review":    "reviewer",
    "playtest":  None,  # playtest 需用户实玩，不 spawn agent
    "done":      None,  # 收尾不 spawn
}

# combo-B M5: shadow-review 异类 agent 路由表
# 原则：shadow 用不同 domain 的 agent，避免同质化盲区
SHADOW_ROUTE = {
    "review": "qa-lead",  # reviewer 产出由 qa-lead 从测试覆盖性视角 shadow
}


# ---------------------------------------------------------------------------
# 工具
# ---------------------------------------------------------------------------

def _now() -> str:
    return datetime.datetime.now().strftime("%Y-%m-%d_%H%M%S")


def _read_text_safe(path: Path) -> str:
    try:
        return path.read_text(encoding="utf-8", errors="replace")
    except Exception:  # noqa: BLE001
        return ""


def parse_frontmatter(text: str) -> tuple[dict, str]:
    """解析 YAML frontmatter（轻量解析，不引入 yaml 依赖）"""
    if not text.startswith("---"):
        return {}, text
    parts = text.split("---", 2)
    if len(parts) < 3:
        return {}, text
    fm_text = parts[1]
    body = parts[2].lstrip("\n")
    fm: dict = {}
    for line in fm_text.splitlines():
        line = line.strip()
        if not line or line.startswith("#"):
            continue
        m = re.match(r"^([\w\-]+)\s*:\s*(.*)$", line)
        if m:
            key, val = m.group(1), m.group(2).strip()
            # 简单处理引号
            if val.startswith('"') and val.endswith('"'):
                val = val[1:-1]
            fm[key] = val
    return fm, body


def find_project_dir(story_path: Path) -> Path:
    """从 story 路径反推 project 根（projects/<name>/stories/<x>.md）"""
    for parent in story_path.resolve().parents:
        if parent.name == "stories" and parent.parent.name and parent.parent.parent.name == "projects":
            return parent.parent
    raise ValueError(f"无法从 {story_path} 反推 project dir（期望 projects/<name>/stories/<x>.md）")


def update_story_status(story_path: Path, new_status: str) -> bool:
    """改 story md frontmatter status 字段；不存在则插入"""
    text = _read_text_safe(story_path)
    if not text:
        return False
    fm, body = parse_frontmatter(text)
    if not fm:
        # 没 frontmatter，加一个
        new_text = f"---\nstatus: {new_status}\n---\n\n{text}"
    else:
        if "status" in fm:
            new_fm_text = re.sub(
                r"^(\s*status\s*:\s*)\S+",
                rf"\1{new_status}",
                text.split('---', 2)[1],
                count=1,
                flags=re.M,
            )
        else:
            new_fm_text = text.split('---', 2)[1].rstrip() + f"\nstatus: {new_status}\n"
        new_text = f"---{new_fm_text}---\n{body}"
    story_path.write_text(new_text, encoding="utf-8")
    return True


# ---------------------------------------------------------------------------
# Spawn-prompt 模板（与 agent-spawn-contract TPL-01/07/08 对齐）
# ---------------------------------------------------------------------------

PROMPT_ENGINEER = """你是 engineer agent。本次任务：实现 user story `{story_id}`。

## 任务模式（agent-spawn-contract）
- Mode: DRAFT（首次实现） / PATCH（已有部分代码补完，由你判断）
- Output paths（必须落盘）:
  1. {code_file_hint}  ← 主代码文件（如不确定路径，参考 story 中的"涉及文件"段）
  2. {story_path}      ← 完成后将 status 改为 implementing→testing 的中转标记（status 字段会由 dev-story run.py 自动维护，你只需关注代码）
- Output mode: overwrite for code, replace_in_file for story status

## 现状注入

### Story 全文
{story_excerpt}

### 关联 GDD 锚点（如已识别）
{gdd_anchor_hint}

### 项目元数据
- engine: {engine}
- workspace: {workspace}
- project: {project}

## 实现约束
- 严格按 story acceptance criteria 实现，不擅自扩展
- 遵守 `code-standards` rule
- GDScript：每改完 .gd 必须本地跑 `godot --headless --check-only --path {project_game_path} --quit`，EXIT 0 才算完成
- 改动 ≥ 100 行或新建 ≥ 3 文件 → 在 message 中标 `needs_review: true`
- **不要写测试**（测试在下一步 dev-story --action test 由 tester agent 写）

## 视觉资产红线（dev-story SOP 强制）
- 如 story 涉及视觉，先扫 `projects/{project}/game/assets/` 是否齐
- 缺资产 → spawn `art-asset-pipeline` 或开 `[VISUAL_DEBT]` backlog 条目，**不允许默认 ColorRect 占位**
- 详见 anti-patterns.md AP-04

## 真实玩家路径测试预留
- 如 story 涉及玩家可见行为，本次 implement 阶段就要确保有 InputMap action 注册（不写测试，但留好接口）
- 用 Input.action_press 写测试是下一步 tester 的事，但接口必须 ready

## 交付协议
1. 落盘代码 + headless check EXIT 0
2. send_message(type="message", content="实现完成: <文件清单 + 行数>; needs_review: yes/no; headless check: PASS")
3. 等 main agent 确认
4. shutdown_response(approve=true, reason="代码实现交付完成")

## 不允许（来自 retro 教训）
- ColorRect 默认占位（AP-04）
- cheat-only 隐藏 bug（AP-04）
- 不跑 headless check 就交付
- 把代码塞到 shutdown reason 里
"""

PROMPT_TESTER = """你是 tester agent。本次任务：为 story `{story_id}` 编写测试。

## 任务模式
- Mode: DRAFT（新建测试文件）
- Output path: projects/{project}/qa/tests/test_{story_slug}.gd
- Output mode: new_file

## 现状注入

### Story 全文
{story_excerpt}

### 实现代码（engineer 刚落盘）
请你 read_file 以下代码看实现：
{code_file_hint}

### 测试入口约定
- 项目测试入口：projects/{project}/qa/run-tests.ps1
- 测试基类 / 工具：参考 projects/{project}/qa/tests/ 已有文件

## 测试覆盖必须包含（test-standards rule）
1. **happy path** — acceptance criteria 每条 ≥ 1 测试
2. **edge case** — 输入边界 / null / 空数组 / 极端数值
3. **真实玩家路径测试** — 至少 1 条用 InputMap action_press 模拟玩家输入（dev-story 红线）
4. **回归点** — 如 story 修复 bug，加 1 条防回归

## 不允许（AP-04 / dev-story 红线）
- 只写 cheat-mode 测试（必须含真实输入路径）
- 跳过 edge case
- 测试不能跑（落盘后必须能跑通）

## 交付协议
1. 落盘 test_{story_slug}.gd
2. 跑测试入口确保 PASS（如 run-tests.ps1 存在）
3. send_message(type="message", content="测试完成 N 条；real_input_test included: yes/no；本地 run-tests: PASS/FAIL")
4. shutdown_response approve=true
"""

PROMPT_REVIEWER = """你是 reviewer agent。本次任务：对 story `{story_id}` 实现做 review。

## 任务模式
- Mode: REVIEW
- Output: 通过 send_message 返回 verdict + 修改清单（不强制落盘文件）

## 现状注入

### Story 全文
{story_excerpt}

### engineer 实现 + tester 测试 文件
请 read_file 这些文件评审：
{code_file_hint}
projects/{project}/qa/tests/test_{story_slug}.gd

### 关联 rule
- `commit-discipline`
- `code-standards`
- `test-standards`

## 评审 4 维
1. **正确性** — 实现是否真正满足 acceptance criteria？
2. **风险** — 是否引入回归（命名冲突 / 全局状态污染 / 性能热点）？
3. **风格** — 命名 / 注释 / 错误处理符合 code-standards？
4. **测试质量** — tester 是否覆盖 happy + edge + 真实输入 + 回归点？

## 综合 verdict
- APPROVE — 可 commit
- APPROVE_WITH_NITS — 可 commit + 列建议（不阻塞）
- REQUEST_CHANGES — 必须修后再 commit

## 交付协议
1. send_message(type="message", content="review verdict: <X>; 改进项: <清单或 'none'>")
2. 等 main agent 确认
3. shutdown_response approve=true

## 不允许
- "看起来没问题"（必须给行号 + 文件 + 理由）
- 评审超过 30 分钟（拆批，每次 ≤ 200 行 diff）
"""


# ---------------------------------------------------------------------------
# 主流程
# ---------------------------------------------------------------------------

def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(prog="dev-story run.py")
    parser.add_argument("--story", required=True, help="story md 路径（绝对或相对工作区）")
    parser.add_argument("--action", required=True,
                        choices=["implement", "test", "review", "playtest", "done", "status"],
                        help="状态机 action 或 'status' 只看当前状态。"
                             "playtest = 标记进入用户实玩阶段；done 必须从 playtest_pending 转")
    parser.add_argument("--force", action="store_true",
                        help="跳过状态转换检查（用于修复异常 story；AP-10 修法下慎用，会跳过 playtest gate）")
    parser.add_argument("--playtest-confirmed-by", default=None,
                        help="必须在 --action done 时提供：声明用户已实玩验收。"
                             "传 'user' 表示主人类用户已验收；传 'skip-scaffold' 表示脚手架 story 豁免实玩")
    parser.add_argument("--code-file", default=None, help="指定主代码文件路径（路径提示注入 prompt）")
    parser.add_argument("--gdd-anchor", default=None, help="关联 GDD 章节路径")
    parser.add_argument("--shadow", action="store_true",
                        help="combo-B: 在 review 阶段额外生成 shadow-review prompt（异类 agent 二审）")
    args = parser.parse_args(argv)

    # 解析 story 路径
    story_path = Path(args.story)
    if not story_path.is_absolute():
        story_path = (WORKSPACE / story_path).resolve()
    if not story_path.exists():
        print(f"[error] story 文件不存在: {story_path}", file=sys.stderr)
        return 2

    # 反推 project
    try:
        project_dir = find_project_dir(story_path)
    except ValueError as e:
        print(f"[error] {e}", file=sys.stderr)
        return 2
    project = project_dir.name

    # 解析 frontmatter
    text = _read_text_safe(story_path)
    fm, body = parse_frontmatter(text)
    current_status = (fm.get("status") or "ready").lower()
    story_id = fm.get("id") or story_path.stem

    print(f"[dev-story] story={story_id} · project={project} · 当前状态={current_status}", file=sys.stderr)

    # action=status 仅打印
    if args.action == "status":
        print(f"story_id: {story_id}")
        print(f"project: {project}")
        print(f"current_status: {current_status}")
        print(f"available_actions: {list(TRANSITIONS.get(current_status, {}).keys()) or ['(终态 / 需要 --force 重置)']}")
        return 0

    # 校验状态转换合法
    expected_from, expected_to = ACTION_TO_NEXT[args.action]
    if not args.force and current_status != expected_from:
        print(f"[error] 状态非法：{current_status} 不能执行 --action {args.action}", file=sys.stderr)
        print(f"        期望状态: {expected_from} → {expected_to}", file=sys.stderr)
        print(f"        如需强制，加 --force", file=sys.stderr)
        return 3

    # 收尾 action=done（AP-10 修法：强制 playtest gate）
    if args.action == "done":
        # 必须从 playtest_pending 转入（或显式 --force）
        if not args.force and current_status != "playtest_pending":
            print(f"[error AP-10] 当前状态 '{current_status}' 不能直接 --action done", file=sys.stderr)
            print(f"        playtest gate 要求：reviewing → playtest_pending → done", file=sys.stderr)
            print(f"        先跑：python {sys.argv[0]} --story {args.story} --action playtest", file=sys.stderr)
            print(f"        然后用户实玩 ≥ 1 分钟后再跑 --action done --playtest-confirmed-by user", file=sys.stderr)
            return 3

        # 必须显式声明 playtest 谁验收（防 AI 自跳）
        if not args.force and not args.playtest_confirmed_by:
            print("[error AP-10] --action done 必须带 --playtest-confirmed-by 参数", file=sys.stderr)
            print("        合法值：'user'（主人类用户实玩验收）/ 'skip-scaffold'（脚手架 story，无玩法）", file=sys.stderr)
            print("        AI agent 不允许自己声明实玩通过", file=sys.stderr)
            return 3

        update_story_status(story_path, "done")
        confirmed_by = args.playtest_confirmed_by or "force"
        print(f"[ok] story {story_id} 状态: {current_status} → done · playtest_confirmed_by={confirmed_by}")

        # 自动跑 consistency-check（BL-S020 修法）
        print()
        print("=" * 60)
        print("自动运行 consistency-check...")
        print("=" * 60)
        cc_script = Path(__file__).resolve().parents[1] / "consistency-check" / "run.py"
        if cc_script.exists():
            import subprocess
            project_name = story_path.resolve().parts[-3] if len(story_path.resolve().parts) >= 3 else None
            cc_args = [sys.executable, str(cc_script), "--no-report"]
            if project_name:
                cc_args.extend(["--project", project_name, "--story", story_id])
            r = subprocess.run(cc_args, capture_output=False, text=True, encoding="utf-8",
                               cwd=str(Path(__file__).resolve().parents[3]), timeout=30)
            if r.returncode != 0:
                print(f"\n[warn] consistency-check 发现 critical 问题（exit={r.returncode}）")
                print("       请修复后再 commit")
        else:
            print("  (consistency-check run.py 不存在，跳过)")
        print()
        print("Story 收尾建议：")
        print(f"  1. commit message: [story] {story_id}: <短描述>")
        print(f"  2. 如本次改动 >= 100 行：再 spawn reviewer 看 commit 前 review（TPL-08）")
        print("=" * 60)
        return 0

    # action=playtest（reviewing → playtest_pending）— 不 spawn，只切状态 + 给用户实玩指引
    if args.action == "playtest":
        update_story_status(story_path, "playtest_pending")
        print(f"[ok] story {story_id} 状态: {current_status} → playtest_pending")
        print()
        print("=" * 60)
        print("⏸  PLAYTEST GATE（AP-10 修法）")
        print("=" * 60)
        print(f"现在需要**用户**实玩验收。AI 不允许自己跳过此步骤。")
        print()
        print(f"  1. 启动游戏：godot --path projects/{project}/game")
        print(f"  2. 用户实玩 ≥ 1 分钟，对照 vertical slice 5 项清单：")
        print(f"     [ ] Camera2D 跟随玩家")
        print(f"     [ ] 屏幕/世界边界（不能走出 viewport）")
        print(f"     [ ] 主角视觉辨识度（能一眼看到）")
        print(f"     [ ] 死亡/失败反馈")
        print(f"     [ ] 完成/胜利反馈")
        print(f"  3. 全部 OK → 用户确认后跑：")
        print(f"     python {sys.argv[0]} --story {args.story} --action done --playtest-confirmed-by user")
        print(f"  4. 任何一项不 OK → 退回 reviewing，spawn engineer 修复：")
        print(f"     在 story md 把 status 改回 reviewing，加 hotfix 子任务")
        print("=" * 60)
        return 0

    # 准备 prompt 模板变量
    project_md_path = project_dir / "PROJECT.md"
    project_md_text = _read_text_safe(project_md_path)
    m_engine = re.search(r"^\s*engine\s*[:=]\s*([\w\-\.]+(?:\s+[\w\-\.]+)*)", project_md_text, re.M | re.I)
    engine = m_engine.group(1).strip().split("\n")[0].strip() if m_engine else "unknown"

    story_excerpt = body.strip()
    if len(story_excerpt) > 3000:
        story_excerpt = story_excerpt[:2800] + "\n... (story 截断，详见 " + str(story_path.relative_to(WORKSPACE)) + ")"

    code_file_hint = args.code_file or "(未指定，请按 story 中描述定位)"
    gdd_anchor_hint = args.gdd_anchor or "(请 read_file projects/" + project + "/gdd/ 下相关章节)"
    story_slug = story_id

    common_vars = dict(
        story_id=story_id,
        project=project,
        story_path=str(story_path.relative_to(WORKSPACE)).replace("\\", "/"),
        story_excerpt=story_excerpt,
        code_file_hint=code_file_hint,
        gdd_anchor_hint=gdd_anchor_hint,
        engine=engine,
        workspace=str(WORKSPACE),
        project_game_path=str((project_dir / "game").resolve()),
        story_slug=story_slug,
    )

    template_map = {
        "implement": PROMPT_ENGINEER,
        "test":      PROMPT_TESTER,
        "review":    PROMPT_REVIEWER,
    }
    template = template_map[args.action]
    prompt = template.format(**common_vars)

    # --- combo-B M3: 自动 inject AGENT.md 产出契约 + self-rubric 引用 ---
    agent_name = ACTION_TO_AGENT[args.action]
    agent_dir = WORKSPACE / ".codebuddy" / "agents" / agent_name
    schema_path = agent_dir / "output-schema.yaml"
    combo_b_inject = ""
    if schema_path.exists():
        combo_b_inject = f"""

## 你的产出契约与自检（combo-B 强制）
1. read_file `.codebuddy/agents/{agent_name}/output-schema.yaml` — 你的产出字段定义 + self_rubric 自检清单
2. read_file `.codebuddy/agents/{agent_name}/AGENT.md` § 自检步骤 + § 产出契约 — 你的交付前强制步骤
3. 交付前必须跑 self_rubric 逐条自查，全过后在 send_message 中标注 `self_rubric: N/N PASS`
4. 如工作中发现新经验 → 追加到 `.codebuddy/agents/{agent_name}/playbook.md` 待消化素材区
"""
    prompt += combo_b_inject

    # 落盘 prompt
    TEMP_DIR.mkdir(parents=True, exist_ok=True)
    ts = _now()
    prompt_path = TEMP_DIR / f"dev-story-{args.action}-{project}-{story_slug}-{ts}.md"
    prompt_path.write_text(prompt, encoding="utf-8")

    # 转换状态
    update_story_status(story_path, expected_to)

    rel = prompt_path.relative_to(WORKSPACE)
    print(f"[ok] story 状态: {current_status} → {expected_to}")
    print(f"[ok] spawn-prompt: {rel}")

    # combo-B M5: shadow-review prompt 生成
    shadow_agent = SHADOW_ROUTE.get(args.action) if args.shadow else None
    shadow_rel = None
    if shadow_agent:
        _lines = [
            "你是 {sa} agent，本次以 **shadow reviewer** 身份工作。",
            "",
            "## 任务模式",
            "- Mode: SHADOW-REVIEW（独立二审，不是接力）",
            "- Output: send_message 返回你的独立 verdict",
            "",
            "## 你的视角",
            "- 主 reviewer 看：正确性 / 风险 / 风格 / commit 纪律",
            "- 你看：测试覆盖性 + 真实输入路径 + 回归矩阵覆盖",
            "",
            "## 现状注入",
            "- Story: {sid} (项目: {proj})",
            "- 主代码: {cf}",
            "- 测试文件: projects/{proj}/qa/tests/test_{slug}.gd",
            "- read_file .codebuddy/agents/{sa}/output-schema.yaml",
            "",
            "## 你要独立回答的 3 个问题",
            "1. 测试是否含真实输入路径（action_press）？不含则 verdict=REQUEST_CHANGES",
            "2. 测试是否覆盖 story 全部 AC？",
            "3. 改动是否影响回归矩阵中的高风险路径？",
            "",
            "## 交付协议",
            "1. send_message verdict + 与主 reviewer 一致/不一致 + 理由",
            "2. 如不一致列具体分歧点 + evidence",
            "3. shutdown_response approve=true",
            "",
            "## combo-B 产出契约",
            "read_file .codebuddy/agents/{sa}/output-schema.yaml",
            "read_file .codebuddy/agents/{sa}/AGENT.md",
            "交付前 self_rubric 自检。",
        ]
        shadow_prompt = "\n".join(_lines).format(
            sa=shadow_agent, sid=story_id, proj=project, cf=code_file_hint, slug=story_slug
        )
        shadow_path = TEMP_DIR / f"dev-story-shadow-{shadow_agent}-{project}-{story_slug}-{_now()}.md"
        shadow_path.write_text(shadow_prompt, encoding="utf-8")
        shadow_rel = shadow_path.relative_to(WORKSPACE)
        print(f"[ok] shadow-prompt ({shadow_agent}): {shadow_rel}")

    print()
    print("=" * 60)
    print(f"下一步（main agent 操作）：")
    print(f"  使用 task 工具 spawn `{agent_name}` agent，prompt 见: {rel}")
    if shadow_rel:
        print(f"  [shadow] 用 team 模式 spawn `{shadow_agent}` agent（name='{shadow_agent}-shadow'），prompt 见: {shadow_rel}")
        print(f"  reviewer + shadow 必须隔离（team 模式确保互不可见 verdict）")
        print(f"  两方 verdict 都回来后比对——不一致需 main agent 仲裁")
    print(f"  契约要点：4 契约")
    print(f"  完成后跑：python .codebuddy/skills/dev-story/run.py --story {args.story} --action <下一步>")
    print("=" * 60)

    return 0


if __name__ == "__main__":
    sys.exit(main())
