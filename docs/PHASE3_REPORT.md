# LittleGod 0.3 — living-world gameplay report

This milestone continues checkpoint `3b04cab`; the project, artwork, six species/biomes, six powers, local saves, localization and Android pipeline were retained. It adds four living chapters and individual relationships, rather than a separate game or a static presentation.

## Opening and player loop

The 0.2 rendered opening had an attractive island but a generic hint, interchangeable animals and passive species reveals. The new chapter button offers an immediately actionable rain gift, a named neighbor, wildlife welcomed at camp, then a blessing for the community. It focuses the relevant target and moves the camera smoothly. Rain keeps the whole planet visible. Successful gifts return to inspection, reducing accidental repeat casts. A visible 1×/3× state helps players choose their session pace.

In the recorded MCP input playthrough, rain produced a meadow on tick 1; meeting Luma revealed its explorer trait; Fern formed a food-sharing friendship with Amber Haven; blessing helped that community reach village stage. The journal recorded all four living chapters, including Tansy's lantern grove. These are simulation results: screenshots and MCP logs were taken from the running Godot scene. The headless integration test also executes this same care loop through the scene's actual input handlers.

For a short visit, players can give rain, meet a neighbor and welcome wildlife, with a friendship after four nearby simulation visits. A blessed starting camp can reach 12 people within roughly two minutes at 1×, or sooner at 3×. Longer visits include village/town growth, community expansion, habitat editing, meeting individuals and managing the conditions for groves and meadows. There are no streaks, loss-of-reward countdowns, notifications, purchases, forced advertisements or absence multipliers. Discoveries replenish 8 spirit and award 12 XP once; meeting a new individual awards 2 XP once. Existing power costs, spirit regeneration and the sky-theme unlock remain.

## Systemic personality and discoveries

Every animal receives a persistent identity, seed-derived name and one of four traits. Gardeners restore vegetation on their current cell; friendly animals approach nearby communities and share real food; explorers can migrate outside their native biome; patient animals consume less effective food through reduced hunger. Births and wildlife gifts receive fresh identities. Selection and motion follow identity when the population array changes. The neighbor album returns the camera to a living individual; it does not grant repeated observation rewards.

Communities receive permanent names and customs: orchard keepers cultivate their home cell, riverfolk gather extra food in rain, and stargazers advance technology under clear skies. Friendly wildlife within two cells contributes food; four visits create a persistent friendship and a visible heart. Wildlife summoned directly at a settlement is welcoming/friendly, making the opening interaction predictable without charging for failed attempts to roll a trait. This remains linked to hunger, movement, vegetation and real community food.

| Chapter | Actual trigger | State and visual consequence |
|---|---|---|
| Desert meadow | Rain, desert moisture ≥ .55, plants ≥ .45 | One cell becomes permanent grassland with full vegetation and rendered flowers; repeat transformations have a 90-tick ecological cooldown |
| Friendship | Friendly individual visits a community four times within two cells | Shared food, visitor count, named friend identity, heart and named history entry |
| Lantern grove | Content fox, hunger < .25, forest vegetation > .85, at the 45th tick of a 90-tick cycle | Forest resources +12, animated fireflies for 35 ticks; conditions must still hold on later cycles |
| First village | Actual settlement stage reaches village | More homes/walkers in the existing renderer, named chapter and progression reward |

Four permanent chapter records preserve the original named subjects even when the bounded general event history rolls over. Existing species discoveries still work; observation can reveal a species immediately. No chapter is generated solely as flavor text. Optional version-one save fields migrate on load; legacy ecology/RNG/cell state is retained. Terraforming removes obsolete meadow/grove visuals. Newly founded communities receive usable identities in their founding tick.

Offline progression runs the same event rules, still bounded to 480 ticks over eight hours at one tick per real minute. Return summaries now show measured creature/population/community changes and newly discovered chapters, followed by actual recorded events. There is no new penalty for returning late. This compressed simulation is not a literal replay of live seconds.

## Visual work and assets

The existing painted atlas, licensed fonts, audio, shaders and icon set remain intact. No new paid service, image-generation call or replacement concept art was used in this phase. New graphics are inexpensive original procedural flowers, fireflies, friendship hearts, selection names and event rings in the real renderer. Settlement clearings now account for tall foreground props; the camp is larger, and wildlife has local spacing around a home. Final screenshot review caught intermittent missing sprite-based power icons; these now use native GUI texture controls. Individual names, traits, chapter guidance, journal, album and return summaries support English and Turkish; proper names are shared between languages.

Real gameplay evidence is under `docs/screenshots/`: `phase3-before.png`, `phase3-neighbor.png`, `phase3-friendship.png`, `phase3-village.png`, `phase3-discoveries.png`, `phase3-extended.png`, `phase3-neighbors.png`, and `phase3-journal-tr.png`. The extended image uses accelerated real simulation to tick 450 (15 minutes of normal live simulation), not a 15-minute uninterrupted human playtest. `devtools/phase3-final-visual.json` also checks all icons after the accelerated care loop. Camera/menu icons use the documented native [Godot Button icon API](https://docs.godotengine.org/en/stable/classes/class_button.html); power icons sit above button backgrounds as GUI siblings. Computer Use separately inspected the native game window. Developer playtesting cannot establish that new players will enjoy or revisit the game; external first-time player testing remains necessary.

## Performance evidence

Movement now builds one coordinate index per tick and looks up four neighbors instead of scanning every cell for each moving animal. Shared terrain corners/colors are computed once per rebuild. Topology gifts and biome transformations refresh promptly; slow vegetation tint refreshes every eight simulation ticks. Prop caches are no longer forcibly discarded after every gift. No simulation tick or original test was removed to improve the measurements.

| Environment | FPS | Frame p95 | Duration |
|---|---:|---:|---:|
| Windows smooth | 60.05 | 18.33 ms | 15 s |
| Android emulator, later APK validation | 57.89 | 20.69 ms | 30 s |
| Android emulator smooth, isolated repeat | 58.02 | 20.00 ms | 30 s |
| Android emulator battery saver | 29.56 | 35.12 ms | 30 s |
| Android emulator, 70 individuals | 52.99 | 23.61 ms | 12 s |
| Android emulator blank control | 57.62 | 18.86 ms | 12 s |

Normal Android simulation averaged .669 ms/tick, peak .863 ms, versus the 0.2 measurement of .950/1.254 ms. Its last terrain build cost 6.624 ms, versus 17.408 ms; 3 rebuilds occurred in 30 seconds, versus 15 previously. Desktop last-build cost was 4.987 ms, 2 builds in 15 seconds, simulation .546 ms/tick. The final original/extended test logs record the simulation throughput separately from rendering FPS.

The later APK validation measured .757 ms average simulation, 1.298 ms peak, 6.677 ms last terrain build, 139 draw calls, 45.97/35.99 MB static/video memory, and 2.039 s to the first engine frame. Save bytes were unchanged. Another intermediate post-export validation reached 50.04 FPS / 23.05 ms p95 with a 5.002 s first frame and 310 ms peak process time; its JSON is also retained. These iterations reinforce the startup-variance limitation rather than establishing a guaranteed cold-start time. The final capacity guard additionally rejects wildlife gifts at 70 creatures without charging spirit or changing a different creature's trait; its regression check passes.

Normal Android used 138 current/169 peak draw calls, 45.95 MB reported static memory and 35.99 MB video memory. Battery saver used 94 calls, 41.87/22.97 MB. The 70-individual case used 158 calls and 1.102 ms average simulation cost (1.545 ms peak). The atlas remains 1024×1024; effects are bounded and reduced in battery saver. These engine memory counters do not represent total Android process RSS.

Startup and frame variance remain material. An initial smooth run measured 39.04 FPS / 47.80 ms p95 / 4.684 s first engine frame, and a repeat measured 56.36 FPS / 22.04 ms. A separate invisible project runtime was found and stopped before the isolated 58.02 FPS run. Warm-up and host contention may both contribute; this is not a controlled proof of either cause. The isolated first engine frame was 2.031 s, versus 2.486 s in the prior phase's run; cached startup comparisons are not a certified cold-start improvement. Peak Android process time still reached 107 ms in smooth mode and 84 ms in saver. The 70-creature FPS result is below the prior milestone's short stress run despite cheaper simulation. We do not claim stable 60 FPS under all conditions or sustained mid-range phone performance.

Only API-35 x86_64 `LittleGod_Test` / `emulator-5554`, backed by an NVIDIA laptop GPU, was available. No physical Android device was connected. Profile scripts compare the player's save bytes before/after and all completed profiles reported unchanged saves. Blank-control pacing also varies. Full metrics, including the slower runs, are retained under `docs/benchmarks/phase3/` and `builds/phase3/`.

## Verification and delivery

The original 51 checks, scene-clock integration check and 15 phase-two checks are preserved. The phase-three suite adds trait behavior, reproducible identities, one-time observation rewards, positive/negative rare-event triggers, food-sharing relationships, all chapters, save migration/round-trips, malformed extensions, offline events/return deltas, final-offline-tick village discovery, immediate founder identity, full guided care loop, album selection and identity tracking. Exact current totals and logs are in `docs/TEST_REPORT.md`.

Android package `org.littlegod.livinguniverse` versionCode 3 / versionName 0.3.0 exports to `D:\LittleGod\builds\android\LittleGod-0.3-debug.apk`. Signature schemes v2/v3, update installation and startup are validated through the SDK tools/emulator. ARM64 and x86_64 remain enabled, min API 24/target 36, Internet permission disabled. It is a debug build, with no store publication or system-security changes. Desktop source play uses `D:\LittleGod\Launch LittleGod.cmd` and the verified runtime `D:\LittleGod\tools\godot\Godot_v4.7.2-stable_win64.exe`.

Source delivery: `D:\LittleGod\builds\LittleGod-0.3-source.zip`. Git release checkpoint is tagged `littlegod-0.3`; the delivery message supplies its commit hash. Remaining limitations include four-chapter content depth, simple technology/ecology, one save slot, dense sprite overlap, startup spikes, shutdown resource/ObjectDB warnings, and absent physical-device/haptic/thermal validation. See `KNOWN_ISSUES.md`.

The six-hour return scenario (`devtools/phase3-return.json`) produced four new chapters, eight additional creatures, 43 additional people and one new community through actual offline ticks. Its real Turkish return screen is `docs/screenshots/phase3-return.png`. Final APK startup was separately checked with a short three-second validation, not used as an FPS benchmark; `final-startup.json` confirms Android startup, simulation and unchanged save bytes. The actual full-height Android capture is `docs/screenshots/phase3-android.png`. This inspection also exposed a safe-area overlap between the population line and chapter button; both the chapter and spirit row now follow the top safe inset.
