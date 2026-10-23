# E2B regional performance evidence

Only Iron Hills is implemented/measured. No Ashen Desert result exists. Android is emulator-5554/API35/x86_64/NVIDIA OpenGL translation. The connected Samsung phone reported `unauthorized` during this development run; no E2B phone performance, thermal, haptic or battery verification is claimed. Earlier successful E1 phone installation is separate.

| Scene / cap | FPS | p95 ms | Model step µs |
|---|---:|---:|---:|
|Emulator 60 cap · Active mountain encounters|59.69|21.13|152|
|Emulator 60 cap · Cleared Forgotten Mine|59.83|18.94|142|
|Emulator 30 cap · Active mountain encounters|30.22|38.90|137|
|Emulator 30 cap · Cleared Forgotten Mine|30.22|36.44|163|
|Desktop · cleared mine|60.67|16.94|108|

Final desktop setup 10.76ms, 61 draw calls, 47.67MiB static allocator memory. Android60-cap mine setup 37.91ms, 62 draw calls, 48.17MiB static / 42.45MiB reported video memory. The Android cleared-mine samples span8 seconds; the active encounters sample includes real bot navigation and fights with both archetypes and reports its exact frame count. It is a short encounter sample, not a sustained stress/thermal test. Exact setup, draw calls, static/video memory, launch activity timing and OS PSS/RSS are in benchmarks/phase085e2. Godot allocator/video monitors and Android process PSS are different measurements.

The first static mountain ground submitted hundreds of circle/path drawing commands. It now imports one original960×1440 vector terrain texture, retaining separate live hero/enemies, props, interactables and collision bodies. The largest new texture is approximately5.27MiB at RGBA8 before driver compression/mipmaps; there are no new particle systems. Enemy count is bounded at2, loot at20 and stored regions at2. Existing20Hz combat and30FPS battery-saver behavior remain. Reported model-step cost includes combat/collision helpers, rather than attributing GPU/frame time to AI without evidence.

An earlier long-lived emulator run degraded to35.59FPS/p9552.09ms at the cleared mine, with an8.87FPS short encounter sample; it is retained in builds/phase085e2/degraded-session. Earlier successful native runs were around57–60FPS. Session/host variability is a real limitation; compare the retained observations and final controlled rerun instead of claiming every difference is a code optimization. Restarting the same emulated disk uses no wipe, OS security change or App Control bypass.

E1 route-view59.80FPS/p9519.38ms and30.00FPS/p9534.88ms remain historical reference values for a different scene. They are not interchangeable adventure-map benchmarks. Reproduce with devtools/android_regions_validate.py --fps60/30 (arguments separated as `--fps 60` and `--fps 30`); commands clear only the isolated QA package. Native controls and engine-driven bot travel are labeled separately in result JSON.

Known runtime output includes an emulator cached-shader warning/recompile after restart, and existing headless/editor-export ObjectDB/resource cleanup warnings. These are retained; script parse errors, invalid saves or failed assertions are not accepted. APK signing/import and activity-start timing do not measure complete first-play readiness.
