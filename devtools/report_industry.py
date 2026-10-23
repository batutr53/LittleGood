"""Report the verified prerequisite slice honestly; never promote it to a finished 0.9 release."""
from pathlib import Path
import hashlib,json,re,shutil,subprocess
root=Path(__file__).resolve().parents[1];docs=root/'docs';raw=root/'builds/phase09'
def read(name):return json.loads((raw/name).read_text(encoding='utf-8'))
def write(name,text):(docs/name).write_text(text.strip()+'\n',encoding='utf-8')
tests=read('industry-tests.json');visual=read('visual.json');balance=read('balance.json')
android=read('android-industry/result.json');kingdom=read('android-kingdom/result.json');legacy=read('android-legacy/result.json');native=read('android-native/result.json')
assert tests['failed']==0 and not balance['failures'] and all(r['all_passed'] for r in [visual,android,kingdom,legacy,native])
mcp=(raw/'mcp.log').read_text(encoding='utf-8')
assert 'Error:' not in mcp and re.search(r'"entries":\s*\[\s*\]',mcp) and '"actual_forge_roof_opens_workshop_entry": true' in mcp,'MCP did not verify the rendered forge and an empty runtime error list'
apk=root/'builds/android/LittleGod-0.8.5-milestone-B-debug.apk';sha=hashlib.sha256(apk.read_bytes()).hexdigest()
profiles=[read('android-smooth-kingdom-hidden-industry.json'),read('android-smooth-kingdom-industry.json'),read('android-economy-kingdom-industry.json')]
assert all(p['installed_apk_sha256']==sha and p['player_save_unchanged'] for p in profiles)
table='| 20-second emulator scenario | FPS | p50 / p95 ms | First frame ms | Draw / peak | Static / video MiB | Simulation avg / peak ms |\n|---|---:|---:|---:|---:|---:|---:|\n'
for label,p in zip(['Same ecosystem, campaign removed','Eight buildings, four citizens, two equipped tools','Same industry fixture, battery saver'],profiles):
 table+=f"| {label} | {p['average_fps']:.2f} | {p['frame_p50_ms']:.2f} / {p['frame_p95_ms']:.2f} | {p['first_frame_ms']} | {p['draw_calls']:.0f} / {p['peak_draw_calls']:.0f} | {p['static_memory_mb']:.1f} / {p['video_memory_mb']:.1f} | {p['simulation_average_ms']:.2f} / {p['simulation_peak_ms']:.2f} |\n"
archive=docs/'archive/first-kingdom-a';archive.mkdir(parents=True,exist_ok=True)
for name in ['STATUS.md','KNOWN_ISSUES.md','ANDROID_TEST_REPORT.md','TEST_REPORT.md','AGE_OF_KINGDOMS_DESIGN.md','QUEST_DATABASE.md','PROGRESSION_BALANCE.md','ECONOMY_DESIGN.md']:
 target=archive/name
 if not target.exists():target.write_bytes(subprocess.check_output(['git','show','phase09-base-first-kingdom:docs/'+name],cwd=root))
evidence=docs/'benchmarks/phase09';evidence.mkdir(parents=True,exist_ok=True)
for path in raw.glob('final-*.log'):shutil.copy2(path,evidence/path.name)
for name in ['industry-tests.json','balance.json','visual.json','mcp.log','export.log','export-qa.log','apk-validation.txt','android-smooth-kingdom-hidden-industry.json','android-smooth-kingdom-industry.json','android-economy-kingdom-industry.json']:
 shutil.copy2(raw/name,evidence/Path(name).name)
for folder in ['android-industry','android-kingdom','android-legacy','android-native']:
 target=evidence/folder;target.mkdir(exist_ok=True)
 for name in ['result.json','memory.txt','logcat.txt']:
  if (raw/folder/name).exists():shutil.copy2(raw/folder/name,target/name)
for path in evidence.rglob('*'):
 if path.suffix in ['.log','.txt']:path.write_text('\n'.join(line.rstrip() for line in path.read_text(encoding='utf-8-sig').splitlines()).rstrip()+'\n',encoding='utf-8')
for name in ['iron-village','workshop','craft-queue','inventory','compare-tool','equipped-village','iron-chapter-complete','workshop-tr','inventory-tr','adb-compare']:
 shutil.copy2(raw/'android-industry'/(name+'.png'),docs/'screenshots'/('phase09-'+name+'.png'))
for name in ['mcp-industry-world','mcp-forge','mcp-workshop']:
 shutil.copy2(raw/(name+'.png'),docs/'screenshots'/('phase09-'+name+'.png'))
ticks=[r['ticks'] for r in balance['scenarios']]
write('STATUS.md',f'''# Road to LittleGod 0.9 — verified Iron Age prerequisite

**Current playable version:0.8.5-devB, Age of Kingdoms milestones A+B. The complete0.8.5 campaign and0.9 are not finished.** The0.9 request explicitly requires repairing critical0.8.5 systems first; audit found only realm1–5 and the first village. This checkpoint adds the next coherent playable slice, not levels31–50 on an unfinished game. Base `phase09-base-first-kingdom` = `fabe135231750ab30aef16233c58819cc178648c`. Verified continuation checkpoint `age085-milestone-b`. No `littlegod-0.9` or final `littlegod-0.8.5` tag was created. Prior tags/builds/source remain.

Implemented now: optional ChapterII, realm6–10 and five additional EN/TR main quests; stone quarry, iron mine, furnace and forge; ore/iron balances; assigned stonecutters/miners/smelters/smiths; exact two-ore/one-wood→one-iron conversion; paid-material crafting queue; unique owned tool instances; citizen equipment, comparison/unequip/transfer; four usable crafted tools. Axe increases its citizen's actual wood output50%, pick increases ore50%/stone35%, sickle increases food35%, hammer increases stone/builder labor25%. A tool can only belong to one citizen; no item is duplicated by moving it. All recipes consume real inputs and need smith labor. Offline work uses the original bounded simulation clock and cannot mint repeated completions.

The first chapter and its406checks remain unchanged. Old campaign-v1 saves remain realm5 until the player chooses ChapterII; that explicit transition preserves XP600, citizens, buildings, wardrobe, old balances and claims, adds zero ore/iron, and opens realm6 without re-awarding quests. Private campaign-v2/industry-v1 validation extends the original checksum/atomic save envelope. Public visits/export strip private campaign/inventory data. The original online source and disabled purchases remain untouched.

New original vector art: four isometric production structures plus shared768×192atlas and four tool icons. Original terrain/creature/cosmetic atlases, Arin and font licenses remain. Active forge/furnace warmth and workplace movement follow actual available work. Empty inputs/full storage stop production and active animation. Construction remains citizen labor, not a timer-only menu. Bounds24plots/12citizens/32items/4queued jobs; catalog limits leave room for all mandatory B structures.

Verification: **406 retained + {tests['passed']} new = {406+tests['passed']} passing game checks**, plus the retained50first-chapter and50new ten-quest/eight-hour offline scenarios. {len(visual['checks'])} actual desktop rendered industry checks; Android{len(android['checks'])} industry checks including external ADB unequip/equip/persistence, {len(kingdom['checks'])} first-kingdom checks including external house placement, {len(legacy['checks'])} retained interaction/lifecycle/visit checks and {len(native['checks'])} native JSON Save/Open checks. Godot MCP rendered the eight-building village, selected the actual forge roof and opened its workshop, with an empty runtime error list. Automation is not human beta evidence.

{table}

Emulator-5554/API35/x86_64,1080×2400 portrait,720×1600 world viewport, Godot4.7.2 GL Compatibility. No physical device. Hidden control removes the optional campaign logic/rendering/HUD in memory from the same starting ecosystem; it is not isolated GPU-only testing. Host/cache variation remains; these samples do not establish stable60/30 or phone performance. Normal/saver caps60/30 remain. Original player save bytes and absent temp/settings slots survived updates; performance uses a separate validated benchmark save and never overwrites the player planet. Raw evidence: `docs/benchmarks/phase09`.

## Launch and files

- Play: `D:/LittleGod/Launch LittleGod.cmd`, verified runtime `D:/LittleGod/tools/godot/Godot_v4.7.2-stable_win64.exe`.
- Player APK: `D:/LittleGod/builds/android/LittleGod-0.8.5-milestone-B-debug.apk`, version0.8.5-devB/code86, {apk.stat().st_size}bytes, ARM64/x86_64, minAPI24/target36, debug signaturev2/v3. SHA256 `{sha}`. Installed and started with player data retained.
- Isolated QA APK: `D:/LittleGod/builds/android/LittleGod-0.8.5-milestone-B-qa-debug.apk`. Only this disposable package was cleared.
- Source: `D:/LittleGod/builds/LittleGod-0.8.5-milestone-B-source.zip`; CRC/commit/hash manifest `D:/LittleGod/builds/phase09/checkpoint-manifest.json`.
- Exact continuation: `D:/LittleGod/docs/PHASE09_REPORT.md`. Earlier A documents are retained under `docs/archive/first-kingdom-a`;0.8 and A builds/tags are preserved.

Play ☰→First Kingdom, finish the first five quests and choose **Begin ChapterII · the Iron Age**. Tap current objectives for build/job guidance. Quarry stone, mine ore, assign a smelter to a furnace, then build a forge. Assign a smith, queue an axe and pick, close menus to let work advance, and equip citizens through Inventory. Keep a free builder; recruit more citizens to run concurrent workplaces. The recipe and inventory screens explain actual effects and reserved costs. After quest10, free construction/crafting continues and the UI explicitly states that adventures/armies/levels11–50 remain unavailable.

Remaining prerequisites:0.8.5C–H, including an actual playable adventure, hero/combat/loot, levels11–30, army/formations/regions/finale and side content. Then the requested0.9A–G technology/diplomacy/31–50/tactical conquest/siege/dungeons/legendary gear/guild fallback can begin. Existing API/.NET runtime remains blocked by Windows App Control; no bypass/security change. No paid service, live purchase, public deployment or store publication.

![Actual Android workshop](screenshots/phase09-workshop.png)
![Actual Android tool comparison](screenshots/phase09-adb-compare.png)
![Actual living world](screenshots/phase09-equipped-village.png)
''')
write('PHASE09_REPORT.md',f'''# 0.9 audit, prerequisite implementation and exact continuation

The supplied0.9 mission assumes a finished0.8.5 RPG/army campaign. The repository was clean at `fabe135`/`age085-milestone-a`; the reports and actual source establish only A:realm1–5, five quests, civilian food/timber/stone and buildings. There was no hero, inventory/crafting/loot, adventure scene, army or realm6–30 progression. Claiming the0.9 campaign or upgrading an existing military system would have been false. A safe base tag `phase09-base-first-kingdom` was created, all406existing game checks rerun, and work followed the requested prerequisite order.

**Completed checkpoint:0.8.5 milestone B, Iron Age.** Realm6–10, five new main quests, quarry/mine/furnace/forge, real input/output conversion, worker jobs, bounded persistent craft queue, unique item inventory and real equipped production/construction effects now work. No0.9release tag or finished0.8.5tag. The checkpoint is `age085-milestone-b`; APK/source paths and measured results are in STATUS.md.

## Source architecture and invariants

`scripts/industry.gd` owns the optional industry substate and recipes; `kingdom.gd` remains the single common resource, campaign and tick authority. Explicit opt-in upgrades campaign version1→2 and adds industry version1, ore/iron0 and empty inventory/queue/gear. Old XP, stock, workers, building IDs, claims and cosmetics remain exact; existing600XP naturally opens6. No old quest reward is replayed. Base world save envelope staysv1. `tests/fixtures/planet-v085a.json` was generated by actual tagged milestone-A model code, not by labeling a new save as old. A full old editor import hit a Godot font-import crash; an isolated extraction of the actual model scripts/data plus required cosmetic SVG produced and verified the authentic fixture. No security bypass was involved.

All new balances/progress are integer thousandths. Quarries/mines consume real cell resources; furnaces consume2ore+1wood periron and cannot burn materials at full output storage. Crafting reserves exact ingredients once, allocates a stable unique ID, and completes only after actual assigned smith work. Inventory+queue≤32; pending queue≤4; one tool/citizen and one owner/tool. Each forge uses its own work budget, queue jobs preserve building references during relocation/upgrades, and repeated same-clock/offline processing is idempotent. Public projections omit the entire private campaign. No billing, premium gear or online currency authority was introduced.

`kingdom_interface.gd` supplies chapter opt-in, resources, new objectives, workstation inspection, queue/recipe costs, worker tools and comparison/transfer. A second completed forge can be selected. `kingdom_renderer.gd` retains the existing depth-sorted sprites and adds the shared industry atlas; workers and warm workstation pulses are driven by available work. Missing ore/wood, full storage or absent smiths produce no fake work animation. Bounds increased from16to24plots because the A catalog could otherwise fill every slot before mandatory B construction. Per-type caps total21, leaving every mandatory structure possible. Existing A per-type limits remain.

## Validation

{406+tests['passed']} game checks pass: all406original plus{tests['passed']} new. New tests include authentic-v1 opt-in preservation, exact resource conversion, real boosted harvested output, material reservation, no-smith stalls, unique inventory, atomic transfer, invalid IDs/unknown recipes/full queues, unfinished and complete save restoration, public privacy/read-only behavior, absent-fuel animation, repeated clocks and seven seeded legal ten-quest/offline journeys. Additional50new seeds complete all ten quests with actual gathering/building/job/recipe/equipment actions and then8hours of bounded offline replay. Range{min(ticks)}–{max(ticks)}active ticks (2seconds at1×, excluding navigation/menus); no XP/resources/objectives are forced. The retained50A scenarios pass separately. These are reachability/consistency checks, not human fun or retention measurements.

Desktop{len(visual['checks'])} rendered industry checks pass. A visual-harness bug initially left the planet hidden after replacing its model; enabling the actual world layer fixed it, and the eight-structure check now passes. Real renders, not concept illustrations, were inspected. Godot MCP selected the forge's roof and workshop; its error list was empty. Android{len(android['checks'])} industry/{len(kingdom['checks'])} A/{len(legacy['checks'])} legacy/{len(native['checks'])} native Save/Open checks pass. External ADB equipment toggles and house placement are distinct from engine-injected pinch. Player data stays intact; only the separate betaqa ID is cleared. APK signature/metadata and final installed-hash performance reports are archived. No phone was connected.

The offline campaign needs no backend changes. Existing online code/artwork/saves/tags/APKs are retained. Updated0.8API/.NET execution remains blocked by Windows App Control; previous0.7real service baseline is historical. Native online guilds cannot honestly be claimed ready. No security policy, paid service or publishing action was used. The0.9NPC alliance fallback remains pending behind the unfinished campaign/adventure prerequisites.

## Reproduce this checkpoint

Use the verified `tools/godot/Godot_v4.7.2-stable_win64_console.exe`. Run original tests/suite/runtime/phase2…phase8/phase085, plus `tests/industry.gd`, `tests/kingdom_balance.gd` and `tests/industry_balance.gd` headless. Run `tests/industry_playtest.gd` with rendering. Export with `devtools/build_kingdom.py` (player) and `--qa` (disposable package), preserving original preset bytes. Run `android_kingdom_validate.py` for industry; `--phase kingdom --output-dir builds/phase09/android-kingdom` reruns A. The legacy and native drivers take `--apk builds/android/LittleGod-0.8.5-milestone-B-qa-debug.apk` and a phase09 output folder. MCP actions are in `devtools/industry-visual.json`.

Stop editor/QA before profiling. `profile_android.py --industry --fixture builds/phase09/android-industry/phase085_profile_world.json --duration 20 --output-dir builds/phase09` profiles the legal completed B fixture; add `--hide-kingdom` or `--economy` for controls. Only the dedicated private benchmark slot changes, never the player's planet. `devtools/report_industry.py` derives documentation/evidence from accepted results and checks final APK hashes.

## Exact continuation, before any0.9advanced feature

1. Start at `age085-milestone-b`; retain all{406+tests['passed']}current checks, original A v1 fixture, new v2 save/queue/gear rules, original art and online sources.
2. Implement0.8.5C, realm11–15: explicit chapter transition preserving2200XP and all existing rewards; hero/Warrior foundation and a separate **playable** Wildwood adventure. Provide movement/touch controls, enemy AI/hitboxes/health/damage, readable attack telegraphs, retreat/return, real loot, weapon/armor consumers and first boss. Reuse citizen inventory concepts carefully with versioned ownership/slot expansion; current tools are civilian equipment, not a fake combat system. No text-only battles qualify.
3. Extend recipes and inventory with actual combat effects and loot persistence; add quests11–15 only when reachable through real adventure actions. Add v2→new migration fixtures, battle/loot/conservation/offline/save tests and render/playtest Android before C checkpoint.
4. Finish0.8.5D military16–20, Etrade/regions21–25, Ffinale26–30, Gside quests/expeditions/optional policies, Hpolish. Verify all required1–30progression/combat/army/loot before0.9A begins.
5. Then follow0.9A–G exactly:31–35technology/diplomacy; tactical squads; actual territory/siege; three real dungeons/bosses; legendary effects/research;36–50campaign; verified guild or functional NPC-alliance fallback. Do not fabricate existing military/regions,50quests or online readiness. Tag `littlegod-0.9` only after its core acceptance passes.

Current limitations and performance are documented in KNOWN_ISSUES.md and PERFORMANCE_PHASE09.md. This execution delivers the coherent prerequisite B checkpoint; it does not claim the full requested expansion.
''')
write('PERFORMANCE_PHASE09.md',f'''# Iron Age prerequisite — measured emulator performance

Final player APK SHA256 `{sha}`; version0.8.5-devB/code86. Profiles run serially with desktop editor and QA stopped, from the same legal completed8-building/4-citizen/2-equipped-tool save. Normal/saver caps remain60/30. Hidden control removes the entire campaign in memory, including economy/rendering/HUD; it is not a GPU-only experiment. Original player save bytes stayed unchanged.

{table}

These are short emulator-5554 API35x86_64/GL Compatibility samples, not phone benchmarks or a controlled causal improvement claim.1080×2400 output,720×1600internal viewport. Startup includes engine/shader/cache/host effects; first-frame counters are not pure world-generation cost. Original world atlas1024² and cosmetic768×512 remain; industry adds768×192 and reused A576×384. Maximum24structures/12citizens/32items/4queued recipes; retained sprite/atlas batching and simulation ticks avoid per-unit physics/navigation agents. No unbounded particle system was added. Production potential and available output are separate; cached active animations stop for absent inputs/full storage.

Simulation costs in the table are much lower than observed frame times; the inherited renderer/emulator host remains the main frame-budget concern. This does not prove which GPU/driver component dominates. Static/video Godot counters and Android full-process PSS/RSS differ; the post-QA dump is retained in benchmarks/phase09/android-industry/memory.txt. Physical thermals, battery, real haptics/OEM input and stable60/30 remain unverified. Original shutdown resource warnings remain; no accepted campaign SCRIPT ERROR. See actual JSON for process/world/foreground/terrain metrics rather than interpreting FPS alone.
''')
write('BALANCE_PHASE09.md',f'''# Civilian progression and industry balance — prerequisite B

Completed main quests1–10; no hero/army/dungeon/research/territory balance is claimed. Realm threshold20*n*(n+1), quest n grants40*nXP; A ends600XP and B ends2200XP. Explicit chapter opt-in controls the5/10cap; future C can unlock11 without re-awarding anything. New quests6–10 grant wood12/stone8/gold3 each, plus XP240/280/320/360/400.

Quarry6:12wood4stone; mine7:14wood8stone; furnace8:14wood10stone; forge9:18wood8stone2iron. Each takes6base labor ticks and has2job slots, max2per new type. Production uses real local resource for quarry/mine; furnace consumes2ore1wood→1iron. Base production0.45×level×sum(worker skills×equipped multiplier)×trust; full storage/input limits are applied before debiting. Existing food wages/housing/skill rules remain. Queue recipes require a finished forge, realm9, paid inputs, capacity and smith labor4work-ticks/item. Menus pause simulation. Additional citizens allow simultaneous chains; the automated minimal journey deliberately reassigns one citizen across stages while keeping a builder free.

Forester's Axe2iron2wood, lumber×1.50; Iron Pick2iron1wood, mine×1.50/quarry×1.35; Rainseed Sickle1iron1wood, farm×1.35; Mason's Hammer1iron2wood, quarry/builder×1.25. These multipliers affect actual work, not only descriptions. One tool per citizen; transferring removes old ownership; no item duplication or ingredient refund occurs. Bounds32items including reserved jobs,4queued jobs,12citizens,24plots. Tool capacity has no salvage yet and is disclosed.

{balance['count']} new legal ten-quest journeys passed, active range{min(ticks)}–{max(ticks)}ticks, median{sorted(ticks)[len(ticks)//2]}. At1× each tick is2seconds; human navigation/menu/thought time is excluded. Every journey then passed8hours of bounded offline replay, consistency and repeated-report checks. The prior50first-chapter scenarios also pass. No human enjoyment/retention, legendary item scaling, armies or1–50campaign completion can be inferred from these tests. Future mineral-depletion and war economies must be balanced after their actual systems exist.
''')
write('ANDROID_TEST_REPORT.md',f'''# Android — verified Iron Age prerequisite B

Version0.8.5-devB/code86; {apk.stat().st_size}bytes; ARM64/x86_64; minAPI24/target36; debug signaturev2/v3. SHA256 `{sha}`. Player package unchanged:org.littlegod.livinguniverse. Install/update/startup succeeded. Existing planet/backup data and absence of temp/settings files were preserved; the report records presence separately. Only disposable org.littlegod.livinguniverse.betaqa was cleared. Prior APKs remain.

{len(android['checks'])} industry checks: actual ten-quest progression, eight rendered structures, paid forge queues, crafted instances, UI equipment effects, exact restore and actual external ADB unequip/re-equip/save. {len(kingdom['checks'])} first-kingdom checks, {len(legacy['checks'])} legacy input/lifecycle/visit checks and {len(native['checks'])} native JSON Save/Open checks pass separately. Engine pinch injection is not claimed as physical two-finger testing. Actual English/Turkish workshop/inventory and planet screenshots were inspected. Raw evidence is in benchmarks/phase09; previous A report is archived under archive/first-kingdom-a.

{table}

Only emulator-5554/API35x86_64,1080×2400portrait/720×1600viewport, Godot4.7.2 GL Compatibility. No physical phone, thermals/battery/OEM safe-area/haptic validation. Samples do not establish stable60/30. Hidden control removes campaign logic and presentation in the same starting ecosystem; no primary save writes. The final APK hash is recorded per profile. See PERFORMANCE_PHASE09.md for bounds and remaining bottlenecks. No App Control/security changes or publishing.
''')
write('TEST_REPORT.md',f'''# Accepted prerequisite-B checks

All406retained checks pass, unchanged: original356plus50First Kingdom checks. Added{tests['passed']}industry checks, total**{406+tests['passed']}**. Exact logs are in benchmarks/phase09/final-*.log. Previous A report is archived under archive/first-kingdom-a.

New coverage: authentic tagged v1 save/explicit transition; preservation of balances/claims/XP/people/wardrobe; real resource conversion; material reservation; assigned smith progress and no-smith stalls; same-clock idempotency; actual boosted harvested stock; atomic tool transfer; unknown/duplicate/dangling items; reserved and finished queue save/load; no ingredient consumption at full storage/absent ore; read-only/public privacy; empty-fuel animation; multiple seeded legal ten-quest and offline journeys; player-save bytes. The first-chapter50scenarios and new50ten-quest/8hour replay scenarios pass separately.

Desktop rendered{len(visual['checks'])}; Android industry{len(android['checks'])}, A{len(kingdom['checks'])}, legacy{len(legacy['checks'])}, native Save/Open{len(native['checks'])}. Godot MCP selected the actual forge and reported no runtime errors. These are automated QA, not human beta or phone evidence. Shutdown ObjectDB/resource warnings are disclosed. Existing backend runtime remains App-Control blocked from0.8 and is not counted passing; no backend source change was made.1–30/1–50campaign, combat, armies, territory, bosses and guild systems are incomplete and have no false passing claim.
''')
write('AGE_OF_KINGDOMS_DESIGN.md','''# Implemented A+B architecture

The original ecosystem remains central. Optional capital campaign v1 supplies the first five quests/civilian economy; explicit ChapterII adds campaign v2/industry v1, five further quests and real mineral→iron→tool work. Original food/population/cell resources have one authority; Stardust stays cosmetic. Public snapshots omit private campaign state.

Ecosystem.tick→Civilization.tick→Kingdom.tick→Industry.tick, guarded by real persisted clocks. Integer thousandths preserve exact material/skill/work state. Four industrial types and four actual civilian tools extend the existing isometric renderer/UI without a second world/economy. Construct with idle citizens, assign jobs, queue reserved-cost crafting, equip/transfer unique tool instances, observe work and claim verified goals. Offline replay follows the original bounded simulation and never silently claims quests.

Bounds:24plots (catalog max21),12citizens,32inventory+queued instances,4pending jobs,30history entries. Old v1 saves remain unchanged until explicit chapter opt-in;600XP opens6, all earlier IDs/claims/artwork/online source remain. Save envelope remainsv1 with strict optional extension schemas. A and B have verified playable checkpoints; C–H remain pending. Adventures/hero combat/loot, armies, regions/finale, side quests and later policies are not represented by fake menus.0.9technology/diplomacy/conquest/dungeons must follow completed0.8.5prerequisites.
''')
quests=json.loads((root/'assets/kingdom/quests.json').read_text(encoding='utf-8'))
qtable='| ID / realm | Quest EN / TR | Real objectives | Rewards |\n|---|---|---|---|\n'
for q in quests:qtable+=f"| {q['id']} / {q['level']} | {' / '.join(q['title'])} | "+'; '.join(o['text'][0]+': '+str(o['target']) for o in q['objectives'])+' | '+', '.join(str(v)+' '+k for k,v in q['rewards'].items())+' |\n'
write('QUEST_DATABASE.md',f'''# Implemented primary quest database — chapters I+II

Ten real main quests; no sidequests or placeholder11–50entries. Stable localized IDs/prerequisites/objectives/rewards/navigation live in assets/kingdom/quests.json. First chapter remains gated at5until explicit opt-in. Quests6–10 involve real quarry/mine/furnace/forge output, completed paid crafting and two equipped citizens working productively. Only current complete goals can be claimed once. Production progress is lifetime within the realm; tool-work counts actual productive equipped-worker turns, not menu taps.

{qtable}

Quest10ends at2200XP/cap10. Actual adventure/combat/army quests remain pending. Navigation opens the actual plot preview, work assignments, workshop or inventory; no scripted fake level increments are used by the reachability probe.
''')
write('PROGRESSION_BALANCE.md',(docs/'BALANCE_PHASE09.md').read_text(encoding='utf-8'))
econ=(archive/'ECONOMY_DESIGN.md').read_text(encoding='utf-8')
write('ECONOMY_DESIGN.md',econ+'''\n## Iron Age — implemented prerequisite B

ChapterII explicitly adds zero ore/iron, preserving all common balances. Quarry/mine consume real rocky cell resources; furnace consumes stored2ore1wood periron. Forge reserves recipe costs and requires actual smith work; unique item IDs and one-owner equipment avoid duplication. Exact costs/effects/limits are in BALANCE_PHASE09.md. Storage applies to ore/iron as to wood/stone; at capacity inputs are not consumed. Core housing/upkeep and cosmetic Stardust are retained. Global plot budget24/catalog21leaves room for every mandatory structure. No war/legendary/paid economy is claimed; those remain future systems.
''')
write('KNOWN_ISSUES.md','''# Known issues — road to0.9, current0.8.5-devB

- A+B only:realm1–10 and ten main quests. Hero/real adventure combat/loot, levels11–30, army/formations/raids, further regions/finale/sidequests/expeditions/policies remain0.8.5prerequisites.0.9levels31–50, technology/diplomacy/tactical conquest/siege/dungeons/legendary gear/guild fallback have not begun. No completed0.8.5or0.9tag.
- Current equipment is useful civilian tools; no fake sword/armor combat bonuses. Inventory32including queued items,4pending jobs,12citizens,24plots/catalog21. There is no salvage/discard or craft cancellation/refund yet. Tools can be freely moved and unequipped. Two completed forges can be selected; queue costs are reserved once, work pauses without assigned smiths or during forge upgrades.
- Vector structures/tools extend retained painted scenery but do not yet provide distinct painted upgrade tiers. Short workplace walk/sway and active warmth are not obstacle-aware hauling/logistics. Dense adjacent mountains can occlude industrial structures; objective/inspect focus and pan/zoom help. Inputs/full storage now stop active work animation.
- The original generic cell resources regrow, including rock. Separate finite mineral deposits, coal and complex refining are absent. B is reachable in50tested seeds plus legacy fixtures, not every arbitrarily edited old terrain; restore suitable terrain or relocate within7tiles after chapter opt-in if needed. First chapter keeps5.5radius; optional old-capital housing/population preservation remains.
- Menus pause work. Keep a free builder; reassign or recruit citizens for concurrent production. No new absence punishment/streak/ads/payment gate was added. Human balancing, accessibility and long-term fun/retention remain untested.
- Emulator frame/startup/shader-cache variability and old Godot cleanup warnings remain. See PERFORMANCE_PHASE09.md. Stable60and30, physical touch/haptics/thermals/battery/OEM layout need a real phone; only emulator ADB and separately labeled engine pinch were tested. Windows native Computer Use was unavailable; Godot/MCP/ADB provided actual rendering.
- Existing updated0.8API/.NET runtime remains Windows-App-Control blocked. No bypass/security changes and no new backend edits. Offline play/read-only export/import remain available; secure live guilds are not claimed ready. No paid service, public deployment, store publication or human testers. Historical issues/reports remain in archive/first-kingdom-a and the preserved0.8documents.
''')
inventory=(docs/'ASSET_INVENTORY.md').read_text(encoding='utf-8');marker='\n## Iron Age prerequisite assets\n'
if marker in inventory:inventory=inventory.split(marker)[0]
write('ASSET_INVENTORY.md',inventory+marker+'''
Four original192²SVG production structures (quarry/mine/furnace/forge), shared768×192industry atlas and four192²tool SVG icons (axe/pick/sickle/hammer), reproducible with devtools/create_industry_art.py. Native vector generation extends the established palette; no external image/stock/paid API was used for this slice. Existing Arin generated raster, painted original terrain/species, old atlases and licenses remain. Workplace animation and warm production pulses use actual simulation state. phase09-* captures are actual Godot/Android renders reached by legal automated actions, not concept art or human progress.
''')
print('Honest prerequisite-B report generated; full0.9 remains incomplete.')
