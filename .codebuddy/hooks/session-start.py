#!/usr/bin/env python3
"""SessionStart hook · 极简引导（不注入全文，避免上下文浪费）。

设计原则：
- 只注入"索引 + 路径指引"——告诉 main agent **有哪些资源、什么场景查哪个**
- 真正的细则由 UserPromptSubmit / PreToolUse hook 按场景精准注入
- 上下文成本控制在 ~500 字符以内

参考 CodeBuddy 官方 Hooks 规范：
  hookSpecificOutput.additionalContext 会被注入到 main agent
"""
from __future__ import annotations
import json
import os
import sys
from datetime import datetime
from pathlib import Path

if sys.platform == "win32":
    try:
        sys.stdout.reconfigure(encoding="utf-8")  # type: ignore[attr-defined]
        sys.stderr.reconfigure(encoding="utf-8")  # type: ignore[attr-defined]
    except Exception:
        pass

WORKSPACE = Path(__file__).resolve().parents[2]


def main() -> int:
    try:
        sys.stdin.read()
    except Exception:
        pass

    # 活跃项目数
    project_dir = WORKSPACE / "projects"
    project_n = sum(1 for _ in project_dir.glob("*/PROJECT.md")) if project_dir.exists() else 0

    # 极简引导文本（~600 字符）
    ctx = f"""# 工作室引导（{datetime.now().strftime('%Y-%m-%d %H:%M')}）

活跃项目: {project_n} 个 · 工作区: `{WORKSPACE.as_posix()}`

## 渐进披露三层结构（重要）

每个 rule / skill / agent 都按三层组织：
- **CORE**（`RULE.mdc` / `SKILL.md` / `AGENT.md`）：身份 + 红线 + 索引（每次注入 / spawn 时必带）
- **MANUAL/PLAYBOOK/HANDBOOK**：详细 SOP / 模板（按需 read_file，CORE 中有指引）
- **ARCHIVE**：历史判例（仅 RCA / postmortem 时查）

→ 不要假设 CORE 即全部内容；遇到具体场景时按 CORE 指引 read 对应 MANUAL §

## 高频资源索引

| 任务类型 | 入口 |
|---|---|
| 美术/资产/sprite/png | spawn `art-director` agent OR `python .codebuddy/skills/timiai-image/scripts/_check_key.py` 自检 → `art-asset-pipeline` skill |
| 实现 story | `python .codebuddy/skills/dev-story/run.py` |
| milestone 评审 | `python .codebuddy/skills/milestone-review/run.py` |
| qa gate | `python .codebuddy/skills/qa-gate/run.py` |
| spawn agent | `.codebuddy/rules/agent-spawn-contract/MANUAL.md` § TPL-01~09 |

## 知识库（按需查阅，不预读全文）

- 反模式 11 条：digest `studio/docs/anti-patterns-digest.md`（CORE）→ manual `anti-patterns.md` → archive `anti-patterns-archive.md`
- 项目结构：`.codebuddy/rules/project-structure/RULE.mdc`
- 工具用法：`.codebuddy/rules/tool-usage-no-popup/RULE.mdc`（→ MANUAL.md 详细）
- 渐进披露架构：`studio/docs/progressive-disclosure-architecture.md`

## 强制约束

1. 删文件用 `delete_file` 工具，禁止 `Remove-Item`/`rm`/`del`
2. 写完长文件用 `read_file` 验证行数（AP-09）
3. 美术资产**必须**先跑 `_check_key.py` 再决定路径（AP-10）
4. vertical slice 必须有：camera/边界/视觉/反馈/完成（AP-10 修法）
5. 不允许 AI 自宣布 QUALITY_PROVEN，最高只能 QUALITY_MECHANISM_PROVEN

> 触发其中任一关键词时，UserPromptSubmit hook 会注入相应细则。
"""

    result = {
        "continue": True,
        "hookSpecificOutput": {
            "hookEventName": "SessionStart",
            "additionalContext": ctx
        }
    }
    print(json.dumps(result, ensure_ascii=False))
    return 0


if __name__ == "__main__":
    sys.exit(main())
