"""Publish measured E2B evidence. Refuses incomplete or failed native/test reports."""
from pathlib import Path
import json,shutil,re,hashlib
r=Path(__file__).resolve().parents[1];out=r/'builds/phase085e2';docs=r/'docs';bench=docs/'benchmarks/phase085e2';bench.mkdir(parents=True,exist_ok=True)
def read(p):return json.loads(p.read_text(encoding='utf-8-sig'))
v=read(out/'verification.json');render=read(out/'rendered.json');assert v['all_passed'] and v['game_checks']==689 and render['all_passed']
native={}
player=read(out/'player-install/result.json');assert player['signature_verified'] and player['installed'] and player['started_private_benchmark']
for name in ['result.json','signature.txt','startup.txt','logcat.txt']:
 shutil.copyfile(out/'player-install'/name,bench/('player-'+name))
for fps in [60,30]:
 d=out/f'android-emulator-5554-{fps}';result=read(d/'result.json');reopen=read(d/'reopen.json');proof=read(d/'preservation.json')
 assert result['all_passed'] and reopen['all_passed'] and proof['player_files_unchanged'] and 'combat_profile' in result
 native[fps]=result
 for name in ['result.json','reopen.json','preservation.json','startup.txt','memory.txt','logcat.txt']:
  shutil.copyfile(d/name,bench/f'android-{fps}-{name}')
for name in ['verification.json','rendered.json','regions.log','regional_combat.log']:
 shutil.copyfile(out/name,bench/name)
for fps in [60,30]:
 for name in ['result.json','reopen.json','startup.txt','memory.txt','logcat.txt']:
  shutil.copyfile(out/f'degraded-session/android-{fps}'/name,bench/f'degraded-{fps}-{name}')
for source,name in [('world-map.png','world-map'),('mcp-iron-tr.png','entry-tr'),('iron-combat-warning.png','crawler-warning'),('forgotten-mine-tr.png','forgotten-mine')]:
 shutil.copyfile(out/source,docs/f'screenshots/phase085e2b-{name}.png')
for name in ['android-iron-entry','android-iron-warning','android-forgotten-mine-tr','android-iron-restored']:
 shutil.copyfile(out/'android-emulator-5554-60'/f'{name}.png',docs/f'screenshots/phase085e2b-{name}.png')
apk=r/'builds/android/LittleGod-0.8.5-milestone-E2B-debug.apk';sha=hashlib.sha256(apk.read_bytes()).hexdigest()
assert hashlib.sha256((r/'builds/android/LittleGod-0.8.5-milestone-E1-debug.apk').read_bytes()).hexdigest()=='ae6384a4a227bf55ccfd95c2d85cb6ed4729454849b7b5c8a1ae861c090d8e68'
def write(name,text):(docs/name).write_text(text.strip()+'\n',encoding='utf-8')
rows=[]
for fps,d in native.items():
 for key,title in [('combat_profile','Active mountain encounters'),('profile','Cleared Forgotten Mine')]:
  p=d[key];rows.append(f'|Emulator {fps} cap · {title}|{p["fps"]:.2f}|{p["p95_ms"]:.2f}|{p["step_us"]}|')
performance='\n'.join(rows);p=render['profile']
write('PERFORMANCE_MILESTONE_E2.md',f'''
# E2B regional performance evidence

Only Iron Hills is implemented/measured. No Ashen Desert result exists. Android is emulator-5554/API35/x86_64/NVIDIA OpenGL translation. The connected Samsung phone reported `unauthorized` during this development run; no E2B phone performance, thermal, haptic or battery verification is claimed. Earlier successful E1 phone installation is separate.

| Scene / cap | FPS | p95 ms | Model step µs |
|---|---:|---:|---:|
{performance}
|Desktop · cleared mine|{p['fps']:.2f}|{p['p95_ms']:.2f}|{p['step_us']}|

Final desktop setup {p['setup_ms']:.2f}ms, {int(p['draw_calls'])} draw calls, {p['static_bytes']/1048576:.2f}MiB static allocator memory. Android60-cap mine setup {native[60]['profile']['setup_ms']:.2f}ms, {int(native[60]['profile']['draw_calls'])} draw calls, {native[60]['profile']['static_bytes']/1048576:.2f}MiB static / {native[60]['profile']['video_bytes']/1048576:.2f}MiB reported video memory. The Android cleared-mine samples span8 seconds; the active encounters sample includes real bot navigation and fights with both archetypes and reports its exact frame count. It is a short encounter sample, not a sustained stress/thermal test. Exact setup, draw calls, static/video memory, launch activity timing and OS PSS/RSS are in benchmarks/phase085e2. Godot allocator/video monitors and Android process PSS are different measurements.

The first static mountain ground submitted hundreds of circle/path drawing commands. It now imports one original960×1440 vector terrain texture, retaining separate live hero/enemies, props, interactables and collision bodies. The largest new texture is approximately5.27MiB at RGBA8 before driver compression/mipmaps; there are no new particle systems. Enemy count is bounded at2, loot at20 and stored regions at2. Existing20Hz combat and30FPS battery-saver behavior remain. Reported model-step cost includes combat/collision helpers, rather than attributing GPU/frame time to AI without evidence.

An earlier long-lived emulator run degraded to35.59FPS/p9552.09ms at the cleared mine, with an8.87FPS short encounter sample; it is retained in builds/phase085e2/degraded-session. Earlier successful native runs were around57–60FPS. Session/host variability is a real limitation; compare the retained observations and final controlled rerun instead of claiming every difference is a code optimization. Restarting the same emulated disk uses no wipe, OS security change or App Control bypass.

E1 route-view59.80FPS/p9519.38ms and30.00FPS/p9534.88ms remain historical reference values for a different scene. They are not interchangeable adventure-map benchmarks. Reproduce with devtools/android_regions_validate.py --fps60/30 (arguments separated as `--fps 60` and `--fps 30`); commands clear only the isolated QA package. Native controls and engine-driven bot travel are labeled separately in result JSON.

Known runtime output includes an emulator cached-shader warning/recompile after restart, and existing headless/editor-export ObjectDB/resource cleanup warnings. These are retained; script parse errors, invalid saves or failed assertions are not accepted. APK signing/import and activity-start timing do not measure complete first-play readiness.
''')
write('AGE085_E2_REPORT.md',f'''
# E2A/E2B — playable Iron Hills, partial E2

Build0.8.5-devE2B / Android code90. This execution delivers the world-map foundation and actual Iron Hills exploration. **E2C Ashen Desert, E2D quest22 and complete E2 acceptance remain unfinished.** Campaign stays1–21; no `age085-e2-regions` or final E tag is claimed. Safe baseline: `age085-e2-base-e1` at914728f. Release checkpoint: `age085-e2b-iron-hills`.

Implemented a trusted local region registry, bilingual destination inspection, honest unavailable desert card, recommendations/unlocks/resources/enemy/landmark information and explicit distinction from unchanged caravan trading posts. Reused the original hero/combat scene with real static collision, navigable mining paths, finite mineral pickup, persistent mine discovery and home banking. The two enemies actually fight: armored slow aimed heavy attacks versus quick locked lunges and recovery repositioning. A zero-distance recovery edge found by tests was fixed.

Ten original vector assets cover mountain terrain, cliffs, ore, pine, mine/cart, both enemies and two map previews. They are usable imported gameplay layers/sprites. The desert preview is labeled unavailable and does not pretend to be a playable scene. Original C artwork, warrior, Wildwood, worlds, online source and older APKs remain. Actual rendered inspection caught prop occlusion and excessive static draw commands; the mine/deposits now sort with actors and the terrain imports once.

All639 retained game assertions pass unchanged. New40 regional and10 combat assertions pass: **689 game assertions**. Six legal seeded journeys complete the real1–21 campaign then explore, gather, fight, discover and return from Iron Hills. No injected XP or flags substitute for legal progression. Desktop rendered movement/combat/damage/pickup/discovery/return/save checks pass. Godot MCP inspected Turkish map/entry with an empty runtime error list. Native Computer Use APIs were unavailable; Godot/MCP/ADB supply actual rendering evidence.

Android native QA:20 checks plus6 genuine force-stop/relaunch checks pass at each60/30 cap. Actual ADB inputs select the map card, enter, move the joystick, attack, dodge, inspect both deposits/discovery and return home. Route-following/fight automation between these controls is explicitly engine-driven. Pending caravan state and active node/discovery data restore exactly; banked materials and private saves persist. Player primary/backup/temp/settings bytes remain identical. No real player's slot was cleared. Physical phone was unauthorized for this run, so no E2B phone claim is made.

Player APK: `D:/LittleGod/builds/android/LittleGod-0.8.5-milestone-E2B-debug.apk` ({apk.stat().st_size}bytes, SHA256 `{sha}`). Isolated QA APK uses `.betaqa`. Player APK v2/v3 signatures, in-place installation and startup also passed on the emulator; a private benchmark marker prevented player-save writes and primary/backup/temp/settings bytes remained identical. Cold activity start reported1199ms, which does not establish complete gameplay readiness. Desktop launcher: `D:/LittleGod/Launch LittleGod.cmd`, verified Godot4.7.2 runtime under tools/godot. Source archive: `D:/LittleGod/builds/LittleGod-0.8.5-milestone-E2B-source.zip`; exact commit and archive hash are recorded in builds/phase085e2/checkpoint-manifest.json after checkpointing.

Read REGIONAL_ADVENTURE_ARCHITECTURE.md, REGIONAL_ENEMIES.md, SAVE_MIGRATION_MILESTONE_E2.md and PERFORMANCE_MILESTONE_E2.md for limits and evidence. Quest22 is explicitly absent; QUEST_22_DESIGN.md documents remaining behavior without awarding it. No E3–E6/0.9/1.0 work, purchase, publishing, paid service or security bypass occurred.

![Real Turkish mountain entry](screenshots/phase085e2b-entry-tr.png)
![Real crawler telegraph](screenshots/phase085e2b-crawler-warning.png)
![Real mine discovery](screenshots/phase085e2b-forgotten-mine.png)
''')
history=docs/'history';history.mkdir(exist_ok=True)
for name in ['STATUS.md','KNOWN_ISSUES.md']:
 dest=history/('E1-'+name)
 if not dest.exists():shutil.copyfile(docs/name,dest)
write('STATUS.md',f'''
# LittleGod — E2A/E2B: Beyond the Kingdom

Current build: **0.8.5-devE2B / Android code90**. Playable Iron Hills and expanded world map are implemented and verified. **E2 remains partial: Ashen Desert and quest22 are not implemented. Realm campaign remains1–21.** No full E2/E/0.9 tag is claimed.

Explore a real mountain map with the existing Warrior controls, collision, two distinct fighting enemies, finite ore/stone deposits, Forgotten Mine discovery/history and safe material banking. Original Wildwood, E1 trade posts/caravans, military, equipment, saves and artwork remain. Mine/deposit persistence prevents reloading for free resources. Warehouse capacity is checked before depleting a node.

**689 game assertions pass:**639 retained plus50 regional/combat. Six legal1–21-plus-mountains seeds,13 rendered desktop checks, Turkish Godot MCP inspection and26 native/restart Android checks per60/30 cap pass. Native ADB touches and bot navigation are explicitly distinguished. Player save/settings files remain byte-identical during isolated QA. The connected phone was unauthorized during E2B verification; results are emulator-only.

Measured final Iron Hills samples (different scene from E1 route watch):

| Scene / cap | FPS | p95 ms | Model step µs |
|---|---:|---:|---:|
{performance}

Exact measurements, degraded-session observations, memory and limits: PERFORMANCE_MILESTONE_E2.md and benchmarks/phase085e2.

- Launch: `D:/LittleGod/Launch LittleGod.cmd`.
- Runtime: `D:/LittleGod/tools/godot/Godot_v4.7.2-stable_win64.exe`.
- Player APK: `D:/LittleGod/builds/android/LittleGod-0.8.5-milestone-E2B-debug.apk`.
- Isolated QA APK: `D:/LittleGod/builds/android/LittleGod-0.8.5-milestone-E2B-qa-debug.apk`.
- Source archive: `D:/LittleGod/builds/LittleGod-0.8.5-milestone-E2B-source.zip`.
- Baseline tag: `age085-e2-base-e1`; partial release tag: `age085-e2b-iron-hills`.
- APK SHA256: `{sha}`.
- Exact commit/archive hashes: `D:/LittleGod/builds/phase085e2/checkpoint-manifest.json`.

After real quest21, use Hero Hall → world map → Iron Hills → Enter. Inspect mineral rings within reach, dodge warnings and inspect the northern mine. Home banks cargo; ore feeds your furnace/forge and stone pays construction. Deposits/enemies do not refresh in E2B. The Ashen Desert card explicitly says it is unavailable.

See AGE085_E2_REPORT.md, REGIONAL_ADVENTURE_ARCHITECTURE.md, REGIONAL_ENEMIES.md, SAVE_MIGRATION_MILESTONE_E2.md, QUEST_22_DESIGN.md, KNOWN_ISSUES.md and MILESTONE_E_CONTINUATION.md. Historical E1 status/issues are preserved under docs/history. No publishing or paid service occurred.

![Actual mountain entry](screenshots/phase085e2b-entry-tr.png)
![Actual mine discovery](screenshots/phase085e2b-forgotten-mine.png)
''')
write('KNOWN_ISSUES.md','''
# Known issues —0.8.5-devE2B

- E2A and E2B are the verified partial checkpoint. Ashen Desert, its oasis/three enemies/poison/material consumer and quest22 remain unimplemented. Realm progression is1–21; the desert card is explicitly unavailable. No E3 or later work was started.
- Mountain deposits and enemies are finite and have no respawn in this checkpoint. The two nodes yield6 ore/5 stone; enemy loot is bounded. Clear warehouse space at home if a pickup cannot fit. Repeatable outpost production is outside E2B.
- Adventure uses the compact original C hero controller and camera. Mountain collisions and new enemy behavior are real, but this is not a large seamless/open-world navigation system. No new boss or ancient relic quest exists.
- Android verification is emulator-only. The connected physical phone was unauthorized during this run. Long-lived emulator/host graphics sessions can degrade sharply; short60/30-cap samples do not establish phone thermals, battery, haptics or simultaneous multitouch. Active-encounter samples are brief.
- Headless/editor/export ObjectDB/resource cleanup warnings remain. Emulator restart may log a cached-shader recompile warning. Logs are retained; no new script parse/runtime errors or failed game assertions are accepted.
- Existing32-slot/four-job inventory and military/trade limits remain. Staffed-forge/merchant salvage protects gear, artifacts and reserved kits. Trade prices/quotes/reservations are unchanged; future route price changes still need explicit migration.
- Home/industry/caravan/offline simulation freezes during any active adventure or army battle. E1 Live Route Watch intentionally advances home ticks while watching and restores the previous pause on exit. Menus otherwise pause work.
- Native Computer Use was unavailable. Actual Godot rendering, MCP inspection and ADB controls were used. Automated tests do not establish human beta enjoyment or long-term balance.
- Existing API/.NET App Control blockage remains untouched; purchases stay disabled. No security bypass, paid service, store release, public deployment or external messaging occurred. Older milestone reports and builds remain.
''')
# Readable copies trim padding only; exact adb stdout remains in builds/phase085e2.
for path in bench.glob('*.txt'):
 path.write_text('\n'.join(line.rstrip() for line in path.read_text(encoding='utf-8').splitlines()).rstrip()+'\n',encoding='utf-8')
print('Finalized measured E2B docs and screenshots')
