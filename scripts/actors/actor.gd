class_name Actor
extends CharacterBody3D

@export var character_sheet: CharacterSheet

func _ready() -> void:
	character_sheet = character_sheet.duplicate()
	character_sheet.current_hp = character_sheet.max_hp

func take_damage(amount: int) -> void:
	character_sheet.current_hp -= amount
	if character_sheet.current_hp <= 0:
		die()

func die() -> void:
	queue_free()
