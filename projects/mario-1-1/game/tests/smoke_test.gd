extends SceneTree

## smoke_test · 自动化烟雾测试
## 启动 main 场景，跑 N 帧，检查关键节点是否生成
## 注意：用 -s 模式时 autoload 不激活，本测试需要主场景已加载（间接调用）

func _init() -> void:
	# 切换到 main 场景
	await process_frame
	change_scene_to_file("res://scenes/main.tscn")
	await process_frame
	await process_frame
	await create_timer(0.5).timeout

	var root := get_root()
	var main := root.get_node_or_null("Main")
	if not main:
		push_error("[SMOKE] Main not found")
		quit(1)
		return

	var ll := main.get_node_or_null("LevelLoader")
	if not ll:
		push_error("[SMOKE] LevelLoader not found")
		quit(1)
		return

	var entities := ll.get_node_or_null("Entities")
	if not entities:
		push_error("[SMOKE] Entities not found")
		quit(1)
		return

	var ground := entities.get_node_or_null("Ground")
	var blocks := entities.get_node_or_null("Blocks")
	var enemies := entities.get_node_or_null("Enemies")
	var triggers := entities.get_node_or_null("Triggers")

	print("[SMOKE] Ground children: %d" % (ground.get_child_count() if ground else -1))
	print("[SMOKE] Blocks children: %d" % (blocks.get_child_count() if blocks else -1))
	print("[SMOKE] Enemies children: %d" % (enemies.get_child_count() if enemies else -1))
	print("[SMOKE] Triggers children: %d" % (triggers.get_child_count() if triggers else -1))

	var player := main.get_node_or_null("Player")
	if player:
		print("[SMOKE] Player position: %s" % player.global_position)
		print("[SMOKE] Player velocity: %s" % player.velocity)

	# 跑 3 秒，看 player 是否还活着（不掉死亡线）
	await create_timer(3.0).timeout
	if player and is_instance_valid(player):
		print("[SMOKE] After 3s player y: %f" % player.global_position.y)

	# 通过 root 找 autoload
	var gm := root.get_node_or_null("GameManager")
	if gm:
		print("[SMOKE] lives=%d score=%d time=%d" % [gm.get("lives"), gm.get("score"), gm.get("time_left")])

	print("[SMOKE] PASS")
	quit(0)

