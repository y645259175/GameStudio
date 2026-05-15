extends Camera2D

## Sprint 1 简版：横向跟随玩家，不可回退
## Sprint 2 接入完整 deadzone / lookahead

@export var target_path: NodePath

var _target: Node2D = null
var _max_x_reached: float = 0.0
var _bounds_left: float = 0.0
var _bounds_right: float = 3200.0
var _viewport_half_w: float = 640.0


func _ready() -> void:
	if target_path:
		_target = get_node(target_path) as Node2D
	var cl := _get_cl()
	if cl:
		_bounds_left = float(cl.get_value("camera.bounds.left", 0))
		_bounds_right = float(cl.get_value("camera.bounds.right", 3200))


func _get_cl() -> Node:
	var tree := Engine.get_main_loop() as SceneTree
	if tree and tree.root.has_node("ConfigLoader"):
		return tree.root.get_node("ConfigLoader")
	return null


func _process(_delta: float) -> void:
	if not _target or not is_instance_valid(_target):
		return
	# 跟随玩家 X，但不可回退
	var target_x: float = _target.global_position.x
	if target_x > _max_x_reached:
		_max_x_reached = target_x
	# 屏幕中心 X 不能小于已到达的最大 X
	var cam_x: float = clamp(_max_x_reached, _bounds_left + _viewport_half_w, _bounds_right - _viewport_half_w)
	global_position.x = cam_x
	global_position.y = 360  # 固定 Y（1-1 不上下滚）
