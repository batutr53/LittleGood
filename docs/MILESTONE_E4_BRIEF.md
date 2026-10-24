# LITTLE GOD — AGE OF KINGDOMS
# MILESTONE E4: FRONTIER KINGDOMS
# REMOTE OUTPOSTS, WORKER COLONIES, RESOURCE MINING, SUPPLY CHAINS, MILITARY PROTECTION & REAL KINGDOM LOGISTICS

## YOUR MISSION

Continue development of the EXISTING LittleGod project.

PROJECT DIRECTORY:
D:\LittleGod

TARGET:
LittleGod 0.8.5 — Milestone E4

CAMPAIGN TARGET:
Realm Level 24

You are the autonomous game development studio responsible for:
- Game direction
- Godot programming
- Kingdom economy
- Resource simulation
- Worker assignment systems
- Outpost construction
- Military integration
- Logistics and caravan systems
- Quest progression
- Save migrations
- Original artwork
- Mobile UI/UX
- Automated testing
- Visual gameplay testing
- Android performance
- Build packaging

This milestone must make the player's kingdom capable of expanding beyond its original borders and establishing permanent resource-producing outposts.

Use Codex, Godot MCP, Computer Use, terminal tools and available image-generation capabilities.

Do not stop at planning.

Implement actual playable systems, inspect the running game, fix problems, test real gameplay and deliver a verified checkpoint.

Make routine design and engineering decisions autonomously.

Do not request manual coding, artwork or ordinary testing from the product owner.

Do not activate paid services, modify security policies, deploy publicly or publish the game.

---

# 0 — VERIFY THE REAL PROJECT STATE

Before making changes:

1. Inspect Git branch, commits, tags and working tree.
2. Read docs/STATUS.md.
3. Read the latest milestone reports.
4. Inspect the actual game implementation.
5. Run all currently documented automated tests.
6. Inspect the save migration architecture.
7. Inspect current campaign and quest progression.
8. Verify existing resource, worker, army and caravan models.
9. Verify adventure regions and dungeon systems.
10. Create a safe checkpoint before significant work.

Previously reported verified baseline:

Milestone C:
- Realm Levels 1–15
- Hero
- Real Wildwood adventure
- Combat
- Equipment and loot
- Thornheart boss
- 539 passing game checks

Milestone D:
- Critical military prerequisites were reportedly implemented before E1.
- Do not assume all advanced military functionality exists.

Milestone E1:
- Realm Levels 1–21
- 639 game assertions
- Marketplace
- Merchant assignments
- Real local trading
- Persistent caravans
- Cargo reservations
- Escorts and safe threat decisions

E2 and E3 specifications were provided, but their completion reports have not been supplied to the product owner.

Therefore:

DO NOT ASSUME E2 OR E3 ARE COMPLETE.

Check the repository.

If either prerequisite is incomplete, finish its critical required gameplay first and verify it before starting dependent E4 systems.

If prerequisite work cannot be completed within execution limits, leave an accurate checkpoint and continuation report rather than claiming E4 is complete.

Do not fabricate completed features.

Do not recreate the project.

Do not duplicate existing resource, inventory, quest, adventure or caravan systems.

Preserve all current legitimate saves and completed quests.

---

# 1 — CREATIVE VISION

The player has built a growing ancient kingdom.

Its citizens have established agriculture, mining, blacksmithing and military defense.

Heroes have explored distant forests, mountains, deserts and ancient ruins.

Now the kingdom needs permanent control of remote resources.

The player should be able to:

- Discover a valuable external resource deposit.
- Claim a suitable frontier location.
- Build a small outpost.
- Assign eligible citizens as remote workers.
- Send guards or soldiers to protect them.
- Operate a working mine.
- Accumulate genuine materials.
- Organize a supply caravan.
- Transport the resources home.
- Use the materials in the existing kingdom economy.
- Upgrade and fortify the outpost.
- Respond to meaningful regional threats.

The outpost should feel like a small living settlement.

Workers move around.

Mining operations create visible activity.

Guards patrol.

Wagons carry supplies.

Buildings evolve.

The player should feel that their kingdom has physically expanded into new lands.

The outpost must NOT be a decorative map icon with fake resource rewards.

---

# 2 — LEVEL 24: THE FRONTIER OUTPOST

Implement the main story quest:

**THE FRONTIER OUTPOST**

Story:

An ancient mineral deposit has been discovered beyond the kingdom.

The king's advisors believe that securing these resources will be essential for the coming conflict.

But the region is dangerous.

The player must organize workers, supplies and military protection to establish the first permanent settlement outside their homeland.

## MAIN QUEST OBJECTIVES

1. Complete Realm Level 23 through legitimate gameplay.
2. Receive the frontier expedition mission.
3. Open the world map.
4. Inspect available frontier locations.
5. Choose a valid Iron Hills mining site.
6. Prepare legitimate construction materials.
7. Transport necessary supplies.
8. Construct the first Frontier Outpost.
9. Assign at least two eligible civilian workers.
10. Assign an available guard or squad.
11. Start real mineral production.
12. Collect a required amount of legitimate ore.
13. Load the extracted material onto a supply caravan.
14. Transport the material back to the kingdom.
15. Deposit it in the home resource economy.
16. Demonstrate a legitimate resource consumer or production use.
17. Resolve or secure the outpost against one meaningful regional threat.
18. Return to the kingdom.
19. Complete Realm Level 24.
20. Unlock preparation for the Desert Sovereign chapter.

Every objective must correspond to actual gameplay state.

Do not progress the quest by opening a menu that only pretends production or transport occurred.

No forced XP.

No free injected resources.

No manual completion flags in normal gameplay.

All rewards must be granted exactly once.

Support English and Turkish localization.

---

# 3 — EXTERNAL OUTPOST PLACEMENT

Create a functional outpost construction system.

An outpost can only be built at valid discovered frontier locations.

For E4, fully implement at least one Iron Hills mining location.

If the actual verified Ashen Desert architecture safely supports it, add one optional desert frontier site using the same reusable system.

Do not require the optional desert site for the Level 24 main quest.

Each frontier site should define:
- Unique site ID
- Region ID
- Coordinates or logical placement
- Unlock requirements
- Available resource deposits
- Construction limits
- Hostility rating
- Supply route
- Supported building types
- Persistent discovery state
- Outpost ownership

## PLACEMENT REQUIREMENTS

The player must:
- Select the frontier site.
- See the construction preview.
- Inspect required resources.
- Confirm construction.
- Pay legitimate construction costs.
- Observe construction progress.
- See the completed outpost.

Reject invalid placements.

Prevent duplicate outposts at the same exclusive site.

Do not allow construction at undiscovered or locked sites.

Prevent construction costs from being charged more than once for a repeated command.

Preserve location ownership after save/load.

---

# 4 — OUTPOST BUILDINGS

Implement a compact collection of real functional structures.

## COMMAND CAMP

The central outpost structure.

Functions:
- Represents the outpost's existence.
- Provides limited storage.
- Supports workers and assignments.
- Enables upgrades.
- Displays outpost status.

## REMOTE MINE

Functions:
- Extracts actual regional mineral deposits.
- Requires assigned eligible miners.
- Requires remaining deposit capacity or valid regeneration.
- Produces resources in the remote outpost storage.
- Shows visual mining activity.

## SUPPLY DEPOT

Functions:
- Stores extracted materials.
- Receives incoming supplies.
- Provides loading capacity for caravans.
- Displays storage usage.

## GUARD POST

Functions:
- Assigns actual soldiers.
- Improves security.
- Supports meaningful regional defense.
- Displays guards when present.

Optional visual structures:
- Worker tents
- Campfire
- Simple palisade
- Mineral processing equipment

Do not implement decorative buildings as if they performed real economic functions.

Each gameplay building must have:
- Stable ID
- Construction cost
- Construction state
- Visual appearance
- Worker or guard requirements
- Upgrade rules where relevant
- Resource effects
- Save persistence
- Clear inspector panel

Reuse existing construction, industry and worker concepts where appropriate.

---

# 5 — OUTPOST UPGRADES

Implement a coherent three-tier progression model.

## TIER 1 — FRONTIER CAMP

Features:
- Basic command camp
- Limited worker capacity
- Small resource storage
- Basic mining
- Minimal defenses

## TIER 2 — MINING SETTLEMENT

Features:
- Improved mine efficiency
- Increased worker capacity
- Larger warehouse
- Better supply handling
- Improved visual appearance

## TIER 3 — FORTIFIED OUTPOST

Features:
- Better defense
- Stronger palisades or guard facilities
- Improved storage and logistics
- Greater development capacity
- Visibly upgraded structures

At minimum, the complete Tier 1 experience must be implemented and tested to satisfy the main quest.

Tier 2 and Tier 3 should be implemented using the same architecture if execution limits permit.

Do not label the full upgrade system complete if higher tiers are decorative or untested.

Create appropriate upgrade previews.

Do not consume upgrade materials before requirements are met.

Avoid impossible future-resource dependencies.

---

# 6 — REAL REMOTE WORKER MANAGEMENT

Extend the EXISTING civilian job system.

A citizen should be able to work at a remote outpost.

Required assignments:
- Frontier Miner
- Supply Worker
- Builder
- Optional Outpost Supervisor

Reuse existing citizens and identities.

Do not create duplicate workers disconnected from the original population.

## ASSIGNMENT RULES

A citizen cannot simultaneously be:
- A home farmer.
- A home miner.
- A caravan merchant.
- A soldier.
- A remote miner.

Unless a future explicit mechanic permits it.

Assigning a citizen to the outpost must remove them from any incompatible current job through a safe atomic transition.

The worker must remain traceable by stable ID.

Players must be able to:
- View available workers.
- Assign workers.
- Recall workers.
- Inspect current assignments.
- See output contributions.
- Identify missing workers.
- Identify idle workers.

Do not create phantom labor.

Population counts must remain conserved.

If the worker is unavailable, assigned elsewhere or invalid, reject the assignment with a clear message.

---

# 7 — TRANSPORT AND WORKER TRAVEL

Remote workers should not teleport silently between the kingdom and the outpost.

Implement a clearly defined assignment and travel model.

For example:

1. Select workers.
2. Prepare transport.
3. Confirm assignment.
4. Record departure.
5. Advance bounded travel.
6. Mark workers as arrived.
7. Start production only after arrival.

Use the existing caravan or expedition infrastructure where practical.

Avoid inventing an incompatible second transport scheduler.

A strategic travel abstraction is acceptable when a full walking simulation would be expensive.

The UI must honestly represent it as strategic travel.

No instant remote mining before workers arrive.

Provide safe worker recall.

Prevent repeated transfer commands from duplicating citizens.

---

# 8 — REAL RESOURCE DEPOSITS

This is one of the most important requirements.

Remote resources must come from actual site deposits.

Implement:
- Deposit type
- Deposit quantity
- Maximum reserve
- Production rate
- Worker requirement
- Mining efficiency
- Remaining capacity
- Storage constraints
- Exhaustion or renewal rules

Suggested resources:
- Iron Ore
- Stone
- Small amounts of Ancient Mineral or equivalent verified regional material

Reuse established resource definitions.

Do not create conflicting versions of Iron Ore.

## RESOURCE CONSERVATION

Remote mining must satisfy:

Extracted quantity cannot exceed legitimate available deposit quantity.

Produced material must enter remote storage.

The deposit must decrease accordingly unless explicitly renewable.

Full storage must stop or constrain production.

Absent miners must prevent production.

An exhausted deposit must stop producing.

Repeated same-clock updates must not duplicate output.

Offline processing must remain bounded.

Save/load must preserve deposit amounts exactly.

Do not use infinite resource generation as a hidden workaround for progression.

If a renewable deposit mechanic is used, make its regeneration bounded, explicit and tested.

---

# 9 — REMOTE STORAGE

Implement persistent outpost storage.

Storage must have:
- Capacity
- Resource quantities
- Incoming supplies
- Outgoing shipments
- Reserved cargo
- Free capacity
- Transfer history

Prevent negative values.

Prevent transfer of resources not actually owned.

Prevent exceeding storage capacity.

Do not erase resources if the player attempts to send more cargo than a caravan can carry.

Cargo should be reserved exactly once.

Provide a clear outpost storage panel.

Protect quest-critical materials.

Use the project's established integer-precision and inventory conventions.

---

# 10 — INTEGRATE WITH THE EXISTING CARAVAN SYSTEM

Do not rebuild the E1 caravan architecture.

Extend it to support outpost logistics.

Existing E1 includes:
- Persistent caravans
- Merchants
- Trade routes
- Cargo reservations
- Escorts
- Exactly-once delivery
- Route monitoring
- Safe detour or return decisions

Reuse these concepts whenever compatible.

Introduce cargo routes:

KINGDOM → OUTPOST
- Food
- Construction materials
- Tools
- Requested supplies

OUTPOST → KINGDOM
- Extracted ore
- Stone
- Regional materials
- Legitimate recovered goods

## DELIVERY REQUIREMENTS

A real logistics transaction must include:
1. Cargo reservation.
2. Capacity validation.
3. Departure.
4. Route progression.
5. Threat handling.
6. Arrival.
7. Cargo transfer.
8. Reservation release.
9. Persistent delivery receipt.

Repeated collection must not duplicate resources.

An interrupted save must not create cargo at both locations.

Use stable shipment IDs and idempotent transitions.

A route must not simultaneously be completed and pending.

Create clear handling for cargo returns, canceled shipments and failed deliveries.

---

# 11 — THE COMPLETE SUPPLY CHAIN

The player should be able to perform this genuine sequence:

1. Gather wood and stone at home.
2. Construct or prepare an outpost.
3. Assign eligible workers.
4. Transport supplies.
5. Start remote mining.
6. Accumulate ore in the outpost warehouse.
7. Assign caravan transport.
8. Reserve actual extracted ore.
9. Send the caravan home.
10. Complete the route.
11. Collect the shipment.
12. Deposit ore into the kingdom's common economy.
13. Refine ore in the existing furnace.
14. Use refined iron in the existing forge.
15. Produce equipment.
16. Equip or deploy the resulting item.

Every resource change must be legitimate.

This flow must be demonstrated through integrated tests.

Do not substitute direct inventory mutation for transportation.

---

# 12 — MILITARY PROTECTION

Integrate the existing D military system.

Military protection must be meaningful.

Players should be able to:
- View available home soldiers.
- Assign guards to an outpost.
- Send a squad.
- Recall defenders.
- Inspect local defensive strength.
- See supply requirements.
- Respond to regional threats.

An outpost guard must not simultaneously be counted as:
- A home defender.
- A caravan escort.
- A soldier deployed to another battlefield.

Unless a legitimate transport and return action resolves the state first.

Maintain military identity and equipment ownership.

Do not duplicate soldiers.

## PROTECTION BENEFITS

Protection can:
- Reduce threat probability or severity.
- Improve defensibility.
- Unlock safe mining operations in dangerous regions.
- Provide actual resistance in encounters.
- Improve route security when assigned appropriately.

Do not use meaningless displayed defense numbers.

Protection must influence real gameplay outcomes.

---

# 13 — REGIONAL THREAT SYSTEM

Introduce one meaningful outpost threat encounter.

Possible attackers:
- Mountain raiders
- Cave creatures
- Bandit scouts

Threats should depend on:
- Region hostility
- Outpost visibility
- Local guards
- Defenses
- Supplies
- Campaign progress

The player must receive understandable warnings.

For the first Level 24 mission, implement at least one real threat resolution.

If the existing D tactical battlefield is verified:
- Reuse its actual battle system.
- Integrate available outpost guards.
- Use proper terrain and enemy units.
- Apply actual battle consequences.

If only a smaller verified encounter model is available, implement a genuinely functional encounter using that system.

Do not claim a fully rendered army siege when only an abstract encounter was verified.

## OFFLINE SAFETY

Do not destroy remote settlements automatically because the player was absent.

Major attacks should wait for player acknowledgment or an explicit auto-resolution decision.

Safe resource production may continue through bounded offline progression.

Pending threats must persist correctly.

Threat states must not regenerate duplicate rewards or losses when reopening a save.

---

# 14 — OUTPOST DEFENSE AND REPAIR

Implement meaningful defenses.

Examples:
- Wooden palisade
- Guard post
- Watchtower

At minimum, the required outpost guard facility must work.

If defenses have durability:
- Damage must be legitimate.
- Repairs must consume real materials.
- Durability must persist.
- UI must display actual condition.
- Defensive effects must reflect remaining durability.

Do not make invulnerable buildings that are falsely described as destructible.

Do not turn this milestone into a full advanced siege warfare expansion.

The large ancient castle siege belongs to Milestone F.

---

# 15 — OUTPOST PRODUCTION AND OFFLINE PROGRESSION

The existing LittleGod project has carefully defined simulation clocks.

Preserve them.

Known prior behavior:
- Home simulation pauses during active hero adventures.
- E1 Live Route Watch intentionally advances home/caravan simulation.
- Offline progression is bounded.
- Repeated identical clock processing is idempotent.

Inspect the latest actual implementation and document the resulting rules.

Outpost production must have a clear relationship to these clocks.

Avoid:
- Double simulation.
- Negative stock.
- Infinite unattended rewards.
- Time-travel exploits.
- Duplicate route arrivals.
- Craft queue corruption.
- Worker duplication.
- Incorrect army deployment.

Test:
- Game closed for several hours.
- Save and reopen.
- Adventure entry and exit.
- Caravan route view.
- Pending outpost construction.
- Pending shipment.
- Pending threat.
- Repeated identical clock updates.

Do not punish the player for taking a break.

---

# 16 — OUTPOST MAP AND VISUALIZATION

Create a beautiful frontier outpost scene.

The player should visually see:
- Command camp
- Tents
- Mine
- Mining workers
- Storage
- Guard post
- Soldiers
- Resource activity
- Supply wagon
- Natural environment
- Outpost upgrades

Use the existing LittleGod art direction.

The outpost should have a distinctive visual identity while fitting naturally into Iron Hills.

### SCENE REQUIREMENTS

- Real Godot nodes.
- Functional click/touch inspection.
- Clear building boundaries.
- Readable camera.
- Worker or representative work animations.
- Mining activity tied to actual production.
- Soldier animation tied to actual deployed guards.
- Storage indicators tied to real quantities.
- Weather and ambient elements where appropriate.

Do not animate mining when there are no miners or no valid resources.

Do not display guards if no actual soldiers are stationed there.

Do not present a concept illustration as a playable outpost.

---

# 17 — MOBILE USER EXPERIENCE

Design the outpost interface for Android portrait gameplay.

Keep interaction simple.

Required screens:

## FRONTIER MAP

Show:
- Discovered frontier sites
- Locked frontier sites
- Available resources
- Threat rating
- Current outposts
- Active supply routes

## OUTPOST OVERVIEW

Show:
- Name
- Tier
- Workers
- Guards
- Storage
- Resource production
- Supply status
- Security status
- Next upgrade

## WORKER ASSIGNMENT

Show:
- Available citizens
- Assigned workers
- Productivity
- Worker arrival state
- Recall action

## LOGISTICS PANEL

Show:
- Origin
- Destination
- Available cargo
- Reserved cargo
- Caravan capacity
- Assigned escort
- Supply requirements
- Route status

## SECURITY PANEL

Show:
- Assigned soldiers
- Defense strength
- Threats
- Equipment/supply readiness
- Response options

Use clear icons.

Large touch targets.

Short explanations.

Turkish and English localization.

No overwhelming management tables on the main planet screen.

---

# 18 — ADVISOR AND QUEST GUIDANCE

Extend the existing advisor system.

Introduce frontier development gradually.

Example explanations:

"Your kingdom needs more iron. The Iron Hills contain rich deposits."

"An outpost requires workers. Assign citizens before mining can begin."

"The ore stays at the outpost until a caravan brings it home."

"Your guards protect the miners. Send an available squad to secure the camp."

"Your caravan returned with iron. Your furnace can now refine it."

Keep dialogue concise.

Provide working quest navigation for:
- Frontier map
- Construction site
- Worker assignment
- Guard assignment
- Resource storage
- Caravan preparation
- Shipment collection
- Forge

Do not create buttons without functional actions.

Do not interrupt active combat with repeated tutorials.

Show clear reasons when an action is unavailable.

Examples:
- Not enough wood
- Missing worker
- No storage capacity
- Route blocked
- No available soldiers
- Missing supplies
- Deposit exhausted

---

# 19 — ORIGINAL ARTWORK

Create original game-ready assets.

OUTPOST BUILDINGS:
- Frontier Command Camp
- Mining Station
- Supply Depot
- Guard Post
- Palisade
- Upgraded structures

WORKERS:
- Frontier Miner
- Supply Worker
- Outpost Builder

MILITARY:
- Frontier Guard
- Patrol Squad
- Outpost Banner
- Defensive structures

ENVIRONMENT:
- Iron Hills terrain
- Ore deposits
- Cave entrance
- Rock formations
- Wooden supports
- Mining equipment
- Lanterns
- Crates
- Wagons
- Roads

INTERFACE:
- Frontier map markers
- Worker assignment cards
- Outpost inspector
- Storage indicators
- Shipment preparation
- Threat warnings
- Upgrade previews
- Quest markers

Use available image generation when appropriate.

Otherwise produce original procedural/vector assets.

Keep sprite sizes and visual language consistent.

Integrate all art into actual playable Godot scenes.

Inspect rendered results and iterate.

Do not use ripped copyrighted game sprites.

---

# 20 — SOUND, ANIMATION AND GAME FEEL

Add satisfying feedback for:
- Claiming an outpost site
- Beginning construction
- Completing construction
- Assigning a worker
- Arriving at a remote location
- Mining activity
- Filling storage
- Loading cargo
- Caravan departure
- Caravan arrival
- Guard assignment
- Threat warning
- Successful outpost defense
- Upgrading the outpost

Use subtle animations and sound.

Avoid excessive popups.

Do not overload Android rendering with unnecessary particles.

All effects should correspond to actual game state.

---

# 21 — ECONOMY BALANCE

Create explicit and testable balance rules.

Define:
- Outpost construction costs
- Worker travel time
- Worker productivity
- Deposit extraction rates
- Deposit capacities
- Outpost storage limits
- Caravan capacity
- Shipment duration
- Supply consumption
- Guard costs
- Threat probabilities
- Defense strength
- Upgrade costs

A legitimate Level 24 player must be able to complete the main quest using resources available through existing Levels 1–23.

Do not require future Level 25 boss materials.

Do not require unavailable military units.

Do not require impossible worker or population counts.

Do not allow trade-to-mining loops to create unlimited currency.

Test different legal world seeds.

Keep the economy understandable and rewarding.

Make the first functioning outpost achievable without hours of repetitive grinding.

---

# 22 — STORAGE AND INVENTORY COMPATIBILITY

The project previously had a 32-item unique inventory capacity and later added legitimate salvage mechanics.

Inspect the actual current system.

Do not assume unlimited inventory space.

Avoid making regional loot, worker kits or outpost cargo impossible to store.

Preserve:
- Civilian tools
- Hero gear
- Military equipment
- Unique relics
- Craft queues
- Caravan cargo
- Quest-critical items

Implement explicit storage and transfer ownership.

Do not silently discard items.

Prevent item duplication during:
- Worker assignment
- Caravan loading
- Outpost arrival
- Outpost collection
- Forge transfers
- Save restoration

Do not create a second independent inventory that bypasses existing conservation rules.

---

# 23 — SAVE MIGRATIONS

Extend the existing versioned save architecture.

Persist:
- Frontier sites
- Outpost identities
- Outpost tiers
- Building states
- Worker assignments
- Worker travel
- Guard assignments
- Soldier deployment
- Resource deposits
- Outpost storage
- Cargo reservations
- Inbound shipments
- Outbound shipments
- Production timestamps
- Threat state
- Defense damage
- Quest 24 progress
- Chronicle events

Preserve all earlier data.

Important:
- Completed quest claims
- Existing Realm XP
- Hero XP
- Hero equipment
- Current health
- Civilian worker IDs
- Military soldier IDs
- Merchant assignments
- Caravan routes
- Pending cargo
- Crafting queues
- Unique inventory IDs
- Ancient relics
- Region discoveries
- Previous boss rewards
- Cosmetics
- World simulation

Use authentic historical fixtures where available.

Do not fabricate old saves.

Migrations must be explicit and idempotent.

No duplicate rewards.

No negative resources.

No missing items.

No phantom workers.

No phantom soldiers.

---

# 24 — AUTOMATED TESTING

Run all current legitimate tests.

Do not hard-code the assumed count of 639 if the project has legitimately gained additional coverage.

Add tests for:

FRONTIER SITES
- Discovery requirements
- Site claiming
- Duplicate site prevention
- Construction costs
- Valid location

WORKERS
- Worker eligibility
- Job transfers
- Population conservation
- Arrival and recall
- No simultaneous incompatible assignments

PRODUCTION
- Deposit quantities
- Worker productivity
- Storage limits
- No-worker stalls
- Exhaustion behavior
- Repeated clock idempotency
- Offline progression

LOGISTICS
- Cargo reservations
- Supply consumption
- Caravan capacity
- Shipment dispatch
- Delivery completion
- Return cargo
- Canceled routes
- Exactly-once collection
- No duplication across locations

MILITARY
- Guard deployment
- Soldier ownership
- Escort conflicts
- Threat resolution
- Defense impact
- Safe offline threat handling
- Recovery and recall

QUESTS
- Level 24 prerequisites
- Objective progression
- Legitimate ore production
- Real shipment completion
- Actual home delivery
- Threat requirement
- Exactly-once quest reward

PERSISTENCE
- Previous save migrations
- Outpost save/load
- Pending shipment restoration
- Active production restoration
- Threat restoration
- Item conservation
- Worker conservation
- Military conservation

Test legal seeded progression from Realm Level 1 through Level 24.

Use real building, gathering, fighting, trading, crafting, worker and shipment commands.

Do not force XP.

Do not inject resources.

Do not directly set quest flags.

Negative tests may construct invalid states if clearly labeled.

Preserve all valid existing checks.

---

# 25 — RENDERED PLAYTESTING

Use actual Godot runtime and available visual tools.

Verify:
- Frontier map selection
- Outpost construction
- Mining visual activity
- Worker assignments
- Guard assignments
- Storage updates
- Caravan loading
- Resource movement
- Threat response
- Outpost upgrades where implemented
- Return to kingdom
- Quest progress
- Save/reopen

Inspect actual screenshots.

Do not use conceptual artwork as evidence of working gameplay.

Fix:
- Camera clipping
- Input overlap
- Inaccessible controls
- Incorrect sprite sorting
- Missing animations
- UI scale issues
- Production animation inconsistencies

Use Godot MCP or Computer Use when available.

If unavailable, use supported Godot CLI and rendered test harnesses.

---

# 26 — ANDROID PERFORMANCE

Build a disposable QA Android package.

Verify:
1. Installation
2. Startup
3. Existing kingdom gameplay
4. Existing adventure regions
5. Existing Marketplace
6. Existing caravans
7. Frontier map
8. Outpost construction
9. Worker assignment
10. Guard assignment
11. Resource production
12. Cargo loading
13. Caravan dispatch
14. Delivery collection
15. Quest 24
16. Save/force-stop/reopen
17. Normal graphics mode
18. Battery-saver mode

Measure:
- Android emulator FPS
- Frame-time percentiles
- Outpost scene construction
- Production tick costs
- Caravan tick costs
- Memory use
- Save/load time

Preserve realistic mobile performance.

Avoid individually updating hundreds of remote workers every frame.

Use bounded economic simulation and lightweight representative animations.

Do not claim physical-device performance without testing an actual connected device.

Protect the real player save slot.

Do not weaken Windows security or App Control restrictions.

---

# 27 — IMPLEMENTATION ROADMAP

Work in independently verified slices.

## E4A — FRONTIER FOUNDATION

Implement:
- Prerequisite audit
- Level 24 campaign transition
- Frontier site data
- Site claiming
- Outpost construction
- Command Camp
- Outpost inspection interface

Run tests and checkpoint.

## E4B — REMOTE WORKERS AND MINING

Implement:
- Worker transfer rules
- Worker travel state
- Frontier Miner role
- Real mineral deposits
- Production ticks
- Resource depletion
- Remote storage
- Mining animations

Run legal production tests and checkpoint.

## E4C — LOGISTICS AND SUPPLY CHAINS

Implement:
- Outpost cargo
- Home supply transport
- Remote shipment preparation
- Existing caravan integration
- Exact cargo reservations
- Real delivery
- Resource deposition at home
- Forge consumer integration

Run end-to-end material conservation tests and checkpoint.

## E4D — MILITARY SECURITY

Implement:
- Guard Post
- Soldier assignment
- Squad availability
- Defense effects
- Regional threat
- Actual threat resolution
- Recovery and recall
- Safe offline processing

Run rendered or properly grounded battle tests.

Checkpoint.

## E4E — QUEST 24

Implement:
- All main quest objectives
- Contextual advisor guidance
- Progression rewards
- Permanent chronicle milestone
- Chapter V continuation

Verify legitimate Level 1–24 progression.

Checkpoint.

## E4F — POLISH AND RELEASE

Implement and verify:
- Original outpost artwork
- Touch controls
- Visual worker activity
- Resource animations
- Caravan feedback
- UI clarity
- Economic balance
- Save migrations
- Full regression tests
- Android tests
- Performance measurements
- Documentation
- Source archive

Only mark E4 complete when all mandatory acceptance criteria are verified.

If execution limits interrupt progress, leave the latest stable playable checkpoint and precise continuation instructions.

Do not label incomplete work as a finished E4 release.

---

# 28 — DEFINITION OF DONE

A legitimate player must be able to:

1. Continue their original LittleGod world.
2. Preserve all earlier quests and inventory.
3. Reach Realm Level 24 legally.
4. Select a valid frontier site.
5. Build a real outpost.
6. See the outpost in an actual game scene.
7. Assign real eligible citizens.
8. Have them arrive through a defined transport process.
9. Begin legitimate mining.
10. Observe real deposit consumption.
11. See production stop when workers are absent or storage is full.
12. Store extracted ore at the outpost.
13. Assign actual available soldiers.
14. See security affect real outpost mechanics.
15. Prepare a supply caravan.
16. Reserve actual cargo.
17. Dispatch the shipment.
18. Complete the legitimate route.
19. Receive the exact transported resources at home.
20. Use the delivered resources in the existing economy.
21. Resolve a meaningful outpost threat.
22. Complete Realm Level 24.
23. Save, close and reopen successfully.
24. Continue mining and transportation without duplication.
25. Return to the original planet without losing anything.

These interactions must be implemented through real gameplay systems.

Not placeholder menus.

Not fake production.

Not fictional caravans.

Not duplicated workers.

Not simulated quest completion unrelated to player actions.

---

# 29 — FINAL RELEASE DELIVERABLES

When all E4 core requirements pass verification:

Create:
- LittleGod E4 Android debug APK
- Isolated QA APK
- Updated desktop launcher
- Source archive
- Actual frontier map screenshots
- Outpost construction screenshots
- Remote mining screenshots
- Worker assignment screenshots
- Military guard screenshots
- Caravan delivery screenshots
- Quest 24 completion screenshots
- Test reports
- Performance reports
- Save migration reports

Update:
- docs/STATUS.md
- docs/KNOWN_ISSUES.md
- MILESTONE_E_CONTINUATION.md

Create:
- AGE085_E4_REPORT.md
- FRONTIER_OUTPOST_ARCHITECTURE.md
- REMOTE_WORKER_SYSTEM.md
- RESOURCE_LOGISTICS.md
- OUTPOST_SECURITY.md
- QUEST_24_DESIGN.md
- PERFORMANCE_MILESTONE_E4.md

Create verified Git checkpoint/tag:

age085-e4-frontier

Only create the tag when the complete E4 milestone has passed its mandatory acceptance criteria.

Do not tag age085-milestone-e yet.

Do not tag littlegod-0.9 or littlegod-1.0.

Do not start E5 until E4 is verified.

Report:
- What was actually implemented
- What tests passed
- Which playable features were visually verified
- Android emulator findings
- Actual performance measurements
- Save compatibility
- Known issues
- Remaining E5 and E6 requirements

Never fabricate verification results.

---

# FINAL CREATIVE DIRECTIVE

LittleGod should now feel like a civilization growing beyond the borders of its original kingdom.

The player explores a distant land.

They discover valuable mineral deposits.

They establish a frontier outpost.

They send real citizens to work there.

They protect those workers with actual soldiers.

The workers produce real resources.

Caravans carry those resources home.

Blacksmiths use the materials to equip heroes and armies.

The distant settlement becomes an important part of the player's growing kingdom.

Everything must be connected.

Everything must have real gameplay consequences.

Everything must preserve prior player progress.

**MAKE THE FRONTIER FEEL ALIVE.**

START IMPLEMENTING E4 NOW.

DO NOT STOP AFTER WRITING A PLAN.

DO NOT START E5 UNTIL E4 IS VERIFIED.