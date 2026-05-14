# -*- coding: utf-8 -*-
"""TimiAI 文生图。

端点由 models.json 的 endpoint 字段自动路由：
  llmproxy → /ai_api_manage/llmproxy/images/generations
  hunyuan  → /ai_api_manage/hunyuan/images/generations

输出：
  stderr  [timiai] 进度日志
  stdout  JSON {"success":..., "model":..., "mode":..., "variants":[...], "files":[相对路径], ...}

抽卡模式（--draw N）：
  随机抽卡（默认）：配合 --variants-file prompts.json 使用，每次 draw 用不同 prompt 变体。
                    AI 在调用前先生成 N 个变体写入 JSON，体现最大多样性。
  定向抽卡：        只传 --prompt / --prompt-file，不传 --variants-file，N 次用同一 prompt。

额外参数：--param key=value 透传任意字段（可多次，数字/bool 自动解析）

示例：
  # 定向抽卡（固定 prompt）
  python text2image.py --prompt "pixel art cat" --draw 3

  # 随机抽卡（每次 draw 用不同变体）
  python text2image.py --variants-file ./variants.json --draw 3
  # variants.json 格式：["prompt1", "prompt2", "prompt3"]

  # 混元国风
  python text2image.py --prompt "古风仙境" --model hunyuan-image-v3.0-v1.0.4
"""

import argparse
import base64
import json
import sys
import time
from pathlib import Path

import requests

from _auth import (base_url as default_base_url, require_api_key_or_exit,
                   validate_model, resolve_gen_endpoint, to_relative,
                   parse_fallback_arg, is_retryable_error)

try:
    sys.stdout.reconfigure(encoding="utf-8")
    sys.stderr.reconfigure(encoding="utf-8")
except Exception:
    pass


def log(msg):
    sys.stderr.write(f"[timiai] {msg}\n")
    sys.stderr.flush()


def parse_args():
    p = argparse.ArgumentParser(description="TimiAI 文生图（支持随机/定向抽卡）")
    g = p.add_mutually_exclusive_group(required=True)
    g.add_argument("--prompt", help="文本提示词（定向抽卡，单行）")
    g.add_argument("--prompt-file", help="从文件读取提示词（定向抽卡，多行/长 prompt）")
    g.add_argument("--variants-file",
                   help='随机抽卡：JSON 文件，格式 ["prompt1","prompt2",...]，'
                        '每次 draw 按序取不同变体（超出则循环）')
    p.add_argument("--model", default=None,
                   help="模型名（默认读 models.json 的 default 字段）")
    p.add_argument("--n", type=int, default=1)
    p.add_argument("--size", default=None,
                   help="gpt-image-* 尺寸（宽高须 16 整除）")
    p.add_argument("--quality", default=None, choices=["low", "medium", "high", "auto"])
    p.add_argument("--param", action="append", default=[], metavar="KEY=VALUE",
                   help="透传任意额外参数（可多次，数字/bool 自动解析）")
    p.add_argument("--draw", type=int, default=1,
                   help="抽卡次数（默认 1；建议 ≤ 10）")
    p.add_argument("--draw-sleep", type=float, default=0.0)
    p.add_argument("--fallback", default="auto",
                   help='主模型限流/上游异常时的备用模型链：'
                        '"auto"(默认,读 models.json 配置) | "off"(禁用) | '
                        '"modelA,modelB"(显式覆盖)')
    p.add_argument("--out", default="./timiai_t2i_{ts}_d{draw}_{i}.png",
                   help="输出文件模板，支持 {ts} {i} {draw}")
    p.add_argument("--timeout", type=int, default=300)
    p.add_argument("--base-url", default=default_base_url())
    return p.parse_args()


def parse_extra_params(param_list):
    result = {}
    for kv in param_list:
        eq = kv.find("=")
        if eq <= 0:
            continue
        k, v = kv[:eq], kv[eq + 1:]
        if v == "true":       v = True
        elif v == "false":    v = False
        elif v.isdigit():     v = int(v)
        else:
            try:              v = float(v)
            except ValueError: pass
        result[k] = v
    return result


def warn_size(size):
    if not size or size == "auto":
        return
    try:
        w, h = [int(x) for x in size.lower().split("x")]
        if w % 16 != 0 or h % 16 != 0:
            log(f"警告: size={size} 宽或高不是 16 的倍数，Azure 可能拒绝；"
                f"建议改为 {((w+15)//16)*16}x{((h+15)//16)*16}")
    except Exception:
        pass


def build_body(model, prompt_text, n, size, quality, extra):
    body = {"model": model, "prompt": prompt_text, "n": n}
    if model.startswith("gemini"):
        body["aspect_ratio"] = extra.pop("aspect_ratio", "1:1")
        body["imageSize"]    = extra.pop("imageSize", "1K")
    elif not model.startswith("hunyuan"):
        body["size"] = size or "1024x1024"
        if quality:
            body["quality"] = quality
    body.update(extra)
    return body


def download_url(url: str, timeout: int) -> bytes | None:
    """尝试 GET 下载远程 URL 的图片字节；失败返回 None。"""
    try:
        r = requests.get(url, timeout=timeout)
        if r.status_code == 200:
            return r.content
    except Exception:
        pass
    return None


def save_result(data, prompt_text, out_pattern, draw_idx, timeout):
    """保存结果。返回 (saved_paths, error_text)。
    成功时 error_text=""；业务错误/空响应时 saved=[] 且 error_text 非空。
    """
    if not isinstance(data, dict) or "error" in data:
        err = json.dumps(data, ensure_ascii=False)[:800]
        log(f"业务错误: {err}")
        return [], err
    items = data.get("data") or []
    if not items:
        err = json.dumps(data, ensure_ascii=False)[:800]
        log(f"空响应: {err}")
        return [], err
    ts = time.strftime("%Y%m%d_%H%M%S")
    saved = []
    for i, item in enumerate(items, 1):
        b64 = item.get("b64_json")
        url = item.get("url")
        path = Path(out_pattern.format(ts=ts, i=i, draw=draw_idx))
        path.parent.mkdir(parents=True, exist_ok=True)
        if b64:
            path.write_bytes(base64.b64decode(b64))
            rel = to_relative(str(path.resolve()))
            log(f"✅ 已保存: {rel}  ({path.stat().st_size // 1024} KB)")
            saved.append(rel)
        elif url:
            log(f"图片 URL，尝试下载: {url}")
            raw = download_url(url, timeout)
            if raw:
                path.write_bytes(raw)
                rel = to_relative(str(path.resolve()))
                log(f"✅ 已保存（URL下载）: {rel}  ({len(raw) // 1024} KB)")
                saved.append(rel)
            else:
                log(f"🔗 下载失败，返回 URL: {url}")
                saved.append(url)
    return saved, ""


def do_one_call(url, headers, body, timeout, out_pattern, draw_idx, prompt_text):
    """单次 HTTP 调用。返回 (saved_paths, error_text)。"""
    t0 = time.time()
    try:
        resp = requests.post(url, headers=headers, json=body, timeout=timeout)
    except requests.RequestException as e:
        err = f"网络错误: {e}"
        log(err)
        return [], err
    dt = time.time() - t0
    log(f"HTTP {resp.status_code} 耗时 {dt:.1f}s")
    if resp.status_code != 200:
        err = f"HTTP {resp.status_code}: {resp.text[:500]}"
        log(f"响应错误: {resp.text[:1000]}")
        if "divisible by 16" in resp.text.lower():
            log("提示: size 的宽高必须都是 16 的倍数")
        return [], err
    try:
        result = resp.json()
    except Exception:
        err = f"非 JSON: {resp.text[:400]}"
        log(err)
        return [], err
    return save_result(result, prompt_text, out_pattern, draw_idx, timeout)


def call_with_fallback(primary_model, fallback_chain, prompt_text,
                        args, extra, api_key, draw_idx):
    """主模型 + fallback 链：依次尝试，返回 (saved, used_model, attempts)。
    attempts: 列表，每元素 {"model":..., "error":..., "ok": bool}
    """
    candidates = [primary_model] + (fallback_chain or [])
    attempts = []
    headers = {"Content-Type": "application/json", "Authorization": api_key}

    for idx, model in enumerate(candidates):
        if idx > 0:
            log(f"⤵ 尝试 fallback 模型 [{idx}/{len(candidates)-1}]: {model}")
        endpoint = resolve_gen_endpoint(model, args.base_url)
        # extra 每次重新 copy（build_body 会 pop gemini 字段）
        body = build_body(model, prompt_text, args.n, args.size, args.quality, dict(extra))
        saved, err = do_one_call(endpoint, headers, body,
                                  args.timeout, args.out, draw_idx, prompt_text)
        if saved:
            attempts.append({"model": model, "ok": True, "error": ""})
            return saved, model, attempts

        attempts.append({"model": model, "ok": False, "error": err[:300]})
        # 最后一个候选了就不用再判断
        if idx == len(candidates) - 1:
            break
        # 错误是否值得继续 fallback
        if not is_retryable_error(err):
            log(f"✋ 错误不可重试，停止 fallback: {err[:200]}")
            break

    return [], candidates[0], attempts


def main():
    args = parse_args()
    api_key = require_api_key_or_exit()
    extra   = parse_extra_params(args.param)

    # ── Prompt / Variants 解析 ──────────────────────────────
    if args.variants_file:
        # 随机抽卡：从 JSON 文件读取 prompt 变体数组
        vf = Path(args.variants_file)
        if not vf.exists():
            log(f"错误: variants-file 不存在: {args.variants_file}")
            sys.exit(2)
        try:
            variants = json.loads(vf.read_text(encoding="utf-8"))
            if not isinstance(variants, list) or not variants:
                raise ValueError("须为非空数组")
        except Exception as e:
            log(f"错误: variants-file JSON 解析失败: {e}")
            sys.exit(2)
        draw_mode = "random"
        log(f"随机抽卡模式：共 {len(variants)} 个 prompt 变体，draw={max(1,args.draw)}")
    elif args.prompt:
        variants  = [args.prompt]
        draw_mode = "fixed"
    else:
        pf = Path(args.prompt_file)
        if not pf.exists():
            log(f"错误: prompt 文件不存在: {args.prompt_file}")
            sys.exit(2)
        variants  = [pf.read_text(encoding="utf-8").strip()]
        draw_mode = "fixed"

    # ── 模型 ────────────────────────────────────────────────
    from _auth import load_models
    cfg_models = load_models()
    model = args.model or (cfg_models.get("default") or "gpt-image-2")
    validate_model(model)

    if not model.startswith("gemini") and not model.startswith("hunyuan"):
        warn_size(args.size)

    draw_n  = max(1, args.draw)
    if draw_n > 10:
        log(f"警告: --draw={draw_n} 超过建议上限 10")

    # ── Fallback 链 ─────────────────────────────────────────
    fallback_chain = parse_fallback_arg(args.fallback, model)
    if fallback_chain:
        log(f"fallback 链: {' → '.join(fallback_chain)}")
    else:
        log(f"fallback: 已禁用")

    endpoint = resolve_gen_endpoint(model, args.base_url)
    headers  = {"Content-Type": "application/json", "Authorization": api_key}

    log(f"model={model}  draw={draw_n}  mode={draw_mode}  endpoint={endpoint}")
    if args.param:
        log(f"extra params: {extra}")
    log("正在生成图片，请稍候...")

    all_saved      = []
    used_prompts   = []   # 记录每次实际使用的 prompt
    fallback_log   = []   # 记录每次 draw 的 fallback 情况
    failed         = 0
    run_t0         = time.time()

    for k in range(1, draw_n + 1):
        # 随机抽卡：按序取变体（超出则循环），定向抽卡：始终取 variants[0]
        prompt_text = variants[(k - 1) % len(variants)]
        used_prompts.append(prompt_text[:200])

        log(f"===== draw {k}/{draw_n}  prompt=[{prompt_text[:80]}...] =====" if len(prompt_text) > 80
            else f"===== draw {k}/{draw_n}  prompt=[{prompt_text}] =====")

        saved, used_model, attempts = call_with_fallback(
            model, fallback_chain, prompt_text, args, extra, api_key, k
        )

        # 记录 fallback 信息（只有真的发生了 fallback 才记录）
        if len(attempts) > 1 or (attempts and not attempts[0]["ok"]):
            fallback_log.append({
                "draw":     k,
                "primary":  model,
                "actual":   used_model if saved else None,
                "attempts": attempts,
            })
            if saved and used_model != model:
                log(f"♻ draw {k} 通过 fallback [{used_model}] 救活")

        if saved:
            all_saved.extend(saved)
        else:
            failed += 1
        if k < draw_n and args.draw_sleep > 0:
            time.sleep(args.draw_sleep)

    total_dt = time.time() - run_t0
    log(f"完成: 成功 {len(all_saved)} 张 / 失败 {failed} 次 / 总耗时 {total_dt:.1f}s")
    if fallback_log:
        rescued = sum(1 for f in fallback_log if f["actual"] and f["actual"] != model)
        log(f"fallback 统计: {rescued}/{len(fallback_log)} 次降级救活")

    out_json = {
        "success":      len(all_saved) > 0,
        "model":        model,
        "mode":         draw_mode,          # "random" | "fixed"
        "variants":     used_prompts,       # 实际每次用的 prompt（定向时全相同）
        "draw":         draw_n,
        "files":        all_saved,
        "count":        len(all_saved),
        "failed":       failed,
        "fallbacks":    fallback_log,       # 每次 draw 的 fallback 详情（无 fallback 时为空数组）
        "elapsed_s":    round(total_dt, 1),
    }
    sys.stdout.write(json.dumps(out_json, ensure_ascii=False, indent=2) + "\n")
    sys.stdout.flush()
    if not all_saved:
        sys.exit(1)


if __name__ == "__main__":
    main()
