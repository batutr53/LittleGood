# Milestone C performance — measured, not a phone guarantee

Godot4.7.2 GL Compatibility. Desktop: RTX4070 Laptop GPU. Android: emulator-5554,API35,x86_64,1080×2400,720×1600 viewport, host NVIDIA OpenGL ES translation. No physical device. Debug builds; no public deployment.

| Actual scenario | Window | FPS | p95 frame ms | Draw calls | Simulation step us |
|---|---:|---:|---:|---:|---:|
| Desktop final Wildwood, after actual rendered guardian fight |10s|60.20|16.867|47|70 whole-run mean|
| Android instrumented guardian fight |2.56s|57.76|20.108|53|79|
| Android postbattle Wildwood,60 cap |15.00s|60.00|18.913|39|124|
| Same scene,30 cap |15.00s|30.00|38.296|39|110|
| Same simulation with scene/HUD hidden |15.02s|60.01|17.933|1|117|

The guardian sample includes runtime screenshot capture and is short; it is not a sustained thermal test. The30-cap sample changes the cap inside the same already-created scene, retaining its tree materials; choosing battery saver before entry also omits foliage shaders. Scene construction measured8.677ms desktop and11.115ms Android; this excludes process startup. Android `am start -W` cold activity timing is retained in player-startup.txt. Android static tracked memory46.96MiB/video36.53MiB; full process PSS/RSS are retained in android-memory.txt. Tracked static memory is not total process memory.

## Evidence and changes

Initial desktop terrain submitted430 separate decorative circles plus other commands; the first rendered C5 sample reported505 draw calls. Original procedural SVG terrain is now imported once and drawn as a single cached texture. Static chest/herb/barrier props no longer rebuild their command geometry on every combat frame; dynamic effects redraw only while visible enemies, strikes, dashes, damage numbers or fading actors require it. The final desktop sample is47 calls, about91% below the initial505. These counts are objective; similar60-FPS capped desktop averages do not show a speedup by themselves.

AI/combat runs at20Hz with at most four enemies and bounded catch-up. Runtime movement uses real collision bodies; AStar construction occurs only on explicit probe routes. Hero art is imported with a384px size cap, terrain is960×1440 and the retained tree atlas1024×1024. Effect textures keep strong references; no per-frame texture loads. UI refreshes at5Hz; no live world regeneration is used when switching modes.

The long-lived emulator process was severely degraded: visible views gave roughly4–9FPS and even the hidden control later fell to7.87FPS. Guest reboot alone did not restore it. A full stop/restart of the same LittleGod_Test AVD, with the same disk, host GPU option and no wipe, restored the hidden control to57–60FPS. Fresh visible runs measured50.33 and60.00FPS;30-cap runs29.90 and30.00. This supports a substantial emulator-session component; the exact host/driver cause is not proven and not all gains can be attributed to game changes. WHPX was installed/usable; a host snapshot showed about12GiB free RAM and low GPU use, not obvious resource exhaustion.

Earlier isolation samples also showed visible-render cost beyond the hidden control, so game drawing was optimized rather than dismissing the problem as emulator-only. Precache/degraded/fresh JSON evidence is retained. No renderer/security setting was bypassed. A transient package-installer timeout was recovered by restarting the test emulator; only the disposable QA package was cleared.

## Limits

Stable60/30 across devices is not established. The latest smooth sample still has a77ms physics monitor peak and74ms process monitor peak; the30-cap p95 is38.30ms. Occasional hitches remain. No physical touch/haptics, battery drain, thermals, long sustained combat or mid-range phone benchmark was performed. Human gameplay comfort and broader aspect ratios need beta testing.
