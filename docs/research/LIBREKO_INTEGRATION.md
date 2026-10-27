# LibreKO integration checkpoint — 28 October 2026

## Downloaded sources

All three unique URLs supplied by the user are downloaded locally. Repeated URLs
refer to the same checkout. Snapshots include the tracked files at the following
revisions, rather than the full historical Git history:

| Repository | Pinned revision | Local directory | Tracked files |
|---|---|---|---:|
| [LibreKO](https://github.com/ZeusAFK/LibreKO) | e5f0e4200fd42f69934f55557f92f2ee2ccfafde | D:/LittleGod/builds/research/LibreKO | 6,143 |
| [LibreKO-Assets](https://github.com/ZeusAFK/LibreKO-Assets) | b44cf9ddf5c3c0b703db0db5d7fe505b582cab66 | D:/LittleGod/builds/research/LibreKO-Assets | 120 |
| [LibreKO-vscode](https://github.com/ZeusAFK/LibreKO-vscode) | 4c4597a3a6a150755a7020d82a88a7ff6b78b1d3 | D:/LittleGod/builds/research/LibreKO-vscode | 14 |

Inventory records file counts, bytes, extensions, source revisions and license
hashes in `docs/benchmarks/libreko/sources.json`. Downloaded code stays outside
Godot imports and Android exports under the existing ignored `builds/` folder.
All three upstream projects declare AGPL-3.0. No upstream server or extension
was installed or run. This is targeted inspection, not a complete audit of all
6,277 source files or a claim that their tests passed.

## What is actually available

[LibreKO README](https://github.com/ZeusAFK/LibreKO/blob/e5f0e4200fd42f69934f55557f92f2ee2ccfafde/README.md):
C#/.NET 10 server and Godot 4.7.2 .NET client, server-owned seed tables and quest
scripts, original background art, interface SVGs and minimap previews. Its 3D
rigs, geometry, monster textures and animation effects are generated separately.

[LibreKO-Assets README](https://github.com/ZeusAFK/LibreKO-Assets/blob/b44cf9ddf5c3c0b703db0db5d7fe505b582cab66/README.md):
offline Python decoders/bakers for an **installed** KO client containing Data,
Zones and DTex. Outputs include glTF, PNG, heightmaps, terrain splats, table JSON,
skill presentation and sound. The asset repository contains **no PNG, SVG or
glTF art pack**. Its committed shine JSON is data, not a bundle of visual effects.
Server gameplay numbers are not supplied by decoding skill presentation.

[VS Code extension](https://github.com/ZeusAFK/LibreKO-vscode/blob/4c4597a3a6a150755a7020d82a88a7ff6b78b1d3/README.md):
quest grammar, language-server integration and contextual ID-to-name hints. It
does not add gameplay or convert LittleGod's existing JSON/GDScript quests.
Not installed into the user's editor because LittleGod does not use that DSL.

## Implemented in the running LittleGod game

* Eight unchanged upstream SVGs: bag, user, scroll, hammer, users-three, sliders,
  pin and combat-defence. Theme mappings connect character, inventory, quests,
  construction, people, menu, regions and shield icons. Navigation uses the
  existing gold/cream palette and keeps current routes, labels and target sizes.
* Editable SVG sources, full AGPL license and provenance NOTICE are included in
  `assets/third_party/libreko/`. Both license and NOTICE are `.txt` files covered
  by the Android export include filter. No proprietary client conversion output
  is distributed and the project has not been wholesale relicensed.
* Normal weapon +7/+8/+9/+10 now have four distinct glow strengths. Existing
  reverse tiers +1/+5/+11/+21 retain their strengths. Reference:
  [ItemShine](https://github.com/ZeusAFK/LibreKO/blob/e5f0e4200fd42f69934f55557f92f2ee2ccfafde/Client/src/Fx/ItemShine.cs).
* Simulation-accepted attacks emit short-lived 2D trails. Fire has rising
  strokes, frost a crystal glint, lightning a zigzag, poison droplets. Main
  melee arcs use the actual equipped weapon's element. Rejected cooldown input
  does not emit an attack trail. A profile snapshot prevents subsequent weapon
  changes from recoloring a trail already emitted.
* Trails are bounded to six, or two in battery mode; segments and fire strokes
  are reduced in battery mode. Reduced-motion mode narrows the sweep and removes
  rising fire strokes. Idle unenhanced equipment stops requesting FX redraws.
  No particle nodes, new bitmap textures, combat-stat changes or save fields.
* Effects are independently implemented for LittleGod's existing 2D actor
  presentation. They are not a port of LibreKO's skeleton/bone-based 3D trails.

## Repeatable source/asset tooling

`python -X utf8 devtools/libreko_sources.py --fetch`

Downloads missing pinned snapshots and checks existing ones without resetting
local changes. Inventory rejects an unexpected revision or dirty checkout.

`python -X utf8 builds/research/LibreKO-Assets/bake.py --list`

This was executed successfully to verify the upstream pipeline entry point.
For a separately available installed KO client:

```
python -X utf8 devtools/libreko_sources.py --ko "D:/Games/KnightOnline" --only items --dry-run
```

The example path is illustrative, not an installation found or baked here.
The bridge validates required folders, joins the pinned server seed data and
limits output to `builds/external-assets/LibreKO`. Omitting `--dry-run` executes
the upstream offline baker. A full bake requires the upstream Python packages
and substantial output space. Output does not silently replace runtime assets.
No installed KO client's characters, models or skill effects were baked in this
checkpoint. Other unrelated game projects on D: were left untouched.

## Next adaptation candidates, still pending

1. Target-aware quest/material indicators. Upstream `TargetQuestDrops` joins
   active quest collection requirements to actual monster drop tables; adapt to
   LittleGod's real contracts and colony needs rather than inventing rates.
2. Review upgrade recipes, probability/settings tables and transactional server
   validation. Keep LittleGod's documented non-destructive failure behavior;
   do not overwrite player economy or rates with unrelated server data.
3. Data-driven attachments and animation events after a deliberate 3D/layered
   actor pipeline. Current illustrations do not have skeleton sockets, so 3D
   meshes and trails cannot simply be pasted into them.
4. Quest authoring validation inspired by contextual ID hints; retain current
   quest identities, stage gates and save compatibility.
5. Account/network architecture is a separate migration. Existing account
   service, saves, colony production and home/expedition rules remain in use.

## Validation and artifacts

Live inspection exposed an existing target-card error: Thornheart's localized
name is an `{en,tr}` dictionary while ordinary enemy names use arrays. The common
localization adapter now accepts both formats. Added all 12 enemy names in both
languages and an actual target-card assertion; the real Thornheart target was
then inspected in Godot MCP. Existing **97 object-selection checks** also pass.

Existing **822 campaign**, **270 UI**, **98 compact HUD**, **45 armory** and **46 armory visual** checks
passed. New **68 rendered effect/save checks** and **6 source-tooling tests**
passed. The new rendered checks cover accepted/rejected attack feedback, all
five element profiles, all normal glow levels, reverse tier boundaries,
bounded/expiring effects, presentation purity, old fixture loading, new-state
save/load, all eight imported icon routes and actual PNG output. Existing
shutdown ObjectDB/resource warnings remain.

Actual Godot MCP runtime was launched and visually inspected. Screenshots:
`docs/screenshots/libreko/` (before, inventory, five element attacks, Android
captures). Fixtures use private test saves; no player save reset.

APK: `D:/LittleGod/builds/android/LittleGod-LibreKO-debug.apk`, version code 106,
isolated package `org.littlegod.livinguniverse.rpgqa`. Launcher:
`D:/LittleGod/Launch LittleGod.cmd`. Build preset restored byte-for-byte.

Android results are recorded in `docs/benchmarks/libreko/`. The first default
software-renderer emulator run completed its 12 model checks but logged GLES
uniform-limit shader failures and very poor FPS; it is **not** a clean graphics
validation or an optimization result. A fresh host-GPU run is reported separately.
The final APK passed **14 Android checks**, including actual accepted-swing trails
and the imported bag icon. Host-GPU emulator paused-home samples were 38.30 FPS /
p95 29.14 ms at 60 cap and 30.07 FPS / p95 35.22 ms at battery 30; 373/292 draw
calls, 63.19 MiB texture memory, 59.36/59.09 MiB static memory. Cold activity
startup was 988 ms. Player files were preserved; the inspected log had no script
errors. Stable 60 FPS remains unmet. Earlier host-GPU samples were 11.64/18.05 FPS; session variability prevents attributing the final improvement to these changes.
The physical Samsung device was visible as `unauthorized` during this task;
this new APK was not installed or profiled on the phone.
