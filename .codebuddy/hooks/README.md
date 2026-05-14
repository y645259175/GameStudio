# Hooks · 工作室 hook 集合

> **用途**：5 个 hook 的导航与启用指南。Phase 1 期间仅起草不启用，Phase 2 git init 后按需挂载。
>
> **关联文档**：v4 规划 §6.1.1（hooks 5 件清单）

---

## hook 总览

| # | 文件 | 类型 | 触发 | 启用时机 | Phase 1 状态 |
|---|---|---|---|---|---|
| 1 | `validate-commit.sh` | git pre-commit | 每次 commit 前 | Phase 2+ 启用 | 完整实现 |
| 2 | `pre-commit-lite.sh` | git pre-commit（替代）| 每次 commit 前 | Phase 2+ 启用 | 完整实现 |
| 3 | `log-agent.sh` | AI 框架钩子 | skill / agent 事件 | Phase 1.5+ 启用 | 骨架 |
| 4 | `session-start.sh` | AI 框架钩子 | 新会话启动 | Phase 1.5+ 启用 | 骨架 |
| 5 | `detect-gaps.sh` | cli 工具 | 手动 / 定时 | Phase 2+ 启用 | 骨架（指向 skill）|

> 1 / 2 二选一：`validate-commit.sh` 强校验阻塞 / `pre-commit-lite.sh` 轻量警告不阻塞。建议项目早期用 lite，进入 production stage 后切换强校验。

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
