# mikerpg
This is an RPG game that I am designing in Godot it is an experiment to build out a game that I can play at home with friends. 

The goals are as follows:
1. Build a single player game to start
2. Add a multiplayer option with an admin (or Dm/GM) client, like Neverwinter Nights.
3. Use as much of the godot editor as possible as the toolset for making stories.
4. Use components that already exist in the wild, example Inventory systems, and only code new when there is not a sufficient 3rd party addon or it no longer meets my needs.
5. Make the game as modular as possible and not have to hardcode as much as possible. Example, do I need to hardcode all NPCs or can I make a generic NPC class/object/whatever where the values are populated from a datastore?

## Setup

Requires Godot 4.7+.

`addons/` is gitignored (third-party code, not part of the core game). After cloning, fetch each addon before opening the project in Godot:

**GLoot** (inventory system, v3.0.2, MIT license — https://github.com/peter-kish/gloot):
```
git clone --depth 1 https://github.com/peter-kish/gloot.git /tmp/gloot
cp -R /tmp/gloot/addons/gloot addons/gloot
cp /tmp/gloot/LICENSE addons/gloot/LICENSE
rm -rf /tmp/gloot
```

Nothing else to configure — the plugin is already enabled in `project.godot`, Godot just needs the files present on disk. If the project opens with inventory-related script errors, this step was skipped.

## Prompt
```
You are an experienced Godot programmer and engineer helping me with learning Godot. I have discussed at length with other ideas and concepts and now want to focus in on something. I want to build a basic single player or multi player role playing game, ultimately based on 5e SRD rules. I want start as simple as possible and 5e rules can be substituted for something simplistic to start with and then be layered in or swapped in over the simple rules. We can start at the beginning tutorial style to build a basic game and add on as we go. The biggest thing is that I also want to add game elements that already exist, for example inventory. If I don’t have to build it, then I don’t want to. Can that be done?
```

## Response

Yes. In fact, that is exactly how I would approach this.

Rather than “build an RPG in Godot,” I’d frame the project as **assemble a small RPG from reusable systems, and only write the glue and game-specific logic ourselves**. Godot is particularly friendly to this because scenes, nodes, resources, signals, and addons all encourage composition.

For example, we absolutely do **not** need to start by writing an inventory system. There are mature Godot 4 inventory addons already. One current option is Expressobits’ Inventory System, which separates inventory logic from UI, represents items as resources, and explicitly supports multiplayer. ([Godot Engine][1]) There are also alternatives such as Wyvernbox and newer modular inventory addons. ([Godot Engine][2]) Godot’s Asset Library currently contains thousands of community assets, so this “buy/borrow before build” approach can go quite far. ([Godot Engine][3])

The same applies elsewhere. For dialogue, for example, Nathan Hoad’s Dialogue Manager is a well-established Godot 4 addon with branching dialogue, its own editor/runtime, localization support, and GDScript/C# integration. ([Godot Asset Store][4]) Networking does not necessarily mean building a socket protocol either; Godot itself has a high-level multiplayer API, and there are third-party multiplayer/backend systems if we eventually want them. ([Godot Engine documentation][5])

So I think our learning project should deliberately look something like this:

1. **Build:** a tiny room and a player who can move.
2. **Build:** one NPC or monster.
3. **Build:** an extremely simple rule system: `HP = 10`, `attack = random 1–6`, monster dies at 0.
4. **Integrate:** an existing inventory addon instead of writing inventory.
5. **Build:** item pickup as the glue between our world and the inventory addon.
6. **Integrate:** an existing dialogue system.
7. **Build:** a tiny quest using dialogue + inventory + combat: “Kill the rat and bring me its tail.”
8. **Refactor:** separate the simplistic rules from the game so we can begin replacing them with 5e SRD concepts.
9. **Later:** multiplayer.
10. **Much later:** GM mode, full 5e rules, campaign tools, etc.

The important architectural decision happens surprisingly early: **the game should not know that its rules are 5e.**

For instance, I don't want our player code eventually becoming something like:

```gdscript
func attack():
    var proficiency_bonus = 2
    var strength_modifier = 3
    var roll = randi_range(1, 20)
    ...
```

Instead, conceptually, I'd like:

```gdscript
combat.attack(player, goblin)
```

At first, `combat.attack()` might contain ridiculously simple rules:

```text
roll 1–6
subtract that much HP
```

Later we can replace the implementation with:

```text
d20
+ ability modifier
+ proficiency if appropriate
compare against AC
roll weapon damage
apply modifier
```

The **game surrounding it doesn't have to change**.

That same philosophy will help enormously with third-party addons. We don't want our entire game tightly coupled to `SomeInventoryPlugin`. We might have our own tiny interface that conceptually says:

```gdscript
player.inventory.add_item(item)
player.inventory.remove_item(item)
player.inventory.has_item(item)
```

Behind that interface can be somebody else's inventory addon. If someday we dislike it, we swap the implementation rather than rebuilding the entire RPG.

### What I would actually have you build first

I'd go even smaller than “RPG.”

Our **Lesson 1 game** should be:

> There is a room.
> There is a player.
> You can walk around.

That's it.

But we'll build it in a way that becomes the foundation rather than a disposable tutorial. Something like:

```text
MikeRPG/
│
├── scenes/
│   ├── world/
│   │   └── test_room.tscn
│   ├── actors/
│   │   └── player.tscn
│   └── ui/
│
├── scripts/
│   ├── actors/
│   ├── rules/
│   └── systems/
│
├── data/
│   ├── items/
│   ├── creatures/
│   └── quests/
│
└── addons/
	└── [other people's excellent work]
```

Notice that last directory. **`addons/` is going to become one of our favorite directories.**

And there's another benefit to starting this way: you aren't merely learning “how to code an RPG.” You're learning **how Godot wants games assembled**—scenes, nodes, resources, signals, input actions, autoloads, addons, etc. That's much more valuable than copying a 40-part RPG tutorial and discovering at episode 37 that everything is intertwined.

For our first milestone, I'd aim for something laughably modest:

> **Milestone 1 — Walk Into the Tavern**
> Launch game → player appears → player can walk around a small map → camera follows player → player collides with walls.

Then:

> **Milestone 2 — There's a Goblin in the Tavern**
> Add an entity → interact with it → attack → HP decreases → goblin dies.

Only after that do we start bringing in inventory, dialogue, quests, and other people's addons.

That gives us a clean progression where **every new lesson adds one real feature to the same game** instead of doing disconnected Godot exercises.

I would also keep this **single-player initially**. Godot's multiplayer facilities are there when we're ready, but introducing network authority while you're simultaneously learning nodes, scenes, signals, resources, animation, UI, and game rules would obscure what each piece is doing. Godot's high-level multiplayer system is designed such that we can layer networking into a scene/node architecture later. ([Godot Engine documentation][5])

So yes: **we can absolutely build this tutorial together, and “don't reinvent inventory/dialogue/etc.” can be an explicit project rule.**

If you're ready, I would make the very next step **Lesson 1: create the Godot project, make `player.tscn`, make `test_room.tscn`, and get a capsule/cube walking around an ugly empty room.** No art, no 5e, no inventory yet. Just the smallest possible piece of a real architecture.

[1]: https://godotengine.org/asset-library/asset/1650?utm_source=chatgpt.com "Inventory System - Godot Asset Library"
[2]: https://godotengine.org/asset-library/asset/1919?utm_source=chatgpt.com "Wyvernbox - Inventory System - Godot Asset Library"
[3]: https://godotengine.org/asset-library/asset?utm_source=chatgpt.com "Godot Asset Library"
[4]: https://store.godotengine.org/asset/nathanhoad/dialogue-manager/?utm_source=chatgpt.com "Dialogue Manager"
[5]: https://docs.godotengine.org/en/stable/tutorials/networking/high_level_multiplayer.html?utm_source=chatgpt.com "High-level multiplayer - Godot Docs"
