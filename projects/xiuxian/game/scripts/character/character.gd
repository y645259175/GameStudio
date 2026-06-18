# =============================================================================
# Character.gd · 角色统一数据结构（ADR-0003 三维度 + IBuffable）
#
# 核心设定：门主 / 弟子 / 长老 / 宗外人物在数据层面是同一种结构，区别只在 identity。
# 三维度：
#   Identity     身份（长期，互斥）
#   ActionState  行动状态（即时，互斥）
#   Buffs        修饰器（多个并存，由 BuffService 管理）—— 继承自 IBuffable
#
# 纪律（GDD-01 §6.12）：
#   - 本类是契约层（字段 schema + 状态枚举），不持有成长/突破/觉醒玩法公式
#   - 临时修饰（中毒/受伤/加速）走 buff，不在此加独立字段
#   - 子系统改字段必须走 CharacterService 接口，不直接写 character.xxx
# =============================================================================
class_name Character
extends IBuffable

# 身份（长期稳定，互斥）
enum Identity {
	MASTER_CURRENT,    # 现任门主
	DISCIPLE,          # 本宗弟子
	ELDER,             # 长老阁（仅主动传位的前门主）
	NON_SECT,          # 宗门外人物
}

# 行动状态（即时，每月可刷新，互斥）
enum ActionState {
	IDLE,              # 空闲
	IN_CULTIVATION,    # 修炼中（含闭关；子模式由 action_state_data.mode 区分）
	DEAD,              # 死亡（终态）
}

# === 核心字段 ===
var id: String = ""
var character_name: String = ""        # 玩家可见名（GDScript 'name' 是 Node 属性，这里用 character_name）
var original_name: String = ""
var gender: String = "male"
var identity: int = Identity.DISCIPLE
var action_state: int = ActionState.IDLE
var non_sect_role: String = ""
var portrait_id: String = ""
var age_months: int = 0

# === 内容字段（M3 schema / 内容 M5+）===
var traits: Array = []
var personality: String = ""
var origin: String = ""

# === 修仙属性 ===
var spirit_root: Dictionary = {}       # {fire:int, water:int, wood:int, metal:int, earth:int}（base 永久值）
var realm: String = "qi_1"             # 境界 id（如 qi_1 = 炼气1层）；契约层只存 id，玩法在 GDD-04
var sub_level: int = 1                 # 小境界层数 1-9
var lifespan_total_months: int = 0
var lifespan_remaining_months: int = 0
var attributes: Dictionary = {}        # 悟性/体魄/神识/炼丹/炼器（GDD-02 §3）

# === 战斗衍生（M3 占位 / M5 启用）===
var skills: Array = []
var equipped: Dictionary = {}

# === 各状态附加数据 ===
var action_state_data: Dictionary = {} # IN_CULTIVATION → {mode, since_month, ...} / DEAD → {died_at_month, cause}


func _init(p_id: String = "") -> void:
	id = p_id
	target_id = p_id
	target_type = TargetType.CHARACTER


# -----------------------------------------------------------------------------
# 序列化（ADR-0004 存档；buffs 由 BuffService 序列化各 Buff）
# -----------------------------------------------------------------------------
func to_dict() -> Dictionary:
	var buff_dicts: Array = []
	for b in buffs:
		buff_dicts.append(b.to_dict())
	return {
		"id": id,
		"character_name": character_name,
		"original_name": original_name,
		"gender": gender,
		"identity": identity,
		"action_state": action_state,
		"non_sect_role": non_sect_role,
		"portrait_id": portrait_id,
		"age_months": age_months,
		"traits": traits,
		"personality": personality,
		"origin": origin,
		"spirit_root": spirit_root,
		"realm": realm,
		"sub_level": sub_level,
		"lifespan_total_months": lifespan_total_months,
		"lifespan_remaining_months": lifespan_remaining_months,
		"attributes": attributes,
		"skills": skills,
		"equipped": equipped,
		"action_state_data": action_state_data,
		"buffs": buff_dicts,
	}


static func from_dict(d: Dictionary) -> Character:
	var c := Character.new(d.get("id", ""))
	c.character_name = d.get("character_name", "")
	c.original_name = d.get("original_name", "")
	c.gender = d.get("gender", "male")
	c.identity = d.get("identity", Identity.DISCIPLE)
	c.action_state = d.get("action_state", ActionState.IDLE)
	c.non_sect_role = d.get("non_sect_role", "")
	c.portrait_id = d.get("portrait_id", "")
	c.age_months = d.get("age_months", 0)
	c.traits = d.get("traits", [])
	c.personality = d.get("personality", "")
	c.origin = d.get("origin", "")
	c.spirit_root = d.get("spirit_root", {})
	c.realm = d.get("realm", "qi_1")
	c.sub_level = d.get("sub_level", 1)
	c.lifespan_total_months = d.get("lifespan_total_months", 0)
	c.lifespan_remaining_months = d.get("lifespan_remaining_months", 0)
	c.attributes = d.get("attributes", {})
	c.skills = d.get("skills", [])
	c.equipped = d.get("equipped", {})
	c.action_state_data = d.get("action_state_data", {})
	c.buffs = []
	for bd in d.get("buffs", []):
		c.buffs.append(Buff.from_dict(bd))
	return c
