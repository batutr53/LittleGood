# Android / desktop animation measurements — V4B preview

Measured with verified Godot4.7.2. Emulator: `emulator-5554`, x86_64, host NVIDIA RTX4070 laptop GPU translation. No physical Android device was connected. These are Warrior idle/walk/native-input samples, not a completed boss/VFX stress certification.

| Sample | FPS | p95 ms | Draw calls | Static bytes | Texture bytes |
|---|---:|---:|---:|---:|---:|
| Desktop rendered | 60.02 | 16.92 | 50 | 51221095 | 47997619 |
| Emulator cap60 | 37.41 | 47.83 | 42 | 51560698 | 53896536 |
| Emulator cap30 | 29.22 | 58.85 | 42 | 51550077 | 53896536 |

The paired comparison on an earlier V4B candidate before the input-clear fix (its APK hash was not recorded for that comparison) measured original actor60.03FPS/p9518.74ms vs preview60.06FPS/p9518.76ms. Texture memory increased16MiB including mipmaps; measured presentation CPU changed137→151µs/frame and model CPU142→147µs/tick. This isolates the actor cost in a steady scene, not every possible encounter.

The first fresh-emulator attempt was5.72FPS/p95566.47ms and failed native movement. It is retained under `android-initial-failure`. After emulator initialization, warm-up and a longer native drag, control checks passed. No device-wide driver or security setting was changed. Low initial samples are not erased or represented as physical-phone results. Cold-start hitches remain a limitation.

AM Activity launch timings are stored separately in startup.txt; they are not a measurement of first interactive gameplay. Android dumpsys PSS is in memory.txt; Godot static allocation and GPU texture indicators are distinct counters, not total process RSS.

Each final Android run passes12 native/session checks and5 restart checks. Native ADB input tests movement, multiple walk frames, attack, dodge, pause/resume and no touch-through. A debug fixture positions the real hero near the wolf for the hit test; this is not a native campaign-completion claim. Force-stop reload compares two separately saved worlds through the real Persistence loader. An earlier harness compared normalized integers to unnormalized JSON numeric strings and failed despite equal numeric data; that failed run is retained.

Final APK SHA256: `da59e8634fd48d361d29f44bd0ccedaeb4bc1397dfeb8f409fcca9f2b9f7d54e`. Package `org.littlegod.livinguniverse.v4preview`, code93. Existing player saves and E3 APK/source hashes are unchanged.

The final native-input run remained variable:37.41FPS/p9547.83ms at the60 cap and29.22FPS/p9558.85ms at the30 cap. Functional checks passed; the stable60FPS performance objective is not achieved or certified. Rendering/host transport remains a suspected bottleneck because measured model/presentation CPU is below0.5ms, but no physical-device attribution is proven.
