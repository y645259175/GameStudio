# SVN 提交流程详解

> 本文档包含 SVN 提交的完整流程、风险评估规则和脚本模板。
> 在 SKILL.md 工作流程 Step 5 需要提交时查阅此文档。

---

## 📝 文本类改动的快捷提交流程

**如果本次是文本类改动（Step 2 中判定为📝），执行以下简化流程：**

1. **检测变更文件**：仅对 xlsx 所在目录执行 `svn status`
2. **确认变更范围**：应只有 `.xlsx` 文件变更，不应有 `.pbin`/`.txt` 变更
3. **跳过风险评估**（文本类改动默认为 🟢 低风险）
4. **提示用户输入 commit log**（含 story 号）
5. **展示最终确认清单**（仅 xlsx 文件）
6. **用户确认后提交**

> 文本类改动不导表、不提交 pbin，策划会在后续统一导表。

---

## 🔢 数值类 / 🔧 结构类改动的完整提交流程

导出完成后，执行以下流程：

### 5.1 检测变更文件

对以下两个目录执行 `svn status`，收集所有变更文件：

| 目录 | 说明 |
|------|------|
| `common/` | Excel 源文件、proto、导出的 pbin 数据 |
| `AOE3D/Assets/` | 复制到工程的 pbin 及自动生成的 Lua/C# 代码 |

```bash
# 查看 common 目录变更
svn status L:/AOEM_Trunk_0921/common

# 查看 res/工程目录变更
svn status L:/AOEM_Trunk_0921/AOE3D/Assets
```

### 5.1.5 检查导出文件是否实际发生变化

在展示 diff 和提交之前，**必须先验证本次导出是否真正产生了文件变化**：

1. 检查 `svn status` 结果中是否包含 `.pbin` 文件的变更（状态为 `M`）
2. 若 **未发现任何 .pbin 文件变更**，则输出警告并中止提交流程：

```markdown
⚠️ 警告：本次导出未检测到任何 .pbin 文件发生变化！

可能原因：
- Excel 修改未正确保存
- 导出脚本执行失败或报错
- 修改的内容与原数据相同（值未变）

建议操作：
1. 重新检查 Excel 文件中的修改是否已保存
2. 查看导出脚本的输出日志，确认是否有报错
3. 确认后重新执行导出，再进行提交

是否仍要继续提交？（请回复「强制提交」或「取消」）
```

3. 若检测到 `.pbin` 文件变更，则继续执行 5.1.8。

### 5.1.8 提交前风险评估

在展示 Diff 和执行提交之前，**必须对本次所有修改逐项进行风险评估**，并以清单形式展示给用户。

**风险等级定义：**

| 等级 | 标识 | 说明 |
|------|------|------|
| 🔴 高风险 | HIGH | 直接影响商业化、玩家付费、大型玩法活动开启；或影响范围广、难以回滚 |
| 🟡 中风险 | MED  | 影响核心玩法数值、系统功能开关、多系统联动配置 |
| 🟢 低风险 | LOW  | 影响范围小、易于回滚、仅影响展示/文案/非核心数值 |

**高风险判定规则（满足任一即为高风险）：**
- 修改涉及**商城、充值、礼包、付费道具**相关配置表（如 `B_宝物`、`G_商城`、`J_礼包` 等）
- 修改涉及**大型玩法活动开启/关闭**的开关字段（如 `openLevel`、`isOpen`、`startTime`、`endTime` 等）
- 修改涉及**玩家付费数值**（如价格、折扣、购买上限、奖励数量等）
- 修改涉及**全局功能开关**（影响所有玩家的功能可见性或可用性）
- 修改**删除或重置**已有数据行（可能导致玩家已有进度/数据异常）

**中风险判定规则（满足任一即为中风险）：**
- 修改涉及**核心玩法数值**（战斗力、资源产出、建筑/科技时间等）
- 修改涉及**解锁条件**（等级、VIP、前置任务等门槛）
- 修改涉及**多个系统联动**的配置（改动会影响多个功能模块）
- 修改涉及**Proto 结构**（新增/删除字段，影响数据解析）

**低风险判定规则：**
- 修改仅影响**文案、名称、描述、图标路径**等展示内容
- 修改**非核心数值**（如排序权重、UI 布局参数等）
- 修改**新增数据行**（不影响已有数据）且影响范围明确

**风险评估输出格式：**

```markdown
## ⚠️ 提交前风险评估

| # | 修改内容 | 影响范围 | 风险等级 | 说明 |
|---|---------|---------|---------|------|
| 1 | F_家族势力.xlsx：areaId=2，unlockLevel: 4→3 | 家族势力区域解锁条件 | 🟡 MED | 降低解锁门槛，影响所有玩家的区域解锁进度，需确认是否为预期调整 |
| 2 | FamilyLandAreaConf.pbin（客户端+服务器） | 配置数据文件 | 🟢 LOW | 由 Excel 自动导出，内容与 Excel 一致 |

**综合风险等级：🟡 中风险**

> 请确认以上风险评估无误后，回复「确认提交」继续执行，或回复「取消」中止提交。
```

> ⚠️ **注意**：若综合风险等级为 🔴 **高风险**，必须在评估结果中额外输出醒目警告，并强烈建议用户二次确认后再提交。

### 5.2 展示 Diff 清单

将变更文件整理为清单，明确展示给用户：

```markdown
## SVN 提交清单

### common 目录变更
| 状态 | 文件路径 |
|------|----------|
| M    | common/excel/xls/Main/X_xxx.xlsx |
| M    | common/excel/client/data/XxxConfig.pbin |
| M    | common/excel/client/data/XxxConfig.txt |
| M    | common/excel/server/data/XxxConfig.pbin |
| M    | common/excel/server/data/XxxConfig.txt |

### AOE3D/Assets 目录变更
| 状态 | 文件路径 |
|------|----------|
| M    | AOE3D/Assets/StreamingAssets/pbin/XxxConfig.pbin |

### 文件 Diff 详情
（对每个变更文件执行 svn diff，展示具体改动内容）
```

对文本文件（.proto、.lua、.cs、**.txt**）执行 `svn diff` 展示具体内容变化；
对二进制文件（.xlsx、.pbin）仅展示文件路径和状态，不展示 diff 内容。

> ⚠️ **重要**：导出后会同时生成 `.pbin`、`.txt`、`.json` 三种格式文件。提交时 **`.pbin` 和 `.txt` 文件必须一并提交**（`.json` 文件视项目规范决定是否提交）。

### 5.3 提示用户输入提交 Log

> ⚠️ **关键规则：commit log 中的 story 号有项目检测逻辑，必须使用正确的 story 号！**
>
> - **`common/excel/AI/` 目录下的内容**（ai_tool 脚本、skills 等）：固定使用 `--story=132879632 【长期】AI相关能力和工具提交用单`
> - **所有其他提交**（Excel 配置表、pbin、proto 等业务数据）：**必须主动询问用户**需要附加的 commit log 描述（包含正确的 story 号），不可自行编造或使用 AI 专用的 story 号

```markdown
📝 请输入本次 SVN 提交的 commit log：
（需要包含 --story=xxx 号，例如：「--story=131234567 修改家族势力表，区域ID=2解锁等级改为4」）
```

### 5.4 提交前最终确认（强制规则）

> ⚠️ **在执行 `svn commit` 之前，必须将完整的提交文件清单和 commit log 展示给用户做最终确认，用户确认后才可执行提交，不可跳过此步骤。**
>
> ⚠️ **执行顺序**：贴清单 → 等确认 → 写脚本 → 执行。禁止先写脚本再贴清单。

```markdown
## 📋 SVN 提交最终确认

**Commit Log：**
`--story=xxxxxxx 本次提交描述`

**提交文件清单：**
| # | 状态 | 文件路径 |
|---|------|---------|
| 1 | M | common/excel/xls/Main/X_xxx.xlsx |
| 2 | M | common/excel/client/data/XxxConfig.pbin |
| 3 | M | common/excel/client/data/XxxConfig.txt |
| 4 | M | common/excel/server/data/XxxConfig.pbin |
| 5 | M | common/excel/server/data/XxxConfig.txt |

⚠️ 请确认以上提交内容无误，回复「确认提交」执行，或回复「取消」中止。
```

**用户确认后**，使用 Python 脚本执行提交（避免命令行中文路径和 `--story` 参数的编码问题）。

---

## AI 工具脚本规范

### 命名规范
- 所有 AI 自动生成的工具脚本，文件名必须加 `ai_tool_` 前缀
- 例如：`ai_tool_modify_excel.py`、`ai_tool_svn_commit.py`

### 存放规则（临时 → 提升）

> ⚠️ **核心规则：工作过程中产生的所有脚本，默认存放在 `common/excel/AI/temp/` 目录下。**

| 目录 | 定位 | 说明 |
|------|------|------|
| `common/excel/AI/temp/` | **临时脚本区** | 所有工作过程中生成的脚本默认存放于此，属于临时文件，可随时清理 |
| `common/excel/AI/` | **正式工具区** | 仅存放经过验证、被证明特别有用的脚本，**须经用户明确允许**后才可放入 |

**工作流程：**

1. **默认行为**：配表专家在工作过程中生成的所有 `ai_tool_*` 脚本，一律存放在 `AI/temp/` 目录下
2. **执行路径**：脚本在 `common/excel/` 目录下执行，引用路径为 `AI/temp/ai_tool_xxx.py`
3. **脚本提升**：任务完成后，如果某个脚本被证明特别有用、具备长期复用价值，主动向用户提议：

```markdown
🔧 本次任务中的脚本 `AI/temp/ai_tool_xxx.py` 具备长期复用价值：
- [说明为什么有用]
- [预期复用场景]

是否将其提升到正式工具区 `AI/ai_tool_xxx.py`？
回复「提升」执行，或回复「跳过」保留在临时区。
```

4. **用户确认后**：将脚本从 `AI/temp/` 移动到 `AI/` 目录下
5. **下次执行同类任务时**：优先检查 `AI/` 目录下是否有可复用的正式脚本，再考虑在 `AI/temp/` 下新建

### Excel 修改脚本模板（`AI/temp/ai_tool_modify_excel.py`）

```python
# -*- coding: utf-8 -*-
import openpyxl

wb = openpyxl.load_workbook('xls/Main/X_xxx.xlsx')
ws = wb['Sheet名称']

# 打印前N行，确认结构
print('=== 当前数据 ===')
for i in range(1, 10):
    row_data = [ws.cell(i, c).value for c in range(1, 6)]
    if any(v is not None for v in row_data):
        print('row %d: %s' % (i, row_data))

# 找字段名所在列（第3行是英文字段名行，第2行是中文注释行）
header_row = 3
target_id_col = None
target_val_col = None
for c in range(1, 20):
    val = ws.cell(header_row, c).value
    if val == 'id字段名':      # 替换为实际主键字段名
        target_id_col = c
    if val == '目标字段名':    # 替换为实际要修改的字段名
        target_val_col = c

print('id列: %s, 目标字段列: %s' % (target_id_col, target_val_col))

# 找到目标行并修改
modified = False
for row in range(4, ws.max_row + 1):
    if ws.cell(row, target_id_col).value == 目标id值:  # 替换为实际 id 值
        old_val = ws.cell(row, target_val_col).value
        ws.cell(row, target_val_col).value = 新值       # 替换为实际新值
        print('修改 row %d: id=%s, 字段: %s -> %s' % (row, 目标id值, old_val, 新值))
        modified = True
        break

if not modified:
    print('[错误] 未找到目标行！')
    exit(1)

wb.save('xls/Main/X_xxx.xlsx')
print('[成功] Excel 已保存')
```

**注意事项：**
- Excel 表头结构：第1行是 `convert(...)` 声明，第2行是中文注释，第3行是英文字段名，第4行起是数据
- 脚本默认存放在 `common/excel/AI/temp/` 目录，必须在 `common/excel/` 目录下执行
- 执行示例：`DataTableTool\dependencies\python-3.8.2\python.exe AI\temp\ai_tool_modify_excel.py`

### 提交脚本模板（`AI/temp/ai_tool_svn_commit.py`）

```python
# -*- coding: utf-8 -*-
import subprocess
import sys
import os
import tempfile

# ⚠️ 关键：脚本开头必须强制控制台代码页为 936 (GBK)
# 若当前控制台是 65001 (UTF-8)，subprocess 会把中文路径按 UTF-8 编码传给 svn.exe，
# svn.exe 按 GBK 解码 → 中文路径乱码 → 报 "not under version control"
# 这是 Windows 上 svn 中文路径异常的最常见根因，第一步必须排除
os.system('chcp 936 >nul 2>&1')

log_msg = '<用户输入的完整log，包含--story=xxx>'  # 直接作为字符串，不会被svn解析为参数

files = [
    r'L:\AOEM_Trunk_0921\common\excel\xls\Main\X_xxx.xlsx',
    r'L:\AOEM_Trunk_0921\common\excel\client\data\XxxConfig.pbin',
    r'L:\AOEM_Trunk_0921\common\excel\client\data\XxxConfig.txt',   # txt 必须一并提交
    r'L:\AOEM_Trunk_0921\common\excel\server\data\XxxConfig.pbin',
    r'L:\AOEM_Trunk_0921\common\excel\server\data\XxxConfig.txt',   # txt 必须一并提交
]

# 过滤出在版本控制下的文件
valid_files = []
for f in files:
    r = subprocess.run(['svn', 'info', f], capture_output=True, text=True, encoding='gbk', errors='replace')
    if r.returncode == 0:
        valid_files.append(f)

# ⚠️ 关键：将 log 写入 GBK 编码文件，用 -F 参数传入
# 本项目 SVN 服务器使用 GBK 编码存储 log，必须用 GBK 写入才能正确显示中文
# 不能用 -m 直接传参（Windows subprocess 传参编码不可控）
# 不能用 UTF-8/UTF-8 BOM（SVN 服务器不识别，会乱码）
log_file = os.path.join(tempfile.gettempdir(), '_svn_log_msg.txt')
with open(log_file, 'w', encoding='gbk') as f:
    f.write(log_msg)

try:
    cmd = ['svn', 'commit'] + valid_files + ['-F', log_file]
    r = subprocess.run(cmd, capture_output=True, text=True, encoding='gbk', errors='replace')
    print(r.stdout)
    if r.returncode != 0:
        print('[错误]', r.stderr)
        sys.exit(1)
    print('[成功] 提交完成！')
finally:
    os.remove(log_file)  # 清理临时 log 文件
```

**关键注意事项：**
- `--story=xxx` 等包含 `--` 的 log 内容，**必须通过 Python 脚本传入**，不能直接在命令行中使用（SVN 会将其解析为自己的选项）
- **log 编码（核心）**：本项目 SVN 服务器使用 **GBK 编码**存储 commit log。必须将 log 写入 **GBK 文件**，用 `-F` 参数传入。用 `-m` 直接传参或用 UTF-8/UTF-8 BOM 文件均会导致中文乱码
- Excel 文件（`xls/Main/`）和 pbin 文件（`client/data/`、`server/data/`）可能属于**不同的 SVN Working Copy**，需要分别提交
- 中文文件名在命令行中存在编码问题，统一使用 Python 脚本处理
- 执行脚本：`DataTableTool\dependencies\python-3.8.2\python.exe AI\temp\ai_tool_svn_commit.py`

> ⚠️ **注意**：若用户取消提交，不执行 svn commit，保留本地修改。
