# LITTLE GOD — AGE OF KINGDOMS
# MILESTONE E3: SECRETS OF THE ANCIENTS
# PLAYABLE ANCIENT DUNGEONS, ENVIRONMENTAL PUZZLES, ELITE ENEMIES, RARE LOOT, ARTIFACTS & ADVANCED EQUIPMENT

## MISSION

Continue developing the EXISTING LittleGod game.

PROJECT DIRECTORY:
D:\LittleGod

TARGET:
LittleGod 0.8.5 — Milestone E3

CAMPAIGN TARGET:
Realm Level 23

Your responsibility is to deliver a beautiful, genuinely playable ancient-ruins adventure connected to LittleGod's existing kingdom, hero, crafting, economy, quest and world-history systems.

You are acting as:
- Lead Game Designer
- Senior Godot Developer
- RPG Designer
- Dungeon Designer
- Combat Designer
- Quest Designer
- UI/UX Designer
- Technical Artist
- Animation Developer
- Game Balance Designer
- QA Engineer
- Android Performance Engineer

Use Codex, Godot MCP, Computer Use, terminal tools and available image-generation capabilities.

Do not stop after writing a development plan.

Implement real gameplay, visually inspect it, playtest it, fix bugs, balance progression and generate a working Android build.

Do not ask the user to manually create sprites, scenes, code or test fixtures.

Do not activate paid infrastructure.

Do not publish the game.

---

# 0 — AUDIT THE REAL CURRENT PROJECT

First inspect the actual repository and reports.

Previously verified checkpoints reported to the product owner:

- Milestone C: Realm Levels 1–15, 539 passing checks, playable Wildwood, Warrior, combat, boss, equipment and loot.
- Milestone D critical prerequisites: reported implemented during E1.
- Milestone E1: Realm Levels 1–21, 639 passing assertions, Marketplace, merchant jobs, caravans, trading routes and persistent cargo.
- Milestone E2: specification was supplied, but its implementation and verification have NOT yet been reported to the product owner.

Therefore, do not assume E2 is complete.

Before doing E3:

1. Inspect Git history, branches, checkpoints and tags.
2. Read docs/STATUS.md.
3. Read the latest E1 and E2 reports where available.
4. Inspect actual playable region scenes.
5. Verify whether Iron Hills and Ashen Desert have been implemented.
6. Verify regional combat, movement, harvesting and quests.
7. Verify Realm Level 22 is legally reachable.
8. Run the existing test suites.
9. Check save migration behavior.
10. Create a safe Git checkpoint.

If E2 is incomplete, finish its critical requirements first.

Do not claim that missing systems already exist.

Do not skip the verified playable-region foundation.

Preserve:
- Original planet and world simulation
- Citizen and worker identities
- Resources and production
- Military assignments
- Hero state and equipment
- Crafting and pending forge queues
- Merchant jobs
- Caravan cargo reservations
- Pending routes and escrow
- Existing world regions
- Previous boss rewards
- Inventory ownership
- Campaign progression
- Completed quest claims
- Existing save data
- Original artwork
- Localization
- Existing online code

Never recreate the project from scratch.

---

# 1 — CREATIVE VISION

The hero has reached the mysterious Ashen Desert.

Deep beneath its ruins lies evidence of an ancient civilization.

The kingdom's scholars discover that these people possessed unusual knowledge of metallurgy, crystals and lost mechanisms.

The player must investigate the ruins.

They will encounter:
- Forgotten corridors
- Ancient machinery
- Locked stone doors
- Hidden chambers
- Environmental hazards
- Elite guardians
- Rare materials
- A mysterious historical relic

This dungeon must feel like an actual adventure rather than an ordinary combat arena.

The player should experience:
- Curiosity
- Exploration
- Discovery
- Danger
- Puzzle solving
- Tactical combat
- Exciting rewards
- Meaningful kingdom progression

Every discovery should make the world feel older, larger and more mysterious.

---

# 2 — MAIN QUEST 23: RELICS OF THE ANCIENTS

Implement a new story chapter objective:

**RELICS OF THE ANCIENTS**

Required progression:

1. Complete Realm Level 22 legitimately.
2. Receive information about ancient ruins.
3. Open the world map.
4. Locate the ancient ruin entrance.
5. Prepare the hero.
6. Enter the playable dungeon.
7. Discover an ancient inscription.
8. Solve the first environmental mechanism.
9. Defeat an elite guardian.
10. Open the sealed relic chamber.
11. Recover the Ancient Sun Relic.
12. Escape or return safely.
13. Bring the relic to the kingdom.
14. Research or inspect the recovered artifact.
15. Use legitimate dungeon materials to craft one meaningful equipment upgrade.
16. Equip the item.
17. Complete Realm Level 23.
18. Unlock the narrative setup for Realm Level 24.

All objectives must be event-driven.

Opening an interface alone must not satisfy unrelated gameplay requirements.

An item already owned before the corresponding legitimate quest stage must not automatically replace a newly required discovery unless that behavior is explicitly designed and tested.

Quest rewards must be granted exactly once.

Support English and Turkish.

Keep instructions short and understandable.

---

# 3 — FIRST PROPER ANCIENT DUNGEON

Create a real playable dungeon called:

**THE SUNKEN SANCTUARY**

Location:
Ashen Desert.

The dungeon must be entered through an actual region interaction or a clearly connected adventure entrance.

Do not create a separate fake minigame unrelated to Adventure Mode.

Use the existing:
- Warrior controller
- Movement system
- Touch controls
- Combat engine
- Dodge mechanics
- Health and healing
- Loot system
- Inventory
- Equipment
- Save architecture

Create a cohesive dungeon with at least five meaningful interconnected spaces.

## ROOM 1 — THE FORGOTTEN ENTRANCE

Purpose:
Introduce the dungeon atmosphere.

Include:
- Ancient stone structures
- Torches or magical light
- Environmental storytelling
- Readable navigation
- A discoverable inscription
- A clearly visible path forward

The inscription must create a persistent discovery record.

## ROOM 2 — THE TRIAL OF STONE

Purpose:
Introduce environmental interaction.

Include:
- Pressure plates
- A sealed door
- Clear puzzle feedback
- A logical solution
- Successful door-opening animation

The puzzle must be genuinely functional.

The door must not open merely because the player waits.

Provide a contextual hint if the player struggles.

## ROOM 3 — THE HALL OF GUARDIANS

Purpose:
Introduce difficult combat.

Include:
- Distinct arena shape
- Environmental obstacles
- Elite enemies
- Telegraph-based attacks
- Legitimate combat rewards

Combat must use real damage and hit detection.

## ROOM 4 — THE HIDDEN TREASURY

Purpose:
Reward exploration.

Include:
- Optional secret path
- Discoverable chest
- Rare crafting material
- Small historical discovery
- A visually satisfying reward moment

The room should be optional but rewarding.

Players must not be forced to know a hidden trick to finish the main quest.

## ROOM 5 — THE SUN RELIC CHAMBER

Purpose:
Main story conclusion.

Include:
- Memorable room artwork
- Central ancient mechanism
- Final guardian challenge
- Unlockable relic chamber
- Actual unique artifact interaction
- Completion sequence
- Safe return to kingdom

Do not introduce the major Desert Sovereign boss here.

Azrakh belongs to E5.

E3's final guardian should be an elite encounter, not a replacement for the E5 regional boss.

---

# 4 — ENVIRONMENTAL PUZZLE ENGINE

Build reusable puzzle foundations.

Puzzle types:
- Pressure plates
- Ordered switches
- Locked doors
- Triggered mechanisms
- Hidden pathways

Implement at least two distinct complete puzzle interactions.

Each puzzle should have:
- Stable unique ID
- Activation rules
- Clear visual state
- Correct completion condition
- Feedback for invalid actions
- Persistence behavior
- Reset/retry logic where appropriate

Do not use random puzzle solutions that may become impossible.

Make puzzles understandable through environmental clues.

Keep interaction touch-friendly.

No tiny precision clicking.

No long text-only riddles.

### ANTI-SOFTLOCK REQUIREMENT

A player must never become permanently trapped because:
- A door closes at the wrong time.
- An enemy blocks a switch.
- A puzzle resets incorrectly.
- A saved game restores an impossible puzzle state.
- A required item is consumed prematurely.

Provide a safe return or recovery path.

Test interrupted puzzles and save/load.

---

# 5 — ENVIRONMENTAL HAZARDS

Add readable dungeon hazards.

Examples:
- Spike traps
- Falling stone warning zones
- Magical floor runes
- Timed flame vents

Implement at least two.

Requirements:
- Clear warning.
- Fair activation timing.
- Actual damage or status effect.
- Real dodge/counterplay.
- Safe recovery windows.
- Proper collision and hit detection.
- Correct cooldown behavior.
- Save/load consistency.

Avoid invisible damage sources.

Avoid unavoidable damage loops.

The player must understand why they were hit.

---

# 6 — ELITE ENEMIES

Create at least two distinct dungeon enemies.

## ANCIENT SENTINEL

A heavily armored guardian.

Behavior:
- Patrols or guards a defined area.
- Detects the hero.
- Performs a slow frontal strike.
- Uses a telegraphed defensive counterattack.
- Has recognizable openings for attacks.

## SUN PRIEST'S SHADE

A magical remnant of the ancient civilization.

Behavior:
- Maintains distance.
- Fires a telegraphed magical projectile.
- Occasionally relocates.
- Uses a short area denial ability.
- Becomes vulnerable after completing an attack pattern.

Both enemies must have:
- Original game-ready artwork
- Distinct behavior
- Real movement
- Health
- Combat statistics
- Attacks
- Collision
- Animation feedback
- Loot tables
- Defeat effects

Do not reuse an existing enemy AI unchanged and only recolor its sprite.

Reuse common combat infrastructure appropriately.

---

# 7 — FINAL ELITE ENCOUNTER

Create a dungeon finale enemy:

**THE SUNWARD WARDEN**

This is an elite guardian, not the Desert Sovereign boss.

Use a compact but memorable encounter.

Mechanics:
- A heavy melee strike
- A directional energy attack
- A shielded phase or timed vulnerability window
- Clear attack telegraphs
- Distinct defeat feedback

The encounter should test what the player learned:
- Movement
- Dodge
- Target selection
- Equipment preparation
- Reading attack warnings

Defeating the Warden must unlock the relic chamber through actual game state.

Do not use a scripted animation as proof of combat.

---

# 8 — THE ANCIENT SUN RELIC

Introduce one unique story artifact:

**ANCIENT SUN RELIC**

It should have:
- Stable unique item ID
- Beautiful icon
- Localized description
- Lore
- Explicit quest association
- Ownership rules
- Unique reward behavior
- Chronicle entry

The relic must be obtained through actual interaction in the completed dungeon.

Do not generate multiple identical unique relics through repeated chest opening, entering/exiting or loading.

The relic should unlock meaningful progression.

Possible uses:
- An advanced forge recipe
- A temporary environmental blessing
- A future research prerequisite
- A significant kingdom chronicle discovery

For E3, implement at least one actual usable benefit.

Do not make it merely a decorative inventory entry.

Preserve a sensible path for later E4/E5 expansions.

---

# 9 — ADVANCED CRAFTING AND EQUIPMENT

Extend the EXISTING industry and forge.

Do not create an unrelated crafting system.

Add a small catalog of meaningful equipment.

Suggested examples:

## ANCIENT IRON BLADE

Requires:
- Legitimate refined metal
- Dungeon alloy material
- Real forge work

Effect:
- Improves actual melee combat effectiveness.

## SUNGUARD SHIELD

Requires:
- Legitimate existing kingdom materials
- Dungeon guardian material

Effect:
- Provides actual defensive value.
- May grant a small timed combat benefit after a successful defensive action if the existing combat architecture supports it.

## RUINWALKER ARMOR

Requires:
- Legitimate metal
- Leather
- Ruins material

Effect:
- Improves survivability against one defined hazard type or damage category.

## SUNSTONE TALISMAN

Requires:
- Relic-related material
- Crafting prerequisites

Effect:
- Grants one modest, clearly described and tested ability enhancement or resistance.

Do not create four functionally identical items.

Each item must have real value.

### EQUIPMENT SPECIAL EFFECT SYSTEM

Create a small maintainable equipment modifier architecture.

Examples:
- Bonus attack
- Bonus defense
- Hazard resistance
- Cooldown modifier
- Limited on-hit effect

Keep effects deterministic and safe.

Avoid uncontrolled effect stacking.

Prevent infinite loops between triggered effects.

Ensure UI descriptions match actual code behavior.

Do not build a huge generic MMORPG item engine unnecessarily.

---

# 10 — MATERIAL AND INVENTORY INTEGRITY

Add a concise set of new crafting materials, such as:
- Ancient Alloy
- Sunstone Fragment
- Sentinel Core
- Inscribed Tablet

Every material needs a real source and consumer.

The existing 32-item inventory constraint must be inspected.

Use any valid storage or salvage extensions already introduced in D/E1.

If necessary, improve storage access without destroying existing ownership rules.

Protect:
- Equipped items
- Civilian tools
- Military equipment
- Unique artifacts
- Quest-critical items
- Pending forge job ingredients
- Caravan cargo

Avoid silent item deletion.

Prevent:
- Duplicate pickups
- Duplicate chest rewards
- Repeatable unique artifact creation
- Material multiplication through save/load
- Negative resource balances
- Missing item ownership
- Consuming ingredients without producing the expected output

Use the established exact-once reward rules.

---

# 11 — SECRET ROOMS AND DISCOVERY

Exploration must be rewarding.

Implement at least:
- One optional hidden passage.
- One secret treasure location.
- Two lore discoveries.
- One unique chamber discovery.

Use subtle environmental clues:
- Cracked walls
- Unusual symbols
- Light from hidden openings
- Ancient inscriptions

Avoid forcing players to randomly tap every wall.

A secret should feel discoverable.

When found:
- Display an attractive discovery notification.
- Record the discovery persistently.
- Award legitimate collectible progress.
- Add an entry to the existing World Chronicle.

Do not fabricate discoveries in offline summaries.

---

# 12 — WORLD HISTORY AND ANCIENT CIVILIZATION

The ancient ruins should establish a coherent historical mystery.

Create a short lore foundation.

Suggested ancient civilization:

**THE SUNFORGED DYNASTY**

They once controlled advanced metallurgy and mysterious light-powered mechanisms.

Their civilization disappeared after an unknown catastrophe.

Create lore through actual environmental discoveries.

Do not rely on long unskippable text.

Examples:
- Inscribed tablets
- Abandoned forge remains
- Broken royal symbols
- A damaged mechanical guardian
- The sealed Sun Relic

The player should gradually uncover a mystery that can continue into E4, E5 and the final ancient-throne storyline.

Keep descriptions concise.

Use English and Turkish localization.

---

# 13 — QUEST AND PLAYER GUIDANCE

Extend the existing advisor system.

Do not duplicate tutorial logic.

Required guidance:
- How to enter ruins.
- How switches and mechanisms work.
- How to identify hazards.
- How to approach elite enemies.
- How to inspect rare loot.
- How to bring the relic home.
- How to craft advanced equipment.
- How to equip the new item.

Example short hints:

"These stones react to pressure. Try activating them in the order shown on the wall."

"Red markings signal a trap. Move away before it activates."

"The ancient guardian is heavily armored. Dodge its heavy strike before counterattacking."

"You found Ancient Alloy. Your blacksmith may know how to use it."

"Bring the relic home to uncover its purpose."

Create working navigation actions for:
- Dungeon entrance
- Active quest objective
- Inventory
- Forge
- Equipment
- World map
- Return to kingdom

All guidance must be contextual and dismissible.

Do not interrupt combat with long messages.

---

# 14 — MOBILE DUNGEON UI

Design an interface suitable for portrait Android devices.

Display:
- Hero health
- Compact objective
- Movement controls
- Attack
- Dodge
- Special skill
- Consumable
- Interact
- Pause
- Return or retreat
- Inventory access

When approaching puzzle objects, show a contextual interaction control.

Avoid overlapping buttons.

Ensure enemy warnings remain visible.

Do not hide the hero behind large visual effects.

Add appropriate camera constraints.

Improve movement readability in narrow corridors.

Provide clear exit paths.

Preserve existing desktop controls.

---

# 15 — ORIGINAL VISUAL ART

Create high-quality original game assets.

ENVIRONMENTS:
- Ancient sandstone corridor
- Inscribed entrance
- Guardian chamber
- Hidden treasury
- Sun Relic chamber
- Broken pillars
- Pressure plates
- Sealed stone doors
- Wall symbols
- Ancient mechanisms

ENEMIES:
- Ancient Sentinel
- Sun Priest's Shade
- Sunward Warden

ITEMS:
- Ancient Sun Relic
- Ancient Alloy
- Sunstone Fragment
- Sentinel Core
- Ancient Iron Blade
- Sunguard Shield
- Ruinwalker Armor
- Sunstone Talisman

VISUAL EFFECTS:
- Opening doors
- Activated pressure plates
- Magical runes
- Trap warnings
- Guardian attacks
- Rare loot pickups
- Relic discovery
- Equipment crafting
- Quest completion

Use available original image-generation tools where appropriate.

Otherwise use original procedural/vector assets.

Ensure all artwork is integrated into actual Godot scenes.

Do not replace playable content with static screenshots.

Inspect real rendered gameplay.

---

# 16 — SOUND AND GAME FEEL

Add appropriate feedback for:
- Footsteps on ancient stone
- Puzzle interaction
- Switch activation
- Door opening
- Trap warning
- Trap activation
- Enemy attacks
- Successful hits
- Loot discovery
- Secret room discovery
- Relic acquisition
- New equipment crafting

Use original or properly licensed sound assets if available.

If unavailable, use safe generated audio where feasible and report any gaps.

Respect sound settings.

Avoid irritating repeated audio.

---

# 17 — GAME BALANCE

Balance E3 against actual equipment and materials available by Realm Level 23.

Do not require:
- Future E4 outpost materials
- Future E5 boss artifacts
- Locked Level 24–30 equipment
- Impossible worker counts
- Unavailable resource deposits

A legitimate Level 23 Warrior must be able to complete the dungeon with appropriately available gear.

Avoid unavoidable damage.

Make rare materials valuable without requiring excessive repetitive farming.

Provide a reasonable recovery path if the player loses.

No permanent quest deadlocks.

### ECONOMY CONNECTION

A legitimate player should be able to:

Explore dungeon
→ Defeat elite enemies
→ Collect actual materials
→ Return to kingdom
→ Use staffed forge
→ Complete a legitimate crafting job
→ Equip an advanced item
→ Experience real combat improvements.

Validate the entire loop.

---

# 18 — SAVE/LOAD AND STATE MIGRATION

Extend the existing versioned save architecture.

Persist:
- Quest 23 state
- Dungeon unlocks
- Dungeon progress
- Puzzle completion
- Door state
- Discoveries
- Treasure claim history
- Unique relic ownership
- Elite encounter state
- New equipment
- Crafting progress
- World chronicle entries

Define what is restored inside the dungeon after reopening the app.

If an active dungeon run is not fully resumable, provide a safe explicit return/re-entry policy that preserves committed rewards and never duplicates claims.

Never silently reset committed unique discoveries.

Maintain existing home/adventure simulation clock semantics.

Preserve E1 caravan clocks and escrow.

Preserve existing military state and crafting queues.

Old saves must migrate without replaying prior quest rewards.

Use authentic historical fixtures.

Test idempotent migration.

---

# 19 — AUTOMATED TESTS

Run all current existing legitimate tests.

Do not assume a fixed test count if E2 added new tests.

Add new tests for:
- E2 to E3 migration
- Quest 23 prerequisites
- Dungeon entry
- Valid room transitions
- Puzzle completion
- Invalid puzzle actions
- Door state persistence
- Anti-softlock recovery
- Trap telegraphs
- Trap damage
- Dodge interaction
- Elite AI
- Elite attack states
- Final guardian defeat
- Secret-room discovery
- Treasure exact-once claims
- Unique relic ownership
- Item capacity
- Material conservation
- Equipment effects
- Combat modifier stacking
- Forge recipe costs
- Craft queue restoration
- Quest completion
- Chronicle persistence
- Repeatable dungeon entry
- Save/load during a dungeon
- Android lifecycle
- Historical save compatibility

Run legal seeded progression from Realm Level 1 through Level 23.

Use real gameplay and simulation commands.

Do not force XP, create free materials or manually set quest completion flags.

Negative tests may construct invalid data and must be clearly labeled.

Create actual rendered dungeon tests.

Verify real:
- Movement
- Collision
- Switch activation
- Door opening
- Enemy attacks
- Trap warnings
- Damage
- Treasure pickup
- Relic acquisition
- Kingdom return

Maintain all existing valid regressions.

---

# 20 — PERFORMANCE

Profile E3 independently.

Measure:
- Dungeon scene load
- Room transitions
- Static geometry
- Dynamic lighting
- Puzzle updates
- Enemy AI
- Combat
- Particle effects
- Loot
- Memory usage
- Android FPS
- Frame-time percentiles

Avoid expensive light/shadow effects that severely degrade mobile performance.

Cache static geometry when beneficial.

Use bounded enemy counts.

Do not instantiate unnecessarily heavy objects each frame.

Preserve normal and battery-saver modes.

Do not claim physical-device measurements without a connected physical device.

Distinguish desktop, emulator and real-phone measurements.

---

# 21 — ANDROID VALIDATION

Build an isolated Android QA package.

Verify:
1. Installation
2. Startup
3. Existing kingdom
4. Existing caravans
5. Existing adventure regions
6. Dungeon selection
7. Dungeon entry
8. Touch movement
9. Puzzle controls
10. Trap avoidance
11. Elite combat
12. Treasure collection
13. Warden encounter
14. Relic acquisition
15. Return to kingdom
16. Advanced crafting
17. Equipment activation
18. Save and reopen
19. Quest completion
20. Battery-saver behavior

Use actual ADB interaction where supported.

Distinguish engine-injected controls from external Android input.

Protect real player saves.

Do not disable security protections.

---

# 22 — IMPLEMENTATION ORDER

Follow these verified development slices.

## E3A — DUNGEON FOUNDATION

- Audit E2.
- Validate Level 22.
- Create dungeon data architecture.
- Implement dungeon entrance.
- Build connected rooms.
- Implement movement and camera.
- Safe dungeon exit.

Run rendered tests and checkpoint.

## E3B — PUZZLES AND HAZARDS

- Pressure plates.
- Mechanisms.
- Sealed doors.
- Two actual puzzle interactions.
- Two real hazards.
- Anti-softlock handling.
- Persistent state.

Run rendered tests and checkpoint.

## E3C — ELITE COMBAT

- Ancient Sentinel.
- Sun Priest's Shade.
- Elite AI patterns.
- Distinct attacks.
- Real combat.
- Loot tables.
- Sunward Warden encounter.

Run rendered combat verification and checkpoint.

## E3D — RELIC AND HISTORY

- Secret room.
- Treasure.
- Lore discoveries.
- Relic chamber.
- Unique Sun Relic.
- Chronicle integration.
- Exactly-once claim logic.

Run save/restore tests and checkpoint.

## E3E — CRAFTING AND QUEST 23

- Advanced materials.
- Combat equipment recipes.
- Real stat/effect consumers.
- Forging.
- Hero equipment integration.
- Quest 23 objectives.
- Level 23 completion.

Verify legitimate complete gameplay.

Checkpoint.

## E3F — POLISH AND RELEASE

- Original artwork.
- Animations.
- Sound.
- Contextual guidance.
- Touch usability.
- Economy balance.
- Save compatibility.
- Android tests.
- Performance optimization.
- Full regression suite.
- Documentation.
- Source archive.

Do not start E4 until E3 is verified.

If execution limits interrupt work, leave a fully tested intermediate checkpoint and exact continuation instructions.

Do not falsely label partial E3 work as complete.

---

# 23 — DEFINITION OF DONE

A legitimate player must be able to:

1. Continue their existing LittleGod kingdom.
2. Preserve all previous quests and items.
3. Finish Level 22.
4. Unlock the ancient ruins.
5. Enter a real playable dungeon.
6. Move through several connected chambers.
7. Activate pressure plates.
8. Open a locked door.
9. Avoid actual traps.
10. Fight an elite enemy that attacks back.
11. Discover a secret chamber.
12. Claim valid treasure once.
13. Reach the relic chamber.
14. Defeat the Sunward Warden.
15. Recover the Ancient Sun Relic.
16. Return to the kingdom.
17. Bring dungeon materials to the forge.
18. Craft an advanced item with actual materials.
19. Equip it.
20. Observe its real mechanical effect.
21. Complete Realm Level 23.
22. Save, quit and reopen without losing progress.
23. Revisit the dungeon without duplicating unique rewards.

All earlier game features must remain functional.

No placeholder dungeon.

No fake puzzle.

No simulated text-only combat.

No decorative-only equipment bonuses.

---

# 24 — FINAL RELEASE

Once ALL E3 core requirements are implemented and verified:

Produce:
- Updated desktop launcher
- LittleGod E3 Android debug APK
- Isolated Android QA APK
- Source archive
- Actual dungeon screenshots
- Puzzle screenshots
- Elite combat screenshots
- Secret room screenshot
- Sun Relic discovery screenshot
- Advanced forging screenshot
- Quest 23 completion screenshot
- Performance results
- Regression test results
- Save migration report

Update:
- docs/STATUS.md
- docs/KNOWN_ISSUES.md
- MILESTONE_E_CONTINUATION.md

Create:
- AGE085_E3_REPORT.md
- DUNGEON_ARCHITECTURE.md
- DUNGEON_PUZZLES.md
- ANCIENT_CIVILIZATION_LORE.md
- EQUIPMENT_EFFECTS.md
- QUEST_23_DESIGN.md
- PERFORMANCE_MILESTONE_E3.md

Create Git checkpoint/tag:

age085-e3-ancients

Only tag when E3 is fully verified.

Do not create age085-milestone-e until E1–E6 are complete.

Do not tag littlegod-0.9 or 1.0.

Clearly report:
- Features implemented
- Existing tests preserved
- New tests passing
- Legal progression results
- Real rendered gameplay evidence
- Android test results
- Performance measurements
- Known issues
- Save compatibility
- Remaining E4/E5/E6 requirements

Do not claim success for untested features.

---

# FINAL DIRECTIVE

Make the player's next adventure feel mysterious, dangerous and rewarding.

The dungeon must be genuinely explorable.

The puzzles must work.

The traps must be avoidable.

The guardians must fight back.

The hidden chambers must reward curiosity.

The relic must have legitimate ownership and progression meaning.

The new equipment must actually improve combat.

The quest must guide the player naturally.

The entire experience must remain enjoyable on Android.

Continue the verified existing project.

Preserve everything already completed.

Build and verify LittleGod 0.8.5 E3.

DO NOT STOP AT PLANNING.

DO NOT START E4 UNTIL E3 IS VERIFIED.

START IMPLEMENTING NOW.