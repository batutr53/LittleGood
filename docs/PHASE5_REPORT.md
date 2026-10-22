# LittleGod 0.5 — living-world release report

The project was continued in place. Phase four was incomplete when this brief arrived; resilient persistence, loading, onboarding, diagnostics and mobile QA were finished first and checkpointed as **2542db7 / littlegod-0.4**. That release's APK/source archive remain available. Phase five extends LivingStories, the current journal/UI, powers and simulation rather than creating a parallel game.

## Implemented gameplay

Creatures retain stable identities, individual names and four simulation-affecting traits. They now record their explored places, time first recorded, preferred species habitat, companions and rivals. Repeated co-location of well-fed members of the same species creates companionship and a hunger benefit. Hungry mossbuns recognize co-located foxes and avoid their occupied destinations when alternatives exist. First birth, individual exploration and recorded survival create real history. Migrated animals receive a first-recorded date, not an invented birth date.

Villages with sufficient food and technology construct visible cultural landmarks. Existing orchard, riverfolk and stargazer customs now also support recurring harvest, water-conservation and learning traditions. Nearby prosperous villages form symmetric learning alliances. A community recovering from a recorded dry spell creates a recovery memory and harvest benefit. Landmarks use the existing painted atlas plus animated banners.

Three secrets have testable conditions and physical consequences: a raised mountain beside a wet, lush forest creates a spring that moistens the neighboring forest; a patient fox with 360 healthy forest ticks during a lantern night becomes a silver guardian and nourishes plants; a wetland bird after rain clears, from tick 60 onward, restores vegetation and starts a temporary rainbow choir. The fox retains the painted silhouette through an original silver shader. The journal gives understandable clues. No reward streak, countdown, monetization or notification was added.

The illustrated **Planet Chronicle** stores location, tick, named subject, identity/species, biome and vegetation snapshot data. Cards focus the real recorded location. It preserves permanent firsts, rare discoveries and community milestones while rotating older individual episodes, with 64 memory cards / 128 deduplication IDs. The existing recent-activity log remains accessible. These are illustrated state records, not historical screenshot reconstructions.

**Look closer** exposes a selected creature's recorded history, habitat and relationships or a community's culture/timeline. Creatures and communities can be renamed with Turkish characters. Up to five favorite locations can be marked and revisited. Existing unlocked planet themes remain available. Naming does not change identity or rewrite the original names in historical records.

The return experience prioritizes actual rare events and community milestones, then other recent histories, with illustrated camera-linked highlights. Actual absence duration is displayed separately from the protected offline cap. A seven-day return still simulates only 480 ticks; it does not impose seven days of consumption. The captured seven-day report uses accelerated seeded simulation, not an actual week-long wait.

Postcards hide controls and capture the real animated viewport with planet name/day/memory count. A preview precedes a native Save PNG dialog. Android API 35's system picker was exercised and a 1080×2400 PNG was retrieved and visually inspected before the resolution adjustment; the final Android capture also writes a verified 720×1600 PNG. No save or diagnostic file is attached; no account, upload or direct-send integration exists. Users can share their exported picture themselves.

## Validation and corrections

All **206 automated checks pass**: 51 core, 1 runtime, 15 phase two, 49 phase three, 40 phase four and 50 phase five. Existing assertions were retained. New checks cover relationships, culture, rare triggers, memory retention/rotation, offline highlights, names/favorites, PNG writing, compatibility and the actual window Back signal. Version-one fixtures from phases one, two, three and four load; the 0.4 fixture was generated using source taken from its checkpoint.

Forty seeded balance scenarios complete with valid worlds, successful transactional saves and matching restored histories. See [balance evidence](GAMEPLAY_BALANCE.md). These are automated simulations, not evidence of enjoyment or human retention.

Real Godot MCP play included first-gift guidance, observation, wildlife interaction, extended evolution, a mountain/forest experiment, Chronicle/details, postcards, English/Turkish and return summaries. Screenshots were inspected and the rename control was moved into immediate reach. Rare fox timing was adjusted after measured over-frequency. Final MCP gameplay error queries were empty. One temporary MCP snippet initially had mixed indentation; its automation code was corrected and rerun. The native Windows Computer Use helper could list windows but failed activation twice with `foreground window did not report a process id`; final visual validation used Godot MCP.

The isolated Android QA package passed **17 additional automated checks**: blank QA storage, creation form, save, actual ADB pan/zoom-button/power taps, checkpoints, home/kill/reopen, actual Android Back, engine-level synthetic two-finger events, postcard writing and 30/60 quality settings. The pinch test is not physical multi-touch verification. The extended test found Godot's default `quit_on_go_back` was still enabled; the release disables auto-quit and handles the actual window signal. The disposable QA ID alone is cleared; the player package is updated in place and profile runs compare its save bytes.

## Performance and limits

See [current status](STATUS.md) and versioned JSON under `docs/benchmarks/phase5` for final measured FPS/frame-time/startup results, including slower runs. A lazy spatial index removed work from worlds with no raised mountains: headless 480-tick offline work measured 294.81 ms before and 212.05 ms after in two samples. This is a directional sample, not a controlled hardware benchmark. Frame-sliced replay peaked at 4.41 ms per slice / 828.13 ms overall in the latter sample. Additional stories cost more CPU than 0.4's 161.40 ms synchronous sample; slicing keeps the interface responsive. Generation was .678 ms, verified save 9.896 ms and parse 2.218 ms; headless readings exclude GPU upload.

All artwork, six biomes/species, settlements, powers, settings, saves and previous regression checks are retained. New art is procedural animation and one shader, with existing atlas illustrations. There are no new raster texture allocations or paid asset/API calls.

Long-term economy/content depth remains limited: four communities reach their population caps in hour-long scenarios and food is abundant. Native crash stacks, direct native social sharing, physical-device thermal/battery testing, and external 10–20-person beta feedback remain outstanding. No real retention or human-fun claim is made. See [known issues](KNOWN_ISSUES.md) and [beta plan](BETA_TEST_PLAN.md).

Release paths: `D:\LittleGod\Launch LittleGod.cmd`; verified runtime `D:\LittleGod\tools\godot\Godot_v4.7.2-stable_win64.exe`; APK `D:\LittleGod\builds\android\LittleGod-0.5-debug.apk`; Windows export `D:\LittleGod\builds\windows\LittleGod.exe`; source archive `D:\LittleGod\builds\LittleGod-0.5-source.zip`. Desktop play uses the official runtime; Windows App Control was never bypassed. The successful source checkpoint is tagged `littlegod-0.5`. Nothing was published.

A final regression check ensures discovery celebrations still fire when the Chronicle is full. Android now renders the 720-wide composition in both modes, retaining full effects at 60-FPS cap in smooth mode. The final measured smooth/saver/stress results are in STATUS.md; Android 60 FPS remains a known unmet target.
