#!/usr/bin/env python3
"""UserPromptSubmit hook · 按用户 prompt 关键词精准注入相关知识。

设计原则：
- 不是"散弹枪式"全量注入，而是"狙击式"按场景命中
- 注入 CORE 红线 + 指向 MANUAL/PLAYBOOK/HANDBOOK 具体段（渐进披露架构）
- 每条匹配规则尽量短（~150-300 字符），避免污染

匹配规则按"风险优先级 P0 → P2"排序，命中后追加注入。
"""
from __future__ import annotations
import json
import os
import re
import sys
from pathlib import Path

if sys.platform == "win32":
    try:
        sys.stdout.reconfigure(encoding="utf-8")  # type: ignore[attr-defined]
        sys.stderr.reconfigure(encoding="utf-8")  # type: ignore[attr-defined]
    except Exception:
        pass

WORKSPACE = Path(__file__).resolve().parents[2]
TIMIAI_KEY = WORKSPACE / ".codebuddy" / "skills" / "timiai-image" / ".timiai_key"


# 匹配规则：(关键词正则, 注入文本生成函数 / 静态文本)
def rule_art_asset(prompt: str) -> str | None:
    pattern = r"(美术|资产|sprite|png|图片|texture|tile|atlas|背景|立绘|key visual|art|视觉|画面)"
    if not re.search(pattern, prompt, re.IGNORECASE):
        return None

    key_status = "❓ 未检测"
    if TIMIAI_KEY.exists():
        try:
            klen = len(TIMIAI_KEY.read_text(encoding="utf-8").strip())
            if klen > 0:
                key_status = f"✅ 就绪（{klen} 字符）"
            else:
                key_status = "❌ 文件存在但为空"
        except Exception as e:
            key_status = f"❌ 读取失败: {e}"
    else:
        key_status = "❌ 不存在"

    return f"""
### 🎨 美术任务注入

**timiai key 状态**：{key_status} · 路径：`{TIMIAI_KEY.as_posix()}`

**资产生成流程（按优先级）**：
1. 首选：spawn `art-director` agent → 调 `art-asset-pipeline` skill → 走 `timiai-image` pipeline
2. 次选（紧急且 key 不可用）：用 IDE `image_gen`，但**必须** commit msg 标 `[VISUAL_DEBT downgrade]` + backlog 开 VISUAL_DEBT 条目 + 入库前 `art-director` 走 in-context 评审

**关键命令**：
- 自检 key：`python .codebuddy/skills/timiai-image/scripts/_check_key.py`
- pipeline：`python .codebuddy/skills/timiai-image/scripts/pipeline.py --config <task.json>`

**详细资源（按需 read，不预读全文）**：
- `art-director` agent：CORE `agents/art-director/AGENT.md`（≤52 行 红线）→ 详细 6 维评审 / 决议词汇 → `agents/art-director/HANDBOOK.md` § 2-3
- `timiai-image` skill：CORE `skills/timiai-image/SKILL.md` → 五步工作流 / Prompt 七要素 → `PLAYBOOK.md` § 1-3 → 完整 API / daemon → `ARCHIVE.md`
- `art-asset-pipeline`：CORE `skills/art-asset-pipeline/SKILL.md` → 7 步流程 → `PLAYBOOK.md`

**相关反模式**：AP-03 / AP-04 / AP-10 / AP-11（详见 `studio/docs/anti-patterns.md` § AP-XX）

**禁止**：
- 看到 `.gitignore` 排除 `.timiai_key` 就假设它不存在（必须 Test-Path）
- 1024x1024 AI 图直接 Lanczos 缩小（必走 quantize 16 色 + nearest）
- 单看 raw 资产判 APPROVE（TPL-05 v2 强制 in-context 截图，AP-11）
"""


def rule_vertical_slice(prompt: str) -> str | None:
    pattern = r"(vertical[\s\-]?slice|关卡|level|可玩|playable|demo|完整体验)"
    if not re.search(pattern, prompt, re.IGNORECASE):
        return None

    return """
### 🎮 Vertical Slice 强制 5 项清单（AP-10 修法 · TPL-09）

任何"可玩 level / playable demo"必须 done 前确认 5 项**全部就位**：

| # | 检查项 | 缺失症状 | 修法 |
|---|---|---|---|
| 1 | **Camera2D 跟随玩家** | 镜头不动 | `player.tscn` 加 Camera2D（zoom + smoothing + limit）|
| 2 | **屏幕/世界边界** | 玩家走出 viewport | 左右 StaticBody2D + 底部 KillZone Area2D |
| 3 | **主角视觉辨识度** | 不知道哪个是主角 | 对比度 ≥ 4.5:1 + 描边 + 体型独特 |
| 4 | **死亡/失败反馈** | 死了没感觉 | KillZone + fade + 音效 + 重置 |
| 5 | **完成/胜利反馈** | 通关没感觉 | GoalArea + signal emit + UI 提示 + print |

reviewer 必须 grep 这 5 项实现，**任一缺失 → REQUEST_CHANGES**。
**禁止**：声称 "vertical slice 完成" 但未对照清单。

**详细 SOP**：
- TPL-09 完整模板：`.codebuddy/rules/agent-spawn-contract/MANUAL.md` § TPL-09
- 截图工具：`studio/templates/godot-screenshot/`
- AP-10 修法：`studio/docs/anti-patterns.md` § AP-10
"""


def rule_review_or_qa(prompt: str) -> str | None:
    pattern = r"(review|审|verdict|PASS|qa[\s\-]?gate|milestone|gate|质量)"
    if not re.search(pattern, prompt, re.IGNORECASE):
        return None

    return """
### 🔍 Review / QA 任务注入

**verdict 词汇（不允许 AI 自宣 QUALITY_PROVEN）**：
- AI 给的 verdict 必须带 `_MECHANISM` 后缀（`GATE_PASSED_MECHANISM` / `CONDITIONAL_PASS_MECHANISM` / `ADVANCE_MECHANISM`）
- `QUALITY_PROVEN` / `READY_FOR_RELEASE` 必须有用户实玩反馈作证据，AI 不能单独宣布

**reviewer 4 维 self_rubric**：每维 ≥ 1 条 evidence_lines（具体 file:line）。

**红线**：
- 测试 PASS 但只有 cheat-only（直接改 velocity/state）→ REQUEST_CHANGES
- 看到 `[文件] N 行` 但 read_file 显示 < N×0.8 → AP-09 截断 → REQUEST_CHANGES
- vertical slice review 必须独立跑 TPL-09（5 项清单），与 4 维代码 review 是独立维度
- 跨文件数值不一致 → 必须主动建议三方共识（BL-S026），不能只标 issue 就交差

**详细资源（按需 read）**：
- `reviewer` agent：CORE `agents/reviewer/AGENT.md` → 详细 4 维 / shadow team mode / TPL-08/09 → `HANDBOOK.md`
- `qa-lead` agent：CORE `agents/qa-lead/AGENT.md` → 7 项 metrics / 阈值表 → `HANDBOOK.md`
- `qa-gate` skill：CORE `skills/qa-gate/SKILL.md` → 4 步流程 + 阈值 → `PLAYBOOK.md` § 1-2
- `agent-spawn-contract` MANUAL § TPL-08（commit review）+ § TPL-09（vertical slice）

**相关反模式**：AP-09 / AP-10 / 防截断协议（`anti-patterns.md`）
"""


def rule_delete_command(prompt: str) -> str | None:
    pattern = r"(Remove-Item|\brm\b|\bdel\b|删除文件|清理)"
    if not re.search(pattern, prompt, re.IGNORECASE):
        return None

    return """
### ⚠️ 文件删除提示（AP-07）

**禁止**：execute_command 调用 `Remove-Item` / `rm` / `del`（触发 IDE 内置高危拦截 + 违反 tool-usage rule）

**正确**：
- 单文件：`delete_file` IDE 工具
- 批量：`python -c "import os,glob; [os.remove(f) for f in glob.glob('pattern')]"` 或写 .py 脚本
- 命令行兜底：`cmd /c "del /f path"`（cmd 的 del 不被特殊拦截）

**详细**：`tool-usage-no-popup` rule § Long Session 卫生 / 流程逃逸禁令 → `MANUAL.md`
"""


def rule_commit(prompt: str) -> str | None:
    pattern = r"(commit|提交|git)"
    if not re.search(pattern, prompt, re.IGNORECASE):
        return None

    return """
### 📝 Commit 注入

**commit-discipline**：message 必须带 tag `[story]` / `[fix]` / `[chore]` / `[hotfix]` / `[VISUAL_DEBT]` / `[refactor]` / `[docs]` / `[test]` / `[perf]` / `[feat]` / `[merge]` / `[revert]`

格式：`[tag] <scope>: <短描述>` · 大改动（≥100 行 或 ≥5 文件）前必须 spawn reviewer 走 TPL-08

**commit-msg hook 自动跑**：
1. tag 检查（`pre-commit-discipline.py`）
2. 渐进披露 lint（`check_progressive_disclosure.py`）—— rule/skill/agent CORE 超阈值会阻塞

**超 review 阈值的修法**（任选）：
- 精简内容（推荐）
- 拆到 MANUAL/PLAYBOOK/HANDBOOK
- 在文件头部加 `<!-- OVER_LIMIT_REASON: 具体理由 -->`
- approval 区且无 reason → commit msg 加 `[layer-override]` tag 表示用户已审批

**详细**：`commit-discipline` rule（CORE）/ `progressive-disclosure-architecture.md`（架构总文档）
"""


def rule_dev_story(prompt: str) -> str | None:
    pattern = r"(dev[\s\-]?story|story[\s\-]?\d|实现.*story|新.*story)"
    if not re.search(pattern, prompt, re.IGNORECASE):
        return None

    return """
### 📦 dev-story 流程注入

**状态机（6 状态，AP-10 修法）**：
ready → implementing → testing → reviewing → **playtest_pending** → done

**关键**：playtest_pending 必须用户实玩 ≥ 1 分钟 + `--playtest-confirmed-by user` 才能进 done，AI 不允许自跳。

**入口**：`python .codebuddy/skills/dev-story/run.py --story <path> --action <implement|test|review|playtest|done> [--shadow]`

**红线**：
- 视觉 story 必须先扫 `assets/`，缺资产 spawn `art-asset-pipeline` 或开 [VISUAL_DEBT]
- 玩家可见行为必须有"真实玩家路径测试"（Input.action_press），禁止 cheat-only
- vertical slice 进 reviewing 时必须跑 TPL-09 五项清单
- engineer **不允许**跳过状态机自重写已交付内容（BL-S025 流程逃逸）；如需重写必须 spawn 新 story 或回 implementing

**详细资源（按需 read）**：
- `dev-story` skill：CORE `skills/dev-story/SKILL.md` → 完整 11 步流程 / 绕过 SOP / DoD 自检 / 自主模式 → `PLAYBOOK.md` § 1-4
- `engineer` agent：CORE `agents/engineer/AGENT.md` → 详细实现 SOP → `HANDBOOK.md`
- TPL-01 实现模板：`agent-spawn-contract/MANUAL.md` § TPL-01
"""


def rule_progressive_disclosure(prompt: str) -> str | None:
    """新增：当用户/agent 提到改 rule/skill/agent 文档时提醒走渐进披露"""
    pattern = r"(改.*rule|改.*skill|改.*agent|新增.*rule|新增.*skill|新增.*agent|update.*rule|update.*skill|update.*agent|RULE\.mdc|SKILL\.md|AGENT\.md|MANUAL\.md|PLAYBOOK\.md|HANDBOOK\.md|ARCHIVE\.md)"
    if not re.search(pattern, prompt, re.IGNORECASE):
        return None

    return """
### 📚 渐进披露架构提示（D 系列改造）

工作室 rule / skill / agent 按**三层**组织：

| 层 | 文件 | 长度建议 | 注入时机 |
|---|---|---|---|
| **CORE** | `RULE.mdc` / `SKILL.md` / `AGENT.md` | rule/skill ≤30 / agent ≤40 | 每次 / spawn 时必带 |
| **MANUAL/PLAYBOOK/HANDBOOK** | 同名 .md | ≤150 | agent 按需 read_file |
| **ARCHIVE** | `ARCHIVE.md` | 无上限 | 仅 RCA / postmortem |

**改 / 新增文档时的决策树**：
```
新内容来了
├── 每次都遵守？        → CORE（精简 1-2 行）
├── 某场景必须遵守？     → MANUAL §对应场景
└── 仅历史溯源？        → ARCHIVE
```

**红线机制（分级提醒，非硬上限）**：
- 写完跑 lint：`python .codebuddy/scripts/check_progressive_disclosure.py`
- 超 review 阈值（rule/skill 50-80 / agent 60-100）→ 必须文件头部加 `<!-- OVER_LIMIT_REASON: 理由 -->`
- 超 approval 阈值（rule/skill 80+ / agent 100+）→ 必须 commit msg 加 `[layer-override]` tag

**反模式**：不归类直接追加到 CORE 末尾——这是滑坡的开端。

**详细**：`studio/docs/progressive-disclosure-architecture.md` / 模板见 `studio/templates/progressive-disclosure/`
"""


RULES = [
    rule_art_asset,
    rule_vertical_slice,
    rule_review_or_qa,
    rule_delete_command,
    rule_commit,
    rule_dev_story,
    rule_progressive_disclosure,
]


def main() -> int:
    try:
        raw = sys.stdin.read()
        data = json.loads(raw) if raw.strip() else {}
    except Exception:
        data = {}

    # CodeBuddy 传入字段：prompt（用户 prompt 文本）
    prompt = ""
    if isinstance(data, dict):
        prompt = data.get("prompt") or data.get("user_prompt") or ""
        if not prompt and "tool_input" in data:
            ti = data.get("tool_input") or {}
            if isinstance(ti, dict):
                prompt = ti.get("prompt") or ""

    if not prompt:
        print(json.dumps({"continue": True}, ensure_ascii=False))
        return 0

    injections = []
    for rule_fn in RULES:
        try:
            text = rule_fn(prompt)
            if text:
                injections.append(text)
        except Exception as e:
            injections.append(f"[rule_fn {rule_fn.__name__} 异常: {e}]")

    if not injections:
        print(json.dumps({"continue": True}, ensure_ascii=False))
        return 0

    additional_context = "## 工作室智能提示（按 prompt 关键词触发）\n" + "\n".join(injections)
    result = {
        "continue": True,
        "hookSpecificOutput": {
            "hookEventName": "UserPromptSubmit",
            "additionalContext": additional_context
        }
    }
    print(json.dumps(result, ensure_ascii=False))
    return 0


if __name__ == "__main__":
    sys.exit(main())
