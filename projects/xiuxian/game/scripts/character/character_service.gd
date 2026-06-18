# =============================================================================
# CharacterService.gd · 角色数据唯一入口（autoload，名字 CharacterService）
#
# 设计依据：GDD-02 契约层 + ADR-0003 + GDD-01 §6.12。
#
# 职责：
#   - 角色仓库（按 id 索引所有 Character）
#   - 契约接口：create / get / set_state / get_attribute / change_attribute
#   - 状态/属性变更时广播 signal（经 EventBus + CharacterRegistry.dispatch）
#
# 纪律：
#   - 子系统**不直接** character.action_state = X，必须走 set_action_state()
#   - 子系统**不直接** character.attributes[k] += v，必须走 change_attribute()
#   - 这样状态机校验 / signal 广播 / review 红线才能集中执行
#
# Godot Autoload：名字 CharacterService，路径 res://scripts/character/character_service.gd
#   顺序：在 EventBus / CharacterRegistry 之后
# =============================================================================
extends Node

# id → Character
var _characters: Dictionary = {}


func _ready() -> void:
	print("[CharacterService] ready")


# -----------------------------------------------------------------------------
# 仓库
# -----------------------------------------------------------------------------
func register(c: Character) -> void:
	_characters[c.id] = c


func create(id: String) -> Character:
	var c := Character.new(id)
	# 应用 CharacterRegistry 注册的扩展字段默认值
	for attr_id in CharacterRegistry.get_registered_attributes():
		if not c.attributes.has(attr_id):
			c.attributes[attr_id] = CharacterRegistry.get_attribute_default(attr_id)
	_characters[id] = c
	return c


func get_character(id: String) -> Character:
	return _characters.get(id, null)


func has(id: String) -> bool:
	return _characters.has(id)


func all() -> Array:
	return _characters.values()


func count() -> int:
	return _characters.size()


# -----------------------------------------------------------------------------
# 行动状态（互斥，走接口校验 + 广播）
# -----------------------------------------------------------------------------
func set_action_state(id: String, new_state: int, state_data: Dictionary = {}) -> bool:
	var c: Character = get_character(id)
	if c == null:
		push_error("[CharacterService] set_action_state: no character %s" % id)
		return false
	# DEAD 是终态，不可再转出
	if c.action_state == Character.ActionState.DEAD and new_state != Character.ActionState.DEAD:
		push_warning("[CharacterService] %s is DEAD, cannot change state" % id)
		return false
	var old_state := c.action_state
	c.action_state = new_state
	c.action_state_data = state_data
	var old_name := _state_name(old_state)
	var new_name := _state_name(new_state)
	EventBus.character_state_changed.emit(id, old_name, new_name)
	CharacterRegistry.dispatch("state_changed", [id, old_name, new_name])
	if new_state == Character.ActionState.DEAD:
		var cause: String = state_data.get("cause", "unknown")
		EventBus.character_died.emit(id, cause)
		CharacterRegistry.dispatch("died", [id, cause])
	return true


func _state_name(s: int) -> String:
	match s:
		Character.ActionState.IDLE: return "idle"
		Character.ActionState.IN_CULTIVATION: return "in_cultivation"
		Character.ActionState.DEAD: return "dead"
		_: return "unknown"


# -----------------------------------------------------------------------------
# 身份（数据驱动转移规则 M2 后期接 identity_transitions.json；M3 先宽松）
# -----------------------------------------------------------------------------
func change_identity(id: String, new_identity: int) -> bool:
	var c: Character = get_character(id)
	if c == null:
		return false
	c.identity = new_identity
	return true


# -----------------------------------------------------------------------------
# 属性（面板属性，如悟性/体魄；走接口便于 review + 未来 signal）
# -----------------------------------------------------------------------------
func get_attribute(id: String, key: String, default_value: Variant = 0) -> Variant:
	var c: Character = get_character(id)
	if c == null:
		return default_value
	return c.attributes.get(key, default_value)


func set_attribute(id: String, key: String, value: Variant) -> bool:
	var c: Character = get_character(id)
	if c == null:
		return false
	c.attributes[key] = value
	return true


func change_attribute(id: String, key: String, delta: Variant) -> bool:
	var c: Character = get_character(id)
	if c == null:
		return false
	var cur = c.attributes.get(key, 0)
	c.attributes[key] = cur + delta
	return true


# -----------------------------------------------------------------------------
# 寿元（契约层；衰减玩法在 GDD-04，这里只提供读写 + 濒死广播）
# -----------------------------------------------------------------------------
func decrease_lifespan(id: String, months: int = 1, warning_threshold: int = 50) -> void:
	var c: Character = get_character(id)
	if c == null:
		return
	# 寿元未初始化（total=0）视为不参与衰减（测试用临时角色 / 未配置寿元的实体）
	if c.lifespan_total_months <= 0:
		return
	c.lifespan_remaining_months -= months
	if c.lifespan_remaining_months <= 0:
		set_action_state(id, Character.ActionState.DEAD, {"cause": "lifespan_exhausted"})
	elif c.lifespan_remaining_months <= warning_threshold:
		EventBus.lifespan_warning.emit(id, c.lifespan_remaining_months)


# -----------------------------------------------------------------------------
# 序列化（ADR-0004）
# -----------------------------------------------------------------------------
func to_dict() -> Dictionary:
	var out: Dictionary = {}
	for id in _characters:
		out[id] = _characters[id].to_dict()
	return out


func from_dict(d: Dictionary) -> void:
	_characters.clear()
	for id in d:
		_characters[id] = Character.from_dict(d[id])
