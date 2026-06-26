# 文本表导出流程

> ⚠️ **注意**：文本表修改后**一般不需要手动导出**，由下游流水线统一处理。
> 仅在用户明确坚持要导出时，才参考本文档执行。

---

## 文本表与普通配置表的区别

| 对比项 | 普通配置表 | 文本表 |
|--------|-----------|--------|
| 文件位置 | `xls/Main/` | `xls/Text/` |
| 导出方式 | 单表导出 | **全量合并导出** |
| 导出脚本 | `export_one_for_ai.py` | `AI/ai_tool_export_text_excel.py` |
| 输出文件 | `XxxConfig.pbin` | `TextClientzh_CN.pbin` 等多语言文件 |
| 参考 bat | `export_one_for_ai.bat` | `common/convert_text_excel.bat` |

> 文本表（`W_文本表_Excel_*.xlsx`）与普通配置表不同，**必须全量合并导出**，不能单独导出某一个文本表。

---

## 文本表导出命令

```bash
# 在 common/excel/ 目录下执行（全量合并导出所有文本表）
DataTableTool\dependencies\python-3.8.2\python.exe AI\ai_tool_export_text_excel.py
```

---

## 文本表导出流程说明

脚本内部分两步执行（完全参考 `common/convert_text_excel.bat`）：

**Step 1**：扫描 `xls/Text/` 目录，动态生成 `ClientExcelConverter/need_convert_text_excel.json`
- 使用 `common/tools/python-3.8.2/python.exe` 执行 `gen_text_excel_json.py`
- 实时输出扫描进度

**Step 2**：调用 DataTableTool 的 `Converter` 类执行全量导出
- 先导出客户端，再导出服务器
- 实时输出导出进度和生成文件列表
- 最终输出：`client/data/TextClientzh_CN.pbin` 等多语言文件

---

## 文本表导出完成标志

脚本输出以下内容时表示导出成功：

```
[客户端] 导出完成，生成文件：
  TextClientzh_CN.pbin
  ...
[服务器] 导出完成，生成文件：
  ...
============================================================
[OK] 文本表导出完成！
============================================================
```

---

## 何时需要导出文本表

- 修改了 `xls/Text/W_文本表_Excel_*.xlsx` 中的任何内容
- 新增了文本表文件
- 修改了文本表中的多语言文案

> **再次强调**：正常流程中文本表修改后不需要手动导出，流水线会统一处理。
> 本文档仅供用户明确要求手动导出时参考。

---

## 导出脚本路径注意事项

`ai_tool_export_text_excel.py` 存放在 `common/excel/AI/` 目录下，脚本内的路径计算需要注意：

- `os.path.dirname(os.path.realpath(__file__))` 返回的是 `AI/` 目录
- 需要再向上一级才能得到 `common/excel/` 目录
- `tools_python` 路径是 `common/tools/python-3.8.2/python.exe`（不是 `common/excel/tools/`）
- `gen_json_script` 路径是 `common/excel/tools/pytool/gen_text_excel_json.py`（不是 `AI/tools/`）

```python
# 正确的路径计算方式
ai_dir = os.path.dirname(os.path.realpath(__file__))       # common/excel/AI/
script_dir = os.path.dirname(ai_dir)                        # common/excel/
tools_python = os.path.join(script_dir, '..', 'tools', 'python-3.8.2', 'python.exe')
gen_json_script = os.path.join(script_dir, 'tools', 'pytool', 'gen_text_excel_json.py')
```
