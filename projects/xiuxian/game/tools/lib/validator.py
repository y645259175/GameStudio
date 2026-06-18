"""按 schema 校验 + 类型转换。

输入：原始 SheetData（值都是 str / int / float）+ TableDef
输出：转换后的 dict 行 + 累积错误
"""
from __future__ import annotations
from typing import Any

from .errors import ConvertError, ErrorReport
from .toml_schema import FieldDef, Schema, TableDef
from .xlsx_reader import SheetData


def convert_and_validate(
    schema: Schema,
    table: TableDef,
    sheet: SheetData,
    xlsx_name: str,
    all_loaded: dict[str, dict[str, list[dict]]],   # for fkey lookup: schema_stem → table → rows
    text_keys: set[str] | None = None,              # for tid 校验
    report: ErrorReport | None = None,
) -> list[dict[str, Any]]:
    """转换 sheet 数据为 typed dict 列表，累积错误到 report。"""
    report = report or ErrorReport()

    # 1. 字段名一致性
    schema_fields = set(table.fields.keys())
    sheet_fields = set(sheet.field_names)
    missing = schema_fields - sheet_fields
    extra = sheet_fields - schema_fields
    if missing:
        report.add(ConvertError(
            f"schema declared fields not in xlsx: {sorted(missing)}",
            xlsx=xlsx_name, sheet=sheet.sheet,
        ))
    if extra:
        report.add(ConvertError(
            f"xlsx has fields not in schema: {sorted(extra)} (add to {schema.path.name} or remove from xlsx)",
            xlsx=xlsx_name, sheet=sheet.sheet,
        ))
    if missing or extra:
        return []

    # 2. 第一遍：逐行转换非 dynamic 字段，建主键索引
    typed_rows: list[dict[str, Any]] = []
    pk_seen: dict[Any, int] = {}
    for rec, row_line in zip(sheet.rows, sheet.row_xlsx_lines):
        out: dict[str, Any] = {}
        skip_this_row = False
        for fname, fdef in table.fields.items():
            raw = rec.get(fname, "")
            if fdef.type == "dynamic":
                # 第二遍处理
                out[fname] = raw
                continue
            try:
                v = _convert_value(fdef, raw, text_keys=text_keys)
            except ConvertError as e:
                e.xlsx, e.sheet, e.row, e.field = xlsx_name, sheet.sheet, row_line, fname
                report.add(e)
                skip_this_row = True
                continue
            out[fname] = v
        if skip_this_row:
            continue

        # 主键唯一性
        pk_val = out.get(table.pkey)
        if pk_val in (None, ""):
            report.add(ConvertError(
                f"primary key '{table.pkey}' is empty",
                xlsx=xlsx_name, sheet=sheet.sheet, row=row_line, field=table.pkey,
            ))
        elif pk_val in pk_seen:
            report.add(ConvertError(
                f"duplicate primary key '{pk_val}' (also at row {pk_seen[pk_val]})",
                xlsx=xlsx_name, sheet=sheet.sheet, row=row_line, field=table.pkey,
            ))
        else:
            pk_seen[pk_val] = row_line
        typed_rows.append(out)

    return typed_rows


def resolve_fkeys_and_dynamic(
    schema: Schema,
    table: TableDef,
    typed_rows: list[dict[str, Any]],
    sheet: SheetData,
    xlsx_name: str,
    all_loaded: dict[str, dict[str, list[dict]]],
    report: ErrorReport,
) -> None:
    """第二遍：fkey 校验 + dynamic 类型解析。原地修改 typed_rows。"""
    for rec, row_line in zip(typed_rows, sheet.row_xlsx_lines[: len(typed_rows)]):
        for fname, fdef in table.fields.items():
            raw = rec.get(fname, "")
            if fdef.type == "fkey":
                # raw 已经在第一遍按 string 转过，这里只校验目标存在性
                if raw == "":
                    continue
                target = _lookup_fkey(fdef.fkey, raw, all_loaded)
                if target is None:
                    report.add(ConvertError(
                        f"fkey '{fdef.fkey}' value '{raw}' not found in target table",
                        xlsx=xlsx_name, sheet=sheet.sheet, row=row_line, field=fname,
                    ))
            elif fdef.type == "dynamic":
                # type_resolver 形如 "BuffType[{buff_subtype_id}].buff_param1_type"
                resolved_type = _resolve_dynamic_type(
                    fdef.type_resolver, rec, all_loaded
                )
                if resolved_type is None:
                    report.add(ConvertError(
                        f"dynamic type_resolver failed: {fdef.type_resolver}",
                        xlsx=xlsx_name, sheet=sheet.sheet, row=row_line, field=fname,
                    ))
                    continue
                if resolved_type == "" and (raw == "" or raw is None):
                    rec[fname] = None
                    continue
                if resolved_type == "" and raw not in ("", None):
                    report.add(ConvertError(
                        f"dynamic field has value but resolved type is empty (该 buff_subtype 未声明此参数槽)",
                        xlsx=xlsx_name, sheet=sheet.sheet, row=row_line, field=fname,
                    ))
                    rec[fname] = raw
                    continue
                try:
                    rec[fname] = _convert_dynamic(resolved_type, raw)
                except ConvertError as e:
                    e.xlsx, e.sheet, e.row, e.field = xlsx_name, sheet.sheet, row_line, fname
                    report.add(e)


# ----------------------------------------------------------------------------
# 内部辅助
# ----------------------------------------------------------------------------

def _convert_value(fdef: FieldDef, raw: Any, *, text_keys: set[str] | None) -> Any:
    if fdef.type == "string":
        return "" if raw is None else str(raw)
    if fdef.type == "int":
        if raw == "" or raw is None:
            return 0
        try:
            return int(raw)
        except (TypeError, ValueError):
            raise ConvertError(f"expected int, got {raw!r}")
    if fdef.type == "float":
        if raw == "" or raw is None:
            return 0.0
        try:
            return float(raw)
        except (TypeError, ValueError):
            raise ConvertError(f"expected float, got {raw!r}")
    if fdef.type == "bool":
        if raw in (1, True, "1", "true", "True"):
            return True
        if raw in (0, False, "", "0", "false", "False", None):
            return False
        raise ConvertError(f"expected bool 0/1, got {raw!r}")
    if fdef.type == "enum":
        s = "" if raw is None else str(raw)
        if fdef.enum is None or s not in fdef.enum:
            raise ConvertError(f"value '{s}' not in enum {fdef.enum}")
        return s
    if fdef.type == "tid":
        s = "" if raw is None else str(raw)
        if s == "":
            return ""
        if text_keys is not None and s not in text_keys:
            raise ConvertError(f"tid '{s}' not found in TextTable")
        return s
    if fdef.type == "fkey":
        # 第一遍只转字符串，第二遍校验存在性
        return "" if raw is None else str(raw)
    if fdef.type == "dynamic":
        # 第一遍不处理
        return raw
    raise ConvertError(f"unknown type {fdef.type}")


def _lookup_fkey(fkey: str, value: Any, all_loaded: dict) -> Any:
    """fkey 形如 'TableName.col_name'，在所有已烘焙的表里找。"""
    if "." not in fkey:
        return None
    target_table, target_col = fkey.split(".", 1)
    for schema_stem, tables in all_loaded.items():
        if target_table in tables:
            for row in tables[target_table]:
                if str(row.get(target_col, "")) == str(value):
                    return row
    return None


def _resolve_dynamic_type(resolver: str, rec: dict, all_loaded: dict) -> str | None:
    """resolver 形如 'BuffType[{buff_subtype_id}].buff_param1_type'

    1. 解析占位 → 取 rec[buff_subtype_id] 的值
    2. 在 BuffType 表里找 pkey == 该值的行
    3. 返回该行 buff_param1_type 字段的值
    """
    import re
    m = re.match(r"^(\w+)\[\{(\w+)\}\]\.(\w+)$", resolver)
    if not m:
        return None
    target_table, key_field, target_col = m.group(1), m.group(2), m.group(3)
    key_value = rec.get(key_field)
    if key_value is None or key_value == "":
        return ""

    for schema_stem, tables in all_loaded.items():
        if target_table not in tables:
            continue
        # 找 pkey == key_value 的行（target_col 取出来即类型）
        rows = tables[target_table]
        for row in rows:
            # pkey 字段名不知道，遍历值
            for v in row.values():
                if str(v) == str(key_value):
                    return str(row.get(target_col, ""))
    return None


def _convert_dynamic(resolved_type: str, raw: Any) -> Any:
    """把 raw 按运行时反查到的 type 转换。

    支持 INT16 / INT32 / INT64 / FLOAT / STRING / ARRAY / BOOL
    ARRAY 用半角逗号分隔，全部转 int（数组里混合类型暂不支持）
    """
    if resolved_type in ("INT16", "INT32", "INT64"):
        if raw == "" or raw is None:
            return 0
        try:
            return int(raw)
        except (TypeError, ValueError):
            raise ConvertError(f"expected {resolved_type}, got {raw!r}")
    if resolved_type == "FLOAT":
        if raw == "" or raw is None:
            return 0.0
        try:
            return float(raw)
        except (TypeError, ValueError):
            raise ConvertError(f"expected FLOAT, got {raw!r}")
    if resolved_type == "STRING":
        return "" if raw is None else str(raw)
    if resolved_type == "BOOL":
        if raw in (1, True, "1", "true", "True"):
            return True
        if raw in (0, False, "", "0", "false", "False", None):
            return False
        raise ConvertError(f"expected BOOL, got {raw!r}")
    if resolved_type == "ARRAY":
        if raw == "" or raw is None:
            return []
        s = str(raw)
        items = [x.strip() for x in s.split(",") if x.strip() != ""]
        out = []
        for x in items:
            try:
                out.append(int(x))
            except ValueError:
                try:
                    out.append(float(x))
                except ValueError:
                    out.append(x)
        return out
    raise ConvertError(f"unknown resolved_type '{resolved_type}'")
