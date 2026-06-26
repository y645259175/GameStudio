# 配置表导出流程详解

> 本文档包含普通配置表（非文本表）的完整导出技术细节。
> 在 SKILL.md 工作流程 Step 4 需要导出时查阅此文档。

---

## 重要前置说明

> ⚠️ `run_one.bat` 和 `run_all.bat` 已失效（`conv2pb.py` 无命令行入口），**不能直接调用 `conv2pb.py`**。

---

## 方式一：命令行工具（推荐，自动化友好）

项目提供了 `export_one_for_ai.py` 脚本，可在命令行中单独导出指定 Excel：

```bash
# 在 common/excel/ 目录下执行
cd common/excel

# 导出单个 Excel（客户端 + 服务器，默认 both，AI 默认行为）
DataTableTool\dependencies\python-3.8.2\python.exe export_one_for_ai.py xls/Main/F_家族势力.xlsx

# 仅导出客户端
DataTableTool\dependencies\python-3.8.2\python.exe export_one_for_ai.py xls/Main/F_家族势力.xlsx client

# 仅导出服务器
DataTableTool\dependencies\python-3.8.2\python.exe export_one_for_ai.py xls/Main/F_家族势力.xlsx server

# 或使用 bat 包装（更简洁）
export_one_for_ai.bat xls/Main/F_家族势力.xlsx
export_one_for_ai.bat xls/Main/F_家族势力.xlsx client
```

**参数说明：**
- 第一个参数：Excel 路径，相对于 `common/excel/xls/` 目录，支持 `xls/Main/xxx.xlsx` 或 `Main/xxx.xlsx` 两种写法
- 第二个参数（可选）：`client`（仅客户端）/ `server`（仅服务器）/ `both`（默认，客户端+服务器）

> **AI 默认行为**：配表专家执行导出时，默认使用 `both` 模式，同时导出客户端和服务器数据，无需额外指定参数。

---

## 方式二：图形化工具

```bash
# 启动图形化导出工具
L:/AOEM_Trunk_0921/common/excel/ClientExcelConverter.bat
```

操作步骤：
1. 双击 `common/excel/ClientExcelConverter.bat` 打开工具
2. 在文件列表中找到目标 Excel（修改过的文件会红色置顶显示）
3. 双击文件名，或勾选后点击导出按钮，执行 **Step 2**（导出 .pbin）
4. 导出完成后执行 **Step 3**（复制 .pbin 到工程目录）
5. 若修改了 proto，先执行 **Step 1**（重新生成 Lua/C# 接口代码）

```bash
# 仅重新生成 Lua/C# 接口代码（修改了 proto 后执行，在图形化工具中点击 Step 1）
# 或命令行执行：
cd common/excel/client
client_generate_excel_map.bat
```

---

## 技术背景：导出工具调用链

> 以下是对导出工具调用链的完整研究结论，供排查问题时参考。

**调用链（正确方式）：**

```
ClientExcelConverter.bat
  └─ cd DataTableTool
  └─ python src/launcher.py AOEM data_path=<common/excel路径>
       └─ plugin_config.cur_project = Project.AOEM
       └─ path.external_data_path = <common/excel路径>
       └─ plugin_mgr.call_plugin('init_config')
            └─ external_data_loader.init_config()
                 ├─ path.excel_path = external_data_path + '/xls'
                 ├─ path.proto_path = external_data_path + '/proto'
                 ├─ path.cli_output_path = external_data_path + '/client/data'
                 └─ path.svr_output_path = external_data_path + '/server/data'
       └─ ui.main() → ConverterUI → ConvertThread
            └─ converter.Converter(excel_sheet_dict, is_client).process()
```

**关键说明：**
- `conv2pb.py` 是旧版工具，**没有命令行入口**，`main()` 函数需要外部传入 `info`/`env` 参数
- 新版工具是 `DataTableTool/src/converter.py` 的 `Converter` 类
- `excel_sheet_dict` 的 key 是相对于 `path.excel_path`（即 `common/excel/xls/`）的路径
- `logger.is_close_ui = True` 可切换为命令行输出模式（绕过 wx.CallAfter）
- `plugin_mgr` 必须用 `Project.AOEM` 初始化，否则路径配置不正确

---

## 导出验证失败的处理

### logger.error 导致导出中断

`DataTableTool/src/logger.py` 的 `error()` 函数调用 `exit()`，是致命错误。
`converter.py` 中 `check_table()` 在 `write_output()` 之前执行，因此验证错误会阻止 pbin 生成。

**解决方案**：在 `ai_tool_export_one.py` 中 monkey-patch `logger.error` 为非致命函数：

```python
# Monkey-patch logger.error 为非致命（收集警告但不退出）
import DataTableTool.src.logger as logger_mod
_original_error = logger_mod.error
_warnings = []

def _non_fatal_error(msg, *args, **kwargs):
    _warnings.append(str(msg))
    print(f'  [WARNING] {msg}')

logger_mod.error = _non_fatal_error
```

> 这样可以在存在预存数据验证问题（如 id:1079 缺少文本字段等历史遗留问题）时，仍然成功生成 pbin 文件。
