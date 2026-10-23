"""Document only measured/verified E2 prerequisites; never mark the E3 dungeon complete."""
from pathlib import Path
import json,shutil,hashlib
r=Path(__file__).resolve().parents[1];out=r/'builds/phase085e2full';docs=r/'docs';bench=docs/'benchmarks/phase085e2full';bench.mkdir(parents=True,exist_ok=True)
def read(path):return json.loads(path.read_text(encoding='utf-8-sig'))
v=read(out/'verification.json');render=read(out/'rendered.json');assert v['all_passed'] and v['game_checks']==745 and render['all_passed']
native={}
for fps in [60,30]:
 d=out/f'android-{fps}';first=read(d/'before-restart.json');result=read(d/'result.json');proof=read(d/'preservation.json')
 assert first['all_passed'] and result['all_passed'] and proof['player_files_unchanged']
 native[fps]=result
 for name in ['before-restart.json','result.json','preservation.json','startup.txt','memory.txt','logcat.txt']:shutil.copyfile(d/name,bench/f'android-{fps}-{name}')
iron=out/'android-iron-60';assert read(iron/'result.json')['all_passed'] and read(iron/'reopen.json')['all_passed']
for name in ['result.json','reopen.json','preservation.json']:shutil.copyfile(iron/name,bench/('iron-'+name))
player=out/'player-install';assert read(player/'result.json')['signature_verified']
for name in ['result.json','signature.txt','startup.txt','logcat.txt']:shutil.copyfile(player/name,bench/('player-'+name))
for name in ['verification.json','rendered.json','desert.log']:shutil.copyfile(out/name,bench/name)
shutil.copyfile(r/'builds/desert-mcp.log',bench/'godot-mcp.log')
for name in ['mcp-desert-card-tr','mcp-desert-entry-tr']:shutil.copyfile(out/(name+'.png'),docs/('screenshots/phase085e2-'+name+'.png'))
for name in ['desert-entry-tr','oasis-discovery-tr','scorpion-warning-tr','poison-status-tr','crystal-pickup-tr','quest22-complete-tr']:
 shutil.copyfile(out/(name+'.png'),docs/('screenshots/phase085e2-'+name+'.png'))
for name in ['android-desert-poison','android-desert-restored','android-quest22-complete-tr']:
 shutil.copyfile(out/'android-60'/(name+'.png'),docs/('screenshots/phase085e2-'+name+'.png'))
history=docs/'history';history.mkdir(exist_ok=True)
for name in ['STATUS.md','KNOWN_ISSUES.md','QUEST_22_DESIGN.md','REGIONAL_ADVENTURE_ARCHITECTURE.md','REGIONAL_ENEMIES.md','SAVE_MIGRATION_MILESTONE_E2.md','AGE085_E2_REPORT.md','PERFORMANCE_MILESTONE_E2.md','MILESTONE_E_CONTINUATION.md']:
 dest=history/('E2B-'+name)
 if not dest.exists():shutil.copyfile(docs/name,dest)
def write(name,text):(docs/name).write_text(text.strip()+'\n',encoding='utf-8')
apk=r/'builds/android/LittleGod-0.8.5-milestone-E2-debug.apk';sha=hashlib.sha256(apk.read_bytes()).hexdigest()
rows=[]
for fps,result in native.items():
 for key,label in [('combat_profile','Desert encounters'),('profile','Cleared ancient road')]:
  p=result[key];rows.append(f'|Emulator {fps} · {label}|{p["fps"]:.2f}|{p["p95_ms"]:.2f}|')
table='\n'.join(rows);p=render['profile'];nchecks=len(read(out/'android-60/before-restart.json')['checks'])+len(native[60]['checks'])
write('STATUS.md',f'''
# LittleGod — E2: Beyond the Kingdom; E3 prerequisites

Current verified release: **0.8.5-devE2 / Android code91**, realm campaign1–22. The E3 audit correctly found the previous E2B checkpoint incomplete. This run completed the missing critical E2 gameplay before starting any dungeon. **E3 Sunken Sanctuary, puzzles, elites, Sun Relic, advanced equipment and quest23 are not implemented.** No E3 completion tag is claimed.

Wildwood, playable Iron Hills and playable Ashen Desert now share the existing hero/combat/camera/input/loot architecture. The desert adds original terrain/props/palms, oasis discovery with one saved recovery, ancient road lore, three distinct fighting enemies, four-second non-stacking poison, finite crystals, a useful staffed-forge purification tonic, safe return and real quest22 crystal registration. Existing trade posts, caravans/escrow/guards, workers, industry, military, heroes/gear, old regions, bosses and planet saves remain.

**745 game checks pass:689 retained unchanged +56 new.** Three legal1–22 campaign seeds pass without XP/quest/resource injection.15 actual rendered desktop checks pass, including real sting/poison and quest22. Godot MCP inspection is recorded separately. Android has{nchecks} native/restart checks at each60/30 cap, including force-stop with active poison and exact restoration, real joystick/attack/dodge/inspect/home/register/claim input. Current E2 APK also passes26 retained native mountain/restart checks. Bot navigation is explicitly distinguished from external touchscreen input.

| Scene | FPS | p95 ms |
|---|---:|---:|
{table}

Desktop desert: {p['fps']:.2f}FPS / p95{p['p95_ms']:.2f}ms. No physical E2 device verification: connected phone is ADB unauthorized. Emulator samples do not establish phone thermals, battery or haptics. Player update/startup and v2/v3 signature verification pass; private test slots/marker preserve primary, backup, temp and settings bytes.

- Desktop: `D:/LittleGod/Launch LittleGod.cmd`.
- Verified runtime: `D:/LittleGod/tools/godot/Godot_v4.7.2-stable_win64.exe`.
- Player APK: `D:/LittleGod/builds/android/LittleGod-0.8.5-milestone-E2-debug.apk`.
- QA APK: `D:/LittleGod/builds/android/LittleGod-0.8.5-milestone-E2-qa-debug.apk` (`.betaqa`).
- Source: `D:/LittleGod/builds/LittleGod-0.8.5-milestone-E2-source.zip`.
- Git: `age085-e2-regions`; exact commit/build/archive hashes: `D:/LittleGod/builds/phase085e2full/checkpoint-manifest.json`.
- APK SHA256: `{sha}`.

After real quest21, discover the northern Forgotten Mine in Iron Hills and return home. Choose Ashen Desert in the world map; this opt-in activates22. Discover the oasis, defeat a desert enemy, inspect crystals and return. Use Arin's desert report to register one actual crystal, then claim22. Spare crystals plus herbs/gold become purification tonics through real forge labor. One required crystal is protected until registration. In the desert, Heal uses a tonic first and clears poison; Home also clears poison safely.

See AGE085_E2_REPORT.md, AGE085_E3_REPORT.md (explicitly partial), QUEST_22_DESIGN.md, REGIONAL_ADVENTURE_ARCHITECTURE.md, REGIONAL_ENEMIES.md, SAVE_MIGRATION_MILESTONE_E2.md, PERFORMANCE_MILESTONE_E2.md and MILESTONE_E_CONTINUATION.md. Previous E2B reports remain in docs/history. No paid infrastructure, public publishing or security change occurred.

![Actual oasis discovery](screenshots/phase085e2-oasis-discovery-tr.png)
![Actual poison HUD](screenshots/phase085e2-poison-status-tr.png)
![Actual quest22 completion](screenshots/phase085e2-quest22-complete-tr.png)
''')
write('AGE085_E2_REPORT.md',f'''
# E2 — verified prerequisite completed during the E3 audit

Audit baseline45cc684 / age085-e2b-iron-hills genuinely contained mountains but no playable desert or quest22. `age085-e3-base-e2b` protects that start. No E3 dungeon was started before correcting the missing foundation. This checkpoint is0.8.5-devE2/code91, actual campaign1–22 and tag `age085-e2-regions`; it is not complete E3 or complete overall E.

Implemented actual960×1440 Ashen Desert navigation/collision on the original Adventure Mode, original sand/dunes/sandstone/palms/road/oasis art, visible water ripple/drifting sand, distinctive three-enemy combat, finite crystal collection, oasis recovery/discovery, historical road entry, useful purification tonic through the original forge, quest22 event provenance/registration and localized navigation hints. All earlier regions, sources, art, save fixtures and builds remain. No boss/E3 relic was invented.

Sand Stalker pursues quickly and disengages diagonally after a short strike. Dune Scorpion uses a slow aimed heavy sting, four-second poison and an armor opening during recovery. Ruin Sentinel guards/leashes to its ruin and locks a visible ranged impact circle, checking terrain line of sight. All attacks use actual HP, collision and damage; no menu combat stands in for rendered play. Poison advances on the authoritative20Hz adventure clock only, never wall-clock/offline time, and has exactly four2HP ticks per uninterrupted application. Reapplication refreshes duration without stacking. Tonic, oasis recovery, defeat and home return clear it consistently.

Crystals are a single concise new stackable warehouse material, not a second inventory. Sources are6 finite node crystals and2 from each scorpion/sentinel. Their consumer is the real four-tick staffed-forge tonic:2 crystal,1 herb,1 gold → one32-slot consumable; Heal consumes it to restore35HP and cure poison. Registration consumes one proven returned crystal exactly once. Crafting protects the last required crystal until registered. The optional ancient road adds persistent short lore. Material/node/enemy/unique old boss rewards do not refresh on load. Gold remains the existing wallet limit rather than being incorrectly limited by warehouse size.

All689 retained assertions and56 new checks pass (745). Authentic E2B fixture was generated before new desert code, through legal1–21/mountains plus a pending caravan and potion craft queue. Three1–22 seed journeys, legacy C/D/E1/E2B roundtrips, poison/clock/idempotency/capacity/provenance/forge/return/readonly/malformed-state tests pass.15 actual desktop rendered checks exercise movement, combat, warning, real poison, oasis, crystal, road, home and22. Android native checks ({nchecks} per cap) use actual ADB controls and a real process restart while poisoned.26 retained mountain native/restart checks pass on the new E2 QA APK. Bot route-following is labeled separately.

Player APK v2/v3 signature, in-place update and private benchmark startup pass without changing player primary/backup/temp/settings bytes. Phone was unauthorized, so phone verification is not claimed. Measured performance/memory and limits are in PERFORMANCE_MILESTONE_E2.md; raw copies under docs/benchmarks/phase085e2full and builds/phase085e2full. Existing shutdown cleanup and cached-shader warnings are retained, not hidden as successes for script errors.

Deliverables: desktop launcher, player/isolated QA APKs, original integrated artwork, actual screenshots, tests and source ZIP. Exact paths/hashes: STATUS.md and builds/phase085e2full/checkpoint-manifest.json. E3 dungeon/puzzles/hazards/elites/unique relic/advanced equipment/quest23 remain explicit next work. No E4–E6,0.9, public launch or paid service was started.
''')
write('AGE085_E3_REPORT.md','''
# E3 audit checkpoint — prerequisite work only

The supplied E3 request explicitly requires unfinished E2 to be completed first. The starting E2B tag lacked Ashen Desert, poison, regional material consumer and quest22. This run implemented and verified those critical prerequisites, leaving a working E2 checkpoint with exact continuation instructions.

**E3 itself is not complete and its dungeon has not been started.** There is no Sunken Sanctuary, five-room dungeon, puzzle/door/hazard engine, Ancient Sentinel/Shade/Warden encounter, Sun Relic, advanced equipment or quest23 claim. No age085-e3-ancients tag or E3 APK is produced. Do not present the new desert as the requested dungeon.

The original E3 brief is preserved as MILESTONE_E3_BRIEF.md. Current code/testing/art/Android delivery is detailed in AGE085_E2_REPORT.md and STATUS.md. E3 must continue from a genuine legally reachable22, retain all745 current game checks and extend the original regional/combat/industry ownership model. MILESTONE_E_CONTINUATION.md records the ordered next slices and safeguards. No E4 has started.
''')
write('QUEST_22_DESIGN.md','''
# Quest22 — The Ashen Desert

The previous E2B campaign stops at21. Completing21 and discovering the Forgotten Mine enables desert selection. Actual entry creates an optional version2 regional record, initializes a zero crystal balance and activates22. Merely opening the map creates no quest events or stock. Earlier saves and tests retain the1–21 cap until opt-in.

Objectives: actual desert entry → actual oasis inspection → eligible actual desert kill → canonical desert-crystal pickup → safe home return with recorded expedition proof → consume/register one crystal with Arin → ordered claim22. Rewards are880 realmXP and4 each gold/wood/stone, exactly once. Registered material cannot be substituted with unrelated stock before the actual pickup/kill/discovery proof. Validator checks event flags against persistent region evidence.

Canonical pickup records crystal provenance; any return banks actual cargo. A defeated return preserves loot under the established Adventure policy, clears poison and restores the hero, but does not set safe-return proof. Re-enter and return alive after the real discoveries to complete recovery without farming another finite node. The last required home crystal is protected from tonic crafting until registration, preventing a depletion softlock. Returning cannot duplicate cargo or claims.

Advisor actions open the actual desert destination or Arin's registration panel. The in-region Guide button points to oasis, a living enemy, crystal node or the return trail and explains the current action. Home is always available, including defeat. TR/EN hints are short and do not interrupt combat. See tests/desert.gd and the native Android driver for actual input/progression proof.
''')
write('REGIONAL_ADVENTURE_ARCHITECTURE.md','''
# E2 regional architecture

The original Adventure Mode remains the authority for movement, CharacterBody2D collision,20Hz combat, hero stats, inventory, loot, camera, native joystick/attack/dodge/heal and return. Trusted local registry IDs are wildwood, iron_hills and ashen_desert; trade post hills remains a separate strategic route. The live scene chooses the region's real map geometry and original art. No remote scripts or static concept-art encounters are used.

E2B introduced optional adventure.regions.version1 with at most two parked inactive runs. E2 preserves that record and all old run data. Actual desert entry after21 and the discovered mine upgrades it to version2 and adds seven boolean quest-proof flags plus one zero-initialized stock key desert_crystal. Old saves are not automatically reset or upgraded on load. Current run has the only active region/cargo owner; switching removes it from stored and parks the old inactive run. Legacy missing region means Wildwood. No cross-region item/cargo copying is performed.

New desert run fields: region, nodes.crystal, poison_until, poison_next, recovered and road. Existing landmark means the oasis. Timers use the persisted adventure clock and are normalized after JSON load. Region-specific shape/enemy/material/proof validation rejects unsupported kinds, duplicate region/run IDs, impossible poison and quest flags without actual saved discovery/kill/pickup evidence. All three regions can be switched/restored while retaining the old boss and equipment identities.

Deposits are finite and never refresh in E2. Mountain nodes produce6 ore/5 stone; desert node produces6 crystals. Desert enemies provide4 more crystals. Pickup checks canonical loot identity, reach, alive/active state, per-resource warehouse capacity and current cargo before mutation. Gold follows the existing wallet ceiling. Node depletion is committed only after successful pickup. Recipes/gear use the original32-item/four-job system; ordinary materials use existing thousandth-unit stock/cargo stacks. No second inventory exists.

Clock policy: every active adventure, including absence or defeat awaiting return, freezes home/industry/military/caravan/offline ticks. Regional pause also freezes adventure timers. Poison has no wall-clock catch-up. Home return banks actual cargo once, clears poison, restores health and the saved home pause preference. E1 Live Route Watch intentionally advances home/caravan ticks while watching and restores prior pause on close; its behavior remains distinct.

Oasis discovery/history is persistent; its optional35HP recovery and poison cure is usable once, saved forever. Road lore is optional. The in-region Guide points to the next real objective. Home is always available; failed expeditions retain committed discoveries/loot, with a fair safe-return retry for22. Crystal registration consumes one real proven material; forge spending protects the final required unit until registered.

Tests: retained689 checks, tests/desert.gd, tests/desert_playtest.gd, scripts/desert_qa.gd and devtools/android_desert_validate.py. QA alone may be cleared. Native gestures and bot route-following are reported separately. The E3 dungeon is not yet part of this architecture; extend it without replacing original ownership or clock semantics.
''')
write('REGIONAL_ENEMIES.md','''
# E2 regional enemies

The original Wildwood enemies/Thornheart remain unchanged. Mountains retain Stone Crawler (74HP/7armor, slow aimed1050ms heavy strike/1550ms recovery) and Cave Stalker (46HP/1armor,420ms locked lunge/850ms recovery with diagonal disengagement). Original artwork, death/loot identities and finite mountain state persist.

| Desert enemy | HP / armor | Behavior | Real reward |
|---|---|---|---|
|Sand Stalker|50 /1|165units/s pursuit;350ms short melee warning;1000ms recovery with350ms disengagement; no wolf-identical idle recovery|2 leather,36XP, weighted herb/gold|
|Dune Scorpion|80 /8|58units/s;1050ms aimed107-unit heavy sting;2000ms recovery with armor reduced to0; actual hit applies poison|2 crystals,42XP, weighted herb/iron|
|Ruin Sentinel|88 /5|72units/s;guards650,350; returns when hero leaves330-unit guard area;900ms locked65-radius ranged impact warning and1500ms recovery; terrain line-of-sight checks|2 crystals,48XP, weighted iron/gold|

Poison is non-stacking four-second status: four2HP ticks on authoritative simulation time. It persists across an active save/relaunch with no duplicate tick or offline damage, and clears on home return, defeat, purification tonic or the once-only oasis recovery. Actual damage requires a hit and can be dodged. Scorpion recovery opens a real armor window. Saved states drive visible telegraphs, HP bars, attack sway, hit numbers and defeat fade; no text-only combat or new boss is substituted for an encounter.

Each region has bounded canonical enemies, no reward reroll/respawn and exactly-once loot IDs per run. The desert enemies reuse shared hit/dodge/gear/collision/loot infrastructure but have separate state logic. Automated and rendered tests verify genuine warnings, damage, misses, poison timing, pursuit/recovery/guard behavior and legal victory with currently available gear.
''')
write('SAVE_MIGRATION_MILESTONE_E2.md','''
# E2 save compatibility

Authentic E2B fixture tests/fixtures/planet-v085e2b.json was generated at45cc684 before desert source existed, through real1–21/mountain progression and real pending caravan/forge commands. The generator guards both that commit and absence of ashen_desert.gd. C/D/E1 fixtures remain unchanged. Real player slots are never used for fixture generation or QA reset.

Existing E2B regional version1 and old saves load without automatic new stock/progression. Actual unlocked desert entry adds only optional regional version2, quest-proof flags, desert run and zero crystal stock. Kingdom/adventure versions, workers, gear IDs, industry items/jobs, military kits/assignments, trade quotes/routes/escrow/cargo/escorts, original planet and old boss rewards stay canonical. Parked regions are moved rather than copied. Migrations are idempotent and shape-validated.

The desert clock, enemy windups/HP, poison deadlines/next tick, finite node/loot, oasis discovery/recovery, road, cargo and quest proof persist. Native Android force-stop while poisoned restores exact active kingdom state and paused home/caravan ticks before resuming. Status never processes twice on the same clock. Home clears status and banks cargo once. A defeated return keeps existing fair loot recovery but requires an alive return for safe-return quest proof.

Material use goes through the existing stock/industry pipeline. The tonic is a real queued item, capacity/cost checked with real smith work; one required crystal is reserved until registration. Registration/quest rewards are exactly once, and validators require saved source evidence for objective flags. Node depletion commits only with successful pickup and cannot reset through loading/re-entry. No unowned item or duplicate artifact is created.

Tests include exact active/poison/complete roundtrips, C/D/E1/E2B legacy saves, pending trade/forge preservation, repeated offline pause, readonly rejection, malformed and forged proof, multiple region restoration, finite gathering/capacity, status bounds, real consumer, protected quest stock and three legal1–22 seeds. Android QA uses .betaqa and private files; player primary/backup/temp/settings bytes are compared through QA and player-package update/private benchmark startup. No physical E2 validation is inferred from emulator results.
''')
write('MILESTONE_E_CONTINUATION.md','''
# Continue E3 from verified E2

Current release:0.8.5-devE2/code91, age085-e2-regions, real1–22. The E3 audit began at45cc684 / age085-e2b-iron-hills and protected it as age085-e3-base-e2b. Missing E2 desert/poison/material consumer/quest22 were implemented and verified first. E3 itself is not started: no dungeon, puzzles, hazards, elites, Sun Relic, advanced equipment or23. Do not create age085-e3-ancients until complete E3 acceptance; do not begin E4–E6/0.9/1.0.

Read MILESTONE_E3_BRIEF.md, STATUS.md, AGE085_E2_REPORT.md and the explicitly partial AGE085_E3_REPORT.md. Run devtools/verify_desert.py (745 game checks), then real desert/mountain rendered tests. All fixtures/rendered tests must use private paths; no player reset. Preserve C/D/E1/E2B/E2 history, online source, artwork and APKs. Never fabricate historical fixtures from newer code.

E3A next: extend the trusted regional architecture with Sunken Sanctuary and an actual entrance tied to desert/claimed22. Use the original shared controller/combat/collision/HUD/save model. Build five meaningful connected spaces with readable paths, camera bounds, inscription and safe Home exit. Do not enable23 from opening a map or insert fake room text instead of navigation. Preserve existing clock policy and parked-run ownership. Current state permits two parked regions for three total regions; adding a fourth requires explicit bounded schema/validation changes, not truncation of old regions.

E3B: persistent pressure plates plus ordered switches, sealed doors with real collision/open animation, two fair hazards with warning/damage/dodge/recovery, contextual hints and interrupted-save/anti-softlock tests. Solutions must be deterministic and always recoverable. Home remains available.

E3C: Ancient Sentinel guard/frontal/counter pattern, Sun Priest Shade ranged/relocation/area-denial pattern and compact Sunward Warden melee/directional-energy/shield-opening encounter. Reuse hit/gear/loot infrastructure, not unchanged recolors. Do not add Azrakh. Verify actual fights, damage/counterplay and distinct original sprites in rendered scenes.

E3D: discoverable optional passage/treasury, two lore findings and unique chamber, exact-once real Sun Relic interaction after Warden. Keep committed unique claims on defeat/re-entry/load and record concise Sunforged Dynasty lore. No fabricated offline discoveries.

E3E: concise useful dungeon materials, real existing staffed-forge recipes, distinct deterministic combat effects and UI descriptions, canonical inventory/kit/tool/relic protections. Quest23 requires claimed22, real dungeon inscription/mechanism/elite/relic, actual home return/research, legitimate materials/forge work and equipping a meaningful upgrade. No injected XP, free materials or arbitrary flags. Test legal1–23 seeds and exactly-once rewards.

E3F: actual five-room/puzzle/hazard/combat/secret/relic/forge/23 screenshots, complete migrations/retained745 checks, independent dungeon performance/memory, isolated Android native controls and genuine process restart at60/30. Bot navigation is not external touch. Player APK signing/update/startup must preserve byte-identical primary/backup/temp/settings; phone was unauthorized during the E2 run, so recheck rather than assume phone verification. No security/App Control bypass.

Current invariants: regional version2 is opt-in at actual desert entry after21/mine. Stock has one new desert_crystal key only then; current and parked runs retain unique owners. Finite mountain/desert deposits never refresh. Desert totals10 crystals;22 registration consumes1 and tonic consumes2 crystal+1herb+1gold via four real forge ticks. Last quest crystal is protected. Poison is four2HP ticks over4 seconds on simulation clock, saved/idempotent, cleared by tonic/once-only oasis/defeat/home. Any active adventure freezes home/industry/caravan/offline time; E1 Live Route Watch separately advances home then restores pause. Preserve all of it while adding dungeon behavior.

After all E3 acceptance passes, export a new correctly versioned E3 player/QA APK and source archive, update truthful reports and tag age085-e3-ancients. No complete overall E tag until E1–E6 actually exist.
''')
write('PERFORMANCE_MILESTONE_E2.md',f'''
# E2 desert performance

Desktop RTX4070 and Android emulator/API35/x86_64/OpenGL translation are reported separately. The physical Samsung phone remained ADB unauthorized; no phone performance/thermal/battery/haptic claim is made.

| Scene | FPS | p95 ms |
|---|---:|---:|
{table}
|Desktop cleared desert road|{p['fps']:.2f}|{p['p95_ms']:.2f}|

Desktop setup {p['setup_ms']:.2f}ms, {int(p['draw_calls'])} draw calls, {p['step_us']}µs average model/collision step, {p['static_bytes']/1048576:.2f}MiB static memory. Android60 cleared road: setup{native[60]['profile']['setup_ms']:.2f}ms, {int(native[60]['profile']['draw_calls'])}draw calls, {native[60]['profile']['static_bytes']/1048576:.2f}MiB static / {native[60]['profile']['video_bytes']/1048576:.2f}MiB reported video memory. Full OS PSS/RSS and activity launch time are separate raw records, not the same allocator measurement.

The region uses one imported original960×1440 terrain layer, shared cached sprite resources, bounded3 enemies/20 loot entries and at most2 parked regions. No dynamic shadow lights or particle systems were added. Sand uses6 lightweight streaks; oasis uses one animated arc. Combat remains20Hz; cap30 uses the existing battery-saver settings. Active combat is a short bot-assisted encounter sample, not a sustained stress test; cleared-road samples span8 seconds. Native gestures and bot navigation are labeled separately.

Historical E2B mountain and E1 live-route results concern different scenes; do not compare them as identical benchmarks. Existing E2B degraded long-emulator-session evidence remains under benchmarks/phase085e2. Current raw desert samples live under benchmarks/phase085e2full. Startup shader-cache recompilation warnings and known Godot headless/editor/export ObjectDB/resource warnings remain. Reproduce with devtools/android_desert_validate.py --fps 60 / --fps 30. No security bypass or emulator wipe was used.
''')
write('KNOWN_ISSUES.md','''
# Known issues —0.8.5-devE2

- E2 core regions and quest22 are verified. E3 dungeon/puzzles/hazards/elites/relic/equipment/quest23 are not implemented. No E3 completion tag, E4 work or complete overall E claim exists.
- Mountain/desert node and enemy rewards are finite, persisted and not refreshed on re-entry. Desert provides10 total crystals (node6 + scorpion2 + sentinel2); registration consumes1, tonic crafting consumes2. There is no repeatable outpost production. Clear warehouse space before gathering; uncollected loot remains.
- The compact C Warrior controls/camera remain, with shared20Hz combat and modest vector animations. Sentinel is a telegraphed ranged impact-area attack, not a new projectile engine. Desert has no boss. The oasis has one saved35HP recovery, not unlimited regeneration.
- Defeat retains collected loot and restores health at home under existing policy. Safe-return proof for22 requires a subsequent alive return if defeated. Last required crystal is protected from tonic crafting; artifacts/military/gear ownership remains unchanged.
- Phone was unauthorized during E2 verification. Emulator short60/30 results do not establish phone thermals, battery, simultaneous multitouch, haptics or OEM cutouts. Long-lived emulator sessions can degrade; historical degraded samples remain.
- Existing shader-cache recompilation and Godot headless/editor/export cleanup warnings remain. New script errors and failed tests are not accepted. Native Computer Use was unavailable; actual Godot/MCP/ADB rendering supplies evidence.
- Existing32-item/four-job inventory, salvage protections and bounded strategic caravan model remain. Adventure/offline/home/caravan time freezes in any active region; E1 Live Route Watch separately advances home ticks then restores prior pause.
- Online/.NET App Control blockage remains untouched. No paid infrastructure, security bypass, public publishing or store release occurred. Historical reports/builds are preserved.
''')
for path in list(bench.glob('*.txt'))+list(bench.glob('*.log')):path.write_text('\n'.join(line.rstrip() for line in path.read_text(encoding='utf-8').splitlines()).rstrip()+'\n',encoding='utf-8')
print('Wrote verified E2 prerequisite reports; E3 explicitly unfinished')
