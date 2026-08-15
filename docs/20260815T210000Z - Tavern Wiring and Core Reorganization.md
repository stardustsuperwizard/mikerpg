# Tavern Wiring and Core Reorganization

Work-log doc continuing from `docs/20260815T190000Z - Game Objects and Rules Implementation.md`, covering two same-day follow-ups: pointing the main menu at the user's own out-of-band `misadventures/scenes/tavern/` content instead of the `scenes/` reference room, and a naming/reorganization pass across `core/` (and its `data/` mirror) done interactively over several rounds.

## 1. Main menu now boots the tavern scene

`misadventures/scenes/tavern/` (`player.tscn`, `nonplayer.tscn`, `demo_room.tscn`, `door.tscn`) is a user-authored, self-consistent duplicate of the `scenes/` reference content — same scripts, same `data/` resources, re-pathed internally to point at each other. `AppConfig.game_scene_path` (both the tracked source at `tools/addon_config/maaacks_game_template/.../app_config.tscn` and the live, gitignored copy under `addons/`, kept in sync via `tools/restore_addon_config.sh`) now points at `res://misadventures/scenes/tavern/world/demo_room.tscn` instead of `res://scenes/world/demo_room.tscn`.

The tavern copy predated the interaction prompt (`docs/20260815T190000Z`, part 3), so it was missing the "Press E to interact" hint near its door — added the same way as the reference scene, instancing the shared `scenes/ui/interaction_prompt.tscn`.

`tools/verify.sh` gained a fifth check booting the tavern room directly, since it's now the scene actually reached from the menu.

## 2. `core/` reorganization

Prompted by wanting `core/actions/` to distinguish framework from content: `AttackAction`/`OpenAction` (concrete verbs) moved into `core/actions/verbs/`, leaving `Action`/`ActionResult`/`ActionRunner` (the framework) at `core/actions/`. Extended to `core/actors/` and the object layer the same way, arrived at over a few rounds of naming discussion:

- `core/actors/actor_body_3d.gd` / `actor_body_2d.gd` → `core/actors/bodies/`.
- `core/objects/` → `core/things/` (and `data/objects/` → `data/things/` to match). Rejected names along the way, and why:
  - Keeping `objects/` — collides with Godot's own `Object`, the literal root of its class hierarchy, and didn't match the class names it actually holds (`GameObject`/`ObjectDefinition`, not `Object`) — every other `core/` folder mirrors its class family (`actions/` → `Action*`, `actors/` → `Actor`, `controllers/` → `Controller`), so this was the odd one out on both counts.
  - Renaming the whole folder to `props/` — rejected because `game_object.gd`/`object_definition.gd` aren't prop-specific; `Actor` builds its own `game_object` from those same two classes, so they're the shared foundation, not something belonging to props alone.
  - `game_objects/` — a working two-word compromise, replaced once a one-word option surfaced.
  - **`things/`** — settled on because it's one word (matching every other `core/` folder) and, more importantly, it's the design doc's own vocabulary: *"a game contains things... a game object is a thing that participates in gameplay."*
- `core/objects/nouns/door.gd` → `core/things/props/door.gd` — `Door` is the concrete, non-actor content living under the `things/` framework, same shape as `actions/verbs/`: framework at the parent, concrete instances in a named subfolder.

Two path-reference classes needed fixing at each move, since GDScript's global `class_name` resolution only covers one of them:

- Files instantiating a class only via `class_name` in code (`AttackAction.new(...)`, `OpenAction.new(...)`) needed no changes when moved — Godot resolves by class name regardless of file location.
- Files referencing a script by explicit `res://` path — any `.tscn` with `script = ExtResource(...)` pointing at a moved file (`Door`, `ActorBody3D`, `ActorBody2D` are all attached directly to scene nodes), and `data/things/*.tres`, whose `ObjectDefinition` script reference is a path, not a class-name lookup — needed every reference caught and re-pathed by hand across both `scenes/` and its `misadventures/scenes/tavern/` mirror.

Final shape:

```
core/
├── actions/            (Action, ActionResult, ActionRunner)
│   └── verbs/           (AttackAction, OpenAction)
├── actors/              (Actor)
│   └── bodies/           (ActorBody3D, ActorBody2D)
├── authority/
├── controllers/
├── rules/               (RulesManager, RulesProvider)
│   └── lite/              (LiteRulesProvider, Dice, AbilityScores, CharacterSheet)
├── things/               (GameObject, ObjectDefinition)
│   └── props/              (Door)
├── ui/                  (InteractionPrompt)
└── world/               (WorldManager, SpawnPoint)
```

## Verification

`tools/verify.sh` (five checks: script rescan, main menu, `demo_room.tscn`, tavern's `demo_room.tscn`, `demo_room_2d.tscn`) passed after each move. The `core/things/` renames in particular were caught failing on the first pass — unlike `actions/verbs/`, `Door`/`ActorBody3D`/`ActorBody2D` are attached as scene-node scripts by path, not purely referenced through `class_name`, so moving them without re-pathing every `.tscn`/`.tres` reference broke loading immediately and loudly (exactly the kind of error `verify.sh` exists to catch before it's discovered in the editor).

## Open items

Unchanged from `docs/20260815T190000Z`: capability enforcement in `ActionRunner`, a 2D door / 2D `WorldManager`, and a real multiplayer regression test for the `Actor` presentation split — none of this session's renames touch those.
