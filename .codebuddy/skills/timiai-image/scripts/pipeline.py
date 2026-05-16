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
    parse_fallback_arg,
)
from _cache import cache_key, cache_lookup, cache_save, cache_copy_to
import postprocess

# 复用 batch_generate 里的 _try_with_fallback
from batch_generate import _try_with_fallback


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

    stage_dir.mkdir(parents=True, exist_ok=True)
    raw_path = stage_dir / f"{tid}_raw.png"

    # 1. 查 cache（基于 prompt + model + size + quality + extra）
    key_extra = {"params": json.dumps(extra_params, sort_keys=True, ensure_ascii=False)} if extra_params else None
    ckey = cache_key(prompt, model, size, quality or "", key_extra)
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
