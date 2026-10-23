# Android 0.7 verification

Device: emulator-5554, Android API35 x86_64. No physical device was connected. Final player APK SHA256: `875aaad0597de7d2ac7a487ffa07c756cdca99c00effdd909aca47f5996af05c`. Version 0.7.0/code7, org.littlegod.livinguniverse, min API24/target36, ARM64+x86_64. v2/v3 signatures verify. install -r succeeded without clearing the player package; primary, backup, temp and settings bytes all remain identical. The separate disposable org.littlegod.livinguniverse.betaqa package was reset only for QA.

34 real HTTP-to-PostgreSQL checks pass from the emulator through host alias 10.0.2.2:5087. Two independent accounts register/sign in, publish a real simulation snapshot, request/accept friendship, download and explore that exact planet, inspect its creature biography/community, react, receive real inbox activity, opt in to discovery, block access, unpublish and delete. Every check passes. The activity is explicit test data, not real users. Published response size 61520 bytes; measured completion 1014.3 ms. QA package hash is recorded in the raw result.

With the actual host API process stopped and port 5087 no longer listening, all five offline checks pass: service unreachable, simulation, powers, checkpoint and load. The prior 26 ADB/lifecycle/rendered-icon/save/visit checks and three native JSON Save/Open/source-integrity checks also pass on this APK's source. First actual ADB gift handler-to-post-draw sample was 76.558 ms; this excludes OS input/display latency. Synthetic engine pinch is labeled separately from actual ADB taps/pan/button zoom.

| Scenario | Average FPS | p95 frame ms | First engine frame ms |
|---|---:|---:|---:|
| Windows source, 15 s | 60.09 | 16.88 | 1564 |
| Android emulator normal, 30 s | 33.87 | 35.11 | 2392 |
| Android emulator saver, 20 s | 29.97 | 35.07 | 2440 |
| Android emulator 70 creatures, 20 s | 29.38 | 42.36 | 2340 |

These are emulator results with development editors/test games closed during samples. Each profile records the actual installed APK hash, version, scenario and unchanged player save. Real battery consumption, thermal throttling, physical pinch/haptics and OEM safe areas/keyboards remain unverified. Post-social QA PSS/RSS was 190284/277460 KiB; compare cautiously because it is a different process state from 0.6. No default background HTTP/polling is added. See raw results in benchmarks/phase7.

Late repeated profiles slowed despite no active editor/test game. A preserved 0.6 APK installed with -r -d then measured 33.14 FPS / 35.32 ms p95; restoring the final 0.7 APK measured 33.87 / 35.11. Both benchmark runs preserve the player save, and the final 0.7 update preserves all four files. An earlier 0.7 candidate measured 57.61 FPS (21.995 ms p95), saver 30.00 and stress 47.09 before the final navigation guard; that earlier APK is not substituted for the release measurements. This matched late control does not show an online-feature FPS regression, and does not isolate the host/emulator slowdown. NVIDIA was observed in P8/210 MHz during the late control; no power/security setting was changed and no causal claim is made from that observation. Stable normal/max-population 60 FPS remains unresolved in this late host state. Battery saver stays near 30.
