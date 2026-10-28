# Reforge R2 Android QA — 28 October 2026

Artifact: `D:/LittleGod/builds/android/LittleGod-Reforge-R2-debug.apk`, version
107, isolated package `org.littlegod.livinguniverse.rpgqa`. Production export
preset restored byte-for-byte; old production and QA APKs remain available.
Hashes/size: `docs/benchmarks/reforge/apk.json`.

The connected phone was removed by the owner. All new Android evidence is from
the API 35 x86_64 LittleGod_Test emulator with host GPU, not a physical phone.

**13 Android checks passed:** real wall-clock worker progression while Arin is
open, actual visual movement, ten-tick gathering cycle, exact collection, no
duplicate collection, dialogue save/load, settings pause, native ADB X closing,
state validity and private lifecycle checkpoint. The harness uses an isolated
fixture and save slot. It is not the full native onboarding journey. Existing
production planet/backup/settings files were preserved by the validator.

**Force-stop/relaunch:** three restore checks passed in a new Android process.
Private saved bytes remained unchanged, validated world/jobs loaded again.
This is actual process restart, not a same-process dictionary roundtrip.
Physical OEM suspension, calls, virtual keyboard, density/cutout and simultaneous
multitouch tests remain pending.

Final short paused-home samples (not active combat or live-NPC profiling):

| Cap | FPS | p95 frame ms | Draw calls | Texture MiB | Static MiB |
|---|---:|---:|---:|---:|---:|
| 60 | 29.42 | 40.46 | 378 | 49.41 | 49.76 |
| Battery 30 | 30.11 | 35.36 | 297 | 49.41 | 49.56 |

ADB cold activity startup: 5,691 ms. No script errors in the inspected final
Android log. Earlier emulator samples were much slower; no controlled
performance-improvement or stable-60 claim is made. Existing desktop shutdown
ObjectDB/resource warnings remain.

The same final APK also passed the existing **26 Android battle checks**:
actual HP/MP, damage, experience, loot and combat routes. The data-driven skill
JSON is verified inside the APK. This is a rendered private-fixture regression,
not a native player completing the whole first hunt; see `combat-android.json`.

Desktop regressions: 822 campaign, 270 UI, 224 journey and 98 compact-HUD checks
passed. New 72 continuity/layout checks cover the main clock gate, mining,
construction, repeated windows, exact collection, saving, pause/suspend/visit
gates and Arin layout at six dimensions in TR/EN. Earlier systems checkpoint
adds 120 model checks plus 142 playbook/46 battle/41 class-combat/45 armory.

Run:

```
python -X utf8 devtools/android_rpg_validate.py --apk LittleGod-Reforge-R2-debug.apk --output reforge-r2-final-android --screenshots reforge --phase reforge
python -X utf8 devtools/reforge_lifecycle.py
```

This APK retains the existing **landscape main HUD**. Only Arin dialogue is
portrait-responsive so far. Global portrait orientation is deferred until the
whole HUD/menus and input routes are rebuilt and verified, rather than shipping
a forced orientation with broken controls.
