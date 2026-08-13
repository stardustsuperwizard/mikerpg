# World / Room Manager (data-driven spawning) — Implementation Plan

This is the implementation plan produced during a Claude Code planning session, saved here before execution as a record of the design reasoning. Not yet built at the time of writing.

## Context

A review of the "Core vs Standard" architecture doc found that of the 11 Core-level concerns it names (Actor, Player, GM, NonPlayer, World, Actions, Networking, Rules contract, Feature contract, Setting loader, Save/load contract), only **Actor** and the **Rules contract** actually exist in code. **World** doesn't exist as code at all.

Right now `scenes/world/demo_room.tscn` hardcodes its actor population directly as scene-tree children: a `Player` node and a `Goblin` node with baked `transform`/`character_sheet`/`color` property overrides, hand-placed in the `.tscn` file. This doesn't scale to multiple rooms, doesn't give a future GM anything to spawn from, and doesn't give future save/load anything serializable to restore from.

The goal of this step is narrow and deliberate: prove a room's actor population can come from **data** (a list of spawn recipes) read by a **manager**, instead of being baked into the scene tree by hand — nothing more. This is the same "smallest proof" discipline already used for the Actor/Controller split and the AI Controller MVP (see `docs/20260812T225600Z - AI Controller and Combat Review.md`, which explicitly deferred a `Brain` abstraction and generic `ActionRequest` until a second concrete case existed). The same restraint applies here: no multi-room switching, no interaction system, no spawn/despawn registry, no GM spawn UI yet — those all lack a second concrete use case today.

## Design

**`core/world/spawn_point.gd`** (new) — a plain data `Resource`, the complete recipe for one spawned actor (scene + stats + look + placement, no partial-override/fallback logic):

```gdscript
class_name SpawnPoint
extends Resource

@export var actor_scene: PackedScene
@export var character_sheet: CharacterSheet
@export var color: Color = Color.WHITE
@export var transform: Transform3D = Transform3D.IDENTITY
```

`character_sheet` is required (non-null) on every entry — this mirrors the existing invariant on `Actor` itself, which already unconditionally calls `character_sheet.duplicate()` in `_ready()`, so this introduces no new risk.

**`core/world/world_manager.gd`** (new) — `Node3D` subclass (not plain `Node`: it's attached to a spatial room root, and future spatial logic there — e.g. `global_transform` math — should type-check without a cast):

```gdscript
class_name WorldManager
extends Node3D

@export var spawn_points: Array[SpawnPoint] = []

func _ready() -> void:
	for spawn_point in spawn_points:
		spawn(spawn_point)

func spawn(spawn_point: SpawnPoint) -> Actor:
	var actor := spawn_point.actor_scene.instantiate() as Actor
	actor.character_sheet = spawn_point.character_sheet
	actor.color = spawn_point.color
	actor.transform = spawn_point.transform
	add_child(actor)
	return actor
```

Notes:
- `spawn()` is public on purpose — it's the seam a later GM spawn-tool or save/load restore would call — but no registry/despawn/runtime-spawn-UI is being built now.
- Property assignment (`character_sheet`, `color`, `transform`) must happen **before** `add_child()`, not after — `add_child()` on an already-in-tree parent fires the child's `_ready()` synchronously, and `Actor._ready()` needs `character_sheet` set first or it crashes on `.duplicate()`.
- This equivalence (`actor.transform = spawn_point.transform` reproducing the old hardcoded per-instance transforms) depends on `WorldManager` staying attached to the room's own root node (identity transform, direct children) — add a one-line comment noting this so a future reparent doesn't silently break spawn placement.

**`scenes/actors/nonplayer.tscn` edit**: `SpawnPoint` deliberately carries no Controller-property overrides (no generic override mechanism until something besides this one case needs it). `demo_room.tscn` currently overrides the Goblin instance's `Controller.aggro_range` to `6.0` (script default is `10.0`). To preserve that tuning without inventing override machinery, bump `nonplayer.tscn`'s own `Controller` node default to `aggro_range = 6.0` directly.

**`scenes/world/demo_room.tscn` edit**:
- Attach `world_manager.gd` as the script on the `DemoRoom` root node (`type="Node3D"`, already exists, currently scriptless).
- Add `ext_resource` entries for `world_manager.gd`, `spawn_point.gd`, and `data/players/mike.tres` (not currently referenced directly in this scene — `player.tscn` bakes it as its own default, but `SpawnPoint` is the complete recipe so it's set explicitly here too; harmless intentional redundancy, not a bug).
- Add two `SpawnPoint` `sub_resource` blocks (Mike: `player.tscn` + `mike.tres` + transform `(-7, 0.05, 2)`; Goblin: `nonplayer.tscn` + `goblin.tres` + green `Color(0.2, 0.6, 0.2, 1)` + transform `(3, 0.05, -3)`), following this project's existing pattern for embedding a scripted `Resource` sub-resource (see `goblin.tres`'s `AbilityScores` block: `type="Resource"` + `script = ExtResource(...)` + fields).
- Remove the hardcoded `[node name="Player" ...]`, `[node name="Goblin" ...]`, and nested `[node name="Controller" parent="Goblin" index="2"]` blocks; assign the two sub-resources to `DemoRoom`'s new `spawn_points` array property.
- Leave `World` (the pre-existing floor/wall geometry grouping node — unrelated name collision with the new `WorldManager` script, not touched), `CameraRig`, and `DirectionalLight3D` untouched.
- Update `load_steps` in the header to match the new resource count.

**Known uncertainty — the exact `.tscn` syntax for a typed `Array[SpawnPoint]` export containing custom-script `SubResource` entries is not 100% confirmed.** Verify empirically rather than trust by inspection:
1. Try `spawn_points = Array[SpawnPoint]([SubResource("SpawnPoint_mike"), SubResource("SpawnPoint_goblin")])` first.
2. Run `tools/verify.sh` (this project's existing smoke test — rescans for parse errors, then boots `demo_room.tscn` headless and greps for errors, filtering known-benign shutdown noise).
3. If that fails, fall back in order to `Array[Resource("res://core/world/spawn_point.gd")]([...])`, then a plain untyped `[SubResource(...), SubResource(...)]` literal.
4. Whichever parses cleanly, confirm it also populates correctly (not just "no parse error") — see verification step below.

## Verification

1. After creating each new script, force a rescan and confirm the class registers: `rm -f .godot/global_script_class_cache.cfg && /Applications/Godot.app/Contents/MacOS/Godot --headless --editor --quit --path .` — check the log for `SpawnPoint` / `WorldManager` appearing in `update_scripts_classes`, zero errors.
2. Run `tools/verify.sh` after each `.tscn` edit, iterating array-syntax candidates until clean.
3. Deeper runtime-equivalence check, reusing this project's established throwaway-driver pattern (temporary `Node3D` scene + script, deleted after use — same approach as the AI Controller review doc's `tmp_test_leash` and this session's earlier `_smoke_test_driver.gd`): instantiate `demo_room.tscn`, wait a frame, walk its children, and print for each spawned `Actor`: name, `global_position`, `character_sheet.character_name`, `max_hp`, `armor_class`, `color`, and (goblin only) `Controller.aggro_range`. Confirm:
   - Exactly 2 actors spawned.
   - Positions match the old hardcoded transforms: `(-7, 0.05, 2)` Mike, `(3, 0.05, -3)` Goblin.
   - Mike: HP 12, AC 10, white. Goblin: HP 7, AC 15, green.
   - Goblin's `aggro_range` reads `6.0` (confirms the `nonplayer.tscn` edit took effect).
   - Delete the throwaway driver files afterward — not part of what's left in the working tree.
4. Final `tools/verify.sh` pass on the finished state.
5. Leave all changes uncommitted in the working tree for manual review (per user preference — they handle commits themselves).

### Files
- `core/world/spawn_point.gd` (new)
- `core/world/world_manager.gd` (new)
- `scenes/world/demo_room.tscn` (edit)
- `scenes/actors/nonplayer.tscn` (edit)
