"""Build phase-six documentation from measured, local evidence; never uploads."""
from pathlib import Path
import json, shutil, re, hashlib
root=Path(__file__).resolve().parent.parent
raw=root/'builds/phase6'; dest=root/'docs/benchmarks/phase6'; dest.mkdir(parents=True,exist_ok=True)
def read(p):return json.loads((raw/p).read_text(encoding='utf-8'))
def write(p,s):(root/p).write_text(s,encoding='utf-8')
smooth=read('final-android/android-smooth.json'); saver=read('final-android/android-economy.json'); stress=read('final-android/android-stress.json'); desktop=read('desktop-smooth.json'); pipeline=read('pipeline.json'); qa=read('android-qa/result.json'); native=read('android-social/result.json'); balance=read('balance.json'); install=read('android-install.json'); verified=read('android-installed-verify.json')
artifact_hash=hashlib.sha256((root/'builds/android/LittleGod-0.6-debug.apk').read_bytes()).hexdigest()
assert all(d['installed_apk_sha256']==artifact_hash for d in [smooth,saver,stress])
verified={'installed_apk_matches_artifact':True,'sha256':artifact_hash,'package':'org.littlegod.livinguniverse','version':smooth['installed_version'],'device':'emulator-5554'}
(raw/'android-installed-verify.json').write_text(json.dumps(verified,indent=2),encoding='utf-8')
assert qa['all_passed'] and native['all_passed'] and not balance['failures'] and all(install['preserved'].values())
assert stress['creatures']==70 and not stress['control_scene'] and smooth['installed_version']=='0.6.0'
files=['desktop-smooth.json','pipeline.json','balance.json','android-install.json','android-installed-verify.json','android-qa/result.json','android-social/result.json','apk-signature.txt','apk-badging.txt','android-qa-memory.txt','environment.json','import-isolated.log']
for folder in ['baseline-android','recheck-05','before-foreground-cache','before-icon-fix','final-android','editor-control','editor-closed-recheck']:
 for file in (raw/folder).glob('*.json'):
  if 'invalid' not in file.name and file.name!='benchmark-options.json':files.append(str(file.relative_to(raw)))
for name in files:
 target=dest/name;target.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(raw/name,target)
results={ 'source':'automated_functional_validation','suites':{'core':51,'runtime':1,'phase2':15,'phase3':49,'phase4':40,'phase5':50,'phase6':74},'total':280,'balance_scenarios':len(balance['rows']),'android_qa_checks':len(qa['checks']),'native_file_checks':len(native['checks']),'physical_devices':0,'human_beta_testers':0}
(dest/'tests.json').write_text(json.dumps(results,indent=2),encoding='utf-8')
for src,name in [('final-android/android-smooth.png','phase6-android.png'),('android-social/import-profile.png','phase6-android-import.png')]:shutil.copy2(raw/src,root/'docs/screenshots'/name)
samples=[('Windows final / 15s',desktop),('Android 0.5 early / 20s',read('baseline-android/android-smooth.json')),('Android 0.5 later / 20s',read('recheck-05/android-smooth.json')),('Android 0.6 before foreground work / 30s',read('before-foreground-cache/android-smooth.json')),('Android 0.6 final / 30s',smooth),('Android final saver / 30s',saver),('Android final 70 creatures / 20s',stress),('Android blank control / 15s',read('before-foreground-cache/android-control.json')),('Same APK / two editors / 20s',read('editor-control/android-smooth.json')),('Same APK / editors closed / 20s',read('editor-closed-recheck/android-smooth.json'))]
table='| Sample | FPS | p95 frame ms | First engine frame ms |\n|---|---:|---:|---:|\n'+''.join(f"| {label} | {d['average_fps']:.2f} | {d['frame_p95_ms']:.2f} | {d['first_frame_ms']} |\n" for label,d in samples)
perf=f"""# Performance — LittleGod 0.6

{table}
API 35 x86_64 LittleGod_Test emulator, RTX 4070 Laptop host, Compatibility renderer. Only emulator-5554 was attached. Android normal and saver render the 720-wide composition (720×1600 on this display); normal retains full effects/60-FPS cap, saver caps at 30. Desktop capture is 540×960; retain its raw engine render-size monitor, which is sampled before capture and can differ during window scaling. These short samples are not sustained physical-phone or thermal measurements.

## Interpretation and changes

The unchanged 0.5 APK measured 59.68 FPS early in this phase and 22.59 in the later confirmed-version recheck. The blank control reached 58.68. The clean-host final 0.6 sample is {smooth['average_fps']:.2f} FPS; stable 60 FPS at maximum population remains unresolved. A matched same-APK test measured 19.68 FPS with two host Godot editors open and 58.31 after closing them. Host development workload is a demonstrated major factor. The exact CPU/GPU/driver contention inside that workload is not isolated. It is not evidence that new gameplay alone caused the slowdown or that phones will be fast. Previous phase-five failures and the new slow samples are preserved.

Foreground work was indexed by simulation/terrain invalidation instead of scanning every empty tile every frame. Favorite halos now use one small ID map instead of per-creature callback searches. Rain lines use one multiline command, retaining appearance. Sprite frame/material assignments avoid redundant setters; retained prop caches and sliced simulation continue. Fresh Android startup now applies the 720-wide mode even without a settings file. Generated build output now joins the already excluded documentation images outside Godot resource scans. The earlier scan had imported 90 generated PNGs and reported duplicate UIDs for copied benchmark images; the isolated import no longer reports those duplicate/nested-project warnings. Build helpers preserve this isolation. No artwork was downsized or mechanics removed. The atlas remains 1024×1024. The pre/post normal samples changed from 21.12 to {smooth['average_fps']:.2f} FPS and foreground elapsed wall counters from 20.79 to {smooth['foreground_cpu_average_ms']:.2f} ms. The final host workload also changed, so this difference must not be attributed to code optimization alone. Draw-call totals did not decrease; engine batching already combines these primitives.

Final normal: simulation mean {smooth['simulation_average_ms']:.3f} ms / peak {smooth['simulation_peak_ms']:.3f}; world update mean {smooth['world_cpu_average_ms']:.3f} ms; creature animation mean {smooth['creature_animation_average_ms']:.3f} ms; foreground elapsed mean {smooth['foreground_cpu_average_ms']:.3f} ms. Ending draw calls {int(smooth['draw_calls'])}, peak {int(smooth['peak_draw_calls'])}; last terrain build {smooth['terrain_last_build_ms']:.3f} ms, {smooth['terrain_rebuilds']} rebuilds; active effects {smooth['effects']}. Foreground timings include dispatch/queue stalls and are not isolated GDScript CPU or GPU timestamps. Seventy-creature simulation mean {stress['simulation_average_ms']:.3f} ms and animation {stress['creature_animation_average_ms']:.3f} ms; rendering remains the larger unresolved cost. Effects are short procedural rings/lines, not GPU particle emitters.

Engine static memory {smooth['static_memory_mb']:.2f} MiB and reported video memory {smooth['video_memory_mb']:.2f} MiB. A separate Android QA profile/card session measured 171218 KiB total PSS and 267088 KiB RSS with dumpsys meminfo (different loaded UI/cache state; not the benchmark's engine-static total). No leak growth or thermal endurance claim is inferred from one sample.

## Startup, persistence and input

First-engine-frame times above are engine-uptime samples, not controlled OS tap-to-interactive cold starts. Shader and emulator startup varied substantially. Current headless Windows pipeline: generation {pipeline['world_generation_ms']:.3f} ms, verified save {pipeline['save_ms']:.3f} ms, parse {pipeline['restore_parse_ms']:.3f} ms, synchronous 480-tick replay {pipeline['offline_480_ms']:.3f} ms. Frame-sliced replay peak {pipeline['staged_offline']['offline_peak_slice_ms']:.3f} ms, total {pipeline['staged_offline']['offline_wall_ms']:.3f} ms. Raw terrain-build samples remain in pipeline.json. Phone saving/startup may differ.

Final isolated Android first real ADB power input: {qa['handler_to_frame_ms']:.3f} ms from game handler entry to RenderingServer frame-post-draw. Earlier samples were 168.134/172.093 ms. This excludes OS touch dispatch and display scan-out, and includes first-use rendering work; it is not physical touch-to-photon latency. A first-interaction hitch remains, without a confirmed cause or proven final latency improvement. Lifecycle QA validates background/kill/reopen and immutable visit resume, not OEM hardware gestures.

## Evidence integrity

Profile runs preserve the player's primary save bytes; update validation also compares backup/temp/settings bytes. The final installed player APK SHA-256 matches the artifact: `{verified['sha256']}`. The profiler records package version, scenario options and (where path discovery succeeds) installed APK hash; a separate final hash check supplies verification for earlier unavailable hash fields. One interrupted stress sample and one mislabeled pre-comparison attempt were excluded, rather than counted. Accepted later 0.5 recheck explicitly records installed_version=0.5.0. Normal/saver/stress final samples were run sequentially after final installation, with both LittleGod development editors and desktop games closed and the QA package force-stopped. Earlier samples had idle development editors present, so the final run also controls that host-workload confound. Exports and desktop GPU profiles were kept outside those samples.

Raw local logs: builds/phase6. Versioned JSON, signature/package information and tests: docs/benchmarks/phase6. Godot shutdown cleanup and shader-cache warnings remain. Physical profiling, representative mid-range ARM hardware, reliable cold-start/input studies and sustained 60-FPS work are still required.
"""
write('docs/PERFORMANCE_PHASE6.md',perf)
status=fr"""# LittleGod 0.6 — local social universe beta candidate

Continues the existing LittleGod 0.5 checkpoint c3b2f12 in place. Safe base tag: phase6-base-0.5. Source release tag: littlegod-0.6. Existing artwork, gameplay, Android package identity and version-one saves are preserved. This is a local, offline showcase foundation; no online friends service, payments, publishing or external analytics was enabled.

## Implemented and exercised

Versioned public planet JSON export/import; strict untrusted-data limits; eight replaceable local showcase copies; independent read-only visits with comparison profiles and device-only reactions; native PNG/JSON saving and actual Android Open-picker import; clipboard summaries; richer rendered postcards. Creature portraits/favorites/keepsakes, recorded origins/parents/family groups and migration histories extend the existing traits, bonds and Chronicle. Conditional migration, gardener canopies, wetland bird/grazer shelter, actual conserved food trade and reciprocal rivalry/cooperation create real world consequences. Wonders supplies optional state-based actions and camera-linked places without deadlines or absence penalties.

Original atlas, typography, water, scenery, weather and animations remain. New art is a vector favorite star and procedural place/trade/halo overlays, plus culture tinting of retained village props. Mobile card lists wrap and scroll vertically; six small icon controls repaint through HUD changes, with actual Android pixel validation. Foreground decoration indexing, favorite lookup, redundant sprite-setter removal and rain command batching preserve presentation. First launch joins bounded, private local diagnostic events. No human engagement numbers are fabricated.

## Verification

- **280 unit/scene checks pass** (all prior 206 plus 74 new); **40 seeded extended scenarios**, zero failures.
- **{len(qa['checks'])} Android lifecycle/social checks** and **{len(native['checks'])} native JSON file checks** pass. ADB pan/zoom-button/gift/Back are real injected input; pinch is synthetic engine input, not physical fingers.
- Actual tagged-0.5 fixture and all older version-one fixtures load. Visits leave imported bytes and own-save bytes unchanged after the deliberate entry checkpoint. Player update preserves primary/backup/temp/settings bytes.
- VersionCode 6 / 0.6.0 main debug APK installs and runs; v2/v3 signatures verify. Minimum API 24 / target 36; ARM64+x86_64. Installed bytes match the exported APK. Native JSON Save/Open and actual rendered PNG writing are exercised on API 35.
- Real Godot MCP play and English/Turkish scenes inspected; final gameplay error lists empty. Known shutdown resource warnings persist. Computer Use found the launcher window but capture/activation failed twice with “foreground window did not report a process id.”

## Measured limits

Final Windows {desktop['average_fps']:.2f} FPS. Final emulator normal **{smooth['average_fps']:.2f} FPS / {smooth['frame_p95_ms']:.2f}-ms p95**, saver **{saver['average_fps']:.2f} / {saver['frame_p95_ms']:.2f} ms**, 70 creatures **{stress['average_fps']:.2f} / {stress['frame_p95_ms']:.2f} ms**. First engine frames {smooth['first_frame_ms']}/{saver['first_frame_ms']}/{stress['first_frame_ms']} ms respectively. The unchanged 0.5 build ranged from 59.68 early to 22.59 later; blank control 58.68. A matched same-APK control measured 19.68 with two development editors open versus 58.31 after closing them. The clean-host normal sample approaches 60 FPS, while stress rendering and frame spikes still need work. First-input feedback and frame spikes remain. No physical phone was connected and no real human beta was conducted. PERFORMANCE_PHASE6.md retains representative slow, control and final samples with caveats; automation cannot prove enjoyment or retention.

## Launch and deliverables

- Launcher: `D:\LittleGod\Launch LittleGod.cmd` (official verified source runtime).
- Runtime: `D:\LittleGod\tools\godot\Godot_v4.7.2-stable_win64.exe`.
- Project: `D:\LittleGod\project.godot`.
- Player APK: `D:\LittleGod\builds\android\LittleGod-0.6-debug.apk`.
- Isolated QA APK: `D:\LittleGod\builds\android\LittleGod-0.6-qa-debug.apk`.
- Source: `D:\LittleGod\builds\LittleGod-0.6-source.zip`.
- Public examples: `D:\LittleGod\docs\examples\Lumi.lgplanet`, `Nacre.lgplanet`.
- Full local evidence: `D:\LittleGod\builds\phase6`; versioned summaries: `D:\LittleGod\docs\benchmarks\phase6`.

Windows debug export is also generated under builds/windows, but use the verified source launcher; exported launch is not claimed App-Control-verified. No security feature was disabled or bypassed.

[Living world](screenshots/phase6-world.png) · [Collection](screenshots/phase6-collection.png) · [Biography](screenshots/phase6-biography.png) · [Profile](screenshots/phase6-profile.png) · [Read-only visit](screenshots/phase6-visit.png) · [Turkish profile](screenshots/phase6-profile-tr.png) · [Wonders](screenshots/phase6-places.png) · [Controlled story fixture](screenshots/phase6-system-stories.png) · [Rendered postcard](screenshots/phase6-postcard-export.png) · [Android](screenshots/phase6-android.png) · [Android imported profile](screenshots/phase6-android-import.png).

See PHASE6_REPORT.md, SOCIAL_ARCHITECTURE.md, PLAYER_EXPERIENCE_REPORT.md, TEST_REPORT.md, BETA_TEST_PLAN.md and BETA_FEEDBACK_FORM.md. Remaining work includes physical-device profiling, first-input/startup hitches, direct native share integration, deeper late progression and real invited-player feedback. Online accounts require the consent/authentication/moderation/backend work described in SOCIAL_ARCHITECTURE.md. Nothing was sent to testers or published.
"""
write('docs/STATUS.md',status)
write('docs/PHASE6_REPORT.md',f"""# Phase six delivery — LittleGod 0.6

The existing 0.5 project was audited and extended in place; baseline six suites passed all 206 checks. The safe phase6-base-0.5 tag preserves c3b2f12. Source delivery is tagged littlegod-0.6. No project recreation, save reset, paid service, social backend or publication occurred.

## Playable changes

Local universe supports public `.lgplanet` export/import, validated bounded copies, comparison profiles, read-only ecosystem/community visiting, local friendly reactions, summaries and real-world postcards. The native Android Save/Open flow wrote and reopened actual JSON without changing the original file. Public projection excludes save/RNG/timestamp/device/diagnostic/private-path data and remaps identities; visible player names are intentionally public and reviewed in the profile. Unknown fields, executable/resource payloads, invalid references/types/ranges, oversize/deep documents and future formats are rejected. See SOCIAL_ARCHITECTURE.md for the exact boundary and future asynchronous-provider interface.

Creature favorites use stable IDs, preserve small departed keepsakes and add portrait collection controls. Biographies record parent names, family group, first-recorded origin and migrant status, alongside preserved traits, history and bonds. Habitat-driven migrations, gardener canopy shelter, bird/grazer reed shelter and real food transfers extend world simulation. Scarce neighbors form reciprocal rivalries and can cooperate again after resources recover or alliance forms. These are conditional discoveries, with no calendar rewards, punishments, fabricated daily messages or artificial waits. Wonders focuses real places and suggests current actions. Existing return reports include actual new events during bounded offline replay.

## Presentation and interaction

Retained original painted assets, typography, terrain transitions, water, weather and animations. Added original favorite SVG and procedural animated places, trade trails and favorite halos; retained village art gains culture tinting. Profiles feature varied species portraits, population, environments, discoveries, landmarks and recent memories. Postcards include public world statistics over the real scene. Wrapped discovery/collection buttons and vertical card lists fix observed horizontal overflow; visitor menus scroll and hide editing. PNG-save results now appear in the visible preview. No static concept art substitutes for gameplay.

The first fifteen-minute equivalent was exercised through actual opening controls plus simulation to tick 450. Two independent, safe showcase examples are included. A controlled Story test world renders deliberately prepared habitat/community conditions through actual rules; it is labeled as a test fixture. English/Turkish screenshots and final MCP error checks were inspected. Windows Computer Use found the source-launcher game but failed activation/capture twice; MCP supplied the rendered evidence. PLAYER_EXPERIENCE_REPORT.md separates functional playtesting from unproven human fun.

## Verification and packaging

280 unit/scene checks, 40 seeded longer scenarios, {len(qa['checks'])} Android checks and {len(native['checks'])} native file checks pass. Original assertions remain. Tagged-0.5 and older v1 saves migrate optional fields; real player save/settings bytes are preserved through updates and profiles. A visit deliberately checkpoints the player's current world, then does not write either planet during the visit, including Android resume. See TEST_REPORT.md and versioned evidence.

Main debug APK version 0.6.0/code 6 installs, starts, verifies v2/v3 signatures and matches installed SHA-256 {verified['sha256']}. Existing package ID and ARM64+x86_64 support remain. The official-runtime desktop launcher is updated, a separate disposable QA package is built, and the source ZIP is generated from the release Git checkpoint. APK/source paths and screenshots are in STATUS.md. Source archive excludes local SDK/runtime tools and generated build/cache directories.

## Performance and beta readiness

Final Windows {desktop['average_fps']:.2f} FPS; emulator normal {smooth['average_fps']:.2f}, saver {saver['average_fps']:.2f}, 70 creatures {stress['average_fps']:.2f}. Normal rendering approaches 60 FPS on the clean host, but maximum-population 60 FPS remains unresolved. The unchanged 0.5 APK also fell from an early 59.68 to a later 22.59, while a blank control reached 58.68. A matched final-APK editor-load test reproduced 19.68 FPS with two editors and 58.31 closed, demonstrating major host-workload interference. Ninety generated screenshots had also entered editor imports; the tracked builds/.gdignore marker and build helpers exclude generated build outputs; the existing documentation exclusion remains, eliminating duplicate UID warnings. Foreground indexing/lookup/batching and redundant sprite-setter fixes address actual hot work, without conflating code changes with host-workload effects. Startup variation, first-gift latency and frame spikes remain. PERFORMANCE_PHASE6.md records all metrics, memory, draw calls, pipeline timing and limitations.

Diagnostics add once-only first launch to bounded local session/action/discovery/error events, with explicit simulated-source QA. Unclean sessions are hints, not confirmed native crash stacks. The feedback form/testing guide prepare voluntary 10–20-person evaluation; zero external human testers and zero physical devices were measured. Direct native share-sheet integration, OEM pickers, sustained phone performance and deeper late progression remain. Online friends additionally need an authorized service, consent, authentication, ownership controls, moderation, quotas, deletion flows and operational support; no service was started.
""")
print(json.dumps(results,indent=2))
