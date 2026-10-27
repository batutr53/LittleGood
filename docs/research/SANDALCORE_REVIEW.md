# SandalCore suitability review for LittleGod

Reviewed 27 October 2026. Upstream snapshot: [`ec070a83ffb5cee4148f0d74ddf95fbeb54df052`](https://github.com/cyborqz/SandalCore/tree/ec070a83ffb5cee4148f0d74ddf95fbeb54df052). Read-only clone: `D:/LittleGod/builds/research/SandalCore`. No upstream scripts, installers, data extractors or server binaries were executed. No upstream source was copied into LittleGod's runtime. This is source analysis, not validation of a running Ashes of Creation server/client.

## What this repository actually supplies

[README](https://github.com/cyborqz/SandalCore/blob/ec070a83ffb5cee4148f0d74ddf95fbeb54df052/README.md) describes an independent Ashes of Creation-compatible server emulator. It has C++ world simulation/Unreal networking, Go account/character/city/quest services, PostgreSQL/NATS infrastructure and tools that build required data from a locally installed proprietary client. It is not a Godot game, an Android client, an art pack or a ready mobile HUD. It explicitly ships no game-client files or Intrepid game assets. It therefore cannot provide the requested finished class models, animations, maps or UI artwork for LittleGod.

LittleGod currently uses Godot/GDScript, a local fixed-step simulation/private saves and an existing C# account/social API. Replacing these with SandalCore would discard working integrations and introduce another protocol/content/runtime stack. The useful material is the design of individual systems and their tests.

## Best adaptations, in recommended order

### 1. A readable gathering job lifecycle

Evidence: [node_board.h](https://github.com/cyborqz/SandalCore/blob/ec070a83ffb5cee4148f0d74ddf95fbeb54df052/server/worldd/gather/node_board.h), [node_board.cpp](https://github.com/cyborqz/SandalCore/blob/ec070a83ffb5cee4148f0d74ddf95fbeb54df052/server/worldd/gather/node_board.cpp), [gathering.h](https://github.com/cyborqz/SandalCore/blob/ec070a83ffb5cee4148f0d74ddf95fbeb54df052/server/worldd/gather/gathering.h).

NodeBoard records Available / Channeling / Gathered, the worker/player holding the node, start/completion times and cancellation/respawn statistics. `begin` rejects a missing or already-held node before starting work. The gathering layer separates node state, tool requirements, duration, reward rolls, profession XP and wear.

LittleGod already has single-duty worker reservation, terrain-specific sources, progress, cargo caps and preserved overflow. Adapt the explicit **available → travelling → working → returning → cargo ready / warehouse full / depleted** state and clear reason codes to its existing tick model. Add per-node capacity/reservations rather than allowing unlimited overlapping workers; make each worksite display who is using it. Suitable tools can show a preview of actual output and profession XP. Keep saved depleted deposits and offline replay; do not inherit SandalCore's documented reset-on-server-restart limitation. Renewable trees should visibly regrow under explicit ecological rules; ore should remain finite unless a designed replacement source exists.

### 2. Enemy perception, leash and reset

Evidence: [npc_ai.h](https://github.com/cyborqz/SandalCore/blob/ec070a83ffb5cee4148f0d74ddf95fbeb54df052/server/worldd/npc/ai/npc_ai.h), [npc_ai.cpp](https://github.com/cyborqz/SandalCore/blob/ec070a83ffb5cee4148f0d74ddf95fbeb54df052/server/worldd/npc/ai/npc_ai.cpp), [threat.h](https://github.com/cyborqz/SandalCore/blob/ec070a83ffb5cee4148f0d74ddf95fbeb54df052/server/worldd/npc/ai/threat.h).

The AI separates Idle / Chase / Attack / Reset / Dead, checks hearing/sight/line of sight, gives orders rather than moving physics itself, and returns home after a leash break. Threat switching has hysteresis and a bounded table; its documented 110% target-switch ratio is their model, not a LittleGod balance recommendation.

LittleGod already has attack anticipation/recovery and collision-aware pursuit. Add distinct patrol/perception, chase limits, obstacle-aware loss of target and an unmistakable return/reset state. Preserve first-time boss rewards and item IDs during reset; reset is not a second kill. Do not add complex multi-player threat calculations before companions/parties actually exist. For future defense battles, use threat/taunt roles only where real multiple combatants justify them.

### 3. One validated ability result drives all feedback

Evidence: [ability_pipeline.h](https://github.com/cyborqz/SandalCore/blob/ec070a83ffb5cee4148f0d74ddf95fbeb54df052/server/worldd/session/ability_pipeline.h), [hit_resolver.h](https://github.com/cyborqz/SandalCore/blob/ec070a83ffb5cee4148f0d74ddf95fbeb54df052/server/worldd/combat/hit_resolver.h).

The ability pipeline validates knowledge, target, activation rules, resources and cooldowns, rejects duplicate recent request IDs, then separates cast/cost/effect/hit timing. HitResolver computes results without applying them itself. Confirmations distinguish requested and effective effects, such as healing zero at full health. Effects have duration, stacking rules and shields.

LittleGod should retain its 50-ms combat step and existing mana/cooldowns, but move toward a compact data-defined cast lifecycle and a structured result: actor/target, accepted/rejected reason, effective damage/heal, element, cost, cooldown and visual event. That result must drive HP/MP bars, damage numbers, status icons and animation timing together. Next useful statuses are bounded burn/poison, slow, stun immunity windows and shields, with explicit replacement/refresh rules and tested save/offline behavior. Do not import their complete expression bytecode compiler or retail formulas.

### 4. Interest-based updates for mobile

Evidence: [world/relevancy.h](https://github.com/cyborqz/SandalCore/blob/ec070a83ffb5cee4148f0d74ddf95fbeb54df052/server/worldd/world/relevancy.h).

Actors are classified Awake / Snapshot / Out; entering/leaving distance thresholds differ to prevent edge churn, and actor opens have a per-tick budget. These are network-relevance rules; their distance values and 15-Hz clock are not Android performance settings.

Adapt the principle: selected/on-screen workers and enemies animate fully, nearby objects update less frequently, distant cosmetics sleep, and new map decorations load in a bounded per-frame budget. **Simulation progress still uses the authoritative tick/offline calculation**, so hiding an object never stops its production or changes combat rewards. Profile the real connected phone separately; this repository establishes no LittleGod FPS improvement. Our existing prop culling is a useful starting point, not a reason to rebuild rendering.

### 5. Colony development stages with explicit unlocks

Evidence: [citynode/levels.go](https://github.com/cyborqz/SandalCore/blob/ec070a83ffb5cee4148f0d74ddf95fbeb54df052/services/internal/citynode/levels.go), [citynode/service.go](https://github.com/cyborqz/SandalCore/blob/ec070a83ffb5cee4148f0d74ddf95fbeb54df052/services/internal/citynode/service.go).

City state, XP progress and mutations are separated. Importantly, `Progress` explicitly does **not** level a node by itself; names such as Metropolis in an enum do not prove every settlement stage is complete gameplay.

Adapt to Hearthbound colony milestones: camp → village → fortified village → town, each unlocking visible building changes, a defined worksite, production recipe or defense option. Use existing quest/build/food/population state as evidence, rather than duplicate unconnected XP bars. Show one next unlock and its exact requirements. Completing hero expeditions can supply specific research materials without forcing repeated boss grinding or destroying progress after absence.

### 6. Inventory transactions and container rules

Evidence: [items/inventory.h](https://github.com/cyborqz/SandalCore/blob/ec070a83ffb5cee4148f0d74ddf95fbeb54df052/server/worldd/items/inventory.h).

Equip/unequip/move/swap are pure commands that return ordered storage events. Instance identity, displaced items and free capacity are checked before changes. Two-handed equipment reserves multiple slots; resource grants route into appropriate containers. Its documentation explicitly has permissive class rules because that game's data differs.

Useful for LittleGod: preview two-handed weapon/offhand swaps, refuse changes atomically when displaced gear has no room, preserve one owner per item and show why a move failed. Keep our class requirements and worker/soldier/hero reservations. Use simple material stacks or a settlement warehouse rather than importing an elaborate rectangular resource-bag puzzle that would complicate the mobile UX. Do not assume manual stack merge is already complete: upstream lists it as missing.

### 7. Future online authority and replay tests

Evidence: [services/README.md](https://github.com/cyborqz/SandalCore/blob/ec070a83ffb5cee4148f0d74ddf95fbeb54df052/services/README.md), [character/progress.go](https://github.com/cyborqz/SandalCore/blob/ec070a83ffb5cee4148f0d74ddf95fbeb54df052/services/internal/character/progress.go), [quests/quests.go](https://github.com/cyborqz/SandalCore/blob/ec070a83ffb5cee4148f0d74ddf95fbeb54df052/services/internal/quests/quests.go), [test_worldd_npc_ai.cpp](https://github.com/cyborqz/SandalCore/blob/ec070a83ffb5cee4148f0d74ddf95fbeb54df052/server/worldd/tests/test_worldd_npc_ai.cpp).

Keep the principle of one runtime writer, authenticated internal calls, transactions around progression/grants and deterministic clock-driven tests. Our existing C# service can evolve toward server-owned battle sessions, immutable loadout snapshots, request IDs, revision checks, once-only reward delivery and reconnect recovery. There is no need to adopt Go/C++/NATS/gRPC microservices at LittleGod's current scale. Crucially, a neighbor showcase is not an authoritative battle snapshot, and offline client saves must not become trusted PvP rewards.

## What not to take or claim

- No client models, animations, textures, UI or maps are supplied for reuse. Running extraction tools against another game's client is outside this review and is not an art pipeline for LittleGod.
- Do not replace Godot with Unreal network emulation, the required proprietary client, large navigation-data extraction or a many-service deployment.
- Do not describe quests, crafting, guilds, node sieges or caravans as ready-made completed modules. [ROADMAP](https://github.com/cyborqz/SandalCore/blob/ec070a83ffb5cee4148f0d74ddf95fbeb54df052/ROADMAP.md) and [KNOWN_ISSUES](https://github.com/cyborqz/SandalCore/blob/ec070a83ffb5cee4148f0d74ddf95fbeb54df052/KNOWN_ISSUES.md) list substantial unfinished work. The quest package does exist, but identifies itself as persistence/validation for the first slice; it is not a completed NPC narrative system.
- Do not import documented full-bag/death-pile confusion, unsaved depleted resources, stationary town NPCs/incomplete collision, or placeholder ability visuals.
- A source file or test file is evidence of implementation intent, not proof that upstream currently passes tests or works in our Android build. No upstream tests were run here.

## Code reuse boundary

[LICENSE](https://github.com/cyborqz/SandalCore/blob/ec070a83ffb5cee4148f0d74ddf95fbeb54df052/LICENSE) is AGPL-3.0; [NOTICE](https://github.com/cyborqz/SandalCore/blob/ec070a83ffb5cee4148f0d74ddf95fbeb54df052/NOTICE) states AGPL-3.0-only with section-7 attribution/modified-version/naming terms. Direct source integration needs a separate license/architecture decision, including applicable source-availability and network-use obligations; this audit does not determine their reach for an unbuilt integration. No license is being changed and no such source integration is performed. Recast/Detour has its separate zlib license, but LittleGod's existing 2D navigation should be evaluated before adding a native library.

## Practical next delivery

Prioritize **worker/worksite lifecycle and visible progress → enemy patrol/leash/reset → validated ability/status results → measured mobile update budgets → colony stage unlocks → inventory swap polish → server-owned PvP**. Add acceptance tests at each step: double assignment, full warehouse, reconnect/cancel, a mob behind a wall, leash without duplicate loot, status refresh/expiry, sleeping-object simulation equivalence and exactly-once online rewards. This complements the existing [development ledger](../DEVELOPMENT_BACKLOG.md); it does not silently mark its incomplete milestones as delivered.
