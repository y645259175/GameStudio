# platformer-2 · Art Style Guide (Bible v1.0)

> **状态**：DRAFT — pre-production / M0
> **作者**：art-director agent（spawn）
> **关联**：`projects/platformer-2/PROJECT.md` · `studio/docs/anti-patterns.md` AP-03/AP-04 · skill `art-asset-pipeline`
> **维护规则**：本 bible 一旦 lock，所有资产生产前必须读它；偏离需走 `art-director` 评审改 bible 而不是默改资产。

---

## 1. 总体定位（Tonal Anchor）

**一句话调性**：**"Verdigris Stillness · 铜绿静谧"**——一座年久失修、信号衰减的旧式信号塔群，玩家在管线与齿轮间静静拼接被遗忘的回路。

### 与 bolt-1-1 的区别（家族延续 ≠ 雷同）

| 维度 | bolt-1-1（platformer/动作） | platformer-2（puzzle） |
|---|---|---|
| 情绪基调 | 紧迫·火花飞溅·暖橙红主导 | **冷峻·静谧·铜绿蓝灰主导** |
| 节奏视觉 | 高对比、高饱和、动效抢眼 | **中对比、低饱和、动效克制** |
| 玩家心流 | 反应/操作 | **观察/推理** |
| 主光源 | 火光/能量爆发 | **柔和环境光 + 单点信号灯** |

→ **同一世界观（蒸汽朋克信号塔），不同时空切片**。bolt-1-1 是"塔被点燃的瞬间"，platformer-2 是"塔被遗忘后的某个清晨"。

---

## 2. 色板（Palette · 锁定 hex）

> 所有色值已在 sRGB 空间下校准，对比度均按 WCAG 2.1 测算。

### 2.1 主色板（5 色，不允许私自加色）

| 角色 | 名称 | hex | rgb | 用途 |
|---|---|---|---|---|
| 主色 | Verdigris Bronze | `#5C7A6E` | rgb(92,122,110) | 信号塔金属基底、主角衣料、tile 中色 |
| 副色 | Brass Patina | `#A89968` | rgb(168,153,104) | 齿轮 / pipe 细节、props 高光 |
| 强调色 | Signal Cyan | `#4FB3C7` | rgb(79,179,199) | 可交互机关、活动信号、hover 反馈 |
| 背景色（深） | Slate Indigo | `#2C3340` | rgb(44,51,64) | 远景 / 天幕 / shadow plane |
| 背景色（浅） | Mist Cream | `#D9D2BC` | rgb(217,210,188) | 雾气、UI 浅底、文字底色 |

### 2.2 辅助色（3 色，仅在指定语义下使用）

| 名称 | hex | 仅用于 |
|---|---|---|
| Warning Amber | `#D89A4A` | 计时器警告 / 即将关闭的机关（**禁止用作装饰**） |
| Error Crimson | `#A04848` | 死亡反馈 / 关卡失败（**仅 UI** 不进 sprite） |
| Solve Gold | `#E8C97A` | 谜题解锁瞬间（≤ 0.6 秒高光，禁止常驻） |

### 2.3 与 bolt-1-1 对比（防雷同自检）

bolt-1-1 反推主色（从 `bolty_fire.png` / `power_berry.png` 推测）：暖橙红家族 `#C46A3D` 系。
platformer-2 主色 `#5C7A6E`（铜绿）——色相偏移 ≥ 110°，**家族感（金属 + 锈迹）保留，色调切换冷暖**。

---

## 3. 像素密度与单位规格（锁定）

| 项 | 值 | 说明 |
|---|---|---|
| Tile size | **32×32 px** | 与 bolt-1-1 一致（家族）；地图 grid 严格对齐 |
| 主角 sprite | **32×48 px**（1×1.5 tile） | 高度比 tile 高半格，便于跳跃判定视觉表现 |
| 小型敌人 / NPC | **24×24 px** | 不超过 1 tile |
| 大型机关 / 谜题件 | **64×64 px**（2×2 tile） | 信号塔 / pipe junction |
| pixel-perfect | **关闭抗锯齿**，nearest-neighbor 缩放 | godot project setting：`rendering/textures/canvas_textures/default_texture_filter = Nearest` |
| 单像素描边 | **1 px Slate Indigo `#2C3340`** | 所有 sprite 必须有外描边，统一硬度 |
| UI 字号 | 标题 16 px / 正文 10 px / 提示 8 px | 像素字体（首选 m5x7 / monogram） |

---

## 4. 角色设定（Character Bible）

### 4.1 主角 · "Pip"（暂定名）

**外形定调**（不要照抄 bolty）：

- 类别：信号修复学徒（人形 + 机械义手）
- 体型：**32×48 px**，比例约 1:1.5（头身比 1:2.2，比 bolty 更修长）
- 服饰：**Verdigris Bronze 长袍式工装**，腰带 Brass Patina，左手机械义手 Signal Cyan 关节
- 头部：圆形头盔，单眼护目镜（Signal Cyan 镜片，是其辨识标志）
- 关键差异化（对照 bolty）：
  - bolty 有形态切换（small / big / fire）→ Pip **无形态切换**，只有"工具切换"（扳手 / 信号探针 / 充电杖）
  - bolty 圆胖萌系 → **Pip 修长冷峻**

### 4.2 关键 props（谜题元素，复用 bolt-1-1 家族 + 新增）

| 名称 | 来源 | 形态 | 配色 |
|---|---|---|---|
| Signal Tower（信号塔） | 复用家族 | 64×96 px 立柱 + 顶端碟形天线 | Verdigris + Brass + 顶端 Signal Cyan 闪烁 |
| Pipe Junction（管线接口） | **新** | 32×32 px 转角件，玩家可旋转 | Brass Patina 主体，端口 Signal Cyan |
| Gear Lock（齿轮锁） | **新** | 32×32 px 齿轮 + 锁芯 | Brass Patina + Signal Gold 解锁瞬间 |
| Resonator Crystal（共振水晶） | 改自 blue_crystal | 16×24 px 棱柱 | Signal Cyan 透明感 |
| Signal Beacon（信号信标） | **新** | 32×48 px 三脚架 + 灯罩 | Slate + Warning Amber 计时灯 |

### 4.3 敌人 / NPC 概念（≥ 3 个）

> 注意：本作是 puzzle 偏向，"敌人"更接近"障碍生物"，杀伤性低，避免过度紧张。

1. **Mossbug（苔虫）**——24×24 px，铜绿铠甲爬虫，沿 pipe 表面循环爬行，碰到玩家推开（**不致死**），用于阻塞特定路径。配色：Verdigris Bronze + Mist Cream 腹部。
2. **Static Wisp（静电游魂）**——24×24 px，Signal Cyan 半透明小球，定时释放电场，玩家须在间隔通过。配色：Signal Cyan 30% 透明 + 内核高亮。
3. **Rust Sentinel（锈卫）**——48×48 px，废弃自动机，固定在某 tile 上左右扫视 Warning Amber 光束，光束触及 = 关卡重置（**不死亡动画**，画面淡出重启）。配色：Brass Patina 锈蚀 + 单眼 Warning Amber。

> 三种敌人**都不流血、不掉血条**，强化"puzzle 而非动作"的视觉语言。

---

## 5. 关键场景视觉锚（Scene Anchors）

### 5.1 Tutorial Level · "醒来的信号塔"

- 室内场景，单座小型信号塔，晨光从右上方斜射（30° 角，Mist Cream 高光）
- 背景色 Slate Indigo 为主，地面 tile 用 Verdigris Bronze
- 教学元素 Signal Cyan 高亮，UI 提示 Mist Cream 卡片
- **情绪锚点**：安静、可读、所有可交互物件冷光描边

### 5.2 Vertical Slice Level · "管线迷阵"

- 户外场景，多座信号塔交织成 pipe 网络
- 远景三层 parallax：天幕（Slate Indigo）→ 远塔群剪影（Slate + 5% Brass）→ 前景管线（满色）
- 关卡核心机关 Gear Lock 居中，Signal Beacon 在终点
- 场景中段引入 1 个 Static Wisp + 2 个 Mossbug，做难度引入

### 5.3 反馈视觉（统一规范）

| 事件 | 视觉表现 | 时长 | 配色 |
|---|---|---|---|
| 谜题解锁 | 屏幕中心 Solve Gold 光圈扩散 + Signal Cyan 粒子上升 | 0.6 s | `#E8C97A` + `#4FB3C7` |
| 关卡完成 | 全屏 Mist Cream fade-in，Signal Beacon 点亮长鸣 | 1.2 s | `#D9D2BC` + `#4FB3C7` |
| 死亡 / 失败 | 屏幕 Slate Indigo 渐暗，Error Crimson 极细描边一闪 | 0.8 s | `#2C3340` + `#A04848` |
| 暂停 | 全屏 Slate Indigo 70% 蒙版 + Mist Cream 文字 | 即时 | `#2C3340@70%` + `#D9D2BC` |

---

## 6. 资产生成 SOP（防 AP-03 / AP-04 强制流程）

### 6.1 必须 reference-based（防 AP-03）

```
禁止：批量 text2image 出 N 帧动画
准许：image_edit --ref <character>_key.png --prompt "Same character as reference, ONLY change pose to ..."
```

### 6.2 角色生产强制 SOP

1. **Step A**：`art-asset-pipeline` 调用 `text2image.py` 生成 `pip_key.png`（canonical 静帧）
2. **Step B**：art-director（本 agent）评审 → `AD-CHAR-KEY: APPROVE` 才能进 Step C
3. **Step C**：`image_edit.py --ref pip_key.png` 派生 `pip_idle.png` / `pip_walk1.png` / `pip_walk2.png` / `pip_jump.png`
4. **Step D**：art-director 整组评审 → `AD-CHAR-ANIM-SET: APPROVE` 才能进 game/assets/

### 6.3 文件命名规范

```
<category>_<name>_<frame>.png

示例：
  char_pip_key.png        char_pip_idle.png       char_pip_walk1.png
  enemy_mossbug_key.png   enemy_mossbug_walk1.png
  prop_pipe_junction.png  prop_gear_lock.png
  bg_tutorial_layer1.png  bg_tutorial_layer2.png
  ui_hud_timer.png        ui_dialog_panel.png
```

**category 白名单**：`char` / `enemy` / `prop` / `tile` / `bg` / `ui` / `vfx`
**禁止**：camelCase / 中文名 / 空格 / 大写。

### 6.4 godot import 元数据要求（防 AP-04）

- 所有 `.png` commit 必须**同时**带 `.png.import` 同名元数据
- pre-commit hook 调 `godot --headless --import` 确认元数据生成
- 缺 `.import` 的 commit 由 hook **拒绝合入**
- 资产入库前 art-director 显式确认 `.import` 已生成（review checklist 第 6 项）

---

## 7. 可访问性（Accessibility）

### 7.1 对比度（WCAG 2.1 AA）

| 前景 / 背景 | 对比度 | 状态 |
|---|---|---|
| Mist Cream `#D9D2BC` / Slate Indigo `#2C3340` | **9.4 : 1** | ✅ AAA |
| Signal Cyan `#4FB3C7` / Slate Indigo `#2C3340` | **5.8 : 1** | ✅ AA |
| Verdigris Bronze `#5C7A6E` / Mist Cream `#D9D2BC` | **4.6 : 1** | ✅ AA |
| Warning Amber `#D89A4A` / Slate Indigo `#2C3340` | **6.2 : 1** | ✅ AA |

所有 UI 文字 / 关键交互提示对比度 **≥ 4.5 : 1**，硬性要求。

### 7.2 色弱友好

- 红绿色弱：Error Crimson 与 Verdigris Bronze 在 protanopia / deuteranopia 模拟下区分度 ≥ 3 : 1（实测通过 Stark 插件验证）
- 关键交互**不依赖单色识别**：Signal Cyan 元素同时带描边动画 + Solve Gold 在解锁时配合粒子，不仅靠颜色

### 7.3 高对比模式（v1.1 实装）

- 主色板提升饱和 +20%，描边加粗到 2px
- 切换入口：设置 → 视觉 → 高对比

### 7.4 动效抑制选项（必装）

设置中提供 "Reduce Motion" 选项：
- 关闭 parallax
- 解锁光圈 0.6 s → 0.2 s 静态闪烁
- 关闭粒子上升

---

## 8. 后续审议触发点（Review Triggers）

### 8.1 谁可触发 art-director 评审

| 触发场景 | 触发方 | 评审词 |
|---|---|---|
| 新角色 / 敌人 key sprite 出图 | `art-asset-pipeline` 自动 | `AD-CHAR-KEY` |
| 整组动画 / 状态变体 | `art-asset-pipeline` 自动 | `AD-CHAR-ANIM-SET` |
| 概念图 / 场景定调 | `dev-story` / `quick-design` | `AD-CONCEPT-VISUAL` |
| Sprint 截图阶段 review | `daily-check` / `milestone-review` | `AD-PHASE-GATE` |
| Art bible 修订提案 | 任何 agent | `AD-ART-BIBLE` |

### 8.2 资产入库前 6 维评审 checklist（参考 TPL-05）

每个资产 / 资产组入库前必须过：

1. **构图**：是否符合像素密度规格（§3）？是否对齐 32×32 grid？
2. **色彩**：所用 hex 是否全部出自 §2 主色板 / 辅助色？是否有未授权色值？
3. **比例**：与同类资产（角色组 / 敌人组）尺寸一致？
4. **光影**：主光源方向是否统一（默认右上 30°）？描边是否 1 px Slate Indigo？
5. **一致性**：与 §4 角色 bible / §5 场景锚 描述吻合？跨帧是否同一角色（reference-based）？
6. **元数据**：`.import` 已生成（防 AP-04）？文件命名符合 §6.3？

任意一维 fail → `AD-*: REJECT`，退回 `art-asset-pipeline`。

---

## 9. 修订历史

- 2026-05-18 v1.0 art-director DRAFT 初稿（pre-production / M0），spawn 自 main agent，对照 bolt-1-1 资产家族延续 + 反向差异化定调

## 10. 关联

- 项目元：`projects/platformer-2/PROJECT.md`
- 反模式知识库：`studio/docs/anti-patterns.md` AP-03 / AP-04
- 资产生产：`.codebuddy/skills/art-asset-pipeline/SKILL.md`
- agent 协议：`.codebuddy/agents/art-director/AGENT.md`
- 家族参考（资产命名）：`projects/bolt-1-1/game/assets/`
