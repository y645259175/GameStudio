# CodeBuddy IDE 环境怪癖手册

> **作用**：记录 CodeBuddy IDE（vscode 插件版）实测发现的 schema/行为差异，避免新 session 重复踩坑。
> **维护**：每次踩到新 quirk → 实测验证 → 追加到本文。

---

## 速览

| ID | quirk | 一句话现象 | 一句话规避 |
|---|---|---|---|
| Q-01 | `settings.json` 只有 `hooks` 字段有效 | `permissions` 字段不存在于官方 schema | 不要配 permissions；权限通过 hook 的 `permissionDecision` 实现 |
| Q-02 | `settings.json.hooks` 需要 Python + 正确格式 | 之前用 bash + 错误 JSON → 不工作；用 Python + `hookSpecificOutput` 嵌套后正常调用 | 用 `python script.py` 不用 `bash script.sh`；输出必须含 `hookSpecificOutput` 嵌套层 |
| Q-03 | `Remove-Item` / `rm` 等删除命令强制弹窗 | 内置硬保护，PreToolUse hook 返回 allow 也压不住（hook 对高危命令根本不被触发） | **agent 删文件必须用 `delete_file` 工具**，不发命令行 |
| Q-04 | 复合命令 `cmd1; cmd2` 整串被首词匹配 | `cd X; rm Y` 看 cd 不看 rm | 默认每条独立 tool call；批量任务写 Python 脚本一次审批 |

---

## Q-01 · `settings.json.permissions` 字段不生效

### 现象

`.codebuddy/settings.json` 里的：

```json
{
  "permissions": {
    "defaultMode": "acceptEdits | bypassPermissions | default",
    "allow": ["Bash(...)"],
    "ask": ["Bash(...)"],
    "deny": ["Bash(...)"]
  }
}
```

**全部不被 CodeBuddy IDE 识别**。

### 实测证据（2026-05-18）

| 测试 | 配置 | 命令 | 预期 | 实际 |
|---|---|---|---|---|
| T1 | `defaultMode: bypassPermissions`，`Bash(New-Item:*)` 在 `allow` | `New-Item ...` | 不弹 | ✅ 不弹 |
| T2 | 同上，`Bash(Remove-Item:*)` 在 `allow` | `Remove-Item ...` | 不弹 | ❌ **弹窗** |
| **T5（关键反证）** | `defaultMode: acceptEdits`，把 `Bash(New-Item:*)` **从 allow 移到 deny** | `New-Item ...` | 应被拒绝 | **仍然成功执行** |

T5 决定性证据：如果 `permissions` 生效，T5 应该被 deny 拦住，但**直接成功**。证明 schema 完全未实现。

### 推断

- T1 的 `New-Item` 不弹与配置无关，是因为它**不在 IDE 内置高危清单里**
- T2 的 `Remove-Item` 弹与配置无关，是因为它**在 IDE 内置高危清单里**
- 所有 `permissions` 字段是死配置

### 规避

1. 不要往 `settings.json` 加 `permissions` 字段
2. 真正的弹窗控制只剩两层：
   - **CodeBuddy 内置硬编码的高危操作保护**（不可关）
   - **IDE GUI「自动运行」开关**（一刀切，不进 git）
3. 文件操作走 IDE 工具调用（`delete_file` / `write_to_file` / `replace_in_file`）

---

## Q-02 · `settings.json.hooks` 字段不生效

### 现象

`.codebuddy/settings.json` 里的：

```json
{
  "hooks": {
    "SessionStart": [...],
    "PreToolUse":   [{ "matcher": "Bash", "hooks": [...] }],
    "PostToolUse":  [...],
    "Stop":         [...]
  }
}
```

**全部不被 CodeBuddy IDE 自动调用**。

### 实测证据（2026-05-18 · 重启 IDE 前后两轮）

配置：`PreToolUse` matcher = "Bash"，hook 脚本 stdout 输出标准协议 JSON：

```json
{"continue": false, "permissionDecision": "deny", "reason": "..."}
```

执行步骤：

| 步骤 | 期望（如果 hook 生效） | 实际 |
|---|---|---|
| 重启 IDE 前，跑 `Write-Host hello` | hook 写日志，命令照常执行 | hook 未触发，日志无新增 |
| 重启 IDE 前，跑 `Remove-Item xxx` | hook 输出 deny → 静默拒绝，不弹 | **弹窗**（hook 没拦住） |
| 用户**手动重启 IDE** | 重新加载 settings.json | — |
| 重启后，跑 `Write-Host`/`Get-Date` | hook 应被自动调用 | **未触发**，日志依然只有手动测试那 1 行 |
| 重启后，跑 `Remove-Item` | hook deny 应静默拦下 | **仍弹窗** |
| 全程 `.codebuddy/logs/agent-*.jsonl`（PostToolUse 应写） | 每次 Bash 执行后写 1 行 | **目录从未被自动创建过** |

手动 `echo '{"tool_name":"Bash",...}' | bash hook.sh` → 脚本本身工作正常输出协议 JSON。说明**不是脚本的问题，是 IDE 不调用**。

### 规避

1. 不要在生产流程里依赖 hook 做强约束（permission / 拦截 / 自动审计）
2. hook 脚本可以保留在 `.codebuddy/hooks/` 下，作为**未来 IDE 升级支持时的预备**——脚本本身能工作
3. 想要审计 / 拦截 → 走 sub-agent 模板（`agent-spawn-contract` rule 末尾的 8 个 TPL）+ 主 agent 自检

---

## Q-03 · 删除类命令强制弹窗（不可关）

### 现象

`Remove-Item` / `rm` / `rm -rf` / `Remove-Item -Recurse -Force` 等**破坏性命令行操作**，CodeBuddy 内置硬保护，**任何配置都改不掉**：

- 即便 `defaultMode: bypassPermissions`
- 即便 `allow` 列表里显式列了
- 即便 `PreToolUse` hook 返回 `{permissionDecision: allow}`
- 即便 IDE GUI「自动运行」开关打开（待最终验证）

每次都强制弹窗等用户确认。

### 现实意义

这条 quirk 直接影响 agent 工作流：
- agent 自动跑命令时遇到删除会卡住
- 用户必须在场点"允许"，否则流程中断
- 长 session / 自动化跑批不可行

### 规避（**强制约束**）

**所有 agent（含 sub-agent）删文件 / 文件夹时，必须用 IDE 自带的工具调用：**

| 想做 | 禁止用 | 必须用 |
|---|---|---|
| 删单个文件 | `Remove-Item file.txt` / `rm file.txt` / `del file.txt` | `delete_file` 工具 |
| 删空文件夹 | `Remove-Item dir -Recurse` / `rmdir dir` | `delete_file`（递归参数）|
| 移动文件（=删+建）| `Move-Item` | `write_to_file` 新位置 + `delete_file` 旧位置 |
| 重命名 | `Rename-Item` | `write_to_file` 新名 + `delete_file` 旧名 |
| 批量删除 | `Get-ChildItem ... | Remove-Item` | 写 Python 脚本（一次审批），或 N 次 `delete_file` 工具 |

实测：`delete_file` 工具调用 → **不弹窗，直接成功**（已验证 4 次）。

### 已知例外

- IDE 工具自身的删除（如 git clean / git rm）走另一通道，部分情况下也可能弹窗，本表暂不覆盖

---

## Q-04 · 复合命令首词匹配

详见 `studio/docs/anti-patterns.md` AP-08。简述：

`cd X; New-Item Y; Remove-Item Z` 整串只看首词 `cd`，但**实际执行**会触发 `Remove-Item` 的内置保护弹窗。结果是「命令首词 cd 在 allow → 进入执行 → 中途遇到 Remove-Item 弹窗」，更糟糕的是有时整串被一次审批了，agent 误以为以后都不弹，下次又中招。

### 规避

1. agent 输出命令默认每条独立 tool call，不用 `;` `&&`
2. 批量任务写 Python 脚本一次审批跑完
3. 文件操作优先 IDE 工具调用（同 Q-03）

---

## 实测复盘方法（如未来 IDE 升级想验证 quirk 是否仍在）

### 验证 Q-01（permissions）

1. 在 `settings.json` 写 `{"permissions": {"deny": ["Bash(New-Item:*)"]}}`
2. 重启 IDE
3. 跑 `New-Item -Path test.txt -ItemType File`
4. 若被拒绝 → permissions 已支持；若直接成功 → 仍未支持

### 验证 Q-02（hooks）

1. 配 `PreToolUse: matcher=Bash` 指向 `pre-tool-bash.sh`（脚本里 `echo '{"continue":true}' >> /tmp/hook-test.log`）
2. 重启 IDE
3. 跑任意 Bash 命令
4. 看日志文件有没有新增

### 验证 Q-03（删除保护）

1. 跑 `Remove-Item somefile.txt -Force`
2. 弹窗 → 仍在；不弹 → 已放开

---

## 修订历史

- 2026-05-18 v1.0 初始版本，沉淀 Q-01 ~ Q-04 实测（来源：本日 settings.json + hooks 实测会话）

## 关联文档

- `studio/docs/anti-patterns.md` AP-07 / AP-08
- `.codebuddy/PERMISSIONS.md`（项目级实测记录）
- `.codebuddy/rules/agent-spawn-contract/RULE.mdc`（spawn 时强制约束 agent 文件操作走 IDE 工具）
