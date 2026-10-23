# LITTLE GOD — AGE OF KINGDOMS
# MILESTONE E: THE FORGOTTEN REALMS
# TRADE, CARAVANS, NEW REGIONS, RESOURCE OUTPOSTS, MONSTERS, EXPEDITIONS, RARE LOOT & THE DESERT SOVEREIGN

## MISSION

Continue developing the existing LittleGod project.

PROJECT DIRECTORY:
D:\LittleGod

TARGET RELEASE:
LittleGod 0.8.5 — Milestone E

CAMPAIGN TARGET:
Realm Levels 21–25

You are acting as a complete autonomous development studio responsible for:
- Game design
- Quest and narrative design
- Godot development
- Exploration systems
- Resource economy
- Trading and caravans
- Worker and military integration
- Combat and boss design
- Loot and crafting
- Original artwork and animation
- Mobile UI/UX
- Automated testing
- Performance optimization
- Android packaging

Use Codex, Godot MCP, Computer Use, terminal tools and available image-generation capabilities.

DO NOT STOP AFTER PLANNING.

Implement, launch, inspect, test, debug, polish and package the actual playable game.

Make reasonable technical and creative decisions autonomously.

Do not require the user to manually write code, draw sprites, build scenes or perform ordinary development tasks.

Do not purchase infrastructure, activate paid services or publish the game.

---

# 0 — VERIFY THE ACTUAL DEVELOPMENT STATE

Before changing code:

1. Inspect the current branch, Git history, tags and working tree.
2. Read docs/STATUS.md and the latest milestone reports.
3. Run the currently documented game test suites.
4. Confirm whether Milestone D is genuinely complete.
5. Verify the existing hero/adventure system.
6. Verify combat, equipment, loot and crafting.
7. Verify the real military system if present.
8. Verify Realm Levels 1–20 are reachable through legal actions.
9. Inspect existing save migrations and item ownership rules.
10. Create a safe Git checkpoint.

Previously verified Milestone C baseline:
- Realm Levels 1–15
- 539 passing game checks
- Real Warrior hero
- Playable Wildwood
- Three hostile species
- Thornheart boss
- Persistent loot
- Worker-driven combat crafting
- Android emulator validation

Milestone D was subsequently requested but its completion has NOT been independently established by this instruction.

Do not assume the Army, Barracks, Formation, Defense or Raid systems exist merely because previous prompts requested them.

If Milestone D is incomplete, complete its critical requirements before implementing Milestone E.

Do not duplicate existing systems.

Preserve all earlier saves, artwork, tests, gameplay and online source code.

Do not begin 0.9 development.

---

# 1 — MAIN CREATIVE VISION

The player's kingdom has survived its first dangerous encounters and learned to protect itself.

But the world beyond the kingdom is much larger.

Merchants bring rumors of ancient cities.

Scouts discover roads leading to distant mountains and deserts.

Travelers report mysterious ores and valuable relics.

Unknown monsters attack remote settlements.

The player must:
- Establish trade.
- Explore new regions.
- Secure resources.
- Organize expeditions.
- Protect caravans.
- Build frontier outposts.
- Craft advanced equipment.
- Uncover an ancient civilization.
- Defeat a powerful desert guardian.

This expansion must connect the kingdom economy, hero RPG gameplay and military systems.

Do not create unrelated decorative menus.

The game should feel like a growing, interconnected fantasy world.

---

# 2 — CHAPTER V: THE EXPANDING REALM

Implement five meaningful main quests.

## LEVEL 21 — THE FIRST TRADE ROAD

Story:
Traveling merchants arrive near the kingdom.

Objectives:
1. Construct a Marketplace.
2. Assign an available citizen as a Merchant.
3. Inspect regional trade prices.
4. Prepare legitimate export goods.
5. Create a caravan.
6. Send the caravan to a reachable trade destination.
7. Receive actual goods or currency upon its successful return.

Rewards:
- Realm XP.
- Trade route access.
- Improved commercial opportunities.

Requirements:
The caravan must actually consume and transport inventory/resources.

Do not complete the quest through a button that fabricates a successful trade.

## LEVEL 22 — THE ASHEN DESERT

Story:
A caravan discovers an ancient route leading toward an unusual desert.

Objectives:
1. Unlock the Ashen Desert route.
2. Prepare an expedition.
3. Travel to a real playable desert scene.
4. Discover the first oasis or landmark.
5. Fight at least one new desert enemy.
6. Gather a desert-exclusive material.
7. Return safely.

Rewards:
- Realm XP.
- New crafting materials.
- Access to additional desert discoveries.

## LEVEL 23 — RELICS OF THE ANCIENTS

Story:
A broken tablet reveals the location of forgotten ruins.

Objectives:
1. Discover the ancient ruins.
2. Enter the playable ruins area.
3. Overcome enemies or environmental obstacles.
4. Recover a historical relic.
5. Gather the required crafting materials.
6. Produce a meaningful equipment upgrade.
7. Record the discovery in the Planet Chronicle.

Rewards:
- Realm XP.
- Ancient crafting knowledge.
- Rare equipment recipe.

## LEVEL 24 — THE FRONTIER OUTPOST

Story:
The kingdom must secure resources in a dangerous external region.

Objectives:
1. Claim a valid frontier site.
2. Construct a mining or supply outpost.
3. Assign eligible workers.
4. Assign soldiers or guards.
5. Establish a supply route.
6. Produce and transport real resources.
7. Resolve an actual regional threat.

Rewards:
- Realm XP.
- Frontier production improvements.
- Better expedition readiness.

## LEVEL 25 — THE DESERT SOVEREIGN

Story:
An ancient ruler or guardian has awakened beneath the sands.

Objectives:
1. Discover the final desert temple.
2. Prepare appropriate equipment.
3. Enter the actual boss arena.
4. Survive the boss's distinct attack patterns.
5. Defeat the Desert Sovereign through real combat.
6. Claim its unique artifact.
7. Return to the kingdom.
8. Record the victory.
9. Unlock the next campaign chapter.

Rewards:
- Realm XP.
- Unique boss artifact.
- New advanced military or exploration research.
- Permanent historical milestone.

All objectives must be event-driven and persist correctly.

Quest rewards must be exactly-once.

No forced XP, fake resource injection or menu-only quest completion.

---

# 3 — THE WORLD MAP EXPANSION

Expand the existing Adventure Mode world map.

The player should now see a larger world with multiple accessible destinations.

Required regions:

## WILDWOOD

Existing region.

Preserve all previously implemented functionality.

Do not regress original enemies, loot, quests or boss encounters.

## IRON HILLS

A rocky mountainous region.

Content:
- Mining deposits.
- Caves.
- Stone formations.
- Dangerous mountain creatures.
- Useful ores.
- Military supply opportunities.
- Optional exploration objectives.

## ASHEN DESERT

An ancient desert region.

Content:
- Sandstone ruins.
- Oasis.
- Abandoned roads.
- Desert creatures.
- Rare crystals.
- Archaeological discoveries.
- Ancient temple.
- Regional boss.

Implement real navigable environments.

Use existing Adventure Mode architecture.

Do not create static concept-art screens pretending to be playable locations.

Each region must have a distinct visual identity.

---

# 4 — REGIONAL TRAVEL

Build a consistent regional travel system.

Required properties:
- Destination
- Unlock condition
- Recommended hero level
- Travel requirements
- Region resources
- Known enemies
- Exploration progress
- Discovery records

The player must be able to:
- Select a destination.
- Inspect requirements.
- Start an expedition.
- Enter the actual scene.
- Explore.
- Fight.
- Gather resources.
- Return home.

Prevent travel to locked regions.

Travel must not reset existing worlds.

Adventure and kingdom state must remain consistent.

Explicitly define whether home simulation is paused or advances while exploring.

Preserve the existing Milestone C semantics unless a carefully tested design change is justified.

---

# 5 — TRADE ECONOMY

Create a real in-game trade system.

The player should be able to:
- Buy resources.
- Sell resources.
- Establish trade routes.
- Compare regional prices.
- Assign merchants.
- Send caravans.
- Inspect trade history.

Start with the existing resource economy.

Do not add unnecessary currencies.

Use existing Gold if it genuinely exists.

Otherwise introduce one narrowly scoped, correctly migrated trade currency with clear sources and sinks.

### EXAMPLE TRADE GOODS

- Food
- Wood
- Stone
- Iron Ore
- Refined Iron
- Leather
- Herbs
- Rare Minerals

Not every resource must be tradable.

Quest and unique artifacts should be protected from accidental sale.

### TRADE RULES

- Validate inventory.
- Reserve goods atomically.
- Deduct agreed costs.
- Account for caravan capacity.
- Use real route constraints.
- Deliver goods only after legitimate completion.
- Record completed trades.
- Prevent replay and duplication.
- Preserve pending caravans through save/load.
- Reject invalid quantities.
- Prevent negative balances.
- Prevent buy/sell loops that create infinite currency.

Trade prices must be balanced against gathering, crafting and quest progression.

Avoid hard-coded arbitrage exploits.

---

# 6 — REAL CARAVANS

Implement an actual persistent caravan system.

Caravan state:
- Unique ID
- Origin
- Destination
- Assigned merchant
- Assigned guards
- Cargo
- Capacity
- Supplies
- Departure time
- Travel progress
- Risk conditions
- Arrival state
- Return state
- Rewards or losses

Players should be able to:
1. Assemble a caravan.
2. Select its cargo.
3. Assign a merchant.
4. Assign an escort.
5. Choose the destination.
6. Review expected risk.
7. Confirm departure.
8. Monitor the route.
9. Receive a legitimate arrival or threat event.
10. Collect completed deliveries.

### VISUAL REQUIREMENTS

Create a charming caravan representation.

Include:
- Merchant
- Wagon or pack animal
- Cargo
- Travel animation
- Road indicators
- Destination feedback

Where a route is visible, animate its progress.

Where a route is too large to simulate physically, use a valid bounded abstract travel model with honest UI representation.

Do not claim a full moving-world simulation when it is only a strategic travel model.

---

# 7 — CARAVAN PROTECTION AND RISK

Integrate existing army systems if verified.

Caravan safety should depend on:
- Route danger.
- Escort strength.
- Supplies.
- Regional hostility.
- Travel distance.
- Relevant research or buildings.

Possible encounters:
- Bandits
- Wild animals
- Desert raiders
- Road hazards

When an encounter occurs, offer an appropriate interaction:
- Resolve with the allocated escort simulation.
- Retreat or reroute where valid.
- Enter a playable encounter if the existing battle system supports it.

Do not generate fake battles or imaginary casualties.

Do not allow the player to exploit repeated load/retry for endless loot.

Use deterministic seeded outcomes where appropriate.

Major destructive encounters should not automatically wipe player progress during an offline absence.

---

# 8 — FRONTIER OUTPOSTS

Introduce small external outposts.

The player should be able to establish an outpost at a valid discovered site.

Outpost functions:
- Mining
- Resource storage
- Guard station
- Expedition supply
- Regional trading support

Requirements:
- Legitimate construction costs.
- Valid location.
- Workers.
- Resource deposits.
- Storage.
- Optional military protection.
- Supply route.

Outposts must produce actual resources based on assigned workers and available deposits.

Avoid infinite resource generation.

### OUTPOST PROGRESSION

Level 1:
Basic camp and storage.

Level 2:
Improved resource production.

Level 3:
Fortified outpost with better defenses.

At least one outpost must be fully playable through its required level for the main quest.

Additional upgrades may be limited to the same tested architecture.

Visually show the outpost becoming more developed.

---

# 9 — WORKERS AND RESOURCE PRODUCTION

Reuse the existing worker system.

Add relevant frontier jobs:
- Caravan Merchant
- Caravan Guard
- Outpost Miner
- Outpost Supply Worker

Prevent a citizen from working in two incompatible locations simultaneously.

Maintain:
- Population conservation.
- Worker ownership.
- Building capacity.
- Valid assignments.
- Actual production prerequisites.
- Resource depletion or bounded deposits.
- Upkeep.
- Save compatibility.

Workers should contribute visibly where supported.

The player must understand production rates and deficits.

---

# 10 — NEW DESERT MONSTERS

Create new enemies with distinct combat mechanics.

Implement at least three meaningful enemy archetypes.

## SAND STALKER

- Fast movement.
- Ambush behavior.
- Close-range attacks.
- Low defense.
- Distinctive desert materials.

## DUNE SCORPION

- Armored creature.
- Slow but powerful attacks.
- Telegraph-based sting.
- Poison or temporary debuff with visible counterplay.

## RUIN SENTINEL

- Ancient mechanical or magical guardian.
- Defensive behavior.
- Telegraph-based ranged or area attack.
- Rare ancient materials.

Each enemy must have:
- Original artwork.
- Distinct AI.
- Movement.
- Attack.
- Damage.
- Health.
- Hit reactions.
- Telegraphs.
- Death behavior.
- Loot table.
- Persistent reward behavior.

Reuse the existing combat architecture.

Do not create three identical enemies with different colors.

---

# 11 — SECOND MAJOR BOSS

Create a visually impressive desert boss.

Name:

**AZRAKH — THE DESERT SOVEREIGN**

The boss guards an ancient temple.

Make the boss distinct from Thornheart.

### COMBAT MECHANICS

Phase I:
- Wide sweeping attack.
- Sand projectile.
- Clearly telegraphed ground hazard.

Phase II:
- Stronger sandstorm attack.
- Area denial.
- Summoned obstacles or enemies where appropriate.
- New attack combinations.

The player must be able to:
- Read enemy attacks.
- Dodge dangerous mechanics.
- Use equipment meaningfully.
- Recover when appropriate.
- Defeat the boss through player skill.

Create:
- Unique boss sprite.
- Attack animations.
- Hit feedback.
- Boss health UI.
- Phase transition.
- Victory effect.
- Unique artifact.

Do not create an ordinary monster with inflated health and call it a boss.

---

# 12 — LOOT AND NEW EQUIPMENT

Extend existing inventory and crafting.

New materials may include:
- Desert Crystal
- Sentinel Core
- Ancient Alloy
- Scorpion Venom
- Sovereign Relic Fragment

Use a concise balanced item catalog.

Implement a small set of meaningful new equipment:

- Desert-forged Sword
- Guardian Shield
- Sandwalker Armor
- Ancient Talisman
- Unique Desert Sovereign Artifact

These items must have actual effects.

Examples:
- Additional defense.
- Modified movement speed.
- Improved resistance against a specific hazard.
- Small meaningful combat ability enhancement.
- Better expedition readiness.

Do not create items with fake bonuses.

Use the existing forge and equipment architecture.

---

# 13 — INVENTORY AND STORAGE IMPROVEMENTS

The verified Milestone C inventory had a capacity of 32 items.

Milestone D may have expanded inventory or storage; inspect the actual repository.

The new loot, army and trade systems must not make progression impossible because of inventory limitations.

Implement a coherent solution such as:
- Settlement warehouse.
- Material stack separation.
- Safe transfer to outpost storage.
- Equipment inventory expansion.
- Item sorting and filtering.
- Protected quest materials.
- Explicit sale or salvage rules.

Never silently destroy items to make room.

Prevent duplication during transfers.

Test inventory overflow and recovery.

Ensure pending craft queues remain valid.

---

# 14 — RARE DISCOVERIES AND ANCIENT HISTORY

Add discovery content that makes exploration emotionally rewarding.

Examples:
- Forgotten merchant road.
- Ancient mining inscription.
- Desert oasis.
- Buried royal statue.
- Broken war banner.
- Lost temple.
- Ancient astronomer's device.

Discoveries should:
- Appear in actual regions.
- Require legitimate exploration.
- Have localized descriptions.
- Award meaningful knowledge or progression.
- Be added to the existing world chronicle.
- Persist across saves.

Avoid repeated popup spam.

Allow players to review discovered history.

---

# 15 — OUTPOST AND MILITARY CONNECTION

Military forces should have a real role in frontier expansion.

Use existing military systems if Milestone D verified them.

Soldiers should be able to:
- Escort caravans.
- Guard remote outposts.
- Respond to threats.
- Secure dangerous routes.
- Improve expedition safety.

Do not silently duplicate soldiers between the home kingdom and distant assignments.

A deployed squad should not simultaneously defend the home kingdom unless the rules explicitly support it.

Implement a clear military availability interface.

Preserve soldier equipment and commander identities.

---

# 16 — PLAYER GUIDANCE AND USER EXPERIENCE

This is a high priority.

Players should understand the expanded world without needing external documentation.

Extend the existing advisor and onboarding.

New concepts must be introduced gradually.

Example dialogue:

"Your kingdom is ready to trade. Assign a merchant and prepare your first caravan."

"The Ashen Desert holds rare materials. Your hero should carry supplies before traveling."

"An outpost can gather resources beyond your borders, but it needs workers and protection."

"Your caravan has arrived. Open the trade report to collect its cargo."

"Ancient ruins hide unusual treasures. Explore carefully."

Keep guidance short and actionable.

### QUEST NAVIGATION

Every main quest should guide the player to the relevant interaction.

Examples:
- Open Marketplace.
- Focus caravan.
- Open destination map.
- Focus available outpost site.
- Open inventory.
- Open forge.
- Open the boss region.

Do not create nonfunctional navigation buttons.

### UX QUALITY

Build:
- Beautiful world map.
- Clear destination cards.
- Caravan management panel.
- Trade screen.
- Outpost inspector.
- Expedition preparation.
- Discovery journal.
- Boss progression indicators.
- Clear loot comparison.

Keep the interface mobile-first.

Maintain Turkish and English localization.

---

# 17 — VISUAL ART PRODUCTION

Create original game-ready assets.

Required environments:
- Iron Hills.
- Ashen Desert.
- Oasis.
- Ancient ruins.
- Temple exterior.
- Temple interior.
- Mining outpost.

Required buildings:
- Marketplace.
- Caravan station.
- Frontier outpost.
- Resource warehouse.
- Desert guard post.

Required characters:
- Merchant.
- Caravan worker.
- Frontier miner.
- Desert monsters.
- Azrakh boss.

Required visual elements:
- Caravans.
- Trade goods.
- Mineral nodes.
- Crystals.
- Desert vegetation.
- Ancient banners.
- Treasure chests.
- Unique weapons.
- Unique artifact.
- Quest indicators.

Use available image-generation tools or original procedural/vector art.

Keep the style consistent with LittleGod.

Create usable sprites and game assets.

Do not substitute concept art for functioning gameplay.

Inspect actual Godot renders.

---

# 18 — PERFORMANCE AND ANDROID

Avoid uncontrolled simulation complexity.

Use:
- Bounded route updates.
- Efficient caravan state machines.
- Cached map assets.
- Limited active enemy populations.
- Lightweight regional AI.
- Incremental scene loading where useful.
- Data-driven production.
- Bounded offline progression.

Profile:
- World map transitions.
- Desert scene startup.
- Enemy AI cost.
- Loot and inventory updates.
- Caravan progression.
- Outpost production.
- Save/load duration.
- Android frame times.
- Memory consumption.

Maintain normal and battery-saver modes.

Do not claim physical-device performance without actual physical-device testing.

Use a disposable QA package or test slot for Android validation.

Protect real player saves.

---

# 19 — SAVE MIGRATION AND DATA INTEGRITY

Extend the existing versioned save architecture.

Persist:
- Realm Level 21–25 progression.
- Region unlocks.
- Regional discoveries.
- Caravan identities and states.
- Merchant assignments.
- Cargo ownership.
- Trade transactions.
- Outpost identities.
- Outpost workers.
- Outpost resources.
- Outpost defenses.
- New items.
- New equipment.
- Boss defeat.
- Unique rewards.
- Quest completion.
- World chronicle milestones.

Preserve:
- Old XP.
- All completed quests.
- Civilian tool IDs.
- Hero identity.
- Hero equipment.
- Military equipment.
- Soldier identities.
- Training queues.
- Craft queues.
- Existing balances.
- Cosmetics.
- Planet world state.

Migrations must be explicit, repeatable and idempotent.

Do not replay old rewards.

Do not fabricate historical save fixtures.

Do not reset existing caravan, army or crafting state on repeated loads.

---

# 20 — AUTOMATED TESTING

Retain all existing legitimate automated checks.

Add tests for:
- Level 21–25 progression.
- Quest prerequisites.
- Trade price consistency.
- Buy/sell resource conservation.
- Caravan creation.
- Cargo reservation.
- Caravan departure and arrival.
- Caravan event idempotency.
- Escort assignment.
- Soldier availability.
- Outpost construction.
- Worker assignment.
- Remote resource deposits.
- Outpost production.
- Outpost storage.
- Inventory transfers.
- Region unlocking.
- Adventure entry and return.
- New enemy attacks.
- Status effects.
- Equipment bonuses.
- Desert boss phases.
- Unique boss rewards.
- Save/load restoration.
- Offline route processing.
- Historical save migration.
- Quest reward exactly-once behavior.

Run varied legal campaign journeys through Realm Level 25.

Use actual building, gathering, crafting, trading, exploration and combat commands.

Do not force XP or quest completion flags.

Do not inject impossible resource balances to prove campaign reachability.

Negative tests may deliberately construct invalid data but must be clearly labeled as such.

Run real rendered playtests.

Verify Android installation, startup, touch gameplay and save restoration.

---

# 21 — IMPLEMENTATION ORDER

Work in complete playable vertical slices.

## E1 — THE MARKETPLACE

- Campaign Level 21.
- Real Marketplace.
- Merchant role.
- Buy/sell prices.
- First working caravan.
- Trade reports.

Test and checkpoint.

## E2 — EXPANDED WORLD

- World map extension.
- Iron Hills.
- Ashen Desert.
- New exploration scene.
- Desert monsters.
- Realm Level 22.

Test actual playable movement and combat.

## E3 — ANCIENT RUINS

- Ruins exploration.
- Ancient discoveries.
- New material loot.
- Advanced equipment.
- Realm Level 23.

Test real crafting and equipment effects.

## E4 — FRONTIER OUTPOST

- Outpost placement.
- Worker assignment.
- Remote production.
- Resource transport.
- Military protection.
- Realm Level 24.

Verify real economy integration.

## E5 — THE DESERT SOVEREIGN

- Ancient temple.
- Azrakh boss.
- Distinct boss mechanics.
- Unique reward.
- Realm Level 25.
- Chapter V completion.

Verify actual boss combat.

## E6 — POLISH AND RELEASE

- Visual quality.
- User guidance.
- Gameplay balancing.
- Regression tests.
- Save migration.
- Performance.
- Android validation.
- Source archive.
- Documentation.
- Git checkpoint.

After every verified slice:
- Commit changes.
- Document test results.
- Preserve a working checkpoint.

Do not move to Milestone F before Milestone E is verified.

If execution limits prevent the full milestone, stop at the latest tested checkpoint and provide exact continuation instructions.

---

# 22 — ACCEPTANCE CRITERIA

A legitimate player must be able to:

1. Continue their existing kingdom.
2. Reach Realm Level 21.
3. Build a Marketplace.
4. Assign a merchant.
5. Create a caravan.
6. Transport and trade real goods.
7. Receive legitimate payment or goods.
8. Unlock the Ashen Desert.
9. Enter a real playable desert scene.
10. Fight new monsters.
11. Collect new crafting materials.
12. Discover ancient ruins.
13. Craft advanced equipment.
14. Equip an item with real effects.
15. Construct a remote resource outpost.
16. Assign workers.
17. Guard the outpost with actual available soldiers.
18. Produce and transport remote resources.
19. Enter the ancient desert temple.
20. Fight and defeat Azrakh.
21. Claim the unique artifact exactly once.
22. Complete Realm Level 25.
23. Save and reopen with everything preserved.

All systems must connect to the established economy and game state.

No placeholder battles.

No fake trade rewards.

No decorative-only outposts.

No quest progression through invalid events.

---

# 23 — RELEASE LITTLE GOD 0.8.5 MILESTONE E

When the milestone has actually passed verification:

Generate:
- Working desktop launcher.
- LittleGod Milestone E Android debug APK.
- Updated source archive.
- Real screenshots from the desert.
- Real caravan screenshots.
- Outpost gameplay screenshots.
- Azrakh boss screenshots.
- Trade and economy test results.
- Android performance report.

Update:
- docs/STATUS.md
- docs/KNOWN_ISSUES.md

Create:
- docs/AGE085_MILESTONE_E_REPORT.md
- docs/TRADE_AND_CARAVANS.md
- docs/REGIONAL_EXPLORATION.md
- docs/OUTPOST_SYSTEM.md
- docs/QUESTS_21_25.md
- docs/ECONOMY_BALANCE.md
- docs/PERFORMANCE_MILESTONE_E.md

Create a clean Git checkpoint and tag:

age085-milestone-e

Only create this tag when core Milestone E acceptance criteria are satisfied.

Do not tag littlegod-0.9 or littlegod-1.0.

Do not claim that Realm Levels 26–30 are implemented.

Clearly report:
- Actual features completed.
- Automated checks passed.
- Real gameplay tested.
- Android test status.
- Performance measurements.
- Save compatibility.
- Known limitations.
- Remaining Milestone F requirements.

---

# FINAL INSTRUCTIONS

Do not recreate LittleGod.

Do not break existing saves.

Do not destroy the living-world simulation.

Do not duplicate resource or inventory systems.

Do not introduce paid infrastructure.

Do not activate payments.

Do not publish the game.

Do not claim untested features are complete.

Make routine implementation decisions autonomously.

Build beautiful original game assets.

Create real working adventures, caravans, trade and outposts.

Preserve all existing gameplay and tests.

## FINAL OBJECTIVE

LittleGod must become a richer and more interconnected fantasy kingdom RPG.

The player builds a kingdom.

The kingdom produces goods.

Merchants carry those goods to other regions.

Soldiers protect trade routes.

Workers operate frontier mines.

Heroes explore ancient ruins.

Monsters drop useful materials.

Blacksmiths create powerful equipment.

Boss victories unlock new opportunities.

Every system supports the growth of the player's living world.

**START IMPLEMENTING MILESTONE E NOW. DO NOT STOP AFTER PLANNING.**