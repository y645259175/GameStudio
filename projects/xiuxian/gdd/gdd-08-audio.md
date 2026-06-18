---
gdd_id: 08
gdd_title: 音频
status: drafting
last_review: 2026-06-09
sections_complete: [设计精神, 总线设计, 音频接口, M3范围, 命名规范骨架, M5扩展占位]
sections_pending: []
upstream_adr: []
upstream_gdd: [gdd-01]
verdict: drafting
---

# GDD-08 · 音频

> M1 起草纪律（用户定调 2026-06-09）：M3 **音频静默**（GDD-01 §8.3 已知限制），本章 M3 范围 = **接口完整 + 总线就位**，具体 BGM / 音效 / 配音 M5 启动时再产。详细内容延后到 `docs/m1-deferred-details.md`。

---

## 1. 设计精神

### 1.1 本章在 M3 的最小职责

```
M3 实际产出：
  ├─ AudioBus autoload + 5 总线（master / music / sfx / ui / voice）
  ├─ AudioService API（play_sfx / play_music / set_bus_volume）
  └─ 配表 schema（sfx_def / music_def）—— M3 表空，M5 填内容
M3 不做：
  ├─ 任何具体音频文件
  ├─ BGM 分层 / 动态混音
  └─ 配音 / 旁白
```

### 1.2 为什么 M3 留接口

- 加 BGM 时 UI 已挂 `AudioService.play_music("explore")` 调用 → M5 只需填 music 文件
- 战斗 / 突破 / 历练事件已挂音效触发点 → M5 实装无需回头改业务代码

---

## 2. 总线设计

### 2.1 5 总线

```
master（主总线）
 ├─ music（背景音乐）          ─ 探索/战斗/突破 BGM
 ├─ sfx（音效）                ─ 攻击/拾取/UI 反馈
 ├─ ui（UI 音）                ─ 按钮/弹窗（独立总线方便禁音）
 └─ voice（配音 / 旁白）        ─ M5 才用
```

### 2.2 总线参数（M3 默认）

| 总线 | 默认音量 | 是否在玩家设置中暴露 |
|---|---|---|
| master | 0 dB | ✅ |
| music | -6 dB | ✅ |
| sfx | -3 dB | ✅ |
| ui | -3 dB | ✅ |
| voice | 0 dB | ✅ M5 |

### 2.3 Godot 总线配置

`default_bus_layout.tres` 中定义。M2 期建配置文件。

---

## 3. AudioService 接口（M2 必落地）

```gdscript
# scripts/services/audio_service.gd（autoload）
class_name AudioService extends Node

# === 音乐 ===
func play_music(music_id: String, fade_in_sec: float = 1.0) -> void
func stop_music(fade_out_sec: float = 1.0) -> void
func crossfade_to(music_id: String, duration_sec: float = 2.0) -> void

# === 音效 ===
func play_sfx(sfx_id: String, volume_db: float = 0.0) -> void
func play_sfx_2d(sfx_id: String, position: Vector2) -> void  # M5 战斗场景用

# === UI 音 ===
func play_ui(ui_sfx_id: String) -> void  # 按钮 / 弹窗专用

# === 总线控制 ===
func set_bus_volume(bus_name: String, db: float) -> void
func get_bus_volume(bus_name: String) -> float
func set_bus_mute(bus_name: String, mute: bool) -> void
```

### 3.1 M3 行为

- 接口可调用 + 内部正确路由到总线
- **未注册的 music_id / sfx_id 不报错**，仅 debug log（M3 配表空）
- 玩家在设置 UI 调音量 → 总线响应正常（哪怕没声音播放）

### 3.2 M5 实装时

- music_id / sfx_id 配表填实际文件
- AudioService 加载并播放
- 业务代码**无需修改**

---

## 4. 音频资源命名规范（M3 骨架，M5 完善）

### 4.1 文件组织

```
data/audio/
├─ music/
│   ├─ explore_sect.ogg        ← 探索宗门 BGM
│   ├─ explore_expedition.ogg  ← 探索历练 BGM
│   ├─ combat.ogg              ← 战斗 BGM
│   ├─ breakthrough.ogg        ← 突破 BGM
│   └─ menu.ogg                ← 主菜单 BGM
├─ sfx/
│   ├─ ui/
│   │   ├─ button_click.ogg
│   │   ├─ panel_open.ogg
│   │   └─ ...
│   ├─ combat/                 ← M5
│   ├─ event/                  ← 历练事件 / 突破等
│   └─ ambient/                ← 环境音（M5）
└─ voice/                      ← M5
```

### 4.2 命名约定

- 全小写 + 下划线
- 按场景 / 行为分类目录
- 音乐文件用 `.ogg`（小 + 跨平台）
- 音效文件用 `.wav`（短）或 `.ogg`（长）

### 4.3 配表

```
data/table/音频/
├─ 音乐定义.xlsx          ← music_id / 文件路径 / 默认音量 / 是否循环
├─ 音效定义.xlsx          ← sfx_id / 文件路径 / 默认音量 / 总线
└─ proto/audio.schema.toml
```

M3 表空（schema 就位）；M5 填内容。

---

## 5. M3 范围

| 内容 | M3 状态 |
|---|---|
| §2 5 总线 default_bus_layout.tres | ✅ M3（M2 创建）|
| §3 AudioService autoload + API | ⏳ M2 必落地 |
| §3.1 业务代码挂调用点（按钮 / UI / 战斗 / 突破等关键节点）| ⏳ M2-M3 实装 UI 时 |
| §4 配表 schema | ✅ M3 schema 落盘，无内容 |
| 玩家设置：5 总线音量调节 + 静音 | ⏳ M3 UI 实装 |
| BGM / 音效 / 配音 实际文件 | ⏳ M5（→ `docs/m1-deferred-details.md`）|

### 5.1 M3 业务代码挂点清单

虽然 M3 不播声音，但要在以下位置预挂 `AudioService.play_xx(...)` 调用，M5 一填表即响：

| 位置 | API | id（占位）|
|---|---|---|
| 主菜单进入 | `play_music` | `menu` |
| 进宗门 | `play_music` | `explore_sect` |
| 进历练 | `play_music` | `explore_expedition` |
| 战斗开始 | `play_music` | `combat` |
| 突破检定开始 | `play_music` | `breakthrough` |
| 任意按钮点击 | `play_ui` | `button_click` |
| 弹窗 | `play_ui` | `panel_open` |
| 拾取战利品 | `play_sfx` | `loot_pickup` |
| 弟子升级 | `play_sfx` | `level_up` |
| 建筑落成 | `play_sfx` | `building_complete` |

---

## 6. M5 扩展（详细 → `docs/m1-deferred-details.md`）

| 扩展 | M5 启动时展开 |
|---|---|
| 音乐分层与动态混音规则 | 探索 ⇄ 战斗 平滑过渡 / 情绪强度切换 |
| 完整 sfx 库 | 战斗音效 / 环境音 / 修仙特效音（雷劫 / 灵气流转）|
| 配音 / 旁白 | 主线 CG 配音 / 关键 NPC 台词 |
| 多语言配音 | M6 i18n 时决定 |

---

## 7. 风险

| 风险 | 缓解 |
|---|---|
| M3 业务代码漏挂调用点 → M5 实装时回头改 | §5.1 清单 + M3 review 检查 |
| AudioService 未实装 → 按钮无反馈 | M2 必落地（仅接口，无声音也能跑）|
| Godot 总线配置错乱 | M2 单元测试覆盖：set_bus_volume 后值正确 |
| 音频资源管理（M5）大文件加载卡顿 | 音乐 streaming 加载（Godot 自带）|

---

## verdict

drafting · M3 仅 §3 接口 + §5.1 挂点必落地，其余 M5 展开。
