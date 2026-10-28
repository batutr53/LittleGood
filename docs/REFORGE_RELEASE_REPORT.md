# Project Reforge — verified intermediate checkpoint, not release complete

## Implemented

* LibreKO systems checkpoint `2d44211`: data-driven existing skills, explicit
  target validation before cost, timer recovery, reviewed upgrade transactions,
  actual target goals/material tracking and reservation hardening.
* Runtime freeze diagnosis: generic menu gate stopped the home economy during
  Arin conversation; no SceneTree pause was involved.
* Explicit NPC-dialogue clock context uses the existing main simulation.
  Production, gathering travel and construction continue during conversation;
  unrelated player input remains gated. Settings/user pause/visit/expedition/
  suspension/caravan policies remain distinct.
* Functional original Arin at the existing settlement, native world click,
  portrait-led bottom dialogue, existing next-step routes and actual chapter
  reward command. Original art reused; no new campaign quests or identities.
* Desktop + real emulator production tests, native Android X, private save
  force-stop/relaunch, source backup, screenshots and documentation.

## Workstream ledger

| Stream | Actual status / next requirement |
|---|---|
| R1 Audit/freeze | History, STATUS/issues, runtime, baseline, regressions and backup done. Full audio audition, chat and every gameplay scene audit pending. |
| R2 Continuity | Core Arin freeze corrected and desktop/emulator verified. Additional NPC roles and physical OEM interruption certification pending. |
| R3 Hero-centered world | One real adviser anchor exists. Controllable home hero, approach radius, other NPC roles and gate travel integration pending. |
| R4 Guidance | Existing real next-step advice plus combat target-goal join retained. Full coordinator/journal/acceptance/navigation/return journey pending. |
| R5 Mobile HUD | Arin dialogue works at requested compact portrait sizes. Main HUD, menus, safe areas, density and orientation conversion pending. |
| R6 Dialogue/chat | Arin dialogue improved. Full conversation graphs, separated logs/social chat and keyboard handling pending. No live multiplayer claim. |
| R7 Inventory | Existing functioning inventory remains. Reforge full-screen readable inventory/progression pass pending. |
| R8 Combat | Validated target/cost/cooldown improvements. Full animation/contact pipeline, hitbox debug frames and native complete hunt journey pending. |
| R9 Art | Original Arin reused, no new copied game art. Unified directional art/NPC/environment production pending. |
| R10 Audio | Source and five PCM measurements recorded. Listening, buses, mixes, replacements and output comparisons pending. |
| R11 Android | R2 emulator checks, native close and process restart pass. Full portrait journeys, keyboard/multitouch/device certification pending. |
| R12 Release | **Not ready.** No final Reforge tag, no 0.9/1.0 tag, no public deployment. |

See `REFORGE_ANDROID_QA.md` for exact tests/metrics. 72 new continuity checks and
13 emulator + 3 restart checks passed. These checks do not establish that a new
human can understand or enjoy the whole game. Five-person pilot is prepared in
`REFORGE_USABILITY_TEST_PLAN.md`; it has not occurred.

## Artifacts

Launcher: `D:/LittleGod/Launch LittleGod.cmd`.
Intermediate APK: `D:/LittleGod/builds/android/LittleGod-Reforge-R2-debug.apk`.
Backup source archive: `D:/LittleGod/builds/backups/LittleGod-pre-reforge-2d44211.zip`.
Reports: `D:/LittleGod/docs/benchmarks/reforge/`.
Before/after: `D:/LittleGod/docs/REFORGE_BEFORE_AFTER.md`.

The production build, player progress and prior APKs are kept intact. New
physical-phone testing did not occur because the owner disconnected the phone.
The current main HUD remains landscape; forcing portrait before rebuilding its
controls would not satisfy the requested user experience. R3/R4/R5 are the next
implementation slices. This checkpoint is not the full requested overhaul.
