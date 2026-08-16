# Mike's Basic Networking

A minimal ENet bootstrap for Godot 4's high-level multiplayer API.

`network_bootstrap.gd` (an autoload in the consuming game) reads `--server` / `--connect=<address>` from the command line, starts an `ENetMultiplayerPeer` as host or client accordingly, and on each peer connecting, finds a `WorldManager` in the scene tree and spawns a peer-owned actor into it.

## Depends on

[`mikes_game_bones`](../mikes_game_bones/) — uses its `Actor`, `WorldManager`, and `SpawnPoint`.

## Known coupling to fix before this is truly game-agnostic

`_on_peer_connected()` currently hardcodes a specific game's content paths (`res://scenes/actors/player.tscn`, `res://data/players/mike.tres`) rather than taking them as configuration. A reusable version should let the consuming game supply which scene/data to spawn.
