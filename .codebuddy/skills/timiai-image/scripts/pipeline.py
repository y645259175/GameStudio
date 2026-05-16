# -*- coding: utf-8 -*-
"""TimiAI 资产 pipeline · 把 batch_generate（生图）+ postprocess（后处理）拼成一站式流程。

为什么需要：
- bolt-1-1 / 一般像素游戏要的是 16×16 / 32×32 真像素 sprite atlas
- 模型只能给 1024×1024，且经常给"网格 sprite sheet"而不是真 strip
- 每张资产都要走"生图 → auto crop → atlas 切片 → 降采样 → 拼 strip"完整管线
- 不能把这套手动跑 N 次，必须脚本化

输入：一份 pipeline 配置 JSON：

```json
{
  "concurrency": 3,
  "stage_dir": "projects/bolt-1-1/art/_raw",   // 中间产物（原图）
  "tasks": [
    {
      "id": "bolty-small",
      "prompt": "Pixel art sprite ...",
      "model": "gpt-image-2",
      "size": "1024x1024",
      "quality": "medium",
      "post": [
        {"op": "remove_bg", "threshold": 200},
        {"op": "atlas", "grid": "4x2", "frame": "16x16"}
      ],
      "final_out": "projects/bolt-1-1/game/assets/bolty_small_strip.png"
    }
  ]
}
```

支持的 post ops:
  - remove_bg(threshold=200)      去 checkered 假透明背景
  - crop(alpha_threshold=8)        auto-crop 透明边
  - atlas(grid, frame, no_crop?)   N×M 网格切 + 降采样 + 拼 strip
  - shrink(size)                   单图降采样
  - quantize(colors)               palette 量化

执行流程（每个任务）：
  1. 用 _cache 查 raw 出图是否命中（hash = prompt + model + size + quality）
  2. 没命中 → batch_generate 调 API 生图到 stage_dir/<id>_raw.png（落缓存）
  3. 链式跑 post ops：每步输出到 stage_dir/<id>_<step>.png
  4. 最后一步的输出 copy 到 final_out
  5. 报告生成：每个任务的 status / cached / 中间产物路径 / 最终路径

用法：
  python pipeline.py --config pipeline-config.json [--concurrency 3] [--dry-run]
"""
from __future__ import annotations
import argparse
import json
import shutil
import sys
import time
from concurrent.futures import ThreadPoolExecutor, as_completed
from pathlib import Path
from threading import Lock
from typing import Any, Dict, List, Optional

try:
    sys.stdout.reconfigure(encoding="utf-8")
    sys.stderr.reconfigure(encoding="utf-8")
except Exception:
    pass

from _auth import (
    base_url as default_base_url, require_api_key_or_exit,
    parse_fallback_arg, ENDPOINT_EDITS,
)
from _cache import cache_key, cache_lookup, cache_save, cache_copy_to
import postprocess

# 复用 batch_generate 里的 _try_with_fallback
from batch_generate import _try_with_fallback


# ─── image_edit API 调用（reference-based 多帧动画用）─────────

def _call_image_edit(api_key: str, base: str, model: str, prompt: str,
                     reference_paths: list, size: str, quality: str,
                     timeout: int) -> bytes:
    """单次 image_edit 调用，传 1-4 张参考图 + prompt，返回 png bytes。
    适合多帧动画 / 多状态变体场景，让模型基于已有角色基准帧编辑而非重生。
    """
    import urllib.request, urllib.error
    import mimetypes
    url = base.rstrip("/") + ENDPOINT_EDITS

    if len(reference_paths) > 4 or len(reference_paths) < 1:
        raise RuntimeError(f"reference_paths must be 1-4, got {len(reference_paths)}")

    # multipart/form-data 手工组装（避免引入 requests 依赖）
    boundary = "----timiAIBoundary7MA4YWxkTrZu0gW"
    body_parts = []

    def add_field(name, value):
        body_parts.append(f"--{boundary}\r\n".encode("utf-8"))
        body_parts.append(f'Content-Disposition: form-data; name="{name}"\r\n\r\n'.encode("utf-8"))
        body_parts.append(str(value).encode("utf-8"))
        body_parts.append(b"\r\n")

    def add_file(name, filepath):
        from pathlib import Path as _P
        p = _P(filepath)
        if not p.exists():
            raise RuntimeError(f"reference image not found: {filepath}")
        mime = "image/png"
        suf = p.suffix.lower()
        if suf in (".jpg", ".jpeg"):
            mime = "image/jpeg"
        elif suf == ".webp":
            mime = "image/webp"
        body_parts.append(f"--{boundary}\r\n".encode("utf-8"))
        body_parts.append(
            f'Content-Disposition: form-data; name="{name}"; filename="{p.name}"\r\n'.encode("utf-8")
        )
        body_parts.append(f"Content-Type: {mime}\r\n\r\n".encode("utf-8"))
        body_parts.append(p.read_bytes())
        body_parts.append(b"\r\n")

    add_field("model", model)
    add_field("prompt", prompt)
    add_field("size", size)
    add_field("n", 1)
    if quality and quality != "auto":
        add_field("quality", quality)
    for ref in reference_paths:
        add_file("image[]", ref)

    body_parts.append(f"--{boundary}--\r\n".encode("utf-8"))
    body = b"".join(body_parts)

    req = urllib.request.Request(
        url,
        data=body,
        headers={
            "Authorization": api_key,
            "Content-Type": f"multipart/form-data; boundary={boundary}",
        },
        method="POST",
    )
    try:
        with urllib.request.urlopen(req, timeout=timeout) as resp:
            data = resp.read()
    except urllib.error.HTTPError as e:
        body_text = e.read().decode("utf-8", errors="replace")
        raise RuntimeError(f"HTTP {e.code}: {body_text[:300]}")
    except (urllib.error.URLError, TimeoutError) as e:
        raise RuntimeError(f"network: {e}")

    import base64
    try:
        payload = json.loads(data.decode("utf-8", errors="replace"))
    except Exception:
        raise RuntimeError(f"non-JSON response: {data[:200]!r}")

    if "error" in payload:
        raise RuntimeError(f"业务错误: {json.dumps(payload['error'], ensure_ascii=False)[:300]}")

    items = payload.get("data") or []
    if not items:
        raise RuntimeError(f"empty data: {json.dumps(payload, ensure_ascii=False)[:300]}")

    item = items[0]
    if "b64_json" in item:
        return base64.b64decode(item["b64_json"])
    if "url" in item:
        import urllib.request as _r
        with _r.urlopen(item["url"], timeout=timeout) as r2:
            return r2.read()
    raise RuntimeError(f"item missing b64/url: {item}")


_PRINT_LOCK = Lock()


def _log(task_id: str, msg: str):
    with _PRINT_LOCK:
        sys.stderr.write(f"[pipe:{task_id}] {msg}\n")
        sys.stderr.flush()


def _apply_post_op(src: Path, dst: Path, op: Dict[str, Any]) -> Path:
    """跑单个 post op。返回 dst（如果 op 改写了路径会返回新路径）。"""
    name = op.get("op")
    if name == "remove_bg":
        return postprocess.remove_checkered_bg(src, dst, threshold=op.get("threshold", 200))
    if name == "crop":
        return postprocess.auto_crop(src, dst, alpha_threshold=op.get("alpha_threshold", 8))
    if name == "atlas":
        return postprocess.atlas_to_strip(
            src, dst,
            grid=op.get("grid", "4x2"),
            frame_size=op.get("frame", "16x16"),
            crop_each=not op.get("no_crop", False),
            alpha_threshold=op.get("alpha_threshold", 8),
        )
    if name == "shrink":
        return postprocess.shrink(src, dst, size=op.get("size", "16x16"))
    if name == "quantize":
        return postprocess.quantize(src, dst, n_colors=op.get("colors", 16))
    raise ValueError(f"unknown post op: {name}")


def _run_task(api_key: str, base: str, task: Dict[str, Any],
              defaults: Dict[str, Any], stage_dir: Path,
              dry_run: bool = False) -> Dict[str, Any]:
    tid = task.get("id") or "anon"
    prompt = task.get("prompt") or ""
    task_type: str = task.get("type") or defaults.get("type") or "text2image"
    reference_images: list = task.get("reference_images") or []
    model = task.get("model") or defaults.get("model", "gpt-image-2")
    size = task.get("size") or defaults.get("size", "1024x1024")
    quality = task.get("quality") if "quality" in task else defaults.get("quality", "medium")
    fallback_arg = task.get("fallback") if "fallback" in task else defaults.get("fallback", "auto")
    timeout = int(task.get("timeout") or defaults.get("timeout", 180))
    max_retries = int(task.get("max_retries") or defaults.get("max_retries", 2))
    extra_params = task.get("params") or {}
    post_ops: List[Dict[str, Any]] = task.get("post") or []
    final_out = task.get("final_out")

    result = {
        "id": tid,
        "type": task_type,
        "status": "pending",
        "raw_cached": False,
        "model_used": None,
        "raw_path": None,
        "intermediate_paths": [],
        "final_path": final_out,
        "elapsed_s": 0.0,
        "error": None,
    }

    if not prompt:
        result["status"] = "FAIL"
        result["error"] = "empty prompt"
        return result
    if not final_out:
        result["status"] = "FAIL"
        result["error"] = "missing 'final_out' path"
        return result
    if task_type == "image_edit" and not reference_images:
        result["status"] = "FAIL"
        result["error"] = "image_edit type requires 'reference_images' (1-4 paths)"
        return result

    stage_dir.mkdir(parents=True, exist_ok=True)
    raw_path = stage_dir / f"{tid}_raw.png"

    # 1. 查 cache（image_edit 把参考图 hash 也算进 key）
    key_extra: Dict[str, Any] = {}
    if extra_params:
        key_extra["params"] = json.dumps(extra_params, sort_keys=True, ensure_ascii=False)
    if task_type == "image_edit":
        key_extra["type"] = "image_edit"
        # 参考图内容 hash（防止用户改了参考图但 prompt 没变 → cache 误命中）
        import hashlib
        ref_hashes = []
        for rp in reference_images:
            rpp = Path(rp)
            if rpp.exists():
                ref_hashes.append(hashlib.sha256(rpp.read_bytes()).hexdigest()[:16])
        key_extra["refs"] = ",".join(ref_hashes)
    ckey = cache_key(prompt, model, size, quality or "", key_extra if key_extra else None)
    cached = cache_lookup(ckey)

    t0 = time.time()
    try:
        if cached:
            if dry_run:
                result["status"] = "SKIP_DRY"
                result["raw_cached"] = True
                return result
            cache_copy_to(ckey, raw_path)
            result["raw_cached"] = True
            result["model_used"] = "cache"
            _log(tid, f"💾 raw cache hit → {raw_path}")
        else:
            if dry_run:
                result["status"] = "SKIP_DRY"
                return result

            # 路由到不同 API
            if task_type == "image_edit":
                _log(tid, f"调 image_edit, model={model}, refs={len(reference_images)}")
                # image_edit 没有 fallback（gemini 不支持本端点）
                last_err = ""
                data: Optional[bytes] = None
                model_used = model
                for attempt in range(max_retries + 1):
                    try:
                        data = _call_image_edit(
                            api_key, base, model, prompt, reference_images,
                            size, quality, timeout,
                        )
                        _log(tid, f"  ✅ image_edit 成功 (attempt {attempt+1})")
                        break
                    except Exception as e:
                        last_err = str(e)
                        _log(tid, f"  ❌ attempt {attempt+1}: {last_err[:150]}")
                        if attempt < max_retries:
                            time.sleep(2 ** attempt)
                if data is None:
                    raise RuntimeError(f"image_edit failed after {max_retries+1} attempts: {last_err}")
            else:
                # 默认 text2image 走 _try_with_fallback
                fallback_chain = parse_fallback_arg(fallback_arg, model) if fallback_arg else []
                data, model_used = _try_with_fallback(
                    api_key, base, model, fallback_chain, prompt, size, quality,
                    extra_params, timeout, max_retries, tid,
                )

            cache_save(ckey, data, meta={
                "prompt": prompt[:200],
                "model_requested": model,
                "model_used": model_used,
                "size": size,
                "quality": quality,
                "type": task_type,
                "reference_images": reference_images,
            })
            raw_path.write_bytes(data)
            result["model_used"] = model_used
            _log(tid, f"✅ raw saved → {raw_path} ({len(data)//1024} KB)")

        result["raw_path"] = str(raw_path)

        # 2. 链式跑 post ops
        cur = raw_path
        for i, op in enumerate(post_ops):
            step_name = op.get("op", "step")
            step_out = stage_dir / f"{tid}_{i+1}_{step_name}.png"
            _log(tid, f"  post[{i+1}/{len(post_ops)}] {step_name} → {step_out.name}")
            cur = _apply_post_op(cur, step_out, op)
            result["intermediate_paths"].append(str(cur))

        # 3. 复制最后产物到 final_out
        final_p = Path(final_out)
        final_p.parent.mkdir(parents=True, exist_ok=True)
        if cur.resolve() != final_p.resolve():
            shutil.copy2(cur, final_p)
        result["status"] = "OK"
        _log(tid, f"📦 final → {final_out}")

    except Exception as e:
        result["status"] = "FAIL"
        result["error"] = str(e)[:300]
        _log(tid, f"❌ {e}")

    result["elapsed_s"] = round(time.time() - t0, 1)
    return result


def main():
    parser = argparse.ArgumentParser(description="TimiAI 资产 pipeline (gen + postprocess)")
    parser.add_argument("--config", required=True, help="pipeline 配置 JSON")
    parser.add_argument("--concurrency", type=int, default=None)
    parser.add_argument("--dry-run", action="store_true", help="只检查 cache 命中情况")
    parser.add_argument("--report", default=None)
    args = parser.parse_args()

    cfg_path = Path(args.config)
    if not cfg_path.exists():
        sys.stderr.write(f"[pipe] config not found: {cfg_path}\n")
        sys.exit(1)

    cfg = json.loads(cfg_path.read_text(encoding="utf-8"))
    tasks = cfg.get("tasks") or []
    defaults = cfg.get("defaults") or {}
    concurrency = args.concurrency or cfg.get("concurrency") or 3
    stage_dir = Path(cfg.get("stage_dir") or "_pipeline_stage")

    if not tasks:
        sys.stderr.write("[pipe] no tasks\n")
        sys.exit(1)

    api_key = require_api_key_or_exit()
    base = default_base_url()

    sys.stderr.write(f"[pipe] {len(tasks)} tasks, concurrency={concurrency}, stage_dir={stage_dir}\n")

    t0 = time.time()
    results: List[Dict[str, Any]] = []
    with ThreadPoolExecutor(max_workers=concurrency) as ex:
        futs = [ex.submit(_run_task, api_key, base, t, defaults, stage_dir, args.dry_run) for t in tasks]
        for fut in as_completed(futs):
            results.append(fut.result())

    by_id = {r["id"]: r for r in results}
    ordered = [by_id.get(t.get("id"), {"id": t.get("id"), "status": "MISSING"}) for t in tasks]

    elapsed = round(time.time() - t0, 1)
    summary = {
        "total": len(tasks),
        "ok": sum(1 for r in ordered if r.get("status") == "OK"),
        "raw_cached": sum(1 for r in ordered if r.get("raw_cached")),
        "fail": sum(1 for r in ordered if r.get("status") == "FAIL"),
        "skipped_dry": sum(1 for r in ordered if r.get("status") == "SKIP_DRY"),
        "elapsed_s": elapsed,
    }

    output = {"summary": summary, "results": ordered}
    out_json = json.dumps(output, ensure_ascii=False, indent=2)
    if args.report:
        Path(args.report).parent.mkdir(parents=True, exist_ok=True)
        Path(args.report).write_text(out_json, encoding="utf-8")
        sys.stderr.write(f"[pipe] report → {args.report}\n")
    print(out_json)

    sys.stderr.write(f"[pipe] done. ok={summary['ok']}/{summary['total']} cached={summary['raw_cached']} fail={summary['fail']} elapsed={elapsed}s\n")
    sys.exit(0 if summary["fail"] == 0 else 2)


if __name__ == "__main__":
    main()
