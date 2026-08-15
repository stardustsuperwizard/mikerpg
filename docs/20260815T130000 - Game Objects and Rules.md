l# Game Objects, Actions, and Rules

## A Reusable Gameplay Architecture for Godot

### Background

MikeRPG began with a fairly specific goal:

> Build something resembling a modern, open-source Neverwinter Nights: a Godot-based platform for building and playing D&D/5e-style RPGs, including multiplayer, dedicated servers, GM controls, NPCs, combat, quests, dialogue, inventory, and eventually a complete 5e rules implementation.

That remains a goal.

However, building MikeRPG has exposed a more general problem.

Godot provides excellent primitives for creating games:

- Nodes and scenes
- 2D and 3D rendering
- Physics
- Collision
- Navigation
- Animation
- Input
- Networking primitives
- UI
- Resource management

Existing Godot addons and templates also provide many useful pieces:

- Menus
- Save systems
- Pause systems
- Inventory systems
- Dialogue systems
- Starter game templates
- Character controllers
- Networking helpers

But there is a gap between **Godot's engine primitives** and **the semantics of a game**.

Many projects eventually implement their own versions of:

- Player
- NPC
- Creature
- Item
- Interaction
- Health
- Attributes
- Actions
- Effects
- AI control
- Human control
- Network control
- Authority

Worse, these implementations are frequently coupled to a particular genre or presentation.

A platformer starter kit provides a platformer player.

An FPS framework provides an FPS player.

An RPG framework provides an RPG character.

A 3D framework assumes `CharacterBody3D`.

A top-down framework assumes `CharacterBody2D`.

This raises a more fundamental question:

> **What do protagonist-led games actually have in common?**

Consider games as different as:

- Pong
- Pac-Man
- Super Mario Bros.
- The Legend of Zelda: A Link to the Past
- Doom
- Final Fantasy
- Neverwinter Nights
- World of Warcraft
- Minecraft

Their presentation, rules, genres, and complexity are radically different.

Their underlying gameplay architecture is less different than it initially appears.

---

# Games as Modeled Worlds

At the most basic level, a game contains **things**.

Those things have properties.

Things can do things.

Things can have things done to them.

Rules determine what happens.

That gives us a simple model:

> **Game objects represent what exists. Actions represent what is attempted. Rules determine what happens. Godot represents the result.**

This may be the useful abstraction between Godot-the-engine and a specific game.

---

# The Noun Model

A traditional definition of a noun is a person, place, thing, or object.

For purposes of a gameplay framework, it is unnecessary to model every grammatical noun. We do not need an ontology capable of representing abstract concepts simply because English considers them nouns.

Instead:

> **A game object is a thing that participates in gameplay.**

A useful test is:

> **Can something happen to it, or can it cause something to happen?**

If so, it may deserve representation as a game object.

Examples include:

| Thing | Game Object? | Reason |
|---|---:|---|
| Player character | Yes | Acts and changes state |
| Goblin | Yes | Acts and can be acted upon |
| Sword | Yes | Can be equipped, dropped, used |
| Door | Yes | Can open, close, lock, or be destroyed |
| Chest | Yes | Can contain objects and be opened |
| Fireball | Yes | Can travel, hit something, and expire |
| Pong ball | Yes | Moves and collides |
| Pong paddle | Yes | Moves and is controlled |
| Minecraft block | Yes | Can be placed, mined, and destroyed |
| Tree | Maybe | Depends on whether gameplay interacts with it |
| Decorative flower | Probably not | May exist only as presentation |
| Mountain backdrop | No | Presentation/world geometry |
| Hyrule | Not necessarily | Better modeled by world/scene systems |

This prevents the framework from attempting to model the entire world when Godot already provides excellent systems for doing that.

---

# A Person Is a Kind of Game Object

The root abstraction should not necessarily be:

```text
Noun
├── Person
└── Object
