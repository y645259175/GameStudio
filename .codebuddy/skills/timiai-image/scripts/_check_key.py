#!/usr/bin/env python3
"""TimiAI key 自检工具。

用途：AI 在 session 中首次调用 timiai-image skill 前，必须先跑这个脚本验证 key 是否就绪。
取代"看到 .gitignore 排除了 .timiai_key 就以为没 key"的惯性错误判断（AP-07 + AP-10 同类）。

退出码：
  0 = OK，key 已就绪（不打印 key 内容，只确认存在）
  3 = NEED_API_KEY，需要向用户索取并保存

stdout 输出：
  OK · key_source=env|file · key_length=NN · models_available=N
  NEED_API_KEY · 提示如何提供
"""
from __future__ import annotations
import os
import sys
from pathlib import Path

# 工作室固定路径（绝对路径，避免 cwd 依赖）
WORKSPACE = Path("d:/AI/GameStudio")
SKILL_ROOT = WORKSPACE / ".codebuddy" / "skills" / "timiai-image"
KEY_FILE = SKILL_ROOT / ".timiai_key"
MODELS_JSON = SKILL_ROOT / "scripts" / "models.json"


def main() -> int:
    # 1. 环境变量优先
    env_key = os.environ.get("TIMIAI_API_KEY", "").strip()
    if env_key:
        print(f"OK · source=env · key_length={len(env_key)} · skill_root={SKILL_ROOT}")
        return 0

    # 2. 文件 fallback
    if KEY_FILE.exists():
        try:
            k = KEY_FILE.read_text(encoding="utf-8").strip()
        except Exception as e:
            print(f"NEED_API_KEY · key 文件存在但读取失败: {e}")
            return 3
        if k:
            # 同时确认 models.json 也在
            models_n = "?"
            if MODELS_JSON.exists():
                try:
                    import json
                    cfg = json.loads(MODELS_JSON.read_text(encoding="utf-8"))
                    models_n = len((cfg.get("models") or {}))
                except Exception:
                    models_n = "read_fail"
            print(f"OK · source=file · key_length={len(k)} · key_path={KEY_FILE} · models={models_n}")
            return 0
        else:
            print(f"NEED_API_KEY · key 文件存在但为空: {KEY_FILE}")
            return 3

    # 3. 都没有
    print("NEED_API_KEY · 未找到 key")
    print(f"  搜索路径 1（环境变量）: TIMIAI_API_KEY=（未设置）")
    print(f"  搜索路径 2（文件）: {KEY_FILE}（不存在）")
    print(f"  请用户提供 key 后执行：python {SKILL_ROOT}/scripts/save_key.py <API_KEY>")
    return 3


if __name__ == "__main__":
    sys.exit(main())
