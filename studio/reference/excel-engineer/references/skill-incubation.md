# 配表 Skill 孵化流程

> **改一次是劳动，沉淀一次是资产。** 配表专家不仅要高效完成当前任务，更要主动识别那些「可以教给别人的操作」，把它们变成可复用的 Skill，让整个团队受益。
>
> ⚠️ **核心定位**：通过本流程孵化出的 Skill，**明确属于配表专家的子Skill**，由配表专家负责调度和管理。子Skill必须遵循配表专家 SKILL.md 中「子Skill管理」章节的规范要求。

---

## Skill 孵化判断标准

完成任务后，用以下四条标准自检——**满足任一即可提议孵化**：

| # | 判断标准 | 典型场景举例 |
|---|---------|-------------|
| 1 | **会反复执行的操作** | 每个赛季都要新增一批活动配置 |
| 2 | **有固定流程和规则的多步骤工作** | 创建新英雄要改技能表、Buff表、兵种表等多张表，表间有关联规则 |
| 3 | **涉及多张表联动的复杂操作** | 新增一个商城礼包，要同时改礼包表、道具表、文本表、商城表 |
| 4 | **新人上手容易出错的环节** | 文本表的特殊导出流程、Proto 字段编号的规则 |

**一句话判断法：** 如果你觉得「这个操作要是能教给别人就好了」，那它就适合做成 Skill。

---

## Skill 孵化提议

当识别到可 Skill 化的工作时，在任务完成后**主动向用户发起提议**：

```markdown
🔧 配表 Skill 孵化提议

本次任务涉及的操作具备 Skill 化价值，建议沉淀为可复用 Skill：

**Skill 名称建议**：`create-new-hero`（创建新英雄配表流程）
**覆盖的表和流程**：
1. J_技能表.xlsx → 新增技能行，关联 Buff 表
2. B_Buff表.xlsx → 新增 Buff 数据行
3. H_英雄表.xlsx → 新增英雄行，填入技能ID
4. W_文本表 → 新增英雄名称、技能描述文案
5. 导出全部相关 pbin → SVN 提交

**预期收益**：
- 🔄 未来创建新英雄时，一键执行标准化流程，从 ~30 分钟降至 ~5 分钟
- 🛡️ 避免遗漏关联表、字段填错等常见失误
- 📖 新人可直接使用，无需口头传授

是否将此流程沉淀为独立 Skill？回复「孵化」开始，或回复「跳过」。
```

---

## Skill 孵化执行流程

用户确认孵化后，按以下七步执行：

```
① 完成任务 → ② 回顾提炼 → ③ 生成 Skill → ④ 审阅完善 → ⑤ 保存生效 → ⑥ 注册为子Skill → ⑦ 提交公共 Skill 库
```

**各步骤说明：**

| 步骤 | 动作 | 要点 |
|------|------|------|
| ① 完成任务 | 正常完成当前配表工作 | 确保流程走通、结果正确 |
| ② 回顾提炼 | 梳理本次操作的完整步骤、涉及的表和字段、表间关联规则、容易出错的环节 | 特别关注：哪些是固定的、哪些是每次变化的（参数化） |
| ③ 生成 Skill | 使用 `skill-creator` 工具生成 Skill 定义文件 | Skill 内容应包含：触发条件、输入参数、执行步骤、验证检查。**必须遵循子Skill格式规范**（见下方） |
| ④ 审阅完善 | 向用户展示生成的 Skill，接受修改意见 | 遵守 Agent 执行宪法：Skill 文件修改必须经用户确认 |
| ⑤ 保存生效 | 将 Skill 保存到 `.codebuddy/skills/` 目录 | 本地生效，当前用户立即可用 |
| ⑥ 注册为子Skill | 将新Skill注册到配表专家的子Skill管理体系中 | **不可跳过**，详见下方「注册为子Skill」流程 |
| ⑦ 提交公共 Skill 库 | **必须主动询问**用户是否提交到公共配表 Skill 库 | 见下方「团队 Skill 库共享」流程 |

---

## 步骤③：子Skill格式规范

生成的子Skill必须遵循以下格式要求：

1. **`description` 字段简洁化**：只写一句话声明所属关系和职责，不重复描述具体功能
   - ✅ `配表专家（excel-engineer）的子Skill，负责xxx配置。`
   - ❌ 长段描述具体能力细节

2. **正文添加能力概述段**：在标题后、角色描述前，用引用块格式写明完整能力描述
   ```markdown
   > **所属**：配表专家（excel-engineer）的子Skill
   >
   > **能力概述**：[具体能力描述，包含涉及的表、操作类型、关键特性等]
   > - 能力点1
   > - 能力点2
   > - ...
   ```
   这段内容是配表专家判断是否调用此子Skill时优先阅读的部分，必须完整准确。

---

## 步骤⑥：注册为子Skill

Skill 保存到本地后，**必须立即执行以下注册动作**：

1. **更新配表专家 SKILL.md 的子Skill注册表**：
   - 在「子Skill管理 → 子Skill注册表」表格中追加一行
   - 填写：子Skill名称、触发场景（何时应调用此Skill）、说明（能力概述）
   - 触发场景必须明确具体，确保后续任务能准确匹配

2. **向用户确认注册内容**：展示即将追加的注册表行，经用户确认后写入

**注册格式示例：**

```markdown
| `create-new-hero` | 涉及创建新英雄、新增英雄配置、英雄全套配表 | 新英雄配表流程专家。覆盖技能表、Buff表、英雄表、文本表的联动新增，支持一键标准化创建。 |
```

> ⚠️ 注册到子Skill注册表属于修改 SKILL.md，必须遵守 Agent 执行宪法——先展示方案，获得用户确认后才执行。

---

## 团队 Skill 库共享（公共 Skill 库自动提交）

> ⚠️ **强制规则**：每次孵化出新的可复用 Skill 文件夹后，**必须主动询问用户是否提交到公共配表 Skill 库**，不可跳过此步骤。

**公共 Skill 库路径：**

| 库 | 路径 | 适用范围 |
|----|------|---------|
| 通用配表 Skill 库 | `common/excel/AI/skills/` | 所有非战斗相关的配表 Skill |
| 战斗 Skill 库 | `common/excel/AI/skills_for_battle/` | 仅战斗相关的配表 Skill（技能、Buff、兵种、战斗数值等） |

Skill 保存到 `.codebuddy/skills/<skill-name>/` 后，**立即向用户发起提问**：

```markdown
✅ Skill 已创建：`.codebuddy/skills/<skill-name>/`

📢 是否将此 Skill 同步提交到公共 Skill 库？
   - 回复「提交」→ 提交到**通用配表 Skill 库**（`common/excel/AI/skills/`）
   - 回复「提交战斗库」→ 提交到**战斗 Skill 库**（`common/excel/AI/skills_for_battle/`）
   - 回复「跳过」→ 仅保留在本地

💡 判断依据：如果此 Skill 涉及战斗系统（技能、Buff、兵种、战斗数值等），应提交到战斗库；否则提交到通用库。
```

**用户确认提交后，执行以下自动化流程（根据用户选择的目标库替换路径）：**

1. **复制 Skill 文件夹**到公共库：
   - 源：`.codebuddy/skills/<skill-name>/`
   - 目标：`common/excel/AI/skills/<skill-name>/`（或 `skills_for_battle/<skill-name>/`）
   - 复制整个文件夹（包含 SKILL.md、references/、scripts/ 等所有内容）

2. **更新 README.MD**：
   - 读取对应库的 `README.MD`
   - 在「Skill 列表」表格末尾追加一行，填写新 Skill 的信息：
     - **Skill**：Skill 中文名称
     - **目录**：`<skill-name>/`
     - **作者**：从 SKILL.md 的 metadata.author 读取
     - **版本**：从 SKILL.md 的 metadata.version 读取
     - **说明**：从 SKILL.md 的 description 字段提取简要描述，包含触发关键字

   > 示例行：`| 配表专家 | excel-engineer/ | cosmosliu | 2.0 | 配置表领域全能专家。触发关键字：表弟、配表、excel、表格 |`

3. **SVN Add**：
   ```bash
   svn add common/excel/AI/skills/<skill-name> --force
   ```

4. **SVN Commit**（Skill 文件夹 + README.MD 一并提交）：
   - 使用固定 log，通过 Python 脚本 + GBK 文件 + `-F` 参数提交
   - **固定 commit log**：`--story=132879632 【长期】AI相关能力和工具提交用单\n新增配表Skill：<skill-name>`
   - **提交范围**：Skill 文件夹 + README.MD，一次 commit 完成
   - **提交脚本模板**：

   ```python
   # -*- coding: utf-8 -*-
   import subprocess, sys, os, tempfile

   project_root = r'D:\Work\SLGX'
   svn_exe = os.path.join(project_root, r'Tools\svn\win\svn.exe')
   skill_name = '<skill-name>'  # 替换为实际 Skill 名称

   log_msg = '--story=132879632 【长期】AI相关能力和工具提交用单\n新增配表Skill：' + skill_name

   skill_path = os.path.join(project_root, 'common', 'excel', 'AI', 'skills', skill_name)
   readme_path = os.path.join(project_root, 'common', 'excel', 'AI', 'skills', 'README.MD')

   # svn add（仅 Skill 文件夹，README.MD 已在版本控制中）
   subprocess.run([svn_exe, 'add', skill_path, '--force'], check=True,
                  capture_output=True, text=True, encoding='gbk', errors='replace')

   # 写入 GBK 编码 log 文件
   log_file = os.path.join(tempfile.gettempdir(), '_svn_log_msg.txt')
   with open(log_file, 'w', encoding='gbk') as f:
       f.write(log_msg)

   try:
       # Skill 文件夹 + README.MD 一并提交
       cmd = [svn_exe, 'commit', '--depth', 'infinity', skill_path, readme_path, '-F', log_file]
       r = subprocess.run(cmd, capture_output=True, text=True, encoding='gbk', errors='replace')
       print(r.stdout)
       if r.returncode != 0:
           print('[错误]', r.stderr)
           sys.exit(1)
       print('[成功] Skill + README.MD 已提交到公共库！')
   finally:
       if os.path.exists(log_file):
           os.remove(log_file)
   ```

5. **提交成功后输出确认**：

   ```markdown
   ✅ Skill `<skill-name>` 已提交到公共配表 Skill 库！
   - 路径：`common/excel/AI/skills/<skill-name>/`
   - README.MD 已同步更新
   - Revision：<revision号>
   - Log：--story=132879632 【长期】AI相关能力和工具提交用单

   💡 团队共享的 Skill 越多，配表工作的整体效率越高。
      目标：把「个人经验」变成「团队能力」。
   ```

> ⚠️ **注意事项**：
> - 只提交 Skill **文件夹**（不是打包的 .zip）
> - **README.MD 必须同步更新并一并提交**，确保 Skill 列表始终与目录内容一致
> - commit log **固定使用** `--story=132879632 【长期】AI相关能力和工具提交用单`，后接 `\n新增配表Skill：<skill-name>`
> - 提交脚本使用**系统 Python** 执行（项目内置 python-3.8.2 可能存在编码问题）
> - SVN log 必须通过 **GBK 文件 + `-F` 参数**传入，不可用 `-m` 直接传参

---

## 浏览与安装公共 Skill

> 用户可以随时查看公共 Skill 库中有哪些可用的 Skill，并选择安装到自己的本地项目中。
> 
> 配表专家管理两个公共 Skill 库：
> - **通用配表 Skill 库**：`common/excel/AI/skills/`（默认，所有配表场景）
> - **战斗 Skill 库**：`common/excel/AI/skills_for_battle/`（仅战斗相关配表场景）
> 
> 浏览时默认展示通用库。当任务涉及战斗系统，或用户明确要求时，才额外浏览战斗库。

**触发关键字**：`查看skill`、`skill列表`、`有哪些skill`、`安装skill`、`skill库`

### 浏览流程

当用户要求查看公共 Skill 库时，执行以下步骤：

1. **读取 README.MD**：读取 `common/excel/AI/skills/README.MD`，解析「Skill 列表」表格
2. **扫描实际目录**：遍历 `common/excel/AI/skills/` 下的所有子文件夹，读取每个 Skill 的 `SKILL.md` 头部元数据（name、description、author、version）
3. **对比本地状态**：检查 `.codebuddy/skills/` 目录，通过版本号快速标注状态：
   - **❌ 未安装**：本地不存在该 Skill
   - **✅ 已安装（最新）**：本地版本号与公共库一致
   - **📥 有更新**：公共库版本号高于本地
   - **📝 本地版本较新**：本地版本号高于公共库
4. **展示列表**：以清单形式展示给用户

**展示格式：**

```markdown
📦 公共配表 Skill 库（common/excel/AI/skills/）

| # | Skill 名称 | 目录 | 公共库版本 | 本地版本 | 状态 | 说明 |
|---|-----------|------|----------|---------|------|------|
| 1 | 配表专家 | excel-engineer/ | 2.0 | 2.0 | ✅ 最新 | 配置表领域全能专家 |
| 2 | 英雄资源路径 | hero-resource-path/ | 1.0 | - | ❌ 未安装 | 英雄资源路径配置 |
| 3 | xxx | xxx/ | 1.2 | 1.0 | 📥 有更新 | xxx |

💡 操作提示：
   输入序号安装（如「安装 2」）| 输入「全部安装」一键安装所有未安装项
   输入「检查更新」进入更新检查流程 | 输入「更新 3」更新指定 Skill
```

### 安装流程

用户选择要安装的 Skill 后，执行以下步骤：

1. **SVN 更新公共库目录**：`svn update common/excel/AI/skills/`（确保安装最新版本）
2. **复制 Skill 文件夹**到本地：
   - 源：`common/excel/AI/skills/<skill-name>/`
   - 目标：`.codebuddy/skills/<skill-name>/`
   - 复制整个文件夹（包含 SKILL.md、references/、scripts/ 等所有内容）

2. **冲突检查**：
   - 若 `.codebuddy/skills/<skill-name>/` 已存在，提示用户：
   ```markdown
   ⚠️ 本地已存在 Skill `<skill-name>`（版本 x.x）
   公共库版本为 y.y

   - 回复「覆盖」：用公共库版本覆盖本地版本
   - 回复「跳过」：保留本地版本不变
   - 回复「对比」：展示两个版本的差异
   ```

3. **安装确认**：
   ```markdown
   ✅ Skill `<skill-name>` 已安装到本地！
   - 路径：`.codebuddy/skills/<skill-name>/`
   - 版本：<version>
   - 即刻可用，无需重启。
   ```

4. **批量安装**：用户输入「全部安装」时，逐个执行上述流程，跳过已安装且版本一致的 Skill，对版本不一致的逐个询问是否覆盖。

---

## 更新检查与同步

> 定期检查本地已安装的 Skill 是否与公共库保持同步，确保团队始终使用最新版本。

**触发关键字**：`更新skill`、`检查skill更新`、`同步skill`、`skill有更新吗`

### 比对模式选择

执行更新检查时，**先询问用户选择比对模式**：

```markdown
🔍 请选择 Skill 更新比对模式：

A. **快速比对（版本号）**：仅比对 SKILL.md 的 version 字段，速度快、省 token
   ⚠️ 注意：如果本地有内容修改但未更新版本号，快速比对无法检测到，直接拉取更新可能覆盖本地修改

B. **全量比对（文件内容）**：逐文件对比实际内容，准确但消耗更多时间和 token
   ✅ 推荐在不确定本地是否有修改时使用
```

### 快速比对流程（版本号）

1. 遍历本地 `.codebuddy/skills/` 下所有 Skill，读取 `SKILL.md` 的 `version` 字段
2. 读取公共库 `common/excel/AI/skills/` 对应 Skill 的 `version` 字段
3. 比对版本号，判断状态：
   - 版本一致 → ✅ 最新
   - 公共库版本更高 → 📥 公共库有更新
   - 本地版本更高 → 📝 本地版本较新
   - 公共库不存在 → 🆕 仅本地存在（可能是未提交的新 Skill）
4. 展示结果

### 全量比对流程（文件内容）

1. 遍历本地和公共库中对应 Skill 的所有文件
2. 逐文件比对内容（读取文件后对比文本）
3. 判断状态：
   - 所有文件内容一致 → ✅ 最新
   - 公共库有本地不存在的文件，或公共库文件内容更新 → 📥 公共库有更新
   - 本地有公共库不存在的文件，或本地文件内容更新 → 📝 本地有修改
   - 两边都有各自的改动 → ⚠️ 双向不一致
4. 展示结果，对有差异的文件列出具体变更文件清单

### 更新结果展示

```markdown
🔄 Skill 更新检查结果（[快速比对/全量比对]）

| # | Skill | 本地版本 | 公共库版本 | 状态 | 详情 |
|---|-------|---------|----------|------|------|
| 1 | excel-engineer | 2.0 | 2.0 | ✅ 最新 | - |
| 2 | hero-resource-path | 1.0 | 1.1 | 📥 有更新 | SKILL.md、references/xx.md 有变化 |
| 3 | xxx | 1.1 | 1.0 | 📝 本地较新 | 本地有修改，公共库未同步 |

操作提示：
   输入「更新 2」拉取公共库更新 | 输入「全部更新」更新所有有更新项
   输入「对比 2」查看具体差异
```

### 从公共库拉取更新到本地

1. **快速比对模式下**：
   - 先警告用户：「⚠️ 快速比对仅对比了版本号，未检测本地内容是否有修改。如果本地有未体现在版本号中的修改，拉取更新将覆盖这些修改。建议切换全量比对确认后再操作。」
   - 用户确认后，从公共库复制覆盖本地文件

2. **全量比对模式下**：
   - 展示具体变更文件的 diff 摘要
   - 用户确认后，从公共库复制覆盖本地文件

3. **更新完成确认**：
   ```markdown
   ✅ Skill `<skill-name>` 已更新！
   - 本地版本：x.x → y.y
   - 更新文件：[列出变更的文件]
   ```

### 从本地提交修改到公共库

> ⚠️ **谨慎操作**：目前尚无 Skill 审查机制，本地修改提交到公共库后将直接影响所有团队成员。除非你确定修改是**有益且稳定的**，否则不建议轻易提交。

当检查发现本地版本较新或本地有修改时：

1. **不主动建议提交**：仅在用户明确要求时才执行
2. **风险提示**：
   ```markdown
   ⚠️ 将本地修改提交到公共 Skill 库的注意事项：
   - 目前无 Skill 审查机制，提交后立即对所有团队成员生效
   - 请确认修改经过充分测试，且对团队有益
   - 建议先使用「对比」查看具体差异
   
   确认提交请回复「确认提交」，取消请回复「取消」。
   ```
3. 用户明确确认后，执行公共库提交流程（复制 + 更新 README.MD + SVN commit）
