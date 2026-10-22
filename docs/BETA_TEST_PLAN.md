# Closed beta — 10–20 invited testers

Current candidate: **LittleGod 0.5**, `D:\LittleGod\builds\android\LittleGod-0.5-debug.apk`. Keep 0.4 and its evidence for comparison; test the final 0.5 candidate for new feedback. Split the invited group across newer/mid-range/older phones and sandbox newcomers/experienced players. Record actual hardware separately from emulator automation.

No external testers have been recruited or measured. Human enjoyment, clarity and next-day/seven-day return rates remain unknown. Invite testers manually; do not upload local diagnostics automatically.

Install the supplied debug APK on Android API 24+. Keep the existing app installed when updating to preserve its private save. A fresh uninstall removes that save. Open LittleGod, create a named planet and follow the first gift and creature guidance. Source desktop testing uses `D:\LittleGod\Launch LittleGod.cmd` and the verified bundled Godot runtime.

Observe the first two minutes without coaching: can the tester create a world, cast a gift, find a named creature and explain its consequence? At five minutes ask them to explore a habitat and community. At fifteen minutes ask what they care about and what they would change. Ask them to return voluntarily the next day and after seven days; no reminders or rewards are built into the game.

Questionnaire: What did you try first? What surprised you? Which creature or place do you remember? Was any action unclear? Did you understand the return report? What made you stop? Would you choose to return, and why? Rate clarity, touch comfort and visual enjoyment separately; preserve free-text criticism.

Phase-five tasks: find a companion or favorite creature; give it a personal name; mark and revisit a place; interpret a cultural landmark; follow a secret's clue; revisit a Chronicle card; preview and export a postcard without help. Observe whether these tasks strengthen attachment or create menu friction. Do not explain trigger rules unless the tester has already become stuck; record the point of confusion.

Device checklist: portrait and tall aspect ratios, cutouts/safe areas, text size and Turkish/English, pan, true two-finger pinch, selecting creatures, each gift, keyboard/name entry, Android back, battery saver, sound/haptics, home/resume, screen lock, process kill after background, save/restore and update installation. Record OS, model and reproduction steps only with tester consent. Thermal/battery-life tests require physical hardware.

Bug template: version; device/OS; expected and actual result; exact steps; occurrence rate; whether saved world is affected; optional screenshot; optional manually reviewed diagnostic export. Do not request personal identifiers or the player's save unnecessarily.

Beta tools show the optional local event export before copying it. Export only if the tester chooses; they can disable/clear diagnostics independently of the world. Fixed codes support tutorial completion, session duration, first power/creature/community and restore counts. Unclean-session markers are hints, not native crash stacks. Return frequency and next-day/seven-day cohorts require consent-based tester records; no retention results have been inferred from automated simulations.

The 0.5 export also includes fixed `power_used`, `memory_found` and relative UTC `return_day` events. The absolute first UTC day stays private and is not exported. Use completed `session_ended` durations, count `session_started` for frequency and `return_day` values 1/7 for this installation's next-day/seven-day visits. The bounded 200-event log is a recent window, not an all-time counter or a cohort retention denominator. A clear/reset starts a new local record. Separate `source=simulated` from actual player exports. Ask for consent before linking a tester's voluntary export to their questionnaire; no persistent user ID or external analytics is present.

Android 10+ native postcard saving was verified on the API 35 emulator. Test native picker cancellation, file overwrite and export on physical OEM devices; older Android versions need special attention. A user may share the exported PNG through their own file/gallery app. No sending action is automated.

Release gate: all regression checks pass, installation/update and save compatibility verified, no critical runtime errors. Recruit real testers and complete physical-device checks before broader distribution. No store publishing is authorized.
