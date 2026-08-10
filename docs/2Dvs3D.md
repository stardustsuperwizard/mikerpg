# 2d vs 3d

## Prompt
```
Wait, should we be using 3d or 2d to start?
```

## Response
I would use **3D** for MikeRPG.

Not because 3D is inherently better or easier—it isn't—but because of where you ultimately want this project to go: an RPG inspired by tabletop play/Neverwinter Nights, eventually with 5e-style rules, multiplayer, and potentially a GM mode.

The important distinction is that **3D does not mean we need to build a complicated 3D action game**. We can make an extremely simple 3D RPG.

Think *tabletop miniatures on a virtual table*:

```text
          Camera
             \
              \
     ┌─────────────────┐
     │                 │
     │   🧍       👹   │
     │                 │
     │      🪑         │
     │                 │
     └─────────────────┘
            Floor
```

Initially, our "hero" can literally be a capsule and our "goblin" can be a green capsule. The floor can be a big gray rectangle.

That lets you learn the important Godot concepts without worrying about art.

### Why not start in 2D and switch later?

Because 2D → 3D isn't really a graphical upgrade in Godot. They're different systems.

A 2D character might be:

```text
CharacterBody2D
Sprite2D
CollisionShape2D
Camera2D
```

Our eventual 3D character would instead use:

```text
CharacterBody3D
MeshInstance3D
CollisionShape3D
Camera3D
```

Movement changes from `Vector2` to `Vector3`. Physics changes. Cameras change. Navigation changes. Collision changes. Maps change.

Our **inventory, dialogue, quests, character stats, rules, items, dice, etc. can be largely independent of that**, but we'd still be throwing away quite a bit of the first game's world implementation.

### 3D also fits our "don't build it" rule

This is another reason I'd choose it.

We don't have to model chairs, barrels, swords, goblins, taverns, trees, dungeon walls, etc. ourselves. Godot can import common 3D formats such as glTF, and there are enormous libraries of reusable assets available.

So eventually our development process can be much more like:

> "We need a tavern."

rather than:

> "Time to learn Blender and spend six weeks making a tavern."

We'll deliberately investigate existing assets and addons before implementing major commodity systems ourselves.

### But I'd make one change to my previous proposal

I **wouldn't put the camera under Player yet**.

I'd rather begin with something more NWN/tabletop-like:

```text
TestRoom (Node3D)
│
├── World
│   ├── Floor
│   └── Walls
│
├── Player
│
├── CameraRig
│   └── Camera3D
│
└── DirectionalLight3D
```

That gives us conceptual separation between:

**the character** — "Mike the Fighter is standing here"

and

**the player's viewpoint** — "the human playing MikeRPG is looking at the world from here."

That distinction will become extremely useful if we eventually build GM mode. A GM camera may fly around independently of any character.

So I'd commit to **Godot 4 + 3D**, but keep the first game visually primitive.

Our first victory remains wonderfully unimpressive:

**gray floor + capsule → press WASD → capsule moves.**

That's enough to start building the architecture of the RPG around it.
