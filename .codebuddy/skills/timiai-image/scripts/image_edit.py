# -*- coding: utf-8 -*-
"""TimiAI 图像编辑（兼容 OpenAI /images/edits）。

POST /ai_api_manage/llmproxy/images/edits  (multipart)
Authorization: <key>  (裸 key，不加 Bearer)

支持：model + prompt + image[]（最多 4 张）+ size + quality + n + --param 透传
stdout: JSON  stderr: [timiai] 日志  files 字段输出相对路径

示例：
  python image_edit.py --prompt-file ./p.txt --image a.png --image b.png \
      --size 2048x2048 --quality high --draw 3
"""

import argparse
import base64
import json
import sys
import time
from pathlib import Path

import requests

from _auth import (base_url as default_base_url, require_api_key_or_exit,
                   validate_model, to_relative, ENDPOINT_EDITS,
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
    p = argparse.ArgumentParser(description="TimiAI 图像编辑（多图/quality/精确像素/随机&定向抽卡）")
    g = p.add_mutually_exclusive_group(required=True)
    g.add_argument("--prompt", help="编辑指令（定向抽卡，单行）")
    g.add_argument("--prompt-file", help="从文件读取编辑指令（定向抽卡）")
    g.add_argument("--variants-file",
                   help='随机抽卡：JSON 文件，格式 ["prompt1","prompt2",...]')
    p.add_argument("--image", required=True, action="append",
                   help="参考图路径，可重复最多 4 次")
    p.add_argument("--model", default="gpt-image-2",
                   help="模型名（本端点仅支持 gpt-image-* 系）")
    p.add_argument("--size", default="auto",
                   help='输出尺寸或 "auto"；宽高须 16 整除')
    p.add_argument("--quality", default="high",
                   choices=["low", "medium", "high", "auto"])
    p.add_argument("--n", type=int, default=1)
    p.add_argument("--param", action="append", default=[], metavar="KEY=VALUE")
    p.add_argument("--draw", type=int, default=1)
    p.add_argument("--draw-sleep", type=float, default=0.0)
    p.add_argument("--fallback", default="auto",
                   help='主模型限流/上游异常时的备用模型链：'
                        '"auto"(默认,读 models.json) | "off"(禁用) | "modelA,modelB"(显式覆盖)。'
                        '注意：image_edit 仅 gpt-image-* 系兼容，gemini 系不支持本端点')
    p.add_argument("--out", default="./timiai_edit_{ts}_d{draw}_{i}.png",
                   help="支持 {ts} {i} {draw}")
    p.add_argument("--timeout", type=int, default=600)
    p.add_argument("--base-url", default=default_base_url())
    p.add_argument("--field-name", default="image[]", choices=["image[]", "image"])
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
    if size == "auto":
        return
    try:
        w, h = [int(x) for x in size.lower().split("x")]
        if w % 16 != 0 or h % 16 != 0:
            log(f"警告: size={size} 宽或高不是 16 的倍数，Azure 会拒绝；"
                f"建议改为 {((w+15)//16)*16}x{((h+15)//16)*16}")
    except Exception:
        pass


def build_files(paths, field_name):
    if len(paths) > 4:
        log(f"错误: 参考图最多 4 张，当前 {len(paths)} 张")
        sys.exit(2)
    files = []
    for p in paths:
        path = Path(p)
        if not path.exists():
            log(f"错误: 参考图不存在：{p}")
            sys.exit(2)
        mime = "image/png"
        suf  = path.suffix.lower()
        if suf in (".jpg", ".jpeg"):  mime = "image/jpeg"
        elif suf == ".webp":          mime = "image/webp"
        files.append((field_name, (path.name, path.read_bytes(), mime)))
    return files


def download_url(url: str, timeout: int):
    try:
        r = requests.get(url, timeout=timeout)
        if r.status_code == 200:
            return r.content
    except Exception:
        pass
    return None


def save_result(data, out_pattern, draw, timeout):
    """保存结果。返回 (saved_paths, error_text)。"""
    if not isinstance(data, dict) or "error" in data:
        err = json.dumps(data, ensure_ascii=False)[:800]
        log(f"业务错误: {err}")
        return [], err
    items = data.get("data") or []
    if not items:
        err = json.dumps(data, ensure_ascii=False)[:800]
        log(f"空响应: {err}")
        return [], err
    ts    = time.strftime("%Y%m%d_%H%M%S")
    saved = []
    for i, item in enumerate(items, 1):
        b64 = item.get("b64_json")
        url = item.get("url")
        path = Path(out_pattern.format(ts=ts, i=i, draw=draw))
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


def do_one_call(url, headers, data_dict, paths, field_name, timeout, out_pattern, draw_idx):
    """单次 multipart 调用。返回 (saved_paths, error_text)。"""
    files    = build_files(paths, field_name)
    total_mb = sum(len(f[1][1]) for f in files) / 1024 / 1024
    t0       = time.time()
    try:
        resp = requests.post(url, headers=headers, data=data_dict, files=files, timeout=timeout)
    except requests.RequestException as e:
        err = f"网络错误: {e}"
        log(err)
        return [], err
    dt = time.time() - t0
    log(f"HTTP {resp.status_code}  耗时 {dt:.1f}s  (上传 {len(files)} 图 {total_mb:.2f} MB)")
    if resp.status_code != 200:
        err = f"HTTP {resp.status_code}: {resp.text[:500]}"
        log(f"响应错误: {resp.text[:1000]}")
        if "unsupported" in resp.text.lower() and "azure" in resp.text.lower():
            log("提示: 本端点仅接受 gpt-image-* 系，不要传 gemini")
        if "divisible by 16" in resp.text.lower():
            log("提示: size 宽高须 16 整除")
        return [], err
    try:
        result = resp.json()
    except Exception:
        err = f"非 JSON: {resp.text[:500]}"
        log(err)
        return [], err
    return save_result(result, out_pattern, draw_idx, timeout)


def call_with_fallback(primary_model, fallback_chain, prompt_text, args, extra,
                        url, headers, draw_idx):
    """主模型 + fallback 链：依次尝试，返回 (saved, used_model, attempts)。"""
    candidates = [primary_model] + (fallback_chain or [])
    attempts = []
    for idx, model in enumerate(candidates):
        if idx > 0:
            log(f"⤵ 尝试 fallback 模型 [{idx}/{len(candidates)-1}]: {model}")
        data_dict = {
            "model":   model,
            "prompt":  prompt_text,
            "size":    args.size,
            "quality": args.quality,
            "n":       str(args.n),
        }
        data_dict.update(extra)
        saved, err = do_one_call(url, headers, data_dict, args.image, args.field_name,
                                  args.timeout, args.out, draw_idx)
        if saved:
            attempts.append({"model": model, "ok": True, "error": ""})
            return saved, model, attempts
        attempts.append({"model": model, "ok": False, "error": err[:300]})
        if idx == len(candidates) - 1:
            break
        if not is_retryable_error(err):
            log(f"✋ 错误不可重试，停止 fallback: {err[:200]}")
            break
    return [], candidates[0], attempts


def main():
    args       = parse_args()
    api_key    = require_api_key_or_exit()
    extra      = parse_extra_params(args.param)
    url        = args.base_url.rstrip("/") + ENDPOINT_EDITS

    # ── Prompt / Variants 解析 ──────────────────────────────
    if args.variants_file:
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
        log(f"随机抽卡模式：共 {len(variants)} 个 prompt 变体")
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

    validate_model(args.model)
    warn_size(args.size)

    draw_n = max(1, args.draw)
    if draw_n > 10:
        log(f"警告: --draw={draw_n} 超过建议上限 10")

    # ── Fallback 链 ─────────────────────────────────────────
    fallback_chain = parse_fallback_arg(args.fallback, args.model)
    # image_edit 端点仅 gpt-image-* 系兼容，过滤掉非 gpt-image 的 fallback
    fallback_chain = [m for m in fallback_chain if m.startswith("gpt-image")]
    if fallback_chain:
        log(f"fallback 链: {' → '.join(fallback_chain)}")
    else:
        log(f"fallback: 已禁用（image_edit 端点仅支持 gpt-image-*）")

    headers = {"Authorization": api_key}
    log(f"model={args.model}  draw={draw_n}  mode={draw_mode}  size={args.size}  quality={args.quality}")
    log(f"POST {url}")
    log("正在生成图片，请稍候...")

    all_saved    = []
    used_prompts = []
    fallback_log = []
    failed       = 0
    run_t0       = time.time()

    for k in range(1, draw_n + 1):
        prompt_text = variants[(k - 1) % len(variants)]
        used_prompts.append(prompt_text[:200])

        log(f"===== draw {k}/{draw_n}  prompt=[{prompt_text[:80]}{'...' if len(prompt_text)>80 else ''}] =====")

        saved, used_model, attempts = call_with_fallback(
            args.model, fallback_chain, prompt_text, args, extra, url, headers, k
        )

        if len(attempts) > 1 or (attempts and not attempts[0]["ok"]):
            fallback_log.append({
                "draw":     k,
                "primary":  args.model,
                "actual":   used_model if saved else None,
                "attempts": attempts,
            })
            if saved and used_model != args.model:
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
        rescued = sum(1 for f in fallback_log if f["actual"] and f["actual"] != args.model)
        log(f"fallback 统计: {rescued}/{len(fallback_log)} 次降级救活")

    out = {
        "success":   len(all_saved) > 0,
        "model":     args.model,
        "mode":      draw_mode,
        "variants":  used_prompts,
        "draw":      draw_n,
        "files":     all_saved,
        "count":     len(all_saved),
        "failed":    failed,
        "fallbacks": fallback_log,
        "elapsed_s": round(total_dt, 1),
    }
    sys.stdout.write(json.dumps(out, ensure_ascii=False, indent=2) + "\n")
    sys.stdout.flush()
    if not all_saved:
        sys.exit(1)


if __name__ == "__main__":
    main()
