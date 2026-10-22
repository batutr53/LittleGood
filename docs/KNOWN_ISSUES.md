# Current known issues — phase 2

- No physical Android device was connected. Thermal/battery behavior, accessibility, physical haptics and sustained multi-touch interactions need device testing. Emulator results use a laptop NVIDIA host GPU and are not phone performance claims.
- Cold shader/font/mesh startup and occasional terrain rebuilds produce slower frames. The 30-second smooth Android run averages 57.6 FPS with a 20.07 ms p95, while isolated peak process times are higher. The battery-saver mode is available for less capable devices.
- Godot/Forge headless editor import/export emits resource/ObjectDB warnings on shutdown. Standalone runtime tests still show two ObjectDB instances and one resource at exit. No critical startup or gameplay script error was present in the final regression; cleanup warnings remain unresolved.
- Windows App Control blocked the older exported console launcher. Current desktop source play uses the official Godot runtime through Launch LittleGod.cmd. No bypass was attempted.
- Broad biome zones remain generated from the existing model; phase two improves their rendered transitions, not the underlying climate model. Six species share a simplified ecological model. Technology and progression content remain limited to the existing milestone.
- Sprite motion uses independent breathing, bobbing, travel and rain poses rather than full hand-painted directional frame animation. Canopy/building occlusion is improved with depth ordering but can still overlap dense groups. A 70-creature stress scene is deliberately more crowded than the initial world.
- Saves still have one current planet and one backup. New-planet creation replaces that slot after its warning; multi-slot saves and future-version migration remain roadmap work. Existing version-one saves are normalized and their continued evolution is regression-tested.
- Offline progression remains a protected compression of time: one tick per real minute, capped at 480 ticks. It is deliberately not an exact replay of live seconds.
- MCP works through the local standard SDK bridge and editor add-on. The current Codex session still has no dynamically registered native Godot tool namespace; a later session can load the registered server normally.
- No iOS binary or store-ready build exists. The Android APK is debug-signed and no payments, backend, telemetry or publishing are enabled.

Historical phase-one issues, including the old four-Hz terrain cache and font-glyph controls, are archived in docs/archive/PHASE1_KNOWN_ISSUES.md. They should not be mistaken for the current renderer.
