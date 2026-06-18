---
doc_id: data-editing-guide
status: stable
last_updated: 2026-05-29
audience: 策划 / 兼职改表的工程
related: data-format-spec.md
---

# 配表编辑指南（策划速查）

> 第一次改表？三步走：**装插件 → 改 xlsx → 跑导表脚本**。
> 范式总览见 `data-format-spec.md`。

---

## 1. 一次性环境准备（5 分钟）

### 1.1 安装 Python 依赖

```powershell
cd <项目根>
pip install openpyxl watchdog
```

Python 需要 ≥ 3.11（自带 tomllib）。

### 1.2 推荐 IDE 插件（CodeBuddy / VSCode 通用）

| 插件 | 作用 |
|---|---|
| `grapecity.gc-excelviewer` | Excel/CSV 网格视图（最强，预览 xlsx） |
| `tamasfe.even-better-toml` | TOML schema 文件高亮 |
| `mechatroner.rainbow-csv` | CSV 列着色（debug json 偶尔用） |

工作区已配 `.vscode/extensions.json`，打开仓库会弹"安装推荐扩展"，点 **Install All** 即可。

---

## 2. 改一个 buff 数值（最常见）

### Step 1 · 用 Excel / WPS 打开 xlsx

`projects/<game>/data/table/BUFF系统.xlsx`

### Step 2 · 切到对应 sheet

- 改 **buff 类型定义** → `buff枚举` sheet
- 改 **具体 buff 实例** → `buff实例` sheet

### Step 3 · 改数值

例：把"历险跌落山谷受伤"的伤害从 `20` 改成 `30`。

| 实际buffid | 备注 | buff主类id | buff子类id | buff参数1 | ... |
|---|---|---|---|---|---|
| 1 | 历险跌落山谷受伤 | buff_injury | buff_injury_main | ~~20~~ **30** | ... |

保存。

### Step 4 · 跑导表脚本

```powershell
python tools/excel_convert.py
```

正常输出：

```
[ok] buff_system.tres                   8 rows  ← ['BUFF系统.xlsx']
[summary] processed=1 written=1 elapsed=15ms
```

### Step 5 · 启动游戏验证

游戏内查 `DataRegistry.get_field("BuffInstance", 1, "buff_param1")` 应该返回 30。

---

## 3. 改一句多语言文案

### Step 1 · 打开文本表

`data/table/TEXT/文本表_基础文本表.xlsx`

### Step 2 · 找到对应 key 行，改 `文本内容` 列

| 文本key | 文本内容 |
|---|---|
| Text_buff_injury_main | ~~受伤~~ **气血受损** |

### Step 3 · 跑导表

```powershell
python tools/excel_convert.py
```

`text_cn.tres` 自动重新生成。

---

## 4. 加一个新 buff 实例

### Step 1 · 找到 `buff实例` sheet 最后一行

确认下一个空行的位置（例如已有 5 行，下一行 buffid 写 `6`）。

### Step 2 · 填新行

| 实际buffid | 备注 | buff主类id | buff子类id | buff参数1 | ... |
|---|---|---|---|---|---|
| 6 | 闭关受伤 | buff_injury | buff_injury_main | 15 | |

### Step 3 · 跑导表

```powershell
python tools/excel_convert.py
```

如果 `buff_main_id` / `buff_subtype_id` 写错了 → 报 `fkey not found`，照行号修。

---

## 5. 加一个新 buff **类型**（涉及 schema）

加新类型比加实例复杂，要改两个地方：

### Step 1 · 在 `buff枚举` sheet 加一行

| buff主类id | 备注 | buff子类id | 名称 | buff参数1 | buff参数1类型 | ... |
|---|---|---|---|---|---|---|
| buff_lifespan | 寿元 | buff_lifespan_extend | Text_buff_lifespan_extend | months | INT16 | |

### Step 2 · 在文本表加对应 key

`文本表_基础文本表.xlsx`：

| key | content_cn |
|---|---|
| Text_buff_lifespan_extend | 延寿 |

### Step 3 · 跑导表

```powershell
python tools/excel_convert.py
```

如果 schema 校验失败（例如新 type 用了 schema 里没声明的 enum 值）→ 找程序员加 enum。

### Step 4 · （新加 buff_param 类型时）让程序员检查 schema

如果你给参数选了一个新的 type 字符串（schema 里没注册的），程序员要在 `buff_system.schema.toml` 的 enum 列表加该值。

---

## 6. 实时开发（自动导表）

不想每次手动跑？开 watcher：

```powershell
python tools/excel_convert_watch.py
```

它会监听 `data/table/` 下所有 xlsx / toml 变更，**保存即触发烘焙**（debounce 0.8 秒）。

---

## 7. 改值的注意事项（避免坑）

| 现象 | 原因 | 解决 |
|---|---|---|
| 烘焙报 `pkey duplicate` | 主键值重复 | 检查新加行的 buffid / id 是否唯一 |
| 烘焙报 `fkey not found` | 外键指向的目标不存在 | 先在被引用表加该行，再改本表 |
| 烘焙报 `expected int, got '1.5'` | 类型不匹配 | 该列声明 int，单元格不能填小数 |
| 烘焙报 `tid 'xxx' not found in TextTable` | 文本表里没该 key | 先在文本表加行 |
| 改完没生效 | 没跑导表 | `python tools/excel_convert.py` |
| 中文显示乱码 | 文件不是 UTF-8 | xlsx 不会乱码；如果是 .toml/.tres 乱码用 VSCode 右下角改 UTF-8 重打开 |
| 一行改了多个字段，某一个改错 | 烘焙累积所有错误一次报 | 看错误清单逐项修，再跑一次 |

---

## 8. 「备注」列怎么用

- 第 1 行写 `备注` 的列**不会被导出**，纯给策划自己看
- 每个数据列后面建议跟一个备注列
- 备注列里写中文随便写，可以写计算公式 / 数值思路 / 待办事项

---

## 9. CI 拦截

提交前会自动跑：

```powershell
python tools/excel_convert.py --validate
```

校验失败的提交无法合并。本地先跑一次确保通过。

---

## 10. 找谁求助

| 问题类型 | 找谁 |
|---|---|
| 数值思路（这个 buff 多少合理） | 策划组内讨论 |
| 字段类型不会写 | 程序员（改 schema） |
| 烘焙脚本报错看不懂 | 程序员（带错误信息截图） |
| 想加新表 / 新字段 | 程序员（按 `data-format-spec.md` §6 SOP 走） |

详细规范见 `docs/data-format-spec.md`。
