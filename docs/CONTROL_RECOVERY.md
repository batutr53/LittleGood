# Movement and skill-control recovery — 27 October 2026

The reported frozen character was checked through a fresh Godot launch, not a frozen screenshot fixture. In that run, holding D moved the hero from x=240 to x=420, a visible skill-button click spent mana, physics advanced and no runtime script error appeared. The original reported freeze was not reproduced in that state. The audit did find that the displayed movement stick accepted touch events only: desktop mouse dragging did nothing.

Implemented:

- The virtual stick accepts desktop mouse press/drag/release as well as existing mobile touch. Releasing or losing focus clears the mouse latch, movement and held combat input.
- A **Sürükle / WASD** label explains both control paths.
- Pausing shows an explicit central **Savaşa devam et** action and warning. Resuming restores physics processing, clears stale inputs and releases the transient automated-control flag. It does not rewrite saves, grant rewards or heal the hero.
- A defeated hero has a separate **Eve dön ve iyileş** action, making the existing safe-return recovery explicit.
- Inventory/skill windows still intentionally pause combat; closing the overlay restores its previous state. Boss / Av and all navigation remain intact.

Actual Godot MCP mouse drag moved x=240→321 and released to zero movement. A visible skill click reduced mana to approximately 93 (regeneration remained active). The new `tests/control_recovery.gd` uses viewport mouse input, live simulation and touch events: **14 checks pass** for movement, release, skill, pause, recovery from disabled processing/automated input, menu switching and save validity. Existing **61 navigation**, **46 battle-loop** and **98 compact-HUD** and **66 targeting** checks were rerun and pass. Evidence: `docs/benchmarks/controls/`. Historical reports remain preserved.

Android build: `D:/LittleGod/builds/android/LittleGod-Controls-debug.apk`, isolated QA package, version **102**. Desktop launcher: `D:/LittleGod/Launch LittleGod.cmd`; verified runtime: `D:/LittleGod/tools/godot/Godot_v4.7.2-stable_win64_console.exe`. Installation/rendered combat validation and production-save hashes are recorded in the Android report. Android emulator: **26 combat/navigation checks** pass, no script errors, production files preserved. No physical Android device is claimed.

This addresses a concrete missing desktop input path and adds visible recovery controls. It does not establish that every possible freeze cause has been reproduced or eliminated. Existing shutdown resource warnings remain.

The incoming-attack warning test now samples an active fight before restoring its screenshot freeze; paused play correctly shows the pause message instead. Screenshot output directories are created by the Android validator so a new artifact folder does not interrupt collection.
