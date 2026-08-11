# First Files

## Prompt
```
I have created the repo: https://github.com/stardustsuperwizard/mikerpg
```

## Response
Perfect. I can see the repo, and your README already captures the right design constraints: start single-player, eventually add multiplayer + GM/DM mode, use the Godot editor as much as possible, prefer existing addons over reinventing systems, and keep game content data-driven/modular. ([GitHub][1])

You’ve also already created a `scenes/` directory, so I would make the **next commit intentionally tiny**:

```text
mikerpg/
├── scenes/
│   ├── actors/
│   │   └── player.tscn
│   └── world/
│       └── test_room.tscn
├── scripts/
│   └── actors/
│       └── player.gd
├── project.godot
└── README.md
```

Our first goal is simply:

> **Run MikeRPG → see a room → move a placeholder player around it.**

No inventory. No character sheet. No 5e. No multiplayer. No artwork.

And I want to teach this from the **Godot editor outward**, rather than dumping a bunch of files on you. The important thing right now is understanding what a Scene, Node, script, instantiated scene, collision body, camera, and input action actually are.

For `player.tscn`, I suggest we use a `CharacterBody3D` as the root. Under it we'll put a crude `MeshInstance3D` so you can see the player, a `CollisionShape3D` so the player physically exists, and eventually a `Camera3D`.

Conceptually:

```text
Player (CharacterBody3D)
├── MeshInstance3D
├── CollisionShape3D
└── Camera3D
```

Then `test_room.tscn` can be:

```text
TestRoom (Node3D)
├── Floor (StaticBody3D)
│   ├── MeshInstance3D
│   └── CollisionShape3D
│
├── DirectionalLight3D
└── Player
```

Notice one important Godot idea already: **Player isn't code inside the room. Player is its own reusable scene, instantiated into the room.**

Later, that same `player.tscn` could be instantiated into a dungeon, tavern, forest, multiplayer map, or test arena without duplicating its implementation. That's the composition model we're going to lean on heavily.

So I think we are officially at **Lesson 1, Step 1: create the actual Godot project and our Player scene.**

If you have Godot open right now, create/open `mikerpg` as a Godot project and tell me what version of Godot you're running. Then I'll walk you through creating `player.tscn` **click by click**, explaining why we're choosing each node rather than just giving you code.

[1]: https://github.com/stardustsuperwizard/mikerpg "GitHub - stardustsuperwizard/mikerpg: This is an RPG game that I am designing in Godot · GitHub"
