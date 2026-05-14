---
name: quick-fix
description: Light-channel quick-fix workflow for bugs, refactors, and small changes. Use when user says "修个 bug / 小改一下 / quick fix / refactor / 改个错". Skips full story flow but still requires test + reviewer for non-trivial changes. Uses [fix] / [refactor] / [quick] commit tags.
allowed-tools: read_file, write_to_file, list_dir, execute_command, search_content, replace_in_file
disable: false
---

# quick-fix · 轻通道快速修复

## 何时加载

- 不值得开 story 的小问题（改 1-2 文件 / < 30 分钟）
- 编译错 / 类型错 / typo / 小重构
- 用户说"小修一下" / "fix this"

**不加载场景**：影响 ≥ 3 文件 / 涉及业务逻辑 / 影响 AC → 走 `dev-story`；架构 → `architecture-decision`。

## 输入契约

| 输入 | 来源 | 必需 |
|---|---|---|
| 问题描述（1 句话）| 用户 | ✅ |
| 错误日志 / bug 现象 | 用户或 IDE | 推荐 |
| 受影响文件路径 | 推断或用户指定 | 推荐 |

## 流程

### Step 1 · 范围判断

3 问：
1. 改 ≥ 3 文件？
2. 影响某个 story 的 AC？
3. 引入新依赖 / 改公共接口？

任一 YES → 升级 `dev-story`。

### Step 2 · 定位

- 用户给了堆栈 → 直接读对应文件
- 没给 → 用 `search_content` 找症状关键字

### Step 3 · 委托 debugger 或 refactorer

| 类型 | agent | tag |
|---|---|---|
| bug | `debugger` (sonnet) | `[fix]` |
| 小重构 | `refactorer` (sonnet) | `[refactor]` |
| 杂项（typo / 小整理）| `engineer` (sonnet) | `[quick]` |

### Step 4 · 修复

写代码。如 godot 项目，跑：
```
godot --headless --check-only --path projects/<name>/game --quit
```

### Step 5 · 最小测试（按需）

| 改动类型 | 是否需测试 |
|---|---|
| typo / 注释 | ❌ |
| 函数行为修改 | ✅ 至少 1 个单测 |
| 重构 | ✅ 跑既有测试全绿 |

### Step 6 · review（按需）

| 改动行数 | 是否需 reviewer |
|---|---|
| < 10 | ❌ 自检即可 |
| 10-50 | ✅ reviewer 必跑 |
| > 50 | 强制升级 `dev-story` |

### Step 7 · commit

按 `commit-discipline` rule：

```
[fix] <project>: <30 字内描述>

- 根因
- 验证方式
```

或 `[refactor]` / `[quick]`。

## 输出契约

| 字段 | 内容 |
|---|---|
| `verdict` | `FIXED` / `ESCALATED_TO_DEV_STORY` |
| `commit_sha` | hash |
| `files_changed` | 1-2 个 |
| `tag_used` | fix/refactor/quick |

## 调用的 agent

- `debugger` (sonnet) / `refactorer` (sonnet) / `engineer` (sonnet)
- 必要时 `reviewer` (sonnet)

## 加载的 rule

- `commit-discipline`（轻通道 tag）
- `language-policy`

## 失败 / 降级

| 异常 | 策略 |
|---|---|
| Step 1 范围超阈 | 立即升 `dev-story` |
| 修了但 godot 校验报错 | debugger 再排查 |
| 改动暴露了更深 bug | 暂存 + 立 story 跟进 |

## 验收标准

- commit tag 正确（fix/refactor/quick 之一）
- 改动行数 ≤ 50（否则应升级）
- 不破坏既有测试

## Known Limitations

- 范围判断主观，可能误判应升级的修复
- 无强制单测覆盖（依赖 agent 判断）
