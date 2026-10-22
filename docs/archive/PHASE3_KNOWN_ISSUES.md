# Current known issues — LittleGod 0.3

- No physical Android device was connected. Thermal/battery behavior, accessibility, physical haptics and sustained multi-touch interactions need device testing. Emulator results use a laptop NVIDIA host GPU and are not phone performance claims.
- Cold shader/font startup and occasional process spikes remain. Isolated smooth Android profiling reached 58.02 FPS / 20.00 ms p95, battery saver 29.56 / 35.12 ms; a 70-creature case reached 52.99 FPS. Earlier runs varied substantially. CPU simulation and terrain rebuild cost improved, but hitch-free 60 FPS is not established. The engine can report failed cached-shader loading and recompile during startup.
- Godot/Forge import/export and runtime tests emit resource/ObjectDB warnings on shutdown. Counts vary with the exercised UI/resources. Runtime MCP error queries found no gameplay script errors; cleanup warnings remain unresolved and are retained in logs.
- Windows App Control blocked the older exported console launcher. Current desktop source play uses the official Godot runtime through Launch LittleGod.cmd. No bypass was attempted.
- Broad biome zones and six-species ecology remain simplified. Four traits and settlement customs now affect simulation, but the four living chapters are a modest initial content set. Technology is a recorded statistic without an extensive research tree. Enjoyment and daily revisits need external player testing.
- Sprite motion uses independent breathing, bobbing, travel and rain poses rather than full hand-painted directional frame animation. Canopy/building occlusion is improved with depth ordering but can still overlap dense groups. A 70-creature stress scene is deliberately more crowded than the initial world.
- Saves still have one current planet and one backup. New-planet creation replaces that slot after its warning; multi-slot saves and future-version migration remain roadmap work. Existing version-one saves are normalized and their continued evolution is regression-tested.
- Offline progression remains a protected compression of time: one tick per real minute, capped at 480 ticks. It is deliberately not an exact replay of live seconds.
- MCP works through the local standard SDK bridge and editor add-on. The current Codex session still has no dynamically registered native Godot tool namespace; a later session can load the registered server normally.
- No iOS binary or store-ready build exists. The Android APK is debug-signed and no payments, backend, telemetry or publishing are enabled.

Historical phase-one issues, including the old four-Hz terrain cache and font-glyph controls, are archived in docs/archive/PHASE1_KNOWN_ISSUES.md. They should not be mistaken for the current renderer.
