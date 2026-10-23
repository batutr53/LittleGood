# Closed beta — LittleGod 0.8 customization candidate

Current package: `D:/LittleGod/builds/android/LittleGod-0.8-debug.apk`; source launcher `D:/LittleGod/Launch LittleGod.cmd`. Update the existing player package with install -r; never clear/uninstall it to test an update. Keep a private backup before a downgrade. No physical phone or human participant was available in this run.

Use CUSTOMIZATION_FEEDBACK.md for the optional 10–20-person test. Allocate two minutes for uncoached first use and 10–15 minutes for decorating, inventory/shop comprehension, creature attachment, theme preference and local sharing. Include portrait devices with different notches/scales, mid-range hardware, actual two-finger pinch, haptic/audio and accessibility checks. Record measured results, including criticism, without turning opinions into validated demand or retention statistics. No recruitment, notifications or sharing with others was performed.

The offline customization loop and export/visit fallback work without a server. Online v2 cosmetics and prepared purchase endpoints need a new live integration run on an authorized machine: Windows App Control blocked the updated API and .NET test assembly here. Do not bypass it. Preserve the last verified 0.7 evidence; do not expose local development services to external testers. Live payments remain disabled.

## Retained gameplay/online scenarios from 0.7

Online testing is currently local-only. Follow ONLINE_ARCHITECTURE.md to run the real API/PostgreSQL stack, configure desktop/emulator addresses, then use two independent test accounts: explicitly publish a friends-only snapshot, request/accept friendship, visit/inspect/return, send a reaction and inspect real activity. Test public opt-in, profile and planet privacy separately, block/unpublish/account deletion, and turn off the API while keeping the local world usable. Do not expose the development service to external testers; authorized TLS hosting/security/operations remain prerequisites. Report keyboard, accessibility and device findings separately from the scripted client/API checks.

No external testers have been recruited or measured. Human enjoyment, clarity and next-day/seven-day return rates remain unknown. Invite testers manually; do not upload local diagnostics automatically.

Install the supplied debug APK on Android API 24+. Keep the existing app installed when updating to preserve its private save. A fresh uninstall removes that save. Open LittleGod, create a named planet and follow the first gift and creature guidance. Source desktop testing uses `D:\LittleGod\Launch LittleGod.cmd` and the verified bundled Godot runtime.

Observe the first two minutes without coaching: can the tester create a world, cast a gift, find a named creature and explain its consequence? At five minutes ask them to explore a habitat and community. At fifteen minutes ask what they care about and what they would change. Ask them to return voluntarily the next day and after seven days; no reminders or rewards are built into the game.

Questionnaire: What did you try first? What surprised you? Which creature or place do you remember? Was any action unclear? Did you understand the return report? What made you stop? Would you choose to return, and why? Rate clarity, touch comfort and visual enjoyment separately; preserve free-text criticism.

Phase-five tasks: find a companion or favorite creature; give it a personal name; mark and revisit a place; interpret a cultural landmark; follow a secret's clue; revisit a Chronicle card; preview and export a postcard without help. Observe whether these tasks strengthen attachment or create menu friction. Do not explain trigger rules unless the tester has already become stuck; record the point of confusion.

Device checklist: portrait and tall aspect ratios, cutouts/safe areas, text size and Turkish/English, pan, true two-finger pinch, selecting creatures, each gift, keyboard/name entry, Android back, battery saver, sound/haptics, home/resume, screen lock, process kill after background, save/restore and update installation. Record OS, model and reproduction steps only with tester consent. Thermal/battery-life tests require physical hardware.

Bug template: version; device/OS; expected and actual result; exact steps; occurrence rate; whether saved world is affected; optional screenshot; optional manually reviewed diagnostic export. Do not request personal identifiers or the player's save unnecessarily.

Beta tools show the optional local event export before copying it. Export only if the tester chooses; they can disable/clear diagnostics independently of the world. Fixed codes support tutorial completion, session duration, first power/creature/community and restore counts. Unclean-session markers are hints, not native crash stacks. Return frequency and next-day/seven-day cohorts require consent-based tester records; no retention results have been inferred from automated simulations.

The 0.6 export also includes fixed `power_used`, `memory_found` and relative UTC `return_day` events. The absolute first UTC day stays private and is not exported. Use completed `session_ended` durations, count `session_started` for frequency and `return_day` values 1/7 for this installation's next-day/seven-day visits. The bounded 200-event log is a recent window, not an all-time counter or a cohort retention denominator. A clear/reset starts a new local record. Separate `source=simulated` from actual player exports. Ask for consent before linking a tester's voluntary export to their questionnaire; no persistent user ID or external analytics is present.

Android 10+ native postcard saving was verified on the API 35 emulator. Test native picker cancellation, file overwrite and export on physical OEM devices; older Android versions need special attention. A user may share the exported PNG through their own file/gallery app. No sending action is automated.

Release gate: all regression checks pass, installation/update and save compatibility verified, no critical runtime errors. Recruit real testers and complete physical-device checks before broader distribution. No store publishing is authorized.

## Phase six scenarios

Copy a source-package example .lgplanet from docs/examples to the phone Download folder using your usual file transfer. Use the Local universe from the main menu or planet menu. Export your profile to .lgplanet, cancel and retry the picker, import docs/examples/Lumi.lgplanet or Nacre.lgplanet, compare discoveries and visit. Pan, zoom, inspect communities/creatures and Chronicle; confirm no editing powers appear. Try background/resume during a visit, then Return to my world and verify your own planet and camera. Reactions are explicitly local; ask the tester to explain that limitation. Fill/remove a local copy and reject a malformed or oversized file without touching a save. Review public names before exporting.

Favorite a creature, read its family/origin and personal history, follow a Wonders opportunity and revisit a discovered location. Watch a wetland migration, gardener canopy, bird/grazer shelter or actual food trade when conditions permit; do not promise they occur on a calendar. Note whether uncertainty feels interesting or unclear. Existing rain bloom and community onboarding should remain immediate. Use BETA_FEEDBACK_FORM.md for voluntary feedback.

Current automated evidence: 280 regression checks, 40 seeded longer simulations and separate Android QA. These are functional evidence only. There are still zero recruited human testers and zero physical-device results. The release remains a debug beta candidate.
