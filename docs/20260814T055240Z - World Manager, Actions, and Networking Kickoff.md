# World Manager, Actions, and Networking Kickoff

This is a work-log doc from a Claude Code implementation session, not a whiteboarding transcript like the other docs in this folder. It picks up directly from `docs/20260814T000000Z - MikeRPG Core Integration.md` and records what was assessed, decided, and built.

## Starting point

Assessed the repo against the Core MVP target from the Integration doc (`Actor`, `Controller`, `Action`, `World`, `Rules`, `Authority`):

- `Actor`, `Controller` (`PlayerController` + `AIController`), and `Rules` (`RulesProvider`/`RulesManager`/`LiteRulesProvider`) already existed and already matched the doc's target shape.
- `World` didn't exist as code. `demo_room.tscn` hardcoded its `Player`/`Goblin` population as hand-baked scene-tree children. A full design already existed, unexecuted, at `docs/20260812T234000EST - World Manager Plan.md`.
- `Action` didn't exist. `Actor.try_attack()` called the `Rules` autoload directly — the biggest, most-repeated gap called out across the Integration doc.
- `Authority` didn't exist. No ownership/identity concept anywhere, no networking code at all.

## Feedback given before implementation

- Build `World` before `Action` — it's already fully speced and low-risk, and a hand-baked scene tree is a worse foundation to build `Action` on top of than a data-driven one.
- Keep the `Action` MVP to exactly one action (`AttackAction`), not the doc's full example list (`Move`/`Interact`/`Use`/`Talk`) — no second concrete case exists yet to design those against.
- Don't build a full `AuthorityContext` yet — add a bare `owner_id` stub to `Actor` and stop, since there's no networking code to consume it.
- Don't build `GMController` yet, for the same reason.
- Distribution has two independent, well-scoped starting points (Maaack Game Template shell, LAN ENet dedicated-server MVP) that don't need to block finishing Core.

## Work completed

### World Manager

Executed the pre-written plan doc as designed, no changes to the design itself:

- `core/world/spawn_point.gd` (new) — `SpawnPoint` `Resource`: `actor_scene`, `character_sheet`, `color`, `transform`.
- `core/world/world_manager.gd` (new) — `WorldManager` (`Node3D`), spawns every entry in `spawn_points` on `_ready()`; `spawn()` is public as the seam a future GM tool or save/load restore will call.
- `scenes/actors/nonplayer.tscn` — goblin's `Controller.aggro_range` default bumped to `6.0` to preserve the old per-instance tuning that used to live in `demo_room.tscn`.
- `scenes/world/demo_room.tscn` — hardcoded `Player`/`Goblin` nodes replaced with two `SpawnPoint` sub-resources.

Verified with `tools/verify.sh` (parse + headless boot) and a throwaway runtime driver (deleted after use) that instantiated the scene and confirmed: exactly 2 actors spawned, positions/HP/AC/color matching the old hardcoded values exactly, and the goblin's `aggro_range` reading `6.0`.

### Action abstraction

- `core/actions/action.gd` (new) — base `Action`: holds `actor`, defines `execute() -> ActionResult`.
- `core/actions/action_result.gd` (new) — minimal result wrapper (`success: bool` only).
- `core/actions/attack_action.gd` (new) — the one concrete action; wraps the existing `Rules.attack()` call.
- `core/actors/actor.gd` — `try_attack()` now builds and executes an `AttackAction` instead of calling the `Rules` autoload directly.

Deliberately not built: `ActionRunner`, any action type besides `AttackAction`. Both would be dispatch/orchestration machinery with a single caller today.

Verified with `tools/verify.sh` and a throwaway runtime driver: 30 direct `AttackAction` executions between the spawned Mike and Goblin actors produced 15 hits / 15 misses, with damage applied identically to the pre-refactor code path (d20 + STR modifier vs. AC, d6 + modifier damage on hit). First driver attempt appeared to hang for ~17 minutes; root cause was the driver's own bug (it kept awaiting on an actor that had already died and been freed mid-loop, not an engine or `AttackAction` problem) — fixed by removing the driver's dependency on real-time waits and guarding against the target dying.

### Authority stub

- Added `owner_id: int = 0` to `Actor`. Unused today (`0` = unowned/AI-controlled); this is the field a future LAN client will set to its peer ID so a dedicated server can check ownership before honoring an `Action`.

Deliberately not built: a full `AuthorityContext` class, `GMController` — both need a real networking use case to design correctly rather than being guessed at now.

## Networking plan (discussed, not yet built)

- **Transport**: Godot's built-in high-level multiplayer via `ENetMultiplayerPeer`, no auth, connect by direct IP — the LAN-party MVP from the Integration doc's Prompt 6. No Nakama, no client/server repo split; same project runs headless-as-server or as a client depending on a flag.
- **Build sequence** (smallest proof first):
  1. Bare connection: server spawns a `PlayerController`-driven `Actor` per connecting peer via `WorldManager.spawn()`, sets `owner_id = peer_id`. No movement/combat sync yet.
  2. Movement replication via Godot's per-node multiplayer authority (`set_multiplayer_authority()`) + `MultiplayerSynchronizer` — client-authoritative, the standard trusted-LAN-co-op approach.
  3. Attack/Action replication via RPC, resolved only on the server; server checks `owner_id` before honoring the request. First real consumer of the `owner_id` stub, and expected to reveal what `AuthorityContext` actually needs to contain.
  4. `GMController` / a real `AuthorityContext` only after a second peer role (GM) actually exists.
- **Where it lives**: not an addon (`addons/` is third-party-only) and not a "feature" like inventory/dialogue (not a capability an `Actor` opts into — it's a decision about how the whole simulation runs). Landed on two new top-level directories, siblings to `core/`, to be created once there's real code for them: `networking/` (ENet adapter, RPC wiring, replication) and `runtime/` (bootstrap deciding client vs. dedicated-server mode).

## Repo strategy discussion

**Question**: snapshot/fork into a separate single-player-only repo before starting networking work?

**Decision: tag, don't fork.** Both pieces of work landed so far are purely additive — `owner_id` defaults to unowned with zero current consumers, and both `WorldManager` and `AttackAction` were verified byte-for-byte equivalent to the prior behavior. That's the actual bet behind keeping Core's networking-relevant surface to a single ownership field: multiplayer should be additive, not a rewrite. A tag on `main` (e.g. `v0.1-singleplayer` or `pre-networking`) gives the same "always recoverable" guarantee as a hard fork, without the ongoing cost of maintaining two codebases in parallel. A fork remains a reasonable fallback if the networking sequence above later proves it must change single-player behavior — but not before there's actual evidence of that.

**Question**: does adding networking open a security "can of worms"?

**Assessment: accurate, but scoped to the LAN/no-auth design already chosen.** The big can of worms (accounts, passwords, tokens, session hijacking) is exactly what "no auth, LAN only" avoids — that only opens if/when real authentication (e.g. Nakama) gets added later, which isn't in scope now. A smaller, real one opens immediately regardless:
- "No auth" means no authorization — anyone who can reach the port can connect. Fine for people physically at a LAN party; means this must never be port-forwarded to the public internet without adding auth first.
- Client input becomes attacker-controlled input even from a trusted friend's machine (modified or buggy client). This is exactly why the server-side `owner_id` check in networking step 3 is a correctness requirement, not a nice-to-have.
- Client-authoritative movement (step 2) is an accepted LAN tradeoff (a modified client could teleport/speed-hack) — fine for friends in a room, not appropriate the moment this becomes public play.
- Any RPC handlers written need to validate their inputs regardless of who's connecting.

## Git state at end of session

- Branch `prep-for-mvp`, which was at the same commit as `main` (0 ahead/behind) at the start of this session.
- Two commits made:
  1. `Add World Manager for data-driven actor spawning`
  2. `Introduce Action abstraction and Actor.owner_id stub`
- **Push to `origin` failed**: this session has no GitHub credentials available (no `gh` CLI installed; the `osxkeychain` credential helper returned nothing usable non-interactively). As of this writing the two commits above are local-only on this machine.

## Open items / next steps

- Push `prep-for-mvp` and open a PR against `main` — blocked on credentials; needs to happen from an authenticated terminal, or `gh auth login` needs to be run first.
- After merge, tag the commit (e.g. `v0.1-singleplayer` or `pre-networking`) as the recoverable single-player snapshot.
- Begin networking step 1 (bare ENet connection + peer-owned `Actor` spawn) once ready.
- Distribution tracks (Maaack Game Template shell, Dax D20 evaluation) remain deliberately deferred until the networking sequence is far enough along to inform `Authority`/`GMController` design.
