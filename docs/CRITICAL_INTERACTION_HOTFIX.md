# Critical interaction hotfix — 28 October 2026

This is a focused fix to the existing game, not completion of Project Reforge.
No new levels, campaign quests, engine replacement, save version or economic
balance changes were introduced. Player identities, resources, worker duties,
crafting jobs, caravan/military state and prior build artifacts are preserved.

## Root causes and fixes

| Reported problem | Actual evidence | Implemented fix |
|---|---|---|
| Collect appears ineffective | Farm collection already transferred a small amount because food was almost full. Remaining pending output/actual capacity were invisible. Empty results were all called storage full. | Show real ready/stored amounts, distinguish full/running/empty/unavailable, preserve residual products, visible panel-safe success/failure notice and storage/inventory management routes. Harden item/resource transfer guards. |
| Assign worker appears ineffective | Native click assigned Eren but no visible confirmation appeared and menu policy prevented production while the panel stayed open. | Named quick assignment/removal with eligibility reasons, real count/rate refresh, immediate checkpoint and visible worker-name feedback. Reserved/busy duties cannot silently duplicate. |
| Panel blocks other world objects | All menus triggered `blocks_world`, main input return and home-clock return. Transparent veil alone was not the cause. | Explicit home-world inspector context: real panel bounds block input; exposed world can pan/select; another object replaces the inspector, empty world dismisses it; actual clock continues. True modals and NPC dialogue keep distinct policies. |

Details: [collection](PRODUCTION_COLLECTION_FIX.md),
[worker assignment](WORKER_ASSIGNMENT_FIX.md),
[input routing](WORLD_INPUT_ROUTING.md).

## Verified paths

* Desktop real mouse: farm output → Collect → exact settlement-food transfer →
  repeat click → no duplicate. Visible feedback shows partial transfer and
  remaining output. Invalid/full results keep pending output.
* Desktop real mouse: building → staffing → Eren → actual mine assignment →
  named success → Remove. Model tests additionally confirm actual ore output,
  stopped contribution, valid transfer and population conservation.
* Desktop exposed-object taps: Mine→Farm→Forge→Barracks→Marketplace→Mine→Farm.
  Same window count, correct selected contour/ID, no click-through from controls,
  empty-world dismissal and blocked world beneath upgrade confirmation.
* Android external ADB taps repeat Collect/double Collect, open roster,
  assign/remove, Mine/Farm/Forge/Barracks switching, modal outside tap, empty
  world, English Collect and compact portrait Collect/close. No internal
  callback invocation is represented as an Android tap.
* A real unpaused Android inspector allows the existing wall clock to create
  ore after assignment. Paused deterministic collection checks use actual
  model output from legal ticks, not arbitrary injected demonstration products.
* Force-stop and reopen in a new Android process restores the exact private
  save bytes and economic state; six actual production/QA player files remain
  unchanged. No physical phone was connected.

The old dense fixture hides the forge behind other roofs. Private tests expose
it via the real free move command; player buildings are not automatically moved.
A failed Android boundary-coordinate run is preserved separately, not counted
as a pass. Stable visible interiors account for physical/logical pixel rounding.

## Tests

| Checks | Result |
|---|---|
| Existing campaign | 822 passed |
| Landscape UI / compact HUD | 270 / 98 passed |
| Playbook / journey | 142 / 224 passed |
| Object selection / native navigation | 97 / 61 passed |
| Colony model / rendered UI | 94 / 100 passed |
| Estate / battle | 44 / 46 passed |
| Reforge continuity / LibreKO systems | 72 / 120 passed |
| New collection / workers / native mouse integration | 26 / 24 / 65 passed |
| Android native integration | 33 passed; 14 external ADB actions |
| Android new-process restore | 3 passed, unchanged private save bytes |

Counts are per suite and can overlap; they are not independent proofs of fun or
the entire Reforge specification. Existing tests were retained. New guards also
make stale freed button callbacks harmless through WeakRef rather than invoking
an action on a destroyed panel.

Evidence: `docs/benchmarks/hotfix/`; actual renders:
`docs/screenshots/hotfix/`. `native-mouse.txt` and Android log record command IDs,
selected worker/building, validation, actual collection result and world taps.
The QA configuration/private files are debug-only triggers, not player rewards.

## Builds and launch

* Desktop launcher: `D:/LittleGod/Launch LittleGod.cmd` (existing verified Godot
  4.7.2 runtime; no path/security changes needed).
* Main-package artifact: `D:/LittleGod/builds/android/LittleGod-Critical-Hotfix-debug.apk`.
* Installed/tested isolated artifact: `D:/LittleGod/builds/android/LittleGod-Critical-Hotfix-QA-debug.apk`.
* Both version code 108. Main package `org.littlegod.livinguniverse`, QA package
  `org.littlegod.livinguniverse.rpgqa`; manifest/package checked with Android
  `aapt`. Export preset restored byte-for-byte. Main package was exported and
  inspected without replacing the player's installed production app.
* Source archive: `D:/LittleGod/builds/android/LittleGod-Critical-Hotfix-source.zip`.

Reproduce:

```
Godot_v4.7.2-stable_win64_console.exe --path D:/LittleGod --script tests/hotfix_input.gd
python -X utf8 devtools/android_hotfix_validate.py
```

The Android script records every external tap, tests restart, preserves player
files and uses private QA slots. Compact portrait orientation is a **test-only**
override; the production game's main HUD retains the existing landscape layout.

## Remaining limitations

* Dense legacy building overlap can hide a structure behind a visible roof;
  existing move/layout tools remain available. Alpha hit selection does not
  select a building hidden behind another opaque building.
* Food still caps at 100; ordinary storage capacity and 32-item reservations are
  unchanged. Historical over-capacity stock is preserved, so pending output may
  require spending stock or upgrading/building storage before it can transfer.
* User pause, settings, expedition and caravan clock rules remain deliberate.
  Ordinary inspection no longer pauses by itself.
* Old landscape HUD typography/composition is not the full portrait Reforge
  redesign. Physical dp, OEM safe areas and physical-device behavior are not
  certified. No stable FPS improvement is claimed by this interaction hotfix.
* Existing Godot shutdown ObjectDB/resource warnings remain. Inspected final
  QA logs have no script errors. Prior failed/transient runs are retained as
  diagnostic evidence, not successful verification.

Checkpoints: A `6a59eb3`, B `fc0682c`, C `0b8d86b`; D includes integration,
artifacts and reports. The dedicated critical-hotfix tag is created only after
the final verified integration; no 0.9/1.0/Reforge completion tag is created.
