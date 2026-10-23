# Warrior — Milestone C

Chapter III is an explicit, once-only opt-in after the ten existing main quests. `hero.gd` extends campaign version2 to3, preserving XP, claims, buildings, civilian IDs, equipped tools and pending forge jobs. New material balances start at zero. The actual historical B save fixture includes an unfinished crafting job.

Recruit one named Warrior for5 food and3 gold. Names support Turkish, are trimmed and limited to24 characters. The hero has a separate persistent ID, XP, level, health, defeat state, four compatible equipment slots and four action cooldowns. Hero level is `min(15, 1+floor(sqrt(XP/40)))`; it does not replace realm level. Base health100, attack10, defense2, speed180px/s, critical chance10%; each additional hero level adds6 health,2 attack and1 defense.

Weapon, shield, armor and artifact slots reference actual unique items in the existing industry inventory. They do not consume or duplicate those items. Civilian tools cannot enter hero slots; combat equipment cannot enter civilian tool slots. Equipment comparisons calculate the prospective effective health/attack/defense before selection. Equip/unequip is available at home; adventure gear cannot be swapped mid-hit. Maximum-health reductions clamp current health.

The original generated Warrior PNG is animated in the actual scene with walking bob/sway, attack rotation and sword arc, hit tint, dodge transparency/trail and death/recovery feedback. These are procedural sprite animations, not a new frame-by-frame animation sheet. Asset and exact image-generation prompt: `assets/adventure/warrior.png`, `docs/art/warrior-prompt.md`.

Implementation: `scripts/hero.gd`, `scripts/hero_interface.gd`; tests: `hero.gd`, `combat_crafting.gd`, `adventure_invariants.gd` under `tests/`.
