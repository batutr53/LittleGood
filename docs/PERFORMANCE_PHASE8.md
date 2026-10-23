# Performance evidence — 0.8

| Emulator scenario, 20 seconds | FPS | p95 ms | First frame ms | Draw calls / peak | Static / video MiB | Simulation avg ms |
|---|---:|---:|---:|---:|---:|---:|
| Normal, 18 creatures | 14.70 | 93.38 | 7691 | 143 / 172 | 43.3 / 24.8 | 1.55 |
| 32 decorations, Celestial Night | 13.04 | 105.72 | 6522 | 189 / 217 | 43.5 / 24.9 | 3.10 |
| 32 decorations, battery saver | 17.05 | 87.05 | 8257 | 150 / 171 | 43.5 / 24.8 | 1.34 |
| 32 decorations, 70 creatures | 11.42 | 124.70 | 8436 | 244 / 260 | 43.8 / 24.9 | 2.68 |


The same host's original 0.7 APK measured 13.76 FPS / 119.31 ms p95 in a matched late control; it was restored to 0.8 after checking all four save/settings files. The initial 0.7 baseline earlier in the session was 31.77 FPS / 36.37 ms p95. This large variation also affects startup and CPU time; it is emulator/host evidence, not phone performance. The pre-batching decorated candidate measured 7.15 FPS and 270 draw calls; the final equivalent decorated scene measured 189 draw calls. Common atlas + batched glints reduce render submissions; FPS comparisons are not isolated laboratory causal measurements. Normal and 30-FPS saver caps remain; stable 60 on phones and stable 30 under this slow emulator host are not established.

Original world atlas stays 1024×1024; the shared cosmetic atlas is 768×512 (24 cells of 128×128), with individual SVG previews retained. At most 32 placed sprites are retained, reused across theme changes; glints/stars use packed line batches. Effects are bounded and lower in saver. Theme changes no longer rebuild terrain or recreate placed sprites, verified in rendered QA. Final decorated cosmetic draw CPU average: 3.329 ms; last appearance sync 2.430 ms. Scene/world generation CPU: 66.60/1.97 ms.

Android instrumented theme/capture-loop post-draw intervals: 101.6, 121.8, 100.9, 97.4 ms. They include render scheduling/readback/cache/host effects, not pure shader cost or touch-to-photon latency; hitches remain. Shop construction CPU 58.60 ms, atomic checkpoint 23.28 ms, checked load/migration 8.77 ms. Desktop theme intervals: 18.3, 3.8, 3.2, 3.4 ms; desktop checkpoint/load 10.18/2.40 ms. Android post-customization session PSS/RSS: 182753 / 274276 KiB (android-customization/memory.txt) and is not interchangeable with Godot's static/video counters. Emulator shader-cache recompile warnings and old Godot shutdown resource/ObjectDB warnings remain. No physical thermals, energy or OEM input measurements.
