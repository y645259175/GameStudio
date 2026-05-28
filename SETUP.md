# 🚀 新设备部署指南（SETUP.md）

> 本文档指引你（或 AI 助手）如何在一台新电脑上从 GitHub 克隆并还原完整的 GameStudio 开发环境。

---

## 一、环境要求

| 依赖 | 版本 | 用途 |
|------|------|------|
| Git | 2.40+ | 版本控制 |
| Godot | 4.6.2 stable（win64 / macOS / linux 对应版本） | 游戏引擎 |
| Python | 3.10+ | 美术管线脚本 / hook 脚本 |
| CodeBuddy IDE | 最新版 | AI 开发环境（agent/skill/hook 依赖） |

---

## 二、克隆项目

```bash
git clone https://github.com/y645259175/GameStudio.git
cd GameStudio
```

---

## 三、需要手动补充的内容（不在 Git 中）

由于安全性和体积原因，以下内容被 `.gitignore` 排除，需要在每台设备上单独配置。

### 3.1 Godot 引擎（`engine/` 目录）

引擎二进制文件体积约 164 MB，不纳入版本控制。

**操作步骤：**

1. 下载 Godot 4.6.2 stable：https://godotengine.org/download/archive/4.6.2-stable/
2. 在项目根目录创建目录结构：
   ```
   engine/
   └── Godot/
       └── Godot_v4.6.2-stable_win64.exe   ← Windows
       └── Godot_v4.6.2-stable_macos.app   ← macOS（如果是 Mac）
       └── Godot_v4.6.2-stable_linux.x86_64 ← Linux
   ```
3. 确保放置路径与上述一致（项目内脚本和文档引用此路径）

### 3.2 TimiAI API Key（`.timiai_key`）

美术管线（`art-asset-pipeline` skill）使用 TimiAI 图像生成 API，需要 API Key。

**操作步骤（二选一）：**

- **方式 A：文件方式（推荐）**
  ```bash
  # 在项目根目录下执行
  python .codebuddy/skills/timiai-image/scripts/save_key.py <YOUR_API_KEY>
  ```
  这会将 key 保存到 `.codebuddy/skills/timiai-image/.timiai_key`

- **方式 B：环境变量方式**
  ```bash
  # Windows PowerShell
  $env:TIMIAI_API_KEY = "<YOUR_API_KEY>"

  # Linux / macOS
  export TIMIAI_API_KEY="<YOUR_API_KEY>"
  ```

**验证：**
```bash
python .codebuddy/skills/timiai-image/scripts/_check_key.py
# 退出码 0 = OK，3 = 需要提供 key
```

### 3.3 Git 认证（GitHub push 权限）

推荐使用 Git Credential Manager：
```bash
git config --global credential.helper manager
git push  # 首次会弹出登录窗口
```

或使用 SSH：
```bash
git remote set-url origin git@github.com:y645259175/GameStudio.git
```

---

## 四、设备相关路径配置

以下文件使用了**绝对路径**，克隆到新设备后必须修改：

### 4.1 CodeBuddy Hook 脚本路径

**文件：** `.codebuddy/settings.json`

找到 `hook` 配置中的 `command` 字段，把路径改为当前设备的实际路径：

```json
"command": "python <你的实际路径>/GameStudio/.codebuddy/hooks/pre-tool-bash.py"
```

例如：
- Windows: `python D:/Projects/GameStudio/.codebuddy/hooks/pre-tool-bash.py`
- macOS: `python /Users/you/GameStudio/.codebuddy/hooks/pre-tool-bash.py`

### 4.2 Agent Spawn 合约路径

**文件：** `.codebuddy/rules/agent-spawn-contract/RULE.mdc`

搜索 `<PROJECT_PATH>` 相关内容，把 `d:/AI/GameStudio/projects/<name>/game` 改为实际路径。

---

## 五、验证清单

在新设备上完成上述步骤后，按此清单验证：

| # | 检查项 | 验证方法 |
|---|--------|---------|
| 1 | Git 仓库正常 | `git status` 无报错 |
| 2 | Godot 能启动 | 双击 `engine/Godot/Godot_v4.6.2-stable_win64.exe` |
| 3 | 项目能导入 | Godot → Import → `projects/breakout/game/project.godot` → F5 运行 |
| 4 | TimiAI key 就绪 | `python .codebuddy/skills/timiai-image/scripts/_check_key.py` 退出码 0 |
| 5 | Hook 脚本可执行 | CodeBuddy 中触发任意 tool 调用不报路径错误 |
| 6 | Python 可用 | `python --version` 输出 3.10+ |

---

## 六、打包转移（离线场景）

如果新设备无法访问网络，可以将以下内容打包带走：

```
GameStudio-secrets.zip     ← 用于离线部署的补充包
├── engine/
│   └── Godot/
│       └── Godot_v4.6.2-stable_win64.exe
├── .timiai_key             ← TimiAI API Key
└── SETUP-QUICKREF.txt      ← 路径修改提示
```

**制作打包的命令（在当前设备执行）：**

```powershell
# Windows PowerShell
$items = @(
    "engine/Godot/Godot_v4.6.2-stable_win64.exe"
    ".codebuddy/skills/timiai-image/.timiai_key"
)
Compress-Archive -Path $items -DestinationPath "GameStudio-secrets.zip" -Force
```

> ⚠️ **安全警告**：此 zip 包含 API Key，请勿上传到任何公开位置。仅通过安全渠道（如 U 盘、加密传输）转移。

---

## 七、AI 助手部署指令

> 以下内容专为 AI 助手（CodeBuddy / Claude）提供，描述自动化部署步骤。

当 AI 收到"在新设备上部署项目"的请求时，应按以下顺序执行：

1. **确认 Python 版本** ≥ 3.10
2. **确认 Godot 引擎**是否存在于 `engine/Godot/`，不存在则提示用户下载
3. **检查 TimiAI Key**：运行 `_check_key.py`，退出码 3 则提示用户提供 key
4. **修改绝对路径**：
   - 读取 `.codebuddy/settings.json`，将 hook command 中的路径替换为当前工作区路径
   - 读取 `.codebuddy/rules/agent-spawn-contract/RULE.mdc`，替换 `<PROJECT_PATH>` 段
5. **验证**：运行验证清单中的每一项
6. **报告结果**：告知用户哪些通过、哪些需要手动处理

---

## 附录：.gitignore 保护的敏感/大文件

| 模式 | 说明 |
|------|------|
| `engine/` | Godot 引擎二进制（~164 MB） |
| `.timiai_key` | TimiAI API Key 文件 |
| `*.key` / `*.pem` | 各类密钥/证书 |
| `*.secret` | 通用 secret 文件 |
| `.env` / `.env.local` / `.env.*.local` | 环境变量文件 |
| `credentials.json` / `secrets.json` | 凭证配置 |
| `.codebuddy/temp/` / `.codebuddy/logs/` | 临时文件和日志 |
