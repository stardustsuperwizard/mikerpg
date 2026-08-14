class_name WorldManager
extends Node3D

@export var spawn_points: Array[SpawnPoint] = []

func _ready() -> void:
	for spawn_point in spawn_points:
		spawn(spawn_point)

# Assumes WorldManager stays attached to the room's own root node (identity
# transform, direct children) so spawn_point.transform reproduces the old
# hardcoded per-instance transforms as-is.
func spawn(spawn_point: SpawnPoint) -> Actor:
	var actor := spawn_point.actor_scene.instantiate() as Actor
	actor.character_sheet = spawn_point.character_sheet
	actor.color = spawn_point.color
	actor.transform = spawn_point.transform
	add_child(actor)
	return actor
