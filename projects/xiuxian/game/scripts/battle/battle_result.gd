# =============================================================================
# battle_result.gd · 战斗输出契约（ADR-0002）
# =============================================================================
class_name BattleResult
extends RefCounted

var version: int = 1               # M3=1 / M5=2
var winner: String = "DRAW"        # ATTACKERS / DEFENDERS / DRAW / ESCAPED
var hp_changes: Dictionary = {}    # actor_id → hp_delta
var status_changes: Array = []     # 战后挂的 buff/debuff（{target_id, category, subtype, attributes}）
var loot: Dictionary = {}          # 战利品
var log_entries: Array = []        # 战斗日志（v1 仅总结）
var narrative_seed: int = 0
