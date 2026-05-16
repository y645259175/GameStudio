extends CanvasLayer

## HUD · M6.1 重做版（精品游戏标准）
## - 顶部黑色面板 60px 高，工业风金属边框
## - 4 区显示：BOLTY 分数 / Cog 图标+计数 / SECTOR / TIME
## - 像素感字体：黑色描边 + 大字号
## - TIME ≤ 100 时变红 + 闪烁
## - Lives 在右侧用图标表示（小 Bolty 头像 × N）

const HUD_HEIGHT: float = 56.0
const PANEL_BG_COLOR := Color(0.04, 0.06, 0.10, 0.85)  # 深蓝黑半透明
const PANEL_BORDER_TOP := Color("#3878F0")  # 信号蓝
const PANEL_BORDER_BOTTOM := Color("#1A2438")  # 暗
const TEXT_NORMAL := Color("#FFFFFF")
const TEXT_LABEL := Color("#A0B0C8")  # 标签灰
const TEXT_WARNING := Color("#FF4040")
const TEXT_CELEBRATE := Color("#FFC820")
const COG_COLOR := Color("#E8A018")
const BOLTY_COLOR := Color("#E03030")

var _label_score_label: Label
var _label_score_value: Label
var _label_cog_count: Label
var _label_world_label: Label
var _label_world_value: Label
var _label_time_label: Label
var _label_time_value: Label
var _lives_container: HBoxContainer
var _time_blink_t: float = 0.0


func _ready() -> void:
	layer = 100

	# 顶部面板背景
	var panel := ColorRect.new()
	panel.color = PANEL_BG_COLOR
	panel.size = Vector2(1280, HUD_HEIGHT)
	panel.position = Vector2(0, 0)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(panel)

	# 顶部高光描边（亮蓝 1px）
	var border_top := ColorRect.new()
	border_top.color = PANEL_BORDER_TOP
	border_top.size = Vector2(1280, 1)
	border_top.position = Vector2(0, 0)
	border_top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(border_top)

	# 底部分隔线（暗蓝 2px，像素感）
	var border_bot := ColorRect.new()
	border_bot.color = PANEL_BORDER_BOTTOM
	border_bot.size = Vector2(1280, 2)
	border_bot.position = Vector2(0, HUD_HEIGHT - 2)
	border_bot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(border_bot)

	# === 4 区 ===
	# 区域宽度划分：4 列 × 320px 宽
	# Col 0: 60-320 BOLTY+score
	# Col 1: 340-540 COG icon+count
	# Col 2: 600-820 SECTOR 1-1
	# Col 3: 880-1100 TIME
	# Col 4: 1140-1260 LIVES (icons)

	# Col 0: BOLTY + 分数
	_label_score_label = _make_label("BOLTY", Vector2(48, 6), 16, TEXT_LABEL)
	_label_score_value = _make_label("000000", Vector2(48, 24), 28, TEXT_NORMAL)

	# Col 1: COG 图标 + 计数
	var cog_icon := _make_cog_icon(Vector2(380, 16))
	add_child(cog_icon)
	var cog_x := _make_label("×", Vector2(420, 18), 22, TEXT_NORMAL)
	_label_cog_count = _make_label("00", Vector2(440, 16), 26, COG_COLOR)

	# Col 2: SECTOR
	_label_world_label = _make_label("SECTOR", Vector2(620, 6), 16, TEXT_LABEL)
	_label_world_value = _make_label("1-1", Vector2(620, 24), 28, TEXT_NORMAL)

	# Col 3: TIME
	_label_time_label = _make_label("TIME", Vector2(880, 6), 16, TEXT_LABEL)
	_label_time_value = _make_label("300", Vector2(880, 24), 28, TEXT_NORMAL)

	# Col 4: Lives icon container
	_lives_container = HBoxContainer.new()
	_lives_container.position = Vector2(1140, 14)
	_lives_container.add_theme_constant_override("separation", 4)
	add_child(_lives_container)
	_render_lives(GameManager.lives)

	# 信号绑定
	GameManager.score_changed.connect(_on_score_changed)
	GameManager.coins_changed.connect(_on_coin_changed)
	GameManager.lives_changed.connect(_on_lives_changed)
	GameManager.time_changed.connect(_on_time_changed)


func _make_label(text: String, pos: Vector2, font_size: int, color: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.position = pos
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_outline_color", Color.BLACK)
	l.add_theme_constant_override("outline_size", 4)
	l.add_theme_font_size_override("font_size", font_size)
	add_child(l)
	return l


## 像素感的小齿轮图标（用 Polygon2D 画 6 齿）
func _make_cog_icon(pos: Vector2) -> Node2D:
	var c := Node2D.new()
	c.position = pos
	c.scale = Vector2(1.6, 1.6)
	# 外圈齿轮（粗略 6 齿）
	var outer := Polygon2D.new()
	var pts := PackedVector2Array()
	var n := 12
	for i in range(n):
		var ang := i * TAU / n
		var r := 10.0 if i % 2 == 0 else 7.0
		pts.append(Vector2(cos(ang) * r, sin(ang) * r))
	outer.polygon = pts
	outer.color = COG_COLOR
	c.add_child(outer)
	# 内圈深色孔
	var inner := Polygon2D.new()
	var ipts := PackedVector2Array()
	for i in range(8):
		var ang := i * TAU / 8
		ipts.append(Vector2(cos(ang) * 3, sin(ang) * 3))
	inner.polygon = ipts
	inner.color = Color("#404040")
	c.add_child(inner)
	return c


## Lives 用小红点表示
func _render_lives(lives: int) -> void:
	if not _lives_container:
		return
	for c in _lives_container.get_children():
		c.queue_free()
	var n: int = clamp(lives, 0, 9)
	for i in range(n):
		var dot := ColorRect.new()
		dot.color = BOLTY_COLOR
		dot.custom_minimum_size = Vector2(16, 20)
		# 加个 1px 黑边模拟描边
		var border := ColorRect.new()
		border.color = Color.BLACK
		border.size = Vector2(18, 22)
		border.position = Vector2(-1, -1)
		dot.add_child(border)
		border.show_behind_parent = true
		_lives_container.add_child(dot)
	if lives > 9:
		var extra := Label.new()
		extra.text = " ×%d" % lives
		extra.add_theme_font_size_override("font_size", 18)
		extra.add_theme_color_override("font_color", TEXT_NORMAL)
		_lives_container.add_child(extra)


func _on_score_changed(s: int) -> void:
	_label_score_value.text = "%06d" % s


func _on_coin_changed(c: int) -> void:
	_label_cog_count.text = "%02d" % c
	# 90+ 高亮黄；100 庆祝
	if c >= 100:
		_label_cog_count.add_theme_color_override("font_color", TEXT_CELEBRATE)
	elif c >= 90:
		_label_cog_count.add_theme_color_override("font_color", TEXT_CELEBRATE)
	else:
		_label_cog_count.add_theme_color_override("font_color", COG_COLOR)


func _on_time_changed(t: int) -> void:
	_label_time_value.text = "%03d" % max(0, t)
	if t <= 100 and t > 0:
		_label_time_value.add_theme_color_override("font_color", TEXT_WARNING)
	else:
		_label_time_value.add_theme_color_override("font_color", TEXT_NORMAL)


func _on_lives_changed(l: int) -> void:
	_render_lives(l)


func _process(delta: float) -> void:
	# TIME ≤ 100 时闪烁
	if GameManager.time_left <= 100 and GameManager.time_left > 0:
		_time_blink_t += delta
		var phase: float = fmod(_time_blink_t, 0.5) / 0.5
		_label_time_value.modulate.a = 0.5 if phase < 0.5 else 1.0
	else:
		_label_time_value.modulate.a = 1.0
