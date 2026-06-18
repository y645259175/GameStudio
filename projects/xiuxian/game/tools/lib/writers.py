"""把校验后的数据写到运行时格式：

  data/baked/<output>.tres   ← Godot Resource (text format)
  data/debug/<output>.json   ← debug 用 JSON，方便 diff / 工具读
  data/baked/_manifest.json  ← 烘焙清单（含源 hash，支持增量）
"""
from __future__ import annotations
import hashlib
import json
import time
from pathlib import Path
from typing import Any


# ----------------------------------------------------------------------------
# Godot .tres
# ----------------------------------------------------------------------------

def write_tres(out_path: Path, tables_data: dict[str, list[dict[str, Any]]]) -> None:
    """写 Godot Resource 文本格式。

    结构：
      [gd_resource type="Resource" format=3]
      [resource]
      data = {
          "BuffType": [...],
          "BuffInstance": [...]
      }
    Godot 端 load() 后 resource.data 即为 Dictionary。
    """
    out_path.parent.mkdir(parents=True, exist_ok=True)
    body = _format_tres_dict(tables_data, indent=0)
    content = (
        '[gd_resource type="Resource" format=3]\n\n'
        '[resource]\n'
        f'data = {body}\n'
    )
    out_path.write_text(content, encoding="utf-8", newline="\n")


def _format_tres_dict(d: dict, indent: int) -> str:
    if not d:
        return "{}"
    pad = "\t" * (indent + 1)
    end_pad = "\t" * indent
    parts = []
    for k, v in d.items():
        parts.append(f'{pad}{_tres_quote(k)}: {_format_tres_value(v, indent + 1)}')
    return "{\n" + ",\n".join(parts) + f"\n{end_pad}}}"


def _format_tres_value(v: Any, indent: int) -> str:
    if v is None:
        return "null"
    if isinstance(v, bool):
        return "true" if v else "false"
    if isinstance(v, (int, float)):
        return repr(v)
    if isinstance(v, str):
        return _tres_quote(v)
    if isinstance(v, list):
        if not v:
            return "[]"
        pad = "\t" * (indent + 1)
        end_pad = "\t" * indent
        parts = [pad + _format_tres_value(x, indent + 1) for x in v]
        return "[\n" + ",\n".join(parts) + f"\n{end_pad}]"
    if isinstance(v, dict):
        return _format_tres_dict(v, indent)
    return _tres_quote(str(v))


def _tres_quote(s: str) -> str:
    s = s.replace("\\", "\\\\").replace('"', '\\"').replace("\n", "\\n")
    return f'"{s}"'


# ----------------------------------------------------------------------------
# Debug JSON
# ----------------------------------------------------------------------------

def write_json(out_path: Path, tables_data: dict[str, list[dict[str, Any]]]) -> None:
    out_path.parent.mkdir(parents=True, exist_ok=True)
    out_path.write_text(
        json.dumps(tables_data, ensure_ascii=False, indent=2, sort_keys=False),
        encoding="utf-8", newline="\n",
    )


# ----------------------------------------------------------------------------
# Manifest
# ----------------------------------------------------------------------------

def file_hash(path: Path) -> str:
    h = hashlib.sha256()
    with path.open("rb") as f:
        for chunk in iter(lambda: f.read(65536), b""):
            h.update(chunk)
    return h.hexdigest()[:16]


def write_manifest(
    out_path: Path,
    entries: list[dict[str, Any]],
    schema_version: int = 1,
) -> None:
    out_path.parent.mkdir(parents=True, exist_ok=True)
    manifest = {
        "schema_version": schema_version,
        "baked_at": int(time.time()),
        "tables": entries,
    }
    out_path.write_text(
        json.dumps(manifest, ensure_ascii=False, indent=2),
        encoding="utf-8", newline="\n",
    )


def read_manifest(path: Path) -> dict | None:
    if not path.exists():
        return None
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except Exception:
        return None
