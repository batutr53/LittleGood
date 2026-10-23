"""Generate the 0.8 report only from inspected, successful local evidence."""
from pathlib import Path
import json,hashlib,shutil,subprocess,re
root=Path(__file__).resolve().parents[1];out=root/'builds/phase8';docs=root/'docs';evidence=docs/'benchmarks/phase8';evidence.mkdir(parents=True,exist_ok=True)
def read(name):return json.loads((out/name).read_text(encoding='utf-8-sig'))
def write(name,s):(docs/name).write_text(s.strip()+'\n',encoding='utf-8')
apk=root/'builds/android/LittleGod-0.8-debug.apk';apk_hash=hashlib.sha256(apk.read_bytes()).hexdigest();qa_hash=hashlib.sha256((root/'builds/android/LittleGod-0.8-qa-debug.apk').read_bytes()).hexdigest()
install=read('android-install.json');custom=read('android-customization/result.json');desktop=read('visual.json');reg=read('android-qa/result.json');native=read('android-social/result.json');offline=read('android-online/offline-result.json');economy=read('economy.json');balance=read('balance.json');schema=read('schema.json');added=read('tests.json')
assert added['passed']==61 and added['failed']==0
assert all(install['preserved'].values()) and install['apk_sha256']==apk_hash
assert all(x['all_passed'] for x in [custom,desktop,reg,native]) and all(offline['checks'].values())
assert len(custom['checks'])==22 and len(reg['checks'])==26 and len(native['checks'])==3 and len(offline['checks'])==5
assert offline['qa_apk_sha256']==qa_hash and not economy['failures'] and not balance['failures']
assert len(economy['scenarios'])==30 and len(balance['rows'])==40
for suite in ['suite','runtime','phase2','phase3','phase4','phase5','phase6','phase7','phase8']:
 s=(out/f'final-{suite}.log').read_text(encoding='utf-8-sig');assert 'SCRIPT ERROR' not in s and 'FAIL:' not in s and 'FAIL ' not in s,suite
assert 'PHASE8_RESULT: 61 passed, 0 failed' in s
profiles=[('Normal, 18 creatures','final-android/android-smooth.json'),('32 decorations, Celestial Night','final-android/android-smooth-decor-celestial.json'),('32 decorations, battery saver','final-android/android-economy-decor-celestial.json'),('32 decorations, 70 creatures','final-android/android-stress-decor-celestial.json')]
table='| Emulator scenario, 20 seconds | FPS | p95 ms | First frame ms | Draw calls / peak | Static / video MiB | Simulation avg ms |\n|---|---:|---:|---:|---:|---:|---:|\n'
for label,name in profiles:
 r=read(name);assert r['installed_apk_sha256']==apk_hash and r['installed_version']=='0.8.0' and r['player_save_unchanged']
 table+=f"| {label} | {r['average_fps']:.2f} | {r['frame_p95_ms']:.2f} | {r['first_frame_ms']} | {r['draw_calls']:.0f} / {r['peak_draw_calls']:.0f} | {r['static_memory_mb']:.1f} / {r['video_memory_mb']:.1f} | {r['simulation_average_ms']:.2f} |\n"
normal=read(profiles[0][1]);decor=read(profiles[1][1]);saver=read(profiles[2][1]);stress=read(profiles[3][1]);before=read('pre-batching/android-smooth-decor-celestial.json');control=read('matched-07/android-smooth.json')
summary={'game_checks':356,'preserved_phase7_checks':295,'phase8_checks':61,'desktop_render_checks':len(desktop['checks']),'android_customization_checks':22,'android_regression_checks':26,'native_file_checks':3,'android_server_unreachable_offline_checks':5,'economy_scenarios':30,'balance_scenarios':40,'baseline_phase7_real_http_checks':65,'backend_source_compiles':True,'backend_test_cases':42,'final_backend_test_execution':'blocked_by_windows_app_control','new_v2_http_and_purchase_endpoint_verification':'not_performed_runtime_blocked','sql_migration_applied_twice':True,'physical_devices':0,'human_testers':0,'live_payments':False,'apk_sha256':apk_hash,'qa_apk_sha256':qa_hash}
(evidence/'tests.json').write_text(json.dumps(summary,indent=2),encoding='utf-8')
names=['android-install.json','android-customization/result.json','android-customization/memory.txt','android-qa/result.json','android-social/result.json','android-online/offline-result.json','economy.json','balance.json','visual.json','baseline-online.log','baseline-android/android-smooth.json','matched-07/android-smooth.json','matched-control.json','pre-batching/android-smooth.json','pre-batching/android-smooth-decor-celestial.json','pre-batching/android-economy-decor-celestial.json','pre-batching/android-stress-decor-celestial.json','schema.json','schema.log','api.log','backend-tests.log','backend-build.log','apk-signature.txt','apk-badging.txt','adb-devices.txt','mcp-visual.log']+[p for _,p in profiles]+[f'final-{s}.log' for s in ['suite','runtime','phase2','phase3','phase4','phase5','phase6','phase7','phase8']]
for name in names:
 source=out/name;target=evidence/name;target.parent.mkdir(parents=True,exist_ok=True)
 if target.suffix in ['.txt','.log']:target.write_text('\n'.join(x.rstrip() for x in source.read_text(encoding='utf-8-sig').splitlines()).rstrip()+'\n',encoding='utf-8')
 else:shutil.copyfile(source,target)
for name in ['theme-enchanted','theme-crystal','theme-celestial','theme-ancient','editor','shop','item','creature-wardrobe','visit','collection-tr']:
 shutil.copyfile(out/f'android-customization/{name}.png',docs/f'screenshots/phase8-{name}.png')
for name in ['mcp-crystal','mcp-shop','mcp-premium']:shutil.copyfile(out/(name+'.png'),docs/f'screenshots/phase8-{name}.png')
shutil.copyfile(out/'android-customization/adb-preview.png',docs/'screenshots/phase8-adb-preview.png')
shutil.copyfile(out/'android-customization/customized.lgplanet',docs/'examples/Atelier-08.lgplanet')
memory=re.search(r'(?m)^\s*TOTAL\s+(\d+)\s+\d+\s+\d+\s+\d+\s+(\d+)',(out/'android-customization/memory.txt').read_text(encoding='utf-8'))
assert memory
pss,rss=map(int,memory.groups())
limits='''Windows App Control blocked the updated native API executable and final Release test assembly; source compilation succeeds, but new v2 HTTP publishing/entitlement routes and EF receipt concurrency have no final live integration result. No bypass or security change was attempted. The pre-change 65 real HTTP/PostgreSQL checks are a 0.7 baseline. Updated SQL migration/idempotency and database constraints pass separately. Payments remain disabled and native billing adapters/store restore/refund feeds are not implemented. No public deployment, paid service, store publication, physical phone or human beta occurred.'''
perf=f'''{table}

The same host's original 0.7 APK measured {control['average_fps']:.2f} FPS / {control['frame_p95_ms']:.2f} ms p95 in a matched late control; it was restored to 0.8 after checking all four save/settings files. The initial 0.7 baseline earlier in the session was 31.77 FPS / 36.37 ms p95. This large variation also affects startup and CPU time; it is emulator/host evidence, not phone performance. The pre-batching decorated candidate measured {before['average_fps']:.2f} FPS and {before['draw_calls']:.0f} draw calls; the final equivalent decorated scene measured {decor['draw_calls']:.0f} draw calls. Common atlas + batched glints reduce render submissions; FPS comparisons are not isolated laboratory causal measurements. Normal and 30-FPS saver caps remain; stable 60 on phones and stable 30 under this slow emulator host are not established.

Original world atlas stays 1024×1024; the shared cosmetic atlas is 768×512 (24 cells of 128×128), with individual SVG previews retained. At most 32 placed sprites are retained, reused across theme changes; glints/stars use packed line batches. Effects are bounded and lower in saver. Theme changes no longer rebuild terrain or recreate placed sprites, verified in rendered QA. Final decorated cosmetic draw CPU average: {decor['cosmetic_draw_average_ms']:.3f} ms; last appearance sync {decor['cosmetic_sync_ms']:.3f} ms. Scene/world generation CPU: {normal['pipeline']['scene_ready_ms']:.2f}/{normal['pipeline']['world_generation_ms']:.2f} ms.

Android instrumented theme/capture-loop post-draw intervals: {', '.join(f'{x:.1f}' for x in custom['theme_switch_frame_ms'])} ms. They include render scheduling/readback/cache/host effects, not pure shader cost or touch-to-photon latency; hitches remain. Shop construction CPU {custom['shop_cpu_ms']:.2f} ms, atomic checkpoint {custom['save_ms']:.2f} ms, checked load/migration {custom['load_ms']:.2f} ms. Desktop theme intervals: {', '.join(f'{x:.1f}' for x in desktop['theme_switch_frame_ms'])} ms; desktop checkpoint/load {desktop['save_ms']:.2f}/{desktop['load_ms']:.2f} ms. Android post-customization session PSS/RSS: {pss} / {rss} KiB (android-customization/memory.txt) and is not interchangeable with Godot's static/video counters. Emulator shader-cache recompile warnings and old Godot shutdown resource/ObjectDB warnings remain. No physical thermals, energy or OEM input measurements.'''
status=f'''# LittleGod 0.8 — playable customization checkpoint

Verified locally 2026-10-23. Built on `littlegod-0.7` commit 0e74f508b3d0e29c9ef4b9c2f2b2889ed72c05ad, with safe base tag `phase8-base-0.7`. The `littlegod-0.8` tag is a local source checkpoint with the limits below, not store/online production approval.

Implemented: four coordinated original presentation themes; 24 reusable cosmetic illustrations and a shared atlas; depth-sorted magical vegetation, crystals, ruins, statues, banners, lanterns and compatible waterfalls; creature tints/accessory/idle looks; skies/frame; EN/TR inventory, categories/featured/favorites/rarity/previews/requirements, owned counts, explicit unlock confirmation and unavailable premium preview. Decoration mode supports validated ghost placement, movement, four isometric facings, storing, 20-step undo/redo, pan/pinch, pause-state restoration and saving, capped at 32 pieces. The normal living simulation, powers, original artwork, stories, communities and existing favorite/name/history tools remain.

Stardust rewards durable discoveries/restoration/community milestones once, with 525 available against 450 total catalog cost, no paid currency or daily pressure. Save schema v1 retains an optional strict wardrobe v1 extension; actual old 0.7/0.5 fixtures, offline rewards, backup and interrupted-write recovery pass. Cosmetic showcase v2 strips private economy data and reconstructs a read-only decorated visit; plain v1 examples still work. Backend v2 validation and closed purchase interfaces compile, with migration constraints verified on PostgreSQL.

{limits}

Verification: **356 game checks**, including all prior 295 and 61 additions; 30 economy and 40 extended live/offline balance scenarios, no failures. **20** desktop rendered checks and **22** Android customization checks pass, including actual external ADB tile/Place taps and persisted result. Prior 26 Android interaction/lifecycle checks, three native JSON Save/Open checks and five server-unreachable offline checks pass. .NET source has 42 cases; the final blocked attempt is not counted as passing. All four player save/settings files survived Android updates and the temporary old-APK performance control.

{perf}

## Launch and outputs

- Play: `D:/LittleGod/Launch LittleGod.cmd`, verified runtime `D:/LittleGod/tools/godot/Godot_v4.7.2-stable_win64.exe`.
- Player Android: `D:/LittleGod/builds/android/LittleGod-0.8-debug.apk`, version 0.8.0/code 8, {apk.stat().st_size} bytes, ARM64/x86_64, min API24/target36. Signature v2/v3 and installation/startup verified. SHA256 `{apk_hash}`.
- QA only: `D:/LittleGod/builds/android/LittleGod-0.8-qa-debug.apk`, separate disposable package; never clears the player package.
- Source: `D:/LittleGod/builds/LittleGod-0.8-source.zip`, generated from the clean local tag after documentation/preflight. Its verified manifest is `D:/LittleGod/builds/phase8/release-manifest.json`. Prior 0.7 APK/archive remain.
- Local API launcher: `D:/LittleGod/Launch Online Server.cmd`, currently blocked by App Control; do not bypass it. Existing loopback PG55437 and connection configuration are retained.

Open ☰ → Atelier & collection → Decorate planet. Choose an owned piece, tap a clear tile and confirm; drag/pinch navigate. Store a piece before exceeding 32. Creature cards open their wardrobe. Shop premium content is unavailable; every shipped theme is earnable. See PHASE8_REPORT.md, ECONOMY_DESIGN.md, COSMETIC_CATALOG.md, MONETIZATION_ARCHITECTURE.md, ANDROID_TEST_REPORT.md and CUSTOMIZATION_FEEDBACK.md.

Actual Android gameplay, controlled cosmetic QA fixture (not human progress):

![Crystal Paradise](screenshots/phase8-theme-crystal.png)
![Decoration editor](screenshots/phase8-adb-preview.png)
![Turkish collection](screenshots/phase8-collection-tr.png)
'''
write('STATUS.md',status)
write('PERFORMANCE_PHASE8.md','# Performance evidence — 0.8\n\n'+perf)
write('PHASE8_REPORT.md',f'''# Phase eight implementation and validation

0.8 continues the completed 0.7 checkpoint, preserving all existing game systems, saved-world format, art and optional online client. The initial real 65-check API rerun passed before backend changes. Safe Git tag `phase8-base-0.7` identifies the starting state. `littlegod-0.8` is the local playable checkpoint; it does not assert that all external/runtime prerequisites are resolved.

## Player experience delivered

The atelier turns real observation and caring milestones into a finite, understandable cosmetic collection. Two reusable starter pieces are immediately available. Themes, community ornaments, vegetation, sky/frame and individual creature looks are previewed and explicitly unlocked/equipped. No gameplay advantage, paid randomness, subscription, currency sale or absence penalty exists. The original favorite/rename/history tools now connect to individual wardrobes and appearances persist by identity; departed creature looks are pruned during reconciliation. Theme/placement changes chime, optionally request a short haptic and show a confirmation/ring without blocking normal play.

The editor pauses and restores the previous pause state, keeps camera gestures, validates tile/cap/settlement/water boundaries and shows matching size/facing ghost previews. Move/store retain ownership; bounded undo/redo affects layout only. Terraforming never deletes functional terrain through the editor. Placement geometry is checked when edited; later systemic terrain changes may leave decorative items visually misplaced, so players can move/store them rather than losing a save. There is no automatic terrain mutation to accommodate decor.

24 original reusable SVG designs, four themed sky/terrain/water/settlement palettes and procedural ambient graphics retain the original painted art. Shared 768×512 atlas and batched glints/stars were added after actual profiling showed excessive submissions. See COSMETIC_CATALOG.md for every item and generator. No image-generation or paid asset service was required for this vector/code-native addition.

## Sharing and purchase boundary

Version 2 of the existing inert snapshot adds only appearance. Client validation, local JSON export/import, read-only decorated visits and exact home return pass. Appearance never grants wallet/ownership or exposes ledger/favorites/tokens. Server validation, shared catalog, migration and owner-bound fail-closed purchase service are implemented, but {limits}

## Tests and visual inspection

{summary['game_checks']} game checks = all prior 295 + 61 new. Thirty economy scenarios test finite income, buy idempotency, prices, ledger consistency and save/load. Forty retained extended simulation scenarios pass. Twenty desktop and 22 Android rendered customization checks pass. Separate Android regression/native/offline results are 26/3/5. Actual ADB touches place a piece, then checked storage restores it. Godot MCP opens the running crystal world, shop and premium screen and reports no runtime errors. Screenshots were visually examined; oversized clustered props, hidden HUD overlap, facing preview mismatch and a malformed-version comparison exception were corrected. Themes reuse terrain and sprite instances, asserted in rendered QA. No legitimate test was deleted; the old future-version test now uses version99 because v2 is supported.

Desktop cosmetic QA now uses an explicitly simulated diagnostic slot. Earlier cosmetic test iterations inherited the default diagnostic destination; existing ambiguous diagnostic history was not erased, and no diagnostic data is used as human engagement evidence. Automated fixtures, milestone unlocks and testimonials are not represented as players. Human testers/demand/retention verification: zero. CUSTOMIZATION_FEEDBACK.md and BETA_TEST_PLAN.md prepare an optional test; no invitations were sent.

{perf}

## Packaging and limits

Player APK `{apk}` ({apk.stat().st_size} bytes), SHA256 `{apk_hash}`, debug v2/v3 signature, version0.8.0/code8; installation/startup and save bytes checked. Launcher `D:/LittleGod/Launch LittleGod.cmd` uses the existing verified runtime. Source archive/tag and manifest are produced after preflight; archive excludes SDKs, local credentials/database, generated binaries and test-only mocks from the APK. Raw logs and JSON are in docs/benchmarks/phase8; previous Phase7 documents are in docs/archive. Runtime server/API and phone performance must be verified before a wider release. Store integration remains architecture preparation, not live monetization.

![Enchanted Forest, actual Android render](screenshots/phase8-theme-enchanted.png)
![Crystal Paradise, actual Android render](screenshots/phase8-theme-crystal.png)
![Celestial Night, actual Android render](screenshots/phase8-theme-celestial.png)
![Ancient Kingdom, actual Android render](screenshots/phase8-theme-ancient.png)
![Unavailable premium, actual Godot MCP capture](screenshots/phase8-mcp-premium.png)
''')
write('ANDROID_TEST_REPORT.md',f'''# Android 0.8 — verified emulator build

Actual device: emulator-5554, API35 x86_64, 1080×2400 portrait; internal world viewport720×1600, Godot4.7.2 GL Compatibility. Physical devices: zero. Main package org.littlegod.livinguniverse retained. Debug APK version0.8.0/code8, {apk.stat().st_size} bytes, minAPI24/target36, ARM64/x86_64, signaturev2/v3. SHA256 `{apk_hash}`. Updated with install -r; planet/backup/temp/settings bytes preserved. Only the disposable betaqa package was cleared. A temporary same-certificate 0.7 control was restored to 0.8 without file changes.

26 retained actual ADB/engine/lifecycle checks, three native JSON export/import checks, 22 customization checks and five actual server-unreachable offline checks pass. ADB taps target reported live world/button coordinates; engine-injected pinch is separately labeled. Real rendered theme/editor/shop/TR/visit captures were inspected. Native picker automation originally selected a search field and crossed the system gesture edge; it now scrolls within live file-list bounds. This was a test-driver issue; final Save/Open writes/reads and source checksum pass. Automated progress is a controlled QA fixture, not human data.

{perf}

{limits}

No actual two-finger phone interaction, haptic sensation, battery drain, thermal behavior, OEM keyboard/safe-area/accessibility or store transaction was tested. Read MONETIZATION_ARCHITECTURE.md for sandbox/signing/account/runtime requirements. APK files are in D:/LittleGod/builds/android; launch source via D:/LittleGod/Launch LittleGod.cmd.
''')
write('TEST_REPORT.md',f'''# Verification — LittleGod 0.8

356 game checks pass (295 retained +61 new). 30 deterministic economy scenarios and 40 extended simulation scenarios pass. Desktop real-render QA20, Android cosmetic QA22 (including two external ADB placement/persistence checks), existing Android26, native Save/Open3, actual unreachable-service offline5 all pass. Save migration uses actual old 0.5 and tagged0.7 fixtures; corrupted-primary and complete interrupted-write recovery preserve economy/equipment. Local v2 public export/read-only import/home return passes; the future-version assertion now targets99.

.NET source compiles without warnings/errors and contains42 cases. Final execution of the Release test DLL and native API is blocked by Windows App Control and is **not a pass**. 65 real HTTP checks passed on the unchanged0.7 baseline before backend edits. New v2/purchase HTTP paths, EF concurrency and real store verification remain unverified. Real PostgreSQL migration was backed up, applied twice, and transaction/state/owner/cascade constraints passed with rolled-back fixtures.

Actual rendered screenshots were inspected, including the atlas-batched final render. Godot MCP found no runtime errors. Generic old shutdown ObjectDB/resource warnings remain in logs; emulator shader-cache recompilation warnings remain. Earlier desktop cosmetic QA inherited default diagnostics; final harness isolates a simulated slot, keeps ambiguous existing history and makes no human-metrics claim. No physical phone, human beta, paid service, store purchase or public deployment occurred.

Raw accepted evidence is in benchmarks/phase8. Baseline/matched-control/pre-batching profiles are explicitly separate from the final APK hash. No aggregate claim combines mocks with real API checks. Review STATUS.md, PERFORMANCE_PHASE8.md and MONETIZATION_ARCHITECTURE.md before expanding testing.
''')
old=(docs/'archive/phase7-KNOWN_ISSUES.md').read_text(encoding='utf-8').split('\n',2)[2]
write('KNOWN_ISSUES.md',f'''# Known issues — LittleGod 0.8

- Updated native API and final .NET test assembly blocked by Windows App Control. New online v2 publishing, entitlement authorization/concurrency and restore HTTP flow need execution on an authorized runtime. No bypass performed; offline game/export/visit fallback works. Last live service baseline is0.7.
- Live purchases are disabled. Native Google/Apple adapters, authoritative store verification, receipt acknowledgement/refund notifications, actual store restore, account setup/signing/TLS hosting and premium equipment consumer remain external/future work. Earned cosmetics are local, not account-cloud-synced.
- Current emulator FPS: normal {normal['average_fps']:.2f}, 32decor {decor['average_fps']:.2f}, saver {saver['average_fps']:.2f}, 70creatures+32decor {stress['average_fps']:.2f}. Same-host old0.7 control {control['average_fps']:.2f}. Host variation is material; stable phone60 and this host's stable saver30 are unverified. Android theme/capture-loop stalls remain despite eliminating terrain/sprite rebuilds. No physical device was connected.
- Vector cosmetics intentionally complement retained painted art; they are flatter and four presentation themes share original terrain structure. Isometric rotation is four mirrored/foreshortened facings. One ornament per tile; 32concurrent props. Undo/redo retains20layout states only until a world switch and does not refund purchases.
- Terrain can change after a valid placement; decor may then need manual move/store. Large props protect current settlements at placement, not future settlement expansion. No functional terrain is deleted. Rare-condition clarity and generous early collection pacing need real testers; finite rewards stop at525 and catalog costs450.
- Private local soft-currency saves are validated for consistency, not protected from deliberate local file editing. Never use that ledger as proof of premium ownership. Existing ambiguous diagnostics from early desktop QA were retained and are not human evidence; current visual harness uses an isolated simulated destination.
- Shutdown ObjectDB/resource warnings and emulator shader-cache recompilation warnings remain. Physical touch, haptics, thermals, battery, OEM safe areas/keyboards and accessibility need device testing. Windows Computer Use activation was unavailable; actual Godot/MCP and Android ADB rendering supplied visual inspection.
- Human testers/retention/monetization demand remain zero/unvalidated. No public deployment, paid service, live payment or store publication occurred.

## Retained 0.7 limitations (historical measurements)

{old}
''')
print(json.dumps(summary,indent=2))
