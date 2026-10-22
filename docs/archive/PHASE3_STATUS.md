# LittleGod 0.3 — phase 3 status

Continues **0.2 checkpoint `3b04cab`**. Existing gameplay, version-one saves, artwork, localization and Android support remain. The release checkpoint is Git tag **`littlegod-0.3`**; the delivery message contains its commit hash.

Implemented and exercised in the real game: an interactive care loop; persistent creature names and four behavioral traits; a camera-linked neighbor album; named communities with three simulation-affecting customs; wildlife/community food-sharing friendships; rain-driven desert meadows; conditional lantern groves; village chapters; permanent named discovery records; immediate discovery/power effects; EN/TR guidance and journal; clearer speed controls; and return summaries with actual population/community/discovery changes. No streaks, purchases, notifications or new absence penalties were added.

Performance work replaces per-creature full-map movement scans, caches shared terrain corners/colors, retains prop caches across gifts and refreshes slow vegetation tint every eight ticks. Topology changes still refresh promptly. Existing painted assets remain; new flowers, fireflies and hearts use procedural gameplay graphics.

## Verified results

- **116 automated checks pass:** original 51, original scene integration 1, phase-two 15, new phase-three 49. Existing tests were not weakened. The 10,000-tick world remains valid; final run took 6.15 seconds. New checks cover traits, discoveries, friendships, save migration, offline events, threshold timing, founders, onboarding, album, stable selection and full-habitat gift rejection.
- Windows smooth: **60.05 FPS**, 18.33 ms p95, 15 seconds; 4.99 ms last terrain build, two builds.
- Android emulator later APK validation: **57.89 FPS**, 20.69 ms p95, 30 seconds; .757 ms average simulation, 6.68 ms last terrain build, three builds. Prior 0.2 measured .950/17.41 ms and 15 builds. An earlier isolated 0.3 run reached 58.02 FPS.
- Android emulator battery saver: **29.56 FPS**, 35.12 ms p95, 30 seconds. A 70-individual case reached **52.99 FPS**, 23.61 ms p95, 12 seconds. Blank control reached 57.62 FPS. Slower runs are retained and discussed in the report.
- Android debug APK exports, verifies with v2/v3 signatures, installs over the existing package and starts. VersionCode 3 / versionName 0.3.0; min API 24, target 36, ARM64+x86_64. Completed profiles preserve the player's save bytes.
- Godot MCP gameplay input and screenshots plus native Computer Use inspection were performed. No physical Android device was connected. Emulator numbers are not physical-phone, thermal or battery-life claims.

## Exact launchers and outputs

- Source launcher: `D:\LittleGod\Launch LittleGod.cmd`
- Verified runtime: `D:\LittleGod\tools\godot\Godot_v4.7.2-stable_win64.exe`
- Godot project: `D:\LittleGod\project.godot`
- Android debug APK: `D:\LittleGod\builds\android\LittleGod-0.3-debug.apk`
- Source archive: `D:\LittleGod\builds\LittleGod-0.3-source.zip`
- Build/test evidence: `D:\LittleGod\builds\phase3\`
- Versioned test/profile evidence: `D:\LittleGod\docs\benchmarks\phase3\`

## Gameplay evidence and remaining limits

Real rendered screenshots: [before](screenshots/phase3-before.png), [named neighbor](screenshots/phase3-neighbor.png), [friendship](screenshots/phase3-friendship.png), [village](screenshots/phase3-village.png), [discoveries](screenshots/phase3-discoveries.png), [extended simulation](screenshots/phase3-extended.png), [neighbor album](screenshots/phase3-neighbors.png), [Turkish journal](screenshots/phase3-journal-tr.png).

See [gameplay improvement report](PHASE3_REPORT.md), [test report](TEST_REPORT.md) and [known issues](KNOWN_ISSUES.md). Startup/occasional process spikes and shutdown resource warnings remain. Smooth mode does not sustain 60 FPS in every emulator run, especially the 70-creature case. Technology/ecology and the four-chapter content set remain modest; external first-time player feedback and physical-device validation are still needed. One current save plus backup is retained. No security feature was disabled, no paid service was used, and nothing was published.

Phase-two status and issues are preserved under `docs/archive/`.

Final APK startup/save-preservation evidence is `docs/benchmarks/phase3/final-startup.json`; [actual Android gameplay](screenshots/phase3-android.png) and [six-hour return screen](screenshots/phase3-return.png) were also inspected.
