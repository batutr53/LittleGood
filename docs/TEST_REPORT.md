# Test report — 22 October 2026

## Phase 2 update

Current results and profiling evidence are in [PHASE2_REPORT.md](PHASE2_REPORT.md). The existing 51 checks still pass; 15 phase-two interaction/legacy-save/10,000-tick checks and the real-scene clock integration check pass as well (67 total). The old tests did not resume JSON-loaded worlds far enough to expose the float-clock modulo bug; the new fixture regression found it and verifies the fix. Android emulator profiling now averages about 59 FPS in smooth mode and 30 FPS in battery saver. The remainder of this document records phase-one history and must not be read as current rendering/performance status.

## Automated simulation and persistence

Godot 4.7.2 headless ran `tests/suite.gd`: **51/51 checks passed**. The recorded 1,800-tick simulations took approximately 1.3–1.7 seconds on this computer; this is simulation throughput, not a phone frame-rate benchmark.

Coverage includes reproducible terrain/wildlife/RNG; different-seed variation; six land biomes plus river; six creature species; valid generated state; 1,800 ticks; bounded population and history; camp→village→town progression; discoveries and season milestone; all six powers changing real state and charging correct spirit; invalid cell and insufficient-spirit rejection; five save/load cycles; 64-bit RNG state preservation; backup recovery after corruption; invalid save rejection; bounded ten-day absence; actual offline events; clock rollback; invalid creature references; malformed numeric and RNG fields.

An additional scene-level test (`tests/runtime.gd`) instantiated the real main scene, created a test world without writing the player save, closed the menu, waited 3.2 seconds and observed tick 1, `paused=false`, `in_menu=false`, processing enabled. This runtime integration check passed.

Failures found and fixed: drawing transforms placed terrain offscreen; communities stalled because food consumption exceeded renewable resources; raw RNG numbers lost precision across JSON; parsing intentionally corrupt JSON emitted unnecessary errors. The suite was rerun after fixes. See `builds/tests.log`.

## Desktop integration and visual inspection

Godot Forge doctor connected to the actual editor. A standard MCP client enumerated 29 tools, read project information and the scene tree, added `MCPProbe`, set its position to (123,45), read that value back, removed the node and launched the main scene. Runtime error query returned no entries. The scene file contains no probe.

Successful input regression through the running game: create planet from the creation screen; click + (zoom 0.88→1.03); drag (pan 0,0→40,30); choose water and touch tile (selected cell 81; energy 100→88); navigate Settings and change language to Turkish; open discovery journal; return to English and manually save. Screenshots were captured from the real renderer and inspected. `builds/journal-tr.png` verifies Turkish text and scroll layout. Windows Computer Use also inspected editor, main menu and creation screens; embedded window coordinate input was less reliable than MCP input.

Rendered captures: `builds/gameplay.png`, `builds/journal-tr.png`, and Android captures. These are evidence of actual gameplay, not game backgrounds or mockups.

## Performance

Initial standalone capture: about 38 FPS and 1,909 draw calls. Profiling motivated a cached terrain SubViewport and per-cell wildlife lookup. After separation, an uncapped capture measured 89 FPS with 287 draw calls. The final configured capture reached its 60 FPS cap with 287 draw calls. Cache-refresh frames can still take longer; these short desktop observations do not establish sustained mid-range mobile performance. First editor-run profile before optimization was 35 FPS, ~75.7 MB static memory, ~15.1 MB video memory, zero orphan nodes.

## Exports

Android debug export succeeded for ARM64 and x86_64, minimum API 24 and target API 36. Final APK is approximately 57.9 MB. Build-tools `apksigner verify --verbose` reports verification success with v2 and v3 signatures. Windows debug export succeeded with an embedded pack, approximately 103.9 MB. Both exports were rebuilt after the renderer optimization, shader, sound and persistence changes.

Headless editor import/export reports Forge-related resource/ObjectDB cleanup warnings after successful work. Standalone capture occasionally reports two ObjectDB instance leaks at automatic exit. These are documented unresolved cleanup issues, not silently counted as clean logs.

Windows App Control blocked an attempt to run `LittleGod.console.exe`. Therefore the exported Windows package is built but its standalone execution is not verified here. Source gameplay through the official Godot runtime is verified; the launch shortcut uses that runtime.

## Android emulator

A new isolated `LittleGod_Test` API-35 x86_64 AVD was created from the installed system image. The debug APK installed successfully. The exported launcher (`GodotAppLauncher`) starts the engine and main menu. An attempted start of the internal non-exported `GodotApp` activity was rejected normally; using the manifest-resolved launcher fixed the invocation without changing Android security.

SwiftShader initially failed an engine shader uniform limit. Host GPU mode then initialized OpenGL ES 3.1 on the NVIDIA GPU and reached the Godot main loop. The final project also lowers unused 3D light limits. The platform's first-run full-screen hint was dismissed. Menu, creation, live planet and rain screens were captured and visually inspected. Android taps created a planet, chose rain, selected a tile and spent 22 spirit (100→78), with visible rainfall. Swipe panned the planet and + enlarged it. Physical phones, thermal behavior, and full multi-touch gestures remain unverified.

## Remaining validation

An Android relaunch restored the existing planet and displayed a real two-minute return summary (`builds/android-away.png`). No new recorded event occurred in those two offline ticks, so the panel correctly showed its peaceful fallback instead of inventing discoveries.

A later headless host-GPU Android debug run logged about 2 FPS. Live simulation therefore progressed slowly under the emulator's bounded frame delta. Android screenshots and input checks do not establish suitable phone performance or sustained mobile timing. This remains a priority device-validation issue.

See KNOWN_ISSUES.md and ROADMAP.md. No physical Android or iOS performance claim, store-ready claim, payment flow test, or complete premium-game claim is made.
