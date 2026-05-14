# -*- coding: utf-8 -*-
"""TimiAI 脚本共用：API Key 加载/保存 + models.json 读取 + 路径工具。

Key 加载优先级：
  1) 环境变量 TIMIAI_API_KEY（临时覆盖）
  2) skill 根目录下 .timiai_key 文件（通过 save_key.py 写入，永久保存）

models.json 路径：同 scripts/ 目录下。提供 load_models() 和 validate_model() 供脚本使用。
"""

import json
import os
import sys
from pathlib import Path

SKILL_ROOT = Path(__file__).resolve().parent.parent
KEY_FILE   = SKILL_ROOT / ".timiai_key"

SCRIPTS_DIR  = Path(__file__).resolve().parent
MODELS_JSON  = SCRIPTS_DIR / "models.json"

DEFAULT_BASE_URL    = "http://api.timiai.woa.com"
ENDPOINT_LLMPROXY   = "/ai_api_manage/llmproxy/images/generations"
ENDPOINT_HUNYUAN    = "/ai_api_manage/hunyuan/images/generations"
ENDPOINT_EDITS      = "/ai_api_manage/llmproxy/images/edits"
ENDPOINT_CHAT       = "/ai_api_manage/llmproxy/chat/completions"


# ─── API Key ─────────────────────────────────────────────────

def load_api_key() -> str:
    env_key = os.environ.get("TIMIAI_API_KEY", "").strip()
    if env_key:
        return env_key
    if KEY_FILE.exists():
        try:
            k = KEY_FILE.read_text(encoding="utf-8").strip()
            if k:
                return k
        except Exception:
            pass
    return ""


def save_api_key(key: str) -> Path:
    key = (key or "").strip()
    if not key:
        raise ValueError("key 不能为空")
    KEY_FILE.write_text(key, encoding="utf-8")
    try:
        if os.name != "nt":
            os.chmod(KEY_FILE, 0o600)
    except Exception:
        pass
    return KEY_FILE


def base_url() -> str:
    return os.environ.get("TIMIAI_BASE_URL", DEFAULT_BASE_URL)


def require_api_key_or_exit() -> str:
    key = load_api_key()
    if key:
        return key
    # 写到 stdout 让 AI 可识别
    print("[NEED_API_KEY] 未找到 TimiAI API Key。", flush=True)
    print(f'[NEED_API_KEY] 请让用户提供 api key，然后执行：', flush=True)
    print(f'[NEED_API_KEY]   python "{SCRIPTS_DIR / "save_key.py"}" <API_KEY>', flush=True)
    print("[NEED_API_KEY] 保存后重试本次调用即可。", flush=True)
    sys.exit(3)


# ─── models.json ─────────────────────────────────────────────

_models_cache = None


def load_models() -> dict:
    """读取 models.json，返回完整配置 dict。失败时打印警告并返回空 dict。"""
    global _models_cache
    if _models_cache is not None:
        return _models_cache
    if not MODELS_JSON.exists():
        _models_cache = {}
        return _models_cache
    try:
        _models_cache = json.loads(MODELS_JSON.read_text(encoding="utf-8"))
    except Exception as e:
        sys.stderr.write(f"[timiai] 警告: 读取 models.json 失败: {e}\n")
        _models_cache = {}
    return _models_cache


def list_model_ids() -> list:
    """返回 models.json 中的所有模型 id 列表。"""
    cfg = load_models()
    return list((cfg.get("models") or {}).keys())


def validate_model(model_name: str) -> dict | None:
    """检查 model_name 是否在 models.json 中。
    返回模型配置 dict，或 None（不在 json 中，但不阻止调用，只打印警告）。
    """
    cfg = load_models()
    models = cfg.get("models") or {}
    if model_name in models:
        return models[model_name]
    if models:
        known = ", ".join(models.keys())
        sys.stderr.write(
            f"[timiai] 警告: 模型 \"{model_name}\" 不在 models.json 中。\n"
            f"[timiai]         已知模型: {known}\n"
            f"[timiai]         如确认可用，可继续；否则请检查模型名。\n"
        )
    return None


def resolve_gen_endpoint(model_name: str, base: str) -> str:
    """根据模型名或 models.json 的 endpoint 字段自动选择生图端点 URL。"""
    cfg = load_models()
    models = cfg.get("models") or {}
    endpoint_type = (models.get(model_name) or {}).get("endpoint", "")
    # 兜底：名称前缀判断
    if endpoint_type == "hunyuan" or model_name.startswith("hunyuan"):
        return base.rstrip("/") + ENDPOINT_HUNYUAN
    return base.rstrip("/") + ENDPOINT_LLMPROXY


# ─── Fallback 链 ─────────────────────────────────────────────

def get_fallback_chain(model_name: str) -> list:
    """读取模型在 models.json 中声明的 fallback 链；模型未配置或不存在则返回 []。"""
    cfg = load_models()
    models = cfg.get("models") or {}
    chain = (models.get(model_name) or {}).get("fallback") or []
    return [m for m in chain if isinstance(m, str) and m.strip()]


# 触发 fallback 的错误关键字（命中任意一个即认为"值得换模型重试"）
_RETRYABLE_KEYWORDS = (
    "ratelimit",         # litellm.RateLimitError
    "rate limit",
    "rate_limit",
    "too many requests",
    "429",
    "503",
    "overloaded",
    "quota",
    "azureexception",    # 上游 Azure 异常
    "service unavailable",
    "upstream",
    "timeout",
    "timed out",
    "internal server error",
    "500",
)

# 不应触发 fallback 的错误（换模型救不了，立即失败更省时间）
_NON_RETRYABLE_KEYWORDS = (
    "invalid api key",
    "unauthorized",
    "401",
    "403",
    "content_policy",
    "content policy",
    "moderation",
    "safety",
    "billing",
    "invalid_value",     # 参数错误（如 size 不是 16 倍数）
    "divisible by 16",
    "unsupported",       # 端点不支持模型（换 fallback 也可能不支持）
)


def is_retryable_error(error_text: str) -> bool:
    """判定错误文本是否值得换 fallback 模型重试。
    优先级：non_retryable 命中 → False；否则 retryable 命中 → True；都没命中 → True（保守地尝试 fallback）。
    """
    if not error_text:
        return False
    s = str(error_text).lower()
    for kw in _NON_RETRYABLE_KEYWORDS:
        if kw in s:
            return False
    for kw in _RETRYABLE_KEYWORDS:
        if kw in s:
            return True
    # 默认：未明确分类的错误也尝试一次 fallback（业务错误大多是上游问题）
    return True


def parse_fallback_arg(value: str, primary_model: str) -> list:
    """解析 --fallback 参数：
      "off"           → []                禁用
      "auto" / 空值   → models.json 链    使用配置
      "modelA,modelB" → [modelA, modelB]  显式覆盖
    """
    v = (value or "").strip().lower()
    if v in ("off", "no", "false", "none", "disable"):
        return []
    if v in ("auto", "", "on", "yes", "true", "default"):
        return get_fallback_chain(primary_model)
    # 显式列表（保留原大小写）
    return [m.strip() for m in (value or "").split(",") if m.strip()]


# ─── 路径工具 ─────────────────────────────────────────────────

def to_relative(abs_path: str) -> str:
    """把绝对路径转成 IDE 可点击的相对路径。

    转换逻辑（按优先级）：
      1. 相对于工作区根目录（$CODEBUDDY_WORKSPACE_FOLDER 或 $VSCODE_WORKSPACE_FOLDER）
      2. 相对于当前工作目录（CWD）
      3. 两者都失败 → 返回绝对路径本身

    路径分隔符统一用 /（IDE 可点击的要求）。
    """
    from pathlib import Path as _P
    abs_p = _P(abs_path).resolve()

    # 候选 base 目录（优先用 workspace root 环境变量）
    workspace = (
        os.environ.get("CODEBUDDY_WORKSPACE_FOLDER")
        or os.environ.get("VSCODE_WORKSPACE_FOLDER")
        or os.environ.get("WORKSPACE_FOLDER")
    )
    candidates = []
    if workspace:
        candidates.append(_P(workspace).resolve())
    candidates.append(_P.cwd())

    for base in candidates:
        try:
            rel = abs_p.relative_to(base)
            return rel.as_posix()   # 统一用 /，IDE 可点击
        except ValueError:
            continue

    # 都失败，返回绝对路径（也用 /）
    return abs_p.as_posix()
