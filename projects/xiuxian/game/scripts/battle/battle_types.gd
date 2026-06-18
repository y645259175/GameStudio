# =============================================================================
# battle_types.gd · 战斗输入/输出契约（ADR-0002）
#
# BattleContext（输入）+ BattleResult（输出）。用 class_name 供各接入点构造。
# 放一个文件里方便 M3；M5 拆分。
# =============================================================================
class_name BattleContext
extends RefCounted

var attackers: Array = []          # Array[Character]
var defenders: Array = []          # Array[Character]
var env: Dictionary = {}           # 开放扩展（地形/天候，GDD-03 §7.4 白名单）
var seed: int = 0                  # 调用方传入，可复现
var escape_allowed: bool = false
var trigger_source: String = ""    # "expedition_event" / "sect_invasion" / ...
