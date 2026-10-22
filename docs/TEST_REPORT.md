# Verification — LittleGod 0.5

The final build script executes all suites without weakening earlier assertions:

| Suite | Passed |
|---|---:|
| Core suite (including extended simulation) | 51 |
| Scene runtime | 1 |
| Phase two | 15 |
| Phase three | 49 |
| Phase four | 40 |
| Phase five | 50 |
| **Total** | **206** |

Build command: `D:\LittleGod\devtools\build.ps1`. It imports with the verified Godot runtime, fails on a suite exit error and exports Android/Windows debug builds. Full final output: `D:\LittleGod\builds\phase5-build.log`.

Phase five covers actual co-location bonds and hunger benefits, predator recognition, spring adjacency/moisture and terraforming cleanup, healthy forest fox variants, rain-clearing bird effects, recorded exploration/survival, cultural landmarks/traditions/alliances/drought recovery, names/favorites, transactional history round-trip and corruption rejection, four legacy version-one fixtures, offline highlight consistency, bounded seven-day replay with true absence duration, deterministic progression, bounded history rotation retaining first birth, real scene Chronicle/details, window Back routing, independently readable PNG output and preservation of the player's existing save.

Separate from unit/scene totals: **40 seeded balance scenarios**, zero failures, validate world bounds and save/load histories. Separate Android isolated QA: **17 checks**, all passed, with actual ADB pan, zoom-button, power and Back input; creation/checkpoints/background/kill/reopen; normal/battery-saver settings; synthetic two-finger engine events and real PNG writing. The native Android Save picker was also exercised and its exported PNG read/inspected; that manual automation flow is not counted as another unit assertion.

Godot MCP exercised real rendered play and captured English/Turkish Chronicle, individual details, natural evolution, a terrain experiment, postcards and a simulated seven-day return. The final error list was empty. Shutdown ObjectDB/resource warnings remain and are not removed from logs.

Saved world schema stays at version one with optional fields. Fixtures from phases one through four load and continue. The 0.4 fixture was generated with its tagged WorldGen/LivingStories source. Source fixtures and QA writes use dedicated paths; completed main-package profiles compare saved-planet bytes. Neither emulator tests nor seeded simulation constitute physical-device or human playtesting.

Evidence: `docs/benchmarks/phase5`, `docs/screenshots/phase5-*`, and the full local logs under `builds/phase5*`. Historical reports remain under `docs/archive`.
