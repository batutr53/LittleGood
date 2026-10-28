# Şehir ve macera birlikte — 28 October 2026

Players can develop their city and take a hero into combat from their first day. City level/chapter progression no longer gates character, inventory, stats, skills, Wildwood, Iron Hills, Ashen Desert or Sunken Sanctuary access in live player worlds. Heroes still need a weapon; destination levels describe danger, rather than an entry requirement. The Wildwood guardian's chapter-14 barrier is also removed for migrated worlds.

## Player flow

1. Start a planet, or Continue an existing save. The live creation/restore path applies the versioned `parallel_play` migration.
2. Open **Karakter / Çanta / Beceri / Stat** immediately. Four existing classes are available. A missing first hero receives one starter weapon without charging recruitment food/gold or granting chapter rewards.
3. Use **Boss / Av → Bölgeyi incele / gir** or the existing region map. All four adventure destinations are available; choose risk and preparation freely.
4. Fight, earn real XP and pick up actual drops. City building construction, assigned production, forge queues and gathering workers advance through the existing city simulation while the hero fights.
5. **Dön** banks collected cargo with the existing return rules. Collect buffered city products at home. Each worker retains a single assignment; no second city simulation or duplicate loot award is introduced.

Explicit pause, combat pause, a full combat overlay and application suspension stop the live city clock. Existing bounded offline progression can advance the city from a migrated active-adventure save, while combat/monster state stays unchanged. Existing item/production capacity limits remain. Army missions, crafting tiers, hero XP/stat progression and quest rewards retain their own progression; this change removes city progression as a prerequisite for personally adventuring.

## Save handling

The additive extension is `{version:1, starter_granted:bool}`. Existing hero ID/name/XP/HP, equipped item IDs, queues, worker assignments, resources and chapter history are preserved. Migration is idempotent and refuses read-only visited worlds. An armed existing hero gets no replacement item. A full bag does not consume an unsuccessful one-time starter grant. No city chapter is fabricated. Legacy snapshots still validate under their original rules; only live creation/restore explicitly upgrades them. The first offline replay of an unmigrated historical expedition retains its previous freeze policy; subsequent migrated saves use the new policy.

Regional state is initialized safely when visiting desert or sanctuary before their former city chapters. Save validation accepts the new early access while retaining run IDs, inventories, quest-state consistency and duplicate-ownership checks. City and combat share the same save/checkpoints; long hunts also retain the 30-second autosave cadence.

## Verification actually performed

| Suite | Passing checks |
| --- | ---: |
| Existing campaign chain, unchanged tests | 822 |
| Existing native-mouse navigation | 61 |
| Existing collection / worker / input hotfix | 26 / 24 / 65 |
| New parallel-play simulation, migration, offline and real combat | 67 |
| New rendered first-day UI, mouse buttons and joystick | 27 |
| Android emulator, external ADB taps | 16 |
| Android fresh-process save restore | 3 |

The new-world tests grant no city chapters, XP or arbitrary balances. The combat test walks through collision/path rules, fights a live wolf with normal AI/damage, earns XP, picks up generated drops and verifies exact cargo delivery once. Production tests also use a separate documented legacy fixture with a real assigned forge worker and existing craft queue. No existing checks were weakened.

Godot render inspection: first-day bag, hunts and combat at **960×540 / 1600×720**, plus actual Android emulator screenshots. The UI test initially used a Control method on the Node2D joystick; the harness was corrected and the final 27-check run has no script errors. Existing ObjectDB/resource cleanup warnings still occur on desktop test shutdown. Android had one transient ADB offline read, recovered by its bounded retry; final result has zero script errors/fatal exceptions.

Android: isolated QA package installed on `emulator-5554`, version code **109**, six external ADB taps: bag, hunts, destination, enter, skill, return. Fresh-process restore preserves the private save bytes. Both QA and main packages' `planet.json`, `.bak` and `settings.cfg` snapshots were preserved. Main-package APK was exported and its manifest checked, but not installed over the player's app. No physical device was connected. No stable-FPS, battery or physical-device certification is claimed.

Evidence: [benchmarks/parallel](benchmarks/parallel), [screenshots/parallel](screenshots/parallel). Reproduce desktop: verified Godot `--headless --path . --script tests/parallel_play.gd`, then rendered `--path . --script tests/parallel_play_ui.gd`. Android: `python -X utf8 devtools/android_parallel_validate.py` with the QA APK present.

## Launchers and builds

- Desktop: `D:/LittleGod/Launch LittleGod.cmd`
- Verified runtime: `D:/LittleGod/tools/godot/Godot_v4.7.2-stable_win64.exe`
- Main APK: `D:/LittleGod/builds/android/LittleGod-Parallel-debug.apk`
- Isolated QA APK: `D:/LittleGod/builds/android/LittleGod-Parallel-QA-debug.apk`
- Package manifests/checksums: `docs/benchmarks/parallel/main-apk.json`, `qa-apk.json` and `main-manifest.txt`.

## Remaining limits

This is the city/adventure access change, not completion of the entire Reforge roadmap. Finite dungeon content, existing army unlocks, equipment/crafting progression, old dense building overlaps and overall art/animation limitations remain. Render inspection also shows flat background beyond the adventure map's edges, especially on wide views. Live window resizing requires re-entering combat to rebuild its fixed-layout HUD; tested landscape launch sizes fit the main action/return controls. Portrait overhaul and physical-device performance work remain separate.
