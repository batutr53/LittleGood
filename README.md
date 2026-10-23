# LittleGod — Your Living Universe

A playable offline Godot 4.7.2 game, now at **LittleGod 0.6**. Create a named, seeded floating planet, meet individual creatures, influence habitats and communities, collect illustrated memories and make a postcard of your world.

## Play

Run `Launch LittleGod.cmd` to play the current source through the verified Godot runtime. The current Android debug package is **`builds/android/LittleGod-0.6-debug.apk`**. Previous milestone builds remain under `builds/`. Windows App Control blocked the older exported console launcher, so no security settings were changed or bypassed. These are development builds, not store releases.

Phase two adds painted creature and environment sprites, connected terrain with blended biome colors and flowing water, evolving village art, illustrated discoveries, consistent icons/fonts, smoother camera gestures, haptics support, ambient rain, and a battery-saver option. Read `docs/STATUS.md` for actual desktop/Android measurements, screenshots, tests, and remaining limits.

Click **Create a planet**, enter a name and optional seed, then **Let there be life**. The chapter button guides a first rain gift, meeting a creature, welcoming wildlife at camp, and blessing the growing community. Drag the island to pan. Scroll, pinch, or use +/− to zoom. Choose a gift and touch a tile. Blessing requires a settlement tile. A successful gift returns to inspection; touch a creature to learn its name and trait. Spirit regenerates; every gift shows its cost.

Open ☰ for your illustrated creature collection, illustrated Planet Chronicle, favorite places, postcard capture, saving, loading, discoveries and settings. Select a creature or place and use **Look closer** to rename a creature/community, read its history or mark a location. Chronicle cards revisit the actual event location. Postcards use a native Save dialog and never upload. Settings switches English/Türkçe and sound. Space pauses on desktop; Escape and Android Back navigate menus. The speed button shows the current 1× or 3× rate. ◎ centers the view.

Worlds autosave every 30 active seconds, when suspended, and on normal exit. One current planet and a recovery backup are retained. Creating a new planet replaces the current save. Returning after a minute advances a bounded offline simulation and shows real recorded changes.

Local universe opens from the title or planet menu. Review a planet profile, export `.lgplanet` data, import a shared example from `docs/examples`, compare discoveries and visit without editing either world. Reactions stay on this device. You can save a postcard/JSON and share it manually. Favorite individual creatures in the collection, read their family/origin and follow optional **Wonders to look for**. These have real simulation conditions and no calendar deadline.

## Source and verification

Open `project.godot` in the locally installed editor at `tools/godot/Godot_v4.7.2-stable_win64.exe`. `tests/suite.gd` runs with Godot headless and covers generation, simulation, powers, saves, corruption recovery, and offline progression. See `docs/TEST_REPORT.md` for actual results and `docs/KNOWN_ISSUES.md` for limits.

This is a closed beta candidate. Long-term content depth and enjoyment still need human testing. Optional diagnostics stay locally, can be previewed/cleared/disabled and never upload. No payment system, multiplayer backend, external analytics or publishing is present.

All game art, vector assets, shader code, synthesized audio, and game source were created for this project. Godot Forge is an MIT-licensed third-party editor integration. License details: `docs/ASSET_INVENTORY.md`.
