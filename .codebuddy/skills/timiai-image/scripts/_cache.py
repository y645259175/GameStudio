# -*- coding: utf-8 -*-
"""TimiAI 生图缓存 · 通过 hash(prompt + model + size + quality + extra_params) 作为 key
保证同样的输入永远不会重复花 60-120s + tokens 调上游。

存储位置：skill 根目录下 .cache/<hash>.png + .cache/<hash>.json（meta）

API：
- cache_key(prompt, model, size, quality, extra) -> str (16 hex chars)
- cache_lookup(key) -> Path | None    存在则返回 png 路径
- cache_save(key, png_bytes_or_path, meta_dict) -> Path  存盘 + 写 meta json
- cache_path(key) -> Path             给定 key 返回 png 应在的位置（不保证存在）

约定：
- 任何 generator（text2image / image_edit / chat_image / batch_generate）出图后
  应主动调 cache_save 落缓存
- 任何 generator 调用前应先 cache_lookup，命中则直接复制到目标输出路径
- batch 任务跑到一半失败重启后，已生成的会通过 cache 命中跳过（断点续传）

清理：手动 rm -rf .cache/ 即可（或调 cache_clear()）
"""
from __future__ import annotations
import hashlib
import json
import shutil
from pathlib import Path
from typing import Optional, Union

SKILL_ROOT = Path(__file__).resolve().parent.parent
CACHE_DIR = SKILL_ROOT / ".cache"


def _ensure_cache_dir() -> Path:
    CACHE_DIR.mkdir(parents=True, exist_ok=True)
    return CACHE_DIR


def cache_key(prompt: str, model: str, size: str = "", quality: str = "",
              extra: Optional[dict] = None) -> str:
    """计算 16 字符 hash key。
    extra 用于 image_edit 的参考图 hash、chat_image 的 history 摘要等。
    """
    parts = [
        prompt or "",
        "|m=", model or "",
        "|s=", size or "",
        "|q=", quality or "",
    ]
    if extra:
        # 排序保证稳定性
        for k in sorted(extra.keys()):
            parts.append(f"|{k}={extra[k]}")
    s = "".join(parts)
    return hashlib.sha256(s.encode("utf-8")).hexdigest()[:16]


def cache_path(key: str) -> Path:
    """key 对应的 png 路径（可能不存在）。"""
    _ensure_cache_dir()
    return CACHE_DIR / f"{key}.png"


def cache_meta_path(key: str) -> Path:
    return CACHE_DIR / f"{key}.json"


def cache_lookup(key: str) -> Optional[Path]:
    """命中返回 png 路径；未命中返回 None。"""
    p = cache_path(key)
    if p.exists() and p.stat().st_size > 0:
        return p
    return None


def cache_save(key: str, src: Union[bytes, str, Path], meta: Optional[dict] = None) -> Path:
    """落盘 png + meta。src 可以是 bytes / 路径字符串 / Path。"""
    _ensure_cache_dir()
    dst = cache_path(key)
    if isinstance(src, (bytes, bytearray)):
        dst.write_bytes(src)
    else:
        src_path = Path(src)
        if not src_path.exists():
            raise FileNotFoundError(f"cache_save src not found: {src_path}")
        if src_path.resolve() != dst.resolve():
            shutil.copy2(src_path, dst)
    # meta
    meta_to_save = dict(meta or {})
    meta_to_save["key"] = key
    meta_to_save["size_bytes"] = dst.stat().st_size
    cache_meta_path(key).write_text(
        json.dumps(meta_to_save, ensure_ascii=False, indent=2),
        encoding="utf-8",
    )
    return dst


def cache_copy_to(key: str, target: Union[str, Path]) -> Optional[Path]:
    """命中 key 后把缓存 png 复制到 target；未命中返回 None。"""
    src = cache_lookup(key)
    if not src:
        return None
    target_p = Path(target)
    target_p.parent.mkdir(parents=True, exist_ok=True)
    shutil.copy2(src, target_p)
    return target_p


def cache_clear() -> int:
    """清空缓存。返回删除的文件数。"""
    if not CACHE_DIR.exists():
        return 0
    n = 0
    for f in CACHE_DIR.glob("*"):
        try:
            f.unlink()
            n += 1
        except Exception:
            pass
    return n


def cache_stat() -> dict:
    """返回缓存当前状态摘要。"""
    if not CACHE_DIR.exists():
        return {"count": 0, "total_bytes": 0, "dir": str(CACHE_DIR)}
    pngs = list(CACHE_DIR.glob("*.png"))
    total = sum(p.stat().st_size for p in pngs)
    return {
        "count": len(pngs),
        "total_bytes": total,
        "total_mb": round(total / 1024 / 1024, 2),
        "dir": str(CACHE_DIR),
    }


if __name__ == "__main__":
    # CLI: python _cache.py stat | clear
    import sys
    if len(sys.argv) >= 2 and sys.argv[1] == "clear":
        n = cache_clear()
        print(f"cleared {n} files")
    else:
        print(json.dumps(cache_stat(), ensure_ascii=False, indent=2))
