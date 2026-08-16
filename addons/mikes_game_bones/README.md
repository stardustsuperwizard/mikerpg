# Mike's Game Bones

A reusable, genre-agnostic gameplay framework for Godot 4 — the semantic layer between Godot's engine primitives (nodes, physics, rendering) and a specific game's rules and presentation.

## What's in it

```
actions/         Action, ActionResult, ActionRunner (the request -> legality -> resolve pipeline)
  verbs/          concrete actions: AttackAction, OpenAction
actors/          Actor (a presentation-neutral Node)
  bodies/          presentation shells: ActorBody3D, ActorBody2D
authority/       Authority (can this requester act as this actor?)
controllers/     Controller, PlayerController, AIController (decision-making, not execution)
things/          GameObject, ObjectDefinition (traits/capabilities/state -- the "noun" layer)
  props/           concrete non-actor things: Door
world/           WorldManager, SpawnPoint
```

## What it deliberately does not include

Combat resolution, ability scores, dice, character sheets, dialogue, inventory, or any UI. Those are game-specific — see `mikerpg`'s `game1_demo/` or `game2_misadventures/` for examples of a game built on top of this addon, each bringing its own rules engine.

## Design philosophy

`GameObject`s represent what exists. `Action`s represent what is attempted. `Rules` (defined by the consuming game, not this addon) determine what happens. Godot represents the result. See `docs/20260815T130000 - Game Objects and Rules.md` in the main `mikerpg` repo for the full design rationale.
