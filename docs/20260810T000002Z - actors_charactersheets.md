# Actors and CharacterSheets

These are conversations breaking down the basic concept of the character in the game and how to make them more modulular by defining what the concepts are. 

This was the ultimate conclusion:
> **Actor = representation in the game world.**
> **CharacterSheet = representation in the game rules.**

## Prompt 1
https://github.com/stardustsuperwizard/mikerpg lots of progress here on this game.

### Response 1
Yes — this is **substantially past “capsule walking around a room.”** I pulled the repo fresh rather than relying on our earlier conversation.

You now have a meaningful little vertical slice taking shape. The repo has distinct `actors`, `world`, and `ui` scene areas, with a reusable `player.tscn`, a separate `creature.tscn`, an `item_pickup.tscn`, an inventory UI, and a test room tying things together. ([GitHub][1])

More importantly, you’ve already followed one of the biggest architectural principles we talked about: **you did not build your own inventory system.** `player.tscn` is using the Gloot inventory addon, with its item prototypes loaded from `data/items/items.json`. That is exactly the “assemble commodity systems, write the RPG-specific glue” model we wanted. ([GitHub][2])

The separation is also starting to look good:

```text
Player
├── movement / player behavior
├── visual + collision
└── Inventory (Gloot)

Creature
├── creature behavior
├── visual
└── collision

World
├── test_room
└── item_pickup

UI
└── inventory_ui
```

Your inventory UI is also separated from the inventory itself: the scene is a `CanvasLayer` and delegates the actual inventory widget behavior to Gloot's `ctrl_inventory.gd`. ([GitHub][3]) That's a healthy boundary. The player **owns inventory state**, while UI is merely a way of looking at/manipulating it.

And you've introduced a generic `Creature` rather than immediately creating `Goblin`, `Rat`, `Orc`, etc. as unrelated scene types. `creature.tscn` is currently just a reusable `CharacterBody3D` with its own script, mesh, and collision shape. ([GitHub][4]) That points in the direction of the data-driven model from your README: generic runtime objects whose differences come from data rather than hundreds of bespoke classes. Your README still explicitly calls that out as a project goal. ([GitHub][5])

So I think we're at a different stage now.

The original roadmap was roughly:

```text
walk around
    ↓
creature
    ↓
combat
    ↓
inventory
    ↓
pickup
    ↓
dialogue
    ↓
quest
```

You've already crossed several of those boundaries.

At this point I would **not keep adding random RPG features yet**. This is the moment where I'd stop and establish the game's first real internal architecture, because the next few systems — stats, combat, items, creatures, dialogue, quests, eventually 5e — are going to define whether MikeRPG stays modular or slowly turns into one enormous collection of tightly coupled GDScript.

The big question I want us to tackle next is:

> **What exactly is an Actor in MikeRPG?**

Right now you have `Player` and `Creature`. Before we add 5e-ish stats, I think we should decide whether they are fundamentally separate things or whether they're two **roles around a common actor/entity model**.

I strongly suspect the model we ultimately want is closer to:

```text
Actor
├── identity
├── stats
├── health
├── inventory
├── abilities
└── faction/team

Player
└── Actor + player controller

Creature
└── Actor + AI controller
```

Then later:

```text
Goblin
= Creature
+ goblin data

Bandit
= Creature
+ bandit data

Mike the Fighter
= Player
+ character data
```

That becomes extremely important for the eventual GM mode, too. A GM could potentially **possess/control any Actor** instead of us building some completely separate special-case “GM monster control” mechanism.

So yes: you've made enough progress that I'd change gears from basic Godot tutorial into **building MikeRPG's first actual game architecture**.

And I think our next lesson should be: **Actor → Stats → Health → simple attack**, while keeping 5e completely out of it initially. Then we'll see whether the simple rule implementation can later be swapped for SRD rules without changing Player, Creature, inventory, or the world. That would prove the modular design actually works.

[1]: https://github.com/stardustsuperwizard/mikerpg/tree/main/scenes "mikerpg/scenes at main · stardustsuperwizard/mikerpg · GitHub"
[2]: https://github.com/stardustsuperwizard/mikerpg/blob/main/scenes/actors/player.tscn "mikerpg/scenes/actors/player.tscn at main · stardustsuperwizard/mikerpg · GitHub"
[3]: https://github.com/stardustsuperwizard/mikerpg/blob/main/scenes/ui/inventory_ui.tscn "mikerpg/scenes/ui/inventory_ui.tscn at main · stardustsuperwizard/mikerpg · GitHub"
[4]: https://github.com/stardustsuperwizard/mikerpg/blob/main/scenes/actors/creature.tscn "mikerpg/scenes/actors/creature.tscn at main · stardustsuperwizard/mikerpg · GitHub"
[5]: https://github.com/stardustsuperwizard/mikerpg "GitHub - stardustsuperwizard/mikerpg: This is an RPG game that I am designing in Godot · GitHub"

## Prompt 2
Does Godot allow me to call files “actor” or will I run into some kind of system issue. Like in Python if I were to call a file, json.py

### Reponse 2
Yes. **`actor.gd` and `actor.tscn` are perfectly reasonable names in Godot.** You don't have the same problem as creating something like `json.py` in Python and accidentally shadowing the standard library.

There is no built-in Godot `Actor` class that would make `actor.gd` problematic.

You could comfortably structure it like:

```text
scenes/
└── actors/
    ├── actor.tscn
    ├── player.tscn
    └── creature.tscn

scripts/
└── actors/
    ├── actor.gd
    ├── player.gd
    └── creature.gd
```

And your base script could eventually be:

```gdscript
class_name Actor
extends CharacterBody3D
```

Then:

```gdscript
class_name Player
extends Actor
```

and:

```gdscript
class_name Creature
extends Actor
```

#### Where Godot *can* have naming collisions

The thing to be more careful about is **`class_name`**, not the filename.

When you write:

```gdscript
class_name Actor
```

you're registering `Actor` as a globally available GDScript type. Therefore you shouldn't also have another script declaring:

```gdscript
class_name Actor
```

And you wouldn't want to use names that conflict with existing Godot classes:

```gdscript
class_name Node       # bad idea
class_name Resource   # bad idea
class_name CharacterBody3D  # definitely don't
```

But:

```gdscript
class_name Actor
```

is fine.

#### One architectural wrinkle

Before we actually create `Actor`, though, I'd distinguish **Actor the concept** from **Actor the 3D body**.

It's tempting to say:

```gdscript
class_name Actor
extends CharacterBody3D
```

but that makes "being an Actor" synonymous with "being a movable 3D physics body."

That might be exactly what we want. Or we might eventually want:

```text
Player (CharacterBody3D)
├── Actor
│   ├── Stats
│   ├── Health
│   └── Inventory
├── Mesh
└── Collision
```

where `Actor` is game-domain functionality composed into a physical thing.

Given your goal of making the rules swappable and eventually supporting things like NPCs, monsters, players, and GM-controlled entities, **I'd think through that distinction before we make `Actor` the superclass of everything.**

But purely from the Godot naming perspective: **`actor.gd`, `actor.tscn`, and `class_name Actor` are safe names.**

## Prompt 3
What about actors and characters?

### Response 3
Both are safe names in Godot: **`actor.gd`, `actors/`, `character.gd`, `characters/`, and `class_name Actor`/`Character` won't cause a Python-`json.py`-style problem.**

But there's a more interesting question here: **what should those words mean in MikeRPG?**

I think there's a useful distinction.

#### Actor vs. Character

I'd use **Actor** for something that exists and acts in the game world:

```text
Actor
├── Player-controlled actor
├── NPC
├── Goblin
├── Wolf
└── Dragon
```

An Actor has things like position, health, movement, inventory, and the ability to perform actions.

I'd use **Character** for the RPG/rules representation:

```text
Character
├── name
├── level
├── attributes
├── skills
├── HP
├── AC
├── abilities
└── equipment
```

That distinction could become extremely useful once we introduce 5e.

For example, imagine:

```text
Player (Actor)
   │
   └── Character
       ├── STR 16
       ├── DEX 12
       ├── CON 14
       ├── HP 24
       ├── Fighter 3
       └── Longsword
```

The **Actor** answers:

> What thing is walking around the Godot world?

The **Character** answers:

> What RPG entity does that thing represent?

That also means `Character` doesn't necessarily need to be a `Node3D` at all. It could eventually be a `Resource` or some other data-oriented object.

#### That separation has interesting consequences

A goblin could be:

```text
Goblin Actor
     ↓
Goblin Character
```

A player:

```text
Player Actor
     ↓
Mike Character
```

And eventually your GM functionality could potentially change **who controls the Actor** without changing its Character.

```text
              ┌── PlayerController
              │
Actor ────────┼── AIController
              │
              └── GMController

     │
     └── Character
          └── rules/stats/etc.
```

Now "GM becomes the goblin" isn't a special goblin feature.

We detach:

```text
AIController
```

and attach:

```text
GMController
```

The goblin remains the same Actor with the same Character, inventory, HP, position, etc.

#### One terminology caution

Godot does have **`CharacterBody3D`** and **`CharacterBody2D`** built in.

That's not a technical reason you can't create:

```gdscript
class_name Character
```

but I probably **wouldn't**.

When you're learning Godot, having:

```text
Character
CharacterBody3D
```

mean substantially different things could get confusing.

I'd probably call the rules/data object something more explicit:

```text
Actor
└── CharacterSheet
```

or perhaps:

```text
Actor
└── Stats
```

For a 5e-oriented project, **`CharacterSheet` is actually quite expressive**:

```text
Actor                    CharacterSheet
─────                    ──────────────
position                 name
rotation                 species
velocity                 class
collision                level
animation                STR/DEX/CON...
controller               HP
                         AC
                         proficiencies
                         abilities
```

That gives us a really clean conceptual line:

> **Actor = representation in the game world.**
> **CharacterSheet = representation in the game rules.**

And that separation fits extremely well with your goal of starting with toy rules and later replacing them with 5e SRD rules. The Actor shouldn't care whether its CharacterSheet is powered by our six-line BabyRPG rules or a full 5e implementation.
