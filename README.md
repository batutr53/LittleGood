# LittleGod — Your Living Universe

A playable offline Godot 4.7.2 game, now at **LittleGod 0.3**. Create a named, seeded floating planet, meet individual creatures, grow friendships between wildlife and communities, discover flowering meadows and lantern groves, and watch camps become towns.

## Play

Run `Launch LittleGod.cmd` to play the current source through the verified Godot runtime. The current Android debug package is **`builds/android/LittleGod-0.3-debug.apk`**. Previous milestone builds remain under `builds/`. Windows App Control blocked the older exported console launcher, so no security settings were changed or bypassed. These are development builds, not store releases.

Phase two adds painted creature and environment sprites, connected terrain with blended biome colors and flowing water, evolving village art, illustrated discoveries, consistent icons/fonts, smoother camera gestures, haptics support, ambient rain, and a battery-saver option. Read `docs/STATUS.md` for actual desktop/Android measurements, screenshots, tests, and remaining limits.

Click **Create a planet**, enter a name and optional seed, then **Let there be life**. The chapter button guides a first rain gift, meeting a creature, welcoming wildlife at camp, and blessing the growing community. Drag the island to pan. Scroll, pinch, or use +/− to zoom. Choose a gift and touch a tile. Blessing requires a settlement tile. A successful gift returns to inspection; touch a creature to learn its name and trait. Spirit regenerates; every gift shows its cost.

Open ☰ for your neighbor album, saving, loading, discoveries, world history, milestones, settings, pause, or another world. The album can find individual creatures again. Settings switches English/Türkçe and sound. Space pauses on desktop; Escape opens the menu. The speed button shows the current 1× or 3× rate. ◎ centers the view.

Worlds autosave every 30 active seconds, when suspended, and on normal exit. One current planet and a recovery backup are retained. Creating a new planet replaces the current save. Returning after a minute advances a bounded offline simulation and shows real recorded changes.

## Source and verification

Open `project.godot` in the locally installed editor at `tools/godot/Godot_v4.7.2-stable_win64.exe`. `tests/suite.gd` runs with Godot headless and covers generation, simulation, powers, saves, corruption recovery, and offline progression. See `docs/TEST_REPORT.md` for actual results and `docs/KNOWN_ISSUES.md` for limits.

This is an early playable milestone, not the complete premium release described in the brief. Its systems are real, while species behaviors, art variety, achievements, and content depth still need expansion. No payment system, backend, telemetry, or publishing is present.

All game art, vector assets, shader code, synthesized audio, and game source were created for this project. Godot Forge is an MIT-licensed third-party editor integration. License details: `docs/ASSET_INVENTORY.md`.
