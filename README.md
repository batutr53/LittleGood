# LittleGod — Your Living Universe

A playable offline Godot 4.7.2 game, now at **0.8.5-devA — First Kingdom**, with an optional locally tested online universe. This is the verified first vertical slice of Age of Kingdoms, not the completed expansion. Create a named, seeded floating planet, meet individual creatures, influence habitats and communities, collect illustrated memories and visit friends' published worlds.

## Play

Run `Launch LittleGod.cmd` to play the current source through the verified Godot runtime. The current Android debug package is **`builds/android/LittleGod-0.8.5-milestone-A-debug.apk`**. Previous milestone builds remain under `builds/`. Windows App Control blocked the older exported console launcher, so no security settings were changed or bypassed. These are development builds, not store releases.

Open ☰ → First Kingdom to meet Elder Arin and opt into the five-quest campaign. Tap objectives for the actual location/build preview; gather timber, finish a lumber camp and farm, assign named citizens, build housing and raise the first council hall. Keep one citizen free for construction. Menus pause simulation; close them to watch workers produce. Claim each verified reward to unlock the next goal. Resource production, housing, upgrades, relocation and bounded offline work use the existing world. Stardust and your wardrobe remain separate. Levels 6–30, adventure combat and armies are pending; see `docs/PHASE085_REPORT.md` for the exact continuation checkpoint.

Phase two adds painted creature and environment sprites, connected terrain with blended biome colors and flowing water, evolving village art, illustrated discoveries, consistent icons/fonts, smoother camera gestures, haptics support, ambient rain, and a battery-saver option. Read `docs/STATUS.md` for actual desktop/Android measurements, screenshots, tests, and remaining limits.

Click **Create a planet**, enter a name and optional seed, then **Let there be life**. The chapter button guides a first rain gift, meeting a creature, welcoming wildlife at camp, and blessing the growing community. Drag the island to pan. Scroll, pinch, or use +/− to zoom. Choose a gift and touch a tile. Blessing requires a settlement tile. A successful gift returns to inspection; touch a creature to learn its name and trait. Spirit regenerates; every gift shows its cost.

Open ☰ for your illustrated creature collection, illustrated Planet Chronicle, favorite places, postcard capture, saving, loading, discoveries and settings. Select a creature or place and use **Look closer** to rename a creature/community, read its history or mark a location. Chronicle cards revisit the actual event location. Postcards use a native Save dialog and never upload. Settings switches English/Türkçe and sound. Space pauses on desktop; Escape and Android Back navigate menus. The speed button shows the current 1× or 3× rate. ◎ centers the view.

Worlds autosave every 30 active seconds, when suspended, and on normal exit. One current planet and a recovery backup are retained. Creating a new planet replaces the current save. Returning after a minute advances a bounded offline simulation and shows real recorded changes.

Local universe opens from the title or planet menu. Review a planet profile, export `.lgplanet` data, import a shared example from `docs/examples`, compare discoveries and visit without editing either world. Reactions stay on this device. You can save a postcard/JSON and share it manually. Favorite individual creatures in the collection, read their family/origin and follow optional **Wonders to look for**. These have real simulation conditions and no calendar deadline.

## Source and verification

Open `project.godot` in the locally installed editor at `tools/godot/Godot_v4.7.2-stable_win64.exe`. `tests/suite.gd` runs with Godot headless and covers generation, simulation, powers, saves, corruption recovery, and offline progression. See `docs/TEST_REPORT.md` for actual results and `docs/KNOWN_ISSUES.md` for limits.

Online universe is optional. Run `Launch Online Server.cmd` for the local ASP.NET Core/PostgreSQL service, then set the connection in the game's online menu: desktop `http://127.0.0.1:5087`, Android emulator `http://10.0.2.2:5087`. Create a private username/password identity, choose profile visibility, and explicitly publish a reviewed public snapshot. Share your exact invitation code, accept a friend, visit their published planet and send a friendly reaction. Offline creation and saves need no account or server. See `docs/ONLINE_ARCHITECTURE.md` for setup, migrations, Compose and limits. No public hosting is configured; Docker Desktop failed here, so native PostgreSQL supplies actual test evidence.

This is a closed beta candidate. Long-term content depth and enjoyment still need human testing. Optional diagnostics stay locally, can be previewed/cleared/disabled and never upload. Live payments are disabled. No external analytics, public deployment or store publication is configured. Online visits are read-only snapshots, not real-time multiplayer. OAuth/email recovery and public-hosting security/operational prerequisites remain pending.

All game art, vector assets, shader code, synthesized audio, and game source were created for this project. Godot Forge is an MIT-licensed third-party editor integration. License details: `docs/ASSET_INVENTORY.md`.

Open ☰ → Atelier & collection to browse earned Stardust cosmetics, previews, requirements and favorites. Flowers/stones are available immediately. Browse atelier unlocks with explicit confirmation; Decorate planet lets you preview, place, move, face, store and undo/redo up to 32 pieces. Drag/pinch still navigate. Creature profiles open individual wardrobes. Themes, skies and frames change presentation only. Future premium content is explicitly unavailable.

The updated API executable and final .NET test assembly were blocked by Windows App Control on this host. Do not bypass it. The game remains playable offline; current v2 online publishing requires verification on an authorized runtime. See docs/PHASE8_REPORT.md for exact tests, performance, screenshots and limitations.
