extends Node2D
class_name Outpost

## Outpost · 原 Castle，基地哨站视觉占位

const _SpriteHelper = preload("res://scripts/sprite_helper.gd")

const SIZE := Vector2(80, 80)


func _ready() -> void:
	# M6 BL-015：用真实贴图，fallback 简色块
	var sprite := _SpriteHelper.create_sprite(
		"res://assets/outpost.png", SIZE,
		Color("#A0A0A8"), "Sprite"
	)
	# Outpost origin 是底部中心（脚立地面）；贴图中心要对到 (0, -SIZE.y/2)
	sprite.position = Vector2(0, -SIZE.y / 2.0)
	add_child(sprite)
	# 如果是 fallback ColorRect，再补一个门
	if sprite is ColorRect:
		var door := ColorRect.new()
		door.color = Color("#202020")
		door.size = Vector2(20, 32)
		door.position = Vector2(-10, -32)
		door.mouse_filter = Control.MOUSE_FILTER_IGNORE
		door.name = "_PLACEHOLDER_Door"
		add_child(door)
