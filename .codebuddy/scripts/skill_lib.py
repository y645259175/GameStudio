"""共享 skill 辅助库 · 给 run.py 类 skill 复用"""
from __future__ import annotations

import re
import sys
from pathlib import Path
from typing import Any


def force_utf8():
    if sys.platform == "win32":
        try:
            sys.stdout.reconfigure(encoding="utf-8")  # type: ignore[attr-defined]
        except Exception:
            pass


def find_workspace_root(start: Path | None = None) -> Path:
    """从当前位置往上找 .codebuddy 目录定位 workspace root。"""
    p = (start or Path.cwd()).resolve()
    while p != p.parent:
        if (p / ".codebuddy").is_dir():
            return p
        p = p.parent
    return Path.cwd().resolve()


def find_project(name: str | None, ws: Path) -> Path | None:
    """根据名字找项目目录；name=None 时尝试从当前路径推断。"""
    projects_dir = ws / "projects"
    if not projects_dir.exists():
        return None
    if name:
        target = projects_dir / name
        return target if target.is_dir() else None
    # 从当前 cwd 推断
    cwd = Path.cwd().resolve()
    for proj in projects_dir.iterdir():
        if proj.is_dir() and (cwd == proj or proj in cwd.parents):
            return proj
    return None


def list_projects(ws: Path) -> list[str]:
    projects_dir = ws / "projects"
    if not projects_dir.exists():
        return []
    return sorted(p.name for p in projects_dir.iterdir() if p.is_dir() and (p / "PROJECT.md").exists())


def read_text(p: Path, default: str = "") -> str:
    try:
        return p.read_text(encoding="utf-8")
    except Exception:
        return default


def parse_frontmatter(text: str) -> tuple[dict, str]:
    """解析 markdown frontmatter（YAML 格式 --- 包围）+ 返回 body。"""
    if not text.startswith("---"):
        return {}, text
    parts = text.split("---", 2)
    if len(parts) < 3:
        return {}, text
    fm: dict = {}
    for line in parts[1].strip().splitlines():
        m = re.match(r"^\s*([\w_-]+)\s*:\s*(.+?)\s*$", line)
        if m:
            fm[m.group(1)] = m.group(2)
    return fm, parts[2]


def list_stories(proj: Path) -> list[Path]:
    stories_dir = proj / "stories"
    if not stories_dir.exists():
        return []
    return sorted(stories_dir.glob("story-*.md"))


def load_story(story_file: Path) -> dict:
    """读 story，提取 frontmatter + AC / GDD 锚点 / 估算等关键字段。"""
    text = read_text(story_file)
    fm, body = parse_frontmatter(text)
    # AC 数量
    ac_lines = re.findall(r"^\s*-\s*\[?\s*[xX ]?\s*\]?\s*AC[\s\-:]", body, re.MULTILINE)
    ac_count = len(ac_lines)
    if ac_count == 0:
        # 退化方案：扫 "## 验收标准" 段下面的列表项
        m = re.search(r"##\s*(?:验收标准|Acceptance Criteria|AC)\s*\n((?:[\s\S](?!##))*)", body)
        if m:
            seg = m.group(1)
            ac_count = len(re.findall(r"^\s*[-*]\s+", seg, re.MULTILINE))
    # GDD 锚点
    gdd_anchors = re.findall(r"gdd[/-][\w\-]+\.md(?:#\S+)?", body, re.IGNORECASE)
    # 估算
    estimate = fm.get("estimate") or fm.get("size")
    if not estimate:
        m = re.search(r"(?:估算|estimate|size)\s*[:：]\s*([XSMLxsmlxl]+)", body)
        if m:
            estimate = m.group(1).upper()
    # 用户视角描述
    has_user_story = bool(re.search(r"作为\s*[\w]+.*[，,]\s*我想.*[，,]\s*以便", body)) or \
                     bool(re.search(r"as a\s+\w+.*[,，]\s*i want.*[,，]\s*so that", body, re.IGNORECASE))
    # 模糊词
    fuzzy_words = ["流畅", "美观", "差不多", "尽快", "适当", "合理", "feels good", "smooth"]
    fuzzy_hits = [w for w in fuzzy_words if w in body]
    # status
    status = fm.get("status", "unknown").strip().strip("\"'")
    return {
        "file": story_file,
        "title": fm.get("title", story_file.stem),
        "id": fm.get("id", story_file.stem),
        "status": status,
        "ac_count": ac_count,
        "gdd_anchors": gdd_anchors,
        "estimate": estimate,
        "has_user_story": has_user_story,
        "fuzzy_hits": fuzzy_hits,
        "body_len": len(body),
    }


def list_gdd_chapters(proj: Path) -> list[Path]:
    gdd_dir = proj / "gdd"
    if not gdd_dir.exists():
        return []
    return sorted(gdd_dir.glob("*.md"))


def gdd_section_count(gdd_dir: Path) -> int:
    """统计 GDD 章节数（每章一个 md 或 H1 节）。返回章节文件数。"""
    if not gdd_dir.exists():
        return 0
    return len(list(gdd_dir.glob("*.md")))


REQUIRED_GDD_SECTIONS = [
    ("overview", ["overview", "1-overview", "概述"]),
    ("pillars", ["pillars", "2-pillars", "核心支柱", "design-pillars"]),
    ("mechanics", ["mechanics", "3-mechanics", "核心机制"]),
    ("ux", ["ux", "interaction", "user-experience", "4-"]),
    ("art", ["art", "5-art", "美术", "visual"]),
    ("audio", ["audio", "6-audio", "音频"]),
    ("scope", ["scope", "7-scope", "范围"]),
    ("milestones", ["milestone", "roadmap", "8-", "里程碑"]),
]


def gdd_completeness(proj: Path) -> dict:
    """检查 GDD 8 节完整度。"""
    gdd_dir = proj / "gdd"
    if not gdd_dir.exists():
        return {"present": [], "missing": [k for k, _ in REQUIRED_GDD_SECTIONS], "files": []}
    files = [f.name.lower() for f in gdd_dir.glob("*.md")]
    present, missing = [], []
    for sec, keywords in REQUIRED_GDD_SECTIONS:
        if any(any(k in f for k in keywords) for f in files):
            present.append(sec)
        else:
            missing.append(sec)
    return {"present": present, "missing": missing, "files": files}


def print_section(title: str, char: str = "="):
    line = char * 70
    print(line)
    print(title)
    print(line)


def emit_skill_call_log(skill_name: str, args: dict[str, Any], ws: Path):
    """显式标记 skill 被调用（兜底，确保 metrics 能看到）。
    PreToolUse hook 已经会捕获 run.py 调用，这里再写一次保证万一 hook 失败也有记录。"""
    import json
    from datetime import datetime, timezone
    log_dir = ws / ".codebuddy" / "logs"
    log_dir.mkdir(parents=True, exist_ok=True)
    log = log_dir / f"skill-call-{datetime.now().strftime('%Y-%m-%d')}.jsonl"
    entry = {
        "ts": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
        "skill_name": skill_name,
        "runner": "py",
        "from_run_py": True,
        "args": {k: str(v)[:100] for k, v in args.items()},
    }
    try:
        with open(log, "a", encoding="utf-8") as f:
            f.write(json.dumps(entry, ensure_ascii=False) + "\n")
    except Exception:
        pass
