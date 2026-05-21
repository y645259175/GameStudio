extends Node
## 截图工具 — AP-10 修法 in-context 渲染评审用
## 启动场景，等几秒后从 3 个位置截图（出生点 / 中段 / 谜题区）

@export var output_dir: String = "user://screenshots/"
@export var capture_delay: float = 1.0  ## 等场景稳定再截
@export var capture_positions: Array[Vector2] = [
	Vector2(64, 400),    # 出生点
	Vector2(640, 400),   # 中段
	Vector2(960, 400),   # 谜题区
]

var _player: Node2D = null
var _idx: int = 0


func _ready() -> void:
	# 确保截图目录存在
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output_dir))
	_player = get_tree().get_first_node_in_group("player")
	if _player == null:
		# 退而求其次，按名字找
		_player = get_tree().current_scene.find_child("Player", true, false)
	print("[capture] start; player=", _player, " positions=", capture_positions.size())
	await get_tree().create_timer(capture_delay).timeout
	_capture_next()


func _capture_next() -> void:
	if _idx >= capture_positions.size():
		print("[capture] DONE, captured ", capture_positions.size(), " shots")
		get_tree().quit()
		return

	var pos := capture_positions[_idx]
	if _player:
		_player.global_position = pos
		if "velocity" in _player:
			_player.velocity = Vector2.ZERO
	# 等 2 帧让 Camera2D smoothing 跟上
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().create_timer(0.3).timeout

	var img := get_viewport().get_texture().get_image()
	var fname := "%scapture_%02d_x%d.png" % [output_dir, _idx, int(pos.x)]
	var err := img.save_png(fname)
	var path_msg := ProjectSettings.globalize_path(fname)
	print("[capture] ", _idx, " saved: ", path_msg, " err=", err)
	_idx += 1
	_capture_next()
