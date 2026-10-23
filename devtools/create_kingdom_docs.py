"""Write the milestone report from accepted local evidence; never promote an unfinished release."""
from pathlib import Path
import hashlib,json,re,shutil,subprocess
root=Path(__file__).resolve().parents[1];docs=root/'docs';raw=root/'builds/phase085'
def write(name,text):(docs/name).write_text(text.strip()+'\n',encoding='utf-8')
def read(name):return json.loads((raw/name).read_text(encoding='utf-8'))
def preserve(name):
 target=docs/(Path(name).stem+'_08.md')
 if not target.exists():target.write_bytes(subprocess.check_output(['git','show','littlegod-0.8:docs/'+name],cwd=root))
preserve('STATUS.md');preserve('KNOWN_ISSUES.md');preserve('ANDROID_TEST_REPORT.md');preserve('TEST_REPORT.md')
checks=read('tests.json');visual=read('visual.json');android=read('android/result.json');legacy=read('android-legacy/result.json');native=read('android-native/result.json');balance=read('balance.json')
assert checks['failed']==0 and visual['all_passed'] and android['all_passed'] and legacy['all_passed'] and native['all_passed'] and not balance['failures']
profiles=[read('android-smooth-kingdom-hidden.json'),read('android-smooth-kingdom.json'),read('android-economy-kingdom.json')]
apk=root/'builds/android/LittleGod-0.8.5-milestone-A-debug.apk';sha=hashlib.sha256(apk.read_bytes()).hexdigest()
assert all(p['installed_apk_sha256']==sha and p['player_save_unchanged'] for p in profiles)
table='| Emulator scenario, 20 seconds | FPS | p50 / p95 ms | First frame ms | Draw / peak | Static / video MiB | Sim avg / peak ms |\n|---|---:|---:|---:|---:|---:|---:|\n'
for label,p in zip(['Same fixture, kingdom removed','Five structures / four citizens','Same kingdom, battery saver'],profiles):
 table+=f"| {label} | {p['average_fps']:.2f} | {p['frame_p50_ms']:.2f} / {p['frame_p95_ms']:.2f} | {p['first_frame_ms']} | {p['draw_calls']:.0f} / {p['peak_draw_calls']:.0f} | {p['static_memory_mb']:.1f} / {p['video_memory_mb']:.1f} | {p['simulation_average_ms']:.2f} / {p['simulation_peak_ms']:.2f} |\n"
write('ANDROID_TEST_REPORT.md',f'''# Android — 0.8.5-devA First Kingdom

Final debug APK version0.8.5-devA/code85, minAPI24/target36, ARM64/x86_64; signaturev2/v3 and install/update/startup pass. SHA256 `{sha}`. Actual target: emulator-5554, API35x86_64,1080×2400 portrait, internal720×1600, Godot4.7.2 GL Compatibility. No physical phone was connected. Older0.8 results are archived in ANDROID_TEST_REPORT_08.md.

{len(android['checks'])} kingdom checks pass, including legal five-quest progression, rendered workers/buildings, exact save/load and actual external ADB tile/Confirm taps for an additional house. Its capacity and persisted structure count changed. {len(legacy['checks'])} retained touch/lifecycle/save/visit checks and {len(native['checks'])} native JSON Save/Open checks pass. Engine-injected pinch is distinct from external ADB pan/zoom/power taps. These are automated QA, not human beta data. Only the disposable package was cleared; player planet/backup/temp/settings bytes were checked unchanged during update.

{table}

All samples identify the final player APK hash and preserved its save. Hidden control removes the optional campaign state/HUD/logic from the same initial fixture in memory; it is not GPU-only isolation. Stop editor and QA while profiling. Host/emulator variance, cached-shader recompilation and long startup remain; these are not phone performance, power or thermal measurements. Stable60/30 is unproven here. Godot static/video counters and Android PSS/RSS are different memory measures; the post-QA meminfo dump is in benchmarks/phase085/android/memory.txt. No security setting or App Control policy was changed. STATUS.md contains exact launch paths and remaining scope.
''')
write('TEST_REPORT.md',f'''# First Kingdom — accepted local checks

Verified milestone A,0.8.5-devA. Original356game checks retained and rerun (suite51, runtime1, phase2:15, phase3:49, phase4:40, phase5:50, phase6:74, phase7:15, phase8:61). New campaign checks{checks['passed']}, total{356+checks['passed']}; zero failures. Prior report retained in TEST_REPORT_08.md. Exact command logs are under benchmarks/phase085/final-*.log.

Campaign tests cover optional one-time founding, existing food/people/RNG/habitat, objective/prerequisite/level gates, physical cell-resource conservation/cooldown, legal five-quest progression, exact XP/reward uniqueness, workers/slots/jobs, same-tick idempotency, state validation, exact save round-trip, public privacy/read-only boundaries, plot collisions, material costs, capacity during/after upgrades, inactive production, storage caps, bounded offline replay, actual tagged0.7/0.8 save compatibility, corrupt-primary backup recovery, low-food worker/population consistency and player-save byte preservation.

{len(balance['scenarios'])} legal seeded progression scenarios plus8hour bounded offline replay and repeated report checks passed. {len(visual['checks'])} actual desktop rendered checks, {len(android['checks'])} Android kingdom checks, {len(legacy['checks'])} prior Android interaction/lifecycle checks and {len(native['checks'])} native JSON Save/Open checks pass separately. Godot MCP exercised the actual scene, completed the quest chain with legal model actions, selected a real building and reported no runtime errors. Captures were visually inspected. Synthetic progress is explicitly labeled; no human fun/retention/phone result is inferred.

Existing.NET/API executable remains blocked by Windows App Control from0.8. It was not bypassed or counted as newly passing. No new backend source was needed for this offline campaign extension. Old Godot shutdown resource/ObjectDB warnings remain; zero accepted campaign SCRIPT ERROR/parse errors. Future B–H mechanics have no tests or completion claim because they are not implemented.
''')
ticks=[r['active_simulation_ticks'] for r in balance['scenarios']]
evidence=docs/'benchmarks/phase085';evidence.mkdir(parents=True,exist_ok=True)
for name in ['tests.json','visual.json','balance.json','mcp.log','export.log','export-qa.log','apk-validation.txt','android-smooth-kingdom-hidden.json','android-smooth-kingdom.json','android-economy-kingdom.json']:
 shutil.copy2(raw/name,evidence/Path(name).name)
for folder in ['android','android-legacy','android-native']:
 target=evidence/folder;target.mkdir(exist_ok=True)
 for name in ['result.json','memory.txt','logcat.txt']:
  if (raw/folder/name).exists():shutil.copy2(raw/folder/name,target/name)
for path in raw.glob('final-*.log'):shutil.copy2(path,evidence/path.name)
screens=docs/'screenshots';screens.mkdir(exist_ok=True)
for name in ['advisor-intro','first-village','workers','chapter-complete','buildings','kingdom-tr','adb-placement']:
 shutil.copy2(raw/'android'/(name+'.png'),screens/('phase085-'+name+'.png'))
for name in ['mcp-village','mcp-building','mcp-quests']:
 shutil.copy2(raw/(name+'.png'),screens/('phase085-'+name+'.png'))
write('STATUS.md',f'''# LittleGod 0.8.5-devA — First Kingdom, verified milestone A

Local checkpoint: `age085-milestone-a`, based on `littlegod-0.8` (`f9420527e58f2fd6a1a70b7b538c8f9f079aaaab`), with safe base tag `age085-base-0.8`. Verified 2026-10-23. **This is the completed first playable vertical slice, not the finished Age of Kingdoms expansion.** The final `littlegod-0.8.5` release tag has deliberately not been created. Milestones B–H remain.

Implemented: optional bilingual Elder Arin introduction, five data-driven primary quests, realm levels 1–5, verified one-time rewards, real timber/stone gathering, working lumber camps/farms, named paid citizens, job assignment and skill growth, trust/food upkeep, idle-citizen construction, housing/storage/council hall, material costs, level 1–3 building upgrades, relocation, derived village tier 2, bounded history and offline work. Food and population use the original settlement; Stardust/cosmetic ownership remain separate. Existing worlds opt in through the menu and retain their terrain, people and wardrobe.

New original assets: transparent generated Arin portrait (`assets/kingdom/arin.png`, runtime384²), six procedural SVG building/scaffold images and shared576×384 atlas. Original painted terrain, creatures, plants, cosmetic art, typography, sound and online sources remain. Buildings/scaffolds are depth sorted with existing scenery; actual workers visibly move/sway at their assigned workplace. Building roof selection takes priority over overlapping wildlife. Long planet titles now fit their header.

Verification: **356 retained game checks + {checks['passed']} new campaign checks = {356+checks['passed']} passing**, {len(balance['scenarios'])} legal progression / eight-hour offline scenarios, {len(visual['checks'])} desktop rendered checks, {len(android['checks'])} Android kingdom checks including external ADB placement/Confirm taps, {len(legacy['checks'])} retained Android interaction/lifecycle checks and {len(native['checks'])} native JSON Save/Open checks. Actual tagged0.7/0.8 saves, exact campaign round-trip, corrupt-primary backup recovery, duplicate rewards/offline replay, read-only visits and real player-save preservation pass. Godot MCP rendered the completed village and selected an actual building; its runtime error list was empty. Automated scenarios are not human playtests.

{table}

Measurements are from emulator-5554, API35/x86_64,1080×2400 portrait with720×1600 internal viewport, Godot4.7.2 GL Compatibility. No physical Android device was available. The hidden comparison removes the entire optional campaign extension in memory, including its work simulation and HUD; it is not an isolated GPU-only experiment. Both runs start from the same saved ecosystem fixture. Host/emulator/shader-cache variance is substantial, so these samples do not establish a causal FPS gain, stable60 or physical-device performance. Battery-saver still caps at30, normal at60. First-frame counters include engine startup; they are not pure world-generation CPU or touch latency. Raw counters and actual APK SHA are in `benchmarks/phase085`.

## Play and outputs

- Launcher: `D:/LittleGod/Launch LittleGod.cmd`; verified runtime `D:/LittleGod/tools/godot/Godot_v4.7.2-stable_win64.exe`.
- Player APK: `D:/LittleGod/builds/android/LittleGod-0.8.5-milestone-A-debug.apk`, version0.8.5-devA/code85, {apk.stat().st_size} bytes, ARM64/x86_64, minAPI24/target36, debug signed. SHA256 `{sha}`. Installation/update/startup validated; original planet/backup/temp/settings files preserved.
- QA APK: `D:/LittleGod/builds/android/LittleGod-0.8.5-milestone-A-qa-debug.apk`, separate disposable package. Only this package was cleared.
- Source checkpoint archive: `D:/LittleGod/builds/LittleGod-0.8.5-milestone-A-source.zip`; commit/hash/CRC manifest: `D:/LittleGod/builds/phase085/checkpoint-manifest.json`.
- Prior0.8 APK/archive and tags remain intact. This is not a store release, public server deployment or payment integration.

Open ☰ → First Kingdom → Awaken the First Kingdom. Tap objectives for location/build guidance. Meet settlers, gather six timber, claim reward, build a lumber camp and assign a citizen. Close menus to let work advance. Then build/assign a farm, add housing/recruit a fourth citizen, and raise the council hall. Keep an idle citizen for construction. Tap a building's roof to inspect/upgrade/move it. The resource bar opens the campaign. Advisor help can be hidden/replayed. After quest5 free building/upgrading continues with an explicit chapter-complete message.

## Continuation boundary

Next is **milestone B**, levels6–10: quarry, mine, furnace, forge, inventory, crafting and equipment foundations. None is claimed implemented. Then C must provide a separate playable Wildwood adventure with movement/combat/AI/loot/boss; D armies/formations/raids; E regions/trade; F finale; G30side quests/optional captive policies/expeditions; H final polish. No fake adventure buttons, simulated battles, placeholder30quest list or unverified completion tag were added. See `PHASE085_REPORT.md` for exact code entry points and acceptance steps.

Known limitations include incomplete B–H, bounded early construction, flatter vector buildings beside retained painted scenery, emulator frame/startup variance and lack of physical/human beta evidence. Existing online API/.NET execution remains blocked by Windows App Control; no bypass attempted. Payments remain disabled. Read `KNOWN_ISSUES.md` and historical `STATUS_08.md`.

Actual Android gameplay, progressed by legal automated actions:

![First village](screenshots/phase085-first-village.png)
![Real touch placement](screenshots/phase085-adb-placement.png)
![Arin](screenshots/phase085-advisor-intro.png)
''')
write('PHASE085_REPORT.md',f'''# Age of Kingdoms — milestone A implementation and continuation

**Delivered: First Kingdom, 0.8.5-devA. Not a completed0.8.5 expansion.** Checkpoint `age085-milestone-a`; base `age085-base-0.8`. No final release tag. See STATUS.md for APK/archive paths, hashes, screenshots and measured performance.

The implementation extends the existing Godot project. `scripts/kingdom.gd` owns optional private `world.kingdom` v1. `civilization.gd` calls it once per real simulation tick after the original settlement economy. Existing Persistence.offline replay therefore advances construction/work with the same bounds and no automatic quest claims. `persistence.gd` validates and normalizes it in the original atomic checksum envelope. Monetary/skill/progress counters use integer thousandths for exact restoration; existing serializers/world save version remain intact.

`assets/kingdom/quests.json` contains five genuine localized quests with stable IDs/prerequisites/objectives/navigation/rewards. `buildings.json` contains five functional types. `kingdom_interface.gd` provides the optional introduction, objective guidance, live resource bar, placement/inspect/upgrade/move, residents/jobs and history. `kingdom_renderer.gd` retains bounded sprites in the existing depth-sorted world. `world_inhabitants.gd` removes only scenery on functional plots and suppresses duplicate capital walkers. Other species/settlements, cosmetics, powers and visiting remain.

Visual inspection found overlapping long titles and building/creature selection conflicts; both were corrected and inspected. Exact-save tests exposed floating-point round-trip drift, fixed by integer units rather than weakening equality. Housing/storage upgrades now keep their previous capacity during construction. Low-food residents cannot fall below registered paid citizens. Per-type plot limits stop duplicate buildings from consuming every plot before mandatory quest buildings can be placed.

## Accepted evidence

- Original356checks retained and rerun; {checks['passed']} new model checks pass, exact save comparison included.
- {len(balance['scenarios'])} seeded runs complete all five quests using legal gathering/construction/assignment/claims, then eight hours of bounded offline simulation and duplicate-report checks. Active simulated ticks range{min(ticks)}–{max(ticks)} (2seconds each at1×); these exclude navigation/menu time and do not estimate human retention or session length.
- Desktop rendered checks{len(visual['checks'])}; Android kingdom{len(android['checks'])}; retained Android{len(legacy['checks'])}; native Save/Open{len(native['checks'])}. External ADB house taps are separate from engine-injected pinch. Godot MCP selected the actual lumber camp; Arin texture was384×384; runtime errors empty.
- Player package installed with `install -r`; planet/backup/temp/settings bytes preserved. All performance samples identify the final APK hash. No phone connected, no public deployment or paid service.
- Android memory dump, counters, APK metadata/signature, screenshots and logs are retained under `docs/benchmarks/phase085` and `builds/phase085`. Export/runtime retain older Godot ObjectDB/resource shutdown warnings; these are disclosed, not counted as passing tests. No campaign SCRIPT ERROR was accepted.

## Reproduce

Use the verified runtime under `tools/godot`. Run the original suite/runtime/phase2…phase8 headless scripts, then `tests/phase085.gd` and `tests/kingdom_balance.gd`. Run `tests/kingdom_playtest.gd` with rendering enabled. `devtools/build_kingdom.py` exports player, `--qa` exports the isolated QA package and restores preset bytes. `devtools/android_kingdom_validate.py` upgrades the player without clearing it and exercises the disposable QA package. Retained Android drivers accept `--apk builds/android/LittleGod-0.8.5-milestone-A-qa-debug.apk --output-dir builds/phase085/android-legacy` (or android-native for social driver). `profile_android.py --kingdom [--hide-kingdom | --economy] --duration 20 --output-dir builds/phase085` loads only the dedicated private benchmark fixture; player saves are untouched. Stop editor/QA before profiling.

## Exact next implementation step — B

Start from `age085-milestone-a`, preserving0.8 and this APK. Extend the optional campaign with a versioned migration; keep all existing worker IDs, integer balances, plots, claimed quest IDs, rewards and wardrobe. Add actual quarry/mine/furnace/forge definitions and bounded rendering; revise16-plot/per-type budgeting deliberately before additional mandatory structures. Add ore/refined-material types and consume/produce them in real chains. Add localized recipes and validated inventory/item instances; crafting must remove the ingredients and create usable items. Equipment must modify an actual supported consumer rather than only an icon/stat label. Extend levels/quests6–10 with exact XP requirements and reachable resource budgets. Existing600XP should naturally unlock realm6 when the cap expands; never replay first-five rewards. No champion is claimed yet: establish the equipment consumer honestly before C.

Add old0.8.5-devA migration fixtures plus resource conservation/crafting/save/offline tests; retain all406existing game checks and Android behavior. Complete B and render/playtest/checkpoint it before beginning the actual adventure. C must create a separate playable scene with direct movement, hitboxes, damage/AI/loot, equipped-item effects and Wildwood boss; text-only combat is unacceptable. D–H follow the user's order. Final `littlegod-0.8.5` may only be tagged once the complete requested core acceptance criteria pass.

## Remaining scope

Levels6–30, hero XP/classes/gear,30main+30sidequest completeness, combat/regions/bosses, armies/formations/siege, expeditions, captive-policy system and final balance/mobile polish are not implemented in this slice. The current quest UI says so. Existing online server changes from0.8 remain unverified at live runtime because App Control blocks the API/test assembly; no bypass or system-security changes were attempted. Physical device, OEM input/haptics/battery and human enjoyment/retention are unverified. Do not reinterpret automated QA as human beta participation.
''')
write('AGE_OF_KINGDOMS_DESIGN.md','''# Age of Kingdoms architecture — implemented A, pending B–H

The planet remains the existing ecosystem/civilization game. An explicit menu opt-in adds the First Kingdom campaign to its current capital; no planet recreation or save replacement occurs. Food/population/cell resources retain one authority. Cosmetic Stardust and private kingdom wood/stone/gold have different purposes and cannot be converted. Public showcases strip campaign balances, workers and quests.

Data flow: Ecosystem.tick → Civilization.tick → Kingdom.tick → normal view sync/worker animation. Objective counters derive from actual observation/gather/work/completion/recruitment; stable quest IDs control once-only rewards. Construction uses available named citizens and real material costs. UI menus pause time; closing them returns to observing real work. Offline work uses the original bounded replay. No artificial daily deadline, streak, forced ad, payment gate or absence loss was introduced.

World renderer reuses the original isometric projection and retained scenery nodes. Functional structures avoid settlements/cosmetics; scenery is skipped only on their plots. Jobs visibly animate at actual assigned structures. Bounds:16structures,12citizens,30history entries; catalog-specific limits are3per type except one council hall. No NavigationAgent or per-worker timer is needed for this slice.

Implemented: realm1–5, first five main quests, production, worker skills/upkeep/trust, village tier1–2, placement/upgrades/relocation/history/Arin. Pending serial slices: B6–10economic chains/inventory; C11–15first real adventure; D16–20armies; E21–25trade/regions; F26–30finale; Gside content/policies/expeditions; Hfinish/polish. The planned files COMBAT_DESIGN/MILITARY_SYSTEM/EXPEDITION_SYSTEM describe acceptance boundaries, not shipped features.
''')
quests=json.loads((root/'assets/kingdom/quests.json').read_text(encoding='utf-8'))
qtable='| ID / realm | Quest | Actual objectives | Rewards | Next |\n|---|---|---|---|---|\n'
for q in quests:qtable+=f"| {q['id']} / {q['level']} | {q['title'][0]} / {q['title'][1]} | "+'; '.join(o['text'][0]+': '+str(o['target']) for o in q['objectives'])+' | '+', '.join(str(v)+' '+k for k,v in q['rewards'].items())+' | '+(q['next'] or 'Chapter I complete')+' |\n'
write('QUEST_DATABASE.md',f'''# Implemented quest database — First Flame

Canonical source: assets/kingdom/quests.json. **Five main quests, zero side quests in this slice**; the requested30+30 remains pending. Each has EN/TR title/description/objective labels, stable ID, level, chapter, prerequisite list, real objective predicates, navigation, explicit rewards and next link. Progress is realm-lifetime, so genuinely completed relevant work may satisfy later objectives. Only the current complete quest can be claimed, once; no menu or playtest assigns fake levels/currency.

{qtable}

Building objectives require completed construction (previous levels remain valid during upgrade). Production means actual assigned work consuming local resources. Village tier2 derives from a completed hall/house/farm/camp, at least4citizens,6real residents,8food and0.6trust. Arin may be hidden/replayed; no campaign dialogue blocks repeated observation. UI clearly ends this chapter after quest5.
''')
write('PROGRESSION_BALANCE.md',f'''# First Kingdom progression and balance

Realm threshold to reach n+1 is20*n*(n+1) cumulative XP; current cap5. Quest rewards40/80/120/160/200 reach cumulative40/120/240/400/600. No passive XP grind; objectives are construction/work/observation choices. The fifth reward stays600XP in saves; extending the cap can unlock6 without regranting anything. Hero levels are not implemented.

Production per tick is0.45×building level×sum(worker skills)×trust×environment, clamped by actual cell resources and remaining output capacity, rounded down to0.001. Forest factor ismax(0.2,plants); farms use moisture,×0.65in forests. Worker skill starts1.0, gains0.001per productive tick to1.5. Trust starts0.9, +0.002withfood>5, otherwise−0.005, bounded0.55–1.0. Food upkeep0.025per registered citizen per tick. Idle labor equals idle citizens×trust; construction is sequential and bounded, with no production when nobody is assigned.

Housing adds3rooms/level above preserved legacy capacity; global80. Storage begins60wood/stone and adds80per storehouse level. Existing capacity is retained during upgrades. Quest rewards bypass production soft caps to deliver promised rewards in full, within validated hard bounds. Gold is a finite starter/quest/recruitment resource in A; no mine or paid-currency conversion exists yet. Gathering consumes≤3cell resources every4ticks; automated jobs avoid repeated taps. The original ecosystem still regrows generic cell resources, including rock; distinct depleted mineral deposits belong to B and are not falsely claimed.

{len(balance['scenarios'])} legal seeded journeys passed; active simulation range{min(ticks)}–{max(ticks)}ticks and median{sorted(ticks)[len(ticks)//2]}. At1× each tick is2seconds, excluding time in menus, camera navigation and player thought. Each journey then passed8hours of bounded offline replay, consistency and repeated-report idempotency. These are automated reachability checks, not human session-time, fun, retention or economy-exploit proof. Additional balance for B–H must be measured after actual systems exist.
''')
econ=(docs/'ECONOMY_DESIGN.md').read_text(encoding='utf-8')
marker='\n## Age of Kingdoms milestone A economy\n'
if marker in econ:econ=econ.split(marker)[0]
econ+=marker+'''
The existing Stardust cosmetic economy above is unchanged. The optional capital extension stores wood/stone/gold in integer thousandths and uses the existing settlement's food/population. Founding grant:12stone/8gold, exactly once;3existing residents become citizens. Quest XP and materials are delivered only on verified claims. Real forest/mountain gathering and lumber/farm jobs consume cell resources. Wages consume food; recruitment costs2food/1gold, requires realm4/trust≥0.6 and adequate resident/housing capacity. No debt, payment, ads or offline reward claims were added.

| Structure | Realm | Wood / stone / gold | Base labor ticks | Worker slots | Limit |
|---|---:|---:|---:|---:|---:|
| Lumber camp | 2 | 8 / 2 / 0 | 4 | 2 | 3 |
| Farm | 3 | 10 / 2 / 0 | 5 | 2 | 3 |
| Hearth house | 3 | 8 / 2 / 0 | 4 | 0 | 3 |
| Storehouse | 4 | 12 / 4 / 0 | 5 | 0 | 3 |
| Council hall | 5 | 18 / 6 / 2 | 6 | 0 | 1 |

Upgrades reach level3, costing base cost×newlevel and base labor×newlevel. A work tick is2seconds at1× but construction may complete faster with several idle citizens; menus pause time. Relocation is free to suitable nearby vacant plots and preserves progress/assignments. Global bounds16structures/12citizens; per-type limits leave room for mandatory A buildings. At full storage production stops without consuming inputs. See PROGRESSION_BALANCE.md and phase085 balance evidence. No trade/crafting/ore/equipment/military economy is implemented yet.
'''
write('ECONOMY_DESIGN.md',econ)
write('COMBAT_DESIGN.md','''# Combat — not implemented in milestone A

This file records the pending C acceptance boundary. There is currently no champion, combat scene, weapon consumer, monster AI, loot or boss. Existing god powers remain ecosystem interactions and are not presented as battles.

After B supplies validated inventory/equipment and resource-to-usable-item crafting, C must add a separate Wildwood adventure scene with responsive movement, attack hitboxes, health/damage feedback, telegraphed AI, retreat/return, real drops and a boss that can be fought and defeated. Equipment must influence actual combat; save/reload must preserve acquired gear and progress. Rendered desktop and Android touch playtests must demonstrate this loop before any C completion claim. Later classes/regions/bosses follow the full user specification; no fake combat screen qualifies.
''')
write('MILITARY_SYSTEM.md','''# Military — pending milestone D

No army, barracks, soldier recruiting, formation, raid or siege exists in A. Paid citizens currently perform civilian construction/farming/lumber work only.

D must connect recruitment to real equipment/food/population costs, upkeep and bounded squads. Formation and unit composition must alter actual battle outcomes, with observable casualties/retreat/defense and hostile camps. Preserve civilian jobs and offline state coherently; compare seeded army/formation outcomes in tests. Later elite/siege/outposts belong to F. Optional captive labor belongs to G and must have meaningful stability/diplomacy consequences while free workers remain viable; it is not implemented or required for A progression.
''')
write('EXPEDITION_SYSTEM.md','''# Expeditions — pending later slices

No expedition timers, expedition loot or automated battle result exists in A. Offline construction/work is real existing-world simulation, not an expedition feature.

Future expeditions must consume available units/supplies, reserve them against double assignment, resolve from actual party/region rules, persist deterministically and grant results once after bounded offline progression. No missed-day punishment or paid acceleration. Region discoveries and loot must affect playable progression and have repeatable tests for interrupted save, repeated resume and invalid parties. Add only after the required economic/adventure/military consumers are working.
''')
write('KNOWN_ISSUES.md','''# Known issues — 0.8.5-devA, First Kingdom

- Milestone A only. Levels6–30, hero/classes/equipment, combat/adventures/bosses, army/formation/raids, trade/regions/finale, expeditions,30sidequests and captive policies remain pending B–H. Do not tag this as the completed0.8.5 release. Follow PHASE085_REPORT.md for continuation.
- Early buildings use original flat SVG art beside retained painted terrain. Upgrades change scale/capacity but do not yet have three fully distinct painted models. Worker routes are short workplace animations, not obstacle-aware logistics. No resource-hauling simulation is claimed. Actual job outputs/construction determine work animation.
- A has16global plots,3per type except one hall,12named workers and30history entries. B must revise plot/type limits before expanding mandatory buildings. Placement is restricted to5.5tiles from the capital and suitable unoccupied terrain. Terrain changes can interrupt production; relocation retains investments. There is no demolition/refund system yet.
- Quests1–5 are legal-action reachable in50tested seeds, not a proof for every possible edited/old-world terrain. Extremely transformed older capitals may need forest/terrain god powers or relocation within the radius to restore suitable sites. Existing high population/housing is preserved at opt-in.
- The original ecosystem regrows generic cell resources, including rock. Distinct ore deposits, refined materials and crafting are pending. Realm levels are campaign levels; hero progression is absent. Village tier is derived1–2 only. Gold is a finite civilian resource here, separate from cosmetic Stardust.
- Main menus pause simulation, so construction/work waits until the player returns to the world. Leave a citizen idle to build. Low food lowers trust/productivity, but registered workers retain real residents. Human balance/readability/long-term enjoyment need real testers; none were recruited or contacted.
- Emulator rendering/startup/shader-cache variability remains; see actual samples in STATUS.md. Stable60 on a suitable phone and stable30 on this host are unverified. Physical phones, haptics/thermals/battery/OEM safe areas and actual two-finger touch remain untested. ADB taps and engine-injected pinch are explicitly different evidence.
- Godot export and some old test shutdowns report ObjectDB/resource cleanup warnings. Accepted rendered campaign runs had no runtime SCRIPT ERROR. Native Windows Computer Use was unavailable (foreground-window process-id issue); actual Godot/MCP/ADB renders were inspected.
- Existing online API executable/final.NET test runtime remain blocked by Windows App Control, inherited from0.8; no bypass or security change. Offline play and inert read-only import/export were rerun. New live online v2 endpoints are not newly verified. Payments stay disabled; no public deployment, store publishing or paid service occurred. Historical limitations/evidence are retained in KNOWN_ISSUES_08.md.
''')
inventory=(docs/'ASSET_INVENTORY.md').read_text(encoding='utf-8')
asset_marker='\n## Age of Kingdoms milestone A assets\n'
if asset_marker in inventory:inventory=inventory.split(asset_marker)[0]
inventory+=asset_marker+'''
Elder Arin: assets/kingdom/arin.png, new transparent illustration made with the built-in image_gen tool; exact prompt recorded in docs/art/arin-prompt.md. The original generated raster is retained; runtime import is384×384, verified through Godot MCP. No paid external API/stock pack was used. Original six192×192SVG building/scaffold assets plus shared576×384atlas are reproducible with devtools/create_kingdom_art.py. Existing painted worker frame14 is reused with role tint and procedural work/walk sway. Old terrain/creature/ornament art/fonts/licenses remain. Screenshots phase085-* are actual desktop/Android rendered gameplay, legally advanced by automated actions, not concept art or human progress.
'''
write('ASSET_INVENTORY.md',inventory)
# Keep original console bytes in builds; remove only trailing padding from reviewable text copies.
for path in evidence.rglob('*'):
 if path.suffix in ['.log','.txt']:
  path.write_text('\n'.join(line.rstrip() for line in path.read_text(encoding='utf-8-sig').splitlines()).rstrip()+'\n',encoding='utf-8')
print('Milestone A documentation generated from final accepted evidence.')
