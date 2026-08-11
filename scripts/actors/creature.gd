class_name Creature
extends Actor

@export var color: Color = Color.WHITE

@onready var mesh: MeshInstance3D = $MeshInstance3D

func _ready() -> void:
	super._ready()
	add_to_group("creatures")
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	mesh.material_override = material

func take_damage(amount: int) -> void:
	var remaining := character_sheet.current_hp - amount
	print("%s takes %d damage (%d/%d HP)" % [character_sheet.character_name, amount, maxi(remaining, 0), character_sheet.max_hp])
	super.take_damage(amount)

func die() -> void:
	print("%s dies." % character_sheet.character_name)
	super.die()
