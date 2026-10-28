# Reforge clock ownership — R2 core

`main.gd.home_clock_running()` owns permission for the existing home simulation.
The original two-second accumulator, `advance_tick`, kingdom/industry/colony
updates, autosave and bounded offline progression remain the authoritative path.

| Context | Home economy | Player/world input |
|---|---|---|
| Home, no menu, unpaused | Existing clock runs | Existing home controls |
| Arin conversation, unpaused | Same clock runs | Menu gate blocks unrelated world interaction |
| Arin while user explicitly paused | Stops | Close X preserves pause; explicitly labeled Resume action resumes |
| Ordinary management/settings menu | Existing menu pause retained | Menu controls |
| Adventure / army scene | Home paused under existing expedition policy | Scene-specific rules retained |
| Visit | No owned economy mutation | Existing read-only visit controls |
| App suspended/loading | No live clock advancement | Existing lifecycle gates |
| Live caravan route watch | Existing intentional exception retained | Existing watch interaction |

Opening another surface resets `npc_dialogue_open`. Closing resets the flag.
The flag is transient and is not written into world saves. Gathering travel
interpolation now consults the same clock permission; production is not awarded
by animation. Arin's marker checks current quest readiness at a bounded interval.

Verified: ten dialogue ticks produce one real gathering cycle; collection is
exact and cannot replay; repeated opening creates one window and no extra ticks;
construction completes during dialogue; explicit pause, settings, visit and
suspension gates stop the clock; save/load preserves economic state. Native
Android X clears the dialogue context. Force-stop/relaunch preserves private
save bytes and restores jobs in a new process. Other NPC roles, OEM background
interruption paths and physical-device certification remain pending.
