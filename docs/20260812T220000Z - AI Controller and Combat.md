# AI Controller and Combat

## Prompt 1
You are an experienced game developer with Godot game engine and are helping me with creating a game framework. Here is the state of the repo: https://github.com/stardustsuperwizard/mikerpg/tree/main

I want to talk about building an ai system for non-player characters.

## Response 1
Yes. And given where MikeRPG is now, I think NPC AI is one of the places where the distinction you’ve been making between **Godot engine concerns** and **MikeRPG RPG concerns** becomes especially useful.

Your README now says MikeRPG should provide the RPG layer—actors, creatures, rules, quests, GM functionality—while Godot remains responsible for things like navigation, physics, nodes, and networking. ([GitHub][1]) You also now have `core/actors`, `core/rules`, `data/creatures`, and `scenes/actors`, which is a pretty natural foundation for NPC behavior. ([GitHub][2])

I would **not** start by thinking “we need an AI framework.” I would start with:

> **An NPC needs a way to decide what action it wants to perform next.**

That sounds almost trivial, but it gives us a really clean architecture.

Conceptually:

```text
NPC
 │
 ├── Character / Actor data
 │
 ├── Perception
 │     └── What can I see/hear/know?
 │
 ├── Brain
 │     └── What do I want to do?
 │
 └── Actions
       ├── move
       ├── attack
       ├── talk
       ├── flee
       ├── patrol
       └── interact
```

The important part is that **the Brain should not move the NPC directly**.

Instead:

```text
Brain
  ↓
"I want to move toward Player"
  ↓
Actor / movement system
  ↓
Godot NavigationAgent3D
  ↓
CharacterBody3D
```

That respects the design principle you've established: MikeRPG decides *why* the goblin moves; Godot decides *how a 3D object navigates through the world*. ([GitHub][1])

### The first version can be ridiculously small

Imagine the goblin's brain basically doing this:

```gdscript
func think():
    if can_see_player():
        attack_player()
    else:
        idle()
```

Then very quickly:

```gdscript
func think():
    if health_is_low():
        flee()

    elif enemy_in_attack_range():
        attack(enemy)

    elif enemy_visible():
        move_toward(enemy)

    else:
        patrol()
```

That is already legitimate game AI.

And I would resist introducing behavior trees, GOAP, utility AI, machine learning, or LLMs yet.

Those are **ways to implement `think()`**. They shouldn't define the architecture.

That's important for MikeRPG because eventually you could have:

```text
SimpleBrain
BehaviorTreeBrain
UtilityBrain
ScriptedBrain
CompanionBrain
BossBrain
```

all driving the same NPC.

Something like:

```gdscript
class_name NPC
extends Actor

@export var brain: NPCBrain
```

and:

```gdscript
class_name NPCBrain
extends Resource

func decide(actor: NPC, world: WorldState) -> NPCAction:
    return NPCAction.new()
```

Now you've created an RPG abstraction rather than another engine.

And this is where I think it gets particularly interesting for your project.

### NPCs probably shouldn't contain their AI

You already want creature definitions to be data-driven. Your README explicitly raises the question of whether NPCs can be generic objects whose values come from a datastore rather than hardcoded characters. ([GitHub][1])

I would extend exactly that idea to behavior.

Instead of:

```text
Goblin.gd
Skeleton.gd
Guard.gd
Merchant.gd
Wolf.gd
```

you might eventually have:

```text
CreatureDefinition
    id = "goblin"
    hp = 7
    movement_speed = 4
    brain = "aggressive_melee"
```

while:

```text
CreatureDefinition
    id = "town_guard"
    hp = 20
    movement_speed = 4
    brain = "guard"
```

And:

```text
CreatureDefinition
    id = "villager"
    hp = 4
    brain = "civilian"
```

The reusable brains might behave something like:

```text
aggressive_melee
    see hostile
        → pursue
    target in range
        → attack
    low health
        → flee

guard
    assigned post
        → remain nearby
    hostile nearby
        → engage
    hostile flees
        → pursue up to leash distance
    no threat
        → return to post

civilian
    danger nearby
        → flee
    otherwise
        → wander
```

Now you're building something genuinely useful as a **framework**.

A campaign creator doesn't program a goblin. They create a creature and attach behavior.

And later you can expose that inside Godot's editor:

```text
Goblin
─────────────────────
Creature: goblin
Faction: goblins
Brain: AggressiveMelee

Aggression Range: 15m
Leash Range: 30m
Flee HP: 20%
Patrol: None
```

That feels *very* Neverwinter Nights.

There is one architectural distinction I would make right now, though, because I think it will save you a mess later:

**NPC** and **Creature** should probably not imply AI.

Consider:

```text
Actor
├── PlayerCharacter
└── NonPlayerCharacter
```

An NPC merely means:

> This actor is not currently controlled by a player.

Then control is a separate concept:

```text
Controller
├── PlayerController
├── AIController
└── GMController
```

That's extremely useful for your eventual GM mode.

Suppose you're running a game and click a goblin:

> **Possess Goblin**

You don't need to replace the goblin or change its class.

You just do:

```text
Before:

Goblin
  Controller → AIController
```

then:

```text
After:

Goblin
  Controller → GMController
```

and when you're done:

```text
Goblin
  Controller → AIController
```

That is almost exactly the kind of capability your NWN-style architecture is going to want.

So I think the emerging model is:

```text
                    Actor
                      │
              NonPlayerCharacter
                      │
               ┌──────┴──────┐
               │             │
          Character       Controller
             Data             │
                              │
                    ┌─────────┼─────────┐
                    │         │         │
                  AI       Player      GM
                    │
                  Brain
                    │
              ┌─────┼─────┐
              │     │     │
            Idle  Guard Aggressive
```

And underneath all of this:

```text
MikeRPG says:
    "Go to that location."

Godot says:
    NavigationAgent3D
    pathfinding
    collisions
    velocity
    animation
```

That's the dividing line I would protect.

For an MVP, I think we can make this even simpler. **One goblin, three states: Idle → Chase → Attack.** But implement it through a tiny `AIController`/`Brain` boundary rather than embedding it directly into `goblin.gd`.

That gives us an incredibly small first implementation while preserving the architecture you'll eventually need for guards, civilians, monsters, companions, scripted NPCs, and GM possession.

[1]: https://github.com/stardustsuperwizard/mikerpg/tree/main "GitHub - stardustsuperwizard/mikerpg: This is an RPG game that I am designing in Godot · GitHub"
[2]: https://github.com/stardustsuperwizard/mikerpg/tree/main/core "mikerpg/core at main · stardustsuperwizard/mikerpg · GitHub"

## Prompt 2
What is going to prevent the ai goblin from beating me mercilessly at this point? Based on the code I think combat is just me pushing the space bar. A computer can push the space bar much faster than me 

## Response 2
Exactly. If combat is currently “press Space to attack,” then a naive AI that simply calls `attack()` whenever possible will be superhuman because it has no human reaction time, hesitation, or input limitations.

The fix is not to make the AI artificially bad at pressing buttons. The fix is to make **combat itself enforce cadence**.

For example, the player and the goblin should both be subject to something like:

```gdscript
func try_attack():
    if not can_attack:
        return

    perform_attack()
    can_attack = false
    attack_cooldown.start()
```

So Space doesn't mean:

> Attack right now, as fast as the keyboard generates events.

It means:

> Attempt to attack.

The combat system decides whether the attack is currently legal.

That means your goblin AI can happily do:

```gdscript
if target_in_range:
    try_attack()
```

every frame if you want. Most of those attempts simply do nothing because the goblin is still in its attack recovery period.

This gives you a model like:

```text
Goblin sword attack

Wind-up:     0.4 sec
Hit:         0.1 sec
Recovery:    0.8 sec
--------------------
Total:       1.3 sec
```

The human might mash Space 10 times during that 1.3 seconds.

The computer might call `try_attack()` 78 times during that 1.3 seconds.

They both get **one attack**.

And that leads into something more important for MikeRPG: I wouldn't actually model this primarily as a generic “cooldown.” I would model it as an **action**.

Something like:

```text
Actor
  current_action:
      SwordAttack

SwordAttack
  duration
  windup
  impact_time
  recovery
```

Then the goblin can't simultaneously:

```text
attack
attack
attack
move
attack
drink potion
attack
```

because it's currently occupied performing `SwordAttack`.

That becomes useful everywhere:

```text
Attack
Cast Spell
Drink Potion
Open Door
Use Item
Pick Lock
Interact
```

Some actions might take 0 seconds. Some might take 6 seconds. Some can be interrupted. Some prevent movement. Some permit movement.

And now we've stumbled into a pretty important architectural idea for your RPG framework:

> **AI should choose actions. It should not control their execution timing.**

So the AI says:

```text
"I choose Attack(target=Mike)"
```

The combat/action system responds:

```text
"Okay. You're performing SwordAttack until 12.8 seconds."
```

The AI doesn't get another meaningful decision until appropriate.

You could then deliberately make different creatures *think* at different rates too. Maybe a stupid zombie evaluates its situation every second:

```text
think interval = 1.0
```

while a skilled assassin evaluates every 0.15 seconds:

```text
think interval = 0.15
```

But neither can violate the game's action rules.

That also lets you create difficulty without simply cheating. A better goblin doesn't attack 100 times per second. It might instead have better decision-making: it recognizes when to flee, switches targets intelligently, uses cover, waits for you to commit to an attack, or drinks a potion.

So I think your architecture starts looking like:

```text
AI Brain
   ↓
chooses
   ↓
Action
   ↓
Combat / Action System
   ↓
validates timing + rules
   ↓
Animation / movement
   ↓
Godot
```

And importantly, **your player goes through the exact same path**:

```text
Space Bar
   ↓
PlayerController
   ↓
Attack Action
   ↓
Combat / Action System
```

versus:

```text
AI Brain
   ↓
AIController
   ↓
Attack Action
   ↓
Combat / Action System
```

That's a very healthy architecture for MikeRPG. The player and goblin are not fundamentally different creatures. They just have different **controllers deciding which action to request**.

And later when you possess that goblin in GM mode, you swap the AI controller for your GM controller and the entire combat system continues to work unchanged.


## Prompt 3
I take it this is for “real time” combat? If we did this turn based it wouldn’t matter?

## Response 3
Yes. What I described is mostly a **real-time combat problem**.

In turn-based combat, the goblin cannot “press Space faster than you” because the rules themselves define when the goblin is allowed to act. The AI gets a turn, chooses from the legal actions, executes one, and then control advances.

For example:

```text
Player turn
  → Move
  → Attack
  → End Turn

Goblin turn
  → AI evaluates situation
  → Move toward player
  → Attack
  → End Turn

Player turn
  → ...
```

The AI could theoretically evaluate 10 million possibilities per second, but that doesn't give the goblin extra attacks. The combat system says, essentially:

```gdscript
if actor != current_turn_actor:
    reject_action()
```

So this is actually another reason to separate **AI decision-making** from **combat rules**.

The AI should say:

```text
"I would like to attack Mike."
```

Then the combat system decides:

```text
Is it Goblin's turn?        yes
Does Goblin have an action? yes
Is Mike in range?           yes
Is this attack legal?       yes

→ perform attack
→ consume action
```

If the goblin asks again:

```text
"I would like to attack Mike."
```

the combat system responds:

```text
No actions remaining.
```

### And this gets particularly nice with 5e

A 5e-style system already gives us the throttling mechanism:

```text
Goblin's Turn
────────────────
Movement:       30 ft
Action:         1
Bonus Action:   maybe
Reaction:       1/round
Free actions:   rules dependent
```

Your AI therefore isn't really controlling the goblin continuously.

It's solving a small problem once per turn:

> Given the current world state and the resources available to me this turn, what should I do?

Something like:

```gdscript
func take_turn():
    var target = choose_target()

    if can_attack(target):
        attack(target)
    elif can_reach(target):
        move_toward(target)
        if can_attack(target):
            attack(target)

    end_turn()
```

That's considerably easier to reason about than real-time AI.

And there's another interesting consequence for MikeRPG: **the AI architecture doesn't actually have to care whether combat is real-time or turn-based.**

You can potentially have:

```text
                 AI Brain
                    │
              chooses action
                    │
                    ▼
              Action Request
                    │
          ┌─────────┴─────────┐
          ▼                   ▼
   Turn-Based Runtime    Real-Time Runtime
          │                   │
   Action economy         cooldown/action
   initiative             timing/recovery
   movement budget        animation timing
```

The goblin's brain could still decide:

```text
Attack target
Move to location
Use potion
Cast spell
Flee
```

The **rules/runtime determine when those actions are legal**.

That matters for your framework because I would very much like MikeRPG to avoid baking:

> “NPC AI assumes real-time combat”

into `core/nonplayer`.

Instead, something like an `AIController` should ask the currently active rules system what actions are available.

For example:

```gdscript
var actions = actor.get_available_actions()

var decision = brain.choose_action(
    actor,
    actions,
    world_state
)

actor.request_action(decision)
```

In 5e combat:

```text
get_available_actions()

→ Attack
→ Dash
→ Disengage
→ Dodge
→ Help
→ Hide
→ Ready
→ Search
→ Use Object
→ creature abilities...
```

Outside combat:

```text
get_available_actions()

→ Walk
→ Talk
→ Patrol
→ Interact
→ Open Door
→ Use Object
...
```

So yes: **if we go turn-based, the “computer can mash the attack key infinitely fast” problem basically disappears.**

But the separation we were just discussing becomes *more* valuable, not less:

> **Controller decides what the actor wants to do. Rules determine what the actor is allowed to do.**

That feels like a very strong foundational rule for MikeRPG.


## Prompt 4
Well I am interested in turn based grid combat…however…I am also interested in real time combat rpg combat. How does a game like world of Warcraft or an action handle ai combat and pvp?

## Response 4
Yes—and WoW is a useful example because it sits between the two extremes we were discussing.

World of Warcraft combat is **real-time**, but it isn't “whoever can press the attack button fastest wins.” The game separates **continuous real time** from **discrete combat opportunities**.

A simplified model is:

```text
REAL TIME
────────────────────────────────────────────>

Movement       continuous
Targeting      continuous
Position       continuous
Facing         continuous

Auto attack    ─────swing─────X────swing─────X

Abilities      X────GCD────X────GCD────X

Spell          [--- cast time ---] X

Cooldown       X──────────────60 sec────────────X
```

Blizzard itself describes WoW PvP as substantially about trading offensive and defensive cooldowns; abilities have defined availability rather than becoming stronger because the player can spam their input faster. ([World of Warcraft][1])

That gives us a very useful model for MikeRPG.

### PvP: the server enforces the rules

Suppose you and I are fighting.

You mash:

```text
ATTACK
ATTACK
ATTACK
ATTACK
ATTACK
ATTACK
```

The authoritative combat system effectively sees:

```text
Mike uses Slash
    ↓
legal?
    ↓
yes
    ↓
execute Slash
    ↓
start 1.5 second GCD
```

Then:

```text
Mike uses Slash
    ↓
legal?
    ↓
NO — GCD
```

Your keyboard isn't the authority. **The combat system is.**

And there are several independent timing mechanisms: global cooldowns, ability-specific cooldowns, cast/channel times, weapon swing timing, resource costs, animation/ability constraints, etc.

That's how PvP remains sane despite one player having 30 ms latency, another having 100 ms, one clicking abilities, another using keyboard shortcuts, etc.

### NPC combat uses those same rules

Now put a goblin on the other side.

The goblin AI might think:

```text
Target: Mike

Distance: 2m
Health: 82%
Slash: available
Kick: available
Potion: unavailable

Decision → Slash
```

It requests Slash.

The same combat system processes it:

```text
Goblin → Slash → Combat System
                     ↓
                   legal?
                     ↓
                    yes
                     ↓
                   execute
```

The goblin's AI could theoretically execute `choose_action()` every frame. It doesn't matter.

If Slash has a 1.5-second GCD, the goblin gets the same restriction you do.

So:

```text
PLAYER                        NPC

Keyboard                      AI Brain
   ↓                              ↓
PlayerController              AIController
   ↓                              ↓
   └──────── Action Request ──────┘
                 ↓
          COMBAT SYSTEM
                 ↓
        Is action legal?
                 ↓
         Resolve action
```

**That symmetry is really valuable.**

### Where the NPC's "AI" actually comes in

WoW-style NPC behavior adds another concept: **aggro/threat**.

A monster isn't generally running some giant intelligence model asking, “Whom would a goblin realistically hate most?”

It has rules.

Conceptually:

```text
Goblin threat table

Mike       1,250
Alice        830
Bob        2,100
Charlie      400

             ↓

Target Bob
```

WoW's NPC targeting commonly uses threat to determine a mob's current target, with mechanics that can increase, reduce, transfer, or otherwise manipulate threat. ([Warcraft Wiki][2]) Blizzard has explicitly discussed threat as a gameplay mechanic designed to make combat more interesting rather than merely an implementation detail. ([World of Warcraft][3])

Then the AI becomes something more like:

```text
PERCEIVE
    ↓
Players nearby?

TARGET
    ↓
Who has aggro?

DECIDE
    ↓
What should I do?

ACT
    ↓
Request ability

COMBAT RULES
    ↓
Can I actually do it?
```

A dumb goblin could therefore be extremely simple:

```text
No target?
    ↓
Find hostile within 15m

Have target?
    ↓
Update threat

Target outside melee?
    ↓
Chase

Target in melee?
    ↓
Slash available? → Slash
    ↓
otherwise → wait

Target dead?
    ↓
Select next threat target

Nobody left?
    ↓
Return home
```

That's basically enough to produce recognizable MMO monster behavior.

### Action RPGs change the *actions*, not the principle

Now imagine something more Zelda/Dark-Souls-ish rather than WoW.

You don't necessarily have:

```text
target → select Fireball → GCD
```

Instead you have:

```text
Goblin sees Mike
      ↓
approach
      ↓
choose attack
      ↓
WINDUP
      ↓
swing
      ↓
ACTIVE HITBOX
      ↓
RECOVERY
```

The AI can't attack again because it's currently in:

```text
ATTACK_RECOVERY
```

That's the action-game equivalent of the cooldown/GCD concept.

And crucially, this creates **telegraphing**.

The goblin raises his axe:

```text
       🪓
       O
      /|\
      / \

   WINDUP
    0.6 sec
```

You see that and dodge.

Then:

```text
WINDUP → ATTACK → RECOVERY
 0.6s      .2s       .8s
```

The AI doesn't get to go:

> COMPUTER FAST! ATTACK ATTACK ATTACK ATTACK!

because the **game rules say what an axe attack actually is**.

### Which brings us back to MikeRPG

I think we're uncovering a distinction that could be fundamental to the framework:

**Combat Mode** and **Combat Rules** don't need to be the same thing.

You could eventually support:

```text
MikeRPG
│
├── Actors
├── Controllers
│   ├── Player
│   ├── AI
│   └── GM
│
├── Actions
│   ├── Move
│   ├── Attack
│   ├── Cast
│   ├── Use
│   └── Interact
│
└── Combat
    │
    ├── Turn Based
    │     initiative
    │     grid movement
    │     action economy
    │
    ├── MMO / Real Time
    │     cooldowns
    │     GCD
    │     threat
    │     cast times
    │
    └── Action
          windup
          hitboxes
          recovery
          dodge/parry
```

And **NPC AI doesn't have to be rewritten for all three**.

A goblin brain can fundamentally think:

> I see an enemy. I want to get close. I want to attack him.

The combat implementation determines what "get close" and "attack" mean.

In grid 5e:

```text
Move 5 squares
Attack action
End turn
```

In WoW-style:

```text
Path into melee range
Start autoattack
Use available abilities
Observe GCD/cooldowns
```

In action combat:

```text
Navigate toward target
Face target
Begin attack animation
Activate hitbox
Recover
```

That suggests something I like even more than our previous formulation:

> **The AI should not know how combat works. It should know what it wants to accomplish.**

The goblin brain says **“attack Mike.”** The currently installed combat/rules system determines what accomplishing that means.

If we can preserve *that* boundary, you could realistically have a MikeRPG campaign using tactical grid combat and another using WoW-like real-time combat without having to reinvent your entire NPC architecture.

[1]: https://worldofwarcraft.blizzard.com/en-us/news/21464978/opening-moves-balancing-the-cooldown-equation?utm_source=chatgpt.com "Opening Moves: Balancing the Cooldown Equation"
[2]: https://warcraft.wiki.gg/wiki/Target?utm_source=chatgpt.com "Target - Warcraft Wiki - Your wiki guide to the World of Warcraft"
[3]: https://worldofwarcraft.blizzard.com/en-us/news/3300854/dev-watercooler-threat-level-midnight?utm_source=chatgpt.com "Dev Watercooler -- Threat Level Midnight"

## Prompt 5
I like that plan. Let me ask this about global cooldowns and 5e rules. If I wanted to use 5e but make it real-time would the GCD replace initiative order? Would increasing initiative lower the GCD for a character or is that a universal constant?

## Reponse 5
Yes, but I would make one important distinction:

**If you convert 5e to real-time, you need to translate the *action economy*, not literally replace initiative with a GCD.**

In tabletop 5e, a round is 6 seconds. During that round, each creature gets its turn, and initiative determines the ordering of those turns. In real time, everybody is acting simultaneously, so initiative order stops making much sense.

The obvious translation is:

```text
5e TURN-BASED                 REAL-TIME 5e

6-second round        →       continuous time

Initiative order      →       initiative/reaction speed

Action                →       action cooldown

Bonus Action          →       separate bonus-action cooldown

Movement              →       continuous movement / speed

Reaction              →       reaction availability

Extra Attack          →       multiple attacks per attack action

Spell slots           →       unchanged

Concentration         →       unchanged

AC / attack rolls     →       unchanged

Damage dice           →       unchanged
```

And this is where I **wouldn't** use initiative to reduce the GCD.

### Keep the GCD mostly universal

Suppose the base GCD is:

```text
1.5 seconds
```

If initiative directly reduced it, Dexterity/initiative would accidentally become an enormous DPS stat.

Imagine:

```text
Fighter: 1.5s GCD
Rogue:   1.0s GCD
```

Over 30 seconds:

```text
Fighter → ~20 actions
Rogue   → ~30 actions
```

That's an enormous mechanical advantage that doesn't exist in 5e. A +5 initiative character doesn't get 50% more turns.

So I would keep something like:

```gdscript
GLOBAL_COOLDOWN = 1.5
```

as a **combat-system constant**, perhaps adjustable by the campaign/ruleset.

Then translate initiative into something else.

### Initiative becomes "readiness"

Here's a mechanic I think could work beautifully.

When combat starts:

```text
              COMBAT BEGINS
                    │
             initiative roll
                    │
       ┌────────────┼────────────┐
       │            │            │
     Rogue       Fighter       Ogre
     22            14            6
       │            │            │
     0.1s          0.6s         1.2s
       │            │            │
       ▼            ▼            ▼
   READY         READY         READY
```

Initiative determines **how quickly you become ready when combat begins**, rather than how frequently you can act forever.

That's much closer to what initiative represents in tabletop:

> Who reacts first when violence starts?

A high-Dex rogue gets his dagger out and acts almost immediately.

The lumbering ogre takes a moment.

But once combat is underway:

```text
Rogue    X──1.5──X──1.5──X──1.5──X

Fighter       X──1.5──X──1.5──X──1.5──X

Ogre                X──1.5──X──1.5──X──1.5──X
```

Everyone operates under the same basic action cadence.

That's surprisingly faithful to 5e.

### But I wouldn't make *everything* use one GCD

This is where it gets interesting.

I'd probably preserve the 5e action economy using **separate resource clocks**.

An actor might have:

```text
ACTION
ready every 1.5 seconds

BONUS ACTION
ready every 1.5 seconds

REACTION
ready every 1.5 seconds

MOVEMENT
continuous
```

But using one doesn't necessarily consume the others.

So a rogue could:

```text
Attack
   ↓
Cunning Action: Disengage
   ↓
run away
```

without waiting for another complete "turn."

Similarly, a wizard:

```text
Cast Fireball
     ↓
Action unavailable
     ↓

but...

Reaction available
     ↓
Counterspell!
```

Now you're beginning to reproduce 5e's action economy **without turns**.

### And Extra Attack becomes interesting

A level 5 fighter shouldn't suddenly get two complete actions.

5e says that when the fighter takes the Attack action, they can attack twice.

So:

```text
Attack Action
     │
     ├── swing
     │
     └── swing
     │
     ▼
Action cooldown
```

rather than:

```text
Attack
Fireball
Drink Potion
Dash
```

twice as frequently.

That preserves the semantic meaning of Extra Attack.

### Six seconds versus 1.5 seconds

There's one big design decision here.

You could say:

> "A 5e round is six seconds, therefore actions should have six-second cooldowns."

That would be mechanically faithful but probably feel **awful** as a real-time video game.

Press sword attack:

```text
WHACK!

...

...

...

still waiting...

...

WHACK!
```

😂

Instead I'd treat real-time combat as a **time-compressed representation** of 5e.

Perhaps:

```text
Tabletop 5e:

1 round = 6 seconds
1 action / round
```

becomes:

```text
MikeRPG Real-Time 5e:

1 action cycle ≈ 1.5 seconds
```

Everything measured in rounds gets translated accordingly.

For example:

```text
5e duration        Real-time duration

1 round            1.5 sec
2 rounds           3 sec
10 rounds          15 sec
1 minute           ~15 sec*
```

`*` Depending on how aggressively you want to compress time.

That becomes a deliberate **real-time rules adapter**, rather than pretending we're implementing tabletop timing exactly.

### This gives MikeRPG a fascinating rules architecture

You could actually keep the same underlying 5e content:

```text
rules/
    5e/
        abilities
        attacks
        spells
        conditions
        creatures
```

and have two different combat schedulers:

```text
5e rules
   │
   ├───────────────┐
   │               │
   ▼               ▼
Turn Scheduler   Real-Time Scheduler
   │               │
Initiative       GCD
Turns            readiness
Rounds           cooldowns
Actions          action timers
Bonus Actions    bonus timers
Reactions        reaction timers
```

Your goblin definition doesn't change:

```text
Goblin

Speed: 30 ft
AC: 15
HP: 7
STR: 8
DEX: 14

Actions:
    Scimitar
    Shortbow
```

Neither does its AI:

```text
Enemy far away?
    → Shortbow

Enemy close?
    → Scimitar

Low health?
    → Flee
```

What changes is **when the combat scheduler permits those actions to occur**.

And I think that's the architectural sweet spot for what you're building: MikeRPG shouldn't have to choose between "a 5e engine" and "a real-time RPG engine." The 5e rules define **what things mean**; the combat mode defines **how time advances through those rules**.

I'd actually call that abstraction something like a **Combat Clock** or **Action Scheduler**, rather than putting GCD logic directly into the 5e rules. That way `TurnBasedClock` and `RealTimeClock` can both run the same underlying ruleset.

## Prompt 6
Can summarize all the combat methods we have looked at so far?

## Response 6
Absolutely. We've essentially identified **three combat models**, plus a common architecture that could allow MikeRPG to support all three.

| Model                   | Time           | Main limiter            | Positioning   | Example       |
| ----------------------- | -------------- | ----------------------- | ------------- | ------------- |
| **Turn-based tactical** | Discrete turns | Action economy          | Grid          | D&D / BG3     |
| **Real-time MMO**       | Continuous     | GCDs/cooldowns          | Free movement | WoW           |
| **Real-time action**    | Continuous     | Animation/action states | Free movement | Zelda / Souls |

### 1. Turn-based tactical / grid combat

This is the closest translation of tabletop 5e.

```text
Combat begins
      ↓
Roll initiative
      ↓
Rogue
Fighter
Goblin
Wizard
      ↓
repeat rounds
```

On your turn, the 5e rules determine what resources you have:

```text
Movement
Action
Bonus Action
Reaction
```

The grid controls positioning and movement costs.

The AI has no speed advantage because it only gets to make decisions when the combat scheduler gives its actor a turn.

```text
Goblin's turn
     ↓
AI examines battlefield
     ↓
choose movement
     ↓
choose action
     ↓
possibly bonus action
     ↓
end turn
```

This is probably the **most straightforward way to implement actual 5e**.

### 2. WoW-style real-time combat

Everybody exists and moves simultaneously.

There is no conventional initiative order:

```text
──────────────────────────────→ time

Player   X────X────X────X
Goblin    X────X────X────X
Wizard      X────X────X
```

Instead, combat is regulated by things such as:

* Global cooldown (GCD)
* Ability-specific cooldowns
* Cast times
* Weapon swing timers
* Resources such as mana
* Interrupts
* Reactions/procs
* NPC threat/aggro

Pressing an attack button 100 times doesn't create 100 attacks.

The player requests:

```text
Attack
```

and the combat system determines:

```text
Is attack available?
Is target valid?
In range?
Enough resource?
GCD ready?
Ability cooldown ready?

YES → execute
NO  → reject
```

NPCs obey the same rules.

The difference is simply:

```text
Player:
keyboard → PlayerController → action request

NPC:
brain → AIController → action request
```

Both then enter the **same combat system**.

### 3. Action RPG combat

This is closer to Zelda, Souls-like combat, etc.

Instead of the GCD being the primary regulator, the **action itself consumes time**:

```text
        Sword Attack

WINDUP       ACTIVE       RECOVERY
████████     ███           █████████
 0.5s        0.2s           0.7s
```

During those states, the actor has restrictions.

For example:

```text
IDLE
 ↓
ATTACK_WINDUP
 ↓
ATTACK_ACTIVE
 ↓
ATTACK_RECOVERY
 ↓
IDLE
```

The AI can't simply attack infinitely because it's already performing an action.

This model also introduces mechanics such as:

```text
hitboxes
dodging
blocking
parrying
stamina
animation timing
attack telegraphs
iframes
combos
```

It's much more dependent upon physical positioning and player reflexes.

---

### Then we considered "real-time 5e"

This isn't really a fourth fundamental combat model. It's a **5e ruleset adapted to the MMO-style real-time scheduler**.

Instead of:

```text
ROUND
  ↓
initiative order
  ↓
Player turn
  ↓
Goblin turn
```

everyone operates continuously.

But we preserve 5e concepts:

```text
5e                         Real-Time Translation

Action              →      action availability
Bonus Action        →      separate availability
Reaction            →      reaction availability
Movement            →      continuous movement
Extra Attack        →      attacks within Attack action
Spell Slots         →      unchanged
AC                   →      unchanged
Attack Rolls         →      unchanged
Saving Throws        →      unchanged
Concentration        →      unchanged
```

We specifically **didn't** want initiative to make your GCD progressively shorter.

Otherwise Dexterity becomes an enormous attack-speed/DPS stat.

Instead, initiative could determine **initial readiness**.

```text
COMBAT STARTS

Rogue:   Initiative 22 → ready at 0.1s
Fighter: Initiative 14 → ready at 0.6s
Ogre:    Initiative  6 → ready at 1.2s

─────────────────────────────────────→

Rogue     X──────X──────X
Fighter      X──────X──────X
Ogre             X──────X──────X
```

After that initial advantage, everyone follows the normal combat cadence.

We also discussed **time compression**. Literal 5e gives roughly one action per six-second round, which may feel painfully slow in a video game. A real-time adapter could deliberately map a tabletop round to a shorter real-time action cycle, perhaps around 1–2 seconds, with durations converted consistently.

---

### The common architecture is the important discovery

The three systems look very different to the player:

```text
                  MikeRPG Combat
                        │
          ┌─────────────┼─────────────┐
          ▼             ▼             ▼
      Tactical         MMO          Action
     Turn-Based      Real-Time      Real-Time
          │             │             │
     Initiative        GCD        Action States
       Turns         Cooldowns      Windup
       Grid          Cast Times      Hitbox
    Action Econ.      Threat        Recovery
```

But **controllers shouldn't implement any of that**.

The controller merely expresses intent:

```text
PLAYER CONTROLLER
        │
        │ "Attack Goblin"
        ▼

              ACTION REQUEST

        ▲
        │ "Attack Mike"
        │
   AI CONTROLLER
```

Then the active combat system determines what that means.

In turn-based 5e:

> You have an Action available, the target is adjacent, and it's your turn. Attack permitted.

In real-time 5e/MMO:

> Your action/GCD is ready and the target is in range. Attack permitted.

In action combat:

> You're not currently committed to another action. Begin the sword-attack windup.

That gives us a powerful rule for the framework:

> **Controllers decide what actors want to do. Combat systems decide when and how they're allowed to do it.**

And AI sits entirely on the **controller side** of that boundary.

That means the same basic goblin brain could potentially work in all three:

```text
PERCEIVE
   ↓
Enemy detected
   ↓
DECIDE
   ↓
Too far away?
   → MOVE TOWARD

Close enough?
   → ATTACK

Low health?
   → FLEE
```

The goblin doesn't need to understand turns, GCDs, initiative, animation recovery, or hitboxes. It asks the game to `ATTACK(target)`, and the installed combat system/ruleset handles the rest.

For MikeRPG, I think that's the key architectural insight from this whole discussion—not choosing one of these combat styles yet, but **making the NPC/controller/action boundary clean enough that choosing a combat style doesn't require rebuilding the actor and AI systems.**

## Prompt 7
Okay, this is good, let’s talk about the AI system again. Does any of the new information about combat mechanics change anything with the ai models that were laid out previously?

## Response 7
Yes, but mostly in a good way: the combat discussion **validates** the AI architecture we laid out rather than forcing a redesign.

The biggest refinement is that the AI brain should be even more abstract than “choose an attack.” It should choose **intent/goals**, while the active combat system decides which concrete actions are currently legal.

So instead of:

```text
AI Brain
  → Slash
  → Move 3 squares
  → End Turn
```

I would prefer:

```text
AI Brain
  → engage target
  → close distance
  → defend self
  → escape
  → support ally
```

Then a combat-aware decision layer translates that intent into available actions.

For example, the same goblin intent:

```text
"Engage Mike in melee"
```

could become:

```text
Turn-based 5e:
  Move 4 squares
  Attack with Scimitar
  End Turn
```

or:

```text
WoW-style:
  Path toward Mike
  Start melee attack
  Use Slash when available
```

or:

```text
Action combat:
  Approach
  Face Mike
  Begin axe windup
```

That means I would now think of the AI as having roughly four layers:

```text
PERCEPTION
What do I know?
    ↓
GOAL / INTENT
What am I trying to accomplish?
    ↓
TACTICAL DECISION
What legal action best advances that goal?
    ↓
CONTROLLER
Request that action from the game
```

The combat system remains underneath that:

```text
                    AI
                     │
              "Attack Mike"
                     ▼
               AIController
                     │
              Action Request
                     ▼
        Active Combat System
        ├── Turn-based
        ├── MMO real-time
        └── Action real-time
```

That separation becomes especially valuable because the tactical information available to the AI differs by combat mode.

In turn-based grid combat, the AI may reason about:

```text
movement squares
threatened spaces
cover
remaining action
bonus action
reactions
initiative
```

In MMO-style combat:

```text
range
cooldowns
cast state
threat table
resources
buffs/debuffs
```

In action combat:

```text
distance
facing
attack windup
recovery
stamina
incoming telegraphs
```

So I would **not** put those concepts into the generic `NPCBrain`.

Instead, the combat system can expose a normalized view of what the actor can currently do:

```gdscript
var options = combat.get_available_actions(actor)
```

Maybe that returns conceptually:

```text
MOVE_TO(target)
ATTACK(target)
FLEE_FROM(target)
BLOCK
USE_ABILITY("fireball")
HELP(ally)
```

The brain chooses among those.

This also changes how I feel about the earlier `think()` loop. I previously described:

```gdscript
if health_is_low():
    flee()
elif enemy_in_attack_range():
    attack(enemy)
```

That's fine for a prototype, but architecturally I'd now write it more like:

```gdscript
func decide(context):
    if context.health_low:
        return Intent.FLEE

    if context.has_hostile_target:
        return Intent.ENGAGE

    return Intent.IDLE
```

Then the tactical layer figures out what `ENGAGE` means right now.

One other thing changes: **AI update frequency becomes less important than we originally thought.**

We talked about a zombie thinking every second versus an assassin thinking every 0.15 seconds. That can still be useful for performance and personality, but it shouldn't be the primary balance mechanism.

Combat rules provide the hard limits.

So:

```text
Zombie thinks:   every 1.0 sec
Assassin thinks: every 0.1 sec
```

doesn't mean the assassin gets ten times as many attacks. It just means the assassin can react to changing circumstances faster.

That's actually a nice difficulty lever:

```text
Low skill AI:
  slower reaction
  poorer target selection
  simple tactics

High skill AI:
  faster reaction
  better positioning
  better ability selection
  understands combinations
```

without ever cheating on combat rules.

And the **controller idea becomes even stronger**:

```text
Actor
  │
  └── Controller
       ├── PlayerController
       ├── AIController
       └── GMController
```

The controller shouldn't care whether the game is turn-based or real-time. It submits intentions/actions when permitted.

So I think the updated architecture is:

```text
                    NPC
                     │
              AI Controller
                     │
                 Brain
                     │
         ┌───────────┼───────────┐
         │           │           │
     Perception    Goals      Personality
         │           │           │
         └─────── World Context ─┘
                     │
               choose intent
                     │
                     ▼
              Tactical Adapter
                     │
        "What can I legally do?"
                     │
                     ▼
               Action Request
                     │
                     ▼
              Combat System
```

And eventually you could swap brains without changing any of the rest:

```text
PassiveBrain
AggressiveBrain
GuardBrain
AnimalBrain
CompanionBrain
BossBrain
```

while swapping combat systems independently:

```text
TurnBasedCombat
RealtimeGCDCombat
ActionCombat
```

So the combat discussion hasn't made the AI more complicated so much as clarified the boundary:

> **The AI decides purpose. The combat system supplies possibilities and enforces consequences.**

That's the version I'd build toward now.

## Prompt 8
Let's bring it back around to the current state of MikeRPG and the Core/MVP concept. What should the first version of the AI Controller and the Combat/Action Methodology look like?

## Reponse 8
Yes. Looking at the repo as it exists now, I would make the first version much smaller than the architecture we ultimately discussed.

Right now MikeRPG already has the correct seam: `Controller` exposes movement and attack-target intent, `PlayerController` and `AIController` are separate, and `RulesManager.attack()` delegates to a swappable `RulesProvider`. ([GitHub][1]) The README also explicitly says the current milestone is basically “there’s a goblin, attack it, HP decreases, goblin dies,” with simple rules first and 5e later. ([GitHub][2])

So for the MVP I would **not add brains, utility AI, behavior trees, action resources, initiative schedulers, GCD classes, or combat adapters yet.**

I would make exactly two small abstractions real.

### First: make `AIController` actually behave

Today it effectively only marks its actor as a nonplayer. ([GitHub][3])

For V1, give it exactly this behavior:

```text
AIController
    │
    ├── Find nearest player
    │
    ├── If too far away:
    │       move toward player
    │
    └── If close enough:
            request attack on player
```

Conceptually:

```gdscript
class_name AIController
extends Controller

@export var aggro_range := 10.0
@export var attack_range := 2.0

var target: Actor

func get_move_direction() -> Vector3:
    target = _find_target()

    if target == null:
        return Vector3.ZERO

    var distance := actor.global_position.distance_to(target.global_position)

    if distance <= attack_range:
        return Vector3.ZERO

    return actor.global_position.direction_to(target.global_position)


func get_attack_target() -> Actor:
    if target == null:
        return null

    if actor.global_position.distance_to(target.global_position) <= attack_range:
        return target

    return null
```

That's enough AI for the MVP.

No separate `Brain` yet.

Why? Because right now the important abstraction you're proving is:

```text
PlayerController
        │
        ├── move intent
        └── attack target

AIController
        │
        ├── move intent
        └── attack target

               ↓

             Actor
```

Your existing `Controller` API is already moving in exactly that direction: `get_move_direction()` and `get_attack_target()`. ([GitHub][1])

Once you need a second kind of AI—say a cowardly goblin versus an aggressive goblin—**that's when extracting a Brain becomes justified.**

### Second: add one universal action gate

This is where our combat discussion changes the immediate MVP a little.

Right now you have:

```gdscript
RulesManager.attack(attacker, target)
```

which delegates directly to:

```gdscript
provider.resolve_attack(attacker, target)
```

([GitHub][4])

I would keep that.

But I would put a tiny layer **before** it that answers:

> Is this actor currently allowed to perform an attack?

For the first version, that can literally just be a cooldown.

Something conceptually like:

```text
Controller
    ↓
requests attack

Actor / Action Gate
    ↓
can_attack?

NO → ignore

YES
 ↓
RulesManager.attack()
 ↓
LiteRulesProvider.resolve_attack()
```

Maybe the Actor owns:

```gdscript
var attack_cooldown := 1.0
var attack_timer := 0.0
```

and:

```gdscript
func try_attack(target: Actor) -> void:
    if attack_timer > 0.0:
        return

    RulesManager.attack(self, target)
    attack_timer = attack_cooldown
```

Then `_process(delta)` or `_physics_process(delta)` counts it down.

That solves the immediate AI problem:

```text
Human:
SPACE SPACE SPACE SPACE SPACE

AI:
ATTACK ATTACK ATTACK ATTACK ATTACK
```

both become:

```text
try_attack()
    ↓
1 attack per permitted interval
```

And importantly, **the cooldown is not part of the Lite rules provider.**

That's the distinction I'd preserve now.

Your existing rules layer answers:

> What happens when an attack resolves?

For example:

```text
roll damage
subtract HP
check death
```

The action methodology answers:

> When may this actor initiate another attack?

Those are different responsibilities.

### I would call it `ActionController` or `ActionState`, not "CombatClock" yet

For V1, even `ActionSystem` may be too ambitious.

You really only need:

```text
Actor
├── controller
├── HP / character data
└── action state
      └── attack_ready
```

Then the entire current game loop becomes:

```text
                         ACTOR
                           │
              ┌────────────┴────────────┐
              │                         │
        PlayerController           AIController
              │                         │
 keyboard produces intent       code produces intent
              │                         │
              └──────────┬──────────────┘
                         ▼
                     Actor
                         │
                   try_attack()
                         │
                ┌────────┴────────┐
                │                 │
             not ready           ready
                │                 │
             ignore              ▼
                           RulesManager
                                │
                                ▼
                         RulesProvider
                                │
                                ▼
                             damage
```

That is enough architecture for now.

And notice what we **haven't committed to**.

We haven't said:

```text
Combat is turn based.
Combat uses GCD.
Combat uses animation recovery.
Combat uses 5e initiative.
Combat uses a grid.
```

We've only established:

> **Actors request actions; something determines whether those actions may occur; rules resolve the consequences.**

That's the abstraction we need.

### Then later, the tiny action gate gets replaced

Your V1 might effectively mean:

```gdscript
func can_attack() -> bool:
    return attack_timer <= 0
```

A future real-time combat implementation might mean:

```gdscript
func can_attack() -> bool:
    return global_cooldown.ready \
        and weapon.ready \
        and not actor.is_casting
```

A future action-RPG implementation might mean:

```gdscript
func can_attack() -> bool:
    return action_state == IDLE
```

And turn-based 5e might mean:

```gdscript
func can_attack() -> bool:
    return combat.current_actor == actor \
        and actor.turn.action_available
```

But the caller stays:

```gdscript
actor.try_attack(target)
```

That's the important part.

### So I think your next milestone should literally be this

You already have `creature.tscn`, player/nonplayer data, controllers, and a Lite rules provider in the repo. ([GitHub][5])

The next playable behavior should be:

```text
Launch test room

Player can move.

Goblin stands still.

Player enters 10m range.

Goblin moves toward player.

Goblin reaches 2m range.

Goblin requests attack.

Action gate permits one attack.

LiteRules resolves damage.

Goblin waits for attack readiness.

Goblin attacks again.

Player can attack goblin through exactly the same gate.

One of them reaches 0 HP and dies.
```

That's it.

No factions yet—just “goblin targets player.”
No threat table.
No patrol.
No fleeing.
No behavior tree.
No real perception system.
No 5e initiative.
No formal GCD framework.

But architecturally you've proven four foundational concepts:

```text
Controller → intent

Actor → action request

Action methodology → permission/timing

Rules provider → outcome
```

And I think **those four boundaries are Core-worthy**.

Everything we discussed later—behavior trees, tactical AI, turn schedulers, WoW-style GCDs, real-time 5e, action combat—can grow behind those seams without us inventing them before the game needs them.

[1]: https://github.com/stardustsuperwizard/mikerpg/blob/main/core/actors/controllers/controller.gd "mikerpg/core/actors/controllers/controller.gd at main · stardustsuperwizard/mikerpg · GitHub"
[2]: https://github.com/stardustsuperwizard/mikerpg/tree/main "GitHub - stardustsuperwizard/mikerpg: This is an RPG game that I am designing in Godot · GitHub"
[3]: https://github.com/stardustsuperwizard/mikerpg/blob/main/core/actors/controllers/ai_controller.gd "mikerpg/core/actors/controllers/ai_controller.gd at main · stardustsuperwizard/mikerpg · GitHub"
[4]: https://github.com/stardustsuperwizard/mikerpg/blob/main/core/rules/rules_manager.gd "mikerpg/core/rules/rules_manager.gd at main · stardustsuperwizard/mikerpg · GitHub"
[5]: https://github.com/stardustsuperwizard/mikerpg/tree/main/scenes/actors "mikerpg/scenes/actors at main · stardustsuperwizard/mikerpg · GitHub"
