"""Record only measured, passing E1 evidence; leave explicit continuation for unfinished E."""
from pathlib import Path
import json,shutil,hashlib,re
r=Path(__file__).resolve().parents[1];out=r/'builds/phase085e1';docs=r/'docs'
def read(p):return json.loads(p.read_text(encoding='utf-8'))
verification=read(out/'verification-summary.json');a=read(out/'android-60/result.json');b=read(out/'android-30/result.json');restart=read(out/'android-60/reopen-result.json');controls=read(out/'profile-control/results.json');desktop=read(out/'desktop-trade-performance.json')
assert verification['all_passed'] and a['all_passed'] and b['all_passed'] and restart['all_passed']
assert desktop['all_passed'] and a['checks']['menu_pause_restored'] and b['checks']['menu_pause_restored']
assert read(out/'android-30/reopen-result.json')['all_passed'] and all(x['valid'] for x in controls)
archive=docs/'archive/d-critical';archive.mkdir(parents=True,exist_ok=True)
for name in ['STATUS.md','KNOWN_ISSUES.md']:
 if not (archive/name).exists():shutil.copy2(docs/name,archive/name)
bench=docs/'benchmarks/phase085e1';bench.mkdir(parents=True,exist_ok=True)
for src,dest in [('verification-summary.json','verification.json'),('desktop-trade-performance.json','desktop-performance.json'),('android-60/result.json','android-60.json'),('android-60/reopen-result.json','android-reopen.json'),('android-30/result.json','android-30.json'),('android-30/reopen-result.json','android-30-reopen.json'),('profile-control/results.json','render-comparison.json'),('android-before-optimization/result.json','initial-sample.json'),('android-60/player-preservation.json','player-preservation.json')]:shutil.copy2(out/src,bench/dest)
for src,dest in [('mcp-draft-tr.png','phase085e1-draft-tr.png'),('android-60/android-trade-returned.png','phase085e1-android-returned.png'),('caravan-road.png','phase085e1-road.png')]:shutil.copy2(out/src,docs/'screenshots'/dest)
apk=r/'builds/android/LittleGod-0.8.5-milestone-E1-debug.apk';sha=hashlib.sha256(apk.read_bytes()).hexdigest()
game_checks=verification['game_checks'];new=verification['new_trade_checks'];pa=a['profile'];pb=b['profile']
launch=re.search(r'TotalTime:\s*(\d+)',(out/'android-60/player-startup.txt').read_text())
pss=re.search(r'TOTAL PSS:\s*(\d+)',(out/'android-60/memory.txt').read_text())
launch_ms=int(launch.group(1)) if launch else None;pss_mib=int(pss.group(1))/1024 if pss else 0
status=f'''# LittleGod — E1: The First Trade Road

Current build: **0.8.5-devE1 / Android code89**, campaign1–21. **Milestone E is partial: E1 is verified; E2–E6 are not implemented.** No `age085-milestone-e` tag is claimed. The audit found D absent at C; critical D was implemented first at `38c7f0d` / `age085-d-critical`. Existing C/D saves, artwork, hero gear and pending jobs remain.

E1 adds the Lantern Marketplace, real merchant jobs, six ordinary trade goods, local buy/sell and regional price comparisons, two strategic trade routes, capacity/supply/cargo/escort reservations, animated wagon monitoring, exactly-once returns and quest21. Weak escorts meet a safe decision gate: pay for a longer detour or return the actual cargo. Offline absence cannot destroy the caravan. Unused-item salvage also works at a staffed forge before E1, so inventory32 cannot block military crafting; equipped gear, army kits and artifacts are protected.

**{game_checks} game assertions pass**:539 retained,44 military and{new} E1. Separate runtime smoke,12 legal1–20 and8 legal1–21 seed scenarios pass. Actual rendered/MCP gameplay, native Android cargo/dispatch/collection/detour and genuine external-process restart pass at60/30 caps. Player planet/backups/settings were byte-compared through package updates/startup. No physical phone was connected; no phone performance claim is made.

Final emulator live-route samples:60-cap **{pa['fps']:.2f}FPS / p95 {pa['p95_ms']:.2f}ms**,30-cap **{pb['fps']:.2f}FPS / p95 {pb['p95_ms']:.2f}ms**. Home simulation averaged{pa['simulation_average_ms']:.2f}ms/tick, peak{pa['simulation_peak_ms']:.2f}ms. The covered planet renderer is suspended during route watch while simulation continues. Fresh-session visibility comparisons are in the performance report; initial degraded-session results are retained, not treated as phone measurements.

- Launch: `D:/LittleGod/Launch LittleGod.cmd`.
- Verified runtime: `D:/LittleGod/tools/godot/Godot_v4.7.2-stable_win64.exe`.
- Player APK: `D:/LittleGod/builds/android/LittleGod-0.8.5-milestone-E1-debug.apk`.
- Isolated QA APK: `D:/LittleGod/builds/android/LittleGod-0.8.5-milestone-E1-qa-debug.apk`.
- Source: `D:/LittleGod/builds/LittleGod-0.8.5-milestone-E1-source.zip`.
- Checkpoint: `age085-e1-trade`; exact commit/hashes: `D:/LittleGod/builds/phase085e1/checkpoint-manifest.json`.
- APK SHA256: `{sha}` ({apk.stat().st_size}bytes).

After quest20, choose **Begin Chapter V**, build the marketplace, assign a merchant and inspect prices. Prepare1–8 units plus up to two escorts, review the fixed quote, then confirm departure. Live Route Watch advances the home simulation even from a paused village, preserving the prior pause setting on exit. Collect at home to finish21. Safe routes may complete offline into escrow; unsafe routes await a decision. The Iron Hills trading post is a strategic destination, **not yet a playable hero region**.

See [E1 report](AGE085_E1_REPORT.md), [trade/caravans](TRADE_SYSTEM.md), [performance](PERFORMANCE_MILESTONE_E1.md), [known issues](KNOWN_ISSUES.md), [D report](AGE085_D_PREREQUISITE_REPORT.md), [military](MILITARY_SYSTEM.md) and [exact E continuation](MILESTONE_E_CONTINUATION.md). Historical C/D status is archived. All older builds/tags remain. No paid service, publishing, security change or App Control bypass occurred.

![Actual Turkish wagon preparation](screenshots/phase085e1-draft-tr.png)
![Actual strategic route gameplay](screenshots/phase085e1-road.png)
![Actual Android returned caravan](screenshots/phase085e1-android-returned.png)
'''
(docs/'STATUS.md').write_text(status,encoding='utf-8')
(docs/'KNOWN_ISSUES.md').write_text('''# Known issues —0.8.5-devE1

- Campaign reaches1–21. E1 trade is complete as a vertical slice; E2–E6 are outstanding. Iron Hills is currently a strategic trading destination, not a playable hero region. No final Milestone E or0.9/F claim/tag exists. See MILESTONE_E_CONTINUATION.md.
- Caravans use a bounded strategic route model, not free-roaming physical wagons. Escort deterrence can prevent a decision gate; no caravan battle or casualties are fabricated. Detours/returns are real resource/travel decisions. At most two pending and twelve recent records are kept; the bounded kingdom journal holds thirty entries.
- Android checks are emulator-only. Fresh short60/30-cap results do not verify phone thermals, battery, haptics, simultaneous multitouch, cutouts/OEM layouts or mid-range performance. Long-lived emulator graphics sessions can degrade markedly. No physical device was connected.
- Army battle collision is a compact slide model and nearest-target combat, not general army navigation. Units can cluster near the camp obstacle. Injuries preserve citizens; cavalry/siege/permanent deaths are absent. Wildwood remains the compact C region with its existing simple AI and procedural sprite animation.
- Inventory still has32 slots/four queued jobs. Staffed-forge/merchant salvage now frees unused items before E1, preserving equipped/army/artifact items and queued work. The confirmation explicitly discards refund overflow. There is no forge cancellation or artifact sale. A retreat waits if its real cargo cannot fit storage; spend/sell stock before collecting.
- Home simulation and caravans pause during active Wildwood/army battles, including absence. Live Route Watch temporarily advances the home simulation even if it was paused, then restores the prior pause flag when closed. Other menus pause work; keep instructors, smiths, farmers and an idle builder assigned appropriately.
- Existing generic home rocks regrow. Finite regional deposits/outposts/logistics and the Desert Sovereign await E2–E5. The route quote table is part of pending-save validation; future price changes require migration rather than discarding old caravans.
- Known Godot headless/editor shutdown ObjectDB/resource cleanup warnings remain. No new gameplay script errors were accepted as passing. Native Computer Use was unavailable; actual Godot/MCP/ADB rendering supplied visual evidence. Automated tests do not establish human beta enjoyment or long-term balance.
- Existing API/.NET runtime remains Windows-App-Control blocked; no bypass/backend change occurred. Purchases remain disabled. No paid infrastructure, public deployment, store publication or external messaging occurred. Historical C/D issues/status remain archived.
''',encoding='utf-8')
rows='\n'.join(f"| {x['sample']} | {x['fps']:.2f} | {x['p95_ms']:.2f} | {int(x['draw_calls'])} |" for x in controls)
(docs/'PERFORMANCE_MILESTONE_E1.md').write_text(f'''# E1 performance evidence

All Android data is emulator-5554, API35/x86_64, NVIDIA OpenGL translation; no physical device. These are short automated samples, not thermal/battery or mid-range phone verification.

Initial live-watch sample:23.38FPS/p9552.20ms,217 draw calls, simulation1.61ms average/2.35ms peak per two-second tick. A later long-lived emulator session also dropped to8FPS. The same persisted LittleGod_Test disk was relaunched with `-no-snapshot -gpu host`, without wiping data/security changes. Fresh comparisons below separate session degradation from rendering work. Do not attribute every FPS change solely to the optimization.

Route watch now hides/suspends the covered planet and foreground renderers, keeping actual home simulation and caravan ticks active. Leaving the panel restores rendering and the prior pause state. Desktop rendered tests verify both directions. Fresh emulator A/B/A comparisons use the same QA APK, scene, quality and60 cap; the middle control explicitly reenables the covered renderer.

| Sample | FPS | p95 ms | Draw calls |
|---|---:|---:|---:|
{rows}

Full native-touch route run60-cap: {pa['fps']:.2f}FPS/p95{pa['p95_ms']:.2f}ms, {pa['frames']}frames, {int(pa['draw_calls'])}draw calls, {pa['memory_bytes']/1048576:.2f}MiB static/{pa['video_memory_bytes']/1048576:.2f}MiB reported video memory. Home tick{pa['simulation_average_ms']:.2f}ms mean/{pa['simulation_peak_ms']:.2f}ms peak.30-cap with the existing battery-saver quality setting: {pb['fps']:.2f}FPS/p95{pb['p95_ms']:.2f}ms. Android reported cold activity launch TotalTime{launch_ms}ms; this is activity launch, not proven complete gameplay readiness. OS meminfo after the sequence reported{pss_mib:.2f}MiB total PSS, which includes more than Godot's static allocator. Raw timing/meminfo are under builds/phase085e1/android-60 and android-30. No overall phone startup time is inferred from QA campaign-setup time.

Desktop RTX4070 live strategic route: {desktop['fps']:.2f}FPS/p95{desktop['p95_ms']:.2f}ms, {int(desktop['draw_calls'])}draw calls. Updated military desktop before E1:60.15FPS/p9516.76ms,5.36ms battle-scene setup,152µs model step. Active army emulator before E1:55.49FPS/p9528.55ms. Tiny vector assets use the existing importer; no new raster megapixel textures or particles were added.

Simulation/cargo records are bounded (two active, twelve retained records); static route data is cached; combat stays20Hz; home/caravan work uses existing two-second ticks. No mechanics were removed to improve the sample. Remaining hitches, renderer/driver variability and physical-device unknowns remain. Reproduce with `devtools/android_trade_validate.py --fps 60` and `--fps 30`, then `devtools/android_trade_profile.py`. Raw JSON copies are in docs/benchmarks/phase085e1.
''',encoding='utf-8')
print('Recorded measured E1 status and performance:',game_checks,'checks')
