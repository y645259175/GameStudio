# =============================================================================
# CharacterRegistry.gd · 角色契约扩展点（autoload，名字 CharacterRegistry）
#
# 设计依据：ADR-0003 v3.3 amendment + GDD-01 §6.12（角色契约 vs 子系统玩法分离）。
#
# 核心约束：子系统通过本注册表扩展角色契约，**不修改 Character 源码**。
#   - register_state_mode        子系统注册某 ActionState 的子模式（cultivating: normal/bottleneck）
#   - register_attribute         子系统注册新字段（M5 心境 mental_state）
#   - register_attribute_modifier_source  声明"我会通过 buff 改某属性"（用于依赖图/review）
#   - register_signal_listener   子系统挂 character 事件监听器
#
# Godot Autoload 注册：名字 CharacterRegistry，路径 res://scripts/character/character_registry.gd
#   顺序：在 EventBus 之后（监听器可能转发到 EventBus）
# =============================================================================
extends Node

# state_modes[action_state_name] = Array[mode_id]
var _state_modes: Dictionary = {}
# attributes[attr_id] = {default, type}
var _registered_attributes: Dictionary = {}
# modifier_sources[source_id] = Array[target_attr]
var _modifier_sources: Dictionary = {}
# signal_listeners[signal_name] = Array[Callable]
var _signal_listeners: Dictionary = {}


func _ready() -> void:
	print("[CharacterRegistry] ready")


# -----------------------------------------------------------------------------
# 状态子模式扩展
# -----------------------------------------------------------------------------
## 注册某 ActionState 的子模式（如 cultivating 的 normal/bottleneck/deep_retreat）
func register_state_mode(action_state: String, mode_id: String) -> void:
	if not _state_modes.has(action_state):
		_state_modes[action_state] = []
	if mode_id != "" and not _state_modes[action_state].has(mode_id):
		_state_modes[action_state].append(mode_id)


func get_state_modes(action_state: String) -> Array:
	return _state_modes.get(action_state, [])


func is_valid_state_mode(action_state: String, mode_id: String) -> bool:
	return _state_modes.get(action_state, []).has(mode_id)


# -----------------------------------------------------------------------------
# 字段扩展（注册后序列化自动包含；get/set 可校验）
# -----------------------------------------------------------------------------
func register_attribute(attribute_id: String, default_value: Variant, value_type: String = "auto") -> void:
	_registered_attributes[attribute_id] = {
		"default": default_value,
		"type": value_type,
	}


func get_registered_attributes() -> Dictionary:
	return _registered_attributes


func get_attribute_default(attribute_id: String) -> Variant:
	var e: Dictionary = _registered_attributes.get(attribute_id, {})
	return e.get("default", null)


# -----------------------------------------------------------------------------
# Modifier 来源声明（用于 review / 依赖图 / 自动生成文档）
# -----------------------------------------------------------------------------
func register_attribute_modifier_source(source_id: String, modifier_targets: Array) -> void:
	_modifier_sources[source_id] = modifier_targets


func get_modifier_sources() -> Dictionary:
	return _modifier_sources


# -----------------------------------------------------------------------------
# Signal 监听（子系统挂 character 事件，避免散接）
# -----------------------------------------------------------------------------
func register_signal_listener(signal_name: String, callback: Callable) -> void:
	if not _signal_listeners.has(signal_name):
		_signal_listeners[signal_name] = []
	_signal_listeners[signal_name].append(callback)


func get_signal_listeners(signal_name: String) -> Array:
	return _signal_listeners.get(signal_name, [])


## 由 CharacterService 调用：分发某 character 事件给所有注册监听器
func dispatch(signal_name: String, args: Array = []) -> void:
	for cb in _signal_listeners.get(signal_name, []):
		if cb.is_valid():
			cb.callv(args)


# -----------------------------------------------------------------------------
# 调试
# -----------------------------------------------------------------------------
func debug_dump() -> Dictionary:
	return {
		"state_modes": _state_modes,
		"attributes": _registered_attributes.keys(),
		"modifier_sources": _modifier_sources.keys(),
		"signal_listeners": _signal_listeners.keys(),
	}
