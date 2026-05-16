# -*- coding: utf-8 -*-
"""TimiAI 异步后台任务守护 · 让 agent 能"提交任务后做别的事，过会儿再查"。

为什么：
- batch_generate / pipeline 阻塞 1-30 分钟，agent 期间完全空转
- 但 agent 需要在等图的同时干别的活（写代码、改文档、跑测试）
- 解决：用 subprocess.Popen 后台启动，立即返回 job_id；
        agent 之后随时调 `daemon.py status <job_id>` 查进度

使用流程：

  # 1. 提交后台批量任务（立即返回 job_id）
  python daemon.py submit --tasks tasks.json
  → {"job_id": "abc123", "pid": 12345, "log": "..../jobs/abc123.log"}

  # 2. agent 干别的事 ...

  # 3. 查状态
  python daemon.py status abc123
  → {"job_id": "abc123", "state": "running" | "done" | "fail",
     "progress": {"ok": 3, "fail": 0, "pending": 5},
     "log_tail": [...最近 10 行 stderr...]}

  # 4. 任务完成后取报告
  python daemon.py report abc123
  → 完整 batch report JSON

  # 5. 列出所有 jobs
  python daemon.py list

  # 6. 清理已完成的 jobs
  python daemon.py clean

约束：
- jobs 元数据落 .codebuddy/skills/timiai-image/.jobs/<job_id>/
  - submit.json：提交参数
  - report.json：完成后的 batch_generate 输出
  - log.txt：subprocess stderr 流（实时追加）
  - state：running | done | fail
- subprocess 是分离进程（不依赖 agent 父进程存活）
- 同名 tasks 会用同一 hash → 同一 job_id（避免重复提交）

实现策略：
- daemon.py 不自己跑生图 —— 而是用 subprocess.Popen 启动 batch_generate.py
- 父进程立即返回 job_id；子进程独立完成 + 写 report.json + state
- status 通过 1) 检查 state file 2) 检查子进程 PID 是否还活着 3) 解析 log tail 实现
"""
from __future__ import annotations
import argparse
import hashlib
import json
import os
import subprocess
import sys
import time
from pathlib import Path
from typing import Any, Dict, List, Optional

try:
    sys.stdout.reconfigure(encoding="utf-8")
    sys.stderr.reconfigure(encoding="utf-8")
except Exception:
    pass

SKILL_ROOT = Path(__file__).resolve().parent.parent
JOBS_DIR = SKILL_ROOT / ".jobs"
SCRIPTS_DIR = Path(__file__).resolve().parent


def _ensure_jobs_dir() -> Path:
    JOBS_DIR.mkdir(parents=True, exist_ok=True)
    return JOBS_DIR


def _job_id_from(tasks_path: Path, kind: str) -> str:
    """从 tasks 文件内容 + kind 算稳定 job_id。"""
    text = tasks_path.read_text(encoding="utf-8") if tasks_path.exists() else ""
    h = hashlib.sha256(f"{kind}|{text}".encode("utf-8")).hexdigest()[:10]
    return f"{kind}-{h}"


def _job_dir(job_id: str) -> Path:
    return _ensure_jobs_dir() / job_id


def _is_pid_alive(pid: int) -> bool:
    if pid <= 0:
        return False
    if os.name == "nt":
        # Windows: 用 tasklist
        try:
            r = subprocess.run(
                ["tasklist", "/FI", f"PID eq {pid}", "/FO", "CSV", "/NH"],
                capture_output=True, text=True, timeout=5,
            )
            return str(pid) in r.stdout
        except Exception:
            return False
    else:
        try:
            os.kill(pid, 0)
            return True
        except OSError:
            return False


def _read_state(job_id: str) -> str:
    p = _job_dir(job_id) / "state"
    if not p.exists():
        return "missing"
    return p.read_text(encoding="utf-8").strip()


def _write_state(job_id: str, state: str):
    (_job_dir(job_id) / "state").write_text(state, encoding="utf-8")


def cmd_submit(args):
    """提交后台任务。"""
    tasks_path = Path(args.tasks).resolve()
    if not tasks_path.exists():
        print(json.dumps({"error": f"tasks file not found: {tasks_path}"}, ensure_ascii=False))
        sys.exit(1)

    kind = args.kind  # "batch" or "pipeline"
    job_id = args.job_id or _job_id_from(tasks_path, kind)
    jdir = _job_dir(job_id)
    jdir.mkdir(parents=True, exist_ok=True)

    # 已存在且仍在跑 → 拒绝重复提交
    state = _read_state(job_id)
    if state == "running":
        # check pid
        meta = json.loads((jdir / "submit.json").read_text(encoding="utf-8")) if (jdir / "submit.json").exists() else {}
        pid = meta.get("pid", -1)
        if _is_pid_alive(pid):
            print(json.dumps({
                "job_id": job_id,
                "state": "already_running",
                "pid": pid,
                "log": str(jdir / "log.txt"),
            }, ensure_ascii=False))
            return

    # 启动 subprocess
    target_script = "batch_generate.py" if kind == "batch" else "pipeline.py"
    script_path = SCRIPTS_DIR / target_script
    report_path = jdir / "report.json"
    log_path = jdir / "log.txt"

    cmd = [
        sys.executable, "-u", str(script_path),
        "--tasks" if kind == "batch" else "--config", str(tasks_path),
        "--report", str(report_path),
    ]
    if args.concurrency:
        cmd += ["--concurrency", str(args.concurrency)]

    log_f = open(log_path, "w", encoding="utf-8")

    # Windows 用 CREATE_NEW_PROCESS_GROUP + DETACHED_PROCESS 让子进程脱离父进程
    creationflags = 0
    if os.name == "nt":
        creationflags = subprocess.CREATE_NEW_PROCESS_GROUP

    proc = subprocess.Popen(
        cmd,
        stdout=log_f,
        stderr=subprocess.STDOUT,
        cwd=str(SKILL_ROOT.parent.parent.parent),  # workspace root
        creationflags=creationflags,
    )

    submit_meta = {
        "job_id": job_id,
        "kind": kind,
        "tasks_path": str(tasks_path),
        "report_path": str(report_path),
        "log_path": str(log_path),
        "pid": proc.pid,
        "submitted_at": time.time(),
        "cmd": cmd,
    }
    (jdir / "submit.json").write_text(
        json.dumps(submit_meta, ensure_ascii=False, indent=2),
        encoding="utf-8",
    )
    _write_state(job_id, "running")

    print(json.dumps({
        "job_id": job_id,
        "state": "running",
        "pid": proc.pid,
        "log": str(log_path),
        "report": str(report_path),
        "hint": f"poll status: python {Path(__file__).name} status {job_id}",
    }, ensure_ascii=False))


def cmd_status(args):
    """查任务状态。"""
    job_id = args.job_id
    jdir = _job_dir(job_id)
    if not jdir.exists():
        print(json.dumps({"job_id": job_id, "state": "missing"}, ensure_ascii=False))
        sys.exit(1)

    state = _read_state(job_id)
    submit_path = jdir / "submit.json"
    submit_meta = json.loads(submit_path.read_text(encoding="utf-8")) if submit_path.exists() else {}
    pid = submit_meta.get("pid", -1)
    alive = _is_pid_alive(pid)
    report_path = Path(submit_meta.get("report_path", ""))
    log_path = Path(submit_meta.get("log_path", ""))

    # state file 还显示 running，但 pid 已死 → 自动结算
    if state == "running" and not alive:
        if report_path.exists():
            try:
                rep = json.loads(report_path.read_text(encoding="utf-8"))
                _write_state(job_id, "done" if rep.get("summary", {}).get("fail", 0) == 0 else "fail")
                state = _read_state(job_id)
            except Exception:
                _write_state(job_id, "fail")
                state = "fail"
        else:
            _write_state(job_id, "fail")
            state = "fail"

    # 进度估算（从 report.json，如果还没写就从 log 推）
    progress: Dict[str, Any] = {}
    if report_path.exists():
        try:
            rep = json.loads(report_path.read_text(encoding="utf-8"))
            progress = rep.get("summary", {})
        except Exception:
            pass

    # log tail
    log_tail: List[str] = []
    if log_path.exists():
        try:
            lines = log_path.read_text(encoding="utf-8", errors="replace").splitlines()
            log_tail = lines[-15:]
        except Exception:
            pass

    out = {
        "job_id": job_id,
        "state": state,
        "pid": pid,
        "alive": alive,
        "progress": progress,
        "log_tail": log_tail,
        "submitted_at": submit_meta.get("submitted_at"),
        "elapsed_s": round(time.time() - submit_meta.get("submitted_at", time.time()), 1),
    }
    print(json.dumps(out, ensure_ascii=False, indent=2))


def cmd_report(args):
    """取完整报告。"""
    jdir = _job_dir(args.job_id)
    submit_path = jdir / "submit.json"
    if not submit_path.exists():
        print(json.dumps({"error": "job missing"}, ensure_ascii=False))
        sys.exit(1)
    submit_meta = json.loads(submit_path.read_text(encoding="utf-8"))
    rp = Path(submit_meta.get("report_path", ""))
    if not rp.exists():
        print(json.dumps({"error": "report not yet generated", "state": _read_state(args.job_id)}, ensure_ascii=False))
        sys.exit(2)
    sys.stdout.write(rp.read_text(encoding="utf-8"))


def cmd_list(args):
    """列出所有 jobs。"""
    if not JOBS_DIR.exists():
        print(json.dumps({"jobs": []}, ensure_ascii=False))
        return
    jobs = []
    for jdir in JOBS_DIR.iterdir():
        if not jdir.is_dir():
            continue
        sp = jdir / "submit.json"
        meta = json.loads(sp.read_text(encoding="utf-8")) if sp.exists() else {}
        state = _read_state(jdir.name)
        # 自动结算 stale running
        if state == "running" and not _is_pid_alive(meta.get("pid", -1)):
            rp = Path(meta.get("report_path", ""))
            if rp.exists():
                try:
                    rep = json.loads(rp.read_text(encoding="utf-8"))
                    state = "done" if rep.get("summary", {}).get("fail", 0) == 0 else "fail"
                except Exception:
                    state = "fail"
            else:
                state = "fail"
            _write_state(jdir.name, state)
        jobs.append({
            "job_id": jdir.name,
            "kind": meta.get("kind"),
            "state": state,
            "submitted_at": meta.get("submitted_at"),
        })
    print(json.dumps({"jobs": sorted(jobs, key=lambda j: j.get("submitted_at") or 0, reverse=True)},
                     ensure_ascii=False, indent=2))


def cmd_clean(args):
    """清理 done/fail 的旧 job（保留 running）。"""
    if not JOBS_DIR.exists():
        print(json.dumps({"removed": 0}, ensure_ascii=False))
        return
    n = 0
    for jdir in JOBS_DIR.iterdir():
        if not jdir.is_dir():
            continue
        state = _read_state(jdir.name)
        if state in ("done", "fail", "missing"):
            for f in jdir.glob("*"):
                try:
                    f.unlink()
                except Exception:
                    pass
            try:
                jdir.rmdir()
                n += 1
            except Exception:
                pass
    print(json.dumps({"removed": n}, ensure_ascii=False))


def cmd_kill(args):
    """杀掉 running 的 job。"""
    jdir = _job_dir(args.job_id)
    sp = jdir / "submit.json"
    if not sp.exists():
        print(json.dumps({"error": "missing"}, ensure_ascii=False))
        sys.exit(1)
    meta = json.loads(sp.read_text(encoding="utf-8"))
    pid = meta.get("pid", -1)
    if _is_pid_alive(pid):
        try:
            if os.name == "nt":
                subprocess.run(["taskkill", "/F", "/PID", str(pid)], capture_output=True)
            else:
                os.kill(pid, 9)
            _write_state(args.job_id, "fail")
            print(json.dumps({"job_id": args.job_id, "state": "killed"}, ensure_ascii=False))
            return
        except Exception as e:
            print(json.dumps({"error": str(e)}, ensure_ascii=False))
            sys.exit(2)
    print(json.dumps({"job_id": args.job_id, "state": "not_running"}, ensure_ascii=False))


def main():
    parser = argparse.ArgumentParser(description="TimiAI 异步任务守护")
    sub = parser.add_subparsers(dest="cmd", required=True)

    p1 = sub.add_parser("submit", help="提交后台任务")
    p1.add_argument("--tasks", required=True)
    p1.add_argument("--kind", choices=["batch", "pipeline"], default="batch")
    p1.add_argument("--concurrency", type=int, default=None)
    p1.add_argument("--job-id", default=None)
    p1.set_defaults(func=cmd_submit)

    p2 = sub.add_parser("status")
    p2.add_argument("job_id")
    p2.set_defaults(func=cmd_status)

    p3 = sub.add_parser("report")
    p3.add_argument("job_id")
    p3.set_defaults(func=cmd_report)

    p4 = sub.add_parser("list")
    p4.set_defaults(func=cmd_list)

    p5 = sub.add_parser("clean")
    p5.set_defaults(func=cmd_clean)

    p6 = sub.add_parser("kill")
    p6.add_argument("job_id")
    p6.set_defaults(func=cmd_kill)

    args = parser.parse_args()
    args.func(args)


if __name__ == "__main__":
    main()
