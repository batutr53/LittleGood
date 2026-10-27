# LittleGod — RPG interface checkpoint / E3 gameplay baseline

## LibreKO sources and first runtime integration — 28 October 2026

Also fixed an existing boss-target crash caused by mixed array/dictionary localized names. All 12 enemy names are covered in both languages; the actual Thornheart target card was inspected in Godot MCP. Existing **97 object-selection checks** pass.

Downloaded pinned snapshots of all three distinct supplied repositories under `D:/LittleGod/builds/research/`: LibreKO, LibreKO-Assets and LibreKO-vscode. Added revision/license/file inventories and a repeatable source/bake bridge. Imported eight real LibreKO SVG UI icons with unchanged sources, full AGPL license and provenance NOTICE included in the APK. Added distinct +7/+8/+9/+10 weapon glow tiers, element-colored melee arcs and bounded fire/frost/lightning/poison swing trails emitted only for simulation-accepted attacks. Battery mode reduces trail counts/segments; reduced motion narrows the sweep. No save schema, combat balance, quest identities or player inventory changed.

Passed: **822 existing campaign, 270 UI, 98 compact HUD, 45 armory, 46 armory visual, 68 new rendered effect/save and 6 source-tooling tests**. Actual Godot runtime/screenshots inspected. Android host-GPU emulator: **14 checks passed**, installation/startup successful, player files preserved, no script errors. Paused-home samples: **38.30 FPS / p95 29.14 ms** at 60 cap; **30.07 FPS / p95 35.22 ms** at battery 30; 373/292 draw calls, ~63.19 MiB texture memory. Stable 60 FPS remains unmet; earlier host-GPU samples were 11.64/18.05 FPS, showing substantial session variability. Initial default software-renderer run also had GLES uniform-limit shader failures; it is retained separately as failed graphics evidence. These are emulator samples, not a demonstrated optimization gain. Physical Samsung was unauthorized during this task; new phone installation/performance not verified. Existing shutdown resource warnings remain.

APK: `D:/LittleGod/builds/android/LittleGod-LibreKO-debug.apk` (isolated QA package, version 106). Launcher: `D:/LittleGod/Launch LittleGod.cmd`. Real screenshots: `docs/screenshots/libreko/`; evidence: `docs/benchmarks/libreko/`; exact scope/source links/remaining integrations: [LIBREKO_INTEGRATION.md](research/LIBREKO_INTEGRATION.md). **Full LibreKO gameplay/server/3D content is not integrated.** LibreKO-Assets is a converter requiring a separate installed KO client, not a ready character/terrain art pack; no proprietary client content was baked or distributed.

## Object selection and contextual interactions — 27 October 2026

Added sprite-shaped gold building/enemy contours, mint worker contours, green selected resource props and exclusive transient selection. Building upgrade now has current/next level, owned/required materials, source links and explicit validated confirmation. Moving begins at the original cell, keeps the original until confirmation, explains free move/cancel and returns to the moved building. Terrain offers compatible gathering at the selected real cell with explicit worker choice; original settlements and enemies have their own context panels. Enemy Inspect shows actual combat stats/XP/drop navigation and preserves combat pause state. Existing level, worker, resource, storage, range and collision rules remain authoritative.

Validation: **97 new model/rendered/native-input checks**, **24 Android emulator checks**, retained **822 campaign + 270 landscape + 98 compact HUD + 142 playbook + 224 journey + 94 colony model + 66 targeting + 61 navigation + 14 controls** pass. Separate Godot MCP clicks verified real farm upgrade and relocation cancellation; Android used a native ADB upgrade tap and preserved production player files. No physical-phone or performance improvement claim. Existing shutdown warnings, dense old-layout occlusion and some advanced scrolling remain.

APK: `D:/LittleGod/builds/android/LittleGod-Selection-debug.apk` (isolated QA package, version 105). Launcher: `D:/LittleGod/Launch LittleGod.cmd`. Report: [OBJECT_SELECTION_UX.md](OBJECT_SELECTION_UX.md); real screenshots: `docs/screenshots/selection/`; tests/build evidence: `docs/benchmarks/selection/`.

## Journey continuity, spacious settlement and compact forge — 27 October 2026

Implemented modern chapter continuation at milestones 5/10/15/20, fixed the blocked first-hero recruitment route, added Arin's state-derived next action and explicit home resume. Building staffing now opens the selected building's slots and prioritizes available workers. Replaced long forge/drop/contract lists with search, filters and pagination; recipe ingredients lead to gathering, mine/furnace management or actual monster-drop sources. Recipe availability probes the existing command on a private clone. A fresh automated founding → gathering → first reward → lumber camp → staffing → output collection → second reward loop passes. Existing axe/pick bonuses now affect field gathering; profession tool/ripple/dust cues and smoother travel are rendered. Optional reviewed settlement rearrangement spaces building art, preserves IDs/order/work/output and protects active-caravan markets; new placements reject art overlap.

Validation: **224 new model/rendered journey checks**, existing **822 campaign + 270 landscape + 98 compact HUD + 142 playbook + 100 colony UI + 61 native navigation + 14 controls + 46 armory visual** checks pass; colony model is now **94** checks including the original base-yield assertions with the fixture's tool explicitly removed. Godot MCP clicks recruited the first hero and assigned a smith through the real panel. Android **30 checks** cover missing-material rejection, actual furnace production/collection, exact crafting costs, completed order pickup, native ADB X tap and save/load. Production save/backup/settings remain preserved. No physical-device test is claimed. Shutdown resource warnings and emulator 60-FPS limitations remain.

APK: `D:/LittleGod/builds/android/LittleGod-Journey-debug.apk`, isolated QA package, version 104. Launcher: `D:/LittleGod/Launch LittleGod.cmd`. Details: [JOURNEY_AND_SETTLEMENT.md](JOURNEY_AND_SETTLEMENT.md); screenshots: `docs/screenshots/journey/`; evidence: `docs/benchmarks/journey/`. **The complete requested MMORPG scope is still in progress:** [ordered delivery ledger](DEVELOPMENT_BACKLOG.md) records pending NPC chains, directional/layered character art, full reference-item adaptation, advanced combat/economy balance, live social verification and online territory war.

## Ocakbağı colony, explicit worker duties and close buttons — 27 October 2026

Panel X now closes instead of navigating back. Production workers must explicitly release their current duty; roster labels identify building IDs, shared construction, gathering, army and caravan reservations. Replaced visible ambient pets/humans with original Hearthkin creature-worker art while preserving legacy save data privately. Added eight terrain-based gathering jobs (wood/stone/gold/copper/silver/clay/water/fish), visible travel/work phases, tappable cargo bubbles, bounded overflow-safe collection, food cooking and three material-funded fortification tiers affecting actual village-defense soldier stats. Delivered wood/stone advance existing gathering objectives. The Koloni hub connects workers, buildings, resources, defense and existing hero/boss expeditions. New-player objective opens colony founding. Main colony pages fit 960×540 / 1280×720 / 1600×720 in TR/EN without scrolling.

Validation: existing **822 campaign, 270 landscape UI, 98 compact HUD, 142 playbook, 61 native-input navigation and 14 control-recovery checks** pass. New **93 model + 100 rendered UI + 23 Android checks** pass. Godot MCP click and native Android ADB tap both confirm X closes. Android installation/startup successful; production save/backup/settings hashes unchanged; no runtime script errors in the inspected emulator log. Measured paused-home emulator: **32.35 FPS / p95 34.64 ms** at 60 cap, **30.11 FPS / p95 34.64 ms** at battery 30; 385/317 draw calls, ~45.83 MiB texture memory, ~54.73/54.59 MiB static memory. ADB cold activity startup 1,059 ms. These are emulator/paused-home samples, not physical-device or live-combat benchmarks; stable 60 FPS remains unresolved. No physical device connected.

APK: `D:/LittleGod/builds/android/LittleGod-Colony-debug.apk`, isolated QA package, version code 103. Launcher: `D:/LittleGod/Launch LittleGod.cmd`. Research, exact mechanics, compatibility and remaining work: [COLONY_WORKFORCE.md](COLONY_WORKFORCE.md). Real gameplay screenshots: `docs/screenshots/colony/`; reports: `docs/benchmarks/colony/`. Online territory PvP remains unimplemented; current local defense is playable. Dense legacy building overlap, legacy wildlife history/cosmetic references and shutdown resource warnings remain.

## Desktop stick and explicit control recovery — 27 October 2026

Fixed missing desktop mouse support on the visible movement stick; added drag/WASD guidance, central pause/resume action, explicit defeated-hero return and restoration of physics/manual input when the user resumes. Fresh real Godot keyboard, mouse drag and skill clicks work; the original reported freeze was not reproduced. New **14 live control checks**, existing **61 navigation, 46 battle and 98 compact HUD checks** pass. Details and remaining uncertainty: [CONTROL_RECOVERY.md](CONTROL_RECOVERY.md). APK: `D:/LittleGod/builds/android/LittleGod-Controls-debug.apk` (QA package, version 102). Evidence: `docs/benchmarks/controls/`.

## Action combat, real rewards and icon navigation — 27 October 2026

Connected actual hits, enemy counterattacks, HP loss/recovery, MP use, critical damage, EXP and level-up to visible effects. Added contact flashes/sparks, projectile travel, enemy anticipation/recoil, opponent-facing sprites, outlined resource/damage numbers, screen-edge damage feedback, a live EXP bar, MP readout, falling loot and exact tap-to-collect. RPG starter skill costs 8 MP; learned skills retain existing costs. Rewards and pickups stay model-owned and exactly once; collected resources bank on safe return. Full-bag, distance, low mana and potion failures are explained.

Fixed combat pause-state preservation when switching panels; pre-unlock icons now explain their requirement. Home and combat HUDs expose **Boss / Av**, region requirements, solo boss directions and separate army battles. Real viewport mouse-event tests cover correct panel opening at three horizontal sizes.

Existing **822 campaign + 270 landscape UI + 98 compact HUD + 142 playbook + 66 targeting + 41 class-combat + 14 interaction** checks pass; **46 battle-loop + 61 real-input navigation** checks added. Android emulator: **26 checks**, preserved player files, no script errors; short active melee sample **60.05 / 30.03 FPS** at 60 / battery caps. New screenshots and detailed Android results: `docs/benchmarks/battle/`, `docs/screenshots/battle/`. Full behavior, QA limitations and remaining work: [BATTLE_LOOP.md](BATTLE_LOOP.md). APK: `D:/LittleGod/builds/android/LittleGod-Battle-debug.apk` (isolated QA package, version 101). Launcher: `D:/LittleGod/Launch LittleGod.cmd`. No physical phone test claimed; shutdown resource warnings and procedural rather than skeletal animations remain.

## MMORPG target clarity, HUD materials and forest art — 27 October 2026

Implemented explicit enemy name/HP targeting, visible ground rings/pointers, range/obstruction feedback, target cycling, first-tap selection, selected-enemy ranged basics, warnings outside chat, cooldown arcs, localized action/locked/mana captions, persistent home-world context actions, selected inventory/equipment/nav feedback and stale-selection cleanup. Slate metal/gold surfaces improve contrast at the retained compact proportions. Added three original painted forest enemies (built-in image generation, transparent, imported at 512 px) and a richer original vector Wildwood floor aligned with existing collision and landmarks. Saved worlds and item ownership remain compatible.

Validation: **822 campaign, 270 landscape UI, 98 compact HUD, 142 playbook, 41 class combat and 14 RPG interaction checks** retained; **66 new rendered targeting/art checks** pass. Android emulator **13 checks** pass with production files preserved and no script errors. Short paused-home sample ~26.11 FPS at 60 cap / 30.14 at battery 30 cap; this does not establish physical performance or a controlled optimization gain. No physical device connected. Full 3D KO/MMO recreation and directional animation remain unfinished; the existing 2D systems are extended.

APK: `D:/LittleGod/builds/android/LittleGod-Targeting-debug.apk` (QA package, version 100). Launcher: `D:/LittleGod/Launch LittleGod.cmd`. Research, measurements, screenshots, exact generated assets/prompts, checks and limitations: [MMORPG_TARGETING.md](MMORPG_TARGETING.md). Evidence: `docs/benchmarks/targeting/`; screenshots: `docs/screenshots/targeting/`.

## Gameplay clarity and compact playbook — 26 October 2026

Implemented a short first-village flow, current-objective instructions and rewards, separate paginated quest history, a village directory, direct building locate/collect/upgrade/staffing, named construction workers and queue status, placement preview and invalid-site protection, paginated catalogue/worker/region/army pages, trainee/kit selection and compact formation controls. Bottom-left **Köy** and **Savaş** now lead to the real village and army; solo hero expeditions remain separate. Menus explicitly explain that work resumes after closing. Existing model commands, item ownership, saves, original art, chapter conditions and enhancement mechanics remain intact.

Verified **822 campaign + 270 landscape UI + 98 compact HUD**, **44 estate + 45 armory + 48 scroll/set** checks; **142 new rendered UX checks** cover the new-player route, real staffing/construction, no-scroll default-text screens at 960×540 / 1280×720 / 1600×720 in TR/EN, screenshots and save/load. Android emulator: **40 checks**, install/start successful, production save/backup/settings preserved. No physical phone connected. Emulator performance remains poor (8.58 FPS at 60 cap, 11.44 at battery 30 cap); this is **not** a mobile-performance completion claim. Existing shutdown resource warnings, overlapping old village layouts and scrolling in some advanced screens remain.

APK: `D:/LittleGod/builds/android/LittleGod-Playbook-debug.apk` (separate QA package, version 99). Launcher: `D:/LittleGod/Launch LittleGod.cmd`. Research, implementation, limitations, measured results and commands: [PLAYBOOK_UX.md](PLAYBOOK_UX.md). Evidence: `docs/benchmarks/playbook/`; real before/after screenshots: `docs/screenshots/playbook/`.

## Armory, item rebirth and KO Bugda research checkpoint — 26 October 2026

The existing RPG now includes normal enhancement through +10, High/Unique item reverse conversion, rebirth through +21, elemental affinity colors, increasing item glow, real combat-stat bonuses, protected ownership and serial-checked confirmations. Added 16 original painted inventory icons, eight original class weapons, class-weapon drops, searchable real-game drop tables, four one-time contracts and class-specific procedural spell overlays. Four real upgrade-scroll recipes are crafted/collected/consumed once; original class-set bonuses activate at 2/3/5 equipped pieces. Old item IDs, campaigns, growing world and saves remain intact. Research covers 13 page entries and explicitly records missing interactive data and contradictory reference percentages. **This is not completion of the requested one-to-one game recreation.** No third-party art was copied; exact KO formulas, full maps/items, layered directional animation, exact reference set values, booster scrolls and full NPC quest chains remain open.

Validation: **822 campaign, 270 landscape UI, 98 compact UI, 14 RPG interactions and 44 estate checks** retained; **45 armory model + 48 scroll/set model, 46 rendered and 12 Android checks** pass. Actual Godot MCP clicks and native Android anvil confirmation were inspected. The emulator sample remains ~26 FPS at a 60 cap / ~30 at the battery 30 cap; no physical device verified. Existing shutdown resource warnings remain.

APK: `D:/LittleGod/builds/android/LittleGod-Armory-debug.apk`; launcher: `D:/LittleGod/Launch LittleGod.cmd`. Report and exact remaining work: [ARMORY_REFERENCE_IMPLEMENTATION.md](ARMORY_REFERENCE_IMPLEMENTATION.md). Research: `docs/research/kobugda-audit.json`; evidence: `docs/benchmarks/armory/`; real screenshots: `docs/screenshots/armory/`.

## Growing world and village collection — 26 October 2026

Implemented a **1,024-tile starting world**, expandable through adjacent 64-tile parcels to **2,304 tiles**; first expansion free, later purchases use ordinary resources. Twelve original painted building sprites replace most home/industry buildings, at approximately twice the previous size. Buildings are clickable; completed construction, production and forge jobs show tappable bubbles. Collection transfers real output once, retains warehouse overflow and preserves item IDs. Added village paths, wider terrain spacing, zoom controls, fitting minimap, sparse decorations and offscreen prop visibility. Legacy save migration appends cells without reindexing old content; private buffers and public read-only v3 previews are validated.

Checks: **822 campaign + 270 landscape UI + 98 compact UI + 14 RPG interactions** retained; **44 new model/offline/save checks + 13 rendered checks + 6 Android checks** pass. Godot MCP mouse collection and native ADB land purchase were performed and inspected. Desktop sample ~**60.11 FPS**; emulator **17.77 FPS** at 60 cap / **21.33 FPS** at battery 30 cap, so mobile performance remains unresolved. No physical device tested. Android production saves/backup/settings preserved. Existing shutdown resource warnings and dense legacy-layout overlap remain; live v3 server exchange is unverified.

Build: `D:/LittleGod/builds/android/LittleGod-Growing-World-debug.apk` (isolated QA package). Launcher: `D:/LittleGod/Launch LittleGod.cmd`. Full implementation, research, original assets, screenshots, measurements and commands: [GROWING_WORLD.md](GROWING_WORLD.md). Machine-readable evidence: `docs/benchmarks/estate/`.

## Compact mobile RPG layout — 25 October 2026

The full-screen dashboard structure has been replaced with the proportions of the user's Knight-style mobile references: 384×560 right-side inventory at 1280×720, a 40-pixel bottom strip, 235×61 status frame, 448×185 chat, floating stat/skill/quest/forge windows and circular combat controls. Twenty original vector icons and a seven-column bag with adjacent item comparison are implemented. Reference browsing, dimensions, screenshots and verification are documented in [CLASSIC_MOBILE_UI.md](CLASSIC_MOBILE_UI.md). This is a UI pass; earlier incomplete animation/online milestones remain incomplete.

Validated build: `D:/LittleGod/builds/android/LittleGod-Classic-Mobile-debug.apk`. Checks: **98/98** new layout/render/input, **270/270** landscape UI, **14/14** RPG interactions and **822/822** retained campaign checks pass. Seven Android emulator checks and separately inspected native taps pass; production save/backup hashes are preserved. Physical-device and stable 60/30 FPS verification are not claimed. Earlier checkpoint evidence below is historical.

## RPG implementation checkpoint — 25 October 2026

The requested RPG transformation is **in progress**. The new bottom-navigation HUD, combined character/inventory screen, four-hero roster, fourteen equipment positions, attribute/skill allocation, class combat behavior, 28 original equipment definitions and original generated class illustrations are connected to actual game state. Chat client/server source is added and compiles, but Windows App Control blocks running the API; live chat is not verified. Complete directional/layered character animation and full adaptation of the 877-item research catalogue are still outstanding.

Full report, exact evidence and remaining work: [RPG_IMPLEMENTATION_REPORT.md](RPG_IMPLEMENTATION_REPORT.md). Retained checks: **822 passed**; new progression/combat: **21 + 41 passed**, plus **14** UI/travel interaction checks; landscape UI: **270 passed**. Minimized chat reopens, portraits follow class selection, learned abilities show real cooldowns, and safe travel banks expedition cargo before destination selection. APK: `D:/LittleGod/builds/android/LittleGod-RPG-interface-qa-debug.apk`. Android verification uses a separate QA package in the emulator; no physical device was tested. Stable 60/30 FPS across sessions is not claimed.

The sections below describe earlier checkpoints; their layouts and art descriptions are historical.

## Landscape UI continuity update — 25 October 2026

The production UI Rebirth now targets **landscape** as the sole gameplay orientation: the Godot viewport is 1280×720, the Android orientation setting is landscape, and the world camera recalculates its centre around the usable space between the HUD rails. The planet is no longer composed against the lower edge inherited from the old portrait layout.

The live HUD was rebuilt around the landscape world view: an icon rail on the left opens Chronicle, construction, people, inventory, champion, map and menu; a right rail contains the current objective, spirit balance, zoom controls, centring, gifts and speed. The bottom strip exposes all god powers only when opened, keeping the planet readable. A persistent accessibility strip gives one-tap access to text size, high contrast, sound, haptics, battery saver and language. These settings are stored in `user://settings.cfg`; the complete Settings panel remains available for detail controls.

Evidence is from the real Godot runtime and generated screenshots under `docs/screenshots/ui-rebirth/` for 960×540, 1024×576, 1280×720, 1366×768, 1600×900 and 1920×1080, in Turkish and English. The landscape UI suite now reports **186 passing checks** (route safety, true model actions, world selection, save compatibility, landscape fitting and accessibility controls). It is a desktop-rendered verification; no physical Android device was used for this update.

The retained phase-three through phase-six regressions were also reconciled with the new, intentionally non-portrait control tree: 50, 41, 50 and 74 checks pass respectively. They continue to cover the original model, save, visit, Android-back and offline rules; only obsolete fixed UI-tree selectors were replaced by checks for the real visible controls.

The complete retained chain is green again: **822/822 checks** (745 retained plus 77 Sanctuary checks) across legal seeds 7, 42 and 2026.

Launch: `D:/LittleGod/Launch LittleGod.cmd` · runtime: `D:/LittleGod/tools/godot/Godot_v4.7.2-stable_win64.exe`.

**Full Visual Rebirth V4 is incomplete.** A reversible V4A/V4B Warrior style and movement prototype is implemented and rendered in Godot; the default game still uses E3 art. Expansion development is frozen. Unverified E4 work is preserved on `work/e5-sovereign` at8b83003, outside this preview branch. E5/E6/throne and V2/V3 approval are not claimed.

The preview has144 original vector pose cells, four cardinal views, distance-driven walking, stable equipment sockets, idle/dodge/hurt/kneeling poses and contact/follow-through compatible with the existing instantaneous damage model. Pause, touch cancellation, focus loss and suspension now clear movement/held attack/joystick state. It does not yet implement real attack anticipation, three enemy remakes, boss animation, combat sound/VFX overhaul or final V4 art approval.

Retained checks: **822 passed again**. New presentation checks: **27**; rendered checks: **35**. Android60/30 native input and exact force-stop restore pass in the isolated preview package; no physical-device testing. Actual metrics, initial failures and limits are in `ANDROID_ANIMATION_PERFORMANCE.md` and `docs/benchmarks/visual-v4/`.

- Preview launcher: `D:/LittleGod/Launch V4 Warrior Preview.cmd`.
- Normal launcher: `D:/LittleGod/Launch LittleGod.cmd`.
- Preview QA APK: `D:/LittleGod/builds/android/LittleGod-V4B-preview-qa-debug.apk`.
- Preview source archive: `D:/LittleGod/builds/LittleGod-V4B-preview-source.zip`.
- Slice tag: `littlegod-visual-rebirth-v4b-preview`; full V4 completion tag is deliberately absent.
- Report: `docs/VISUAL_REBIRTH_V4_REPORT.md`; source/pivots: `SPRITE_ANIMATION_PIPELINE.md`.

![Actual animated preview in the emulator](screenshots/visual-v4/android-60-walk.png)

## Preserved E3 release


Current verified development build: **0.8.5-devE3 / Android code92**, realm campaign1–23. Playable Sunken Sanctuary includes five connected spaces, two persistent puzzles, two avoidable real traps, three distinct elites, optional treasury/two lore discoveries, unique Sun Relic, four useful forge/equipment recipes and quest23. Existing E2 regions, quests, saves, workers, trade/caravans, military, online source and artwork are preserved.

**822 game checks pass:745 retained +77 new.** Three legal1–23 seeds pass. Rendered desktop: 38 checks, actual combat/puzzles/loot/research/forge/equip/23 screenshots. Both Android60/30 runs verify native controls, exact force-stop restoration and23; navigation/combat/forging helpers are labelled. Player APK signing/update/private startup preserves player files. No physical-device verification.

| Measured scene | FPS | p95 ms |
|---|---:|---:|
| Desktop · relic chamber | 60.81 | 17.12 |
| Emulator 60 · Sustained combat (test path generation excluded) | 59.96 | 25.42 |
| Emulator 60 · Relic chamber | 60.15 | 19.20 |
| Emulator 30 · Sustained combat (test path generation excluded) | 30.56 | 41.85 |
| Emulator 30 · Relic chamber | 30.17 | 38.18 |


The full E4/E5/E6/throne and Visual Rebirth V4 milestones remain incomplete; see the isolated V4B prototype above. E3 is a core gameplay delivery, not a claim of completed premium character animation. See AGE085_E3_REPORT.md, KNOWN_ISSUES.md and docs/benchmarks/phase085e3 for evidence and performance limits.

- Launch: `D:/LittleGod/Launch LittleGod.cmd`.
- Runtime: `D:/LittleGod/tools/godot/Godot_v4.7.2-stable_win64.exe`.
- Player: `D:/LittleGod/builds/android/LittleGod-0.8.5-milestone-E3-debug.apk`.
- QA: `D:/LittleGod/builds/android/LittleGod-0.8.5-milestone-E3-qa-debug.apk` (`.betaqa`).
- Source: `D:/LittleGod/builds/LittleGod-0.8.5-milestone-E3-source.zip`.
- Checkpoint: `age085-e3-ancients`; exact commit/hashes: `D:/LittleGod/builds/phase085e3/checkpoint-manifest.json`.

After real22, open the world map and enter Batık Tapınak. Read the inscription; step on Güneş then Ay; Inspect Güneş→Ay→Yıldız. Read trap warnings and dodge. Defeat the Warden to open the relic chamber; inspect the pedestal, return alive and inspect the recovered relic at home. Assign a smith, forge an ancient item, equip it and claim23. Cracked stone opens the optional treasury. All unique progress survives return/reopen.

![Actual Sanctuary](screenshots/phase085e3-guardian-hall-tr.png)
![Actual Sun Relic](screenshots/phase085e3-sun-relic-tr.png)
![Actual realm23](screenshots/phase085e3-quest23-complete-tr.png)
