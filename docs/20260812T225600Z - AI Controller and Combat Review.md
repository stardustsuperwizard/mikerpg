# AI Controller and Combat Review

## Prompt 1
Go ahead and review the repo again, I had Claude assist me with enabling ai and combat. Did it get close to the mark you laid out?

## Response 1.1
Yes. Claude got **very close to the mark**, and in a couple places it implemented almost exactly the MVP boundary we just discussed.

The strongest part is the overall flow:

```text
Controller
   ↓
movement / attack intent
   ↓
Actor
   ↓
action timing gate
   ↓
RulesManager
   ↓
RulesProvider
   ↓
damage / death
```

That is essentially the architecture we wanted. 

The `AIController` is especially on target. It has an aggro range, an attack range, finds the nearest player, moves toward them when outside attack range, stops when close enough, and returns the player as an attack target. That is exactly the intentionally dumb V1 AI I would have recommended. 

Likewise, `PlayerController` and `AIController` now share the same interface:

```gdscript
get_move_direction()
get_attack_target()
```

The player implementation gets its intent from keyboard input and searches for a nearby nonplayer when an attack is requested; the AI implementation manufactures the same intent from its simple targeting logic. 

That is a really good seam.

### The combat gate also landed where I wanted it

This part of `Actor` is the key:

```gdscript
var _attack_timer := 0.0
```

and:

```gdscript
func try_attack(target: Actor) -> void:
    if _attack_timer > 0.0:
        return

    Rules.attack(self, target)
    _attack_timer = attack_cooldown
```

The actor polls its controller for an attack target and then goes through `try_attack()` rather than letting the controller invoke the rules directly. 

That's important.

Claude did **not** do this:

```text
AIController
   ↓
Rules.attack()
```

which would have tightly coupled AI to combat resolution.

Instead it does:

```text
AIController
   ↓
"I want to attack this target."
   ↓
Actor.try_attack()
```

That's what we wanted.

And because `PlayerController` returns its target through the same API, both player and AI go through the identical cooldown. 

So your original concern—

> “Won't the computer just attack way faster than me?”

—is now solved by the architecture itself.

The AI can effectively ask to attack every physics frame. `Actor` will only allow one attack per `attack_cooldown`, currently exported with a default of one second. 

### Rules are still nicely separated

`RulesManager` remains almost comically small:

```gdscript
func attack(attacker: Actor, target: Actor) -> void:
    provider.resolve_attack(attacker, target)
```



And `RulesProvider` defines the contract:

```gdscript
func resolve_attack(_attacker: Actor, _defender: Actor) -> void:
```



Then `LiteRulesProvider` handles actual RPG resolution: Strength modifier, d20 attack roll against AC, d6 damage, and applying that damage to the target. 

That's a healthy separation:

```text
WHEN may I attack?
    Actor

WHO do I want to attack?
    Controller

WHAT happens when I attack?
    RulesProvider
```

That's probably the cleanest description of the current implementation.

### There is one distinction I'd keep an eye on

The only place I would say “this is fine for MVP, but don't let it grow indefinitely” is `Actor`.

It's currently doing quite a lot:

```text
Actor
├── character sheet initialization
├── visual material setup
├── gravity
├── movement
├── controller polling
├── attack timing
├── attack dispatch
├── damage handling
└── death
```



At **57 lines**, this is absolutely not a problem yet.

In fact, I would resist refactoring it right now.

But this is probably where our future `ActionSystem`/`ActionState` abstraction will eventually emerge.

Today:

```text
Actor
    _attack_timer
```

Tomorrow you might add:

```text
_attack_timer
_spell_timer
_item_timer
_dodge_timer
_interaction_timer
```

and then:

```text
is_casting
is_stunned
is_attacking
is_recovering
is_dead
```

That's the moment where we'd say:

> Okay, `Actor` is starting to contain an action scheduler. Let's extract it.

But **not yet**.

For the current MVP, `_attack_timer` inside Actor is actually the implementation I wanted.

### One small AI issue

There's a subtle behavior in `AIController` worth being aware of.

Every time `get_move_direction()` runs, it does:

```gdscript
target = _find_target()
```



So the NPC isn't really *remembering* an aggro target. It's continually selecting whichever player is nearest within `aggro_range`.

For single-player, that's irrelevant.

With multiplayer later, you could get behavior like:

```text
Goblin attacking Mike

Alice moves 10 cm closer than Mike

Goblin:
"ALICE!"
```

Then Bob gets closer:

```text
Goblin:
"BOB!"
```

😂

Eventually we'd probably distinguish:

```text
acquire_target()
```

from:

```text
maintain_target()
```

and later possibly introduce threat.

But again: **don't solve that yet.** For the single-player MVP, nearest player is exactly the right implementation.

### I also like that you didn't introduce a Brain

There is currently no separate:

```text
AIController
    └── Brain
```

and I think that's correct.

Right now `AIController` itself contains:

```text
See player
Move toward player
Attack player
```



That's about 40 lines of code.

A separate `Brain`, `PerceptionSystem`, `Goal`, `Blackboard`, and `BehaviorTree` would currently just distribute those 40 lines across five abstractions.

The trigger for extracting a Brain should be when you want something like:

```text
Goblin
    aggressive

Villager
    passive/flee

Guard
    protect area

Wolf
    pack behavior
```

At that point:

```text
AIController
      ↓
Brain
```

becomes useful because the controller remains responsible for driving an AI-controlled actor while the brain becomes swappable decision policy.

You're not there yet.

### There is one architectural question I'd revisit later

Your current controllers expose:

```gdscript
get_attack_target() -> Actor
```



For the MVP that's excellent.

Eventually, though, this likely becomes too attack-specific.

When you add:

```text
Cast spell
Drink potion
Open door
Use object
Talk
Dodge
Block
Shove
Dash
```

the controller interface could otherwise turn into:

```gdscript
get_attack_target()
get_spell_target()
get_item_request()
get_dodge_request()
get_interaction_target()
get_shove_target()
...
```

That's probably when we graduate toward the thing we were calling an **Action Request**:

```gdscript
controller.get_action()
```

returning conceptually:

```text
ActionRequest
    type = ATTACK
    target = goblin
```

or:

```text
ActionRequest
    type = CAST
    ability = fireball
    target = goblin
```

But again, I would **not make that change now**.

`get_attack_target()` is simple, readable, and directly supports the milestone you're building.

### So if I grade it against our four MVP boundaries

I would call it:

| Boundary                       | Current implementation                              | Verdict           |
| ------------------------------ | --------------------------------------------------- | ----------------- |
| **Controller → intent**        | `get_move_direction()`, `get_attack_target()`       | ✅ Exactly right   |
| **Actor → action request**     | `try_attack(target)`                                | ✅ Exactly right   |
| **Action timing → permission** | `_attack_timer`, `attack_cooldown`                  | ✅ Right-sized MVP |
| **Rules → outcome**            | `Rules.attack()` → `RulesProvider.resolve_attack()` | ✅ Very clean      |
| **AI sophistication**          | nearest player / approach / attack                  | ✅ Appropriate     |
| **Brain abstraction**          | not added                                           | ✅ Good restraint  |
| **Generic action system**      | not added yet                                       | ✅ Good restraint  |

So yes: **Claude essentially implemented the MVP architecture we laid out.**

More importantly, it did so without getting ahead of you.

You now have a nice little vertical slice:

```text
Player presses Space
       │
       ▼
PlayerController
       │
       ▼
get_attack_target()
       │
       ▼
Actor.try_attack()
       │
       ▼
cooldown gate
       │
       ▼
Rules.attack()
       │
       ▼
LiteRulesProvider
       │
       ▼
hit / miss / damage


AI sees player
       │
       ▼
AIController
       │
       ▼
get_attack_target()
       │
       ▼
Actor.try_attack()
       │
       ▼
SAME EVERYTHING
```

That **“SAME EVERYTHING” below the controller** is the part I like most.

I would actually stop architecting combat for a moment and play with this. The next useful AI feature shouldn't be another abstraction. It should probably be one visible behavior—such as **the goblin gives up and returns home if you run outside its aggro area**. That would force us to introduce the first tiny bit of NPC state (`idle/chasing`) and tell us whether the next AI abstraction is actually necessary.

## Prompt 1.2
Okay, how about this, we have our cake and eat it too. Add the code you think is appropriate to give us this functionality. Please also update this document with information about what you did, why, and what the next steps would be in the future.

## Response 1.2
Implemented the leash/return-home behavior directly inside `AIController` — no new class, no `Brain`, no state machine abstraction. Just enough state to answer "was I chasing something, and where do I belong."

### What changed

`AIController` gained:

```gdscript
const HOME_ARRIVAL_DISTANCE = 0.2

var home_position: Vector3
var _returning_home := false
```

`home_position` is captured once in `_ready()`, from wherever the goblin was placed in the scene — so it's automatically correct per-instance without any scene author having to set it explicitly.

Target acquisition and loss moved into a new `_update_target()`, called at the top of `get_move_direction()` instead of the old unconditional `target = _find_target()`:

```gdscript
func _update_target() -> void:
	if target:
		if actor.global_position.distance_to(target.global_position) > aggro_range:
			target = null
			_returning_home = true
		return

	var found := _find_target()
	if found:
		target = found
		_returning_home = false
```

The key behavior change: once a target is acquired, it's *kept* until it either dies (goes away on its own — `queue_free()` in `Actor.die()` naturally clears the reference on next distance check... actually, more precisely, once it leaves `aggro_range`) rather than being re-selected from scratch every single frame. That's a small but real shift from "purely reactive, no memory" to "remembers what it's doing." Losing the target for being out of range is also what flips `_returning_home` on.

`get_move_direction()` then has a third branch, below "chase target" and "idle with nothing to do":

```gdscript
if _returning_home:
	var home_distance := actor.global_position.distance_to(home_position)
	if home_distance <= HOME_ARRIVAL_DISTANCE:
		_returning_home = false
		return Vector3.ZERO
	return actor.global_position.direction_to(home_position)
```

`get_attack_target()` is untouched — it still just checks the current `target` against `attack_range`, which naturally returns `null` while returning home since `target` is `null` at that point.

Re-acquisition during the walk home is intentional and falls out of `_update_target()` for free: if a player wanders back inside `aggro_range` while the goblin is still walking home, `_find_target()` picks it back up and `_returning_home` clears — the goblin re-engages instead of stubbornly walking home past an enemy standing right next to it.

### Why this shape and not something bigger

The review above specifically flagged this as a *diagnostic* feature, not a foundational one — the point was to find out whether the current stateless-per-frame `AIController` could absorb "remember something across frames" without needing a real state machine or `Brain` extraction. It could: the whole change is ~20 lines, entirely inside the one file, and reads as three plain branches (chasing / returning / idle) rather than a formal state enum with transition logic. That's the signal that a `Brain`/state-machine abstraction is still not justified.

### How it was verified

Rather than trust this by inspection, I built a throwaway test scene (`tools/tmp_test_leash.gd` / `.tscn`, deleted after the run — not part of the commit) that placed a goblin and a stationary "player" `Actor` a few meters apart, let the goblin chase and land a couple of attacks, then teleported the player 50m away mid-run and kept simulating. Headless output confirmed the full cycle:

```text
HOME=(0.0, 0.05, 0.0)
Goblin misses Mike ...
Goblin misses Mike ...
AFTER_APPROACH goblin_pos=(1.083328, 0.000216, 0.0) target=Player:<...>
JUST_AFTER_TELEPORT target=<null> returning_home=true
AFTER_RETURN goblin_pos=(0.1713, 0.000216, 0.0) home=(0.0, 0.05, 0.0) returning_home=false
```

Target dropped and `_returning_home` flipped true the instant the player left `aggro_range`; the goblin then walked back and settled within `HOME_ARRIVAL_DISTANCE` of its actual spawn point, and the flag cleared on arrival.

### Next steps

- **The target-flicker issue from the review is still open.** `_update_target()` still only compares the *current* target against `aggro_range` to decide whether to drop it — it doesn't re-scan for a *closer* player once a target is already locked, so single-target flicker between simultaneous players (the "ALICE!... BOB!" scenario) is actually fixed as a side effect of this change for the common case, but a proper threat/aggro table is still the real fix once multiplayer and multiple simultaneous attackers exist.
- **Idle-at-home vs idle-were-you-stopped isn't distinguished.** Right now "no target, not returning home" just means "stand still wherever you are," which is correct for goblins that got interrupted mid－patrol as much as for ones that never had a target. A future patrol/wander behavior would want to know the difference.
- **This is very likely close to the ceiling for what belongs directly in `AIController`.** The next behavior request that isn't just "add one more bool and one more branch" — e.g. a cowardly goblin, a guard with a post, pack behavior — is the actual trigger point for extracting a `Brain`, per the original architecture doc. This change was deliberately kept small enough to not be that trigger.