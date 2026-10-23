# LittleGod 0.6 — local social universe beta candidate

Continues the existing LittleGod 0.5 checkpoint c3b2f12 in place. Safe base tag: phase6-base-0.5. Source release tag: littlegod-0.6. Existing artwork, gameplay, Android package identity and version-one saves are preserved. This is a local, offline showcase foundation; no online friends service, payments, publishing or external analytics was enabled.

## Implemented and exercised

Versioned public planet JSON export/import; strict untrusted-data limits; eight replaceable local showcase copies; independent read-only visits with comparison profiles and device-only reactions; native PNG/JSON saving and actual Android Open-picker import; clipboard summaries; richer rendered postcards. Creature portraits/favorites/keepsakes, recorded origins/parents/family groups and migration histories extend the existing traits, bonds and Chronicle. Conditional migration, gardener canopies, wetland bird/grazer shelter, actual conserved food trade and reciprocal rivalry/cooperation create real world consequences. Wonders supplies optional state-based actions and camera-linked places without deadlines or absence penalties.

Original atlas, typography, water, scenery, weather and animations remain. New art is a vector favorite star and procedural place/trade/halo overlays, plus culture tinting of retained village props. Mobile card lists wrap and scroll vertically; six small icon controls repaint through HUD changes, with actual Android pixel validation. Foreground decoration indexing, favorite lookup, redundant sprite-setter removal and rain command batching preserve presentation. First launch joins bounded, private local diagnostic events. No human engagement numbers are fabricated.

## Verification

- **280 unit/scene checks pass** (all prior 206 plus 74 new); **40 seeded extended scenarios**, zero failures.
- **26 Android lifecycle/social checks** and **3 native JSON file checks** pass. ADB pan/zoom-button/gift/Back are real injected input; pinch is synthetic engine input, not physical fingers.
- Actual tagged-0.5 fixture and all older version-one fixtures load. Visits leave imported bytes and own-save bytes unchanged after the deliberate entry checkpoint. Player update preserves primary/backup/temp/settings bytes.
- VersionCode 6 / 0.6.0 main debug APK installs and runs; v2/v3 signatures verify. Minimum API 24 / target 36; ARM64+x86_64. Installed bytes match the exported APK. Native JSON Save/Open and actual rendered PNG writing are exercised on API 35.
- Real Godot MCP play and English/Turkish scenes inspected; final gameplay error lists empty. Known shutdown resource warnings persist. Computer Use found the launcher window but capture/activation failed twice with “foreground window did not report a process id.”

## Measured limits

Final Windows 60.02 FPS. Final emulator normal **58.05 FPS / 21.49-ms p95**, saver **29.99 / 35.02 ms**, 70 creatures **48.64 / 28.05 ms**. First engine frames 1677/1679/1708 ms respectively. The unchanged 0.5 build ranged from 59.68 early to 22.59 later; blank control 58.68. A matched same-APK control measured 19.68 with two development editors open versus 58.31 after closing them. The clean-host normal sample approaches 60 FPS, while stress rendering and frame spikes still need work. First-input feedback and frame spikes remain. No physical phone was connected and no real human beta was conducted. PERFORMANCE_PHASE6.md retains representative slow, control and final samples with caveats; automation cannot prove enjoyment or retention.

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
