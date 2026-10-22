# LittleGod — phase 2 status

The existing project is now at the **0.2 visual and mobile-performance milestone**. Phase-one gameplay and version-one saves remain supported. The original 51 checks were retained; 15 new checks and the scene-clock integration check also pass (**67 total**).

Implemented and inspected in real gameplay: connected terrain with blended biome colors, river banks/waterfall and layered cliffs; twelve new original painted creature/environment sprites in a shared atlas; evolving cottage/guildhall settlements and villagers; creature grazing, wandering, breathing and rain reactions; foliage/water shaders; discovery/power effects; consistent vector icons and licensed fonts; illustrated EN/TR discoveries; branded boot art; full-height portrait layout; smooth anchored pan/pinch; accidental pinch-cast prevention; optional haptics; cached audio/rain ambience; and a 30 FPS battery-saver mode.

A legacy-save bug was found and fixed: JSON clocks restored as floats could break integer modulo operations. Loading now normalizes integer fields, and the new fixture test verifies that restored population/discoveries actually advance. The save version, power costs and ecological rules remain compatible.

## Measured performance

| Environment | Average FPS | Frame p95 | Duration |
|---|---:|---:|---:|
| Windows smooth | 60.04 | 16.75 ms | 15 s |
| Android emulator smooth | 57.61 | 20.07 ms | 30 s |
| Android emulator, 70 creatures | 59.30 | 18.34 ms | 12 s |
| Android emulator battery saver | 29.97 | 34.96 ms | 30 s |
| Android emulator blank control | 60.17 | 18.31 ms | 12 s |

The new desktop capture uses about 117 draw calls and 2.6 ms process time, versus 287 calls and 23.9 ms in the baseline capture. Android static memory is roughly 45.5 MB in smooth mode and 42.7 MB in battery saver; reported video memory drops from 35.8 to 24.1 MB. Benchmarks preserve the existing player-save bytes. Only an API-35 x86_64 emulator with NVIDIA host GPU was connected; **no physical-device verification is claimed**.

## Launchers and builds

- Play current source: `D:\LittleGod\Launch LittleGod.cmd`
- Verified runtime: `D:\LittleGod\tools\godot\Godot_v4.7.2-stable_win64.exe`
- Godot project: `D:\LittleGod\project.godot`
- Current Android debug APK: `D:\LittleGod\builds\android\LittleGod-0.2-debug.apk`
- Current source archive: `D:\LittleGod\builds\LittleGod-0.2-source.zip`
- Tests/profile/build evidence: `D:\LittleGod\builds\phase2\`

The APK exports, installs over the previous package and starts on the emulator. Windows source play is verified; the older exported Windows console launcher remains blocked by App Control. No security controls were changed or bypassed. No iOS binary, payments, paid API service, account sign-in or publication was used.

## Screenshots and remaining work

- [Before](screenshots/phase1-before.png), [after](screenshots/phase2-after.png), [evolved towns](screenshots/phase2-town.png), [Turkish journal](screenshots/phase2-journal-tr.png).
- [Detailed implementation, asset, performance and testing report](PHASE2_REPORT.md).
- Physical-device thermals, battery, accessibility, actual haptic feel and sustained multi-touch testing remain.
- Cold startup/mesh-refresh spikes remain; Godot/Forge shutdown still reports resource/ObjectDB cleanup warnings. Short profiles are not a guarantee of sustained hitch-free 60 FPS.
- Climate generation still uses broad biome zones; species ecology, technology, long-term progression and content depth remain simplified.

The phase-one status and known-issues documents are preserved under `docs/archive/`. See `KNOWN_ISSUES.md` for current limits.
