# LittleGod 0.4 — release checkpoint

Phase four was unfinished when the Phase 5 brief arrived. Stability and onboarding work is now checkpointed before expanding the simulation.

Implemented: transactional verified saves with healthy backup retention and interrupted-write recovery; paused-state persistence; debounced intervention saves and lifecycle/menu checkpoints; bounded, frame-sliced offline restore with visible loading; no unused demo terrain at startup; modal input isolation, clean gesture cancellation and back navigation; short interactive care guidance and contextual exploration after its chapters; local, optional diagnostic preview/copy/clear controls. Diagnostics contain fixed event codes and numeric counters, never names or identifiers, and never upload. An unclean session marker is not a confirmed crash report.

Rendering reuses unchanged per-cell prop sprites rather than rebuilding all decorations. Gifts invalidate terrain immediately. Original artwork is retained. Real Godot MCP inputs and captures were inspected, including the contextual action and the evolved world. Current gameplay error query returned an empty list after clearing historical editor errors. Explicit script preload fixed an initial editor class-registration failure.

Verification: 156 automated checks (51 core, 1 runtime, 15 phase two, 49 phase three, 40 phase four). Android isolated fresh-install QA passed 14 additional checks: form creation, real ADB pan/zoom-button/power taps, checkpoints, background/kill/reopen, retained power state and quality settings. These are automated simulated tests, not human feedback. Physical pinch and physical hardware remain unverified.

Android emulator 15-second final smooth run: 58.37 FPS, 19.30 ms p95, .539 ms average simulation, 134 draw calls, 46.02 MB engine static memory / 35.80 MB video memory, first engine frame 2228 ms. Existing player save bytes were unchanged. The current-phase 0.3 baseline was 58.03 FPS / 19.04 ms p95; these do not demonstrate a major average-FPS gain. Offline responsiveness is the measured improvement: 480 synchronous ticks took 161.40 ms; staged restore peaked at 4.41 ms per slice and took 627.50 ms overall. Save verification adds work (8.46 ms in the pipeline sample). Headless timings exclude GPU upload and are not cold-phone measurements.

Outputs: `D:\LittleGod\Launch LittleGod.cmd`, `builds/android/LittleGod-0.4-debug.apk`, `builds/LittleGod-0.4-source.zip`. APK exported, signed, updated on emulator and started. Separate QA package avoids erasing the main app's saved planet. Detailed evidence lives in `builds/phase4`; selected JSON is versioned under `docs/benchmarks/phase4`. Real screenshots are `docs/screenshots/phase4-*.png`.

Remaining: resource/ObjectDB warnings at engine/Forge shutdown, occasional startup/process spikes, physical-device and external first-session testing. No security changes, publishing or paid services.
