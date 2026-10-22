# Checkpoint and exact next work

## Phase 2 update

Visual terrain transitions, painted creature/environment art, evolved village visuals, illustrated discoveries, a consistent icon/font system, portrait expansion, gesture smoothing and a battery-saver mode are now implemented. The repeated terrain viewport redraw and a restored-save float-clock bug were fixed. Current measurements, APK path and screenshots are in STATUS.md and PHASE2_REPORT.md. The original list below is phase-one planning history; physical-device performance, richer ecology/content, accessibility, long-running mobile interruption tests and iOS work remain relevant.

Implemented: environment setup, Godot Forge source installation and working MCP verification, original art pipeline, six biome island, six moving species, interacting climate and vegetation, communities, six gifts, local saves and recovery, bounded return progression, EN/TR menus, discoveries, history, two milestones, cosmetic sky unlock, sounds, animation, desktop and Android debug export.

This is a playable 0.1 milestone. It is not the full premium release or a production-ready mobile launch.

Next tasks in priority order:

1. Profile 20-minute sessions on physical mid-range Android devices; test battery, thermal throttling, cutouts, gesture navigation, pinch, and background/resume interruptions.
2. Strengthen biome generation from current coordinate zones into climate-driven habitat transitions; add shore and river-edge blending and more vegetation arrangements.
3. Expand six species into separate data resources with distinct diets, life cycles, local population tracking, social movement, and richer sprite animations.
4. Add more meaningful rare events, ecological achievements, settlement technology effects, and discovery illustrations. Current milestone has two achievements and one unlock.
5. Replace font-dependent symbols with a consistent SVG icon set, add a dedicated branded splash scene, and improve screen transitions and accessibility options.
6. Improve save migration beyond version one and add multi-slot saves, explicit replacement confirmation, export/import, and more fault-injection tests.
7. Refine rain and movement audio, add optional original music, and validate voice/audio accessibility preferences.
8. Prepare iOS through macOS, Xcode, signing, and device testing. Windows cannot produce or validate an iOS binary.
9. Only after content and physical-device validation, consider opt-in cloud save and cosmetic purchases. No store publication or payment activation is authorized.

The repository and local builds are the continuation point. Inspect `docs/TEST_REPORT.md` and `docs/KNOWN_ISSUES.md` before further work.
