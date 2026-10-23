# Real combat — Milestone C

Normal attacks use a78px forward arc and500ms cooldown; heavy strike uses105px radius,1.6× attack and4s cooldown. A deterministic persisted RNG gives10% critical hits at1.5×. Actual equipped attack is reduced by the target's defense, with minimum1 damage. Each attack can hit an enemy only once. Armor/shield defense reduces incoming damage by the same flat rule.

Dodge travels at450px/s for250ms, grants300ms invulnerability and has1.2s cooldown. Ordinary movement is180px/s. Hurt invulnerability is250ms. Herbs restore25 health; a crafted potion restores35 and is removed exactly once. Healing has1.5s cooldown and cannot revive a defeated hero. Full-health use consumes nothing.

| Enemy | HP / attack / defense | Behavior |
|---|---|---|
| Wolf |32 /9 /0|Fast132px/s chase, short55px bite,500ms warning,1100ms recovery|
| Thorn Beast |48 /15 /3|Slow72px/s armored approach,75px heavy attack,900ms warning,1500ms recovery|
| Ancient Spider |30 /10 /1|115px/s ranged approach, locked landing circle and bounded180px leap,750ms warning,1400ms recovery|
| Thornheart |220 /22 /4|58px/s approach, locked frontal sweep, targeted roots and phase-II radial shockwave;1200ms recovery|

Thornheart's frontal cone reaches140px with dot threshold>.35; roots strike an85px circle at the locked aim point. At110HP or lower the pattern cycle gains a145px radial shockwave and root warnings shorten from1100 to700ms. Directional/area telegraphs match these hit tests. An enlarged original guardian sprite, named health/phase display, warning effects, defeat fade, sound and victory message distinguish the encounter.

Death resolves against the canonical enemy record and marks it dead before granting XP/loot. Repeat callbacks and loaded dead enemies grant nothing. Boss reward state is persistent; the living heart and world-history victory are emitted only on the first eligible victory. An explicit later expedition can earn combat XP from a newly fought enemy, but cannot mint another unique heart.

Tests cover all three boss patterns, the shortened second-phase warning, save/load during a locked warning, actual dodges, enemy attacks back, defeat/recovery and legal1–15 campaigns. Rendered tests use Godot physics rather than the model collision fallback.
