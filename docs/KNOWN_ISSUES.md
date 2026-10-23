# Known issues —0.8.5-devE2B

- E2A and E2B are the verified partial checkpoint. Ashen Desert, its oasis/three enemies/poison/material consumer and quest22 remain unimplemented. Realm progression is1–21; the desert card is explicitly unavailable. No E3 or later work was started.
- Mountain deposits and enemies are finite and have no respawn in this checkpoint. The two nodes yield6 ore/5 stone; enemy loot is bounded. Clear warehouse space at home if a pickup cannot fit. Repeatable outpost production is outside E2B.
- Adventure uses the compact original C hero controller and camera. Mountain collisions and new enemy behavior are real, but this is not a large seamless/open-world navigation system. No new boss or ancient relic quest exists.
- Android verification is emulator-only. The connected physical phone was unauthorized during this run. Long-lived emulator/host graphics sessions can degrade sharply; short60/30-cap samples do not establish phone thermals, battery, haptics or simultaneous multitouch. Active-encounter samples are brief.
- Headless/editor/export ObjectDB/resource cleanup warnings remain. Emulator restart may log a cached-shader recompile warning. Logs are retained; no new script parse/runtime errors or failed game assertions are accepted.
- Existing32-slot/four-job inventory and military/trade limits remain. Staffed-forge/merchant salvage protects gear, artifacts and reserved kits. Trade prices/quotes/reservations are unchanged; future route price changes still need explicit migration.
- Home/industry/caravan/offline simulation freezes during any active adventure or army battle. E1 Live Route Watch intentionally advances home ticks while watching and restores the previous pause on exit. Menus otherwise pause work.
- Native Computer Use was unavailable. Actual Godot rendering, MCP inspection and ADB controls were used. Automated tests do not establish human beta enjoyment or long-term balance.
- Existing API/.NET App Control blockage remains untouched; purchases stay disabled. No security bypass, paid service, store release, public deployment or external messaging occurred. Older milestone reports and builds remain.
