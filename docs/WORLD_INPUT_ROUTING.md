# Hotfix C — world input and inspector ownership

Implementation checkpoint: `0b8d86b`. Baseline investigation found **three
code gates**, rather than a full-screen transparent rectangle alone:

* `Interface.blocks_world` returned true whenever `game.in_menu` was true.
* `main._input` and `_unhandled_input` returned for every menu.
* The home clock returned for every menu except the previous Arin exception.

The decorative veil already ignored mouse events. Changing every Control to
IGNORE or PASS would not fix these gates and would break actual panel buttons.

## Context policy

Home `building`, `staffing`, `worker`, `terrain` and `settlement` surfaces are
ordinary non-modal inspectors. Their real panel and live controls consume input;
exposed world accepts native mouse/emulated single-touch/pan/pinch input. Their
world clock continues through the existing accumulator unless the user paused,
application suspended, or another existing clock owner blocks it.

When an exposed world tap begins selection, the old inspector closes, resets
subscriptions/route context and uses the original real sprite hit-test. A new
building replaces it; empty terrain dismisses it. No duplicate surface or signal
is installed. UI taps do not call the underlying world handler. Feedback overlays
and their text ignore input and disappear after their timeout.

NPC conversation retains its separate rule: economy continues but unrelated
world input is gated until the conversation closes. After close, buildings are
selectable again. Adventure/army inspection retains deliberate combat policy.
Settings and transaction/destructive confirmation routes remain input-blocking;
upgrade/enhance surfaces visibly dim the world. They can be canceled/closed.

Panel bounds adapt to the exposed upper world in portrait test viewports; this
hotfix does not redesign the whole game's legacy landscape HUD. Header close
and scrolling remain available. The actual production orientation is unchanged.

## Verification

65 new rendered/native-mouse checks cover Mine→Farm→Forge→Barracks→Marketplace,
selection contours, one inspector, real Collect/Assign/Remove buttons, no UI
click-through, empty-world dismissal, true modal blocking, inspector clock,
TR/EN bounds at 320×568, 360×800, 393×852 and 1280×720, and save/load.

The old fixture hides the forge behind overlapping roofs. Tests use the real
free relocation command in their **private fixture** to expose it, preserving
IDs, jobs and resources. This is not an automatic rearrangement of player saves.
Building test coordinates are selected from visible opaque interiors, allowing
for Android physical/logical pixel rounding. A prior boundary tap that selected
the quarry instead of farm is retained as failed diagnostic evidence.

Debug world/selection logs record positions and selected building ID. A shared
button callback now uses a WeakRef so a stale freed panel button cannot run a
later action or log an invalid capture error. Existing X/back navigation remains.

Android evidence uses external `adb shell input tap`, including a compact
portrait QA-only orientation/viewport override. Actual tap sequence and exact
results are in `docs/benchmarks/hotfix/`; no physical-phone claim is made.
