class_name PlayerController
extends Controller

const ATTACK_RANGE = 2.0

var _attack_requested := false

func _ready() -> void:
	actor.add_to_group("players")

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("attack"):
		_attack_requested = true

func get_move_direction() -> Vector3:
	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	return (actor.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

func get_attack_target() -> Actor:
	if not _attack_requested:
		return null
	_attack_requested = false

	var nearest: Actor = null
	var nearest_dist := ATTACK_RANGE
	for node in actor.get_tree().get_nodes_in_group("nonplayers"):
		var nonplayer := node as Actor
		if not nonplayer or not nonplayer.hostile:
			continue
		var dist := actor.global_position.distance_to(nonplayer.global_position)
		if dist <= nearest_dist:
			nearest = nonplayer
			nearest_dist = dist
	return nearest
