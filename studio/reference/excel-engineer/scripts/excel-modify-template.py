# -*- coding: utf-8 -*-
"""
配表专家通用改表脚本模板（基于 win32com）

使用方式：
  1. 复制此模板到 common/excel/AI/temp/ 下，重命名为具体任务名
  2. 修改 CONFIG 区域的目标文件和 Sheet
  3. 实现 collect_changes() 函数，收集所有修改
  4. 先以预览模式运行确认，再加 --write 执行写入

运行命令（在项目根目录执行）：
  python common/excel/AI/temp/ai_tool_xxx.py          # 预览模式
  python common/excel/AI/temp/ai_tool_xxx.py --write   # 写入模式

重要说明：
  - 读取和写入均使用 win32com（Excel COM），保留公式/格式/数据验证
  - 严禁使用 openpyxl 保存 xlsx 文件（会静默丢失数据）
  - 路径使用相对于 common/excel/ 的路径，如 "xls/Main/D_道具配置.xlsx"
  - 大表读取务必使用 read_range() 批量读取，禁止逐单元格遍历
  - 全局只能存在一个 ExcelApp 实例，禁止同时创建多个（会导致 COM 断连）
"""
import sys
import io
import os
import time

# 修复中文输出编码
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')

# ============================================================
# 路径工具
# ============================================================
def _find_project_root():
    """向上查找含 common/excel 的项目根目录"""
    for start in [os.getcwd(), os.path.dirname(os.path.abspath(__file__))]:
        d = start
        for _ in range(10):
            if os.path.isdir(os.path.join(d, 'common', 'excel')):
                return d
            parent = os.path.dirname(d)
            if parent == d:
                break
            d = parent
    raise RuntimeError("无法定位项目根目录（需包含 common/excel 目录）")

PROJECT_ROOT = _find_project_root()
EXCEL_ROOT = os.path.join(PROJECT_ROOT, 'common', 'excel')

def excel_path(rel_path):
    """将相对于 common/excel/ 的路径转为绝对路径。
    示例: excel_path("xls/Main/D_道具配置.xlsx")
          excel_path("xls/Text/W_文本表_Excel_道具.xlsx")
          excel_path("xls/activity/xxx.xlsx")
    """
    return os.path.abspath(os.path.join(EXCEL_ROOT, rel_path))

# ============================================================
# CONFIG - 根据任务修改（路径相对于 common/excel/）
# ============================================================
TARGET_FILE = excel_path("xls/Main/X_目标表.xlsx")
TARGET_SHEET = "Sheet名"

# ============================================================
# Excel COM 管理器
#
# ⚠️ 全局只能有一个 ExcelApp 实例！
#    同时创建多个会导致 COM 断连异常。
#    需要先读后写时，在同一个 with 块内操作即可。
# ============================================================
class ExcelApp:
    """Excel COM 封装，支持 with 语句自动清理。
    同一个实例中可以先只读打开读取数据，关闭后再可写打开写入。
    """
    def __init__(self):
        import win32com.client
        self.excel = win32com.client.Dispatch("Excel.Application")
        try:
            self.excel.Visible = False
            self.excel.DisplayAlerts = False
        except Exception:
            pass

    def open(self, file_path, read_only=False):
        """打开工作簿，返回 wb 对象"""
        return self.excel.Workbooks.Open(os.path.abspath(file_path), ReadOnly=read_only)

    def close(self):
        try:
            self.excel.Quit()
        except Exception:
            pass
        try:
            del self.excel
        except Exception:
            pass
        time.sleep(0.5)

    def __enter__(self):
        return self

    def __exit__(self, *args):
        self.close()

# ============================================================
# 批量读取工具（核心性能优化）
#
# ⚠️ 禁止逐单元格遍历大表！
#    ws.Cells(r, c).Value 每次都是一次 COM 跨进程调用，
#    4696行循环 = 4696次COM调用，极慢（30s+）。
#    务必使用 read_range() 一次性读取，速度提升 5-10 倍。
# ============================================================
def read_range(ws, start_row, start_col, end_row, end_col):
    """批量读取区域数据，返回二维列表。
    
    用法:
        data = read_range(ws, 4, 1, max_row, 78)
        # data[0][0] = 第4行第1列的值
        # data[i][j] = 第(start_row+i)行第(start_col+j)列的值
    
    注意: 如果只有一行或一列，返回值仍统一为二维列表。
    """
    rng = ws.Range(ws.Cells(start_row, start_col), ws.Cells(end_row, end_col))
    raw = rng.Value
    
    if raw is None:
        return []
    
    # 单单元格：返回值不是 tuple
    if not isinstance(raw, tuple):
        return [[raw]]
    
    # 单行：raw 是一维 tuple
    if not isinstance(raw[0], tuple):
        return [list(raw)]
    
    # 多行多列：raw 是 tuple of tuples
    return [list(row) for row in raw]

def read_column(ws, col, start_row, end_row):
    """批量读取单列数据，返回一维列表。
    
    用法:
        ids = read_column(ws, 1, 4, max_row)  # 读取第1列第4行到末尾
    """
    data = read_range(ws, start_row, col, end_row, col)
    return [row[0] for row in data]

# ============================================================
# Step 1: 读取数据，收集修改
# ============================================================
def collect_changes():
    """
    读取数据，返回修改列表。
    每项格式: (file_path, sheet_name, row, col, new_value, description)

    注意：file_path 用于支持同时修改多个文件（如配置表+文本表）。
    如果只改一个文件，file_path 统一填 TARGET_FILE 即可。
    """
    changes = []

    with ExcelApp() as app:
        # 只读打开目标文件
        wb = app.open(TARGET_FILE, read_only=True)
        ws = wb.Sheets(TARGET_SHEET)
        max_row = ws.UsedRange.Rows.Count
        max_col = ws.UsedRange.Columns.Count

        # === 批量读取示例 ===
        # 一次性读取全部数据（推荐，大表必须用此方式）：
        # data = read_range(ws, 4, 1, max_row, max_col)
        # for i, row in enumerate(data):
        #     actual_row = 4 + i          # Excel 行号
        #     id_val = row[0]             # 第1列 (index 0)
        #     note = row[3]               # 第4列 (index 3)
        #     if some_condition:
        #         changes.append((TARGET_FILE, TARGET_SHEET, actual_row, 4,
        #                         "新值", f"Row {actual_row}: {note} -> 新值"))
        #
        # 只读某一列（如ID列）：
        # ids = read_column(ws, 1, 4, max_row)
        #
        # 跨文件读取（复用同一 Excel 进程）：
        # wb2 = app.open(excel_path("xls/Text/xxx.xlsx"), read_only=True)
        # ws2 = wb2.Sheets("文本")
        # text_data = read_range(ws2, 4, 1, ws2.UsedRange.Rows.Count, 2)
        # wb2.Close(False)

        wb.Close(False)

        # ⚠️ 如果需要先读后写同一个文件：
        # 在这里关闭只读 wb 后，可以在 write_changes 中再可写打开。
        # 不需要退出 ExcelApp，同一个 with 块内复用同一进程。

    return changes

# ============================================================
# Step 2: 预览修改
# ============================================================
def preview(changes):
    print("=== 修改预览 ===")
    # 按文件分组统计
    files = {}
    for fp, sheet, row, col, val, desc in changes:
        fname = os.path.basename(fp)
        files.setdefault(fname, []).append((sheet, row, col, val, desc))

    for fname, items in files.items():
        print(f"\n  [{fname}] {len(items)} 项修改:")
        for sheet, row, col, val, desc in items[:10]:
            print(f"    {desc}")
        if len(items) > 10:
            print(f"    ... 共 {len(items)} 项")

    print(f"\n  总计: {len(changes)} 项修改")

# ============================================================
# Step 3: 用 win32com 写入（保留所有格式和公式）
# ============================================================
def write_changes(changes):
    print("\n=== 通过 Excel COM 写入 ===")

    # 按文件分组
    file_changes = {}
    for fp, sheet, row, col, val, desc in changes:
        file_changes.setdefault(fp, []).append((sheet, row, col, val))

    with ExcelApp() as app:
        for fp, items in file_changes.items():
            fname = os.path.basename(fp)
            try:
                wb = app.open(fp)
            except Exception as e:
                print(f"  [ERROR] 无法打开 {fname}（可能被占用）: {e}")
                continue

            # 按 sheet 分组写入
            sheets_cache = {}
            for sheet, row, col, val in items:
                if sheet not in sheets_cache:
                    sheets_cache[sheet] = wb.Sheets(sheet)
                sheets_cache[sheet].Cells(row, col).Value = val

            try:
                wb.Save()
                print(f"  [OK] {fname}: {len(items)} 项已写入")
            except Exception as e:
                print(f"  [ERROR] 保存 {fname} 失败: {e}")
            wb.Close(False)

    print("  [OK] 写入完成")

# ============================================================
# Main
# ============================================================
if __name__ == '__main__':
    write_mode = '--write' in sys.argv

    changes = collect_changes()
    preview(changes)

    if write_mode:
        if not changes:
            print("\n无修改，跳过写入。")
        else:
            write_changes(changes)
    else:
        print("\n=== 预览模式（未写入）===")
        print("  确认后加 --write 参数执行实际写入")

    print("\nDone.")
