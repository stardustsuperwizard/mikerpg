# Game Objects and Rules: Implementation

Work-log doc for implementing `docs/20260815T130000 - Game Objects and Rules.md`, done across three passes in the same day: the v0.1 minimal slice from that doc's own "Minimal First Implementation" section, a deeper follow-up that made `Actor` genuinely presentation-neutral and proved it with a second (2D) presentation, and a small UI fix for the interaction the first pass added.

## 1. `ObjectDefinition` / `GameObject` + Door + `open` action

Added the generic trait/capability layer the doc proposes, and used it to add a fourth verb (`open`) and a first non-creature object (`Door`) without touching combat.

- `core/objects/object_definition.gd` (`Resource`: `id`, `display_name`, `traits`, `capabilities`, `default_state`) and `core/objects/game_object.gd` (`RefCounted` runtime instance) — the doc's two minimal primitives, close to verbatim.
- `Actor` gained `object_definition` and a `game_object` built from it in `_ready()`, alongside the existing `character_sheet`. Deliberately additive: `CharacterSheet` stays the typed RPG data (HP/AC/abilities); `ObjectDefinition` is the new generic classification layer. `data/objects/player.tres` and `data/objects/goblin.tres` carry the trait/capability data.
- `core/objects/door.gd` (`StaticBody3D`) + `scenes/world/door.tscn` + `data/objects/door.tres` — a door with real `open`/`locked` state, its own `ObjectDefinition` (traits `interactable`/`openable`/`lockable`), and a `MultiplayerSynchronizer` replicating `open` the same way Actors replicate `position`.
- `core/actions/open_action.gd` + `RulesManager.open()` — implements the doc's legality chain literally (already-open → fail, locked → fail, else open + succeed), returning a real `ActionResult`.
- `Actor.try_interact()` / `request_interact()` / `_resolve_interact()` — mirrors the existing attack RPC triplet exactly, so interaction is server-authoritative in multiplayer the same way attacks are.
- `ActionResult` gained a `reason: StringName` field, and `AttackAction`/`RulesProvider`/`LiteRulesProvider` were upgraded to return a truthful result (hit/miss) instead of the previous hardcoded always-success stub — makes `attack` and `open` consistent.
- New `interact` input action (key `E`).

**Deliberately deferred:** capability *enforcement*. `Action.required_capability()` exists and `AttackAction`/`OpenAction` report their required capability, but `ActionRunner` doesn't check it yet — doing so would add a new silent-failure mode (a scene with a missing/misconfigured `ObjectDefinition` would quietly stop letting an actor act) with no second case yet to justify it, matching the same reasoning already on record in `docs/20260814T170000Z - Authority to Authorization.md` for deferring Authority → Authorization.

## 2. Making `Actor` presentation-neutral, proved with a 2D room

The first pass left `Actor` as `extends CharacterBody3D` — exactly the coupling the design doc argues against. This pass removed it for real, then proved the removal was real by building a second, 2D presentation of the same content.

- `Actor` is now `extends Node`. All movement/physics moved out into a new presentation-shell node type, `Body`:
  - `core/actors/actor_body_3d.gd` (`CharacterBody3D`) — everything `Actor._physics_process()` used to do (gravity, `move_and_slide()`, mesh material override).
  - `core/actors/actor_body_2d.gd` (`CharacterBody2D`) — the 2D equivalent; no gravity/`is_on_floor()` (a top-down room has no vertical axis), `Polygon2D` tint instead of a mesh material.
  - `Actor.global_position: Vector3` is a computed property bridging whichever body it has (`CharacterBody3D.global_position` as-is, or `CharacterBody2D.global_position` mapped `Vector3(x, 0, y)`) — the one place the code explicitly branches on 2D vs. 3D, since GDScript has no interfaces. Every distance/range check in `Controller`/`PlayerController`/`AIController` reads this property, so none of them needed to change.
- **`core/actions/`, `core/rules/`, `core/authority/` needed zero changes.** They only ever touched `character_sheet`, `owner_id`, `game_object`, `take_damage()`, and `get_path()` — all already presentation-neutral. This is the actual validation of the design doc's central claim.
- `PlayerController.get_move_direction()` dropped a `transform.basis` multiply that turned out to be inert (nothing ever rotated an Actor) — also removed the last 3D-only API `Controller` touched.
- `PlayerController.attack_range`/`interact_range` changed from `const` to `@export var` (matching the pattern `AIController.aggro_range`/`attack_range` already used) — needed once a second, differently-scaled presentation existed: 3D stays small-unit scale (speed `5.0`, range `2.0`), 2D is pixel scale (speed `220.0`, range `60.0`), each tuned per instance instead of sharing one hardcoded number.
- `scenes/actors/player.tscn` / `nonplayer.tscn` restructured to `Actor` (root) → `Body` + `Controller`; `MultiplayerSynchronizer`'s replicated path moved from `.:position` to `Body:position`. `WorldManager._spawn_actor()` now sets the transform on `actor.get_node("Body")` instead of on `actor` itself.
- New `scenes/actors/player_2d.tscn` / `nonplayer_2d.tscn` and `scenes/world/demo_room_2d.tscn` — same `Actor` script, same `CharacterSheet`/`ObjectDefinition` `.tres` files as the 3D scenes (`mike.tres`, `goblin.tres`, `player.tres`, `goblin.tres` under `data/objects/`), same `PlayerController`/`AIController` scripts, unmodified. Single-player only — no `WorldManager2D`/`SpawnPoint2D`; those stay `Transform3D`-specific and 3D-only rather than being built out speculatively for a case that doesn't exist yet.
- `Door` stayed 3D-only; not part of this pass's proof.

One correctness detail worth recording: `Actor.global_position`'s getter re-resolves `get_node_or_null("Body")` on every call rather than caching it via `@onready`. Godot readies a node's children before the node itself, and `AIController._ready()` (a child of `Actor`) reads `global_position` to set its home position — with a cached `@onready var body`, that read would run before `Actor`'s own `@onready` vars were assigned, silently returning `Vector3.ZERO`.

## 3. Interaction prompt UI

The door from part 1 had no on-screen indication that `E` did anything. Added:

- `PlayerController.get_nearby_interactable()` — a non-consuming version of the existing interact-target search, safe to call every frame instead of only on keypress.
- `core/ui/interaction_prompt.gd` + `scenes/ui/interaction_prompt.tscn` — a `CanvasLayer` with a bottom-centered "Press E to interact" `Label`, shown whenever `get_nearby_interactable()` is non-null. Finds the player lazily via the `"players"` group rather than an `@export` reference, since `WorldManager` spawns the player at runtime and it doesn't exist when the scene is edited.
- Wired into `demo_room.tscn` only (the only room with an interactable so far). The script only talks to `PlayerController`, not to `Actor`'s body, so it should work unmodified in the 2D room once a 2D interactable exists.

## Verification

`tools/verify.sh` was extended with a fourth check (`demo_room_2d.tscn` boot) and passed after every pass: script rescan, main menu boot, `demo_room.tscn`, `demo_room_2d.tscn`, all headless with no errors. This confirms everything loads and runs, not that it behaves correctly in play — manual playtesting confirmed the door opens (mesh hides, collision disables, prompt shows/hides correctly in range) and combat hit/miss resolves identically in both rooms using the same data files.

Not exercised by any of the above: actual multiplayer replication (`MultiplayerSynchronizer`'s retargeted `Body:position`/`Body:open` paths). `tools/verify.sh` is single-process and headless; a real two-instance LAN test is still open if that confidence is wanted.

## Open items

- Capability enforcement in `ActionRunner` (see part 1) — deferred pending a real second case.
- A 2D door / 2D `WorldManager` — deferred pending an actual need for one.
- Multiplayer regression test for the `Actor` presentation split (see Verification).
- `misadventures/scenes/tavern/` — user-authored, out of band, not covered by this doc.
