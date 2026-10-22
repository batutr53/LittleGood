# Architecture

`scenes/main.tscn` is the entry scene. `main.gd` owns world state and input, coordinates ticks and persistence, and binds the reusable world renderer and interface nodes. The atmosphere uses a separate CanvasItem shader.

| Module | Responsibility |
|---|---|
| `world_gen.gd` | Seeded terrain, climate fields, initial creatures and community |
| `biomes.gd` | Palette, growth rates, localized biome names |
| `ecosystem.gd` | Clock, seasons, weather, soil, vegetation, resources, wildlife, discoveries, achievements, history |
| `civilization.gd` | Food, population, construction stages, technology, trade, expansion |
| `powers.gd` | Costs, validation, persistent gift effects |
| `persistence.gd` | Versioned checksummed envelope, atomic replacement, backup validation, bounded offline ticks |
| `world_view.gd` | Projection, smoothed camera, selection, render coordination and effect state |
| `terrain_surface.gd` | Connected land/water/cliff meshes, blended biome colors, banks and decorations |
| `world_inhabitants.gd` | Shared-atlas sprites, depth ordering, animal behavior animation and settlement activity |
| `game_art.gd` | Shared texture atlas and foliage material |
| `world_foreground.gd` | Weather, selection rings and power effects above the world |
| `performance_probe.gd` | Explicit debug-only profiling sessions and local JSON/screenshot evidence |
| `interface.gd` | Portrait touch controls, menus, inspection, encyclopedia, history, settings, localization |
| `soundscape.gd` | Local synthesized sounds, ambient wind, mute preference |
| `tests/suite.gd` | Deterministic and integration checks, stress simulation, persistence recovery |

World state is JSON-safe data; rendering does not own simulation decisions. Random-generator state is serialized as a decimal string to retain all 64 bits across JSON parsing. Floating-point fields are checked with tolerances in round-trip tests. Simulation work is tick based and independent of frame rate.

Phase two removes the repeatedly redrawn offscreen SubViewport. Three retained meshes represent land/cliffs, water and ground details; shared vertex positions make the land continuous, and vertex colors blend adjacent land biomes. Water glints and foliage sway run in lightweight shaders. Terrain geometry rebuilds on simulation ticks or gifts, rather than four times per second. Painted props, houses, villagers and creatures share one 1024×1024 atlas and use depth ordering. Species-specific idle motion, grazing pauses, travel, wing-like body movement and rain shelter poses are visual behavior linked to existing habitat/hunger/weather state.

The camera separates target pan/zoom from displayed transforms with frame-rate-independent interpolation. Pinch zoom preserves its world anchor, moves with its centroid and suppresses accidental power taps on release. Simulation uses bounded monotonic elapsed time, preserving the intended two-second tick at low frame rates; menus/suspension reset the clock appropriately. Battery saver caps at 30 FPS, reduces decorative effects, disables foliage sway, and renders a smaller internal viewport on mobile. Portrait layouts expand to tall screens rather than adding black bars.

Version-one saves remain supported. After checksum/schema validation, integer fields from JSON are normalized before simulation. This fixes a phase-one bug where a restored float clock reached integer modulo operations. Optional tile `last_gift` metadata guarantees a visible planted tree or raised peak, without changing power costs or ecological rules.

Save files live in Godot's platform-specific `user://` directory. On Windows this is normally `%APPDATA%/Godot/app_userdata/LittleGod — Your Living Universe/`. A SHA-256 envelope detects accidental corruption, not malicious tampering. A flushed temporary file replaces the current save and preserves one `.bak` file. Invalid primary data falls back to the backup. Settings are a separate ConfigFile.

## Future optional services

The offline game should remain authoritative locally. A later ASP.NET Core API could authenticate through a standard OIDC provider, store account and save metadata in PostgreSQL, and store versioned save blobs separately. Upload only after explicit cloud-save opt-in. Use TLS, short-lived access tokens, ownership checks, request limits, schema validation, and per-save revisions. Resolve conflicts through explicit player selection of labeled snapshots; do not silently overwrite a unique planet. Shared planets and leaderboards need separate validated endpoints and abuse controls. None of these services are implemented or needed for this milestone.
