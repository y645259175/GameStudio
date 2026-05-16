# `.codebuddy/settings.json` · permissions 说明

## 目的

让 CodeBuddy AI agent 在工作室项目里**自动执行常用命令**，不每次都弹审批弹窗中断流程。同时**保留高危命令的人工确认**（git push --force / rm -rf / 读 .env 等）。

## 三层结构

| 字段 | 行为 | 适合放什么 |
|---|---|---|
| `allow` | **自动执行**，不弹弹窗 | 文件操作（Remove/Move/Copy/Read/Write）、Git 日常（status/diff/add/commit）、构建测试（python/godot/npm）、信任的 WebFetch 域名 |
| `ask` | **每次弹审批**让用户确认 | 推送 / 重写历史 / 修改 git config |
| `deny` | **完全禁止** | 敏感文件读取（.env / .timiai_key）、强推 |

## 启动模式

`defaultMode: "acceptEdits"` 表示进入会话默认就是**自动接受编辑模式**：
- 文件 Edit/Write 自动批准
- Bash 命令按 allow/ask/deny 规则判定
- 不影响 IDE GUI 上「自动运行」开关（GUI 开关是更彻底的"全部不问"）

如需更激进（完全跳过权限检查）：改 `"defaultMode": "bypassPermissions"`，但只在受信任的工作区使用。

如需更保守（每次都问）：改 `"defaultMode": "default"`。

## 规则语法（重要）

`Bash(npm run test:*)` — **前缀匹配，不是正则**。`*` 只在末尾起通配符作用。

正确写法：
- ✅ `Bash(git diff:*)` — 匹配所有 `git diff ...` 子命令
- ✅ `Bash(npm run test:*)` — 匹配 `npm run test`、`npm run test:unit` 等
- ❌ `Bash(*git*)` — 不会按预期工作（不是真正的通配）
- ❌ `Bash(git.*)` — 不是正则

文件类（Read/Write/Edit）支持 glob：
- ✅ `Read(./secrets/**)` — 递归
- ✅ `Edit(src/**)`
- ✅ `Read(**/.env)` — 任意层级的 .env

## IDE GUI 开关 vs settings.json 的关系

| 维度 | IDE GUI「自动运行」 | `settings.json` permissions |
|---|---|---|
| 粒度 | 一刀切（开/关） | 命令级精细控制 |
| 持久化 | IDE 客户端本地（不进 git） | 项目内（进 git，团队共享） |
| 推荐 | 单人开发者快速使用 | 团队/项目级标准 |

**两者可以共存**：IDE 开关打开时所有命令直接跑（最宽松），关闭时 fallback 到 settings.json 规则。

## 维护约定

- 新增第三方平台 WebFetch 域名 → 加到 `allow` 的 `WebFetch(...)` 列表
- 新增构建/测试工具命令 → 加到 `allow` 的 `Bash(...)`
- 新增需要保护的敏感路径 → 加到 `deny`
- 修改后 commit 让团队共享

## 引用

- 官方文档：https://www.codebuddy.ai/docs/zh/cli/settings
- 权限模式：https://copilot.tencent.com/docs/cli/interactive-mode
- Bash 沙箱：https://www.codebuddy.ai/docs/zh/cli/bash-sandboxing
