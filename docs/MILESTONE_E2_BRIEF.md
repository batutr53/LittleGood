# LITTLE GOD — AGE OF KINGDOMS
# MILESTONE E2: BEYOND THE KINGDOM
# PLAYABLE IRON HILLS, ASHEN DESERT, REGIONAL EXPLORATION, MONSTER HUNTING & REAL RESOURCE GATHERING

## MISSION

Continue development of the EXISTING LittleGod Godot project.

PROJECT: D:\LittleGod

CURRENT REPORTED CHECKPOINT:
- 0.8.5-devE1 / Android code89
- Git tag: age085-e1-trade
- 639 passing game assertions
- Legal Realm Levels 1–21
- Functional Marketplace
- Real merchant jobs
- Resource buy/sell
- Persistent caravans and cargo
- Two strategic trade routes
- Military prerequisite checkpoint age085-d-critical
- Existing Warrior/Wildwood combat
- Existing forge, inventory, hero and loot systems

TARGET:
LittleGod 0.8.5 — Milestone E2

TARGET CAMPAIGN:
Realm Level 22

DO NOT start E3, E4, E5, E6, LittleGod 0.9 or 1.0.

Your task is to implement the first major expansion of actual playable external regions beyond Wildwood.

You are the autonomous Godot game development team.

Perform:
- Code implementation
- Game design
- Regional environment creation
- Enemy AI
- Combat integration
- Original sprite creation
- Visual polish
- Quest design
- Mobile controls
- Automated testing
- Save migration
- Android packaging
- Performance verification

Use Codex, Godot MCP, Computer Use, terminal utilities and available image-generation tools where supported.

Do not stop at planning.

Implement real gameplay, run it, inspect visuals, fix issues and package a verified checkpoint.

Do not ask the user to perform routine development work.

---

# STEP 0 — VERIFY AND PROTECT EXISTING E1

Read:
- docs/STATUS.md
- AGE085_E1_REPORT.md
- TRADE_SYSTEM.md
- PERFORMANCE_MILESTONE_E1.md
- KNOWN_ISSUES.md
- MILESTONE_E_CONTINUATION.md
- AGE085_D_PREREQUISITE_REPORT.md
- Existing campaign, adventure, save and test code

Inspect repository and Git status.

Confirm:
- Actual E1 source and commit.
- Existing 639 assertions.
- Working quest 21.
- Real caravan transport and collection.
- Safe escort decisions.
- Current military prerequisite scope.
- Existing unique item ownership.
- Existing native Android test drivers.

Create safe checkpoint:

age085-e2-base-e1

Preserve:
- All existing completed quests.
- Realm XP.
- Civilian resources.
- Citizen identities.
- Military assignments.
- Merchant assignments.
- Trade prices and routes.
- Pending caravans.
- Caravan cargo reservations.
- Escort assignments.
- Hero identity and equipment.
- Wildwood exploration state.
- Crafting queues.
- Inventory identities.
- Boss reward history.
- Cosmetics.
- World saves.
- Existing online source code.

Do not rewrite the trade system.

Do not rebuild Adventure Mode.

Use the real existing architecture.

---

# 1 — PRIMARY GAMEPLAY OBJECTIVE

The player has built the first trade road.

Merchants now bring news of lands outside the kingdom.

Iron Hills contains deep mineral caves.

Beyond those mountains lies the mysterious Ashen Desert.

The player's hero must physically explore these lands.

The new regions should feel distinct, dangerous, rewarding and connected to the kingdom economy.

By the end of E2, the player should be able to:

1. Open the expanded world map.
2. Choose an unlocked adventure destination.
3. Inspect destination information.
4. Enter Iron Hills.
5. Explore a real mountain landscape.
6. Fight mountain enemies.
7. Collect legitimate mountain materials.
8. Return to the kingdom.
9. Unlock the Ashen Desert through real campaign conditions.
10. Enter the desert.
11. Navigate to an oasis.
12. Fight distinct desert enemies.
13. Collect a desert-exclusive material.
14. Return home with their loot.
15. Complete Realm Level 22.
16. Save and reopen with progress intact.

No fake playable regions.

No static concept images pretending to be gameplay.

No menu-only monster encounters.

---

# 2 — EXPANDED WORLD MAP

Extend the EXISTING world map.

Required destinations:

- Wildwood — existing adventure region
- Iron Hills — NEW playable adventure region
- Ashen Desert — NEW playable adventure region

The world map should show:

- Attractive regional artwork
- Region name
- Discovery status
- Unlock requirement
- Recommended hero level
- Difficulty indicator
- Available resource types
- Known hostile creatures
- Major landmarks
- Relevant quest objectives

Clearly distinguish:

TRADING DESTINATION

A strategic commercial location used by E1 caravans.

ADVENTURE DESTINATION

A real Godot scene that the hero can physically explore.

IMPORTANT:

The existing Iron Hills trading post must remain functional.

Do not rename the strategic route to imply that it is a playable adventure.

Do not break cargo reservations or existing caravan delivery logic.

The new Iron Hills playable region may visually reference the trading outpost, but must have its own actual navigation, collision, encounters and persistence.

---

# 3 — REGIONAL ADVENTURE ARCHITECTURE

Reuse the verified Milestone C Adventure Mode.

Prefer a reusable region-data and scene architecture.

Each region should define:

- Stable region ID
- Localized name
- Scene/resource reference
- Recommended level
- Unlock requirements
- Environment properties
- Spawn definitions
- Resource nodes
- Landmarks
- Active quest interactions
- Valid return points
- Persistent discovery state

Avoid duplicating entire combat systems per region.

Share:
- Hero controller
- Touch input
- Movement
- Dodge
- Health/damage
- Inventory
- Loot handling
- Enemy AI base
- Collision helpers
- HUD
- Return-to-kingdom transitions

Preserve region-specific mechanics through configuration and appropriate specialized scripts.

No unsafe dynamic script execution from downloaded or user-provided data.

---

# 4 — REGION ONE: IRON HILLS

Create a real playable mountain region.

VISUAL DESIGN:

- Rocky paths
- Iron-rich cliffs
- Small cave entrances
- Ancient mining structures
- Mountain vegetation
- Ore veins
- Abandoned mining equipment
- Cracked stone formations
- Warm torchlight near ruins
- Distant mist or subtle ambient effects

The region should feel like a forgotten mining territory.

### MOVEMENT

The hero must navigate:
- Narrow passages
- Rock formations
- Mining paths
- Small open combat areas

Implement real collision.

Prevent movement through rocks and walls.

Maintain readable camera boundaries.

### GATHERING

Create legitimate mineral nodes.

Example materials:
- Iron Ore
- Mountain Stone
- A small amount of special mountain mineral

Gathering must have:
- Visible interaction target
- Clear player feedback
- Real resource reward
- Appropriate interaction distance
- Capacity checks
- Resource conservation
- Defined depletion/respawn behavior
- Save/load consistency

Do not generate unlimited resources by repeatedly loading the same map.

Use a bounded, documented node refresh rule if gathering is repeatable.

Existing iron from mines and newly gathered iron should use the same legitimate economy where compatible.

### MONSTERS

Implement two distinct Iron Hills enemies:

STONE CRAWLER
- Slow armored enemy
- Melee attacks
- Moderate health
- Brief visible heavy-attack warning

CAVE STALKER
- Faster repositioning
- Lower armor
- Quick attack sequence
- Distinct movement behavior

Use real combat, collision, health and damage.

Create original usable sprites.

### LANDMARK

Implement one meaningful discovery:

THE FORGOTTEN MINE

The player can reach and inspect the landmark.

Discovery must be persistent.

Add a short historical entry to the existing world chronicle.

---

# 5 — REGION TWO: ASHEN DESERT

Create a real navigable desert adventure scene.

This is the main visual and narrative feature of E2.

ENVIRONMENT:

- Golden and reddish sand
- Ancient sandstone structures
- Broken pillars
- Desert rocks
- Small dunes
- Sparse vegetation
- A recognizable oasis
- Ancient road fragments
- Buried ruins
- Subtle drifting sand effects

The player should immediately recognize that this is a different region from Wildwood and Iron Hills.

### NAVIGATION

Implement:
- Playable paths
- Meaningful obstacles
- Collision
- Safe movement boundaries
- Adventure camera
- Hero interaction
- Exploration points
- Return interaction

Use genuine rendered environments rather than a static map background.

### OASIS

Create a discoverable oasis.

The oasis must have:
- Unique environment visuals
- Clear interaction point
- Persistent discovery
- Quest objective integration
- Small meaningful gameplay benefit

A limited hero recovery interaction is acceptable if balanced.

Do not grant unlimited consumables through repeated interaction or save/reload.

---

# 6 — DESERT MONSTERS

Create three distinct enemy archetypes.

## SAND STALKER

Behavior:
- Fast pursuit
- Short melee strike
- Brief disengagement or repositioning
- Low armor
- High mobility

Must behave differently from the Wildwood Wolf.

## DUNE SCORPION

Behavior:
- Armored movement
- Slow heavy attacks
- Clearly telegraphed sting
- Brief poison effect
- Vulnerability window after a missed attack

Poison must:
- Display an understandable status indicator.
- Have bounded duration.
- Stop when appropriate.
- Persist or clear consistently across region transitions and save/load.
- Never cause repeated or duplicate damage on the same simulation clock.

## RUIN SENTINEL

Behavior:
- Guards a specific ruin area
- Medium movement speed
- Telegraph-based ranged or area attack
- Returns to guard position when appropriate
- Drops ancient crafting materials

Use a distinct AI state machine.

Do not implement three enemies with identical behavior and different textures.

Each enemy must include:
- Original sprite
- Idle/movement/attack feedback
- Attack timing
- Hitboxes
- Health
- Damage
- Telegraph
- Defeat state
- Real loot drops
- Deterministic test support

Do not create new bosses yet.

Azrakh belongs to Milestone E5.

---

# 7 — REAL NEW RESOURCE MATERIALS

Introduce a small number of regional materials.

Recommended:

- Desert Crystal
- Scorpion Venom
- Sentinel Fragment

Avoid excessive item proliferation.

Every new resource must have:
- Stable item ID
- Category
- Inventory behavior
- Stack rules
- Description
- Legitimate acquisition source
- Defined consumer
- Save compatibility

At minimum, implement one real immediate use for an E2 material, such as a balanced desert-resistance consumable or simple forge upgrade supported by current systems.

Reserve major ancient artifact crafting for Milestone E3.

Do not add dozens of useless items solely to expand the catalog.

Protect required quest materials against accidental loss or provide a legitimate reacquisition route.

---

# 8 — MAIN QUEST 22: THE ASHEN DESERT

Create a real new main quest for Realm Level 22.

TITLE:
The Ashen Desert

QUEST FLOW:

1. Complete quest 21 through a real caravan trade.
2. Receive news of the newly discovered desert route.
3. Open the expanded world map.
4. Prepare the Warrior for the new region.
5. Unlock and enter the Ashen Desert.
6. Reach and discover the oasis.
7. Defeat an eligible desert enemy.
8. Collect a desert-exclusive material from the region.
9. Return safely to the home kingdom.
10. Deliver or register the legitimate material.
11. Complete the quest and award Realm XP.

Provide short Turkish and English narrative text.

All objectives must be event-driven.

Do not trigger monster-hunting progress using arbitrary quest-state setters.

Do not award resource-delivery progress from a previously owned unrelated item.

Do not allow a player to complete the quest solely by opening and closing the world map.

No duplicate rewards.

### QUEST GUIDANCE

Create working navigation actions:

- Open world map
- Highlight Ashen Desert
- Focus oasis objective where appropriate
- Highlight enemy encounter area
- Show return path
- Open resource inventory

When locked:
Clearly explain the missing prerequisite.

Use the existing advisor system.

Do not create duplicate tutorial frameworks.

---

# 9 — OPTIONAL EXPLORATION ACTIVITIES

Add a small number of optional objectives.

Examples:

IRON HILLS:
- Discover the Forgotten Mine.
- Gather mountain materials.
- Defeat a Cave Stalker.

ASHEN DESERT:
- Inspect ancient road fragments.
- Discover a hidden desert supply cache.
- Defeat a Ruin Sentinel.

These should provide:
- Modest legitimate rewards
- Chronicle entries
- Adventure variety

Do not turn E2 into a massive side-quest expansion.

Optional objectives must not block the main quest.

Do not create E3 relic quests prematurely.

---

# 10 — CONNECT REGIONS TO THE KINGDOM

The player should bring expedition resources back home.

Implement a coherent return flow:

Region exploration
→ Legitimate loot collection
→ Inventory or cargo ownership
→ Return to home kingdom
→ Resource availability
→ Existing crafting/industry consumer

Preserve existing ownership and transfer rules.

Never create a second incompatible inventory.

Never duplicate items while entering or exiting a region.

Do not reset the main planet when transitioning between scenes.

Preserve the existing pause/resume semantics for Adventure Mode.

Important existing behavior:
The home/offline simulation deliberately pauses in an active adventure.

Do not accidentally change this behavior while implementing additional regions.

The E1 caravan Live Route Watch uses a different intentional simulation rule.

Do not let scene transitions or world-map rendering break its clock behavior.

Document the final clock policy clearly.

---

# 11 — REGIONAL DIFFICULTY AND EQUIPMENT

Balance Iron Hills and Ashen Desert against the equipment available after Realm Level 21.

Do not require materials from E3, E4 or E5 to complete quest 22.

An appropriately equipped Warrior must have a legitimate path to victory.

The player should understand:
- Recommended hero strength
- Enemy risk
- Potion preparation
- Equipment comparison
- Difficulty differences

Do not overcomplicate the hero progression system.

Keep combat mobile-friendly.

Make dangerous enemy attacks readable and dodgeable.

Create clear failure and recovery behavior.

Do not permanently destroy the kingdom when the hero is defeated.

---

# 12 — MOBILE UX AND VISUAL POLISH

Improve the external world map and Adventure Mode.

Focus on:
- Regional map cards
- Visually distinct region previews
- Short unlock explanations
- Loading transitions
- Touch input responsiveness
- Attack button placement
- Dodge controls
- Status effects
- Loot notifications
- Resource gathering feedback
- Camera clamping
- World navigation
- Return-to-home interaction

Avoid UI overlap with:
- Health bar
- Quest tracker
- Inventory button
- Movement joystick
- Combat abilities

Support Android portrait orientation.

Maintain Turkish and English localization.

Keep explanations short.

The player should understand the first desert expedition without reading documentation.

---

# 13 — ORIGINAL ARTWORK

Create game-ready art assets.

IRON HILLS:
- Rock formations
- Ore veins
- Forgotten Mine
- Mountain paths
- Cave entrance
- Stone Crawler
- Cave Stalker

ASHEN DESERT:
- Desert terrain
- Sandstone ruins
- Oasis
- Ancient road
- Desert vegetation
- Sand Stalker
- Dune Scorpion
- Ruin Sentinel
- Desert Crystal node

UI:
- Region previews
- Exploration markers
- Discovery notifications
- Resource pickup effects
- Poison indicator
- Expedition result summary

Use image-generation tools when available.

Otherwise create original procedural/vector art.

Keep assets consistent with LittleGod.

No ripped commercial-game sprites.

No placeholder concept art substituted for playable scenes.

Inspect actual Godot renders.

---

# 14 — PERFORMANCE

Retain the E1 Android performance baseline as a reference:

60-cap live-route sample:
59.80 FPS / p95 19.38 ms

30-cap:
30.00 FPS / p95 34.88 ms

These measurements concern the E1 route-view scene, not the new adventure maps.

Do not falsely compare unlike scenes as equivalent benchmarks.

Measure the new regions separately.

Profile:
- Region initialization
- Scene construction
- Asset loading
- Enemy AI
- Collision updates
- Loot processing
- Status effects
- Camera movement
- Memory use
- Scene transition times
- Android FPS/frame times

Keep enemy populations bounded.

Reuse resources.

Cache static props where beneficial.

Avoid repeated expensive scene instantiation.

Preserve battery-saver behavior.

Do not claim real-phone performance based on an emulator.

---

# 15 — SAVE MIGRATION AND PROGRESSION

Extend the existing versioned save architecture.

Preserve all E1 and earlier data exactly unless a documented migration requires additions.

New persistent state should include:
- Region unlocks
- Region discoveries
- Completed landmarks
- Resource-node depletion or regeneration state
- Enemy reward tracking where required
- Poison/status-effect handling
- Quest 22 progress
- New materials
- Optional regional achievements

Make migrations idempotent.

Use authentic historical save fixtures.

Test:
- Milestone C saves
- D prerequisite saves
- E1 saves
- Pending caravans
- Pending craft jobs
- Unique boss loot
- Active and defeated heroes
- Inventory capacity
- Repeated offline processing

Do not reset active trade routes.

Do not replay quest 21 rewards.

Do not clear previous region discoveries.

Do not create invalid item owners.

---

# 16 — AUTOMATED TESTING

Run all 639 previously reported checks.

If the actual baseline differs, explain why before modifying or deleting anything.

Add tests for:
- E1 to E2 migration
- Quest 22 prerequisites
- Valid region unlocking
- Region navigation
- Iron Hills exploration
- Iron Hills resource gathering
- Resource-node depletion
- Depletion persistence
- Desert exploration
- Oasis discovery
- Enemy state machines
- Enemy attack telegraphs
- Scorpion poison
- Poison timing idempotency
- Real loot acquisition
- Inventory conservation
- Material ownership
- Region return transitions
- Home simulation pause
- Caravan route-watch clock independence
- Quest objective events
- Quest reward exactly-once behavior
- Save/load and legacy fixtures
- Multiple legal progression seeds

Run seeded legal campaign journeys from Level 1 through Level 22.

Use real building, worker, trading, exploration, combat and loot commands.

Do not inject XP or manually flip completion flags.

Use real rendered Godot playtests to verify:
- Hero movement
- Collision
- Resource interaction
- Combat damage
- Enemy attacks
- Poison effect
- Oasis interaction
- Return to kingdom

Retain all valid existing tests.

Never weaken assertions solely to obtain a green test count.

---

# 17 — ANDROID VERIFICATION

Build a dedicated Android QA version.

Test:
- Installation
- Startup
- Existing kingdom
- Existing Marketplace
- Existing caravan dispatch
- E1 pending-route restoration
- World map
- Iron Hills navigation
- Ashen Desert navigation
- Joystick movement
- Attack
- Dodge
- Poison/status indication
- Loot pickup
- Oasis discovery
- Return-to-home flow
- Quest 22 progression
- Save/relaunch restoration

Run actual input through the Android emulator where supported.

Do not count an engine-injected input as an external touchscreen verification.

Use disposable QA data.

Do not modify the real player's save slot.

Only report tests actually performed.

---

# 18 — IMPLEMENTATION SLICES

Complete E2 in verified submilestones.

## E2A — WORLD MAP FOUNDATION

- Verify E1 baseline.
- Add region data architecture.
- Expand world map.
- Preserve existing trade routes.
- Add region requirements.
- Implement region selection/entry.

Checkpoint after verification.

## E2B — IRON HILLS

- Build real Iron Hills scene.
- Add collision and navigation.
- Add resource nodes.
- Add two new enemy archetypes.
- Add Forgotten Mine discovery.
- Add safe return.

Run real rendered gameplay tests.

Checkpoint.

## E2C — ASHEN DESERT

- Build real desert scene.
- Add oasis.
- Add ancient road landmarks.
- Add three desert enemy archetypes.
- Add desert materials.
- Add combat and loot.
- Add return-to-kingdom transition.

Verify actual playable encounters.

Checkpoint.

## E2D — MAIN QUEST 22

- Implement campaign progression.
- Advisor guidance.
- Real oasis discovery tracking.
- Desert monster objective.
- Actual material acquisition.
- Real home return/delivery.
- Exactly-once completion reward.

Verify full legal progression.

Checkpoint.

## E2E — POLISH AND RELEASE

- Improve original artwork.
- Improve combat feedback.
- Fix camera/UI issues.
- Balance the new regions.
- Test migrations.
- Run complete regression suite.
- Profile Android scenes.
- Package final artifacts.
- Update documentation.

If execution limits prevent completion, leave the latest genuinely verified playable checkpoint and exact continuation instructions.

Do not falsely mark E2 complete.

---

# 19 — REQUIRED DELIVERABLES

When the complete E2 milestone has passed verification:

Create:
- Working desktop launcher
- LittleGod E2 Android debug APK
- Isolated QA APK
- Source archive
- Actual Iron Hills gameplay screenshots
- Actual Ashen Desert gameplay screenshots
- New enemy combat screenshots
- Oasis discovery screenshot
- Quest 22 completion screenshot
- Test results
- Android performance results
- Save migration report

Update:
- docs/STATUS.md
- docs/KNOWN_ISSUES.md
- MILESTONE_E_CONTINUATION.md

Create:
- AGE085_E2_REPORT.md
- REGIONAL_ADVENTURE_ARCHITECTURE.md
- REGIONAL_ENEMIES.md
- QUEST_22_DESIGN.md
- PERFORMANCE_MILESTONE_E2.md

Create verified Git checkpoint/tag:

age085-e2-regions

Only tag when E2 is fully verified.

Do not tag age085-milestone-e until E1–E6 are all complete.

Do not start LittleGod 0.9.

---

# 20 — FINAL ACCEPTANCE TEST

A legitimate player must be able to:

1. Continue their existing Level 21 kingdom.
2. Keep existing trade caravans and escorts intact.
3. Open the expanded world map.
4. Select Iron Hills.
5. Enter a real playable mountain region.
6. Walk around using actual movement controls.
7. Interact with a legitimate mineral node.
8. Obtain a real material reward.
9. Encounter and defeat a mountain monster.
10. Discover the Forgotten Mine.
11. Return home with preserved resources.
12. Unlock Ashen Desert.
13. Enter a real playable desert region.
14. Explore the environment.
15. Discover the oasis.
16. Defeat a desert monster using real combat.
17. Collect a legitimate desert material.
18. Return to the home kingdom.
19. Complete Quest 22 exactly once.
20. Save, close and reopen without losing world, trade, hero or expedition progress.

Do not claim completion unless these behaviors are implemented and verified.

## FINAL DIRECTIVE

LittleGod must now feel like a world larger than the player's home planet.

The mountains must be explorable.

The desert must be explorable.

Enemies must fight back.

Resources must be real.

Loot must have ownership and value.

Quest progress must follow real actions.

Existing trade, kingdom, military and crafting systems must continue working.

Make the adventure beautiful, coherent and smooth on Android.

START IMPLEMENTING E2 NOW.

DO NOT STOP AT PLANNING.

DO NOT START E3 UNTIL E2 IS VERIFIED.