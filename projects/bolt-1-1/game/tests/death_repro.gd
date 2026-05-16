extends SceneTree

## 复现"死亡卡死"bug：模拟玩家死亡，跑 6 秒看会发生什么

func _init() -> void:
	await process_frame
	change_scene_to_file("res://scenes/main.tscn")
	await process_frame
	await create_timer(0.5).timeout

	var root := get_root()
	var main := root.get_node_or_null("Main")
	var player := main.get_node_or_null("Player") if main else null
	var gm := root.get_node_or_null("GameManager")
	if not player or not gm:
		push_error("setup failed")
		quit(1)
		return

	print("[DEATH] before kill: pos=%s state=%s lives=%d" % [player.global_position, player.current_state, gm.lives])

	# 直接调 take_damage 模拟 small 态被怪物撞
	player.take_damage()
	await physics_frame
	print("[DEATH] just after take_damage: state=%s lives=%d main._is_dead=%s" % [
		player.current_state, gm.lives, main._is_dead
	])

	# 跑 4 秒看死亡 → 重生流程
	for i in range(240):
		await physics_frame
		if i % 60 == 0:
			print("[DEATH] f=%d t=%.1fs pos=%s vel=%s state=%s mask=%d _is_dead=%s _resp_t=%.2f lives=%d" % [
				i, i/60.0, player.global_position, player.velocity, player.current_state,
				player.collision_mask, main._is_dead, main._respawn_timer, gm.lives
			])

	# 现在尝试输入推进玩家
	print("[DEATH] === try input after death sequence ===")
	Input.action_press("move_right")
	for i in range(120):
		await physics_frame
		if i % 30 == 0:
			print("[DEATH] post-resp f=%d pos=%s vel=%s state=%s on_floor=%s" % [
				i, player.global_position, player.velocity, player.current_state, player.is_on_floor()
			])
	Input.action_release("move_right")

	quit(0)

