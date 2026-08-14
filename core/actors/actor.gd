class_name Actor
extends CharacterBody3D

const SPEED = 5.0

@export var character_sheet: CharacterSheet
@export var color: Color = Color.WHITE
@export var attack_cooldown := 1.0

# Whether player input may target this actor for attack. Defaults to true so
# existing hostile content (the Goblin) needs no data change; a friendly
# NPC sets this false. Deliberately just a flag, not a faction/relationship
# system -- nothing today needs more than "attackable or not."
@export var hostile: bool = true

# 0 means unowned/AI-controlled; a connected LAN client's peer id otherwise.
# Checked by Authority.can_perform() before an Action is honored.
var owner_id: int = 0

@onready var controller: Controller = get_node_or_null("Controller")
@onready var mesh: MeshInstance3D = get_node_or_null("MeshInstance3D")

var _attack_timer := 0.0

func _ready() -> void:
	character_sheet = character_sheet.duplicate()
	character_sheet.current_hp = character_sheet.max_hp

	if mesh and not _has_own_material(mesh):
		var material := StandardMaterial3D.new()
		material.albedo_color = color
		mesh.material_override = material

# Placeholder actors (bare primitive meshes, no material of their own) rely
# on `color` for visibility. A real imported model already brings its own
# materials/textures and shouldn't have them stomped by a flat color.
func _has_own_material(mesh_instance: MeshInstance3D) -> bool:
	if mesh_instance.get_surface_override_material(0):
		return true
	var mesh_resource := mesh_instance.mesh
	return mesh_resource and mesh_resource.get_surface_count() > 0 and mesh_resource.surface_get_material(0) != null

func _physics_process(delta: float) -> void:
	# Ticks on every peer's own copy regardless of movement authority: the
	# server needs its copy of a peer-owned actor's cooldown to keep
	# decaying, since the server is what actually enforces it (see
	# _resolve_attack), even though it never simulates that actor's movement.
	if _attack_timer > 0.0:
		_attack_timer -= delta

	if not is_multiplayer_authority():
		return

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
		try_attack(target)

# Only the actor's own controlling peer ever calls this (gated upstream by
# the authority check above), so it's just "should I ask the server to
# attack" -- the server is the only one that ever actually resolves it.
func try_attack(target: Actor) -> void:
	if multiplayer.has_multiplayer_peer() and not multiplayer.is_server():
		request_attack.rpc_id(1, target.get_path())
		return

	_resolve_attack(target, multiplayer.get_unique_id())

@rpc("authority", "call_remote", "reliable")
func request_attack(target_path: NodePath) -> void:
	var target := get_node(target_path) as Actor
	if target:
		_resolve_attack(target, multiplayer.get_remote_sender_id())

# The only place an attack is ever actually resolved -- called directly for
# AI/single-player, or from request_attack() for a networked player. Its own
# _attack_timer check is the real cooldown enforcement; the server never
# trusts a client to have rate-limited itself.
func _resolve_attack(target: Actor, requester_id: int) -> void:
	if _attack_timer > 0.0:
		return

	_attack_timer = attack_cooldown
	ActionRunner.run(AttackAction.new(self, target), requester_id)

func take_damage(amount: int) -> void:
	var remaining := character_sheet.current_hp - amount
	print("%s takes %d damage (%d/%d HP)" % [character_sheet.character_name, amount, maxi(remaining, 0), character_sheet.max_hp])
	character_sheet.current_hp = remaining
	if character_sheet.current_hp <= 0:
		die()

func die() -> void:
	print("%s dies." % character_sheet.character_name)
	queue_free()
