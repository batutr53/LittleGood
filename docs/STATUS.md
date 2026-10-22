# LittleGod 0.5 — living-world beta checkpoint

Continues 0.3 checkpoint e08ed4d, completes the unfinished 0.4 checkpoint **2542db7 / littlegod-0.4**, and extends the existing game in place. The final source release is tagged **littlegod-0.5**. This is a playable development/beta checkpoint; Android's 60-FPS target remains unmet in the tested emulator.

## Implemented and exercised

Persistent illustrated Planet Chronicle with real locations and state snapshots; individual exploration/recorded histories; creature companions and predator avoidance; cultural landmarks, traditions and village alliances; mountain/forest springs, patient silver foxes and rain-clearing bird choirs; creature/community naming; favorite places; camera-linked return highlights; local postcard capture and native PNG saving. Original artwork, six biomes/species, powers, settlements, localization, themes and version-one saves are preserved. No absence penalty, streak, backend, paid service, publishing or external analytics was added.

Phase four also supplies transactionally verified save recovery, menu/intervention/lifecycle checkpoints, pause persistence, sliced offline restore/loading, startup without unused demo terrain, retained prop caches, input isolation and private diagnostic controls. Android Back is now handled at the actual window boundary with Godot auto-quit disabled.

## Verification

- **206 automated checks pass**: core 51, runtime 1, phase two 15, phase three 49, phase four 40, phase five 50. Earlier assertions remain intact.
- **40 seeded balance scenarios**, zero failures, including 10-minute/hour live equivalents and 24-hour/seven-day protected offline replay across five seeds with/without gifts.
- **17 isolated Android QA checks** passed: creation, real ADB pan/zoom-button/power/Back inputs, save/background/kill/reopen, quality modes, synthetic engine pinch and PNG writing. Actual two-finger hardware testing remains outstanding.
- Main debug APK exports, verifies v2/v3 signatures, updates the installed player package and starts. VersionCode 5 / versionName 0.5.0; API 24 minimum / target 36; ARM64+x86_64. Completed player-package profiles and a full emulator-process restart preserve existing save bytes.
- Version-one fixtures from phases one through four load; new fields remain optional. Tests use isolated save paths.
- Real Godot MCP inputs, English/Turkish screenshots, postcard previews, simulated return reports and runtime errors were inspected. Final gameplay error list was empty. Computer Use activation failed in this phase; MCP provided visual validation. No physical phone or human beta results exist.

## Measured performance

| Sample | Average FPS | p95 frame ms | First engine frame ms |
|---|---:|---:|---:|
| Windows smooth (15s) | 60.06 | 16.81 | 1154 |
| Android initial native (30s) | 20.99 | 69.10 | 6381 |
| 0.4 rerun, degraded emulator (30s) | 19.19 | 75.88 | 8007 |
| Android blank control (15s) | 50.25 | 35.05 | 8957 |
| Android after OS reboot (30s) | 13.11 | 121.49 | 25562 |
| Android after VM restart, native (30s) | 27.32 | 61.55 | 18137 |
| Android final 720 smooth (30s) | 30.73 | 51.52 | 6279 |
| Android final 720 saver (30s) | 29.87 | 47.03 | 7086 |
| Android final 720 / 70 creatures (15s) | 26.19 | 59.87 | 4955 |

The emulator is API 35 x86_64 / LittleGod_Test on an RTX 4070 Laptop host. Slow results are retained rather than replaced. The old 0.4 build and blank control also slowed in the same long-running environment. OS reboot and a full VM restart did not restore earlier 58-FPS behavior. This does not establish a single root cause or excuse the unmet Android target. Battery saver averages near 30 but still has frame spikes; 60 FPS and stable phone thermals remain unverified.

Final mobile smooth mode renders at 720×1600 on this tall display, with full effects and the 60-FPS cap; saver reduces effects and caps at 30. It uses 22.85 MB reported video memory versus 35.84 MB in the earlier native-resolution smooth sample. Engine static memory is about 42.35 MB; these are engine monitors, not total process PSS. Final smooth average simulation was 1.586 ms / last terrain build 12.849 ms / 153 ending draw calls. Texture atlas stays 1024×1024. First-frame timings exclude a controlled OS tap-to-interactive experiment and vary with warm/cold startup.

The headless pipeline measured .678-ms generation, 9.896-ms verified save, 2.218-ms parsing and 212.052-ms synchronous 480-tick simulation. Frame-sliced replay peaked at 4.414 ms per slice and took 828.126 ms overall. See PERFORMANCE_PHASE5.md for limitations and the lazy-index comparison. Shutdown cleanup and shader-cache warnings remain.

## Launchers and builds

- Desktop source launcher: `D:\LittleGod\Launch LittleGod.cmd`
- Verified runtime: `D:\LittleGod\tools\godot\Godot_v4.7.2-stable_win64.exe`
- Project: `D:\LittleGod\project.godot`
- Android player APK: `D:\LittleGod\builds\android\LittleGod-0.5-debug.apk`
- Isolated automation APK: `D:\LittleGod\builds\android\LittleGod-0.5-qa-debug.apk`
- Windows export: `D:\LittleGod\builds\windows\LittleGod.exe` (use the verified runtime launcher; exported launch is not App-Control-verified)
- Source archive: `D:\LittleGod\builds\LittleGod-0.5-source.zip`
- Raw local evidence: `D:\LittleGod\builds\phase5*`
- Versioned evidence: `D:\LittleGod\docs\benchmarks\phase5`

## Real gameplay and remaining work

[Living world](screenshots/phase5-world.png) · [Chronicle](screenshots/phase5-chronicle.png) · [Creature details](screenshots/phase5-neighbor.png) · [Terrain experiment](screenshots/phase5-spring.png) · [Seven-day simulated return](screenshots/phase5-return.png) · [Turkish Chronicle](screenshots/phase5-chronicle-tr.png) · [Actual postcard](screenshots/phase5-postcard.png) · [Final Android render](screenshots/phase5-android.png).

Read PHASE5_REPORT.md, GAMEPLAY_BALANCE.md, TEST_REPORT.md, BETA_TEST_PLAN.md and KNOWN_ISSUES.md. Real 10–20-person feedback, physical-device testing, Android frame-time work and deeper late progression are still needed. The economy is generous and hour-long scenarios reach community population caps. No human-fun or retention success has been inferred from automation. Nothing was published or sent to testers, and no Windows security setting was changed.
