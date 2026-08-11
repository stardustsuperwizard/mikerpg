# Game Philosphy

## Prompt 1
Yeah. I like that. Let me ask you a philosophical question. How far does this abstraction concept go before I’m back to, “we invented Godot?” 

Is the game a base 5e platform that can be extended with modular addon components (like inventory)?

## Reponse 1
Yes — and I think you've identified the architectural trap perfectly.

If we keep abstracting `Actor`, `Controller`, `CharacterSheet`, `RulesEngine`, `World`, `InventoryProvider`, `MovementSystem`, `InteractionSystem`, etc., eventually **we've built a mediocre game engine on top of Godot**.

Godot already won that job.

The useful boundary, in my view, is:

> **Godot is the game platform. MikeRPG is a 5e RPG platform built with Godot.**

That gives us a much clearer test for what belongs in MikeRPG.

### What Godot should own

Don't abstract things merely because we *could*.

Let Godot be Godot:

```text
Godot
├── Nodes
├── Scenes
├── CharacterBody3D
├── Physics
├── Input
├── Rendering
├── Navigation
├── Animation
├── Resources
├── Signals
├── Multiplayer API
└── Addon/plugin mechanism
```

For example, I would **not** invent `MikePhysicsBody` so that someday we could theoretically replace Godot physics.

We're making a Godot game. Use `CharacterBody3D`.

Likewise, we probably don't need our own generalized event bus. Godot already has signals and groups. We don't need an abstract scene system because `.tscn` exists.

That's where abstraction becomes architecture astronautics.

### What MikeRPG should own

The interesting abstraction boundary is **RPG semantics**.

Godot knows what this is:

```text
CharacterBody3D
```

Godot has no idea what these are:

```text
Actor
CharacterSheet
Ability Score
Creature
NPC
Player Character
Attack
Damage
Armor Class
Saving Throw
Condition
Spell
Feat
Quest
Encounter
Faction
```

**That's our territory.**

And that leads directly to your second question.

I increasingly think MikeRPG should be conceived as:

> **A modular 5e SRD RPG platform built on Godot.**

And then **MikeRPG-the-game is the reference game/campaign built using that platform.**

Conceptually:

```text
                GODOT
                  │
         ┌────────┴────────┐
         │                 │
    Godot features      Godot addons
                           │
                           │
                    Gloot Inventory
                    Dialogue Manager
                    etc.
         │                 │
         └────────┬────────┘
                  │
              MikeRPG Core
                  │
          ┌───────┴────────┐
          │                │
       Actor          CharacterSheet
       Creature       5e Rules
       Interaction    Combat
       Items          Conditions
       etc.           etc.
          │                │
          └───────┬────────┘
                  │
              Mike World
                  │
          ┌───────┼────────┐
        Tavern   Dungeon   Forest
        NPCs     Quests    Story
```

And **Gloot doesn't become part of our RPG rules**.

It's an implementation underneath them.

That's subtle but important.

Suppose our game says:

```gdscript
actor.inventory
```

The actual inventory functionality might currently be provided by Gloot.

We don't need to write another inventory system just because we're making a reusable RPG platform.

### Where modularity gets really interesting

I'd distinguish between **commodity modules** and **game modules**.

Commodity modules are things somebody else has already solved:

```text
Inventory        → Gloot
Dialogue         → Dialogue Manager
Save system      → existing addon, if suitable
Pathfinding      → Godot Navigation
Networking       → Godot multiplayer initially
```

Then MikeRPG adds **RPG-specific modules**:

```text
5e Core Rules
5e Combat
5e Character Creation
5e Conditions
5e Spellcasting
5e Equipment
5e Monsters
GM Mode
Quest System
Encounter System
```

And finally your actual campaign adds content:

```text
Mike World
├── Bob the Innkeeper
├── Goblin Cave
├── Sword of Mike
├── Save-the-Well Quest
└── The Terrible Dragon Steve
```

That's a much more compelling project than building yet another inventory implementation.

### And yes, this could become genuinely reusable

Imagine eventually cloning MikeRPG and getting:

```text
New Godot Project
        +
MikeRPG
        ↓
Basic 5e game
```

You create:

```text
Goblin.tres
```

and specify something conceptually like:

```text
Name: Goblin
Creature Type: Humanoid
AC: 15
HP: 7
Speed: 30

STR: 8
DEX: 14
CON: 10
INT: 10
WIS: 8
CHA: 8
```

Drop a generic Actor into a scene:

```text
Actor
└── CharacterSheet = Goblin.tres
```

and it becomes a goblin.

Then attach:

```text
AIController
```

and it's an NPC.

Attach:

```text
PlayerController
```

and somebody can control it.

That is useful abstraction because it's expressing **RPG concepts**, not reinventing engine concepts.

### The rule I'd use

Whenever we're considering creating an abstraction, ask:

> **"Is this abstraction describing RPG/5e semantics, or are we hiding Godot?"**

If it's:

> "Godot's `CharacterBody3D` is ugly; let's wrap it in our own universal `PhysicalEntity` interface."

Probably **no**.

If it's:

> "A goblin and player both need HP, ability scores, attacks, conditions and inventory."

Probably **yes**.

And if it's:

> "We need an inventory system."

First ask:

> **"Has someone already built a good Godot inventory addon?"**

If yes, **use it**.

That gives MikeRPG a fairly crisp philosophy:

**Don't replace Godot. Don't rebuild solved systems. Build the missing RPG layer.**

And I think **"modular 5e SRD RPG platform for Godot"** is becoming a more accurate description of what you're building than simply "my RPG."

## Prompt 2
lol, we are “Larian Studios lite” hen?

## Response 2
😂 A little bit, yes.

But there’s an important distinction: **Larian Studios Lite with aggressively lowered expectations.**

Larian Studios built an enormous RPG technology stack because they needed to ship enormous commercial RPGs. We're essentially exploring the same *layering problem*, but letting Godot and community addons do as much of the heavy lifting as possible.

Conceptually:

```text
Larian
────────────────────────
Divinity Engine
RPG systems
D&D 5e implementation
GM/content tools
Game content
Baldur's Gate 3
```

versus:

```text
MikeRPG
────────────────────────
Godot                  ← definitely not building this
Community addons       ← definitely stealing* this
MikeRPG RPG layer      ← building this
5e SRD rules           ← building/integrating this
GM tools               ← eventually building this
Mike World             ← game/content
```

**stealing in the proud and ancient open-source sense of complying with licenses.* 😄

And the interesting part isn't trying to reproduce Baldur's Gate 3. It's that **the architecture can resemble what larger RPG studios need without the scope resembling what larger RPG studios build.**

Our first implementation of "combat" can still be:

```text
attack goblin
→ roll d20
→ hit
→ subtract 3 HP
→ goblin dies
```

No cinematic dialogue. No motion-captured goblin getting emotionally devastated by your dialogue choices. No 400-person art department.

But underneath that silly little prototype, we can establish:

```text
Godot
   ↓
Reusable Godot addons
   ↓
MikeRPG RPG platform
   ↓
5e SRD implementation
   ↓
Mike World
```

And **that** is actually a pretty interesting open-source project in its own right.

So yes.

**Larian Studios Lite™ — now with 99.9% fewer employees.**

## Prompt 3
Okay, so tell/show me how this works. Layout the project for me now that we are hyper focused on building a 5e platform.

## Response 3
Yes. Given the direction you’ve settled on, I would now organize MikeRPG as **three clear layers**:

```text
Godot + third-party addons
        ↓
MikeRPG 5e platform
        ↓
Actual game / campaign content
```

Your repo already has the beginnings of this split: `data/`, `scenes/`, and `scripts/`, with separate `actors`, `rules`, `ui`, and `world` areas, plus GLoot as an external inventory addon. ([GitHub][1])

I would evolve it toward this:

```text
mikerpg/
│
├── addons/                     # OTHER PEOPLE'S CODE
│   ├── gloot/
│   ├── dialogue_manager/
│   └── ...
│
├── platform/                   # MIKERPG: reusable RPG/5e layer
│   │
│   ├── actors/
│   │   ├── actor.gd
│   │   ├── actor.tscn
│   │   ├── player_controller.gd
│   │   ├── ai_controller.gd
│   │   └── gm_controller.gd
│   │
│   ├── characters/
│   │   ├── character_sheet.gd
│   │   ├── ability_scores.gd
│   │   ├── class_definition.gd
│   │   └── species_definition.gd
│   │
│   ├── rules/
│   │   ├── dice.gd
│   │   ├── checks.gd
│   │   ├── saving_throws.gd
│   │   ├── combat.gd
│   │   ├── damage.gd
│   │   ├── conditions.gd
│   │   └── movement.gd
│   │
│   ├── items/
│   │   ├── item_definition.gd
│   │   ├── equipment.gd
│   │   └── inventory_adapter.gd
│   │
│   ├── abilities/
│   │   ├── action.gd
│   │   ├── spell.gd
│   │   └── feature.gd
│   │
│   ├── interaction/
│   │   ├── interactable.gd
│   │   └── interaction_system.gd
│   │
│   ├── encounters/
│   │   └── encounter.gd
│   │
│   └── gm/
│       └── ...
│
├── srd/                        # 5E CONTENT / DEFINITIONS
│   │
│   ├── classes/
│   │   ├── fighter.tres
│   │   ├── wizard.tres
│   │   └── ...
│   │
│   ├── species/
│   │
│   ├── monsters/
│   │   ├── goblin.tres
│   │   ├── wolf.tres
│   │   └── ...
│   │
│   ├── items/
│   │   ├── longsword.tres
│   │   ├── shield.tres
│   │   └── ...
│   │
│   ├── spells/
│   │
│   ├── conditions/
│   │
│   └── feats/
│
├── game/                       # MIKE WORLD: YOUR ACTUAL GAME
│   │
│   ├── actors/
│   │   └── mike.tres
│   │
│   ├── npcs/
│   │   └── bob_the_innkeeper.tres
│   │
│   ├── quests/
│   │   └── goblin_problem.tres
│   │
│   ├── maps/
│   │   ├── tavern.tscn
│   │   └── goblin_cave.tscn
│   │
│   ├── dialogue/
│   │
│   └── items/
│       └── sword_of_mike.tres
│
├── ui/
│   ├── character_sheet/
│   ├── inventory/
│   ├── combat/
│   └── gm/
│
├── tests/
│
├── project.godot
└── README.md
```

I would not necessarily create all of those directories today. This is the **target mental model**, not a mandate to create 47 empty folders.

The critical separation is this:

### `platform/` contains behavior

This is the stuff **we build** because Godot does not understand RPGs.

For example:

```gdscript
class_name CharacterSheet
extends Resource

@export var strength: int
@export var dexterity: int
@export var constitution: int
@export var current_hp: int
@export var max_hp: int
@export var armor_class: int
```

Or:

```gdscript
class_name Dice

static func d20() -> int:
    return randi_range(1, 20)
```

Or:

```gdscript
Combat.attack(attacker, target)
```

The platform knows **how the RPG works**.

---

### `srd/` contains 5e definitions

This is a really important distinction.

A goblin is mostly **not code**.

We shouldn't have:

```text
goblin.gd
wolf.gd
orc.gd
dragon.gd
```

with each one implementing its own behavior.

Instead:

```text
Actor
  +
CharacterSheet
  +
GoblinDefinition
```

The definition might eventually be a Godot Resource:

```text
Goblin

AC: 15
HP: 7
Speed: 30

STR: 8
DEX: 14
CON: 10
INT: 10
WIS: 8
CHA: 8

Actions:
    Scimitar
    Shortbow
```

The **platform** knows what `AC`, `HP`, `STR`, an attack roll, and damage mean.

The **SRD data** says what a Goblin's values are.

That is exactly the modularity your README calls for: don't hardcode every NPC when a generic runtime object can be populated from data. 

---

### `game/` contains your adventure

And then we get to the part that's actually Mike's D&D game.

Suppose you make:

```text
game/npcs/gribble.tres
```

Gribble might reference:

```text
Base creature: Goblin
Name: Gribble
Faction: Goblin Cave
Dialogue: gribble.dialogue
Inventory:
    rusty_key
```

You haven't invented a new creature implementation.

You've made **content using the platform**.

That's the same distinction an RPG toolkit needs:

```text
ENGINE
Godot

PLATFORM
MikeRPG

RULESET
5e SRD

CAMPAIGN
Mike World
```

And that's the architecture I would anchor everything else around.

### Actor becomes surprisingly small

This also answers our earlier Actor discussion.

I would resist making `Actor` into a gigantic god-class containing every RPG feature.

An Actor should mostly represent:

> **Something embodied in the Godot world that can participate in the RPG.**

Something roughly like:

```text
Actor (CharacterBody3D)
│
├── Visual
├── Collision
├── CharacterSheet
├── Inventory
└── Controller
```

And then:

```text
Controller
├── PlayerController
├── AIController
└── GMController
```

This is where the architecture becomes very powerful.

A goblin controlled by AI:

```text
Actor
├── CharacterSheet → Goblin
└── AIController
```

A player's fighter:

```text
Actor
├── CharacterSheet → Mike
└── PlayerController
```

A GM who clicks the goblin and chooses **Possess**:

```text
Actor
├── CharacterSheet → Goblin
└── GMController
```

Nothing about the Goblin changes.

That's a legitimate RPG abstraction rather than reinventing Godot.

### CharacterSheet is the bridge into the rules

This is probably going to become one of the most important objects in MikeRPG.

I'd expect something conceptually like:

```text
Actor
      │
      ▼
CharacterSheet
      │
      ├── AbilityScores
      ├── HP
      ├── AC
      ├── Speed
      ├── Proficiencies
      ├── Features
      ├── Conditions
      └── Actions
```

Notice that `CharacterSheet` doesn't necessarily care whether the character is rendered as:

```text
a humanoid
a wolf
a dragon
a floating cube
```

That's Godot/world representation.

Likewise, `Actor` shouldn't calculate:

```text
strength modifier
proficiency bonus
attack roll
saving throw
```

That's rules territory.

So:

```gdscript
actor.attack(target)
```

might eventually delegate:

```text
Actor
  ↓
Combat
  ↓
CharacterSheet
  ↓
Dice / Rules
```

Conceptually:

```gdscript
var result = Combat.attack(actor, target)
```

and `Combat` produces something like:

```text
AttackResult
├── roll: 17
├── modifier: +5
├── total: 22
├── target_ac: 15
├── hit: true
├── damage: 8
└── damage_type: SLASHING
```

Then Godot takes that result and does presentation:

```text
play sword animation
show "8"
play goblin hit reaction
update health bar
```

**Rules don't play animations.**

That's a boundary worth protecting.

### Inventory is a perfect example

GLoot is already external to your core code and deliberately fetched as an addon after clone. 

So:

```text
MikeRPG concept
Inventory
      │
      ▼
inventory_adapter.gd
      │
      ▼
GLoot
```

The rest of MikeRPG shouldn't need to know every GLoot API detail.

For example, your RPG layer might care about:

```gdscript
inventory.has_item("healing_potion")
inventory.add_item("longsword")
inventory.equip("shield")
```

while the adapter translates those requests into whatever GLoot expects.

We're not creating a universal plugin abstraction framework.

We're just putting a **thin seam around an important external dependency**.

### And 5e itself should be modular too

This is the part I would emphasize now.

Don't create one:

```text
rules.gd
```

containing 4,000 lines of D&D.

5e itself is composed of concepts:

```text
Rules
│
├── Dice
├── Ability Checks
├── Saving Throws
├── Attack Rolls
├── Damage
├── Advantage / Disadvantage
├── Conditions
├── Initiative
├── Movement
├── Resting
├── Death / Stabilization
├── Spellcasting
└── Advancement
```

Those can build on each other.

For example:

```text
Dice
 ↓
Check
 ↓
AttackRoll
 ↓
Combat
```

An attack roll doesn't need to reinvent a d20.

And a saving throw doesn't need to reinvent ability modifiers.

You end up with something like:

```text
d20()
  +
ability_modifier()
  +
proficiency()
  +
advantage/disadvantage()
       ↓
   CheckResult
```

Attack rolls and saving throws are specialized uses of that machinery.

That is useful abstraction because **it mirrors the actual rule system**.

### The dependency direction matters

This is perhaps the single most important architectural rule I'd add:

```text
game/
  ↓
srd/
  ↓
platform/
  ↓
Godot + addons
```

Dependencies go **down**.

Never:

```text
platform/
   ↓
game/bob_the_innkeeper.gd
```

The platform should not know Bob exists.

And preferably:

```text
platform/
   X
srd/goblin.tres
```

The generic Actor implementation shouldn't know Goblins exist either.

This means, in principle, somebody could someday take:

```text
platform/
```

and build:

```text
Pathfinder rules
```

or:

```text
Mike's Stupidly Simple RPG Rules
```

on top of it.

Now, I **wouldn't design specifically for Pathfinder today**—that's exactly how we accidentally invent Godot again.

But if the separation falls naturally out of good 5e architecture, great.

### What I would change in your repo *right now*

Very little.

You currently have:

```text
data/
├── creatures/
└── items/

scenes/
├── actors/
├── ui/
└── world/

scripts/
├── actors/
├── rules/
├── ui/
└── world/
```

which is already heading in the right direction. ([GitHub][2])

I wouldn't perform a giant reorganization yet.

Instead, I'd make our **next architectural milestone**:

```text
scripts/
├── actors/
│   └── actor.gd
│
└── rules/
    ├── character_sheet.gd
    ├── ability_scores.gd
    └── dice.gd
```

Then create the smallest possible proof:

```text
Actor A
Mike
STR 16

Actor B
Goblin
AC 12
HP 5
```

Press/interact/trigger:

```text
Mike attacks Goblin.
```

Rules produce:

```text
d20 = 14
STR modifier = +3
total = 17
17 >= AC 12

HIT

damage = 4
Goblin HP: 5 → 1
```

No initiative.

No classes.

No spell slots.

No proficiency bonus even, if we don't need it yet.

Just prove this:

> **A generic Actor can use a CharacterSheet and a generic rules system to interact with another generic Actor.**

Once that works, we've built the first tiny piece of the thing that is actually **MikeRPG** rather than merely a Godot demo.

And from that point forward, every feature gets a simple question:

> **Is this Godot, an addon, the MikeRPG platform, 5e SRD data, or Mike World content?**

If we can answer that consistently, we'll avoid both extremes: a giant hardcoded game on one side and “we accidentally invented Godot 2” on the other.

[1]: https://github.com/stardustsuperwizard/mikerpg "GitHub - stardustsuperwizard/mikerpg: This is an RPG game that I am designing in Godot · GitHub"
[2]: https://github.com/stardustsuperwizard/mikerpg/tree/main/data "mikerpg/data at main · stardustsuperwizard/mikerpg · GitHub"
