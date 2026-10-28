# Hotfix A — production collection

Baseline: `d9cc569`; implementation checkpoint: `6a59eb3`. The main button is
`playbook_ui.gd.building()` → `estate_layer.collect(id)` → `Estate.collect`.
It collects the **selected building**, not every farm/mine/forge/caravan.

## Reproduced cause

The model transfer worked in the inspected desktop case, but the interface
made it look ineffective. Farm food was 99.745/100; 2.725 food waited inside the
farm. A real mouse tap transferred 0.254 food, leaving 2.471 in the farm at
99.999 food (fixed-point floor conservatively avoids exceeding capacity).
There was no panel-local success message or ready/stored quantity. Another
tap returned an empty result, always mislabeled as storage full even when
production was unfinished or empty. Generic menu pause prevented new output
appearing until the panel closed.

The old E2 fixture also has 110.808 wood and 78.4 gold against base capacity 60.
Those legitimate historical balances are preserved; no silent truncation or
fake capacity increase was added. When stores have no room, pending products
correctly remain at their source. Food cap is 100 at the original settlement.

## Implemented

* Read-only collection report distinguishes ready, full, running, empty,
  expedition and unavailable states; exposes real output, capacity and items.
* Building inspector shows actual ready/stored amounts. Collect stays
  reachable and explains empty/full results. New output refreshes in place.
* Nonblocking `ActionNotice` remains visible above panels. Partial transfer
  tells the player that remaining products stay at source. No success sound or
  resource animation on a rejected/empty transfer.
* Existing exact transfer, production quest events, crafted item identity and
  construction acknowledgment remain in the authoritative command. Added
  item-capacity/duplicate-ID and unknown-resource guards before transfer.
* Debug collection trace records button/building/command, pre-state and actual
  result. Pending output is never consumed merely to produce success feedback.

## Verification

26 new model checks use the existing fixture plus actual ticks, forest
gathering, building construction, item queue and collection commands. No
demonstration balances or ready products are injected. They cover real farm
production, partial/full food and warehouse storage, selected owner, unrelated
building preservation, exactly-once quest event, double tap, crafted items,
rejection, read-only worlds and save/load. Existing 44 estate checks also pass.

Native desktop mouse and external Android taps verify real collection and
double collection through the actual button. Reports: `benchmarks/hotfix/`.
Screenshots: `screenshots/hotfix/a-collect.png`, `hotfix-android-collect.png`.
Ordinary inspector clock behavior is documented in `WORLD_INPUT_ROUTING.md`.
