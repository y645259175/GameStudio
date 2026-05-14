extends SceneTree

## 自动化测试：验证 5 关 levels.json 数据可被解析 + 砖块类型完整
## 运行：godot --headless --path <project> -s tests/test_levels.gd --quit

func _initialize() -> void:
	var pass_count := 0
	var fail_count := 0

	# 1. 数据文件存在
	if not FileAccess.file_exists("res://data/levels.json"):
		printerr("FAIL: levels.json missing")
		fail_count += 1
		_finish(pass_count, fail_count)
		return
	print("PASS: levels.json exists")
	pass_count += 1

	# 2. 解析
	var f := FileAccess.open("res://data/levels.json", FileAccess.READ)
	var json := JSON.new()
	var err := json.parse(f.get_as_text())
	f.close()
	if err != OK:
		printerr("FAIL: levels.json parse error %d" % err)
		fail_count += 1
		_finish(pass_count, fail_count)
		return
	print("PASS: levels.json parsed")
	pass_count += 1

	var data: Dictionary = json.data
	var levels: Dictionary = data.get("levels", {})
	var brick_types: Dictionary = data.get("brick_types", {})

	# 3. 5 关都在
	for n in range(1, 6):
		var key := str(n)
		if not levels.has(key):
			printerr("FAIL: level %s missing" % key)
			fail_count += 1
		else:
			var lv: Dictionary = levels[key]
			var layout: Array = lv.get("layout", [])
			if layout.is_empty():
				printerr("FAIL: level %s layout empty" % key)
				fail_count += 1
			else:
				print("PASS: level %s loaded (%d rows × %d cols)" % [key, layout.size(), layout[0].size() if layout.size() > 0 else 0])
				pass_count += 1

	# 4. brick_types 完整
	for t in ["1", "2", "3", "-1"]:
		if not brick_types.has(t):
			printerr("FAIL: brick_type %s missing" % t)
			fail_count += 1
		else:
			print("PASS: brick_type %s present" % t)
			pass_count += 1

	# 5. 关卡内 layout 中的砖块类型都已定义
	for key in levels.keys():
		var layout: Array = (levels[key] as Dictionary).get("layout", [])
		for row in layout:
			for cell in row:
				var c := str(int(cell))
				if c == "0":
					continue
				if not brick_types.has(c):
					printerr("FAIL: level %s uses undefined brick_type %s" % [key, c])
					fail_count += 1
		print("PASS: level %s brick types valid" % key)
		pass_count += 1

	# 6. 球速递增检验
	var prev_speed := 0.0
	for n in range(1, 6):
		var key := str(n)
		var lv: Dictionary = levels[key]
		var spd: float = float(lv.get("ball_speed", 0))
		if spd < prev_speed:
			printerr("FAIL: level %s ball_speed %.0f < previous %.0f" % [key, spd, prev_speed])
			fail_count += 1
		else:
			print("PASS: level %s ball_speed %.0f >= previous %.0f" % [key, spd, prev_speed])
			pass_count += 1
		prev_speed = spd

	_finish(pass_count, fail_count)


func _finish(pass_n: int, fail_n: int) -> void:
	print("==========================================")
	print("Tests: %d passed, %d failed" % [pass_n, fail_n])
	print("==========================================")
	quit(0 if fail_n == 0 else 1)
