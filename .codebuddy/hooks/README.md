# Hooks · 工作室 hook 集合

> **用途**：5 个 hook 的导航与启用指南。Phase 1 期间仅起草不启用，Phase 2 git init 后按需挂载。
>
> **关联文档**：v4 规划 §6.1.1（hooks 5 件清单）

---

## hook 总览

| # | 文件 | 类型 | 触发 | 启用状态 |
|---|---|---|---|---|
| 1 | `validate-commit.sh` | git pre-commit | 每次 commit 前 | Phase 2+ 启用，待挂载 |
| 2 | `pre-commit-lite.sh` | git pre-commit（替代）| 每次 commit 前 | Phase 2+ 启用，待挂载 |
| 3 | `log-agent.sh` | AI 框架钩子 | skill / agent 事件 | 骨架（待集成 IDE 事件链）|
| 4 | `session-start.py` | **SessionStart** | 新会话启动 | **✅ 已启用** · 精简引导（~1KB）|
| 5 | `user-prompt-route.py` | **UserPromptSubmit** | 用户每次发送 prompt | **✅ 已启用** · 按关键词精准注入 |
| 6 | `pre-tool-bash.py` | **PreToolUse** | 任何工具调用前 | **✅ 已启用** · image_gen/删除拦截 + 自动 allow |
| 7 | `detect-gaps.sh` | cli 工具 | 手动 / 定时 | 骨架（指向 skill）|

> 3 层 hook 设计（2026-05-19 升级）：
> - Layer 1（SessionStart）：极简引导，告诉 main agent **有什么资源、什么场景查哪里**
> - Layer 2（UserPromptSubmit）：识别 prompt 关键词，**按场景精准注入**相关 AP / SOP / 命令
> - Layer 3（PreToolUse）：在 image_gen / Remove-Item 等高风险工具调用前**强提示**
>
> 设计理由：避免 SessionStart 全量注入（占上下文 + 容易被遗忘），改为事件驱动的精准提醒。

---

## Phase 2+ 启用步骤（Windows / Git Bash）

```powershell
# 方式 A：用 git 配置 hooksPath 指向工作室目录
cd D:\AI\GameStudio
git config core.hooksPath .codebuddy/hooks

# 注意：此方式要求 hook 文件名与 git 钩子名一致（如 pre-commit）
# 实际操作：建立软链接或重命名
# 推荐做法见方式 B
```

```powershell
# 方式 B：复制法（更直观）
Copy-Item .codebuddy\hooks\pre-commit-lite.sh .git\hooks\pre-commit
# Git for Windows 会自动通过 shebang #!/usr/bin/env bash 调用 bash 解析
```

```powershell
# 切换到强校验
Copy-Item .codebuddy\hooks\validate-commit.sh .git\hooks\pre-commit -Force
```

---

## 行尾符 / 编码注意事项

bash 脚本必须用 **LF 行尾**，否则 git bash 报错 `$'\r': command not found`。

仓库根建议加 `.gitattributes`：
```
*.sh text eol=lf
```

VSCode / CodeBuddy 默认就是 LF，无需特殊配置。

---

## 故障排查

| 现象 | 原因 | 解决 |
|---|---|---|
| `$'\r': command not found` | 文件是 CRLF | 转 LF：`dos2unix file.sh` 或 VSCode 右下角切 LF |
| `Permission denied` | Linux/macOS 缺执行权限 | `chmod +x .git/hooks/pre-commit` |
| `bash: command not found` | Windows 无 git bash | 装 Git for Windows |
| `jq: command not found` | validate-commit 缺 jq | `choco install jq` 或 `scoop install jq` |

---

## 测试 hook

每个 hook 都支持 `--dry-run`（如适用）：
```bash
bash .codebuddy/hooks/validate-commit.sh --dry-run
bash .codebuddy/hooks/pre-commit-lite.sh --dry-run
```

---

## Phase 2+ Review Points

- [Phase 1.5+ TODO] log-agent / session-start / detect-gaps 三个骨架从 `studio/reference/my-game/` 抄完整版
- [Phase 2+ TODO] 评估是否补 PowerShell (.ps1) 版（视 Windows 实战体验）
- [Phase 2+ TODO] 集成到 IDE / CI 的事件触发链路
