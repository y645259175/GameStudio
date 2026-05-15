# 工作室语言策略 (Language Policy)

> **定位**：工作室级唯一语言规范，约束 `.codebuddy/` 与 `studio/` 下所有产出物（skill / agent / hook / rule / template / doc / log / postmortem）的语言选择。
>
> **适用范围**：本仓库所有由人或 AI 起草的文档与代码注释。`projects/` 下各子项目可在不违反本策略的前提下追加项目级补充。
>
> **上游来源**：v4 迁移规划 §9.1（[`studio-incubator-migration-v4_4b2c7a91.md`](../../.codebuddy/plans/studio-incubator-migration-v4_4b2c7a91.md)）
>
> **最后更新**：2026-05-14（Phase 1 · 批 2）

---

## 1. 核心原则

**按 token 性质划分中英，而非按文件类型。**

不存在"中文文件"或"英文文件"——同一份 `.md` / `.py` / `.toml` 中，叙述性文字用中文，代码 / 路径 / 命令 / 标识符 / 技术术语用英文。读者切换语言的成本远低于翻译技术术语带来的歧义成本。

这条原则的反面是常见的两种错误做法：
- **全中文化**：把 `agent` 翻译成"代理"、`hook` 翻译成"钩子"，导致检索断裂、与外部生态术语不一致。
- **全英文化**：用蹩脚英文写业务叙述，降低可读性，让母语贡献者望而却步。

本策略明确拒绝这两种极端。

---

## 2. 七条规则总表

| # | 规则 | 一句话 |
|---|---|---|
| R1 | 业务叙述用中文 | 文档正文、规划说明、postmortem、commit body 中的"为什么 / 怎么做 / 何时做"一律中文 |
| R2 | 代码 / 路径 / 命令 / API 用英文 | 任何会被机器执行或解析的 token 必须英文 |
| R3 | 技术术语保留英文 | `agent` / `skill` / `hook` / `commit` / `lint` 等不翻译 |
| R4 | 引用外部内容时保留原文 | 引擎文档 / API 报错 / 第三方 skill 原样引用，不翻译 |
| R5 | 文件名 / 标识符全英文 | 文件名 / 函数名 / 变量名 / 目录名 一律英文 + kebab-case 或 snake_case |
| R6 | frontmatter / 配置字段值用英文 | YAML / TOML / JSON 的 key 与 value 一律英文 |
| R7 | 注释紧贴语境 | 代码块内中文注释 + 英文 API 调用是允许的混排模式 |

---

## 3. R1 · 业务叙述用中文

文档的"为什么这样设计 / 怎么使用 / 何时该用 / 不该用"一律中文。

**正例**：
> 这个 hook 在每次 commit 前自动运行，用于校验路径是否符合 R5 规则。

**反例**：
> This hook runs before every commit to validate paths according to R5.
（在中文工作室里这样写会让维护者每次都要做一次心智翻译。）

**适用场景**：
- 所有 `studio/docs/*.md`
- skill / agent / hook / rule 文档的"使用说明"段落
- postmortem 全文
- commit body（commit subject 见 §10 FAQ ①）

---

## 4. R2 · 代码 / 路径 / 命令 / API 用英文

**任何会被机器执行或解析的 token 必须英文。**

**正例**：
```bash
cd studio/docs/
mv ../analysis-report ./reference/
```

**反例**：
```bash
cd 工作室/文档/
移动 ../分析报告 ./参考资料/
```

**包含范围**：
- shell 命令与参数
- 文件路径与目录名
- API 端点与参数名
- 函数调用与变量名
- git 操作（`commit` / `tag` / `branch`）

命名规约：路径 / 文件名 用 **kebab-case**；Python 标识符用 **snake_case**；类名用 **PascalCase**。详见 R5。

---

## 5. R3 · 技术术语保留英文

下列术语在文档与对话中**一律不翻译**：

| 术语 | 不要写成 |
|---|---|
| agent | 代理 / 智能体 |
| skill | 技能 |
| hook | 钩子 |
| commit | 提交 |
| lint | 检查 |
| frontmatter | 头部元数据 |
| postmortem | 事后复盘 |
| rule | 规则（在 `.codebuddy/rules/` 语境下保留 rule） |
| template | 模板（作为目录名保留 template） |

**正例**：
> 这个 agent 在 art-asset-pipeline skill 中被调用，触发 lint hook 后写入 commit。

**反例**：
> 这个智能体在美术资产管线技能中被调用，触发检查钩子后写入提交。

**判断准则**：如果该术语在 `.codebuddy/` 目录结构、外部生态（Claude / Cursor / Aider 等）或工具命令中以英文出现，则保留英文。

---

## 6. R4 · 引用外部内容时保留原文

引用以下内容时**原样保留，不翻译**：
- 引擎官方文档（Godot / Unity / Unreal）
- API 错误信息与堆栈
- 第三方 skill / library 的原始描述
- 命令行输出

**正例**：
> Godot 文档说："Nodes are Godot's building blocks"，因此我们……

**反例**：
> Godot 文档说："节点是 Godot 的构建块"，因此我们……
（翻译后失真，无法反向检索原文。）

**例外**：长段引用后可附中文摘要，但原文必须保留。

---

## 7. R5 · 文件名 / 标识符全英文

**所有文件名、目录名、函数名、变量名、配置 key 一律英文。**

| 类别 | 命名规约 | 示例 |
|---|---|---|
| 目录 | kebab-case | `engine-reference/` `art-asset-pipeline/` |
| Markdown 文件 | kebab-case.md | `language-policy.md` `migration-log.md` |
| Python 文件 | snake_case.py | `text2image.py` `save_key.py` |
| Python 函数 / 变量 | snake_case | `parse_prompt()` `image_url` |
| Python 类 | PascalCase | `ArtDirector` `PromptBuilder` |
| YAML / TOML key | snake_case 或 kebab-case | `primary-language` `max_retries` |

**反例**（一律禁止）：
- `中文文件名.md`
- `素材生成.py`
- `def 解析提示词():`

---

## 8. R6 · frontmatter / 配置字段值用英文

YAML / TOML / JSON 的 **key 与 value 都用英文**。

**正例**：
```yaml
---
name: art-director
type: agent
status: active
description: Coordinates art asset production via timiai-image skill.
---
```

**反例**：
```yaml
---
名称: 美术总监
类型: 代理
状态: 启用中
描述: 通过 timiai-image 技能协调美术资产生产。
---
```

**理由**：frontmatter 是给机器解析的结构化数据，与 R2 同源。`description` 字段虽为人类阅读，但作为元数据仍保持英文，正文中文叙述放在 frontmatter 之后的 markdown body。

---

## 9. R7 · 注释紧贴语境

**代码块内中文注释 + 英文 API 调用是允许的混排模式。**

**正例**：
```python
# 调用 timiai-image 生成英雄立绘，传入风格参考图
result = client.image_edit(
    prompt="hero portrait, fantasy style",  # prompt 必须英文，模型对中文 prompt 表现差
    reference_images=[ref_path],
    quality="high",
)
# 失败时降级到 fallback 模型链
if result.error:
    result = client.image_edit(..., fallback="auto")
```

**反例 1**（注释也英文，降低可读性）：
```python
# Call timiai-image to generate hero portrait with style reference
result = client.image_edit(...)
```

**反例 2**（API 参数中文，机器报错）：
```python
result = client.image_edit(
    提示词="英雄立绘，奇幻风格",  # ❌ 参数名必须英文
)
```

**判断准则**：
- 注释 = 给人看 → 中文（R1）
- API 调用 = 给机器看 → 英文（R2）
- prompt 字符串 = 看模型支持，多模态模型当前对英文 prompt 更稳定，故倾向英文（这是模型限制，非语言策略要求）

---

## 10. 边界场景与 FAQ

### Q1 · commit message 怎么写？

**双通道 commit 规约**（v4 §8.3）：
- **Subject**（首行）：英文 + 通道前缀，如 `[story] add language-policy.md` / `[fix] correct R5 example`
- **Body**（空行后）：中文叙述"为什么改 / 改了什么 / 影响范围"

理由：subject 进入 git log 一行展示，需机器友好；body 给未来的人看，需可读性。

### Q2 · 错误信息要不要翻译？

**不翻译。** 原始错误信息保留英文，便于：
- 反向检索 Stack Overflow / GitHub issues
- 复制粘贴给同事 / AI 助手时不损失上下文

可在错误信息后附中文解释：
> `ModuleNotFoundError: No module named 'PIL'` —— 缺 Pillow 库，跑 `pip install pillow` 即可。

### Q3 · 中英混排长度怎么办？

中英混排会导致行长不均。建议：
- markdown 段落不强制换行，让渲染器处理
- 代码块注释超过 80 列时换行，注释行可长可短
- 表格列宽不强求对齐，markdown 渲染会自适应

### Q4 · timiai-image 这种已有混写 skill 怎么处置？

**已有外部接入 skill 不强制改写，作为"既存事实"豁免。**

`timiai-image` 是用户接入的外部图像生成能力，其内部实现与原始描述按当时风格混写中英文。本策略**仅约束工作室自身新建产物**，不强制重写外部 skill。

但**新建 skill 必须遵守 7 条规则**，包括未来要新建的 `art-asset-pipeline`（其调用 `timiai-image` 时按 R4 引用原 skill 描述即可）。

判断准则：
- 既存外部 skill / library → 保留原样（R4 引用原文）
- 工作室自建 skill / agent / hook → 必须 7 条规则全合规

### Q5 · 日志 / postmortem 用什么语言？

- **`v4-migration-log.md` 等过程日志**：中文叙述（R1）+ 英文路径/命令（R2 / R5）
- **postmortem**：全文中文叙述，引用错误信息保留英文（R4）
- **commit log**：见 Q1

---

## 附录 · 与 v4 规划的关系

本策略是 v4 §9.1 的展开版。如本文件与 §9.1 出现冲突，以 v4 规划为准（本文件需修订对齐）。

未来若需修改 7 条规则，应：
1. 先改 v4 §9.1
2. 同步修改本文件
3. 在 `v4-migration-log.md` 记录修订原因

**校验自动化**：本策略当前**靠人工与 AI 自检**保证。Phase 2+ 计划新增 lint hook 做自动校验（YAGNI 原则，本期不实现）。
