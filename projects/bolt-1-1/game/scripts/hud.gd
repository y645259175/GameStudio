extends CanvasLayer

## HUD · 4 区显示：BOLTY+分数 / Cog / SECTOR / TIME

var _label_score: Label
var _label_coin: Label
var _label_world: Label
var _label_time: Label
var _label_lives: Label


func _ready() -> void:
	layer = 100

	var bg := ColorRect.new()
	bg.color = Color(0, 0, 0, 0.0)
	bg.size = Vector2(1280, 60)
	bg.position = Vector2(0, 0)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	_label_score = _make_label("BOLTY\n000000", Vector2(64, 16))
	_label_coin = _make_label("COG x00", Vector2(400, 32))
	_label_world = _make_label("SECTOR\n1-1", Vector2(640, 16))
	_label_time = _make_label("TIME\n300", Vector2(960, 16))
	_label_lives = _make_label("x 3", Vector2(1200, 32))

	GameManager.score_changed.connect(_on_score_changed)
	GameManager.coins_changed.connect(_on_coin_changed)
	GameManager.lives_changed.connect(_on_lives_changed)
	GameManager.time_changed.connect(_on_time_changed)


func _make_label(text: String, pos: Vector2) -> Label:
	var l := Label.new()
	l.text = text
	l.position = pos
	l.add_theme_color_override("font_color", Color.WHITE)
	l.add_theme_font_size_override("font_size", 18)
	add_child(l)
	return l


func _on_score_changed(s: int) -> void:
	_label_score.text = "BOLTY\n%06d" % s


func _on_coin_changed(c: int) -> void:
	_label_coin.text = "COG x%02d" % c


func _on_time_changed(t: int) -> void:
	_label_time.text = "TIME\n%03d" % max(0, t)
	if t <= 100 and t > 0:
		_label_time.add_theme_color_override("font_color", Color.RED)
	else:
		_label_time.add_theme_color_override("font_color", Color.WHITE)


func _on_lives_changed(l: int) -> void:
	_label_lives.text = "x %d" % l
