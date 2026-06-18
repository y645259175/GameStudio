# =============================================================================
# TimeService.gd · 双层时钟（autoload，名字 TimeService）
#
# 设计依据：ADR-0001 双层时钟（v1.0）+ Amendment v1.1（接口扩充）。
#
# 双层时钟模型：
#   外层 = 大世界月节拍（current_month，从 1 起，连续推进，历练中也推进）
#   内层 = 历练百分比时钟（remaining_percent，100→0，每跨 1/N 月阈值广播 month_advanced）
#
# 核心规则（ADR-0001 v2）：
#   1. 大世界月份是唯一节拍；历练中途按百分比映射到月份并广播 month_advanced
#      - N 月图：每跨过 1/N 进度即广播下一月开始；100% 完成时再 +1 月收尾
#   2. 历练中途撤退消耗月数 = ceil(progress * max_months)
#   3. 所有系统只通过 signal 订阅时间，不直接读 current_month 做月度逻辑
#
# 注意：autoload 已提供全局单例名 TimeService，故本文件不写 class_name（避免重名冲突）。
#
# Godot Project Settings → Autoload → 注册：
#   名字: TimeService  路径: res://game/scripts/services/time_service.gd
#   顺序: 在 EventBus 之后
# =============================================================================
extends Node

# -----------------------------------------------------------------------------
# Signal（ADR-0001 v1.1）。TimeService 是时间权威源；同时转发到 EventBus。
# -----------------------------------------------------------------------------
signal month_advanced(new_month: int, year: int, month_of_year: int)
signal year_advanced(new_year: int)
signal progress_advanced(new_remaining_percent: int, just_consumed: int)
signal expedition_time_warning(threshold: String)  # "warning"(30%) / "critical"(10%)

# 撤离结束原因（与 ADR-0001 ExpeditionEndReason 对齐）
enum ExpeditionEndReason { COMPLETED, RETREAT, TIMEOUT, DEFEAT }

const DAYS_PER_MONTH := 30

# -----------------------------------------------------------------------------
# 状态（全部进存档；M2 SaveService 实装后通过 to_dict/from_dict 序列化）
# -----------------------------------------------------------------------------
var _current_month: int = 1               # 外层时钟，从 1 起
var _expedition_active: bool = false
var _expedition_max_months: int = 1       # 当前历练图最大月数（1/2/3...）
var _remaining_percent: int = 100         # 内层时钟，100 → 0
var _pending_day_accumulator: int = 0     # advance_outer_by_days 的不满 30 天累积
var _timeout_pending: bool = false        # remaining_percent 见底时标记（GDD-03 §4.3）
var _warning_fired: Dictionary = {}       # 防止 warning/critical 重复广播


func _ready() -> void:
	print("[TimeService] ready, month=%d" % _current_month)


# =============================================================================
# 大世界（月节拍）
# =============================================================================

func get_current_month() -> int:
	return _current_month


func get_current_year() -> int:
	# 月从 1 起：1-12 月 = 第 1 年
	return (_current_month - 1) / 12 + 1


func get_month_of_year() -> int:
	return (_current_month - 1) % 12 + 1


## 推进 N 月（逐月广播 month_advanced）。触发：撤离回宗 / debug 跳月 / 月结算 tick。
func advance_outer(months: int) -> void:
	if months <= 0:
		return
	for _i in range(months):
		_advance_one_month()


## 按天推进（ADR-0001 v1.1 待解小细节决议：内部累计满 30 天广播一次月节拍）。
## 用于撤离回宗（1/3/7 天）等"天级"推进，避免四舍五入丢精度。
func advance_outer_by_days(days: int) -> void:
	if days <= 0:
		return
	_pending_day_accumulator += days
	while _pending_day_accumulator >= DAYS_PER_MONTH:
		_pending_day_accumulator -= DAYS_PER_MONTH
		_advance_one_month()


func _advance_one_month() -> void:
	var prev_year := get_current_year()
	_current_month += 1
	var year := get_current_year()
	var moy := get_month_of_year()
	month_advanced.emit(_current_month, year, moy)
	EventBus.month_advanced.emit(_current_month, year, moy)
	if year != prev_year:
		year_advanced.emit(year)
		EventBus.year_advanced.emit(year)


# =============================================================================
# 历练内层（百分比时钟）
# =============================================================================

## 进入历练。initial_percent 通常 100。max_months 决定跨月阈值密度。
func enter_expedition(map_id: String, max_months: int = 1, initial_percent: int = 100) -> void:
	_expedition_active = true
	_expedition_max_months = max(1, max_months)
	_remaining_percent = clampi(initial_percent, 0, 100)
	_timeout_pending = false
	_warning_fired.clear()
	EventBus.expedition_started.emit(map_id, _expedition_max_months)


## 退出历练。reason 见 ExpeditionEndReason。结算消耗的整月数 = ceil((100-remaining)/100 * max_months)。
func exit_expedition(reason: ExpeditionEndReason = ExpeditionEndReason.COMPLETED) -> int:
	if not _expedition_active:
		return 0
	var consumed_ratio := float(100 - _remaining_percent) / 100.0
	var months_consumed := int(ceil(consumed_ratio * _expedition_max_months))
	# COMPLETED 至少推满整图月数
	if reason == ExpeditionEndReason.COMPLETED:
		months_consumed = _expedition_max_months
	_expedition_active = false
	var reason_str := _reason_to_string(reason)
	EventBus.expedition_ended.emit(reason_str, months_consumed)
	return months_consumed


func is_expedition_active() -> bool:
	return _expedition_active


func get_expedition_remaining_percent() -> int:
	return _remaining_percent


## 推进 N% 历练进度。触发：节点进入 / 选项 cost_time / 事件 action 消耗。
## 内部：跨月阈值则广播 month_advanced；见底标记 timeout_pending。
func advance_progress(percent: int) -> void:
	if not _expedition_active or percent <= 0:
		return
	var before := _remaining_percent
	var after := clampi(before - percent, 0, 100)
	var just_consumed := before - after

	# 检查是否跨过 1/N 月阈值（以"已消耗百分比"计）
	# 每段 = 100/max_months %；跨过一段 = 新一月开始
	var seg := 100.0 / float(_expedition_max_months)
	var crossed_before := int(floor(float(100 - before) / seg))
	var crossed_after := int(floor(float(100 - after) / seg))
	for _i in range(crossed_after - crossed_before):
		_advance_one_month()

	_remaining_percent = after
	progress_advanced.emit(_remaining_percent, just_consumed)
	EventBus.expedition_progress_changed.emit(_remaining_percent, just_consumed)

	_check_time_warning()

	if _remaining_percent <= 0:
		_timeout_pending = true


func is_timeout_pending() -> bool:
	return _timeout_pending


# 进度告警（GDD-03 §4.3.3）：剩余 ≤30% warning / ≤10% critical，各只广播一次
func _check_time_warning() -> void:
	if _remaining_percent <= 10 and not _warning_fired.has("critical"):
		_warning_fired["critical"] = true
		expedition_time_warning.emit("critical")
		EventBus.expedition_time_warning.emit("critical")
	elif _remaining_percent <= 30 and not _warning_fired.has("warning"):
		_warning_fired["warning"] = true
		expedition_time_warning.emit("warning")
		EventBus.expedition_time_warning.emit("warning")


func _reason_to_string(reason: ExpeditionEndReason) -> String:
	match reason:
		ExpeditionEndReason.COMPLETED: return "completed"
		ExpeditionEndReason.RETREAT:   return "retreat"
		ExpeditionEndReason.TIMEOUT:   return "timeout"
		ExpeditionEndReason.DEFEAT:    return "defeat"
		_: return "unknown"


# =============================================================================
# 存档（M2 SaveService 接入；ADR-0004）
# =============================================================================

func to_dict() -> Dictionary:
	return {
		"current_month": _current_month,
		"expedition_active": _expedition_active,
		"expedition_max_months": _expedition_max_months,
		"remaining_percent": _remaining_percent,
		"pending_day_accumulator": _pending_day_accumulator,
		"timeout_pending": _timeout_pending,
	}


func from_dict(d: Dictionary) -> void:
	_current_month = d.get("current_month", 1)
	_expedition_active = d.get("expedition_active", false)
	_expedition_max_months = d.get("expedition_max_months", 1)
	_remaining_percent = d.get("remaining_percent", 100)
	_pending_day_accumulator = d.get("pending_day_accumulator", 0)
	_timeout_pending = d.get("timeout_pending", false)
	_warning_fired.clear()
