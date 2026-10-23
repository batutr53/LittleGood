# Age of Kingdoms — milestone A implementation and continuation

**Delivered: First Kingdom, 0.8.5-devA. Not a completed0.8.5 expansion.** Checkpoint `age085-milestone-a`; base `age085-base-0.8`. No final release tag. See STATUS.md for APK/archive paths, hashes, screenshots and measured performance.

The implementation extends the existing Godot project. `scripts/kingdom.gd` owns optional private `world.kingdom` v1. `civilization.gd` calls it once per real simulation tick after the original settlement economy. Existing Persistence.offline replay therefore advances construction/work with the same bounds and no automatic quest claims. `persistence.gd` validates and normalizes it in the original atomic checksum envelope. Monetary/skill/progress counters use integer thousandths for exact restoration; existing serializers/world save version remain intact.

`assets/kingdom/quests.json` contains five genuine localized quests with stable IDs/prerequisites/objectives/navigation/rewards. `buildings.json` contains five functional types. `kingdom_interface.gd` provides the optional introduction, objective guidance, live resource bar, placement/inspect/upgrade/move, residents/jobs and history. `kingdom_renderer.gd` retains bounded sprites in the existing depth-sorted world. `world_inhabitants.gd` removes only scenery on functional plots and suppresses duplicate capital walkers. Other species/settlements, cosmetics, powers and visiting remain.

Visual inspection found overlapping long titles and building/creature selection conflicts; both were corrected and inspected. Exact-save tests exposed floating-point round-trip drift, fixed by integer units rather than weakening equality. Housing/storage upgrades now keep their previous capacity during construction. Low-food residents cannot fall below registered paid citizens. Per-type plot limits stop duplicate buildings from consuming every plot before mandatory quest buildings can be placed.

## Accepted evidence

- Original356checks retained and rerun; 50 new model checks pass, exact save comparison included.
- 50 seeded runs complete all five quests using legal gathering/construction/assignment/claims, then eight hours of bounded offline simulation and duplicate-report checks. Active simulated ticks range55–168 (2seconds each at1×); these exclude navigation/menu time and do not estimate human retention or session length.
- Desktop rendered checks12; Android kingdom15; retained Android26; native Save/Open3. External ADB house taps are separate from engine-injected pinch. Godot MCP selected the actual lumber camp; Arin texture was384×384; runtime errors empty.
- Player package installed with `install -r`; planet/backup/temp/settings bytes preserved. All performance samples identify the final APK hash. No phone connected, no public deployment or paid service.
- Android memory dump, counters, APK metadata/signature, screenshots and logs are retained under `docs/benchmarks/phase085` and `builds/phase085`. Export/runtime retain older Godot ObjectDB/resource shutdown warnings; these are disclosed, not counted as passing tests. No campaign SCRIPT ERROR was accepted.

## Reproduce

Use the verified runtime under `tools/godot`. Run the original suite/runtime/phase2…phase8 headless scripts, then `tests/phase085.gd` and `tests/kingdom_balance.gd`. Run `tests/kingdom_playtest.gd` with rendering enabled. `devtools/build_kingdom.py` exports player, `--qa` exports the isolated QA package and restores preset bytes. `devtools/android_kingdom_validate.py` upgrades the player without clearing it and exercises the disposable QA package. Retained Android drivers accept `--apk builds/android/LittleGod-0.8.5-milestone-A-qa-debug.apk --output-dir builds/phase085/android-legacy` (or android-native for social driver). `profile_android.py --kingdom [--hide-kingdom | --economy] --duration 20 --output-dir builds/phase085` loads only the dedicated private benchmark fixture; player saves are untouched. Stop editor/QA before profiling.

## Exact next implementation step — B

Start from `age085-milestone-a`, preserving0.8 and this APK. Extend the optional campaign with a versioned migration; keep all existing worker IDs, integer balances, plots, claimed quest IDs, rewards and wardrobe. Add actual quarry/mine/furnace/forge definitions and bounded rendering; revise16-plot/per-type budgeting deliberately before additional mandatory structures. Add ore/refined-material types and consume/produce them in real chains. Add localized recipes and validated inventory/item instances; crafting must remove the ingredients and create usable items. Equipment must modify an actual supported consumer rather than only an icon/stat label. Extend levels/quests6–10 with exact XP requirements and reachable resource budgets. Existing600XP should naturally unlock realm6 when the cap expands; never replay first-five rewards. No champion is claimed yet: establish the equipment consumer honestly before C.

Add old0.8.5-devA migration fixtures plus resource conservation/crafting/save/offline tests; retain all406existing game checks and Android behavior. Complete B and render/playtest/checkpoint it before beginning the actual adventure. C must create a separate playable scene with direct movement, hitboxes, damage/AI/loot, equipped-item effects and Wildwood boss; text-only combat is unacceptable. D–H follow the user's order. Final `littlegod-0.8.5` may only be tagged once the complete requested core acceptance criteria pass.

## Remaining scope

Levels6–30, hero XP/classes/gear,30main+30sidequest completeness, combat/regions/bosses, armies/formations/siege, expeditions, captive-policy system and final balance/mobile polish are not implemented in this slice. The current quest UI says so. Existing online server changes from0.8 remain unverified at live runtime because App Control blocks the API/test assembly; no bypass or system-security changes were attempted. Physical device, OEM input/haptics/battery and human enjoyment/retention are unverified. Do not reinterpret automated QA as human beta participation.
