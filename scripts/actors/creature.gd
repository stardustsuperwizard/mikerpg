extends CharacterBody3D

@export var data: CreatureData

var current_hp: int

@onready var mesh: MeshInstance3D = $MeshInstance3D

func _ready() -> void:
	add_to_group("creatures")
	current_hp = data.max_hp
	var material := StandardMaterial3D.new()
	material.albedo_color = data.color
	mesh.material_override = material

func take_damage(amount: int) -> void:
	current_hp -= amount
	print("%s takes %d damage (%d/%d HP)" % [data.creature_name, amount, max(current_hp, 0), data.max_hp])
	if current_hp <= 0:
		die()

func die() -> void:
	print("%s dies." % data.creature_name)
	queue_free()
