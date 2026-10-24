"""Create E3 reports only from successful retained/model/rendered/Android evidence."""
from pathlib import Path
import hashlib,json,shutil
r=Path(__file__).resolve().parents[1];out=r/'builds/phase085e3';docs=r/'docs'
def read(p):return json.loads(p.read_text(encoding='utf-8-sig'))
verification=read(out/'verification.json');rendered=read(out/'rendered.json')
assert verification['all_passed'] and rendered['all_passed']
assert rendered['checks']['pack_pauses'] and rendered['checks']['pause_closes_pack']
for name in ['sanctuary-rendered.log','sanctuary-final-ui.log','sanctuary-mcp.log']:
 text=(r/'builds'/name).read_text(encoding='utf-8-sig')
 assert 'SCRIPT ERROR' not in text and 'Parse Error' not in text,name
 assert not [line for line in text.splitlines() if 'ERROR:' in line and 'resources still in use at exit' not in line],name
android={fps:read(out/f'android-{fps}/result.json') for fps in [60,30]}
for fps,result in android.items():
 assert result['all_passed'] and read(out/f'android-{fps}/before-restart.json')['all_passed']
 assert read(out/f'android-{fps}/before-restart.json')['checks']['native_pack_pause']
 assert 'effect_draw_us' in result['profile']
 assert result['apk_sha256']==hashlib.sha256((r/'builds/android/LittleGod-0.8.5-milestone-E3-qa-debug.apk').read_bytes()).hexdigest()
 assert read(out/f'android-{fps}/preservation.json')['player_files_unchanged']
 assert 'SCRIPT ERROR' not in (out/f'android-{fps}/logcat.txt').read_text(encoding='utf-8',errors='replace')
assert read(out/'player-install/result.json')['signature_verified']
assert read(out/'player-install/result.json')['apk_sha256']==hashlib.sha256((r/'builds/android/LittleGod-0.8.5-milestone-E3-debug.apk').read_bytes()).hexdigest()
history=docs/'history';history.mkdir(exist_ok=True)
for name in ['STATUS.md','KNOWN_ISSUES.md','AGE085_E3_REPORT.md','MILESTONE_E_CONTINUATION.md']:
 dest=history/('PRE_E3_'+name)
 if not dest.exists():shutil.copyfile(docs/name,dest)
evidence=docs/'benchmarks/phase085e3';evidence.mkdir(parents=True,exist_ok=True)
for name in ['verification.json','rendered.json','sanctuary.log']:
 source=out/name
 (evidence/name).write_text('\n'.join(line.rstrip() for line in source.read_text(encoding='utf-8-sig').splitlines()).rstrip()+'\n',encoding='utf-8')
for name in ['sanctuary-rendered.log','sanctuary-final-ui.log','sanctuary-mcp.log']:
 (evidence/name).write_text('\n'.join(line.rstrip() for line in (r/'builds'/name).read_text(encoding='utf-8-sig').splitlines()).rstrip()+'\n',encoding='utf-8')
for fps in [60,30]:
 dest=evidence/f'android-{fps}';dest.mkdir(exist_ok=True)
 for name in ['before-restart.json','result.json','preservation.json','memory.txt','startup.txt','combat-frames.json']:
  source=out/f'android-{fps}'/name
  (dest/name).write_text('\n'.join(line.rstrip() for line in source.read_text(encoding='utf-8-sig').splitlines()).rstrip()+'\n',encoding='utf-8')
dest=evidence/'player-install';dest.mkdir(exist_ok=True)
for name in ['result.json','signature.txt','startup.txt']:
 (dest/name).write_text('\n'.join(line.rstrip() for line in (out/'player-install'/name).read_text(encoding='utf-8-sig').splitlines()).rstrip()+'\n',encoding='utf-8')
screens=docs/'screenshots';screens.mkdir(exist_ok=True)
for p in out.glob('*.png'):shutil.copyfile(p,screens/('phase085e3-'+p.name))
for p in (out/'android-60').glob('*.png'):shutil.copyfile(p,screens/('phase085e3-'+p.name))
count=verification['game_checks'];new=verification['sanctuary_checks'];desktop=rendered['profile']
table='| Measured scene | FPS | p95 ms |\n|---|---:|---:|\n'
table+=f"| Desktop · relic chamber | {desktop['fps']:.2f} | {desktop['p95_ms']:.2f} |\n"
for fps,d in android.items():
 for name,key in [('Sustained combat (test path generation excluded)','profile'),('Relic chamber','steady_profile')]:
  p=d[key];table+=f"| Emulator {fps} · {name} | {p['fps']:.2f} | {p['p95_ms']:.2f} |\n"
report=f'''# E3 — Secrets of the Ancients

Verified development build: **0.8.5-devE3 / Android code92**, real realm quests1–23. Baseline57ca7fa / age085-e2-regions is retained as age085-e4-base-e2. Work is isolated on work/e3-sanctuary-validation. Earlier E3 prerequisite-only reports are preserved in docs/history/PRE_E3_*. No E4, E5, E6, throne or Visual Rebirth V4 implementation is claimed.

Sunken Sanctuary is an opt-in fourth region beneath Ashen Desert, unlocked by claimed22 and an armed Warrior. Five connected spaces use the existing CharacterBody2D controller, camera, combat, equipment, inventory, home and save architecture. Two ordered persistent puzzles control colliding animated doors. Two periodic hazards have warning, active and recovery windows, real damage, dodge protection and once-per-cycle persistence. Wrong sequences reset safely; solved gates latch. Home is always available.

Ancient Sentinel has a frontal strike, defensive counter and recovery opening. Sun Priest's Shade has an aimed hitscan spell, locked-target area attack and short recovery relocation. Sunward Warden alternates frontal strike/directional energy, with real armor and vulnerability windows. Shared death/XP/loot code still owns rewards. Dungeon attacks respect walls and closed doors.

The cracked-wall passage leads to optional treasure. Inscription and abandoned-forge lore reveal the Sunforged Dynasty; treasury, relic discovery and research enter the localized Chronicle. The unique Sun Relic is an actual industry item with one persistent ID, protected from crafting/salvage. A full inventory leaves one canonical pickup on the pedestal and supports safe retry. At home its research unlocks four staffed-forge recipes: Ancient Iron Blade (+20 attack), Sunguard Shield (+7 defense), Ruinwalker Armor (+18HP/+4defense/+4 trap resistance), Sunstone Talisman (+2 trap resistance). Resistance stacks only for dungeon hazards; minimum damage1. Gear effects are consumed by real combat.

Finite dungeon rewards total7 alloy,1 core and4 sunstone fragments. Crafting all four spends6 alloy,1 core and2 fragments plus real old materials and labor. No free resources, XP, quest flags or kills are inserted in legal journeys. Quest23 requires inscription, both mechanisms, Warden defeat, relic ownership, alive return, research, and forging/equipping an upgrade; its reward claims once.

Original assets: vector room floor/wall/preview, tablet, pedestal, three distinct elite silhouettes, three material icons, relic and four equipment icons. Source generator: devtools/create_sanctuary_art.py. Eight original bounded mono PCM cues cover stone steps, switch, door, trap warning/activation, sword swing/impact and relic. Generator: devtools/create_sanctuary_audio.py. Existing Warrior artwork is preserved. Doors fade open; runes/plates, telegraphs, hit flash and death feedback follow simulation state. This is modest procedural presentation, not a frame-animation remake or an approved V4 style.

**{count} game checks pass:745 retained unchanged +{new} E3 checks.** Three legal1–23 seeds7/42/2026 pass with all four items actually forged/equipped. Tests cover old saves, pending forge/caravan preservation, active/puzzle/trap/full-inventory saves, offline freeze, read-only APIs, malformed state, elite attacks, material conservation, unique relic retry/protection, quest once and four-region identity. The authentic E2 fixture was made from the old checkpoint before sanctuary code, not fabricated from new data. Rendered desktop has {len(rendered['checks'])} passing checks, including real navigation/collision/puzzles/combat/relic/treasure/return/research/forge/equip/23 and a final saved world. A real workshop localization error found visually was corrected; script errors are rejected independently of boolean reports.

Android native input covers entry, joystick, inscription, all three switches, attack, dodge, relic pickup, return, research and quest23 reward. Automated routes, combat commands and forge/equip helpers are explicitly labelled. Force-stop/reopen verifies exact active puzzle/world restoration at both caps. QA runs in .betaqa and player primary/backup/temp/settings bytes are preserved. Player APK signing, update and private-marker startup pass separately. No physical phone was connected in the final ADB inventory; no phone performance, thermals, battery, haptic or simultaneous-multitouch claim is made.

{table}

Desktop setup {desktop['setup_ms']:.2f}ms, simulation step {desktop['simulation_step_us']}µs, {desktop['draw_calls']:.0f} sampled draw calls, static tracked memory {desktop['static_bytes']/1048576:.2f}MiB. Android measurements, memory snapshots and frame samples are in docs/benchmarks/phase085e3. Initial inclusive bot samples were poor (21.79FPS/p95137.93ms; after reboot17.83FPS/p95160.64ms). They remain in builds/phase085e3/android-60-initial and android-60-inclusive. Those include developer AStar route construction; the final combat sampler excludes test navigation and records steady rendering separately. These are distinct measurements, not a claim that reboot fixed the game. No stable60FPS guarantee is made for physical mid-range devices.

The measured pre-cache sustained-combat run was24.21FPS/p9593.65ms at60, and19.07FPS/p9577.73ms at30; retained in builds/phase085e3/android-60-before-cache and android-30-before-cache. Sanctuary's static inscriptions/geometry now retain canvas commands until their phase/mechanism/door fade changes. Combat effects rebuild at the authoritative20Hz instead of every render frame, and unchanged door colliders are not reassigned. These changes preserve simulation and telegraph timing. Final Android profiles include whole-physics-callback and effect-draw CPU counters. No global timescale or game-balance change was used. Pack opening/closing and Pause interruption clear held/pending attack input, and are verified with external Android taps. Godot MCP separately rendered the actual authentic-E2 destination and entry; its error list was empty. The private benchmark marker prevented touching desktop player slots.

Reproduce: python -X utf8 devtools/verify_sanctuary.py; Godot --path . --script tests/sanctuary_playtest.gd; python -X utf8 devtools/android_sanctuary_validate.py --fps 60 (or --fps 30). Desktop tests use private user files. Do not reset the player's package or world. Godot headless/editor/export can report known resource/ObjectDB cleanup warnings; no new script/runtime error is accepted.

- Desktop launcher: D:/LittleGod/Launch LittleGod.cmd.
- Verified runtime: D:/LittleGod/tools/godot/Godot_v4.7.2-stable_win64.exe.
- Player APK: D:/LittleGod/builds/android/LittleGod-0.8.5-milestone-E3-debug.apk.
- QA APK: D:/LittleGod/builds/android/LittleGod-0.8.5-milestone-E3-qa-debug.apk.
- Source: D:/LittleGod/builds/LittleGod-0.8.5-milestone-E3-source.zip.
- Exact checkpoint/archive/APK hashes: D:/LittleGod/builds/phase085e3/checkpoint-manifest.json.

![Actual solved mechanism](screenshots/phase085e3-guardian-hall-tr.png)
![Actual relic pickup](screenshots/phase085e3-sun-relic-tr.png)
![Actual ancient forge](screenshots/phase085e3-ancient-forging-tr.png)
![Actual realm23](screenshots/phase085e3-quest23-complete-tr.png)
'''
(docs/'AGE085_E3_REPORT.md').write_text(report,encoding='utf-8')
(docs/'PERFORMANCE_MILESTONE_E3.md').write_text('# E3 measured performance\n\n'+table+'\nSee AGE085_E3_REPORT.md for measurement scope, retained bad samples, bot-path exclusion, memory and limitations. Raw supported metrics: docs/benchmarks/phase085e3. No physical-device verification.\n',encoding='utf-8')
(docs/'DUNGEON_ARCHITECTURE.md').write_text('''# Sanctuary architecture

kingdom.version3 and adventure.version1 remain. The regional subrecord opts into version3 only after claimed22 at actual Sanctuary entry. It retains E2 quest proof and adds ancients plus three stock keys. At most three parked runs plus the current region retain unique IDs. Original industry items, workers, caravans, military and saves keep their owners.

sanctuary_map.gd owns960×1440 static room walls, four closed-door rectangles, plates, levers, relic and hazards. Headless movement substeps; the actual scene uses CharacterBody2D/static colliders. AStar is developer bot navigation only. It handles valid actor positions next to blocked grid centres by routing within interaction range. No player auto-pathfinding is added.

sanctuary.gd owns mechanisms/trap clocks/elite state/relic/research/validation. adventure.gd remains the authority for movement, health, attacks, pickup IDs, rewards and return banking. sanctuary_view.gd draws bounded warnings and toggles colliding doors from saved state. No extra crowd or particle system. Clock advancement stays20Hz. Active or defeated adventure freezes home/industry/caravans/offline; no absence damage. Re-entry never refills unique rewards.
''',encoding='utf-8')
(docs/'DUNGEON_PUZZLES.md').write_text('''# Sanctuary puzzles and hazards

Trial of Stone: step on Sun(1), then Moon(2). Wrong order resets; standing still cannot repeat-trigger; completed plates latch. This opens the colliding stone door. Guardians' Hall: Inspect Sun→Moon→Star. Wrong order resets to zero (Sun can restart); no timing deadline; completed gate latches. Switches require solved plates. The cracked-wall Inspect opens the optional treasury gate permanently. Warden death opens the relic door. Doors and mechanisms survive exact save/reopen and Home always permits retreat.

Spikes:4s period, warning1.0–1.8s, active1.8–2.05s, raw16. Runes:5s period,750ms offset, warning1.0–1.9s, active1.9–2.2s, raw20. Both use saved simulation time, one hit per cycle, ordinary defense plus equipped trap resistance, minimum1. Dodge invulnerability prevents damage. Warning and active rectangles equal hazard detection rectangles. Trap cycle bounds, mechanism ranges/prerequisites and chest/relic provenance are validated.
''',encoding='utf-8')
(docs/'ANCIENT_CIVILIZATION_LORE.md').write_text('''# The Sunforged Dynasty

The entrance inscription teaches Sun→Moon and Sun→Moon→Star: light once ordered the dynasty's machinery. An abandoned forge in the optional wing reveals their use of solar heat to temper metal. A cracked stone wall leaks light from a hidden treasury. Mechanical guardians still defend the sealed Sun Relic. Returning its unique artifact and researching it restores useful forging knowledge. Discoveries enter the existing localized Chronicle once; no new currency or text-only progression system is added.
''',encoding='utf-8')
(docs/'EQUIPMENT_EFFECTS.md').write_text('''# Ancient equipment

Recipes and all costs live in assets/kingdom/recipes.json. Industry reserves real materials, waits for assigned forge work and mints canonical item IDs. Research is mandatory. Blade costs3alloy/2iron/2gold for6 work units (+20attack). Shield costs1core/1alloy/1iron/1gold for5 (+7defense). Armor costs2alloy/1iron/1leather for5 (+18health/+4defense/+4trap resistance). Talisman costs2sunstone/2gold for4 (+2trap resistance). These are work units consumed by original skill/stability rules, not wall-clock waits. hero.stats and adventure.hurt consume actual gear; sanctuary.tick additionally consumes hazard_resist. Minimum damage1. No invented defense-on-dodge proc is claimed.

32 owned+queued items, four forge jobs, equipped-item/civilian/military/caravan reservations and salvage protections remain. Unique artifacts are not salvageable. Relic cannot be queued. Full capacity never deletes the pending relic. Legal three-seed campaigns craft/equip all four and conserve7alloy→1,1core→0,4sunstone→2. These finite materials do not regenerate.
''',encoding='utf-8')
(docs/'QUEST_23_DESIGN.md').write_text('''# Realm23 — Relics of the Ancients

Claimed main22 plus armed Warrior unlock actual Sanctuary entry; only entry opts into the additional regional schema and exposes23. Opening a map does not mutate progression. Objectives read saved inscription, both mechanisms, actual dead Warden, canonical unique relic, alive return, home research and crafted/equipped new gear. Reward920 realmXP/4gold/4wood/4stone uses the original exactly-once claim API. Other quests, rewards and their old saves are preserved. Contextual Guide points at the next actionable location; Pack pauses and shows real cargo/stats. Equip remains a home action.
''',encoding='utf-8')
(docs/'SAVE_MIGRATION_MILESTONE_E3.md').write_text('''# E3 save compatibility

The authentic E2 fixture was saved at57ca7fa before sanctuary.gd existed. It contains the real1–22 campaign, old completed regions, a pending caravan and a pending forge job. tests/create_e2_fixture.gd refuses to run from a newer or sanctuary-bearing checkout. Tests preserve old industry/trade/workers/claims on entry, exercise exact active/puzzle/trap/full-capacity round trips, and visit all four regions without changing parked-run identities. Authentic C/D/E1/E2B/E2 files all load and round-trip under the new code.

E3 opts the regional record from2 to3 only on legitimate Sanctuary entry. Kingdom/adventure versions remain3/1. Added ancients records version/relic_item/returned/researched, with conditional ancient_alloy/sentinel_core/sunstone_fragment stock keys. Each Sanctuary run owns mechanism/trap fields. Validation checks prerequisite claims, mechanism consistency, clock bounds, enemy identity/death, canonical guaranteed drops, treasury rows and unique relic ownership. Recipe research, item/queue capacity and equipped/civilian/military reservations remain enforced. Future trap cycles and forged research/return/chest states are rejected. No old reward is replayed.

Active adventures pause offline/home/caravan/industry clocks, including trap damage; absence never injures the hero. Traps save their once-per-cycle marker. Defeat follows the existing collected-cargo policy, but relic research requires an alive return. Both Android caps pass actual force-stop/reopen with exact world/tick/puzzle equality. Player package update/private-marker startup preserves primary, backup, temp and settings bytes; its APK digest is bound to the report. See docs/benchmarks/phase085e3 and builds/phase085e3/checkpoint-manifest.json. Compatibility is new-code loading old saves; running an older E2 binary on an opted-in E3 save is not supported.
''',encoding='utf-8')
(docs/'MILESTONE_E_CONTINUATION.md').write_text('''# Continue after E3

E3 core is verified at devE3/code92, quests1–23. Read STATUS.md, AGE085_E3_REPORT.md and the exact manifest in builds/phase085e3. Retain the E2 baseline and original E3 brief. Run devtools/verify_sanctuary.py, private rendered tests and isolated Android60/30 before any new release. Never fabricate historical fixtures or reset player data.

E4 outposts/remote workers/logistics/24, E5 Azrakh, E6 kingdom expansion and throne systems are not implemented. Visual Rebirth V4 is also separate and remains unimplemented; no character style approval is inferred. Future development requires its original brief and a fresh actual audit. Do not create a complete E/0.9/1.0 tag from this checkpoint. Online/.NET App Control remains untouched. No paid services or publication is authorized.
''',encoding='utf-8')
(docs/'KNOWN_ISSUES.md').write_text('''# Known issues —0.8.5-devE3

- E3 core is implemented; E4/E5/E6/throne/Visual Rebirth V4 are not. Existing Warrior art/compact controls and modest procedural enemy motion remain; this is not a premium frame-animation remake. Shade uses an aimed hitscan spell rather than a travelling projectile engine.
- Finite dungeon enemies/materials/chest/relic never refill. Clear storage before gathering; uncollected loot remains.32-item/four-job limits and artifact/equipment reservations remain. Advanced material recycling is intentionally not introduced.
- Traps share ordinary defense and extra equipped trap resistance; minimum damage1. Powerful combined gear can reach this floor. Safe return banks collected cargo under the existing forgiving defeat policy; relic return proof needs an alive return.
- Android evidence is emulator-only. Final performance tables distinguish sustained combat from developer AStar route construction. Historical poor inclusive bot samples are retained. No physical-device thermals, battery, haptics, simultaneous-multitouch or OEM safe-area certification.
- Known Godot editor/headless/export ObjectDB/resource cleanup warnings remain. Script/runtime errors are rejected. Native Computer Use unavailable; real Godot rendering/MCP/ADB supplies supported evidence.
- Active adventure freezes home/offline/caravans/forge clocks; E1 Live Route Watch separately advances home then restores pause. No security changes, App Control bypass, paid infrastructure or publishing. Older build artifacts are preserved.
''',encoding='utf-8')
status=f'''# LittleGod — E3: Secrets of the Ancients

Current verified development build: **0.8.5-devE3 / Android code92**, realm campaign1–23. Playable Sunken Sanctuary includes five connected spaces, two persistent puzzles, two avoidable real traps, three distinct elites, optional treasury/two lore discoveries, unique Sun Relic, four useful forge/equipment recipes and quest23. Existing E2 regions, quests, saves, workers, trade/caravans, military, online source and artwork are preserved.

**{count} game checks pass:745 retained +{new} new.** Three legal1–23 seeds pass. Rendered desktop: {len(rendered['checks'])} checks, actual combat/puzzles/loot/research/forge/equip/23 screenshots. Both Android60/30 runs verify native controls, exact force-stop restoration and23; navigation/combat/forging helpers are labelled. Player APK signing/update/private startup preserves player files. No physical-device verification.

{table}

E4/E5/E6/throne and Visual Rebirth V4 remain unimplemented. E3 is a core gameplay delivery, not a claim of completed premium character animation. See AGE085_E3_REPORT.md, KNOWN_ISSUES.md and docs/benchmarks/phase085e3 for evidence and performance limits.

- Launch: `D:/LittleGod/Launch LittleGod.cmd`.
- Runtime: `D:/LittleGod/tools/godot/Godot_v4.7.2-stable_win64.exe`.
- Player: `D:/LittleGod/builds/android/LittleGod-0.8.5-milestone-E3-debug.apk`.
- QA: `D:/LittleGod/builds/android/LittleGod-0.8.5-milestone-E3-qa-debug.apk` (`.betaqa`).
- Source: `D:/LittleGod/builds/LittleGod-0.8.5-milestone-E3-source.zip`.
- Checkpoint: `age085-e3-ancients`; exact commit/hashes: `D:/LittleGod/builds/phase085e3/checkpoint-manifest.json`.

After real22, open the world map and enter Batık Tapınak. Read the inscription; step on Güneş then Ay; Inspect Güneş→Ay→Yıldız. Read trap warnings and dodge. Defeat the Warden to open the relic chamber; inspect the pedestal, return alive and inspect the recovered relic at home. Assign a smith, forge an ancient item, equip it and claim23. Cracked stone opens the optional treasury. All unique progress survives return/reopen.

![Actual Sanctuary](screenshots/phase085e3-guardian-hall-tr.png)
![Actual Sun Relic](screenshots/phase085e3-sun-relic-tr.png)
![Actual realm23](screenshots/phase085e3-quest23-complete-tr.png)
'''
(docs/'STATUS.md').write_text(status,encoding='utf-8')
print(f'E3 documentation generated from {count} passing checks and desktop/Android/player evidence.')
