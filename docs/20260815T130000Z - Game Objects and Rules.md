# Game Objects, Actions, and Rules

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
```

That immediately creates awkward classifications:

- Is a wolf a person?
- Is a dragon?
- Is Pac-Man?
- Is an intelligent robot?
- Is a sentient sword?

Instead, there is simply a game object.

What that object **is** can largely be described through traits and data.

John Carter might be:

```yaml
id: john_carter

traits:
  - creature
  - character
  - humanoid
  - human
  - person
```

A wolf:

```yaml
id: wolf

traits:
  - creature
  - animal
```

A sword:

```yaml
id: longsword

traits:
  - item
  - weapon
  - equippable
```

A door:

```yaml
id: wooden_door

traits:
  - interactable
  - openable
  - lockable
```

This avoids creating an enormous inheritance hierarchy merely to describe the nouns of a game.

---

# Games Have a Grammar

The noun analogy leads to another useful abstraction.

If game objects are nouns, **actions are verbs**.

Consider:

```text
NOUN          VERB        NOUN

John          attacks     Thark
Mario         jumps
Pac-Man       eats        pellet
Doomguy       shoots      demon
Link          opens       chest
Steve         mines       block
Cloud         casts       Fire
GM            spawns      dragon
```

The games are dramatically different.

The basic structure is not.

This suggests a conceptual vocabulary.

## Nouns / Game Objects

Things that participate in gameplay.

```text
John Carter
Goblin
Sword
Door
Chest
Tree
Fireball
Paddle
Ball
Block
```

## Traits

What kind of thing an object is.

```text
creature
human
weapon
item
container
openable
destructible
```

## Properties / State

What is currently true about it.

```text
health = 17
locked = true
poisoned = false
strength = 18
ammo = 7
```

## Capabilities

What it can potentially do.

```text
move
attack
jump
interact
equip
cast
open
mine
```

## Actions

Things that are attempted.

```text
move
attack
open
take
drop
equip
cast
speak
use
destroy
```

## Relationships

How game objects relate to one another.

```text
John owns Sword
Sword is equipped by John
Goblin is hostile to John
John is inside Room
Dejah follows John
Chest contains Potion
```

## Rules

The mechanisms that determine whether an action is allowed and what happens when it occurs.

## Events

Facts recording what actually happened.

Together, these form something resembling a grammar for gameplay.

---

# Games Across Genres

This model applies surprisingly well across very different games.

## Pong

```text
Objects:
    paddle
    ball

Actions:
    move

State:
    position
    velocity
    score

Rules:
    collision
    bounds
    scoring
```

## Super Mario Bros.

```text
Objects:
    Mario
    enemies
    blocks
    power-ups

Actions:
    move
    jump
    stomp
    collect

State:
    position
    velocity
    power-up state

Rules:
    gravity
    collision
    damage
```

## Doom

```text
Objects:
    player
    monsters
    weapons
    ammunition
    doors

Actions:
    move
    look
    shoot
    interact
    collect

State:
    health
    ammo
    weapons
    position

Rules:
    collision
    hitscan/projectiles
    damage
```

## Zelda

```text
Objects:
    character
    monster
    weapon
    item
    door
    chest

Actions:
    move
    attack
    open
    take
    use
    push

State:
    health
    position
    locked
    damage
```

## Neverwinter Nights

```text
Objects:
    creature
    character
    item
    spell
    placeable
    trigger
    encounter

Actions:
    move
    attack
    cast
    equip
    speak
    use
    rest

State:
    attributes
    HP
    AC
    effects
    equipment
    faction

Rules:
    D&D/d20
```

The vocabulary grows enormously, but the architecture remains recognizable.

---

# Objects Should Be Composed, Not Classified to Death

A traditional object hierarchy might become:

```text
Entity
└── LivingEntity
    └── Creature
        └── Humanoid
            └── Character
                └── Player
                    └── WizardPlayer
```

That becomes increasingly difficult to reuse.

Instead, objects can be composed from traits, capabilities, state, and eventually components.

For example:

```text
John Carter

traits:
    creature
    character
    human

capabilities:
    move
    attack
    interact
    equip

state:
    health: 30
    strength: 18
```

A door:

```text
Wooden Door

traits:
    door
    interactable
    openable
    lockable

state:
    open: false
    locked: true
```

A chest:

```text
Chest

traits:
    container
    interactable
    openable
    lockable

state:
    open: false
```

The framework does not need `JohnCarter`, `WoodenDoor`, and `TreasureChest` classes merely because these are different game concepts.

---

# Definition vs. Instance

One of the most important distinctions is between **what a kind of object is** and **one particular object currently existing in the game**.

A definition describes the type:

```yaml
id: goblin

display_name: Goblin

traits:
  - creature
  - humanoid

capabilities:
  - move
  - attack

default_state:
  health: 10
  strength: 8
```

Ten goblins can share this definition.

At runtime:

```text
goblin_001
    definition: goblin
    health: 10

goblin_002
    definition: goblin
    health: 4

goblin_003
    definition: goblin
    health: 0
```

Definitions are primarily content.

Instances are current world state.

---

# A Possible Technical Primitive

A minimal Godot representation could resemble:

```gdscript
class_name GameObject
extends RefCounted

var id: StringName
var definition: ObjectDefinition
var state: Dictionary = {}
var traits: Array[StringName] = []
var capabilities: Array[StringName] = []
```

And definitions could use Godot Resources:

```gdscript
class_name ObjectDefinition
extends Resource

@export var id: StringName
@export var display_name: String
@export var traits: Array[StringName]
@export var capabilities: Array[StringName]
@export var default_state: Dictionary
```

Importantly, `GameObject` does **not** have to inherit from `Node2D`, `Node3D`, `CharacterBody2D`, or `CharacterBody3D`.

The game object represents the game concept.

Godot Nodes represent it in a running scene.

---

# Actions Are Verbs

An action represents an attempt to change the world.

A minimal action could look like:

```gdscript
class_name GameAction
extends RefCounted

var actor_id: StringName
var action: StringName
var target_id: StringName
var parameters: Dictionary = {}
```

Examples:

```text
John Carter → attack → Goblin

John Carter → open → Door

Link → open → Chest

Steve → mine → Block

Player → equip → Sword
```

This gives very different games a common semantic structure.

---

# Capabilities vs. Actions

A capability answers:

> **What can this object potentially do?**

An action says:

> **This object is attempting to do it now.**

John Carter might have:

```yaml
capabilities:
  - move
  - attack
  - interact
  - equip
```

That does not mean every attack automatically succeeds.

It means an attack is something John Carter is permitted to attempt.

The rules still determine what happens.

---

# Rules Determine Whether a Sentence Is Legal

An action should not directly mutate the world merely because it was requested.

Instead:

```text
Action requested
       ↓
Can the actor attempt it?
       ↓
Validate target/context
       ↓
Apply rules
       ↓
Determine result
       ↓
Mutate state
       ↓
Produce events
```

For example:

```text
John → OPEN → Door
```

The system might ask:

```text
Can John perform OPEN?
Is Door openable?
Is John close enough?
Is Door already open?
Is Door locked?
If locked, does John have the appropriate key?
```

Then:

```text
Result:
    success

Changes:
    Door.open = true

Events:
    door_opened
```

The "sentence" was legal according to the rules.

---

# Rules Are Where Games Become Different

This is an important boundary.

The action:

```text
John → attack → Goblin
```

does not have to know whether the game uses:

- Zelda-style collision combat
- Real-time action combat
- Final Fantasy-style turns
- World of Warcraft cooldowns
- D&D 5e
- A custom d6 system

The rules determine resolution.

A primitive ruleset might say:

```text
attack:
    damage = random(1, 6)
```

A 5e implementation might instead resolve:

```text
d20
+ ability modifier
+ proficiency
vs.
armor class
```

The semantic action remains:

```text
John → attack → Goblin
```

This provides an important boundary between a reusable framework and an opinionated game implementation.

---

# Action Results

Actions should produce explicit results.

For example:

```gdscript
class_name ActionResult
extends RefCounted

var success: bool
var reason: StringName
var changes: Array
var events: Array
```

An attack might result in:

```text
success: true

changes:
    goblin.health: 10 → 6

events:
    attack_succeeded
    damage_applied
```

This becomes useful for:

- UI
- Animation
- Combat logs
- Networking
- Server authority
- Replays
- AI
- GM tools
- Debugging

The UI does not need to calculate damage.

It can receive:

```text
damage_applied:
    target: goblin_12
    amount: 4
```

and display an appropriate effect.

---

# Controllers Produce Intent

The thing being controlled and the thing controlling it should be separate concepts.

```text
Controller
     ↓
Game Object
```

Possible controllers include:

```text
HumanController
AIController
NetworkController
GMController
ScriptedController
ReplayController
```

A player-controlled character might be:

```text
HumanController
      ↓
John Carter
```

A goblin:

```text
AIController
      ↓
Goblin
```

A multiplayer character:

```text
NetworkController
      ↓
Character
```

A GM possessing a monster:

```text
GMController
      ↓
Goblin
```

The object itself does not fundamentally change because its source of intent changed.

Controllers should preferably request actions rather than directly mutate game state.

```text
Human Input
     ↓
Controller
     ↓
ATTACK request
     ↓
Rules
     ↓
Result
```

AI follows the same path:

```text
AI Decision
     ↓
Controller
     ↓
ATTACK request
     ↓
Rules
     ↓
Result
```

This is particularly important for multiplayer and authoritative-server architectures.

---

# Relationships

Eventually, relationships may deserve first-class representation.

Examples:

```text
John --owns--> Sword

Sword --equipped_by--> John

John --hostile_to--> Thark

Dejah --follows--> John

Chest --contains--> Potion

Door --connects--> Room B
```

Relationships allow gameplay concepts to be expressed without embedding every possible connection into specialized classes.

They should probably not be necessary for the first implementation, but they are a natural extension of the model.

---

# Godot Owns Presentation

The framework should **not** abstract Godot's engine responsibilities.

Godot should continue to own:

- Nodes
- Scenes
- Rendering
- Physics
- Collision
- Navigation
- Animation
- Input primitives
- Audio
- UI
- Resource loading

The framework provides gameplay semantics that Godot intentionally does not provide.

Godot knows what this is:

```text
CharacterBody3D
```

It does not know what this is:

```text
Player Character
```

Godot understands:

```text
NavigationAgent2D
```

It does not understand:

```text
NPC
```

Godot understands:

```text
InputEvent
```

It does not understand:

```text
Goblin attempts to attack John Carter.
```

That semantic layer is the framework's territory.

---

# Presentation Independence

Separating game objects from Godot presentation creates an interesting possibility.

Consider John Carter:

```text
GameObject
    id: john_carter
    health: 30
    strength: 18
    capabilities:
        move
        attack
        interact
```

A 3D game could represent him as:

```text
JohnCarter3D : CharacterBody3D
├── MeshInstance3D
├── CollisionShape3D
├── AnimationTree
└── GameObjectBinding
```

A top-down sprite game could represent the same object as:

```text
JohnCarter2D : CharacterBody2D
├── AnimatedSprite2D
├── CollisionShape2D
└── GameObjectBinding
```

The same game object could theoretically even be represented by a text interface:

```text
"John Carter stands before the door."
```

The presentation changes.

The noun does not.

---

# Why the 2D Experiment Matters

MikeRPG began as a 3D RPG project.

Creating a Zelda/Pokémon-style 2D experiment provides an excellent architectural test.

The question is not simply:

> Can MikeRPG become a 2D game?

The better question is:

> **How much of the game model survives when the entire presentation changes?**

Ideally, these should remain largely unchanged:

```text
GameObject
Actor state
Attributes
Inventory
Equipment
Actions
Combat rules
AI decisions
Authority
Networking
Quests
Dialogue
```

While these change:

```text
CharacterBody3D → CharacterBody2D

MeshInstance3D → AnimatedSprite2D

CollisionShape3D → CollisionShape2D

Camera3D → Camera2D

NavigationAgent3D → NavigationAgent2D

3D world → TileMapLayer
```

If the same John Carter definition can exist in both versions, the architecture has successfully separated gameplay semantics from presentation.

---

# Sprite-Based Presentation

A sprite-based version also opens interesting possibilities for reusable visual systems.

A character could be rendered through a layered paper-doll system:

```text
Character
├── Body
├── Hair
├── Chest
├── Legs
├── Boots
├── MainHand
└── OffHand
```

Each layer uses the same animation frames.

For example:

```text
idle_south
walk_south
walk_north
walk_east
walk_west
attack_south
...
```

When the body displays frame 3 of `walk_south`, the armor, hair, weapon, and boots display their corresponding frame.

Appearance becomes data:

```yaml
appearance:
  body: human_01
  hair: long_03
  hair_color: black
  eyes: green
```

Equipment remains gameplay data:

```yaml
equipment:
  head: iron_helmet
  chest: leather_armor
  legs: brown_trousers
  feet: leather_boots
  main_hand: longsword
  off_hand: wooden_shield
```

The renderer determines how those concepts appear.

An Iron Sword should not fundamentally *be* a sprite or a 3D model.

It is a game object.

Its presentation is supplied by the client.

---

# Mobile and Handheld Presentation

A sprite-based game also maps naturally to mobile.

A handheld-style interface could provide:

```text
┌─────────────────────────────┐
│                             │
│       GAME VIEWPORT         │
│                             │
│                             │
├─────────────────────────────┤
│                             │
│      ▲                (A)   │
│    ◀   ▶            (B)     │
│      ▼                      │
│                             │
│   MENU           INVENTORY  │
└─────────────────────────────┘
```

Input should map to semantic actions rather than particular hardware:

```gdscript
Input.is_action_pressed("move_up")
```

Then `move_up` could originate from:

- W
- Arrow key
- Gamepad D-pad
- Analog stick
- Touchscreen D-pad
- AI
- Network input

Again, the source of intent changes.

The game semantics do not.

---

# Data vs. Code

The goal should **not** be to make everything data.

Data cannot define meaningful behavior unless code exists that understands the vocabulary.

For example:

```yaml
capabilities:
  - jump
```

does not create jumping.

Somewhere, code must implement what `jump` means.

A useful division is:

## Engine Mechanism

Provided primarily by Godot:

```text
collision
physics
rendering
navigation
animation playback
input
network transport
```

## Game Mechanism

Reusable code:

```text
GameObject
Action
ActionResolver
Controller
Inventory
Dialogue
Quest
CombatResolver
AbilitySystem
EffectSystem
```

## Game Definition

Primarily data:

```text
John Carter has 18 Strength.

Goblin has 10 HP.

Longsword deals 1d8 slashing damage.

Potion heals 10 HP.

Luigi jumps higher than Mario.

Fireball costs 3 MP.
```

A useful design principle is therefore:

> **New game content should usually be data. New kinds of game behavior should require code.**

---

# A Layered Architecture

This suggests a possible long-term structure:

```text
Godot
   ↓
Generic Gameplay / Object Framework
   ↓
MikeRPG
   ↓
5e Rules
   ↓
Campaign
```

## Godot

Provides engine primitives.

## Generic Gameplay Framework

Potential reusable Asset Library package:

```text
GameObject
ObjectDefinition
Controller
Action
ActionResult
Capability
Trait
State
Authority
```

## MikeRPG

Adds opinionated RPG concepts:

```text
Creature
Character
Inventory
Equipment
Dialogue
Quest
Encounter
Faction
GM systems
RPG AI
RPG world concepts
```

## 5e Rules

Adds:

```text
Ability scores
Armor Class
Saving throws
Skills
Initiative
Spells
Feats
Classes
d20 resolution
Conditions
```

## Campaign

Adds actual game content:

```text
characters
creatures
quests
maps
items
dialogue
art
music
encounters
```

This allows MikeRPG to remain focused on its original goal—building something resembling "Neverwinter Nights in Godot"—while extracting genuinely reusable pieces into independent Godot addons where appropriate.

---

# Avoid Reinventing Godot

The biggest architectural danger is abstraction for abstraction's sake.

Do **not** create framework replacements for:

```text
Node
Node2D
Node3D
position
sprite
mesh
collision
camera
physics
scene
signal
```

Godot already solves these problems.

Instead, focus on concepts Godot deliberately does not define:

```text
GameObject
Player
NPC
Controller
Action
Capability
Attribute
Effect
Inventory
Equipment
Quest
Dialogue
Authority
Faction
```

The framework should describe **game semantics**, not build another game engine.

---

# Games as Stories

There is also a useful philosophical model underneath this architecture.

A game can be thought of as:

> **A system in which participants create a sequence of events by acting upon a modeled world according to rules.**

Those events form the game's history.

That history becomes its story.

Minecraft can produce:

```text
Steve entered the cave.
Steve mined iron.
A creeper approached Steve.
The creeper exploded.
Steve died.
```

Neverwinter Nights might produce:

```text
John entered the tavern.
John spoke to the innkeeper.
John accepted the quest.
John traveled to the ruins.
John attacked the goblin.
```

One may have heavily authored narrative while the other is largely emergent.

Architecturally, both are sequences of state transitions caused by game objects performing actions under rules.

This gives us:

```text
              WORLD
                │
             contains
                ↓
          GAME OBJECTS
                │
           controlled by
                ↓
           CONTROLLERS
                │
             produce
                ↓
             INTENTS
                │
                ↓
       ┌────── RULES ──────┐
       │                   │
       ↓                   ↓
    ACTIONS             RESULTS
                            │
                       mutate state
                            │
                            ↓
                         EVENTS
                            │
                            ↓
                         HISTORY
                            │
                            ↓
                          STORY
```

This does not mean the API should literally use classes named `Noun`, `Verb`, and `Adjective`.

Those are useful conceptual tools.

Software vocabulary such as:

```text
GameObject
Trait
State
Capability
Action
Relationship
Rule
Event
```

is likely clearer.

The underlying philosophy remains:

> **Model the nouns. Define the verbs. Express differences as data. Let rules determine which sentences are legal. Record what happens as events.**

---

# Minimal First Implementation

The biggest risk is attempting to implement the entire conceptual model immediately.

Version 0.1 should be deliberately tiny.

Start with five primitives:

```text
ObjectDefinition
GameObject
GameAction
ActionResult
ActionResolver
```

A `GameObject` initially needs only:

```text
id
traits
capabilities
state
```

Then implement only three game objects:

```text
Player
Goblin
Door
```

And only three actions:

```text
move
attack
open
```

The complete test scenario becomes:

```text
Player moves.

Player opens door.

Player attacks goblin.

Goblin attacks player.
```

Once that works, represent the same objects in two different Godot presentations.

### 3D

```text
Player
    ↓
CharacterBody3D
    ↓
3D Model
```

### 2D

```text
Player
    ↓
CharacterBody2D
    ↓
AnimatedSprite2D
```

The `GameObject`, actions, state, and rules should not need to change.

If that works, the core architectural hypothesis has been validated.

Only then should the framework expand into:

```text
Controllers
Relationships
Attributes
Effects
Inventory
Equipment
AI
Networking
Authority
Dialogue
Quests
RPG rules
5e
```

---

# Core Design Principle

The framework can ultimately be summarized in four sentences:

> **Game objects represent what exists.**
>
> **Actions represent what is attempted.**
>
> **Rules determine what happens.**
>
> **Godot represents the result.**

Or, expressed through the grammatical model:

> **Model the nouns. Define the verbs. Express differences as data. Let rules determine which sentences are legal. Record what happens as events.**

The goal is not to create a universal game engine.

Godot is already the engine.

The opportunity is to provide the reusable semantic layer between an engine that understands nodes, physics, input, and rendering and a game that understands players, goblins, swords, attacks, ownership, death, quests, and stories.
