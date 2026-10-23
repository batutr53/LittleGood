# Performance — LittleGod 0.6

| Sample | FPS | p95 frame ms | First engine frame ms |
|---|---:|---:|---:|
| Windows final / 15s | 60.02 | 16.97 | 1501 |
| Android 0.5 early / 20s | 59.68 | 18.25 | 1638 |
| Android 0.5 later / 20s | 22.59 | 66.83 | 4508 |
| Android 0.6 before foreground work / 30s | 21.12 | 66.83 | 8650 |
| Android 0.6 final / 30s | 58.05 | 21.49 | 1677 |
| Android final saver / 30s | 29.99 | 35.02 | 1679 |
| Android final 70 creatures / 20s | 48.64 | 28.05 | 1708 |
| Android blank control / 15s | 58.68 | 29.52 | 7779 |
| Same APK / two editors / 20s | 19.68 | 72.09 | 7996 |
| Same APK / editors closed / 20s | 58.31 | 21.35 | 1544 |

API 35 x86_64 LittleGod_Test emulator, RTX 4070 Laptop host, Compatibility renderer. Only emulator-5554 was attached. Android normal and saver render the 720-wide composition (720×1600 on this display); normal retains full effects/60-FPS cap, saver caps at 30. Desktop capture is 540×960; retain its raw engine render-size monitor, which is sampled before capture and can differ during window scaling. These short samples are not sustained physical-phone or thermal measurements.

## Interpretation and changes

The unchanged 0.5 APK measured 59.68 FPS early in this phase and 22.59 in the later confirmed-version recheck. The blank control reached 58.68. The clean-host final 0.6 sample is 58.05 FPS; stable 60 FPS at maximum population remains unresolved. A matched same-APK test measured 19.68 FPS with two host Godot editors open and 58.31 after closing them. Host development workload is a demonstrated major factor. The exact CPU/GPU/driver contention inside that workload is not isolated. It is not evidence that new gameplay alone caused the slowdown or that phones will be fast. Previous phase-five failures and the new slow samples are preserved.

Foreground work was indexed by simulation/terrain invalidation instead of scanning every empty tile every frame. Favorite halos now use one small ID map instead of per-creature callback searches. Rain lines use one multiline command, retaining appearance. Sprite frame/material assignments avoid redundant setters; retained prop caches and sliced simulation continue. Fresh Android startup now applies the 720-wide mode even without a settings file. Generated build output now joins the already excluded documentation images outside Godot resource scans. The earlier scan had imported 90 generated PNGs and reported duplicate UIDs for copied benchmark images; the isolated import no longer reports those duplicate/nested-project warnings. Build helpers preserve this isolation. No artwork was downsized or mechanics removed. The atlas remains 1024×1024. The pre/post normal samples changed from 21.12 to 58.05 FPS and foreground elapsed wall counters from 20.79 to 6.48 ms. The final host workload also changed, so this difference must not be attributed to code optimization alone. Draw-call totals did not decrease; engine batching already combines these primitives.

Final normal: simulation mean 0.748 ms / peak 1.289; world update mean 0.179 ms; creature animation mean 0.134 ms; foreground elapsed mean 6.477 ms. Ending draw calls 155, peak 170; last terrain build 10.287 ms, 3 rebuilds; active effects 1. Foreground timings include dispatch/queue stalls and are not isolated GDScript CPU or GPU timestamps. Seventy-creature simulation mean 1.269 ms and animation 0.392 ms; rendering remains the larger unresolved cost. Effects are short procedural rings/lines, not GPU particle emitters.

Engine static memory 42.74 MiB and reported video memory 22.85 MiB. A separate Android QA profile/card session measured 171218 KiB total PSS and 267088 KiB RSS with dumpsys meminfo (different loaded UI/cache state; not the benchmark's engine-static total). No leak growth or thermal endurance claim is inferred from one sample.

## Startup, persistence and input

First-engine-frame times above are engine-uptime samples, not controlled OS tap-to-interactive cold starts. Shader and emulator startup varied substantially. Current headless Windows pipeline: generation 0.634 ms, verified save 10.949 ms, parse 2.481 ms, synchronous 480-tick replay 249.227 ms. Frame-sliced replay peak 4.608 ms, total 828.945 ms. Raw terrain-build samples remain in pipeline.json. Phone saving/startup may differ.

Final isolated Android first real ADB power input: 40.524 ms from game handler entry to RenderingServer frame-post-draw. Earlier samples were 168.134/172.093 ms. This excludes OS touch dispatch and display scan-out, and includes first-use rendering work; it is not physical touch-to-photon latency. A first-interaction hitch remains, without a confirmed cause or proven final latency improvement. Lifecycle QA validates background/kill/reopen and immutable visit resume, not OEM hardware gestures.

## Evidence integrity

Profile runs preserve the player's primary save bytes; update validation also compares backup/temp/settings bytes. The final installed player APK SHA-256 matches the artifact: `6a88241d4ac414acc60404d394ab30e916c1a451d5c2729c57883fa10637ad5b`. The profiler records package version, scenario options and (where path discovery succeeds) installed APK hash; a separate final hash check supplies verification for earlier unavailable hash fields. One interrupted stress sample and one mislabeled pre-comparison attempt were excluded, rather than counted. Accepted later 0.5 recheck explicitly records installed_version=0.5.0. Normal/saver/stress final samples were run sequentially after final installation, with both LittleGod development editors and desktop games closed and the QA package force-stopped. Earlier samples had idle development editors present, so the final run also controls that host-workload confound. Exports and desktop GPU profiles were kept outside those samples.

Raw local logs: builds/phase6. Versioned JSON, signature/package information and tests: docs/benchmarks/phase6. Godot shutdown cleanup and shader-cache warnings remain. Physical profiling, representative mid-range ARM hardware, reliable cold-start/input studies and sustained 60-FPS work are still required.
