# Iron Age prerequisite — measured emulator performance

Final player APK SHA256 `e5cdead6e91ce285b9d262ebdf452860d7985a1bc6407579e9abbd6c48ad92df`; version0.8.5-devB/code86. Profiles run serially with desktop editor and QA stopped, from the same legal completed8-building/4-citizen/2-equipped-tool save. Normal/saver caps remain60/30. Hidden control removes the entire campaign in memory, including economy/rendering/HUD; it is not a GPU-only experiment. Original player save bytes stayed unchanged.

| 20-second emulator scenario | FPS | p50 / p95 ms | First frame ms | Draw / peak | Static / video MiB | Simulation avg / peak ms |
|---|---:|---:|---:|---:|---:|---:|
| Same ecosystem, campaign removed | 22.28 | 44.05 / 51.13 | 2619 | 181 / 211 | 44.9 / 26.8 | 0.96 / 1.56 |
| Eight buildings, four citizens, two equipped tools | 22.07 | 44.37 / 52.66 | 2641 | 195 / 226 | 45.0 / 26.8 | 1.22 / 1.83 |
| Same industry fixture, battery saver | 26.14 | 37.22 / 45.29 | 2958 | 135 / 162 | 45.0 / 26.7 | 1.37 / 1.80 |


These are short emulator-5554 API35x86_64/GL Compatibility samples, not phone benchmarks or a controlled causal improvement claim.1080×2400 output,720×1600internal viewport. Startup includes engine/shader/cache/host effects; first-frame counters are not pure world-generation cost. Original world atlas1024² and cosmetic768×512 remain; industry adds768×192 and reused A576×384. Maximum24structures/12citizens/32items/4queued recipes; retained sprite/atlas batching and simulation ticks avoid per-unit physics/navigation agents. No unbounded particle system was added. Production potential and available output are separate; cached active animations stop for absent inputs/full storage.

Simulation costs in the table are much lower than observed frame times; the inherited renderer/emulator host remains the main frame-budget concern. This does not prove which GPU/driver component dominates. Static/video Godot counters and Android full-process PSS/RSS differ; the post-QA dump is retained in benchmarks/phase09/android-industry/memory.txt. Physical thermals, battery, real haptics/OEM input and stable60/30 remain unverified. Original shutdown resource warnings remain; no accepted campaign SCRIPT ERROR. See actual JSON for process/world/foreground/terrain metrics rather than interpreting FPS alone.
