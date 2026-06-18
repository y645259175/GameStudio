"""开发期 watcher：监听 data/table/ 变更，自动触发 excel_convert.py

用法：
  python tools/excel_convert_watch.py
  Ctrl+C 退出

依赖：watchdog（无 watchdog 则降级为轮询）
"""
from __future__ import annotations
import subprocess
import sys
import time
from pathlib import Path

THIS = Path(__file__).resolve()
PROJECT_ROOT = THIS.parent.parent
TABLE_DIR = PROJECT_ROOT / "data" / "table"
CONVERT_SCRIPT = THIS.parent / "excel_convert.py"

DEBOUNCE_SEC = 0.8


def run_convert() -> None:
    print(f"\n--- {time.strftime('%H:%M:%S')} 触发烘焙 ---")
    proc = subprocess.run(
        [sys.executable, str(CONVERT_SCRIPT), "--quiet"],
        cwd=str(PROJECT_ROOT),
    )
    print(f"--- exit={proc.returncode} ---\n")


def main_polling() -> int:
    print(f"[watch · 轮询模式] 监听 {TABLE_DIR}")
    print("（要更快响应可装 watchdog: pip install watchdog）\n")
    snapshot: dict[Path, float] = {}

    def scan() -> dict[Path, float]:
        out = {}
        for ext in ("*.xlsx", "*.toml"):
            for p in TABLE_DIR.rglob(ext):
                if p.name.startswith("~$"):
                    continue
                try:
                    out[p] = p.stat().st_mtime
                except OSError:
                    pass
        return out

    snapshot = scan()
    run_convert()
    while True:
        try:
            time.sleep(1.0)
            cur = scan()
            if cur != snapshot:
                changed = [p.name for p in cur if cur.get(p) != snapshot.get(p)]
                snapshot = cur
                if changed:
                    print(f"[change] {', '.join(changed[:5])}")
                    time.sleep(DEBOUNCE_SEC)
                    run_convert()
        except KeyboardInterrupt:
            print("\n[bye]")
            return 0


def main_watchdog() -> int:
    try:
        from watchdog.events import FileSystemEventHandler  # type: ignore
        from watchdog.observers import Observer  # type: ignore
    except ImportError:
        return main_polling()

    print(f"[watch · watchdog 模式] 监听 {TABLE_DIR}\n")

    class H(FileSystemEventHandler):
        last_run = 0.0
        def on_any_event(self, event):
            if event.is_directory:
                return
            p = Path(event.src_path)
            if p.suffix not in (".xlsx", ".toml"):
                return
            if p.name.startswith("~$"):
                return
            now = time.time()
            if now - self.last_run < DEBOUNCE_SEC:
                return
            self.last_run = now
            print(f"[change] {p.name}")
            run_convert()

    obs = Observer()
    obs.schedule(H(), str(TABLE_DIR), recursive=True)
    obs.start()
    run_convert()
    try:
        while True:
            time.sleep(2)
    except KeyboardInterrupt:
        obs.stop()
    obs.join()
    return 0


if __name__ == "__main__":
    sys.exit(main_watchdog())
