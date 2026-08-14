extends Node

const PORT := 7777
const MAX_PEERS := 8

func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	if "--server" in args:
		_start_server()
		return

	var address := _arg_value(args, "--connect=")
	if address != "":
		_start_client(address)

func _start_server() -> void:
	var peer := ENetMultiplayerPeer.new()
	var err := peer.create_server(PORT, MAX_PEERS)
	if err != OK:
		push_error("Failed to start server on port %d: %s" % [PORT, err])
		return

	multiplayer.multiplayer_peer = peer
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	print("NET: server listening on port %d" % PORT)

func _start_client(address: String) -> void:
	var peer := ENetMultiplayerPeer.new()
	var err := peer.create_client(address, PORT)
	if err != OK:
		push_error("Failed to connect to %s:%d: %s" % [address, PORT, err])
		return

	multiplayer.multiplayer_peer = peer
	print("NET: connecting to %s:%d" % [address, PORT])

func _on_peer_connected(id: int) -> void:
	print("NET: peer connected id=%d" % id)

	var world_manager := get_tree().get_first_node_in_group("world_manager") as WorldManager
	if not world_manager:
		push_error("NET: no WorldManager found to spawn peer %d into" % id)
		return

	var spawn_point := SpawnPoint.new()
	spawn_point.actor_scene = load("res://scenes/actors/player.tscn")
	spawn_point.character_sheet = load("res://data/players/mike.tres")

	var actor := world_manager.spawn(spawn_point)
	actor.owner_id = id
	print("NET: spawned actor for peer %d, owner_id=%d" % [id, actor.owner_id])

func _on_peer_disconnected(id: int) -> void:
	print("NET: peer disconnected id=%d" % id)

	for node in get_tree().get_nodes_in_group("players"):
		var actor := node as Actor
		if actor and actor.owner_id == id:
			print("NET: despawning actor for peer %d" % id)
			actor.queue_free()
			return

func _arg_value(args: PackedStringArray, prefix: String) -> String:
	for arg in args:
		if arg.begins_with(prefix):
			return arg.substr(prefix.length())
	return ""
