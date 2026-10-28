# LibreKO systems checkpoint — 28 October 2026

This extends the previous icon/FX integration with actual model/UI rules.

* Separated definitions for all 24 existing learned abilities into
  `assets/rpg/skill-behaviors.json`: mana, cooldown, target policy, range, area,
  guard, dash, heal, cleanse, piercing and damage bonus. Existing numbers and
  hybrid attack/self effects are retained; no extra skills or campaign content.
* Validate explicit selected targets before resource/buff/cooldown commitment.
  Dead/missing, out-of-range or obstructed enemy targets reject the attack with
  visible feedback. Self/area and untargeted casts retain existing rules.
  Starter skill cooldown now uses its authoritative per-skill timer: holding
  its input cannot keep it stuck at the old artificial 50 ms gate forever.
* Upgrade UI commits the reviewed quote, binding item state, serial, costs and
  selected scroll. Changed/replaced ingredients, changed state and forged quote
  fields reject without RNG, material or inventory mutation. Existing legacy
  model entry point remains compatible. Military reservation is also explicitly
  checked by hero equip (current soldier kits already have category protection).
* Target-goal coordinator joins existing unclaimed hunt contracts to real enemy
  identities and optional tracked recipe costs to actual enemy drop definitions.
  Owned stock plus carried cargo count toward material goals. Target card shows
  two compact goals; Inspect shows up to three. Forge recipe offers session-only
  material tracking. Completion feedback says to claim at home; existing reward
  command still enforces real progress, storage and exactly-once delivery.

References inspected at the pinned LibreKO revision:
[attack timing/reach tests](https://github.com/ZeusAFK/LibreKO/blob/e5f0e4200fd42f69934f55557f92f2ee2ccfafde/Server/tests/LibreKO.Game.Tests/AttackTimingAndReachTests.cs),
[magic reach tests](https://github.com/ZeusAFK/LibreKO/blob/e5f0e4200fd42f69934f55557f92f2ee2ccfafde/Server/tests/LibreKO.Game.Tests/MagicReachTests.cs),
[upgrade service](https://github.com/ZeusAFK/LibreKO/blob/e5f0e4200fd42f69934f55557f92f2ee2ccfafde/Server/LibreKO.Game/Protocol/ItemUpgradeService.cs),
[target quest drops](https://github.com/ZeusAFK/LibreKO/blob/e5f0e4200fd42f69934f55557f92f2ee2ccfafde/Server/LibreKO.Game/World/TargetQuestDrops.cs).
These are reference algorithms/patterns; implementations use LittleGod's
existing GDScript models, definitions and balance. No C# runtime code copied.

Verified: **120 new model checks**, **822 retained campaign**, **142 playbook**,
**46 battle**, **41 class-combat** and **45 armory** checks pass. Godot MCP target
card was inspected; `docs/screenshots/libreko-systems/target-goal.png` is an actual
render using a labeled private test fixture, not a legitimate onboarding journey.
Reports: `docs/benchmarks/libreko-systems/`. No APK generated for this intermediate
checkpoint; prior version 106 APK remains intact. Save schema unchanged and
upgrade roundtrip verified. Existing shutdown resource warnings remain.

The subsequent Project Reforge directive supersedes broad feature expansion:
portrait-first UX, NPC clock continuity and a legitimate player journey are next.
This checkpoint does not constitute completion of Project Reforge.
