# Android — 0.8.5-devA First Kingdom

Final debug APK version0.8.5-devA/code85, minAPI24/target36, ARM64/x86_64; signaturev2/v3 and install/update/startup pass. SHA256 `0ce5ff344f96cdf81f4073a982ec24078d5f68b21a3082887b418af44de2594a`. Actual target: emulator-5554, API35x86_64,1080×2400 portrait, internal720×1600, Godot4.7.2 GL Compatibility. No physical phone was connected. Older0.8 results are archived in ANDROID_TEST_REPORT_08.md.

15 kingdom checks pass, including legal five-quest progression, rendered workers/buildings, exact save/load and actual external ADB tile/Confirm taps for an additional house. Its capacity and persisted structure count changed. 26 retained touch/lifecycle/save/visit checks and 3 native JSON Save/Open checks pass. Engine-injected pinch is distinct from external ADB pan/zoom/power taps. These are automated QA, not human beta data. Only the disposable package was cleared; player planet/backup/temp/settings bytes were checked unchanged during update.

| Emulator scenario, 20 seconds | FPS | p50 / p95 ms | First frame ms | Draw / peak | Static / video MiB | Sim avg / peak ms |
|---|---:|---:|---:|---:|---:|---:|
| Same fixture, kingdom removed | 18.32 | 53.21 / 66.31 | 3566 | 164 / 183 | 44.6 / 26.6 | 1.50 / 2.17 |
| Five structures / four citizens | 18.09 | 53.95 / 65.95 | 3396 | 177 / 195 | 44.6 / 26.6 | 1.59 / 2.25 |
| Same kingdom, battery saver | 22.23 | 43.27 / 56.62 | 3570 | 128 / 140 | 44.6 / 26.6 | 1.64 / 2.69 |


All samples identify the final player APK hash and preserved its save. Hidden control removes the optional campaign state/HUD/logic from the same initial fixture in memory; it is not GPU-only isolation. Stop editor and QA while profiling. Host/emulator variance, cached-shader recompilation and long startup remain; these are not phone performance, power or thermal measurements. Stable60/30 is unproven here. Godot static/video counters and Android PSS/RSS are different memory measures; the post-QA meminfo dump is in benchmarks/phase085/android/memory.txt. No security setting or App Control policy was changed. STATUS.md contains exact launch paths and remaining scope.
