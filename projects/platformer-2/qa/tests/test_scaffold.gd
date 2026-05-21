extends SceneTree
# Smoke test for story-001-godot-scaffold (platformer-2 M1)
#
# 范围：仅 smoke 级 —— 验证脚手架可加载、Label 文本正确、_ready 不抛错。
#
# 注意（dev-story 红线）：
#   本 story 是脚手架（Node2D + Label），**不涉及玩家可见行为**，
#   因此本测试**不包含**真实玩家路径测试（Input.action_press / key event 模拟）。
#   story-002+（player 控制器、跳跃、移动等）必须含真实输入路径测试，
#   严禁通过直接修改 velocity / position / 内部 state 字段绕过输入层"假 PASS"。
#   参见：studio/docs/agents/tester.md §"真实玩家路径测试（红线）"
#
# 跑法：
#   godot --headless --script res://../qa/tests/test_scaffold.gd --quit
# 或从仓库根：
#   d:\AI\GameStudio\engine\Godot\Godot_v4.6.2-stable_win64.exe \
#     --headless --path d:\AI\GameStudio\projects\platformer-2\game \
#     --script d:\AI\GameStudio\projects\platformer-2\qa\tests\test_scaffold.gd --quit

func _init() -> void:
	var passed := 0
	var failed := 0

	# ---- 测试 1: main.tscn 能加载 ----
	var scene: PackedScene = load("res://main.tscn") as PackedScene
	if scene == null:
		push_error("[test_scaffold] FAIL test 1: main.tscn load returned null")
		failed += 1
	else:
		var instance := scene.instantiate()
		if instance == null:
			push_error("[test_scaffold] FAIL test 1: main.tscn instantiate returned null")
			failed += 1
		else:
			print("[test_scaffold] PASS test 1: main.tscn loaded & instantiated")
			passed += 1

			# ---- 测试 2: Label 文本正确 ----
			var label: Label = instance.find_child("Label", true, false) as Label
			if label == null:
				push_error("[test_scaffold] FAIL test 2: Label child not found")
				failed += 1
			elif label.text != "platformer-2 M1 prototype":
				push_error("[test_scaffold] FAIL test 2: Label.text mismatch, got: " + label.text)
				failed += 1
			else:
				print("[test_scaffold] PASS test 2: Label.text == 'platformer-2 M1 prototype'")
				passed += 1

			# ---- 测试 3: _ready 不抛错（add_child 触发 _ready） ----
			# 把 instance 挂到 root 下，Godot 会同步触发 _ready。
			# 若 main.gd 抛 push_error 或脚本异常，Godot 会立即报错；
			# 这里若到达后续 print 即认为 _ready 通过。
			get_root().add_child(instance)
			print("[test_scaffold] PASS test 3: main.gd _ready executed without error")
			passed += 1

			# 清理
			instance.queue_free()

	var total := passed + failed
	print("[test_scaffold] RESULT: PASS: %d/%d" % [passed, total])
	if failed > 0:
		print("[test_scaffold] FAILED: %d" % failed)
		quit(1)
	else:
		quit(0)
