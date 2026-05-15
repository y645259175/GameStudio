extends Node

## 全局配置加载器（Autoload）
## 读取 data/gameplay.json，供所有脚本通过 ConfigLoader.get_value() 获取数值

var _data: Dictionary = {}


func _ready() -> void:
	_load_config()


func _load_config() -> void:
	var file := FileAccess.open("res://data/gameplay.json", FileAccess.READ)
	if not file:
		push_error("ConfigLoader: gameplay.json not found")
		return
	var json := JSON.new()
	var err := json.parse(file.get_as_text())
	file.close()
	if err != OK:
		push_error("ConfigLoader: gameplay.json parse error")
		return
	_data = json.data


## 获取嵌套值，用点号分隔路径
## 例：ConfigLoader.get_value("paddle.default_width", 120)
func get_value(path: String, default_val: Variant = null) -> Variant:
	var keys := path.split(".")
	var current: Variant = _data
	for k in keys:
		if current is Dictionary and (current as Dictionary).has(k):
			current = (current as Dictionary)[k]
		else:
			return default_val
	return current


## 获取整个子段
func get_section(section: String) -> Dictionary:
	return _data.get(section, {}) as Dictionary
