extends Node

## 全局配置加载器（Autoload）
## 加载所有 data/*.json 文件并提供路径访问

var _data: Dictionary = {}

const FILES := [
	"player", "physics", "enemies", "items", "scoring",
	"camera", "level-flow", "palette", "hud", "level-elements"
]


func _ready() -> void:
	for fname in FILES:
		var file := FileAccess.open("res://data/%s.json" % fname, FileAccess.READ)
		if not file:
			push_warning("ConfigLoader: %s.json not found" % fname)
			continue
		var json := JSON.new()
		var err := json.parse(file.get_as_text())
		file.close()
		if err == OK:
			_data[fname] = json.data
		else:
			push_error("ConfigLoader: %s.json parse error" % fname)


## 用 "<file>.<key>.<subkey>" 形式访问
## 例：ConfigLoader.get_value("player.walk.maxSpeed", 90)
func get_value(path: String, default_val: Variant = null) -> Variant:
	var keys := path.split(".")
	if keys.size() == 0:
		return default_val
	var first: String = keys[0]
	if not _data.has(first):
		return default_val
	var current: Variant = _data[first]
	for i in range(1, keys.size()):
		if current is Dictionary and (current as Dictionary).has(keys[i]):
			current = (current as Dictionary)[keys[i]]
		else:
			return default_val
	return current


func get_section(file_section: String) -> Dictionary:
	var parts := file_section.split(".")
	var current: Variant = _data.get(parts[0], {})
	for i in range(1, parts.size()):
		if current is Dictionary:
			current = (current as Dictionary).get(parts[i], {})
		else:
			return {}
	return current as Dictionary
