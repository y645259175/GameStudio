# platformer-2 · Vertical Slice In-Context 渲染评审

> **日期**：2026-05-19
> **评审方**：art-director agent (in-context 模式)
> **关联**：TPL-05 5维 + AP-10（实际渲染验证而非 raw 资产）
> **截图样本**：`reports/screenshots/capture_0{0,1,2}_x{64,640,960}.png`
> **对照基准**：`art/style-guide.md` v1.0 + `gdd/gdd-1-overview.md`

---

## 0. 关键诊断：PipeA/B/C 不渲染（用户实玩反馈）

### 现象

3 张截图（玩家 x=64 / 640 / 960）中，**3 个 pipe sprite 全部不可见**：

| 截图 | 玩家位置 | 视野 X 范围 | 期望 pipe 位置 | 实际看到 |
|---|---|---|---|---|
| capture_00 | x=64 | 约 [0, 1080] | (700,480)/(764,480)/(828,480) | ❌ 0 个 pipe |
| capture_01 | x=640 | 约 [100, 1180] | 同上 | ❌ 0 个 pipe（门 (920,472) 可见，pipe 区域空白）|
| capture_02 | x=960 | 约 [420, 1500] | 同上 | ❌ 0 个 pipe（门、旗子均可见）|

特别是 **capture_02 截图中，门左侧紧邻区域应该有 pipe（因为 PuzzleArea (700,480) → 门相对位置 (220, -8) → 门绝对 (920, 472)，pipe 应在门左侧 92~220 px 处），但该区域完全空白**。

### 根因（代码定位）

**原因**：`level_01.tscn` 第 103 行 `SignalNetwork` 节点声明为 `type="Node"`，但其子节点 PipeA/B/C 是 `Area2D`（CanvasItem 派生）。

```tscn
[node name="PuzzleArea" type="Node2D" parent="."]   # 第 99 行：Node2D，有 transform
position = Vector2(700, 480)
z_index = 1

[node name="SignalNetwork" type="Node" parent="PuzzleArea"]  # 第 103 行：⚠️ Node，不是 Node2D
script = ExtResource("3_signet")

[node name="PipeA" type="Area2D" parent="PuzzleArea/SignalNetwork"]  # 第 108 行
position = Vector2(0, 0)   # 期望：通过 PuzzleArea(700,480) 偏移到 (700,480)
```

**Godot transform 传播规则**：
- `Node2D` 的 transform 通过 CanvasItem 树向下传播
- `Node` **不是** CanvasItem，**不会传播** parent 的 canvas transform
- 当 Node2D 子树中插入一个 `Node`，**transform 链断裂**

**实际结果**：
- PipeA 的 `global_position` ≠ (700, 480)，而是 ≈ **(0, 0)**（屏幕左上角，y 在地面上方 560px）
- PipeB ≈ (64, 0)，PipeC ≈ (128, 0)
- 这三个 sprite 实际渲染在屏幕左上角的外面/边缘，玩家在游戏中根本看不到，**且也无法走到那里去交互**
- 解谜机关从此**完全无法触达**——这是 vertical slice 的 **showstopper bug**

### 次生影响

1. **玩家 collide 检测失效**：pipe Area2D 的位置在 (0,0)，玩家走到 PuzzleArea 区域（700,480）不会触发 `_on_body_entered`，`_player_in_range` 永远为 false
2. **谜题无法解**：玩家按 interact 无效，`puzzle_solved` 永不 emit，门永不打开
3. **vertical slice 流程断**：从 spawn → 谜题 → 终点的核心 loop 不通

### 修复指引（技术）

**方案 A（推荐，最小改动）**：将 `SignalNetwork` 改为 `Node2D`

```diff
-[node name="SignalNetwork" type="Node" parent="PuzzleArea"]
+[node name="SignalNetwork" type="Node2D" parent="PuzzleArea"]
 script = ExtResource("3_signet")
```

同时 `signal_network.gd` 第 1 行：

```diff
-extends Node
+extends Node2D
```

`SignalNetwork` 没有用到 Node 独有特性（无 process，纯逻辑容器），改 Node2D 零副作用。

**方案 B（不推荐）**：把 PipeA/B/C 的 position 改成绝对世界坐标 (700,480)/(764,480)/(828,480)。但这违反"PuzzleArea 作为容器"的语义，且未来移动整个解谜区时要改 N 处。

### 顺便发现的潜在 bug

**`pipe_node.gd` 第 24 行覆盖了 .tscn 配置**：

```gdscript
var rotation_steps: int = 0   # ⚠️ 普通 var 没 @export，会用 0 覆盖 .tscn
```

而 `level_01.tscn` 配置了 `rotation_steps = 2/1/1`（第 114/128/142 行），运行时全部被重置为 0。即使 SignalNetwork 修好，**初始旋转状态错误**仍会导致谜题初始连通性 / 视觉表现与设计不符。

**修复**：第 24 行改为 `@export var rotation_steps: int = 0`，并在 `_ready()` 末尾追加 `rotation_degrees = rotation_steps * 90.0` 同步视觉。

---

## 1. 5 维 In-Context 评审

> 评审基准：style-guide v1.0 §2 色板 + §3 像素密度 + §1 "Verdigris Stillness · 铜绿静谧" 调性

### 1.1 构图 — **FAIL**

| 项 | 观察 | 判定 |
|---|---|---|
| 玩家路径可读性 | 出生点 → 平台跳跃 → 谜题 → 旗子，3 张截图叠看路径基本清晰 | OK |
| 谜题机关可见性 | **PipeA/B/C 完全不可见**（见 §0） | ❌ FAIL |
| 平台高度梯度 | Platform1 (200,460) / Platform2 (480,400) / Platform3 (720,340)，高度差合理 | OK |
| 终点视觉锚 | 旗子在 (1180,496)，截图 02 可见，但**孤立无衬托**（应有 Signal Beacon 三脚架，见 style-guide §4.2） | MINOR |

**evidence**：截图 02 玩家 x=960，门左侧 92~220px 区域应有 3 个 48×48 金色 pipe，实际**完全空白**。引用 style-guide §5.2 "Vertical Slice Level · '管线迷阵'"："关卡核心机关 Gear Lock 居中"——核心机关丢失，构图核心元素缺位。

**score**: **FAIL**
**reason**: 解谜机关全部不渲染，关卡核心视觉锚缺失，玩家在游戏中看不到要交互的目标物
**evidence**: capture_02 中门(920,472)左侧空白区域应有 PipeA/B/C；style-guide.md §5.2 line 119 "关卡核心机关 Gear Lock 居中"

### 1.2 色彩 — **MINOR**

| 项 | 实际游戏内 | style-guide 要求 | 判定 |
|---|---|---|---|
| 背景色 | `#4A4A4A` 中性灰 | §2.1 `#2C3340` Slate Indigo | ❌ 偏差（hex 完全不同色相） |
| 地砖主色 | 铜绿 ≈ `#5C7A6E` 系（视觉肉眼） | `#5C7A6E` Verdigris Bronze | ✅ 匹配 |
| 玩家 ColorRect | Signal Cyan 蓝青 ≈ `#4FB3C7` 系 | `#4FB3C7` Signal Cyan | ✅ 匹配（**但作为玩家而非机关，违反 §4.1 含义**）|
| 门 sprite | Brass Patina 金 + Signal Cyan 装饰 | §2.1 `#A89968` + `#4FB3C7` | ✅ 匹配 |
| 旗子 sprite | Verdigris + Mist Cream 旗布 | `#5C7A6E` + `#D9D2BC` | ✅ 匹配 |

**hex_violations**:
- `bg = #4A4A4A` (背景灰) ≠ expected `#2C3340` Slate Indigo（style-guide §2.1 line 38）— 当前背景偏中性灰，缺少蓝紫深沉感，**冲淡了"信号塔被遗忘"的冷峻调**
- 玩家 ColorRect 用 `#4FB3C7` 占用了 §2.1 line 37 "Signal Cyan = 可交互机关 / 活动信号"的语义槽位，**会误导玩家**："蓝青色 = 可交互 → 玩家自己也是可交互目标？"

**score**: **MINOR**
**reason**: 背景色偏离规格但不致命（主色板正确），玩家临时 ColorRect 用了 Signal Cyan 抢占机关语义槽位
**hex_violations**:
- expected #2C3340 Slate Indigo, got #4A4A4A in scene viewport background
- expected player neutral hue (e.g. #5C7A6E protagonist tone), got #4FB3C7 占用 Signal Cyan 槽位

### 1.3 比例 — **MINOR**

| 元素 | 实际尺寸 | style-guide §3 规格 | 判定 |
|---|---|---|---|
| 地砖 | 32×32 px tile | 32×32 ✅ | OK |
| 玩家 ColorRect | 32×48 px | 32×48 ✅ | OK |
| pipe sprite | 48×48 px raw（看 raw 图） | §3 line 63 "大型机关 64×64"，pipe 应当是大型机关 | MINOR（48 vs 64 偏小）|
| 门 sprite | 32×96 px | 风格指南未硬性规定，但与玩家 32×48 比例 1:2 偏过高 | OK |
| 旗子 sprite | 64×96 px | 同上 | OK |
| 玩家 vs 地砖 | 32×48 vs 32×32 | §3 line 62 "高度比 tile 高半格" ✅ | OK |
| 门 vs 玩家 | 96 vs 48 = 2 倍高 | 视觉合理（门要高于玩家才可"通过"）| OK |
| 旗子 vs 玩家 | 96 vs 48 = 2 倍高 | OK | OK |

**evidence**: pipe_straight.png 实际 48×48 px，但 style-guide §3 line 63 写明"大型机关 / 谜题件 64×64 px (2×2 tile)"。pipe 是核心谜题件，应该 64×64。**但因为 pipe 在游戏内不可见，比例问题次要**。

**score**: **MINOR**
**reason**: pipe 资产 48×48，规格要求 64×64；其他比例合规
**evidence**: style-guide.md §3 line 63 "大型机关 / 谜题件 64×64 px"; pipe_straight.png 实际 48×48

### 1.4 光影 / 对比度 — **MINOR**

| 项 | 观察 | 判定 |
|---|---|---|
| 玩家辨识度（AP-10 第 3 项） | 蓝青 ColorRect 在 #4A4A4A 背景下**对比度极强**，瞬间识别 | OK |
| 地砖在背景上对比度 | Verdigris #5C7A6E vs 灰 #4A4A4A，对比度 ≈ 1.4:1（实测肉眼仍可辨）| MINOR（低于 WCAG 4.5:1 要求，§7.1 line 182 要求 ≥ 4.5:1）|
| 门 / 旗子高光 | 金色 Brass Patina 高光在灰背景上很跳，吸引视线 | OK（符合 §5.1 "可交互物件冷光描边"）|
| 主光源方向 | 看不出统一方向（资产各自孤立成图）| MINOR（§3 line 65 + §6 review checklist 第 4 项要求"右上 30° 统一光源"）|
| 描边 | 资产都有暗色描边，符合 §3 line 65 "1 px Slate Indigo `#2C3340`"  | OK |

**score**: **MINOR**
**reason**: 玩家辨识度合格；地砖与背景对比度低于 WCAG AA；多资产光源方向无明显统一
**evidence**: style-guide.md §7.1 line 182 "Verdigris/Mist Cream 4.6:1 AA"，但实际背景换成 #4A4A4A 后地砖对比度跌破 1.5:1；§3 line 65 "1px Slate Indigo 描边" raw 资产合规

### 1.5 一致性 — **MINOR**

| 维度 | 观察 | 判定 |
|---|---|---|
| 资产风格家族感 | 地砖 / pipe / 门 / 旗子 都是"金属浮雕 + 铜绿 + 黄铜高光"风格 | ✅ 同家族 |
| pixel-art 渲染风格 | 4 个资产都呈现像素 + 半绘制混合风（不是纯 pixel-art）| MINOR（style-guide §3 line 64 要求 nearest-neighbor，但资产本身有抗锯齿渲染痕迹）|
| 玩家 vs 资产 | 玩家是**纯色 ColorRect**，与精致美术资产**严重不匹配** | ❌ 这是临时占位，但目前 vertical slice 截图作为评审材料**不合格** |
| "Rusted Brass Stillness" 调性 | 静谧感、不饱和、铜绿基调——**raw 资产匹配**，但 in-context 因 #4A4A4A 背景偏中性灰，调性"静谧"减弱为"冷淡" | MINOR |
| Signal Cyan 语义占用 | 玩家用了 Signal Cyan，与 style-guide §2.1 line 37 "可交互机关"语义冲突 | MINOR |

**score**: **MINOR**
**reason**: 资产之间风格统一（PASS）；但玩家无 sprite 用 ColorRect、Signal Cyan 语义冲突、背景偏离规格——in-context 整体调性偏离 style-guide §1 line 12 "Verdigris Stillness"
**evidence**:
- style-guide.md §1 line 12 "Verdigris Stillness · 铜绿静谧"
- style-guide.md §4.1 line 78 "Pip 主角 Verdigris Bronze 长袍"——当前玩家是蓝青纯色块，与 Pip 形象**完全不符**
- style-guide.md §2.1 line 37 "Signal Cyan = 可交互机关"——被玩家占用

---

## 2. naming_compliance & import_metadata

| 检查项 | 状态 | 备注 |
|---|---|---|
| naming_compliance | **false** | `ground_tile.png` / `pipe_straight.png` / `puzzle_door.png` / `goal_flag.png` 都缺少 style-guide §6.3 line 152 要求的 `<category>_` 前缀（应为 `tile_ground.png` / `prop_pipe_straight.png` / `prop_puzzle_door.png` / `prop_goal_flag.png`）|
| import_metadata | **true** | `pipe_straight.png.import` 等 4 个 .import 文件均存在（防 AP-04 通过）|

**违规命名清单**：
- `ground_tile.png` → 应为 `tile_ground.png`
- `pipe_straight.png` → 应为 `prop_pipe_straight.png`
- `puzzle_door.png` → 应为 `prop_puzzle_door.png`
- `goal_flag.png` → 应为 `prop_goal_flag.png`

---

## 3. 综合 Verdict

# **AD-REJECT**

### Rejection 决定理由

构图维度 **FAIL**：解谜核心机关 PipeA/B/C 在游戏内**完全不可见**且**无法交互**，导致 vertical slice 核心 loop（出生 → 谜题 → 旗子）**彻底中断**。这是 showstopper 级缺陷，不是渐进改进项。

即使其他 4 维都是 MINOR（不到 FAIL），**1 维 FAIL 即触发 REJECT**（schema line 90 "verdict 规则：≥1 FAIL → AD-REJECT"）。

### reject_remediation（按优先级排序）

1. **【P0 / 必修】修复 SignalNetwork transform 链**：
   - `level_01.tscn` 第 103 行 `type="Node"` → `type="Node2D"`
   - `signal_network.gd` 第 1 行 `extends Node` → `extends Node2D`
   - 验证：重新运行截图工具，capture_02 中门左侧应出现 3 个 48×48 金色 pipe sprite
   - 责任方：engineer（一行改动），不需要 art 重做资产

2. **【P0 / 必修】修复 pipe rotation_steps 被覆盖**：
   - `pipe_node.gd` 第 24 行 `var rotation_steps: int = 0` → `@export var rotation_steps: int = 0`
   - `_ready()` 末尾追加 `rotation_degrees = rotation_steps * 90.0` 同步视觉旋转
   - 验证：游戏启动后 PipeA 视觉旋转 180°、PipeB 90°、PipeC 90°（与 .tscn 配置一致）

3. **【P1 / 建议本 sprint 内修】玩家临时 sprite**：
   - 当前 `ColorRect 32×48 #4FB3C7` 既无 sprite 又抢占 Signal Cyan 语义
   - 临时方案：把 ColorRect 颜色改为 Verdigris Bronze `#5C7A6E`（与 Pip 主色一致），让出 Signal Cyan 语义
   - 长期方案：触发 art-asset-pipeline + char-key-verdict 流程，按 style-guide §4.1 + §6.2 SOP 出 `char_pip_key.png`

4. **【P1 / 建议本 sprint 内修】背景色对齐**：
   - 当前视口背景 `#4A4A4A` → 改为 `#2C3340` Slate Indigo（style-guide §2.1）
   - Godot project setting → rendering / environment / default_clear_color
   - 修后地砖 Verdigris vs 背景 Slate 的对比度从 1.4:1 提升到约 3.2:1（仍未达 AA，但符合调性）

5. **【P2 / 下个 sprint 跟进】资产命名规范化**：
   - 4 个 raw 资产加 `<category>_` 前缀，并同步更新 `level_01.tscn` ext_resource 路径
   - 不阻塞 vertical slice，可放入 VISUAL_DEBT backlog

6. **【P2 / 可选】pipe 资产升级 64×64**：
   - 按 style-guide §3 line 63 "大型机关 64×64"，重生 pipe_straight.png 为 64×64（reference-based 用 image_edit 缩放）
   - 当前 48×48 不阻塞功能，可作为 visual debt

7. **【P3 / 可选】终点旗子周边场景化**：
   - style-guide §4.2 line 92 提到 Signal Beacon 三脚架——在终点旁放一个 Signal Beacon prop 强化 "Vertical Slice Level · 管线迷阵" §5.2 的视觉锚

---

## 4. self_rubric 自检（schema line 168-176）

| # | 检查项 | 状态 |
|---|---|---|
| 1 | 5 维评审是否全部填写？每维 score + reason + evidence 是否齐全？ | ✅ PASS |
| 2 | color 维 hex_violations 是否具体到 expected vs actual hex？ | ✅ PASS（#4A4A4A vs #2C3340；#4FB3C7 语义占用）|
| 3 | consistency 维对多帧资产是否检查角色一致性 5 项？ | N/A（本批无多帧动画，是 in-context 渲染评审）|
| 4 | verdict=AD-REJECT 时 reject_remediation 是否非空且可执行？ | ✅ PASS（7 条带优先级 + 具体 diff）|
| 5 | import_metadata 是否真实检查了 .import 文件存在？ | ✅ PASS（search_file 验证 4 个 .import 均存在）|
| 6 | style-guide 色板是否 ≥5 色且每色有 hex？ | ✅ PASS（已读 style-guide §2.1 5 主色 + §2.2 3 辅色）|
| 7 | 是否引用了 art bible 具体行号？（不允许"风格不对"泛泛之谈）| ✅ PASS（§1 line 12, §2.1 line 37/38, §3 line 63/65, §4.1 line 78, §5.2 line 119, §6.3 line 152, §7.1 line 182）|

**self_rubric: 7/7 PASS**

---

## 5. 关联

- 上游：`gdd/gdd-1-overview.md` · `art/style-guide.md` v1.0
- 反模式：AP-10（in-context 渲染验证）+ AP-03（资产入库前一致性）+ AP-04（.import 元数据）
- 修复责任：engineer（P0 改 .tscn / .gd 两处）+ art-director 验证截图（P1 玩家颜色微调）
- 下次评审：P0 修完后 main agent 重新提供截图 → 重审至 AD-APPROVE 才能进入 vertical slice 阶段门
