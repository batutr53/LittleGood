# Hotfix B — worker assignment

Implementation checkpoint: `fc0682c`. Actual route:
building → staffing → named available worker → `Kingdom.assign`.

## Reproduced cause

A native desktop tap on `Ata: Eren · İnşaat havuzu` changed worker #3 from
building 0 to farm #2. Its count became 2/2 and production rate became 0.627
per tick. The model assignment was functional, but the panel silently rebuilt,
gave no visible result and the generic menu gate still stopped real production.
Several callbacks did nothing on rejection; current workers led to another
screen rather than offering a direct removal action.

## Implemented

* Named quick assignment remains the intended existing interaction; no extra
  confirmation is needed for this reversible, explicit choice.
* Read-only eligibility reason checks identity, unavailable/read-only world,
  target existence, building completion/passive role/capacity, current duty,
  military, caravan and gathering reservations. The authoritative `K.assign`
  still validates the mutation; no separate UI worker count is maintained.
* Success reports the worker name, updates the actual count/status, checkpoints
  the save and returns to the same building's roster. Current workers have a
  direct Remove action. Full/no-available states are explained.
* Busy worker transfer requires explicit release first; production contribution
  stops there. The staffing destination is retained across release so another
  valid assignment can follow without losing context. No silent dual duty.
* Gathering callbacks also report actual acceptance/rejection; zero cargo
  collection cannot claim `+0` success. Existing source/travel/buffer rules and
  safe-release requirement remain. No remote travel is skipped.
* Debug logs include worker/building IDs, command result and rejection reason.

24 new model checks cover eligible assignment, production gain, release,
stopped output, legitimate transfer, capacity, passive/unfinished buildings,
military/gathering reservations, identity conservation, invalid IDs and saving.
Military retirement in the capacity fixture uses the real command; no citizens
are fabricated. Existing caravan/military/campaign regressions remain passing.

Native desktop and external Android taps select a worker, assign it to the
real mine, wait for actual ore production during inspection, then remove it.
The measured rate drops on removal. Native screenshots and traces are in
`docs/screenshots/hotfix/` and `docs/benchmarks/hotfix/`.

No new remote-outpost worker system was introduced; existing caravan and
military reservations retain their own travel/management rules.
