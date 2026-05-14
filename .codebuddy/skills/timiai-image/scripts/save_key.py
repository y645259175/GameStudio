# -*- coding: utf-8 -*-
"""将用户提供的 TimiAI API Key 永久保存到 skill 根目录。

用法：
  python save_key.py <API_KEY>

保存位置：<skill 根目录>/.timiai_key
"""

import sys

from _auth import save_api_key


def main():
    if len(sys.argv) != 2 or not sys.argv[1].strip():
        print("用法: python save_key.py <API_KEY>")
        sys.exit(2)
    key = sys.argv[1].strip()
    path = save_api_key(key)
    print(f"[已保存] TimiAI API Key 已写入 {path}")
    print("[提示] 后续调用 text2image / image_edit / chat_image 无需再传 key。")


if __name__ == "__main__":
    main()
