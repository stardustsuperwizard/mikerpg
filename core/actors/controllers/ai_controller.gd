class_name AIController
extends Controller

@export var aggro_range := 10.0
@export var attack_range := 2.0

var target: Actor

func _ready() -> void:
	actor.add_to_group("nonplayers")

func get_move_direction() -> Vector3:
	target = _find_target()

	if target == null:
		return Vector3.ZERO

	var distance := actor.global_position.distance_to(target.global_position)
	if distance <= attack_range:
		return Vector3.ZERO

	return actor.global_position.direction_to(target.global_position)

func get_attack_target() -> Actor:
	if target == null:
		return null

	if actor.global_position.distance_to(target.global_position) <= attack_range:
		return target

	return null

func _find_target() -> Actor:
	var nearest: Actor = null
	var nearest_dist := aggro_range
	for node in actor.get_tree().get_nodes_in_group("players"):
		var player := node as Actor
		if not player:
			continue
		var dist := actor.global_position.distance_to(player.global_position)
		if dist <= nearest_dist:
			nearest = player
			nearest_dist = dist
	return nearest
