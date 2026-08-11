# Player vs NonPlayer, and the Controller Pattern

This is a log of the conversation (with Claude Code, working directly in the repo) that led to retiring `Player` and `Creature` as separate classes in favor of a single `Actor` driven by a swappable `Controller`.

This was the ultimate conclusion:
> **Don't split Actors by class (`Player` vs `NonPlayer`). Split them by who's driving.**
> **Actor = what exists in the world. Controller = who's deciding what it does.**

## Prompt 1
I actually want to step back and make a direction change from the docs a bit. We have player and creature and I don't like that. I think that a cleaner idea is "player" and "nonplayer" do you agree?

### Response 1
Partial agreement — `NonPlayer` is a better umbrella than `Creature`. `Creature` reads as monster-specific (wolves, goblins), but it doesn't naturally cover an NPC like a shopkeeper or quest-giver, which the project clearly wants too. Player/NonPlayer cleanly covers "is this the thing the human is driving or not," which `Creature` never quite did.

But there's a sharper alternative already implicit in the project's own docs (`actors_charactersheets.md`, `game_philosphy.md`): don't make Player/NonPlayer a class split at all — make it a **Controller** attached to a generic `Actor` (`PlayerController` vs `AIController` vs `GMController`), with `Creature`/`NonPlayer` surviving only as an SRD/data category, not a code class. That's what actually delivers the GM-possession goal already written down: the goblin doesn't change type when the GM takes it over, its controller just swaps. Baking "NonPlayer" into the class hierarchy would have re-created almost the same rigidity `Creature` had, just relabeled.

Offered the choice: a straight rename (`Creature` → `NonPlayer`, still two classes on `Actor`), or build the `Controller` split now so "who's driving" stops being baked into the class at all.

## Prompt 2
I like your approach. please go ahead with the controller plan.

### Response 2 — what was actually built

`Actor` (`scripts/actors/actor.gd`) is now the *only* actor script. It owns:
- the physical body (`CharacterBody3D`, mesh, gravity, `move_and_slide`)
- its `CharacterSheet` (rules data — HP, AC, ability scores)
- calling `Combat.attack()` when its controller says to

It has no idea whether it's being played by a human, an AI, or (eventually) a GM. Each physics frame it just asks its `Controller` child two questions:

```gdscript
controller.get_move_direction() -> Vector3
controller.get_attack_target() -> Actor
```

`Controller` (`scripts/actors/controllers/controller.gd`) is the base class, defaulting both to no-op (stand still, don't attack).

```text
Actor (CharacterBody3D)
├── CharacterSheet
├── MeshInstance3D / CollisionShape3D
└── Controller
     ├── PlayerController   → reads WASD + attack key
     ├── AIController        → currently a stub (goblin still just stands there)
     └── GMController         → not built yet — this is the payoff
```

`player.tscn` and `creature.tscn` are now the *same script* (`actor.gd`), differing only by which controller node they carry. Group membership (`"player"`, `"creatures"`) moved from being hardcoded in the class to being registered by whichever controller is attached — so it now reflects "how is this being controlled," not "what class is this."

This directly matches the possession model from `actors_charactersheets.md`:

```text
Goblin controlled by AI:
Actor
├── CharacterSheet → Goblin
└── AIController

Goblin possessed by GM (future):
Actor
├── CharacterSheet → Goblin
└── GMController
```

Nothing about the goblin's stats, mesh, or scene changes when that swap happens — only the controller.

**Verification**: rather than trust the refactor by inspection, ran it through the actual Godot 4.7 binary headless — a scripted scene instantiated a real `player.tscn` and `creature.tscn`, confirmed `PlayerController`/`AIController` correctly self-registered their groups, then drove attacks through the real input-flag → physics → `Combat.attack()` path and got the expected miss/hit/damage sequence with independent per-instance HP. Zero script or runtime errors.

**What's intentionally not done yet**: `AIController` only registers the `"creatures"` group — it still returns the base class's no-op movement/attack, so the goblin doesn't move or fight back. That's the next natural step now that it's isolated to one file. `GMController` (possession) doesn't exist yet either.
