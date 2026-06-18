"""schema TOML 加载与校验。

支持的字段 type:
  - string / int / float / bool         基础类型
  - enum  (+ enum=[...])                 枚举
  - tid   (+ fkey=...)                   文本表 key 引用
  - fkey  (+ fkey="Table.col")           外键引用其它表
  - dynamic (+ type_resolver=...)        类型由其它字段值反查决定（例：buff_paramN）

支持的 table 级元字段:
  - sheet                  对应 xlsx 的 sheet 名
  - pkey                   主键字段名
  - cn / desc              中文名 / 描述
  - inherit_when_blank     列表，列出"承上规则"列名（空值时沿用上一行）
"""
from __future__ import annotations
from dataclasses import dataclass, field
from pathlib import Path
from typing import Any
import sys

# Python 3.11+ 内置 tomllib，3.10 及以下用 tomli
if sys.version_info >= (3, 11):
    import tomllib  # type: ignore
else:
    try:
        import tomli as tomllib  # type: ignore
    except ImportError:
        raise SystemExit("Python < 3.11 需要 `pip install tomli`")

VALID_TYPES = {
    "string", "int", "float", "bool",
    "enum", "tid", "fkey", "dynamic",
}


@dataclass
class FieldDef:
    name: str
    type: str
    cn: str = ""
    desc: str = ""
    enum: list[str] | None = None
    fkey: str = ""
    type_resolver: str = ""

    @classmethod
    def from_toml(cls, name: str, raw: dict[str, Any]) -> "FieldDef":
        t = raw.get("type", "")
        if t not in VALID_TYPES:
            raise ValueError(f"field {name}: unknown type '{t}'")
        return cls(
            name=name,
            type=t,
            cn=raw.get("cn", ""),
            desc=raw.get("desc", ""),
            enum=list(raw["enum"]) if "enum" in raw else None,
            fkey=raw.get("fkey", ""),
            type_resolver=raw.get("type_resolver", ""),
        )


@dataclass
class TableDef:
    name: str
    sheet: str
    pkey: str
    cn: str = ""
    desc: str = ""
    inherit_when_blank: list[str] = field(default_factory=list)
    fields: dict[str, FieldDef] = field(default_factory=dict)

    @classmethod
    def from_toml(cls, name: str, raw: dict[str, Any]) -> "TableDef":
        if "sheet" not in raw:
            raise ValueError(f"table {name}: missing 'sheet'")
        if "pkey" not in raw:
            raise ValueError(f"table {name}: missing 'pkey'")
        td = cls(
            name=name,
            sheet=raw["sheet"],
            pkey=raw["pkey"],
            cn=raw.get("cn", ""),
            desc=raw.get("desc", ""),
            inherit_when_blank=list(raw.get("inherit_when_blank", [])),
        )
        for fname, fraw in (raw.get("fields") or {}).items():
            td.fields[fname] = FieldDef.from_toml(fname, fraw)
        if td.pkey not in td.fields:
            raise ValueError(f"table {name}: pkey '{td.pkey}' not in fields")
        return td


@dataclass
class Schema:
    path: Path
    schema_version: int
    target_xlsx: str
    target_xlsx_glob: str
    output_baked: str
    tables: dict[str, TableDef] = field(default_factory=dict)

    @classmethod
    def load(cls, path: Path) -> "Schema":
        with path.open("rb") as f:
            raw = tomllib.load(f)
        s = cls(
            path=path,
            schema_version=int(raw.get("schema_version", 1)),
            target_xlsx=raw.get("target_xlsx", ""),
            target_xlsx_glob=raw.get("target_xlsx_glob", ""),
            output_baked=raw.get("output_baked", path.stem.replace(".schema", "") + ".tres"),
        )
        if not s.target_xlsx and not s.target_xlsx_glob:
            raise ValueError(
                f"schema {path}: must declare either 'target_xlsx' or 'target_xlsx_glob'"
            )
        for tname, traw in (raw.get("tables") or {}).items():
            s.tables[tname] = TableDef.from_toml(tname, traw)
        if not s.tables:
            raise ValueError(f"schema {path}: no [tables.*] declared")
        return s


def load_all_schemas(proto_dir: Path) -> dict[str, Schema]:
    """扫描 proto 目录加载所有 *.schema.toml。"""
    out: dict[str, Schema] = {}
    for p in sorted(proto_dir.glob("*.schema.toml")):
        s = Schema.load(p)
        out[p.stem] = s
    return out
