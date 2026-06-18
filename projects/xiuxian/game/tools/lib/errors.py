"""统一错误类型 + 行号定位格式化"""
from __future__ import annotations
from dataclasses import dataclass


class ConvertError(Exception):
    """烘焙过程中所有可定位错误的基类。"""

    def __init__(self, msg: str, *, xlsx: str = "", sheet: str = "",
                 row: int = 0, col: str = "", field: str = ""):
        self.msg = msg
        self.xlsx = xlsx
        self.sheet = sheet
        self.row = row
        self.col = col
        self.field = field
        super().__init__(self.format())

    def format(self) -> str:
        loc_parts = []
        if self.xlsx:
            loc_parts.append(self.xlsx)
        if self.sheet:
            loc_parts.append(f"[{self.sheet}]")
        if self.row:
            loc_parts.append(f"row={self.row}")
        if self.col:
            loc_parts.append(f"col={self.col}")
        if self.field:
            loc_parts.append(f"field={self.field}")
        loc = " ".join(loc_parts)
        return f"{loc}: {self.msg}" if loc else self.msg


@dataclass
class ErrorReport:
    """累积错误，最后一次性报告（避免一个错就退出）。"""
    errors: list[ConvertError]

    def __init__(self):
        self.errors = []

    def add(self, err: ConvertError) -> None:
        self.errors.append(err)

    def has_errors(self) -> bool:
        return len(self.errors) > 0

    def print_all(self) -> None:
        if not self.errors:
            return
        print("\n" + "=" * 70)
        print(f"  烘焙失败：共 {len(self.errors)} 个错误")
        print("=" * 70)
        for i, err in enumerate(self.errors, 1):
            print(f"  [{i}] {err.format()}")
        print("=" * 70 + "\n")
