# -*- coding: utf-8 -*-
"""TimiAI 多模态聊天式图像生成（Nano Banana / Gemini image preview）。

POST http://api.timiai.woa.com/ai_api_manage/llmproxy/chat/completions
Content-Type: application/json
Authorization: <TIMIAI_API_KEY>   (裸 key，不加 Bearer)

说明：
- 本端点仅支持 gemini 系模型，不能用 gpt-image-*（Azure 会拒绝）。
- 支持 1–4 张参考图 + 文本指令，也支持多轮迭代（逐轮把上一轮输出作为历史送回）。

输出约定：
  stderr：[timiai] 进度日志
  stdout：JSON {"success":..., "model":..., "files":[...], "count":N}
          （多轮时 files 包含所有轮次的保存路径）

示例：
  # 单轮 + 参考图
  python chat_image.py --prompt "..." --image a.png --image b.png \
      --aspect-ratio 9:16 --image-size 4K --out result.png

  # 多轮（脚本自动维护对话历史）
  python chat_image.py --prompts "画一只柴犬" "给它加红帽子" "换成水彩画" \
      --aspect-ratio 1:1 --image-size 2K --out-prefix ./round
"""

import argparse
import base64
import json
import sys
import time
from pathlib import Path

import requests

from _auth import (base_url as default_base_url, require_api_key_or_exit,
                   validate_model, to_relative)

try:
    sys.stdout.reconfigure(encoding="utf-8")
    sys.stderr.reconfigure(encoding="utf-8")
except Exception:
    pass

CHAT_ENDPOINT    = "/ai_api_manage/llmproxy/chat/completions"
CONVERT_ENDPOINT = "/ai_api_manage/file/url_conversion"


def log(msg):
    sys.stderr.write(f"[timiai] {msg}\n")
    sys.stderr.flush()


def parse_args():
    p = argparse.ArgumentParser(description="TimiAI 多模态聊天式图像生成（Gemini/Nano Banana）")
    p.add_argument("--prompt", help="单轮提示词")
    p.add_argument("--prompt-file", help="从文件读取单轮提示词")
    p.add_argument("--prompts", nargs="+",
                   help="多轮提示词（每一轮的输出作为历史送入下一轮）")
    p.add_argument("--image", action="append", default=None,
                   help="初始参考图，可重复；多轮模式下仅第 1 轮使用")
    p.add_argument("--model", default="gemini-3-pro-image-preview",
                   help="模型名，默认 gemini-3-pro-image-preview；"
                        "可选 gemini-3.1-flash-image-preview 及 -stb / -bft 变体")
    p.add_argument("--aspect-ratio", default="1:1",
                   choices=["1:1", "4:3", "16:9", "21:9", "9:16", "4:5"])
    p.add_argument("--image-size", default="1K", choices=["1K", "2K", "4K"])
    p.add_argument("--draw", type=int, default=1,
                   help="抽卡模式（仅对单轮 --prompt 有效）：重复次数，默认 1，建议 ≤ 10")
    p.add_argument("--draw-sleep", type=float, default=0.0)
    p.add_argument("--out", default="./timiai_chat_{ts}_d{draw}.png",
                   help="单轮输出路径，支持 {ts} {draw} 占位")
    p.add_argument("--out-prefix", default="./timiai_chat_round",
                   help="多轮输出前缀（默认 ./timiai_chat_round）")
    p.add_argument("--timeout", type=int, default=600)
    p.add_argument("--base-url", default=default_base_url())
    p.add_argument("--use-url-conversion", action="store_true",
                   help="把图片先上传到 COS 再用 URL 传入（请求体过大 / 多轮 4K 推荐开启）")
    return p.parse_args()


def encode_b64(path: Path) -> str:
    return base64.b64encode(path.read_bytes()).decode("utf-8")


def upload_to_cos(base_url, api_key, path: Path, model: str) -> str:
    url = base_url.rstrip("/") + CONVERT_ENDPOINT
    headers = {"Authorization": api_key}
    suffix = path.suffix.lower() or ".png"
    payload = {"file_base64": encode_b64(path), "file_type": suffix, "model": model}
    resp = requests.post(url, headers=headers, json=payload, timeout=120)
    resp.raise_for_status()
    r = resp.json()
    return r.get("presigned_url") or r.get("url")


def build_user_content(text, image_paths, use_url_conversion, base_url, api_key, model):
    content = [{"type": "text", "text": text}]
    for p in image_paths or []:
        pth = Path(p)
        if not pth.exists():
            log(f"错误: 参考图不存在：{p}")
            sys.exit(2)
        if use_url_conversion:
            cos_url = upload_to_cos(base_url, api_key, pth, model)
            content.append({"type": "image_url", "image_url": {"url": cos_url}})
        else:
            mime = "image/png"
            if pth.suffix.lower() in (".jpg", ".jpeg"):
                mime = "image/jpeg"
            b64 = encode_b64(pth)
            content.append({"type": "image_url", "image_url": {"url": f"data:{mime};base64,{b64}"}})
    return content


def call_chat(base_url, api_key, model, messages, aspect_ratio, image_size, timeout):
    url = base_url.rstrip("/") + CHAT_ENDPOINT
    headers = {"Content-Type": "application/json", "Authorization": api_key}
    body = {
        "model": model,
        "messages": messages,
        "image_config": {"aspect_ratio": aspect_ratio, "image_size": image_size},
        "response_modalities": ["IMAGE", "TEXT"],
    }
    if model.endswith("-stb"):
        body.pop("image_config")
        body["generation_config"] = {
            "imageConfig": {
                "aspectRatio": aspect_ratio,
                "imageSize": image_size,
                "imageOutputOptions": {"mimeType": "image/png"},
            }
        }
        body["response_modalities"] = ["IMAGE"]

    log(f"POST {url}  model={model}  aspect={aspect_ratio}  size={image_size}  "
        f"messages={len(messages)}  body≈{len(json.dumps(body))//1024}KB")
    t0 = time.time()
    try:
        resp = requests.post(url, headers=headers, json=body, timeout=timeout)
    except requests.RequestException as e:
        log(f"网络错误: {e}")
        return None
    dt = time.time() - t0
    log(f"HTTP {resp.status_code} 耗时 {dt:.1f}s")
    if resp.status_code != 200:
        log(f"响应错误: {resp.text[:1000]}")
        return None
    try:
        return resp.json()
    except Exception:
        log(f"非 JSON: {resp.text[:500]}")
        return None


def extract_image(result):
    try:
        msg = result["choices"][0]["message"]
    except Exception:
        return None, ""
    text_reply = msg.get("content", "") or ""
    for img in msg.get("images") or []:
        url = (img.get("image_url") or {}).get("url") or ""
        if url.startswith("data:"):
            return url.split(",", 1)[1], text_reply
        if url:
            return url, text_reply
    return None, text_reply


def download_url_bytes(url: str, timeout: int):
    try:
        r = requests.get(url, timeout=timeout)
        if r.status_code == 200:
            return r.content
    except Exception:
        pass
    return None


def save_b64_png(b64: str, path: Path) -> int:
    raw = base64.b64decode(b64)
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_bytes(raw)
    return len(raw)


def main():
    args = parse_args()
    api_key = require_api_key_or_exit()

    single_prompt = None
    if args.prompt:
        single_prompt = args.prompt
    elif args.prompt_file:
        pf = Path(args.prompt_file)
        if not pf.exists():
            log(f"错误: prompt 文件不存在: {args.prompt_file}")
            sys.exit(2)
        single_prompt = pf.read_text(encoding="utf-8")

    if not single_prompt and not args.prompts:
        log("错误: 必须提供 --prompt / --prompt-file 或 --prompts")
        sys.exit(2)

    validate_model(args.model)

    all_saved = []
    run_t0 = time.time()

    if args.prompts:
        if args.draw > 1:
            log("提示: 多轮模式（--prompts）下忽略 --draw（抽卡仅对单轮有意义）")
        history = []
        first_images = args.image or []
        for idx, text in enumerate(args.prompts, 1):
            log(f"===== 第 {idx}/{len(args.prompts)} 轮：{text} =====")
            imgs_this_round = first_images if idx == 1 else []
            user_content = build_user_content(
                text, imgs_this_round, args.use_url_conversion,
                args.base_url, api_key, args.model,
            )
            messages = history + [{"role": "user", "content": user_content}]
            result = call_chat(args.base_url, api_key, args.model, messages,
                               args.aspect_ratio, args.image_size, args.timeout)
            if not result:
                sys.exit(1)
            b64_or_url, text_reply = extract_image(result)
            if not b64_or_url:
                log(f"无图: {json.dumps(result, ensure_ascii=False)[:500]}")
                sys.exit(1)
            if text_reply:
                log(f"模型文字回复: {text_reply[:300]}")

            if b64_or_url.startswith("http"):
                log(f"🔗 远程图片，尝试下载: {b64_or_url}")
                raw = download_url_bytes(b64_or_url, args.timeout)
                if raw:
                    ts = time.strftime("%Y%m%d_%H%M%S")
                    out_path = Path(f"{args.out_prefix}_{idx}_{ts}.png")
                    out_path.parent.mkdir(parents=True, exist_ok=True)
                    out_path.write_bytes(raw)
                    rel = to_relative(str(out_path.resolve()))
                    log(f"✅ 已保存（URL下载）: {rel}  ({len(raw) // 1024} KB)")
                    all_saved.append(rel)
                else:
                    log(f"🔗 下载失败，返回 URL: {b64_or_url}")
                    all_saved.append(b64_or_url)
                continue

            ts = time.strftime("%Y%m%d_%H%M%S")
            out_path = Path(f"{args.out_prefix}_{idx}_{ts}.png")
            save_b64_png(b64_or_url, out_path)
            rel = to_relative(str(out_path.resolve()))
            log(f"✅ 已保存: {rel}  ({out_path.stat().st_size // 1024} KB)")
            all_saved.append(rel)

            history.append({"role": "user", "content": user_content})
            try:
                cos_url = upload_to_cos(args.base_url, api_key, out_path, args.model)
                assistant_content = []
                if text_reply:
                    assistant_content.append({"type": "text", "text": text_reply})
                assistant_content.append({"type": "image_url", "image_url": {"url": cos_url}})
                history.append({"role": "assistant", "content": assistant_content})
            except Exception as e:
                log(f"警告: COS 上传失败（{e}），终止多轮链")
                break
    else:
        draw_n = max(1, args.draw)
        if draw_n > 10:
            log(f"警告: --draw={draw_n} 超过建议上限 10")
        log(f"单轮抽卡 draw={draw_n}")

        failed = 0
        for k in range(1, draw_n + 1):
            log(f"===== draw {k}/{draw_n} =====")
            user_content = build_user_content(
                single_prompt, args.image, args.use_url_conversion,
                args.base_url, api_key, args.model,
            )
            messages = [{"role": "user", "content": user_content}]
            result = call_chat(args.base_url, api_key, args.model, messages,
                               args.aspect_ratio, args.image_size, args.timeout)
            if not result:
                failed += 1
                if k < draw_n and args.draw_sleep > 0:
                    time.sleep(args.draw_sleep)
                continue
            b64_or_url, text_reply = extract_image(result)
            if text_reply:
                log(f"模型文字回复: {text_reply[:300]}")
            if not b64_or_url:
                log(f"无图: {json.dumps(result, ensure_ascii=False)[:500]}")
                failed += 1
                continue
            if b64_or_url.startswith("http"):
                log(f"🔗 远程图片，尝试下载: {b64_or_url}")
                raw = download_url_bytes(b64_or_url, args.timeout)
                if raw:
                    ts = time.strftime("%Y%m%d_%H%M%S")
                    out_path = Path(args.out.format(ts=ts, draw=k))
                    out_path.parent.mkdir(parents=True, exist_ok=True)
                    out_path.write_bytes(raw)
                    rel = to_relative(str(out_path.resolve()))
                    log(f"✅ 已保存（URL下载）: {rel}  ({len(raw) // 1024} KB)")
                    all_saved.append(rel)
                else:
                    log(f"🔗 下载失败，返回 URL: {b64_or_url}")
                    all_saved.append(b64_or_url)
                continue
            ts = time.strftime("%Y%m%d_%H%M%S")
            out_path = Path(args.out.format(ts=ts, draw=k))
            save_b64_png(b64_or_url, out_path)
            rel = to_relative(str(out_path.resolve()))
            log(f"✅ 已保存: {rel}  ({out_path.stat().st_size // 1024} KB)")
            all_saved.append(rel)

            if k < draw_n and args.draw_sleep > 0:
                time.sleep(args.draw_sleep)

        total_dt = time.time() - run_t0
        log(f"完成: 成功 {len(all_saved)} 张 / 失败 {failed} 次 / 总耗时 {total_dt:.1f}s")

    total_dt = time.time() - run_t0
    result_json = {
        "success":   len(all_saved) > 0,
        "model":     args.model,
        "prompt":    (single_prompt or (args.prompts[0] if args.prompts else ""))[:200],
        "files":     all_saved,
        "count":     len(all_saved),
        "elapsed_s": round(total_dt, 1),
    }
    sys.stdout.write(json.dumps(result_json, ensure_ascii=False, indent=2) + "\n")
    sys.stdout.flush()

    if not all_saved:
        sys.exit(1)


if __name__ == "__main__":
    main()
