# =============================================================================
# expedition_probe.gd · 历练界面「真点击」交互+截图探针
# 通过 emit_signal("pressed") 真实点击按钮模拟玩家，验证无死锁 + 选项玩法。
# =============================================================================
extends Node

var _screen: Control = null
var _shot_options_done := false
var _shot_post_choice_done := false


func _ready() -> void:
	await get_tree().process_frame
	_run()


func _run() -> void:
	GameManager._init_world_data()
	await get_tree().create_timer(0.3).timeout
	ExpeditionService.start_expedition_ui("青岚秘境", _party_ids())
	var packed: PackedScene = load("res://scenes/expedition_screen.tscn")
	_screen = packed.instantiate()
	get_tree().root.add_child(_screen)
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().create_timer(0.5).timeout
	await _shot("expedition_start")

	print("[probe] loop start, node_count=%d" % ExpeditionService.node_count())
	var step := 0
	for frame in range(120):
		await get_tree().create_timer(0.12).timeout
		if not is_instance_valid(_screen):
			break
		var finished: bool = (_screen.get("_finished") == true)
		if finished:
			await get_tree().create_timer(0.2).timeout
			await _shot("expedition_end")
			print("[probe] PASS expedition finished + settle shown")
			break
		var opt_box: VBoxContainer = _screen.get_node_or_null("%OptionBox")
		var continue_btn: Button = _screen.get_node_or_null("%ContinueBtn")
		if opt_box and opt_box.visible and opt_box.get_child_count() > 0:
			if not _shot_options_done:
				await _shot("expedition_options")
				_shot_options_done = true
				print("[probe] PASS options shown (%d options)" % opt_box.get_child_count())
			var picked: Button = null
			for ch in opt_box.get_children():
				if ch is Button and not (ch as Button).disabled:
					picked = ch
					break
			if picked == null and opt_box.get_child_count() > 0:
				picked = opt_box.get_child(0)
			if picked:
				picked.emit_signal("pressed")
			await get_tree().create_timer(0.25).timeout
			if not _shot_post_choice_done:
				await _shot("expedition_post_choice")
				_shot_post_choice_done = true
				print("[probe] PASS choice outcome shown")
			continue
		if continue_btn and not continue_btn.disabled:
			continue_btn.emit_signal("pressed")
			step += 1
			if step == 2:
				await get_tree().create_timer(0.2).timeout
				await _shot("expedition_mid")
			continue

	if _shot_options_done:
		print("[probe] PASS option interaction chain OK")
	else:
		print("[probe] WARN no option event rolled this run")
	_done()


func _shot(shot_name: String) -> void:
	var img: Image = get_viewport().get_texture().get_image()
	img.save_png("res://_shots/%s.png" % shot_name.replace(" ", "_"))
	await get_tree().process_frame


func _party_ids() -> Array:
	var party: Array[String] = []
	for cid in SectService.get_member_ids():
		party.append(cid)
	return party


func _done() -> void:
	get_tree().quit()
