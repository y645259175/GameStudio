# -*- coding: utf-8 -*-
"""列出 TimiAI 平台上当前 api key 实际可用的图像模型。

原理：TimiAI 没有标准 /v1/models 接口。通过发送故意非法请求观察错误类型推断可用性。
探测不消耗图像生成配额（都是 400 错误），但占少量 QPM。

端点覆盖：
  generations  → /ai_api_manage/llmproxy/images/generations
  hunyuan      → /ai_api_manage/hunyuan/images/generations   (混元独立端点)
  edits        → /ai_api_manage/llmproxy/images/edits
  chat         → /ai_api_manage/llmproxy/chat/completions

用法：
  python list_models.py                  # 探测全部候选模型（人类可读表格）
  python list_models.py --json           # 机器可读 JSON（供 AI/Skill 选模型）
  python list_models.py --filter gpt     # 只测模型名含 gpt 的
  python list_models.py --endpoint generations
  python list_models.py --models my-custom-model-id
"""

import argparse
import json
import sys
import time

import requests

from _auth import (base_url as default_base_url, require_api_key_or_exit,
                   load_models, GEN_ENDPOINT, HUNYUAN_ENDPOINT, EDIT_ENDPOINT, CHAT_ENDPOINT)

try:
    sys.stdout.reconfigure(encoding="utf-8")
    sys.stderr.reconfigure(encoding="utf-8")
except Exception:
    pass

# 候选模型清单：从 models.json 读取，再补充探测用的额外候选
CANDIDATE_MODELS = {
    "OpenAI 系": [
        "gpt-image-2",
        "gpt-image-1",
        "dall-e-3",
        "dall-e-2",
    ],
    "Google Gemini / Nano Banana 系": [
        "gemini-3-pro-image-preview",
        "gemini-3-pro-image-preview-bft",
        "gemini-3-pro-image-preview-stb",
        "gemini-3.1-flash-image-preview",
        "gemini-3.1-flash-image-preview-bft",
        "gemini-3.1-flash-image-preview-stb",
        "gemini-3-pro-image",
        "gemini-3.1-flash-image",
    ],
    "Black Forest Labs": [
        "FLUX.2-pro",
        "flux.2-pro",
        "flux-2-pro",
    ],
    "腾讯混元": [
        # 走独立 hunyuan 端点，用 probe_hunyuan 探测
        "hunyuan-image-v3.0-v1.0.4",
        "hunyuan-image",
        "hunyuan",
    ],
    "Midjourney": [
        "midjourney",
        "mj",
    ],
}

# "请求模型不存在" 的 \u 转义形态（r.text 中出现的形式）
NOT_FOUND_UNICODE_MARK = "\\u8bf7\\u6c42\\u6a21\\u578b\\u4e0d\\u5b58\\u5728"


def parse_args():
    p = argparse.ArgumentParser(description="探测 TimiAI 平台图像模型的可用性")
    p.add_argument("--json", action="store_true",
                   help="输出机器可读 JSON（供 AI/Skill 选模型；抑制表格输出）")
    p.add_argument("--filter", help="只测模型名含此关键字的候选")
    p.add_argument("--endpoint",
                   choices=["generations", "hunyuan", "edits", "chat", "all"],
                   default="all")
    p.add_argument("--models", nargs="+", default=[],
                   help="追加自定义模型名")
    p.add_argument("--base-url", default=default_base_url())
    p.add_argument("--timeout", type=int, default=20)
    p.add_argument("--sleep", type=float, default=0.3)
    return p.parse_args()


def _classify(text):
    tl = text.lower()
    if ("请求模型不存在" in text or NOT_FOUND_UNICODE_MARK in text
            or "model not found" in tl or "does not exist" in tl
            or "notfounderror" in tl or "invalid model" in tl):
        return "NOT_FOUND"
    if "azureexception" in tl and "unsupported" in tl:
        return "WRONG_ENDPOINT"
    return None


def probe_generations(base_url, api_key, model, timeout):
    url = base_url.rstrip("/") + GEN_ENDPOINT
    body = {"model": model, "size": "1024x1024"}
    try:
        r = requests.post(url, headers={"Authorization": api_key, "Content-Type": "application/json"},
                          json=body, timeout=timeout)
    except requests.RequestException as e:
        return "EXC", str(e)[:120]
    text = r.text
    cls = _classify(text)
    if cls:
        return cls, ""
    tl = text.lower()
    if "'prompt'" in text or ("prompt" in tl and ("empty" in tl or "missing" in tl or "required" in tl)):
        return "OK", ""
    if r.status_code == 200 and '"error"' not in text:
        return "OK", ""
    return "UNKNOWN", text[:120]


def probe_hunyuan(base_url, api_key, model, timeout):
    """混元专用：走独立的 /hunyuan/images/generations 端点。"""
    url = base_url.rstrip("/") + HUNYUAN_ENDPOINT
    body = {"model": model, "size": "1024x1024"}
    try:
        r = requests.post(url, headers={"Authorization": api_key, "Content-Type": "application/json"},
                          json=body, timeout=timeout)
    except requests.RequestException as e:
        return "EXC", str(e)[:120]
    text = r.text
    cls = _classify(text)
    if cls:
        return cls, ""
    tl = text.lower()
    if "'prompt'" in text or ("prompt" in tl and ("empty" in tl or "missing" in tl or "required" in tl)):
        return "OK", ""
    if r.status_code == 200 and '"error"' not in text:
        return "OK", ""
    return "UNKNOWN", text[:120]


def probe_edits(base_url, api_key, model, timeout):
    url = base_url.rstrip("/") + EDIT_ENDPOINT
    tiny_png = bytes.fromhex(
        "89504e470d0a1a0a0000000d49484452000000010000000108060000001f15c4"
        "890000000a49444154789c6300010000000500010d0a2db40000000049454e44ae426082"
    )
    files = [("image[]", ("t.png", tiny_png, "image/png"))]
    data = {"model": model, "size": "1024x1024"}
    try:
        r = requests.post(url, headers={"Authorization": api_key},
                          data=data, files=files, timeout=timeout)
    except requests.RequestException as e:
        return "EXC", str(e)[:120]
    text = r.text
    cls = _classify(text)
    if cls:
        return cls, ""
    tl = text.lower()
    if "'prompt'" in text or ("prompt" in tl and ("empty" in tl or "missing" in tl or "invalid" in tl)):
        return "OK", ""
    if r.status_code == 200 and '"error"' not in text:
        return "OK", ""
    return "UNKNOWN", text[:120]


def probe_chat(base_url, api_key, model, timeout):
    url = base_url.rstrip("/") + CHAT_ENDPOINT
    body = {"model": model, "max_tokens": -1}
    try:
        r = requests.post(url, headers={"Authorization": api_key, "Content-Type": "application/json"},
                          json=body, timeout=timeout)
    except requests.RequestException:
        return "EXC", "timeout（可能可用）"
    text = r.text
    cls = _classify(text)
    if cls:
        return cls, ""
    tl = text.lower()
    if "vertex_ai" in tl or "maxoutputtokens" in tl or "invalid_argument" in tl:
        return "OK", ""
    if "messages" in tl and ("required" in tl or "missing" in tl or "empty" in tl):
        return "OK", ""
    if r.status_code == 200 and '"error"' not in text:
        return "OK", ""
    return "UNKNOWN", text[:120]


ICON = {"OK": "✅", "NOT_FOUND": "❌", "WRONG_ENDPOINT": "·", "UNKNOWN": "?", "EXC": "⚠"}


def build_endpoints(args):
    """返回 [(ep_name, probe_fn), ...]，hunyuan 模型额外附加 hunyuan 端点。"""
    ep_all = []
    if args.endpoint in ("all", "generations"):
        ep_all.append(("generations", probe_generations))
    if args.endpoint in ("all", "hunyuan"):
        ep_all.append(("hunyuan", probe_hunyuan))
    if args.endpoint in ("all", "edits"):
        ep_all.append(("edits", probe_edits))
    if args.endpoint in ("all", "chat"):
        ep_all.append(("chat", probe_chat))
    return ep_all


def main():
    args = parse_args()
    api_key = require_api_key_or_exit()

    # 候选清单：优先从 models.json 读，再补充 CANDIDATE_MODELS 里额外的探测候选
    cfg = load_models()
    json_models = list((cfg.get("models") or {}).keys())

    if args.models:
        probe_list = [("自定义", args.models)]
    else:
        # 合并 models.json 模型 + CANDIDATE_MODELS 里不重复的额外候选
        combined = {}
        for cat, models in CANDIDATE_MODELS.items():
            for m in models:
                combined.setdefault(cat, [])
                if m not in combined[cat]:
                    combined[cat].append(m)
        # 把 models.json 里的模型优先放在最前面（单独一个分类）
        if json_models:
            # 从已有分类中移除（避免重复），然后作为"models.json 配置"分类放在头部
            for cat in combined:
                combined[cat] = [m for m in combined[cat] if m not in json_models]
            combined = {"models.json 配置": json_models, **{k: v for k, v in combined.items() if v}}
        probe_list = list(combined.items())

    if args.filter:
        probe_list = [
            (cat, [m for m in models if args.filter.lower() in m.lower()])
            for cat, models in probe_list
        ]
        probe_list = [(c, m) for c, m in probe_list if m]

    endpoints = build_endpoints(args)

    summary = {}   # category -> [(model, {ep: status})]

    if not args.json:
        sys.stdout.write(f"[TimiAI 模型可用性探测] base={args.base_url}\n")
        sys.stdout.write("[说明] 探测通过发送非法请求，不消耗生成配额\n\n")
        sys.stdout.write(f"{'模型名':<44} " + " ".join(f"{ep[0]:<14}" for ep in endpoints) + "\n")
        sys.stdout.write("-" * (44 + 15 * len(endpoints)) + "\n")

    for category, models in probe_list:
        if not args.json:
            sys.stdout.write(f"\n[ {category} ]\n")
        for model in models:
            # 混元系：在 generations 和 hunyuan 都探测；非混元跳过 hunyuan
            results = {}
            for ep_name, probe_fn in endpoints:
                if ep_name == "hunyuan" and not model.startswith("hunyuan"):
                    results[ep_name] = "N/A"
                    continue
                if ep_name == "generations" and model.startswith("hunyuan"):
                    results[ep_name] = "N/A"
                    continue
                status, _ = probe_fn(args.base_url, api_key, model, args.timeout)
                results[ep_name] = status
                time.sleep(args.sleep)

            summary.setdefault(category, []).append((model, results))

            if not args.json:
                cells = []
                for ep_name, _ in endpoints:
                    st = results[ep_name]
                    if st == "N/A":
                        cells.append(f"  {'N/A':<12}")
                    else:
                        cells.append(f"{ICON.get(st, '?')} {st:<12}")
                sys.stdout.write(f"  {model:<42} " + " ".join(cells) + "\n")

    # 汇总
    ok_by_ep = {}
    for category, rows in summary.items():
        for model, results in rows:
            for ep_name, status in results.items():
                if status == "OK":
                    ok_by_ep.setdefault(ep_name, []).append(model)

    if args.json:
        # 机器可读输出
        out = {
            "probed_at": time.strftime("%Y-%m-%d %H:%M:%S"),
            "available": ok_by_ep,
            "all": {
                cat: {m: res for m, res in rows}
                for cat, rows in summary.items()
            },
        }
        sys.stdout.write(json.dumps(out, ensure_ascii=False, indent=2) + "\n")
    else:
        sys.stdout.write("\n" + "=" * 70 + "\n[结论]\n" + "=" * 70 + "\n")
        for ep_name, models in ok_by_ep.items():
            sys.stdout.write(f"\n  {ep_name} 可用模型 ({len(models)}):\n")
            for m in models:
                sys.stdout.write(f"    ✅ {m}\n")
        sys.stdout.write("\n[图例]\n")
        sys.stdout.write("  ✅ OK            = 模型存在且当前 key 有权限\n")
        sys.stdout.write("  ❌ NOT_FOUND     = 模型不存在或 key 没权限\n")
        sys.stdout.write("  · WRONG_ENDPOINT = 模型不适用本端点（正常，换端点）\n")
        sys.stdout.write("  ?  UNKNOWN       = 未识别的响应，建议人工查看\n")
        sys.stdout.write("  N/A              = 跳过（该模型不适用此端点）\n")


if __name__ == "__main__":
    main()
