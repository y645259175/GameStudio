extends Area2D
class_name KillZone

## KillZone — story-004 hotfix BL-P2-018
## 玩家碰到则重置回起点（不真删，简化死亡反馈）

@export var respawn_position: Vector2 = Vector2(64, 400)


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") or body.name == "Player":
		body.global_position = respawn_position
		if "velocity" in body:
			body.velocity = Vector2.ZERO
		print("[killzone] player respawned at ", respawn_position)
