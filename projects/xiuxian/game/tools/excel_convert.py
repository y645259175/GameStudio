"""导表脚本（工作室通用配表范式 v1.0）

用法：
  python tools/excel_convert.py                    # 全量烘焙（增量优化：未变源跳过）
  python tools/excel_convert.py --force            # 强制全量（忽略 hash）
  python tools/excel_convert.py --validate         # 仅校验，不写产物（CI 用）
  python tools/excel_convert.py BUFF系统           # 只烘焙指定 xlsx（不带后缀）
  python tools/excel_convert.py --list             # 列出已注册的 schema 与对应 xlsx

退出码：
  0 = 成功 / 1 = 校验失败 / 2 = 其它错误（schema / IO 等）

约定（不可变）：
  data/table/*.xlsx                  ← 源表
  data/table/proto/*.schema.toml     ← schema
  data/table/TEXT/文本表_*.xlsx      ← 文本表
  data/baked/<name>.tres             ← 运行时产物
  data/debug/<name>.json             ← debug 产物
  data/baked/_manifest.json          ← 烘焙清单（含 hash）
"""
from __future__ import annotations
import argparse
import sys
import time
from pathlib import Path
from typing import Any

# 让 tools/lib 可被导入
THIS = Path(__file__).resolve()
PROJECT_ROOT = THIS.parent.parent
sys.path.insert(0, str(THIS.parent))

from lib.errors import ConvertError, ErrorReport  # noqa: E402
from lib.toml_schema import Schema, load_all_schemas  # noqa: E402
from lib.xlsx_reader import read_sheet, SheetData  # noqa: E402
from lib.validator import convert_and_validate, resolve_fkeys_and_dynamic  # noqa: E402
from lib.writers import (  # noqa: E402
    write_tres, write_json, write_manifest, read_manifest, file_hash,
)


# ----------------------------------------------------------------------------
# 路径
# ----------------------------------------------------------------------------

DATA_DIR        = PROJECT_ROOT / "data"
TABLE_DIR       = DATA_DIR / "table"
PROTO_DIR       = TABLE_DIR / "proto"
TEXT_DIR        = TABLE_DIR / "TEXT"
BAKED_DIR       = DATA_DIR / "baked"
DEBUG_DIR       = DATA_DIR / "debug"
MANIFEST_PATH   = BAKED_DIR / "_manifest.json"


# ----------------------------------------------------------------------------
# 主流程
# ----------------------------------------------------------------------------

def main(argv: list[str] | None = None) -> int:
    ap = argparse.ArgumentParser(description="工作室通用导表工具 v1.0")
    ap.add_argument("xlsx_name", nargs="?", default="",
                    help="只烘焙某张表（不带 .xlsx），留空 = 全量")
    ap.add_argument("--force", action="store_true", help="忽略 hash，强制全量重烘焙")
    ap.add_argument("--validate", action="store_true", help="仅校验不写产物")
    ap.add_argument("--list", action="store_true", help="列出已注册的 schema")
    ap.add_argument("--quiet", action="store_true", help="只输出错误")
    args = ap.parse_args(argv)

    t0 = time.perf_counter()

    if not PROTO_DIR.exists():
        print(f"[error] schema 目录不存在: {PROTO_DIR}")
        return 2

    # 1. 加载所有 schema
    try:
        schemas = load_all_schemas(PROTO_DIR)
    except Exception as e:
        print(f"[error] 加载 schema 失败: {e}")
        return 2

    if args.list:
        _print_schema_list(schemas)
        return 0

    if not schemas:
        print(f"[warn] 没有 schema：{PROTO_DIR}/*.schema.toml")
        return 0

    # 2. 收集要处理的 (schema, xlsx_path) 对
    tasks = _collect_tasks(schemas, only=args.xlsx_name)
    if not tasks:
        print(f"[warn] 没有找到匹配的 xlsx (only={args.xlsx_name!r})")
        return 0

    # 3. 增量过滤（除非 --force / --validate）
    old_manifest = read_manifest(MANIFEST_PATH) if not args.force else None
    fresh_tasks: list[tuple[Schema, list[Path]]] = []
    if old_manifest and not args.force and not args.validate:
        old_hashes: dict[str, str] = {
            e["output"]: e.get("source_hash", "")
            for e in old_manifest.get("tables", [])
        }
        for schema, xlsxs in tasks:
            cur_hash = _combined_hash([schema.path] + xlsxs)
            if old_hashes.get(schema.output_baked) == cur_hash:
                if not args.quiet:
                    print(f"[skip] {schema.output_baked}  (未变更)")
                continue
            fresh_tasks.append((schema, xlsxs))
    else:
        fresh_tasks = tasks

    if not fresh_tasks:
        if not args.quiet:
            print("[done] 所有产物均为最新，无需烘焙。")
        _print_summary(t0, 0, 0)
        return 0

    # 4. 加载文本表 keys（供 tid 字段校验）
    text_keys = _load_text_keys(schemas, fresh_tasks, args.quiet)

    # 5. 第一遍：所有表转换 + 主键校验
    report = ErrorReport()
    all_loaded: dict[str, dict[str, list[dict]]] = {}
    sheet_data_cache: dict[tuple[str, str], SheetData] = {}

    for schema, xlsx_list in fresh_tasks:
        all_loaded[schema.path.stem] = {}
        for xlsx_path in xlsx_list:
            for tname, tdef in schema.tables.items():
                try:
                    sd = read_sheet(
                        xlsx_path, tdef.sheet,
                        inherit_when_blank=tdef.inherit_when_blank,
                    )
                except ConvertError as e:
                    report.add(e)
                    continue
                sheet_data_cache[(str(xlsx_path), tname)] = sd
                typed_rows = convert_and_validate(
                    schema, tdef, sd, xlsx_path.name, all_loaded,
                    text_keys=text_keys, report=report,
                )
                all_loaded[schema.path.stem].setdefault(tname, []).extend(typed_rows)

    # 6. 第二遍：fkey + dynamic（需要全表索引就绪）
    for schema, xlsx_list in fresh_tasks:
        for xlsx_path in xlsx_list:
            for tname, tdef in schema.tables.items():
                sd = sheet_data_cache.get((str(xlsx_path), tname))
                if sd is None:
                    continue
                rows = all_loaded[schema.path.stem].get(tname, [])
                # 仅取本 xlsx 加进来的行（按 sd.rows 同长度）
                this_rows = rows[-len(sd.rows):] if sd.rows else []
                resolve_fkeys_and_dynamic(
                    schema, tdef, this_rows, sd,
                    xlsx_path.name, all_loaded, report,
                )

    if report.has_errors():
        report.print_all()
        print(f"[fail] 烘焙失败：{len(report.errors)} 个错误")
        return 1

    if args.validate:
        if not args.quiet:
            print("[ok] --validate 通过，未写产物")
        _print_summary(t0, len(fresh_tasks), 0)
        return 0

    # 7. 写产物
    BAKED_DIR.mkdir(parents=True, exist_ok=True)
    DEBUG_DIR.mkdir(parents=True, exist_ok=True)
    manifest_entries = []
    if old_manifest:
        kept = {
            e["output"] for e in old_manifest.get("tables", [])
            if e["output"] not in {s.output_baked for s, _ in fresh_tasks}
        }
        manifest_entries.extend(
            e for e in old_manifest.get("tables", []) if e["output"] in kept
        )

    written_count = 0
    for schema, xlsx_list in fresh_tasks:
        tables_data = all_loaded[schema.path.stem]
        out_tres = BAKED_DIR / schema.output_baked
        out_json = DEBUG_DIR / (Path(schema.output_baked).stem + ".json")
        write_tres(out_tres, tables_data)
        write_json(out_json, tables_data)
        manifest_entries.append({
            "schema": schema.path.name,
            "output": schema.output_baked,
            "source_hash": _combined_hash([schema.path] + xlsx_list),
            "row_count": sum(len(v) for v in tables_data.values()),
            "tables": list(tables_data.keys()),
        })
        if not args.quiet:
            row_total = sum(len(v) for v in tables_data.values())
            print(f"[ok] {schema.output_baked:30s} {row_total:5d} rows  ← {[p.name for p in xlsx_list]}")
        written_count += 1

    write_manifest(MANIFEST_PATH, manifest_entries)
    _print_summary(t0, len(fresh_tasks), written_count)
    return 0


# ----------------------------------------------------------------------------
# 辅助
# ----------------------------------------------------------------------------

def _collect_tasks(
    schemas: dict[str, Schema], only: str = ""
) -> list[tuple[Schema, list[Path]]]:
    """每个 schema 对应一个或多个 xlsx 文件。

    - target_xlsx        → 单文件
    - target_xlsx_glob   → glob 匹配多文件
    """
    tasks: list[tuple[Schema, list[Path]]] = []
    for schema in schemas.values():
        if schema.target_xlsx:
            xpath = TABLE_DIR / schema.target_xlsx
            if not xpath.exists():
                print(f"[warn] schema {schema.path.name} 指向的 xlsx 不存在：{xpath}")
                continue
            if only and only not in xpath.stem:
                continue
            tasks.append((schema, [xpath]))
        elif schema.target_xlsx_glob:
            matched = sorted(TABLE_DIR.glob(schema.target_xlsx_glob))
            # 排除 ~$ 临时文件
            matched = [p for p in matched if not p.name.startswith("~$")]
            if only:
                matched = [p for p in matched if only in p.stem]
            if matched:
                tasks.append((schema, matched))
    return tasks


def _combined_hash(paths: list[Path]) -> str:
    parts = []
    for p in sorted(paths, key=str):
        if p.exists():
            parts.append(file_hash(p))
    import hashlib
    return hashlib.sha256("|".join(parts).encode()).hexdigest()[:16]


def _load_text_keys(
    schemas: dict[str, Schema],
    fresh_tasks: list[tuple[Schema, list[Path]]],
    quiet: bool,
) -> set[str]:
    """从已注册的文本表 schema 收集所有 key（供 tid 校验）。"""
    text_keys: set[str] = set()
    for schema in schemas.values():
        if "TextTable" not in schema.tables:
            continue
        if not schema.target_xlsx_glob:
            continue
        matched = sorted(TABLE_DIR.glob(schema.target_xlsx_glob))
        matched = [p for p in matched if not p.name.startswith("~$")]
        for xlsx in matched:
            try:
                sd = read_sheet(xlsx, schema.tables["TextTable"].sheet)
                for row in sd.rows:
                    k = row.get("key")
                    if k:
                        text_keys.add(str(k))
            except ConvertError as e:
                if not quiet:
                    print(f"[warn] 加载文本表失败：{e}")
    return text_keys


def _print_schema_list(schemas: dict[str, Schema]) -> None:
    print(f"已注册 schema（{len(schemas)} 个）：")
    for stem, s in schemas.items():
        target = s.target_xlsx or s.target_xlsx_glob
        tables = ", ".join(s.tables.keys())
        print(f"  - {s.path.name}")
        print(f"      target  : {target}")
        print(f"      output  : {s.output_baked}")
        print(f"      tables  : {tables}")


def _print_summary(t0: float, processed: int, written: int) -> None:
    elapsed = (time.perf_counter() - t0) * 1000
    print(f"[summary] processed={processed} written={written} elapsed={elapsed:.0f}ms")


if __name__ == "__main__":
    sys.exit(main())
