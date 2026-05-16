# -*- coding: utf-8 -*-
"""TimiAI 批量生图 · 一份 JSON/YAML 任务清单一次跑完，自动并发 + 缓存命中跳过 + 失败重试。

为什么需要：
- bolt-1-1 一波要生 8 类资产（每类 1-3 张）；串行调用 60-120s/张 = 总时长 8-30 分钟，
  期间 agent 完全空转
- gpt-image-2 限流随机 429，单点失败常见
- 同样的 prompt 不该重复花 token

设计：
- 输入 JSON 清单（每条任务 = 一组 prompt + 模型 + 尺寸 + 输出路径）
- 用 ThreadPoolExecutor 并发（默认 3，模型限流容忍）
- 每个任务先查 _cache.cache_lookup，命中直接复制，跳过 API 调用
- 调 API 用 _auth.get_fallback_chain 自动降级（gpt-image-2 → gemini → gpt-image-1）
- 失败用 exponential backoff 重试 N 次
- 最终输出 batch report JSON：每条任务的 status / cached / model_used / elapsed / output_path

任务清单格式（JSON）：
```json
{
  "concurrency": 3,
  "tasks": [
    {
      "id": "bolty-small-frames",
      "prompt": "Pixel art ...",
      "model": "gpt-image-2",
      "size": "1024x1024",
      "quality": "medium",
      "out": "projects/bolt-1-1/art/bolty-small-raw.png",
      "fallback": "auto"
    },
    {
      "id": "mossroll-frames",
      "prompt": "...",
      "out": "projects/bolt-1-1/art/mossroll-raw.png"
    }
  ]
}
```

字段默认值（缺省时用全局 default 节）：
  model="gpt-image-2", size="1024x1024", quality="medium", fallback="auto",
  timeout=180, max_retries=2

用法：
  python batch_generate.py --tasks tasks.json [--concurrency 3] [--dry-run]
"""
from __future__ import annotations
import argparse
import base64
import json
import sys
import time
import urllib.request
import urllib.error
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
    get_fallback_chain, is_retryable_error, parse_fallback_arg,
    resolve_gen_endpoint,
)
from _cache import cache_key, cache_lookup, cache_save, cache_copy_to


# ─── 单任务执行 ────────────────────────────────────────────────

_PRINT_LOCK = Lock()


def _log(task_id: str, msg: str):
    with _PRINT_LOCK:
        sys.stderr.write(f"[batch:{task_id}] {msg}\n")
        sys.stderr.flush()


def _call_api(api_key: str, base: str, model: str, prompt: str,
              size: str, quality: Optional[str], extra_params: Dict[str, Any],
              timeout: int) -> bytes:
    """单次 API 调用，返回 png bytes。失败抛 RuntimeError。"""
    url = resolve_gen_endpoint(model, base)
    body: Dict[str, Any] = {
        "model": model,
        "prompt": prompt,
        "size": size,
        "n": 1,
    }
    if quality:
        body["quality"] = quality
    if extra_params:
        body.update(extra_params)

    req = urllib.request.Request(
        url,
        data=json.dumps(body).encode("utf-8"),
        headers={
            "Authorization": api_key,
            "Content-Type": "application/json",
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

    try:
        payload = json.loads(data.decode("utf-8", errors="replace"))
    except Exception as e:
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
        with urllib.request.urlopen(item["url"], timeout=timeout) as r2:
            return r2.read()
    raise RuntimeError(f"item missing b64/url: {item}")


def _try_with_fallback(api_key: str, base: str, primary_model: str,
                       fallback_chain: List[str], prompt: str,
                       size: str, quality: Optional[str],
                       extra_params: Dict[str, Any],
                       timeout: int, max_retries: int,
                       task_id: str) -> tuple[bytes, str]:
    """按 [primary] + fallback_chain 顺序尝试，每个模型最多 max_retries 次。
    返回 (png_bytes, model_used)。
    """
    candidates = [primary_model] + [m for m in fallback_chain if m != primary_model]
    last_err = ""
    for model in candidates:
        for attempt in range(max_retries + 1):
            try:
                _log(task_id, f"调 {model} (attempt {attempt + 1}/{max_retries + 1})")
                t0 = time.time()
                data = _call_api(api_key, base, model, prompt, size, quality, extra_params, timeout)
                _log(task_id, f"  ✅ {model} 成功，耗时 {time.time() - t0:.1f}s")
                return data, model
            except Exception as e:
                last_err = str(e)
                _log(task_id, f"  ❌ {model}: {last_err[:150]}")
                if not is_retryable_error(last_err):
                    _log(task_id, f"  （非可重试错误，跳过 fallback）")
                    raise RuntimeError(last_err) from e
                # 退避
                if attempt < max_retries:
                    backoff = 2 ** attempt
                    time.sleep(backoff)
        _log(task_id, f"  → 切到下一 fallback")
    raise RuntimeError(f"all models failed; last: {last_err}")


def _run_task(api_key: str, base: str, task: Dict[str, Any], defaults: Dict[str, Any],
              dry_run: bool = False) -> Dict[str, Any]:
    """跑单个任务。返回结果 dict（含 status/cached/model_used/output_path/elapsed/error）。"""
    tid = task.get("id") or "anon"
    prompt = task.get("prompt") or ""
    model = task.get("model") or defaults.get("model", "gpt-image-2")
    size = task.get("size") or defaults.get("size", "1024x1024")
    quality = task.get("quality") if "quality" in task else defaults.get("quality", "medium")
    out = task.get("out")
    fallback_arg = task.get("fallback") if "fallback" in task else defaults.get("fallback", "auto")
    timeout = int(task.get("timeout") or defaults.get("timeout", 180))
    max_retries = int(task.get("max_retries") or defaults.get("max_retries", 2))
    extra_params = task.get("params") or {}

    result = {
        "id": tid,
        "status": "pending",
        "cached": False,
        "model_used": None,
        "output_path": out,
        "elapsed_s": 0.0,
        "error": None,
    }

    if not prompt:
        result["status"] = "FAIL"
        result["error"] = "empty prompt"
        return result
    if not out:
        result["status"] = "FAIL"
        result["error"] = "missing 'out' path"
        return result

    # 缓存命中？
    key_extra = {"params": json.dumps(extra_params, sort_keys=True, ensure_ascii=False)} if extra_params else None
    ckey = cache_key(prompt, model, size, quality or "", key_extra)
    cached = cache_lookup(ckey)
    if cached:
        if dry_run:
            result["status"] = "SKIP_DRY"
            result["cached"] = True
            return result
        cache_copy_to(ckey, out)
        result["status"] = "OK"
        result["cached"] = True
        result["model_used"] = "cache"
        _log(tid, f"💾 cache hit ({ckey}) → {out}")
        return result

    if dry_run:
        result["status"] = "SKIP_DRY"
        return result

    # 真正调 API
    fallback_chain = parse_fallback_arg(fallback_arg, model) if fallback_arg else []
    t0 = time.time()
    try:
        data, model_used = _try_with_fallback(
            api_key, base, model, fallback_chain, prompt, size, quality,
            extra_params, timeout, max_retries, tid,
        )
        # 落缓存 + 复制到目标
        cache_save(ckey, data, meta={
            "prompt": prompt[:200],
            "model_requested": model,
            "model_used": model_used,
            "size": size,
            "quality": quality,
        })
        out_p = Path(out)
        out_p.parent.mkdir(parents=True, exist_ok=True)
        out_p.write_bytes(data)
        result["status"] = "OK"
        result["model_used"] = model_used
        result["elapsed_s"] = round(time.time() - t0, 1)
        _log(tid, f"✅ saved → {out} ({len(data)//1024} KB, {result['elapsed_s']}s)")
    except Exception as e:
        result["status"] = "FAIL"
        result["error"] = str(e)[:300]
        result["elapsed_s"] = round(time.time() - t0, 1)
    return result


# ─── 主入口 ────────────────────────────────────────────────────

def main():
    parser = argparse.ArgumentParser(description="TimiAI 批量生图（并发 + 缓存）")
    parser.add_argument("--tasks", required=True, help="任务清单 JSON")
    parser.add_argument("--concurrency", type=int, default=None, help="覆盖任务清单中的 concurrency")
    parser.add_argument("--dry-run", action="store_true", help="只查缓存命中情况，不调 API")
    parser.add_argument("--report", default=None, help="结果报告输出 JSON 路径（默认 stdout）")
    args = parser.parse_args()

    tasks_path = Path(args.tasks)
    if not tasks_path.exists():
        sys.stderr.write(f"[batch] tasks file not found: {tasks_path}\n")
        sys.exit(1)

    cfg = json.loads(tasks_path.read_text(encoding="utf-8"))
    tasks = cfg.get("tasks") or []
    defaults = cfg.get("defaults") or {}
    concurrency = args.concurrency or cfg.get("concurrency") or 3

    if not tasks:
        sys.stderr.write("[batch] no tasks\n")
        sys.exit(1)

    api_key = require_api_key_or_exit()
    base = default_base_url()

    sys.stderr.write(f"[batch] {len(tasks)} tasks, concurrency={concurrency}, dry_run={args.dry_run}\n")
    sys.stderr.write(f"[batch] base={base}\n")

    t0 = time.time()
    results: List[Dict[str, Any]] = []
    with ThreadPoolExecutor(max_workers=concurrency) as ex:
        futs = [ex.submit(_run_task, api_key, base, t, defaults, args.dry_run) for t in tasks]
        for fut in as_completed(futs):
            results.append(fut.result())

    # 排序保证输出和输入顺序一致
    by_id = {r["id"]: r for r in results}
    ordered = [by_id.get(t.get("id"), {"id": t.get("id"), "status": "MISSING"}) for t in tasks]

    elapsed = round(time.time() - t0, 1)
    summary = {
        "total": len(tasks),
        "ok": sum(1 for r in ordered if r.get("status") == "OK"),
        "cached": sum(1 for r in ordered if r.get("cached")),
        "fail": sum(1 for r in ordered if r.get("status") == "FAIL"),
        "skipped_dry": sum(1 for r in ordered if r.get("status") == "SKIP_DRY"),
        "elapsed_s": elapsed,
    }

    output = {"summary": summary, "results": ordered}
    out_json = json.dumps(output, ensure_ascii=False, indent=2)
    if args.report:
        Path(args.report).parent.mkdir(parents=True, exist_ok=True)
        Path(args.report).write_text(out_json, encoding="utf-8")
        sys.stderr.write(f"[batch] report → {args.report}\n")
    print(out_json)

    sys.stderr.write(f"[batch] done. ok={summary['ok']} cached={summary['cached']} fail={summary['fail']} elapsed={elapsed}s\n")
    sys.exit(0 if summary["fail"] == 0 else 2)


if __name__ == "__main__":
    main()
