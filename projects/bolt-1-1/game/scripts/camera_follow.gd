extends Camera2D

## Sprint 1 简版：横向跟随玩家，不可回退
## Sprint 2 接入完整 deadzone / lookahead
## M6.1：加 zoom 1.5x 让视觉接近马里奥原作（256×240 视觉感），
##       camera y 跟玩家在限定范围内移动，确保地面 y=672 始终在屏幕内

@export var target_path: NodePath

var _target: Node2D = null
var _max_x_reached: float = 0.0
var _bounds_left: float = 0.0
var _bounds_right: float = 3200.0
# zoom=1.5 → 视野 853×480。camera y 中心需放到能看见地面的位置：
# 地面 y=672，要求屏幕底 ≥ 672，即 cam_y + 240 ≥ 672 → cam_y ≥ 432
# 同时屏幕顶 ≤ -50（避免上方留太多）→ cam_y - 240 ≤ -50 不实际
# 实际策略：cam_y = clamp(player.y - 100, 432, 472)，让 player 出现在屏幕中下部
const _CAM_ZOOM: float = 1.5
const _VIEW_HALF_W: float = 1280.0 / (2.0 * _CAM_ZOOM)  # 426.67
const _VIEW_HALF_H: float = 720.0 / (2.0 * _CAM_ZOOM)   # 240
const _CAM_Y_MIN: float = 432.0  # 屏幕底刚好到 672（地面）
const _CAM_Y_MAX: float = 480.0  # 屏幕底到 720（最低，玩家落到坑底前一刻）


func _ready() -> void:
	if target_path:
		_target = get_node(target_path) as Node2D
	var cl := _get_cl()
	if cl:
		_bounds_left = float(cl.get_value("camera.bounds.left", 0))
		_bounds_right = float(cl.get_value("camera.bounds.right", 3200))
	zoom = Vector2(_CAM_ZOOM, _CAM_ZOOM)


func _get_cl() -> Node:
	var tree := Engine.get_main_loop() as SceneTree
	if tree and tree.root.has_node("ConfigLoader"):
		return tree.root.get_node("ConfigLoader")
	return null


## 死亡重生时调用：重置 no-scroll-back 状态，让镜头能回到 spawn 位置
func reset_to_target() -> void:
	if _target:
		_max_x_reached = _target.global_position.x


func _process(_delta: float) -> void:
	if not _target or not is_instance_valid(_target):
		return
	# X 跟随玩家，但不可回退
	var target_x: float = _target.global_position.x
	if target_x > _max_x_reached:
		_max_x_reached = target_x
	var cam_x: float = clamp(_max_x_reached, _bounds_left + _VIEW_HALF_W, _bounds_right - _VIEW_HALF_W)
	global_position.x = cam_x
	# Y 在限定范围内跟随（让地面始终可见 + 玩家在屏幕中下部）
	var target_y: float = clamp(_target.global_position.y - 80.0, _CAM_Y_MIN, _CAM_Y_MAX)
	global_position.y = target_y
