# Hooks · 工作室 hook 集合

> **用途**：5 个 hook，覆盖 git 提交校验 + CodeBuddy AI 生命周期事件。
>
> **注册位置**：`.codebuddy/settings.json`（CodeBuddy hook）+ `git config core.hooksPath`（git hook）

---

## hook 总览

| # | 文件 | 事件类型 | 触发时机 | 功能 | 状态 |
|---|---|---|---|---|---|
| 1 | `validate-commit.sh` | git commit-msg | 每次 git commit | 校验 commit message 格式（[story]/[fix]/[refactor]/[chore]） | ✅ 完整 |
| 2 | `pre-commit-lite.sh` | git pre-commit | 每次 git commit 前 | 大文件 / trailing whitespace / CRLF 警告（不阻塞） | ✅ 完整 |
| 3 | `log-agent.sh` | CodeBuddy PostToolUse | AI 每次调完工具后 | 记录工具调用日志到 session-logs/ | ✅ 完整 |
| 4 | `session-start.sh` | CodeBuddy SessionStart | 新会话开始 | 记录会话元信息 + 检测项目 phase | ✅ 完整 |
| 5 | `detect-gaps.sh` | CodeBuddy Stop | AI 完成一轮响应后 | 轻量检测 GDScript 改动是否需要同步 GDD/数值表 | ✅ 完整 |
| 6 | `validate-assets.sh` | git pre-commit | 美术/音频文件 commit 前 | 命名/扩展名/尺寸校验（错误阻塞 / 警告不阻塞） | ✅ 完整 |

## 启用方式

### Git Hook（1-2）

```powershell
git config core.hooksPath .codebuddy/hooks
```

### CodeBuddy Hook（3-5）

已在 `.codebuddy/settings.json` 中注册，下次新会话自动生效。

## 日志位置

CodeBuddy hook 产生的日志写入 `.codebuddy/session-logs/session-<id>.log`，格式：

```
[2026-05-15T13:14:00Z] SESSION_START id=abc123 cwd=/path/to/GameStudio
[2026-05-15T13:14:05Z] TOOL=write_to_file TARGET=projects/breakout/game/scripts/main.gd
[2026-05-15T13:14:06Z] TOOL=execute_command TARGET=cd d:\AI\GameStudio; git add -A...
```

日志文件已 gitignore（不进版本控制）。

## Windows 兼容

这些 .sh 脚本需要 bash。你的系统 bash 位于：
```
C:\Users\boyiyang.BOYIYANG-PC4\scoop\apps\git\current\bin\bash.exe
```

CodeBuddy 的 hook 系统会自动通过 `bash` 调用。如果遇到找不到 bash 的问题，确保 Git for Windows 的 bin/ 在 PATH 中。
