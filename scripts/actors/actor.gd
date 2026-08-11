class_name Actor
extends CharacterBody3D

const SPEED = 5.0

@export var character_sheet: CharacterSheet
@export var color: Color = Color.WHITE

@onready var controller: Controller = get_node_or_null("Controller")
@onready var mesh: MeshInstance3D = get_node_or_null("MeshInstance3D")

func _ready() -> void:
	character_sheet = character_sheet.duplicate()
	character_sheet.current_hp = character_sheet.max_hp

	if mesh:
		var material := StandardMaterial3D.new()
		material.albedo_color = color
		mesh.material_override = material

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta

	var move_direction := controller.get_move_direction() if controller else Vector3.ZERO
	if move_direction:
		velocity.x = move_direction.x * SPEED
		velocity.z = move_direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

	move_and_slide()

	var target := controller.get_attack_target() if controller else null
	if target:
		Combat.attack(self, target)

func take_damage(amount: int) -> void:
	var remaining := character_sheet.current_hp - amount
	print("%s takes %d damage (%d/%d HP)" % [character_sheet.character_name, amount, maxi(remaining, 0), character_sheet.max_hp])
	character_sheet.current_hp = remaining
	if character_sheet.current_hp <= 0:
		die()

func die() -> void:
	print("%s dies." % character_sheet.character_name)
	queue_free()
