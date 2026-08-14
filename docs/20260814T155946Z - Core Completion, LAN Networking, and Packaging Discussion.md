# Core Completion, LAN Networking, and Packaging Discussion

Another work-log doc from a Claude Code implementation session, not a whiteboarding transcript. Picks up directly from `docs/20260814T055240Z - World Manager, Actions, and Networking Kickoff.md` (which ended with World Manager and the Action abstraction built, and the World/Action/Authority PR pending a push) and `docs/20260814T060000Z - CoreRPG Current Status.md` (an external ChatGPT-style consultation the user brought back, evaluating the pre-networking repo state and independently converging on the same three-step Core-completion plan).

## Morning: closing out Core

The `CoreRPG Current Status.md` consultation confirmed the plan already in motion and raised a few points worth recording:

- **Confirmed**: Actor/Controller/Rules were solid; Action and World (built earlier that morning, not yet reflected in the consultation's own view of the repo) were exactly the right next moves; Authority should stay trivial until networking gives it a real job.
- **New, deferred**: `PlayerController.get_attack_target()` conflates "is in the `nonplayers` group" with "is a legal target" — a targeting-legality question that belongs nearer Rules/Authority than the input controller. Acknowledged as correct and likely to matter soon (scene/content work), explicitly deferred — no second concrete case (e.g. a friendly NPC) exists yet to design the real mechanism against.
- **Done**: moved `controllers/` from `core/actors/controllers/` to `core/controllers/`, reflecting that Controller is one of the six Core nouns, not an Actor implementation detail. Pure rename; GDScript resolves scripts by `class_name`, not path, so the only fixes needed were the two `ext_resource` path references in `player.tscn`/`nonplayer.tscn`.
- **Done**: added `core/authority/authority.gd` (`Authority.can_perform()`, trivially `true` at the time -- no networking existed yet to check against) and `core/actions/action_runner.gd` (`ActionRunner.run()`, consulting `Authority` before calling `Action.execute()`). `Actor.try_attack()` now runs through `ActionRunner` instead of calling `.execute()` directly.

This completed the six-noun Core MVP (`Actor`, `Controller`, `Action`, `World`, `Rules`, `Authority`) both planning docs converged on. Committed and pushed directly to `main` (small, low-risk, already-agreed-upon changes, matching the user's preference to skip PR ceremony for this kind of work).

## LAN networking: three-step sequence, three PRs

Built exactly the sequence planned in `docs/20260814T000000Z - MikeRPG Core Integration.md`: bare connection, then movement replication, then attack replication. All three went through PRs since this was genuinely new, higher-risk territory (first networking code in the project).

### Step 1 -- bare ENet connection with peer-owned spawning (PR #2, merged)

New `networking/` directory, sibling to `core/` -- deliberate: Core should never know ENet exists, only about ownership (`Actor.owner_id`, added the previous PR). `networking/network_bootstrap.gd` is an autoload that's a no-op without `-- --server` or `-- --connect=<address>` on the command line. On peer connect, the server spawns a `PlayerController`-driven `Actor` via `WorldManager.spawn()` and sets `owner_id` to the peer id; on disconnect, despawns it. No movement/combat sync -- proving peer identity and spawn/despawn bookkeeping was the whole scope.

Debugging note worth keeping: the very first attempt appeared to hang for ~17 minutes. Root cause was the *test driver's* own bug (it kept awaiting on an actor that had already died and been freed mid-loop), not the engine or the networking code -- fixed by removing the driver's dependency on real-time waits.

### Step 2 -- movement replication (PR #3, merged)

Client-authoritative movement for peer-owned actors, server-authoritative for AI/static content. `Actor._physics_process()` gated on `is_multiplayer_authority()`; `player.tscn`/`nonplayer.tscn` each got a `MultiplayerSynchronizer` replicating `position`; `demo_room.tscn` got a `MultiplayerSpawner` watching `WorldManager`'s path.

This one took three attempts to get right, and the failures were informative:

1. Setting `set_multiplayer_authority(id)` *after* `WorldManager.spawn()` returned -- the client's own replicated copy never received the authority; it stayed stuck "observing" instead of "moving."
2. Setting it *before* `add_child()` by threading an `authority_id` parameter through `spawn()` -- Godot's own error message caught this directly: `MultiplayerSynchronizer... unable to process the pending spawn since it has no network ID... change authority during the "_enter_tree" callback of their multiplayer spawner`. This also surfaced a second bug: a client's freshly-replicated Goblin had `character_sheet == null`, since `WorldManager.spawn()`'s property overrides only ever applied to the server's own local copy, never to a client's independently-instantiated replica.
3. The actual fix: `WorldManager.spawn()` now routes through a `MultiplayerSpawner` custom `spawn_function` instead of instantiating and `add_child()`-ing directly, even offline. The spawn function receives identical data (scene path, character sheet path, color, transform, authority id) on every peer and reconstructs the actor identically everywhere -- which fixed both the authority-timing problem and the `character_sheet` gap at once, since both were really the same root cause (state needs to be established identically on every peer, not just the spawning one).

`WorldManager._ready()` also stopped running its static `spawn_points` on a pure client (it gets that content from replication instead, avoiding a double-spawn), and `nonplayer.tscn` got `goblin.tres`/green baked in as its own default `character_sheet`/`color`, mirroring how `player.tscn` already baked `mike.tres` -- a safety net independent of the `spawn_function` fix.

### Step 3 -- attack replication with real Authority (PR #4, merged)

`Authority.can_perform(action, requester_id)` finally got real logic: an actor's owner (or anyone, for an unowned/AI actor) may act on it. First real consumer of `owner_id`. `Actor.try_attack()` now branches: a pure client sends a `request_attack` RPC to the server instead of resolving locally; the server (or single-player, or AI) resolves directly. `request_attack` is `@rpc("authority", "call_remote", "reliable")` -- Godot's own RPC authority enforcement already rejects a call from any peer other than the actor's real owner, *before* `Authority.can_perform()` ever runs, which was a deliberate choice: `Authority` is the conceptual check and shouldn't depend on whatever transport happens to enforce it today. The requester id comes from `multiplayer.get_remote_sender_id()` inside the RPC handler -- the first point in the codebase with an actual trustworthy requester id, which is why `Authority.can_perform()` didn't take one until this step.

Land mine found and fixed here, originating in the *previous* PR: `_physics_process()`'s movement-authority gate (step 2) also gated the `_attack_timer` decrement, meaning the server's copy of a peer-owned actor's cooldown would never tick down (no movement authority there = the whole function skipped), permanently blocking every attack after the first. Fixed by decoupling the timer's decay from the movement-authority gate -- it now always ticks, on every peer, regardless of authority; only movement and *initiating* an attack stay gated.

Verified with an isolated check (mismatched requester rejected, no HP change; actual owner allowed, action executes) plus a live two-instance test: the client's attack requests resolved server-side with real dice rolls while the Goblin's own AI fought back concurrently through the unchanged local-resolution path, no conflict between the two.

## Afternoon: what "Core" actually means, and how this repo should be packaged

A long discussion prompted by the user opening `network_bootstrap.gd` and asking whether networking is required for single-player. Worth recording in full since it changed how a few things are named and organized, and will matter again whenever distribution/packaging comes up for real.

**Is networking required for single-player?** No, confirmed both by code inspection and by literally deleting the `networking/` folder and testing. `core/` never references anything in `networking/` in either direction -- `Actor.gd` and `WorldManager.gd` only use Godot's own built-in `multiplayer`/`@rpc` primitives (which the README already says Godot owns), never ENet specifically. `grep` confirmed `ENetMultiplayerPeer` appears in exactly one file, `network_bootstrap.gd`.

**Is it "third-party," like `addons/`?** No -- pushed back specifically on that framing. `addons/` has a concrete meaning in this project: externally-sourced code, gitignored, not authored or maintained by us. `networking/` is hand-written, version-controlled, debugged over three PRs. The right existing bucket, per the user's own earlier Core-vs-Standard planning session, is closer to `features/`: "our own code, optional, deletable, doesn't break the base game." Whether it should physically live under a future `features/` directory or stay its own top-level category (as originally planned, since it's a transport/simulation-mode decision rather than a per-Actor gameplay capability like inventory/dialogue) was left open, no strong need to resolve now.

**Could it be swapped for a different networking package?** Depends what kind. An alternative *transport* (Steam, WebSocket, WebRTC -- anything implementing Godot's `MultiplayerPeer` interface) would be a clean swap, isolated entirely to `network_bootstrap.gd`, confirmed by the `ENetMultiplayerPeer` grep above. Something like Nakama (identity/accounts/matchmaking) wouldn't be a swap at all -- per last night's whiteboarding, it's additive, sitting in front of the existing Godot peer connection, not replacing it. Something that wants to own replication/simulation itself (not Godot's `MultiplayerSpawner`/`MultiplayerSynchronizer`) would actually reach into `core/`, and would need real scrutiny before adopting -- the "don't reinvent Godot" principle this whole project is built around.

**"Two kinds of core" -- philosophical vs. technical.** The user's framing: the six nouns are "philosophical core," but `networking/` felt "technically core" since deleting it (without also editing `project.godot`) broke boot entirely. Refined this: it isn't that networking is secretly required -- it's that `project.godot`'s `[autoload]` list had a *hard-coded path* to it, and Godot's autoload system fails at that specific path regardless of what the missing script would have done. That's a packaging/wiring gap, not a deeper truth about what the game needs, and it was actually inconsistent with a rule the project already set for itself: *"deleting a directory under `features/` should not prevent the base game from launching."* `networking/` passed that test *behaviorally* (inert without CLI flags) but failed it *structurally* (deleting the folder broke boot) -- worth fixing, and became the graceful-fallback PR (below).

**On naming**: proposed *not* renaming the six-noun `core/` -- it's four merged PRs and this whole session's vocabulary at this point, and the nouns themselves aren't actually ambiguous. What lacked a name was the *other* axis: "things unconditionally wired at boot." Landed on reusing **Runtime**, since that name was already earmarked in the very first networking planning doc for exactly this kind of thing (`runtime/{standalone, listen_server, dedicated_server}` -- "where authority runs").

**"One clean folder as a future asset-store template."** The user's actual worry, once unpacked: not that the architecture was wrong, but that "Core" had been doing double duty in their head as both "the six-noun contract" and "the thing I'd eventually fork/upload as a starter kit." Those are different jobs. The forkable unit was never meant to be `core/` alone -- it's the whole repo (`core/` + `networking/` + `runtime/` + `scenes/` + `data/` together), the same way Maaack's own template is a whole project with several top-level pieces, not one nested folder. `core/` staying small on purpose is what makes the *whole repo* safe to fork onto a different ruleset or setting later -- it's a statement about reusability, not about how essential something is to *this* game. No renaming or restructuring done as a result; this was a reframe, not a change.

**Should `networking/` live under `runtime/`?** Considered and declined. `runtime/boot.gd`'s job is deciding what to wire up; `networking/` is a real subsystem that gets wired up -- a dependency relationship, not a containment one. Nesting would misrepresent that, and would also box in a future where `runtime/` grows mode-specific bootstraps (`standalone/`, `listen_server/`, `dedicated_server/`, per the original sketch) that would each want to reach `networking/` as a neutral sibling rather than reach into one specific consumer of it. `core/`, `networking/`, and `runtime/` stay siblings, each named for what it *is*.

## Graceful fallback when networking/ is deleted (PR #5, open as of this writing)

Direct result of the "two kinds of core" discussion. Empirically confirmed (by moving `networking/` out of the project entirely and booting headless) that Godot does *not* hard-crash on a missing autoload path -- it logs three `ERROR` lines and continues, and since nothing else references the `Network` singleton by name, gameplay was completely unaffected underneath the noise. But "scary errors on every boot" is exactly the wrong first impression for someone forking this repo as a template and deleting a folder they don't need.

Fix: new `runtime/boot.gd` is now the only unconditional autoload (`Boot`, replacing the direct `Network=...` entry). It loads `networking/network_bootstrap.gd` defensively via `ResourceLoader.exists()` rather than giving it a hard-coded path of its own. Verified both directions: with `networking/` present, single-player and a real two-instance server/client session both still work; with it deleted entirely, boot is completely silent and gameplay (spawn, combat, damage, death) is unaffected.

This is also the first real occupant of `runtime/` as a directory, matching the name chosen in the discussion above.

## Git state as of this writing

- `main` is at PR #4's merge commit. PRs #1-#4 (World/Action/Authority completion, and the three networking steps) are merged.
- PR #5 (`graceful-networking-fallback`, graceful fallback when `networking/` is deleted) is open, not yet merged.
- Explicitly out of scope today, by the user's own call: a README rewrite. The README still describes the pre-networking, pre-Authority state of the project. Needs its own dedicated session, not bundled into this one.

## Open items / next steps

- Merge PR #5.
- README rewrite (explicitly deferred to a future session).
- `PlayerController`'s `nonplayers`-group targeting-legality coupling (flagged this morning, still deferred -- no second concrete case yet).
- Whether `networking/` eventually moves under a `features/` directory once one exists, or keeps its current top-level standing -- left open, no pressure to resolve.
- Distribution-track work (Maaack Game Template shell, Dax D20 evaluation) -- still untouched all session, per the user's original call to finish Core and networking first.
- `GMController` / a real `AuthorityContext` beyond the current `owner_id`-based check -- still deferred; no second peer *role* (as opposed to a second peer) exists yet to design against.
