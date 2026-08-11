extends CharacterBody3D

const SPEED = 5.0
const ATTACK_RANGE = 2.0

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta

	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

	move_and_slide()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("attack"):
		var target := _find_nearest_creature()
		if target:
			Combat.attack(self, target)

func _find_nearest_creature() -> Node:
	var nearest: Node = null
	var nearest_dist := ATTACK_RANGE
	for creature in get_tree().get_nodes_in_group("creatures"):
		var dist: float = global_position.distance_to(creature.global_position)
		if dist <= nearest_dist:
			nearest = creature
			nearest_dist = dist
	return nearest
