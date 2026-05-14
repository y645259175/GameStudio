extends CanvasLayer

## HUD 显示
## GDD §7 UX 与 HUD

@onready var score_label: Label = $ScoreLabel
@onready var lives_label: Label = $LivesLabel
@onready var level_label: Label = $LevelLabel


func _ready() -> void:
	GameManager.score_changed.connect(_on_score_changed)
	GameManager.lives_changed.connect(_on_lives_changed)
	update_all()


func update_all() -> void:
	_on_score_changed(GameManager.score)
	_on_lives_changed(GameManager.lives)
	update_level(GameManager.current_level)


func _on_score_changed(new_score: int) -> void:
	if score_label:
		score_label.text = "Score: %04d" % new_score


func _on_lives_changed(new_lives: int) -> void:
	if lives_label:
		var hearts := ""
		for i in new_lives:
			hearts += "♥"
		lives_label.text = "Lives: %s" % hearts


func update_level(level: int) -> void:
	if level_label:
		level_label.text = "Lv: %d" % level
