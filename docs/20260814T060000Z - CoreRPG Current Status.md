# CoreRPG Current Status

# Prompt 1
Here is the current state of the game, https://github.com/stardustsuperwizard/mikerpg can tell take a look and tell me if this is close the mark?

# Response 1
Yes — **the project is close to the architectural mark, but not yet at the Core boundary we just defined.** The good news is that I would evolve what you have rather than restart anything.

Right now `core/` contains only `actors/` and `rules/`; Actions, World, and Authority are still missing as implemented Core concepts. ([github.com][1])

I’d rate the current state roughly like this:

| Core concept            | Current state            | Assessment                        |
| ----------------------- | ------------------------ | --------------------------------- |
| Actor                   | Implemented              | ✅ Good foundation, needs slimming |
| Controller              | Implemented              | ✅ Pattern is correct              |
| Rules                   | Implemented              | ✅ Very close to exactly right     |
| Action                  | Missing                  | 🔴 Highest priority               |
| World                   | Planned, not implemented | 🟡 Next priority                  |
| Authority               | Missing                  | 🟡 Add after Actions/World        |
| Networking              | Not Core                 | ✅ Correct                         |
| Persistence             | Not Core MVP             | ✅ Fine                            |
| Inventory/dialogue/etc. | Not Core                 | ✅ Correct                         |

Your README is also now expressing the architecture extremely well: Godot owns scenes, nodes, physics, rendering, input, navigation and networking; MikeRPG owns RPG concepts and should use existing addons wherever possible. ([GitHub][2])

### The Rules layer is the strongest part

This is basically the design we wanted:

```gdscript
var provider: RulesProvider = LiteRulesProvider.new()

func attack(attacker: Actor, target: Actor) -> void:
    provider.resolve_attack(attacker, target)
```

`RulesManager` delegates resolution to a replaceable provider rather than knowing D20/5e itself. ([GitHub][3])

That gives you exactly the future path:

```text
Rules
  │
  └── RulesProvider
         ├── LiteRulesProvider
         ├── D20RulesProvider
         └── 5eRulesProvider
```

**I wouldn't substantially rethink that.**

Eventually `attack()` might become a more general resolution mechanism because Actions will sit above it, but the dependency direction is correct.

---

### Controller is also conceptually right

Your base controller is wonderfully small:

```gdscript
class_name Controller
extends Node

@onready var actor: Actor = get_parent() as Actor

func get_move_direction() -> Vector3:
    return Vector3.ZERO

func get_attack_target() -> Actor:
    return null
```

and Player/AI derive from it. ([GitHub][4])

That proves your important abstraction:

```text
Actor doesn't care
WHO made the decision.
```

PlayerController can provide player decisions; AIController can provide AI decisions.

That's exactly right.

What has changed since you wrote it is that we now have a better idea of what the Controller should ultimately return.

Today:

```text
Controller
   ↓
get_move_direction()
get_attack_target()
```

Eventually:

```text
Controller
   ↓
Action
```

That's the next evolution, not a correction.

---

### Action is now the most important missing piece

Your current `Actor` asks its controller directly for movement and attack targets:

```gdscript
var move_direction := controller.get_move_direction()
...
var target := controller.get_attack_target()
if target:
    try_attack(target)
```

Then `Actor.try_attack()` calls:

```gdscript
Rules.attack(self, target)
```

([GitHub][5])

This was a perfectly good way to get the prototype working.

But it exposes exactly why we arrived at `Action`.

Right now the flow is:

```text
Controller
     ↓
Actor
     ↓
specific attack implementation
     ↓
Rules
```

I'd migrate toward:

```text
Controller
     ↓
Action
     ↓
ActionRunner
     ↓
Authority
     ↓
Rules / World
```

For example:

```text
PlayerController
      ↓
AttackAction(actor, target)

AIController
      ↓
AttackAction(actor, target)

GMController
      ↓
AttackAction(actor, target)
```

Now those three controllers don't need separate knowledge about how an attack happens.

And when multiplayer arrives:

```text
Remote player request
      ↓
AttackAction
```

Same object.

That's why I would make **Actions your next Core work**, even before finishing WorldManager.

---

### Actor is currently doing too much — but don't panic

Your `Actor` currently handles:

* character data
* movement
* gravity
* movement speed
* controller polling
* attack timing
* attack execution
* damage
* death
* mesh color/material

([GitHub][5])

For the current tiny playable game, that's completely reasonable.

For the Core architecture we're defining, however, I'd eventually make `Actor` substantially more boring.

In particular, this:

```gdscript
var material := StandardMaterial3D.new()
material.albedo_color = color
mesh.material_override = material
```

has nothing to do with being an RPG Actor. That's presentation/demo behavior. ([GitHub][5])

Likewise:

```gdscript
const SPEED = 5.0
```

and some of the CharacterBody movement implementation are arguably Godot movement concerns rather than the conceptual definition of an Actor.

I'm **not suggesting you refactor all of that immediately**.

Instead let Actions/World emerge first. You'll naturally see what can leave Actor.

Eventually I'd like Actor to feel closer to:

```text
Actor
├── identity
├── character sheet/data
├── controller
├── capabilities/components
└── lifecycle
```

rather than being the place every RPG behavior lives.

---

### There's one specific smell in PlayerController

Your PlayerController searches the scene tree for:

```gdscript
get_nodes_in_group("nonplayers")
```

and finds the closest actor within attack range. ([GitHub][6])

Again, entirely acceptable prototype code.

But architecturally it couples:

```text
PlayerController
      ↓
enemy classification
      ↓
scene tree query
      ↓
combat targeting
```

Eventually the Controller should be expressing:

> “The player requested an attack toward this target.”

It shouldn't necessarily decide that every `"nonplayers"` Actor is a valid enemy.

Why?

Because eventually you might have:

```text
NPC merchant        nonplayer, don't attack
friendly companion  nonplayer, probably don't attack
hostile goblin      nonplayer, attack
possessed goblin    nonplayer but controlled by GM
other player        player, but PvP may allow attack
```

That legality belongs closer to Rules/Actions/relationships than the input controller.

This isn't something I'd fix in isolation today. **Actions will naturally solve it.**

---

### WorldManager: your plan is still useful

You already have the World Manager plan documented, but there's no `core/world/` implementation yet. ([GitHub][7])

Given everything we've discussed since that document was written, I would make the first WorldManager **smaller than you might originally have intended**.

I'd give it only something like:

```text
World
├── register_actor()
├── unregister_actor()
├── get_actor()
├── spawn_actor()
└── current_area / world identity
```

Don't make it:

```text
WorldManager
├── terrain
├── weather
├── navigation
├── scene rendering
├── physics
├── networking
├── persistence
...
```

Godot already owns most of that.

The key purpose of MikeRPG World is:

> Give RPG systems a common concept of “the actors and RPG state that exist in this world.”

---

### Authority should come slightly later

Now that we've discussed LAN networking, this is clearer.

Don't implement ENet in Core.

Don't implement networking in Core.

Implement the concept:

```text
Actor A
is controlled by
Authority X
```

or:

```text
Can this authority request this Action for this Actor?
```

In single-player, the answer is trivial.

Later LAN:

```text
peer 82731
    ↓
authority context
    ↓
Actor 42
```

Later Nakama:

```text
Nakama user abc123
    ↓
authority context
    ↓
Actor 42
```

Core still doesn't know what ENet or Nakama is.

That's exactly what we want.

---

### I would make one additional organizational adjustment

Your controllers currently live under:

```text
core/actors/controllers/
```

([GitHub][8])

That's defensible, but given the conceptual architecture we've arrived at, I now slightly prefer:

```text
core/
├── actors/
├── controllers/
├── actions/
├── world/
├── rules/
└── authority/
```

because Controller isn't merely an implementation detail of Actor anymore.

It is one of the six fundamental Core concepts:

```text
Actor       WHO
Controller  WHO DECIDES
Action      WHAT THEY WANT
World       WHERE
Rules       WHAT HAPPENS
Authority   ARE THEY ALLOWED
```

I wouldn't call moving the folder urgent. It's mostly conceptual cleanliness.

---

### So, is it close?

**Yes. Very close conceptually, less close structurally.**

I'd describe where you are like this:

```text
                    CURRENT

                 ┌── Actor ──┐
                 │           │
            Controller      Rules
                 │           │
              Player      Provider
                AI           │
                           Lite
```

You've built **three of the most important relationships already**.

What we want to finish is:

```text
                       TARGET CORE

                        Actor
                          │
                     Controller
                          │
                        Action
                          │
                     Authority
                          │
                  ┌───────┴───────┐
                  ↓               ↓
                Rules           World
```

And importantly, you don't need another dozen Core systems after that.

### My next three development steps

I would do them in this exact order:

1. **Actions.** Create the smallest useful `Action`, `ActionResult`, and `ActionRunner`, and refactor the existing attack path to prove it works.

2. **World.** Implement a deliberately tiny actor registry/spawn/world identity abstraction based on your existing World Manager work.

3. **Authority.** Initially make it almost trivial—single-player always-authorized—then use that seam when you build the LAN dedicated-server prototype.

After those three, **I would declare the architectural Core MVP essentially complete and stop adding abstractions.**

Then the fun part starts:

```text
MikeRPG Distribution
├── Maaack Game Template
├── D20 systems
├── LAN ENet runtime
├── dedicated server
├── GM UI
└── actual campaign content
```

That's why I think the current repo is in a good place. The key isn't that you're missing huge amounts of code; you're missing **three small abstractions that connect the pieces you've already proven**. ([GitHub][2])

[1]: https://github.com/stardustsuperwizard/mikerpg/tree/main/core "mikerpg/core at main · stardustsuperwizard/mikerpg · GitHub"
[2]: https://github.com/stardustsuperwizard/mikerpg "GitHub - stardustsuperwizard/mikerpg: This is an RPG game that I am designing in Godot · GitHub"
[3]: https://github.com/stardustsuperwizard/mikerpg/blob/main/core/rules/rules_manager.gd "mikerpg/core/rules/rules_manager.gd at main · stardustsuperwizard/mikerpg · GitHub"
[4]: https://github.com/stardustsuperwizard/mikerpg/blob/main/core/actors/controllers/controller.gd "mikerpg/core/actors/controllers/controller.gd at main · stardustsuperwizard/mikerpg · GitHub"
[5]: https://github.com/stardustsuperwizard/mikerpg/blob/main/core/actors/actor.gd "mikerpg/core/actors/actor.gd at main · stardustsuperwizard/mikerpg · GitHub"
[6]: https://github.com/stardustsuperwizard/mikerpg/blob/main/core/actors/controllers/player_controller.gd "mikerpg/core/actors/controllers/player_controller.gd at main · stardustsuperwizard/mikerpg · GitHub"
[7]: https://github.com/stardustsuperwizard/mikerpg/tree/main/docs "mikerpg/docs at main · stardustsuperwizard/mikerpg · GitHub"
[8]: https://github.com/stardustsuperwizard/mikerpg/tree/main/core/actors "mikerpg/core/actors at main · stardustsuperwizard/mikerpg · GitHub"
