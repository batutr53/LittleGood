# Known issues and limits

This is an early playable checkpoint, not a premium launch build.

- Physical Android device testing, thermal/battery profiling, multi-touch pinch validation, iOS compilation, accessibility testing, and extended mobile resume/crash testing remain. Desktop mouse interaction and emulator taps are separate evidence from physical touch testing.
- Terrain currently uses broad biome zones with seeded variation, not fully climate-derived biome assignment. Transition edges are visible. The island is a small floating diorama rather than a spherical planet.
- Six species have distinct habitats, visual silhouettes, movement and hunger but share a compact behavior model. Fox pressure is simplified, not a complete predator/prey simulation. Technology is recorded but has limited gameplay impact.
- Current progression contains six discoveries, two milestones and one cosmetic sky unlock. More achievements, narrative events, cosmetic content, unique buildings, species animation assets and audio variety are needed.
- Cached terrain updates at 4 Hz; moving creatures and effects update every frame. Creatures render in a foreground layer, so canopy occlusion is approximate. Cache refreshes can still create occasional slower frames. No claim of stable 60 FPS on phones is made.
- UI symbols rely on available font glyphs; some appear as colored emoji. A consistent icon atlas, dedicated branded splash and stronger transitions remain. Godot's engine splash still appears on Android.
- Saves retain one current world and one recovery backup. Creating a new planet replaces the current slot after the creation screen warning. Version one is validated; migrations from future versions and multiple slots are not implemented.
- Offline simulation deliberately compresses time (one tick per real minute, maximum 480 ticks) and protects population minima. It does not reproduce every second of live gameplay.
- Godot Forge is installed from source because its requested npm package was unavailable. The native tool list in the current Codex session did not refresh; standard MCP SDK clients verified the live integration. Restarting/reopening a Codex session may be required for native namespace availability.
- Headless editor import/export with the Forge plugin emits ObjectDB/resource-in-use shutdown warnings, even when export succeeds and package signatures verify. Standalone capture occasionally emits two ObjectDB instance warnings on automatic exit. No startup or gameplay exception was reported in the desktop regression. These cleanup warnings should be isolated before a production release.
- Initial Android emulator SwiftShader mode exposed a Godot OpenGL uniform-limit shader error. The dedicated test emulator was switched to host GPU mode; unused 3D light limits were also reduced. Physical GPU coverage remains necessary.

No store release, iOS binary, cloud service, payment integration, or production readiness is claimed.
