# Pre-Content Fixes: Material Override and Attack Targeting

Small work-log doc for a short, self-contained follow-up to `docs/20260814T155946Z - Core Completion, LAN Networking, and Packaging Discussion.md`. That doc ended with the user asking whether Core was done and ready for real content work (imported assets, story/NPC content, addon features). Answer: yes, Core is done -- but two concrete things needed fixing first, both flagged in that conversation as things the user would hit almost immediately otherwise. This is that fix.

## 1. Material override was going to stomp real imported assets

`Actor._ready()` unconditionally built a flat-color `StandardMaterial3D` and set it as `mesh.material_override`, regardless of whether the mesh already had a material. That was fine for the placeholder capsule/box primitives used throughout the demo (`CapsuleMesh` has no material of its own, so this is the only thing making Mike white and the Goblin green), but it would silently overwrite the textures/materials on any real imported model the moment one was dropped in.

Fixed with a small check, `Actor._has_own_material(mesh_instance)`: skip the override if the mesh already has either a per-instance `surface_override_material` or a material baked into the mesh resource itself (as an imported `.glb`/`.fbx` typically would). Placeholder primitives have neither, so they're unaffected; a real model with its own materials is left alone.

## 2. `PlayerController` could target any NPC, hostile or not

Flagged repeatedly through the day (first in the `CoreRPG Current Status.md` consultation, then again by the user directly) and deliberately deferred each time for lack of a second concrete case -- a friendly NPC didn't exist in the repo yet to design the real fix against. The user's "can I start making stories now" question made this concrete: any story involving a non-hostile NPC (merchant, quest-giver, anyone) would immediately expose the bug, since `PlayerController.get_attack_target()` only ever checked `"nonplayers"` group membership, which every AI-controlled actor gets regardless of disposition.

Fixed with the smallest thing that solves it: a `hostile: bool = true` flag directly on `Actor`. Defaults to `true` so existing content (the Goblin) needs no data changes; a friendly NPC sets it `false`. Deliberately not a faction/relationship system -- nothing in the game today needs more nuance than "attackable or not," and building more than that now would be guessing at a shape with no real content to design against yet.

## Verification

Both fixes tested directly rather than by building throwaway content:

- Material: a mesh instance with a pre-set `surface_override_material` was confirmed untouched after `Actor._ready()`; a placeholder mesh with no material was confirmed to still receive the color override (regression check).
- Targeting: two `nonplayer.tscn` instances placed in range of a player actor, one `hostile = true` and one `hostile = false` -- `get_attack_target()` returned only the hostile one, and returned `null` when the friendly one was the only actor in range (not just "skipped it in favor of something else").
- Full `demo_room.tscn` single-player regression (spawn positions, HP, color, combat hit rate) unchanged from baseline.

## Git state

New branch `actor-material-and-targeting-fixes`, off `main` (which now includes PR #5, merged since the last doc). PR pending as of this writing.

## Open items

Unchanged from the previous doc: README rewrite (explicitly deferred), whether `networking/` eventually moves under a `features/` directory, distribution-track work (Maaack, Dax D20) still untouched, `GMController`/a real `AuthorityContext` still waiting on a second peer *role* to design against.

With both fixes in, there's no longer a known landmine blocking real content work -- importing assets and adding NPCs (friendly or hostile) should both behave correctly now.
