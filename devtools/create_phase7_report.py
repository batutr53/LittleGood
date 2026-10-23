"""Release evidence assembled only from verified local results; no network/upload."""
from pathlib import Path
import json,hashlib,shutil,subprocess,xml.etree.ElementTree as ET,re
root=Path(__file__).resolve().parents[1];out=root/'builds/phase7';docs=root/'docs'
def read(name):return json.loads((out/name).read_text(encoding='utf-8-sig'))
backend=read('backend-integration.json');security=read('security-integration.json');desktop_flow=read('godot-integration.json');android=read('android-online/result.json');offline=read('android-online/offline-result.json');qa=read('android-qa/result.json');native=read('android-social/result.json');install=read('android-install.json');balance=read('balance.json')
smooth=read('final-android/android-smooth.json');saver=read('final-android/android-economy.json');stress=read('final-android/android-stress.json');desktop=read('desktop-smooth.json')
mem=re.search(r'TOTAL PSS:\s+(\d+)\s+TOTAL RSS:\s+(\d+)',(out/'android-online/memory.txt').read_text())
pss,rss=map(int,mem.groups())
apk=root/'builds/android/LittleGod-0.7-debug.apk';apk_hash=hashlib.sha256(apk.read_bytes()).hexdigest()
assert backend['passed']==backend['total']==65 and security['all_passed'] and android['all_passed'] and desktop_flow['all_passed'] and qa['all_passed'] and native['all_passed']
assert len(android['checks'])==34 and all(offline['checks'].values()) and all(install['preserved'].values()) and not balance['failures']
assert all(x['installed_apk_sha256']==apk_hash and x['installed_version']=='0.7.0' and x['player_save_unchanged'] for x in [smooth,saver,stress]) and install['apk_sha256']==apk_hash
assert hashlib.sha256((root/'builds/android/LittleGod-0.7-qa-debug.apk').read_bytes()).hexdigest()==android['qa_apk_sha256']
for suite in ['suite','runtime','phase2','phase3','phase4','phase5','phase6','phase7']:
    log=(out/f'final-{suite}.log').read_text(encoding='utf-8-sig')
    assert 'SCRIPT ERROR' not in log and 'FAIL:' not in log and 'FAIL ' not in log
assert 'PHASE7 15/15' in (out/'final-phase7.log').read_text(encoding='utf-8-sig')
trx=ET.parse(out/'dotnet-tests/phase7.trx').getroot();counters=trx.find('.//{*}Counters');assert counters.attrib['passed']=='21' and counters.attrib['failed']=='0'
evidence=docs/'benchmarks/phase7';evidence.mkdir(parents=True,exist_ok=True)
names=['backend-integration.json','security-integration.json','godot-integration.json','android-online/result.json','android-online/offline-result.json','android-qa/result.json','android-social/result.json','android-install.json','balance.json','desktop-smooth.json','final-android/android-smooth.json','final-android/android-economy.json','final-android/android-stress.json','late-slow/android-smooth.json','late-slow/android-economy.json','matched-06/android-smooth.json','emulator-network.txt','host-observation.json','apk-signature.txt','apk-badging.txt','dependency-audit.txt','adb-devices.txt','qa-cleanup.json','dotnet-tests/phase7.trx','android-online/memory.txt','mcp-visual.log']
for name in names:
    target=evidence/name;target.parent.mkdir(parents=True,exist_ok=True)
    if target.suffix in ['.txt','.log']:
        target.write_text('\n'.join(line.rstrip() for line in (out/name).read_text(encoding='utf-8-sig').splitlines()).rstrip()+'\n',encoding='utf-8')
    else:shutil.copyfile(out/name,target)
for suite in ['suite','runtime','phase2','phase3','phase4','phase5','phase6','phase7']:shutil.copyfile(out/f'final-{suite}.log',evidence/f'final-{suite}.log')
shutil.copyfile(out/'openapi.json',docs/'API_SCHEMA.json')
for name in ['friends','profile','visit','creature','inbox','discovery','home-tr']:shutil.copyfile(out/f'android-online/{name}.png',docs/f'screenshots/phase7-{name}.png')
shutil.copyfile(out/'final-android/android-smooth.png',docs/'screenshots/phase7-android-world.png')
for name in ['STATUS','KNOWN_ISSUES','TEST_REPORT']:
    (docs/f'archive/phase6-{name}.md').write_bytes(subprocess.check_output(['git','show',f'littlegod-0.6:docs/{name}.md'],cwd=root))
summary={'game_checks':295,'preserved_phase6_checks':280,'phase7_checks':15,'dotnet_tests':21,'http_integration_checks':65,'security_checks':len(security['checks']),'godot_online_checks':34,'android_online_checks':34,'android_server_stopped_checks':5,'android_regression_checks':26,'native_file_checks':3,'balance_scenarios':40,'physical_devices':0,'human_testers':0,'apk_sha256':apk_hash}
(evidence/'tests.json').write_text(json.dumps(summary,indent=2),encoding='utf-8')
table='| Scenario | Average FPS | p95 frame ms | First engine frame ms |\n|---|---:|---:|---:|\n'
for label,r in [('Windows source, 15 s',desktop),('Android emulator normal, 30 s',smooth),('Android emulator saver, 20 s',saver),('Android emulator 70 creatures, 20 s',stress)]:table+=f"| {label} | {r['average_fps']:.2f} | {r['frame_p95_ms']:.2f} | {r['first_frame_ms']} |\n"
old=read('matched-06/android-smooth.json')
performance_note=f'''Late repeated profiles slowed despite no active editor/test game. A preserved 0.6 APK installed with -r -d then measured {old['average_fps']:.2f} FPS / {old['frame_p95_ms']:.2f} ms p95; restoring the final 0.7 APK measured {smooth['average_fps']:.2f} / {smooth['frame_p95_ms']:.2f}. Both benchmark runs preserve the player save, and the final 0.7 update preserves all four files. An earlier 0.7 candidate measured 57.61 FPS (21.995 ms p95), saver 30.00 and stress 47.09 before the final navigation guard; that earlier APK is not substituted for the release measurements. This matched late control does not show an online-feature FPS regression, and does not isolate the host/emulator slowdown. NVIDIA was observed in P8/210 MHz during the late control; no power/security setting was changed and no causal claim is made from that observation. Stable normal/max-population 60 FPS remains unresolved in this late host state. Battery saver stays near 30.'''
status=fr'''# LittleGod 0.7 — locally tested optional online universe

Verified 2026-10-23. Phase 0.6 was completed and checkpointed as `littlegod-0.6` before online changes. The 0.7 release checkpoint/tag is `littlegod-0.7`, created only after verification. Hosting is **local development only**, with real ASP.NET Core + PostgreSQL and actual desktop/Android HTTP clients. No public deployment, paid service, store publication or human beta is claimed.

## Implemented

- Offline creation, artwork, animations, creatures, civilizations, stories, discoveries, local showcases, saves, localization and battery saver remain. No account/network request is needed to launch, simulate, use powers or save.
- Optional Identity accounts, in-memory access/renewal sessions, server-side logout revocation and account deletion. Existing local worlds link through an explicit reviewed Publish action; there is no silent upload. Local beta uses private usernames, not email; OAuth/email recovery remain pending.
- EN/TR guardian profiles, six retained creature avatars, explicit profile/showcase visibility, exact invitation codes, real requests/accept/reject/remove/block/unblock, friend snapshot profiles and visits, four delivered reactions, opt-in discovery with actual terrain previews and a persisted activity inbox.
- Exact inert v1 snapshot validation in both server and client, revision/hash/update metadata, three retained versions, bounded private memory cache and reauthorization on each visit. The existing read-only boundary preserves the home world and save. Snapshot visits are not real-time multiplayer.
- .NET 10 LTS modular monolith, EF Core/PostgreSQL migration and idempotent SQL, OpenAPI, strict DTOs, request limits, rate limiting, Identity lockout and Data Protection. Docker Compose/API Dockerfile/health checks are included; native PostgreSQL was actually run because Docker Desktop failed during its Inference manager startup.
- New original online SVG and procedural public-terrain preview; existing painted assets retained. Rendered Android/desktop screenshots were examined; stale local-reaction text, duplicate portraits, tiny selectors and preview alignment were corrected.

## Verification

295 game checks (all 280 prior checks plus 15 online transport/session checks); 40 seeded balance scenarios, no failures. 21 .NET validation tests; 65 real HTTP/PostgreSQL integration checks; {len(security['checks'])} real lockout/throttling checks. Two independent disposable users complete 34 actual Godot-to-server checks on Windows and 34 on the Android emulator. A third account tests privacy boundaries in the API suite. QA names are development fixtures, not human activity.

The API was then stopped and its listener absence verified: all 5 Android offline simulation/power/save/load/connectivity checks pass. The prior 26 Android interaction/lifecycle checks and 3 native JSON file checks also pass on the final APK. Physical devices: **0**. Human beta testers: **0**. Save/backup/temp/settings bytes all survived the player-package update. Actual old-save fixtures through 0.5 remain covered. No test was removed; the version assertion now checks project version instead of hardcoding 0.6.

{table}
These are emulator/desktop samples, not phone performance or a causal comparison. Phase 0.6 clean-host emulator normal was 58.05 FPS; host/editor load and startup caches materially affect results. No background polling or startup networking was added. A real published snapshot response was {android['snapshot_bytes']} bytes; observed fetch completion was {android['snapshot_latency_ms']:.1f} ms in the Android emulator and {desktop_flow['snapshot_latency_ms']:.1f} ms in the rendered Windows test. Local API request median/p95 across the integration suite: {backend['latency_median_ms']:.2f}/{backend['latency_p95_ms']:.2f} ms (includes auth/hash requests). Android post-social-session PSS was {pss} KiB, RSS {rss} KiB; this is a different process state than the earlier 0.6 memory sample, not an isolated memory regression measurement. Real battery/thermals remain unmeasured.

## Launch and outputs

- Game: `D:/LittleGod/Launch LittleGod.cmd`, verified runtime `D:/LittleGod/tools/godot/Godot_v4.7.2-stable_win64.exe`.
- Local API: `D:/LittleGod/Launch Online Server.cmd`; native PostgreSQL loopback 55437, API loopback 5087. Game → Online universe → Connection settings; desktop `http://127.0.0.1:5087`, Android emulator `http://10.0.2.2:5087`. Sign in is optional. Default visibility is private; choose Friends before friend visits.
- Player APK: `D:/LittleGod/builds/android/LittleGod-0.7-debug.apk` — version 0.7.0/code 7, {apk.stat().st_size} bytes. v2/v3 signature verification and installation/startup pass. SHA256 `{apk_hash}`. Existing package ID retained; ARM64/x86_64, min API24/target36.
- Source: `D:/LittleGod/builds/LittleGod-0.7-source.zip`, from verified release tag. Backend/migrations/Compose/tests included; local credentials, database, runtimes and generated builds excluded. Existing 0.6 APK/source archive retained.

Read PHASE7_REPORT.md, ONLINE_ARCHITECTURE.md, API_DOCUMENTATION.md, SECURITY_REVIEW.md, ANDROID_TEST_REPORT.md and KNOWN_ISSUES.md. Public-hosting prerequisites remain; Docker execution, OAuth/recovery, physical-phone performance and independent security/human review are not complete. Shutdown ObjectDB/resource warnings remain from earlier milestones. Native Windows Computer Use was unavailable; real Godot rendering/MCP and Android ADB supplied inspection.

![Actual Android published-planet visit](screenshots/phase7-visit.png)
![Actual opt-in discovery gallery](screenshots/phase7-discovery.png)
![Actual Turkish online menu](screenshots/phase7-home-tr.png)
'''
(docs/'STATUS.md').write_text(status,encoding='utf-8')
with (docs/'STATUS.md').open('a',encoding='utf-8') as f:f.write('\n'+performance_note+'\n')
(docs/'TEST_REPORT.md').write_text('''# Verification — LittleGod 0.7

All 280 Phase 6 game checks remain; 15 new checks bring the game total to **295**. The only prior-test version update replaces the fixed 0.6 string with the project version; its simulated-evidence assertion remains. Save fixtures and all read-only guards remain enforced. Forty seeded live/offline balance scenarios pass.

The separate .NET suite has **21** tests covering existing public examples and hostile shape/version/path/event/reference/number cases. **65** real HTTP/PostgreSQL checks use three disposable accounts to exercise authentication, guest-world publishing, actual snapshot payloads, friendship states, reactions, inbox, visibility, block/unblock, removal, deletion, token refresh/revocation, pagination and malformed/oversized input. A separate real security suite proves five-failure Identity lockout and real 429 throttling. No mocked API is counted as integration evidence.

Windows Godot and Android Godot each complete **34** checks against the actual API with two independent disposable identities, including full snapshot reconstruction, creature/settlement inspection, read-only save boundary, home return, real reactions and notifications, block/unpublish/deletion and network failure. Tests drive actual client methods/UI and capture real rendered screens; they are automation, not human usability results. Android uses 10.0.2.2 to reach the host's loopback service. After the API process stopped, **5** independent Android checks confirm the actual failure and continued simulation, powers and save/load. The existing **26** Android ADB/lifecycle checks plus **3** native JSON checks pass on the release APK. Actual ADB pan, zoom, gift, Back and native file pickers are separate from synthetic engine pinch and scripted social calls.

One initial harness compared a nonexistent test-session save; QA now uses its isolated real save slot and the intentional checkpoint boundary. Burst suites initially hit the unchanged 20/IP/minute auth limit on cleanup; separate-window reruns pass, and six interrupted generated QA accounts were removed from the dedicated local database. No limit or guard was weakened. Raw accepted evidence is in docs/benchmarks/phase7 and builds/phase7. Physical devices/human testers: zero.

Godot rendered screenshots were visually examined, including Android visits/gallery/menus and MCP UI captures. Existing shutdown cleanup warnings are retained in raw logs and not represented as gameplay exceptions. APK signatures/install/hash/save preservation and measured performance are recorded in STATUS.md and PHASE7_REPORT.md.
''',encoding='utf-8')
(docs/'PHASE7_REPORT.md').write_text(f'''# Phase 7 delivery report

LittleGod 0.7 adds a real optional local online universe to the existing 0.6 game. The backend is ASP.NET Core 10 / Identity / EF Core / PostgreSQL; the game uses asynchronous HTTP and retains the original offline simulation, artwork and v1 saves. The 0.6 Git tag/source/APK were retained before major changes.

Completed: optional private-username accounts, protected access/renewal tickets, explicit public-profile edits and avatar choices, account deletion/logout, exact-code friendships and blocking, consent-based versioned planet publishing/unpublishing, real read-only friend visits, friendly delivered reactions, opt-in discovery/terrain previews and real persisted activity. No external push, free-text chat, fabricated players/activity or realtime multiplayer is implemented. Online worlds remain snapshots; own-world progress is independent. The small cache is memory-only and requires new authorization before each visit.

The local API ran against actual PostgreSQL 17.11 using vendor-verified portable binaries; Docker Desktop could not start its Inference manager. The supplied Compose/Dockerfile stack is not falsely reported as executed. Migrations actually ran in PostgreSQL, restart migration was safe, and idempotent SQL plus generated OpenAPI are delivered. Authentication uses maintained framework components, not custom cryptography. See SECURITY_REVIEW.md for threat model, tested controls and public-hosting gaps.

Validation: 295 game checks, 40 balance scenarios, 21 .NET tests, 65 real API checks, {len(security['checks'])} security checks, 34 Windows client/server checks, 34 Android client/server checks, 5 actual-server-stopped Android checks, 26 existing Android checks and 3 native-file checks. APK update preserved all four player save/settings files. The native Android account/visit flow is exercised by the debug harness; broader human keyboard/accessibility testing remains. No physical phone, external beta or public hosting is claimed.

{table}
Snapshot download {android['snapshot_bytes']} bytes; emulator fetch {android['snapshot_latency_ms']:.1f} ms versus Windows {desktop_flow['snapshot_latency_ms']:.1f} ms. Local API median/p95 {backend['latency_median_ms']:.2f}/{backend['latency_p95_ms']:.2f} ms over all integration requests, including password hashing. Online calls do not block simulation or run in background. API-unreachable tests demonstrate continued play rather than treating a mock as proof. UI and rendering costs remain bounded; maximum-population 60 FPS, battery, thermal and mid-range-phone claims require physical testing. No causal performance improvement is inferred from different host workloads.

Visual inspection found and corrected a stale local-reaction label, repetitive portraits, short dropdown touch targets and off-center terrain previews. New art is the original online SVG and a procedural map of actual public terrain; existing painted assets remain. See screenshots/phase7-visit.png, phase7-friends.png, phase7-profile.png, phase7-creature.png, phase7-inbox.png, phase7-discovery.png, phase7-home-tr.png and phase7-android-world.png. All are rendered game captures; QA names identify temporary automated worlds.

Artifacts/launch paths and exact APK SHA256 are in STATUS.md. The source ZIP is generated from the verified littlegod-0.7 tag and excludes secrets/generated files. Known issues include Docker startup, no public endpoint/OAuth/recovery, process-local limits, development database/key operational hardening, no independent security/human review, hardware gaps and existing exit cleanup warnings. No paid services, security bypasses or publishing were performed.
''',encoding='utf-8')
(docs/'ANDROID_TEST_REPORT.md').write_text(f'''# Android 0.7 verification

Device: emulator-5554, Android API35 x86_64. No physical device was connected. Final player APK SHA256: `{apk_hash}`. Version 0.7.0/code7, org.littlegod.livinguniverse, min API24/target36, ARM64+x86_64. v2/v3 signatures verify. install -r succeeded without clearing the player package; primary, backup, temp and settings bytes all remain identical. The separate disposable org.littlegod.livinguniverse.betaqa package was reset only for QA.

34 real HTTP-to-PostgreSQL checks pass from the emulator through host alias 10.0.2.2:5087. Two independent accounts register/sign in, publish a real simulation snapshot, request/accept friendship, download and explore that exact planet, inspect its creature biography/community, react, receive real inbox activity, opt in to discovery, block access, unpublish and delete. Every check passes. The activity is explicit test data, not real users. Published response size {android['snapshot_bytes']} bytes; measured completion {android['snapshot_latency_ms']:.1f} ms. QA package hash is recorded in the raw result.

With the actual host API process stopped and port 5087 no longer listening, all five offline checks pass: service unreachable, simulation, powers, checkpoint and load. The prior 26 ADB/lifecycle/rendered-icon/save/visit checks and three native JSON Save/Open/source-integrity checks also pass on this APK's source. First actual ADB gift handler-to-post-draw sample was {qa['handler_to_frame_ms']:.3f} ms; this excludes OS input/display latency. Synthetic engine pinch is labeled separately from actual ADB taps/pan/button zoom.

{table}
These are emulator results with development editors/test games closed during samples. Each profile records the actual installed APK hash, version, scenario and unchanged player save. Real battery consumption, thermal throttling, physical pinch/haptics and OEM safe areas/keyboards remain unverified. Post-social QA PSS/RSS was 190284/{rss} KiB; compare cautiously because it is a different process state from 0.6. No default background HTTP/polling is added. See raw results in benchmarks/phase7.
''',encoding='utf-8')
for name in ['PHASE7_REPORT.md','ANDROID_TEST_REPORT.md']:
    with (docs/name).open('a',encoding='utf-8') as f:f.write('\n'+performance_note+'\n')
print(json.dumps(summary,indent=2))
known=subprocess.check_output(['git','show','littlegod-0.6:docs/KNOWN_ISSUES.md'],cwd=root).decode('utf-8')
known=known.replace('# Known issues — LittleGod 0.6','# Known issues — LittleGod 0.7')
lines=known.splitlines()
lines=[line for line in lines if not line.startswith('- Clean-host emulator performance') and not line.startswith('- This is a LOCAL social showcase')]
lines.insert(2,f'- Current emulator samples: {smooth["average_fps"]:.2f} FPS normal, {saver["average_fps"]:.2f} saver, {stress["average_fps"]:.2f} at 70 creatures; physical-device/max-population 60 FPS remains unverified. Prior host-editor interference evidence remains in PERFORMANCE_PHASE6.md. Current raw results are in benchmarks/phase7.')
lines.insert(3,'- Online accounts/friends/showcases/reactions/discovery/inbox work against a locally tested real API/PostgreSQL service. There is no public endpoint, external OAuth, email recovery, presence, real-time co-simulation or push. Explicit profile/showcase visibility defaults private. A server outage leaves offline play usable; private cached visits still require reauthorization.')
lines.insert(4,'- Docker Desktop failed during Inference manager startup. Compose/Dockerfile are supplied but container execution is unverified. Native PostgreSQL ran the actual tests. Public hosting requires TLS/secrets/least-privilege roles/backups/moderation/account recovery/independent review; see SECURITY_REVIEW.md. Limits are process-local; local development is not production approval.')
lines.insert(5,'- Native Windows Computer Use could not activate/capture the game (foreground window process-id error). Godot MCP, rendered runtime captures and Android ADB provided actual visual inspection. Human keyboard/accessibility and long-term enjoyment testing remain pending. In-flight profile/visit responses now respect Back navigation, covered by real client/server automation.')
(docs/'KNOWN_ISSUES.md').write_text('\n'.join(lines)+'\n',encoding='utf-8')
