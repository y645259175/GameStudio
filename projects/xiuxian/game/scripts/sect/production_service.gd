# =============================================================================
# ProductionService.gd · 生产任务工厂（autoload，GDD-05 §5-6）
#
# 按 task_kind 分发（M3 支持 alchemy/build；M4 加 forge——不改骨架，GDD-05 §6.2 可扩展性纪律）。
# M3 炼丹极简：投配方 + 指派弟子 → 等月节拍 → 到期滚成功率 → 出货/退料。
# =============================================================================
extends Node

signal task_completed(task_id: String, result: Dictionary)

var _tasks: Array = []          # Array[Dictionary]，运行中任务
var _task_counter: int = 0


func _ready() -> void:
	if TimeService:
		TimeService.month_advanced.connect(_on_month_advanced)
	print("[ProductionService] ready")


## 启动任务（task_kind: "alchemy" / "build"；M4 加 "forge"）
func start_task(task_kind: String, params: Dictionary) -> String:
	_task_counter += 1
	var tid := "%s_task_%d" % [task_kind, _task_counter]
	var task := {
		"task_id": tid,
		"kind": task_kind,
		"remaining_months": params.get("duration_months", 1),
		"params": params,
	}
	_tasks.append(task)
	return tid


func active_task_count() -> int:
	return _tasks.size()


func _on_month_advanced(_m: int, _y: int, _moy: int) -> void:
	for i in range(_tasks.size() - 1, -1, -1):
		var t = _tasks[i]
		t["remaining_months"] -= 1
		if t["remaining_months"] <= 0:
			var result := _settle(t)
			_tasks.remove_at(i)
			task_completed.emit(t["task_id"], result)
			if t["kind"] == "alchemy":
				EventBus.alchemy_task_completed.emit(t["task_id"], result)


func _settle(task: Dictionary) -> Dictionary:
	var p: Dictionary = task["params"]
	var success_rate: float = p.get("success_rate", 1.0)
	var success := randf() < success_rate
	if success:
		# 出货：把 output 加进库存
		for rid in p.get("output", {}):
			InventoryService.add(rid, int(p["output"][rid]))
		return {"success": true, "output": p.get("output", {})}
	else:
		# 失败退回半数材料（GDD-05 §5.3 fail_recovery_rate）
		for rid in p.get("materials", {}):
			InventoryService.add(rid, int(p["materials"][rid] * 0.5))
		return {"success": false}
