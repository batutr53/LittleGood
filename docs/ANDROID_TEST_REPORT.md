# Android — verified Iron Age prerequisite B

Version0.8.5-devB/code86; 59999004bytes; ARM64/x86_64; minAPI24/target36; debug signaturev2/v3. SHA256 `e5cdead6e91ce285b9d262ebdf452860d7985a1bc6407579e9abbd6c48ad92df`. Player package unchanged:org.littlegod.livinguniverse. Install/update/startup succeeded. Existing planet/backup data and absence of temp/settings files were preserved; the report records presence separately. Only disposable org.littlegod.livinguniverse.betaqa was cleared. Prior APKs remain.

16 industry checks: actual ten-quest progression, eight rendered structures, paid forge queues, crafted instances, UI equipment effects, exact restore and actual external ADB unequip/re-equip/save. 15 first-kingdom checks, 26 legacy input/lifecycle/visit checks and 3 native JSON Save/Open checks pass separately. Engine pinch injection is not claimed as physical two-finger testing. Actual English/Turkish workshop/inventory and planet screenshots were inspected. Raw evidence is in benchmarks/phase09; previous A report is archived under archive/first-kingdom-a.

| 20-second emulator scenario | FPS | p50 / p95 ms | First frame ms | Draw / peak | Static / video MiB | Simulation avg / peak ms |
|---|---:|---:|---:|---:|---:|---:|
| Same ecosystem, campaign removed | 22.28 | 44.05 / 51.13 | 2619 | 181 / 211 | 44.9 / 26.8 | 0.96 / 1.56 |
| Eight buildings, four citizens, two equipped tools | 22.07 | 44.37 / 52.66 | 2641 | 195 / 226 | 45.0 / 26.8 | 1.22 / 1.83 |
| Same industry fixture, battery saver | 26.14 | 37.22 / 45.29 | 2958 | 135 / 162 | 45.0 / 26.7 | 1.37 / 1.80 |


Only emulator-5554/API35x86_64,1080×2400portrait/720×1600viewport, Godot4.7.2 GL Compatibility. No physical phone, thermals/battery/OEM safe-area/haptic validation. Samples do not establish stable60/30. Hidden control removes campaign logic and presentation in the same starting ecosystem; no primary save writes. The final APK hash is recorded per profile. See PERFORMANCE_PHASE09.md for bounds and remaining bottlenecks. No App Control/security changes or publishing.
