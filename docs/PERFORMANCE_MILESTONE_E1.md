# E1 performance evidence

All Android data is emulator-5554, API35/x86_64, NVIDIA OpenGL translation; no physical device. These are short automated samples, not thermal/battery or mid-range phone verification.

Initial live-watch sample:23.38FPS/p9552.20ms,217 draw calls, simulation1.61ms average/2.35ms peak per two-second tick. A later long-lived emulator session also dropped to8FPS. The same persisted LittleGod_Test disk was relaunched with `-no-snapshot -gpu host`, without wiping data/security changes. Fresh comparisons below separate session degradation from rendering work. Do not attribute every FPS change solely to the optimization.

Route watch now hides/suspends the covered planet and foreground renderers, keeping actual home simulation and caravan ticks active. Leaving the panel restores rendering and the prior pause state. Desktop rendered tests verify both directions. Fresh emulator A/B/A comparisons use the same QA APK, scene, quality and60 cap; the middle control explicitly reenables the covered renderer.

| Sample | FPS | p95 ms | Draw calls |
|---|---:|---:|---:|
| hidden_A | 59.87 | 20.15 | 47 |
| visible_control | 30.87 | 36.85 | 206 |
| hidden_B | 60.04 | 18.11 | 47 |

Full native-touch route run60-cap: 59.80FPS/p9519.38ms, 2836frames, 46draw calls, 47.95MiB static/26.73MiB reported video memory. Home tick1.48ms mean/1.79ms peak.30-cap with the existing battery-saver quality setting: 30.00FPS/p9534.88ms. Android reported cold activity launch TotalTime1214ms; this is activity launch, not proven complete gameplay readiness. OS meminfo after the sequence reported185.19MiB total PSS, which includes more than Godot's static allocator. Raw timing/meminfo are under builds/phase085e1/android-60 and android-30. No overall phone startup time is inferred from QA campaign-setup time.

Desktop RTX4070 live strategic route: 60.24FPS/p9516.70ms, 47draw calls. Updated military desktop before E1:60.15FPS/p9516.76ms,5.36ms battle-scene setup,152µs model step. Active army emulator before E1:55.49FPS/p9528.55ms. Tiny vector assets use the existing importer; no new raster megapixel textures or particles were added.

Simulation/cargo records are bounded (two active, twelve retained records); static route data is cached; combat stays20Hz; home/caravan work uses existing two-second ticks. No mechanics were removed to improve the sample. Remaining hitches, renderer/driver variability and physical-device unknowns remain. Reproduce with `devtools/android_trade_validate.py --fps 60` and `--fps 30`, then `devtools/android_trade_profile.py`. Raw JSON copies are in docs/benchmarks/phase085e1.
