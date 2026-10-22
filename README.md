# LittleGod — Your Living Universe

A playable offline Godot 4.7.2 game checkpoint. Create a named, seeded floating planet; nurture six habitats and six original species; watch camps become towns; shape the ecosystem with six guardian gifts.

## Play

Run `builds/windows/LittleGod.exe` or `Launch LittleGod.cmd`. The Android debug package is `builds/android/LittleGod-debug.apk`. Both are generated locally, without purchases or online services. The Android build is a development build, not a store release.

Click **Create a planet**, enter a name and optional seed, then **Let there be life**. Drag the island to pan. Scroll, pinch, or use +/− to zoom. Choose a gift and touch a tile. Blessing requires a settlement tile. With no gift selected, touch a tile to inspect its creatures, settlement, or soil. Tap the selected gift again to return to inspection. Spirit regenerates; every gift shows its cost.

Open ☰ for saving, loading, discoveries, world history, milestones, settings, pause, or another world. Settings switches English/Türkçe and sound. Space pauses on desktop; Escape opens the menu. 1×/3× adjusts simulation speed. ◎ centers the view.

Worlds autosave every 30 active seconds, when suspended, and on normal exit. One current planet and a recovery backup are retained. Creating a new planet replaces the current save. Returning after a minute advances a bounded offline simulation and shows real recorded changes.

## Source and verification

Open `project.godot` in the locally installed editor at `tools/godot/Godot_v4.7.2-stable_win64.exe`. `tests/suite.gd` runs with Godot headless and covers generation, simulation, powers, saves, corruption recovery, and offline progression. See `docs/TEST_REPORT.md` for actual results and `docs/KNOWN_ISSUES.md` for limits.

This is an early playable milestone, not the complete premium release described in the brief. Its systems are real, while species behaviors, art variety, achievements, and content depth still need expansion. No payment system, backend, telemetry, or publishing is present.

All game art, vector assets, shader code, synthesized audio, and game source were created for this project. Godot Forge is an MIT-licensed third-party editor integration. License details: `docs/ASSET_INVENTORY.md`.
