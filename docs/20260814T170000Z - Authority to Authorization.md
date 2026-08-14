# Authority to Authorization

## Prompt 1
Go ahead and re-pull the main rpg repo. You should see all the changes from this morning.

## Response 1
Yep — **now I see the changes.** The earlier GitHub view I was working from was stale. The current `main` has **30 commits**, and `core/` now contains `actions/`, `actors/`, `rules/`, and `world/`. ([GitHub][1])

More importantly, the Actions work is substantially there:

```text
core/
├── actions/
│   ├── action.gd
│   ├── action_result.gd
│   ├── action_runner.gd
│   └── attack_action.gd
├── actors/
│   ├── actor.gd
│   └── controllers/
├── rules/
└── world/
    ├── spawn_point.gd
    └── world_manager.gd
```

([GitHub][2])

So that changes my assessment significantly.

Of the six Core concepts we've settled on:

| Core concept                          | Current                    |
| ------------------------------------- | -------------------------- |
| **Actor** — who exists?               | ✅                          |
| **Controller** — who decides?         | ✅                          |
| **Action** — what do they want to do? | ✅ now present              |
| **World** — where do they exist?      | ✅ now present              |
| **Rules** — what happens?             | ✅                          |
| **Authority** — may they do it?       | **⬜ remaining major seam** |

And you've done exactly what I wanted with Actions rather than merely creating an empty `actions/` abstraction: there's a concrete `AttackAction` alongside `Action`, `ActionResult`, and `ActionRunner`. ([GitHub][2])

So **I withdraw my previous recommendation that Actions and World are your next two major Core tasks. You've done them.**

At this point I want to inspect the implementations of `action_runner.gd`, `attack_action.gd`, `world_manager.gd`, and the updated `actor.gd` before saying whether I think Authority is literally the last architectural Core piece or whether those implementations reveal one more seam.

But structurally, this is *much* closer to the finish line than the version I reviewed before.

And I particularly like that the repository still has **no required addons** and `addons/` remains explicitly third-party territory. ([GitHub][1]) That means you've added these Core concepts without accidentally dragging Maaack, Dax, networking, inventory, etc. across the Core boundary.

So at first glance: **yes, this morning's work appears to have landed almost exactly where our architecture discussion was pointing.** The remaining question isn't “what major systems are missing?” anymore. It's increasingly **“is Authority the final Core contract, and then do we freeze Core?”**

[1]: https://github.com/stardustsuperwizard/mikerpg "GitHub - stardustsuperwizard/mikerpg: This is an RPG game that I am designing in Godot · GitHub"
[2]: https://github.com/stardustsuperwizard/mikerpg/tree/main/core/actions "mikerpg/core/actions at main · stardustsuperwizard/mikerpg · GitHub"

## Prompt 2
Can you explain what you think authority needs to look like?

## Reponse 2
I think Authority should be **very small**. Its job is not networking, authentication, permissions UI, or GM tooling. It answers one question:

> **Is this source allowed to make this Actor perform this Action?**

That’s it.

For MikeRPG Core, I’d model it around three concepts:

```text
Actor
Action
AuthorityContext
```

An `AuthorityContext` represents **who is asking**. In single-player, that might be “local player.” On a LAN server, it might be Godot peer `82731`. With Nakama later, it might carry a Nakama user ID. For a GM, it might include elevated permissions.

Conceptually:

```gdscript
class_name AuthorityContext
extends RefCounted

var principal_id: String
var roles: Array[StringName] = []
```

Then the Actor needs some notion of ownership/control:

```gdscript
actor.authority_id = "player:82731"
```

and the ActionRunner does something like:

```text
Controller creates Action
        ↓
ActionRunner
        ↓
Authority.can_execute(context, action)
        ↓
YES → execute
NO  → rejected ActionResult
```

I would make the public Core API roughly:

```gdscript
Authority.can_execute(
    context: AuthorityContext,
    action: Action
) -> bool
```

or perhaps return a result rather than a boolean:

```gdscript
Authority.check(
    context: AuthorityContext,
    action: Action
) -> AuthorityResult
```

I prefer the latter eventually because it can tell you **why** something was rejected:

```text
allowed = false
reason = "actor_not_owned"
```

That is useful for debugging, UI, networking, and GM tooling.

The default rule can be extremely simple:

```text
If context controls action.actor:
    allow

Otherwise:
    reject
```

Then GM authority becomes a deliberate override:

```text
if context.has_role("gm"):
    allow
```

So your first implementation could genuinely be this conceptually:

```gdscript
func can_execute(context, action) -> bool:
    if context.has_role(&"gm"):
        return true

    return action.actor.authority_id == context.principal_id
```

That already supports your major scenarios.

Single player:

```text
principal_id = "local"
Actor.authority_id = "local"
```

LAN:

```text
principal_id = "peer:82731"
Actor.authority_id = "peer:82731"
```

Nakama:

```text
principal_id = "nakama:abc123"
Actor.authority_id = "nakama:abc123"
```

GM:

```text
principal_id = "peer:9001"
roles = ["gm"]
```

Notice how Core never learns what ENet or Nakama is. They just produce a principal ID.

I also would **not** put detailed game permissions into Authority initially. Things like:

```text
Can this wizard cast Fireball?
Can this character open this locked door?
Is PvP enabled?
Is the target in range?
Does the character have enough action points?
```

Those are **Rules**, not Authority.

Authority answers:

> Are *you* allowed to issue actions for this Actor?

Rules answer:

> Is this Action legal and what happens?

That distinction is important.

For example:

```text
Peer 82731 requests:
Actor 42 attacks Actor 99
```

First:

```text
Authority:
Does peer 82731 control Actor 42?

YES
```

Then:

```text
Rules:
Is Actor 99 a valid target?
Is Actor 42 alive?
In range?
Cooldown ready?
Roll attack.
Calculate damage.
```

So the pipeline becomes:

```text
Controller / network request
        ↓
Action
        ↓
Authority
"Are you allowed to ask?"
        ↓
Rules
"Is the request legal, and what happens?"
        ↓
World
apply result
```

That’s the cleanest separation I can see.

I would probably implement Core with something this small:

```text
core/
└── authority/
    ├── authority_context.gd
    ├── authority_result.gd
    └── authority_manager.gd
```

And maybe add one field or method to Actor for ownership/control.

I would **not** build ACLs, role hierarchies, permission databases, authentication adapters, peer registries, or GM command frameworks yet.

If that tiny Authority layer works for local player, AI, LAN peers, and GM override, then I think you have the last major Core seam you actually need.

## Prompt 3
ACLs, role hierarchies, permission databases, authentication adapters, peer registries, and GM command frameworks sound like something that should live in a database or data file

## Response 3
Yes — **mostly**. And that observation actually sharpens the design.

The distinction I’d make is between **the authority mechanism** and **authority policy/configuration**.

Core should contain the mechanism:

```text
AuthorityContext
        +
Action
        ↓
Authority.check()
        ↓
allow / deny
```

But things like:

```text
GM can possess NPCs
Moderator can kick players
Player can control own characters
Assistant GM can spawn creatures but not modify rules
```

should absolutely be **data**, not hard-coded conditionals spread throughout Core.

For example, a distribution might eventually have:

```yaml
roles:
  player:
    permissions:
      - actor.control.owned
      - action.execute.owned

  gm:
    permissions:
      - actor.control.any
      - actor.spawn
      - actor.despawn
      - world.modify
      - rules.override

  assistant_gm:
    permissions:
      - actor.control.any
      - actor.spawn
```

Or that information could live in SQLite/Postgres/Nakama storage instead. Core shouldn't care.

The architectural split becomes:

```text
              CORE
                │
       Authority mechanism
                │
      "Does X have permission Y?"
                │
                ▼
        Authority Provider
                │
     ┌──────────┼──────────┐
     ▼          ▼          ▼
 Data File    SQLite     Nakama
```

And I actually like **`AuthorityProvider`** better than putting a complicated ACL system directly into `AuthorityManager`.

Your built-in MVP provider could be ridiculously small:

```text
LocalAuthorityProvider

local player → owns local actor
AI           → controls its actor
GM           → unrestricted
```

Then an eventual distribution provider could read:

```text
config/roles.json
```

and an online installation could use:

```text
Postgres
Nakama
etc.
```

There is one nuance, though: **peer registry and authentication adapters aren't really policy data.**

An authentication adapter is executable integration code:

```text
Nakama session
      ↓
NakamaAuthAdapter
      ↓
AuthorityContext("user:abc123")
```

A peer registry is runtime state:

```text
Godot peer 78142
      ↕
user abc123
      ↕
Actor 37
```

You might *persist* some of that information, but the registry itself is really part of the networking/runtime layer, not a database schema.

Likewise, I wouldn't put the **GM command framework itself** in a database. The *permission to use a command* belongs in data:

```text
gm:
  permissions:
    - world.spawn
```

But the actual implementation:

```text
SpawnActorAction
```

is code.

So I'd divide those examples this way:

| Thing                           | What it really is                        |
| ------------------------------- | ---------------------------------------- |
| ACL entries                     | **Data**                                 |
| Roles                           | **Data**                                 |
| Role hierarchy                  | **Data**                                 |
| User → role assignments         | **Data/persistent state**                |
| Permissions                     | **Data**                                 |
| Authentication adapter          | **Distribution integration code**        |
| Peer registry                   | **Runtime/network state**                |
| GM commands                     | **Actions/features implemented in code** |
| GM → command permission mapping | **Data**                                 |

And this leads to an especially nice MikeRPG design.

Instead of special-casing GM operations:

```text
GMManager.spawn_monster()
GMManager.teleport_player()
GMManager.kill_actor()
```

make those ordinary Actions:

```text
SpawnActorAction
TeleportActorAction
DespawnActorAction
PossessActorAction
```

Authority simply determines who may submit them.

Then:

```text
Player
  │
  └─ AttackAction ───────→ allowed

Player
  │
  └─ SpawnDragonAction ──→ DENIED


GM
  │
  ├─ AttackAction ───────→ allowed
  ├─ SpawnDragonAction ──→ allowed
  └─ PossessActorAction ─→ allowed
```

That is **much cleaner than building a separate GM command architecture**.

It also reinforces why Actions became such a useful Core abstraction. Even GM powers can travel through the same pipeline:

```text
Source
  ↓
Action
  ↓
Authority
  ↓
Rules / World
  ↓
ActionResult
```

So I'd revise my Authority proposal slightly based on your observation:

**Core should not contain an ACL implementation. Core should contain an Authority contract capable of consulting an AuthorityProvider.**

Something roughly like:

```text
core/
└── authority/
    ├── authority_context.gd
    ├── authority_provider.gd
    ├── authority_result.gd
    └── authority_manager.gd
```

with a tiny default implementation somewhere appropriate:

```text
authority/providers/
└── local_authority_provider.gd
```

And stop there.

Later the **MikeRPG distribution** can decide whether permissions come from a `.json`, `.tres`, SQLite database, Postgres, Nakama, or something else.

That's very consistent with the pattern you've already established with `RulesProvider`: **Core defines what question needs answering; the distribution decides how to answer it.**

## Prompt 4
This sounds a lot like identity, authentication, authorization

## Response 4
Exactly. What we’ve been calling “Authority” is really **authorization**, and it sits downstream of identity and authentication.

The clean security model is:

```text
IDENTITY
"Who are you?"
    ↓
AUTHENTICATION
"Prove it."
    ↓
AUTHORIZATION
"What are you allowed to do?"
```

For MikeRPG, those map very naturally to different layers.

```text
Identity
    user/player/principal ID

Authentication
    local trust
    LAN peer/session
    Nakama login/token
    Steam/OAuth/etc.

Authorization
    may this principal control this Actor?
    may they issue this Action?
    do they have GM permissions?
```

So I would actually rename the Core concept from **Authority** to **Authorization** or possibly **Access Control**.

That makes the boundary much clearer.

Core probably does **not** need to own authentication at all. In a LAN game, the runtime can simply establish:

```text
principal_id = "peer:12345"
authenticated = true   # effectively trusted LAN session
```

With Nakama:

```text
Nakama
   ↓ authenticates
principal_id = "user:abc123"
   ↓
MikeRPG authorization
```

The MikeRPG layer only consumes a trusted principal identity and asks:

```text
Can principal abc123 perform AttackAction for Actor 42?
```

That suggests an even cleaner pipeline:

```text
Network / Local Runtime
        ↓
authenticated Principal
        ↓
Action
        ↓
Authorization
        ↓
Rules
        ↓
World
```

And AI fits without pretending it “logs in”:

```text
AI Controller
    ↓
system principal / trusted internal context
    ↓
Action
```

Likewise the GM:

```text
authenticated user
       ↓
roles = ["gm"]
       ↓
Authorization
       ↓
SpawnActorAction allowed
```

So I’d revise our six Core questions slightly:

```text
WHO EXISTS?                 Actor
WHO DECIDES?                Controller
WHAT DO THEY WANT?          Action
WHERE DOES IT HAPPEN?       World
ARE THEY ALLOWED?           Authorization
WHAT HAPPENS?               Rules
```

And **Identity/Authentication are inputs into Core, not Core responsibilities**.

That also makes Nakama’s role wonderfully precise:

> Nakama can provide identity + authentication. MikeRPG provides game-specific authorization.

That is a much cleaner description than saying Nakama provides “authority.”

## Prompt 5
Right, I wasn’t going to add identity or authentication to core. That can be a distribution plugin. But the game authorization, that makes sense. Player A wants to do action, are they allowed? Check rules database or rules code to see

## Response 5
Yes — that’s the right split.

I’d make **Authorization** a very small Core concern that answers:

> Given this principal and this action, is the action permitted?

Then the distribution supplies the identity/authentication context and whatever policy source you want.

Conceptually:

```text
Principal + Action
      ↓
Authorization
      ↓
Policy / rules source
      ↓
ALLOW or DENY
```

For example:

```text
Player A
  ↓
AttackAction(actor=42, target=99)
  ↓
Authorization
  ↓
Does Player A control Actor 42?
Is Player A allowed to issue AttackAction?
  ↓
ALLOW
```

Then **Rules** takes over:

```text
Is Actor 42 alive?
Is target valid?
In range?
Cooldown ready?
Roll hit?
Calculate damage?
```

That distinction is useful because authorization is about **who may request something**, while game rules are about **whether the requested thing is valid in the game state and what its outcome is**.

So I would avoid putting all of this into one giant rules database. You can absolutely store authorization policy as data, but I’d keep the concepts separate:

```text
authorization policy:
    player may control owned actors
    gm may control any actor
    gm may spawn actors

game rules:
    attack range = 2m
    longsword damage = 1d8
    stunned actors cannot attack
```

Both might eventually be backed by JSON, resources, SQLite, or other providers, but they answer different questions.

For Core, I’d probably settle on something like:

```text
core/
└── authorization/
    ├── authorization_context.gd
    ├── authorization_provider.gd
    └── authorization_result.gd
```

And the contract might be as simple as:

```gdscript
authorize(context, action) -> AuthorizationResult
```

Then your distribution can plug in:

```text
LocalAuthorizationProvider
LanAuthorizationProvider
RoleBasedAuthorizationProvider
NakamaBackedAuthorizationProvider
```

without changing Actions or Rules.

That gives you a very clean execution pipeline:

```text
Controller / network request
          ↓
        Action
          ↓
    Authorization
    "may you ask?"
          ↓
        Rules
   "is it valid?"
          ↓
        World
    "apply result"
```

I think that is the final form of the idea we were circling earlier.

## Implementation Plan

The design above is settled, but implementation is **deferred**, not scheduled.

`core/authority/authority.gd` today is exactly the "tiny first implementation" this session converged on: a static `can_perform(action, requester_id)` checking `actor.owner_id == requester_id`, no `AuthorityContext`/`AuthorizationContext`, no provider, no roles, no GM path. That's already correct for the only two principals that exist in the repo right now (an actor's owning peer, and unowned/AI). There's no second role yet to design the provider/policy split against — matches the same deferral already on record for `PlayerController`'s targeting-legality coupling and `GMController`, in `docs/20260814T155946Z - Core Completion, LAN Networking, and Packaging Discussion.md` and `docs/20260814T163520Z - Pre-Content Fixes - Material Override and Attack Targeting.md`.

Concretely deferred until a real second case (most likely a GM role) exists to build against:

- Renaming `Authority` → `Authorization` (and `can_perform` → `authorize`).
- Introducing `AuthorizationContext` (principal id + roles) as a distinct object from the raw `requester_id` int.
- Introducing `AuthorizationProvider`/`AuthorizationResult` (with a reason) and moving the check behind a provider seam, mirroring `RulesProvider`/`RulesManager`.
- Any GM-as-Action work (`SpawnActorAction`, `PossessActorAction`, etc.) that would actually motivate the roles/policy split.

Trigger to revisit: the first time a second principal *role* (not just a second peer) needs to be authorized differently — e.g., a GM client, an assistant GM, or a moderator. Until then, expanding `Authority` would be designing against a hypothetical, which this project has consistently avoided elsewhere (see the `hostile: bool` vs. faction-system call in the Pre-Content Fixes doc).
