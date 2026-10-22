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
| `world_view.gd` | Isometric projection, cached terrain, animated wildlife, weather and interaction feedback |
| `interface.gd` | Portrait touch controls, menus, inspection, encyclopedia, history, settings, localization |
| `soundscape.gd` | Local synthesized sounds, ambient wind, mute preference |
| `tests/suite.gd` | Deterministic and integration checks, stress simulation, persistence recovery |

World state is JSON-safe data; rendering does not own simulation decisions. Random-generator state is serialized as a decimal string to retain all 64 bits across JSON parsing. Floating-point fields are checked with tolerances in round-trip tests. Simulation work is tick based and independent of frame rate.

Terrain is drawn into a transparent 1024×1024 SubViewport, refreshed at 4 Hz or immediately after ticks/gifts. A single cached texture replaces most per-frame terrain calls. Creatures, smoke, selections, particles, and rain remain in the foreground. This trades exact canopy occlusion for readable moving wildlife. A coordinate lookup replaces repeated whole-dictionary comparisons.

Save files live in Godot's platform-specific `user://` directory. On Windows this is normally `%APPDATA%/Godot/app_userdata/LittleGod — Your Living Universe/`. A SHA-256 envelope detects accidental corruption, not malicious tampering. A flushed temporary file replaces the current save and preserves one `.bak` file. Invalid primary data falls back to the backup. Settings are a separate ConfigFile.

## Future optional services

The offline game should remain authoritative locally. A later ASP.NET Core API could authenticate through a standard OIDC provider, store account and save metadata in PostgreSQL, and store versioned save blobs separately. Upload only after explicit cloud-save opt-in. Use TLS, short-lived access tokens, ownership checks, request limits, schema validation, and per-save revisions. Resolve conflicts through explicit player selection of labeled snapshots; do not silently overwrite a unique planet. Shared planets and leaderboards need separate validated endpoints and abuse controls. None of these services are implemented or needed for this milestone.
