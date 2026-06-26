# =============================================================================
# RecruitService.gd · 弟子招收（autoload，GDD-05 §8）
#
# 2 条来源：① 自动来投（月节拍按概率，passive_seeker 资质偏低）
#           ② 主动招收（玩家发起，active_recruit 资质中偏上，扣灵石 + 1 月）
# 受 housing_capacity 硬约束（GDD-05 §8.5）。
# 候选生成走内置 CharacterGenerator（GDD-02 §5.2/5.3 模板）。
# =============================================================================
extends Node

signal recruit_candidates_ready(candidates: Array)   # 主动招收候选就绪
signal auto_recruit_arrived(candidate: Dictionary)   # 自动来投

const ACTIVE_RECRUIT_COST := 300        # 主动招收灵石成本（GDD-06）
const AUTO_RECRUIT_CHANCE := 0.22       # 每月自动来投基础概率（平均 ~4.5 月一次）

var _pending_active := false            # 主动招收进行中（1 月出结果）
var _recruit_counter := 0

# 姓名池（生成用，GDD-02 §5.3）
const SURNAMES := ["云","林","苏","秦","顾","萧","江","沈","陆","白","叶","唐","柳","卫","池"]
const GIVEN_CN := ["清玄","长歌","若水","明松","致远","逸尘","寒星","疏影","承志","知微","景行","明澈","映雪","怀瑾","观澜"]


func _ready() -> void:
	if TimeService:
		TimeService.month_advanced.connect(_on_month_advanced)
	print("[RecruitService] ready")


# -----------------------------------------------------------------------------
# 容量检查（GDD-05 §8.5）
# -----------------------------------------------------------------------------
func has_housing_room() -> bool:
	return SectService.member_count() < BuildingService.get_housing_capacity()


# -----------------------------------------------------------------------------
# 主动招收（GDD-05 §8.3）
# -----------------------------------------------------------------------------
func can_start_active_recruit() -> bool:
	return (not _pending_active) and has_housing_room() and InventoryService.has("spirit_stone", ACTIVE_RECRUIT_COST)


func start_active_recruit() -> bool:
	if not can_start_active_recruit():
		return false
	if not InventoryService.consume("spirit_stone", ACTIVE_RECRUIT_COST):
		return false
	_pending_active = true
	return true


func is_recruiting() -> bool:
	return _pending_active


# -----------------------------------------------------------------------------
# 月节拍：推进主动招收 + 滚自动来投
# -----------------------------------------------------------------------------
func _on_month_advanced(_m: int, _y: int, _moy: int) -> void:
	# 主动招收出结果（GDD-05 §8.3：1 月后给 1-3 候选）
	if _pending_active:
		_pending_active = false
		var n := 1 + (randi() % 3)
		var candidates: Array = []
		for i in range(n):
			candidates.append(generate("active_recruit"))
		recruit_candidates_ready.emit(candidates)
	# 自动来投（GDD-05 §8.2）
	elif has_housing_room() and randf() < AUTO_RECRUIT_CHANCE:
		auto_recruit_arrived.emit(generate("passive_seeker"))


# -----------------------------------------------------------------------------
# 接收候选（玩家选中后落地为正式弟子）
# -----------------------------------------------------------------------------
func accept_candidate(candidate: Dictionary) -> String:
	if not has_housing_room():
		return ""
	_recruit_counter += 1
	var cid := "char_recruit_%d" % _recruit_counter
	var c := CharacterService.create(cid)
	c.identity = Character.Identity.DISCIPLE
	c.character_name = candidate.get("name", "无名")
	c.gender = candidate.get("gender", "male")
	c.realm = "qi_1"
	c.sub_level = 1
	c.portrait_id = candidate.get("portrait", "res://art/m3/portraits/disciple_recruit.png")
	c.spirit_root = candidate.get("spirit_root", {})
	c.attributes = candidate.get("attributes", {})
	c.lifespan_total_months = 720
	c.lifespan_remaining_months = 720
	SectService.add_member(cid)
	return cid


# -----------------------------------------------------------------------------
# CharacterGenerator（GDD-02 §5.2/5.3 模板，M3 内置简版）
# -----------------------------------------------------------------------------
func generate(template_id: String) -> Dictionary:
	# 模板决定资质档次（GDD-05 §8.1）
	var root_total: int
	var insight_base: int
	match template_id:
		"active_recruit":     root_total = 8 + randi() % 7    # 8-14（中偏上）
		"expedition_rescue":  root_total = 12 + randi() % 8   # 12-19（偏高）
		_:                    root_total = 4 + randi() % 6    # passive 4-9（偏低）
	insight_base = 90 + randi() % 40

	# 随机分配灵根点数到 1-2 个五行
	var elements := ["fire", "water", "wood", "metal", "earth"]
	elements.shuffle()
	var roots: Dictionary = {}
	var n_elem := 1 + randi() % 2
	var remaining := root_total
	for i in range(n_elem):
		if i == n_elem - 1:
			roots[elements[i]] = remaining
		else:
			var part: int = 1 + randi() % int(max(1, remaining - 1))
			roots[elements[i]] = part
			remaining -= part

	var gender := "male" if randf() < 0.5 else "female"
	var portrait := "res://art/m3/portraits/disciple_male.png" if gender == "male" else "res://art/m3/portraits/disciple_female.png"

	return {
		"name": _gen_name(),
		"gender": gender,
		"portrait": portrait,
		"spirit_root": roots,
		"root_total": root_total,
		"template_id": template_id,
		"attributes": {
			"insight": insight_base,
			"physique": 40 + randi() % 40,
			"shenshi": 40 + randi() % 40,
			"alchemy": randi() % 20,
			"forging": randi() % 20,
			"experience": 0.0,
		},
		"age_years": 14 + randi() % 6,
	}


func _gen_name() -> String:
	return SURNAMES[randi() % SURNAMES.size()] + GIVEN_CN[randi() % GIVEN_CN.size()]
