# E2 desert performance

Desktop RTX4070 and Android emulator/API35/x86_64/OpenGL translation are reported separately. The physical Samsung phone remained ADB unauthorized; no phone performance/thermal/battery/haptic claim is made.

| Scene | FPS | p95 ms |
|---|---:|---:|
|Emulator 60 · Desert encounters|60.22|19.37|
|Emulator 60 · Cleared ancient road|60.15|18.99|
|Emulator 30 · Desert encounters|30.25|39.15|
|Emulator 30 · Cleared ancient road|30.19|36.89|
|Desktop cleared desert road|60.50|16.98|

Desktop setup 18.39ms, 54 draw calls, 105µs average model/collision step, 50.73MiB static memory. Android60 cleared road: setup26.03ms, 55draw calls, 49.45MiB static / 44.61MiB reported video memory. Full OS PSS/RSS and activity launch time are separate raw records, not the same allocator measurement.

The region uses one imported original960×1440 terrain layer, shared cached sprite resources, bounded3 enemies/20 loot entries and at most2 parked regions. No dynamic shadow lights or particle systems were added. Sand uses6 lightweight streaks; oasis uses one animated arc. Combat remains20Hz; cap30 uses the existing battery-saver settings. Active combat is a short bot-assisted encounter sample, not a sustained stress test; cleared-road samples span8 seconds. Native gestures and bot navigation are labeled separately.

Historical E2B mountain and E1 live-route results concern different scenes; do not compare them as identical benchmarks. Existing E2B degraded long-emulator-session evidence remains under benchmarks/phase085e2. Current raw desert samples live under benchmarks/phase085e2full. Startup shader-cache recompilation warnings and known Godot headless/editor/export ObjectDB/resource warnings remain. Reproduce with devtools/android_desert_validate.py --fps 60 / --fps 30. No security bypass or emulator wipe was used.
