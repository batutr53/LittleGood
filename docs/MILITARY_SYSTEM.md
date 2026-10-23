# Border Company — critical D prerequisite

Optional Chapter IV is available after the fifteen original claims. `kingdom.version` stays 3; the bounded `military` subrecord is added only by explicit opt-in. Existing C equipment IDs, hero records and pending forge jobs remain. Realm cap becomes20 only after opt-in.

Build a barracks at realm16, assign a real instructor, forge military kits at17 and recruit free citizens. Each soldier reserves one canonical citizen and one owned kit, costs3 food/2 gold, and needs six instructor ticks. Soldiers cannot also build, produce or equip civilian tools. At most six soldiers exist, consuming0.01 additional food/tick. Without food or an instructor, training/recovery stops. Dismissal releases citizen and equipment.

Militia, spearman and archer kit data controls actual attack, armor, reach and movement. Balanced, defensive and assault formations modify attack/armor. Veterans gain20XP on each first mission victory, with bounded bonuses. A completed watchtower adds2 attack and a palisade3 armor during village defense only.

The real scene advances persisted actors at20Hz: movement, nearest living target, locked windup, range recheck, damage, recovery, injury, retreat and return. Three raiders attack the village; the fortified camp contains a bowman, raider and150HP captain. Camp geometry affects movement. Android order/formation buttons, warnings, health bars and hit feedback reflect the model. Collision is lightweight bounded arena slide, not general navigation or army body physics.

Injuries preserve citizens/kits. Recovery costs2 food/1 gold and instructor work. Damaged ready soldiers may also recover. Defeat/retreat never awards victory; mission rewards/XP and quest claims are exactly once. Actual return gates quests19/20. Saves retain positions, windups, HP and orders. Home/offline simulation pauses during active battles. Wildwood and army combat cannot run simultaneously.

Validation rejects duplicate soldiers/citizens/gear, forged actor shapes, illegal status/HP/coordinates, orphaned reservations and inconsistent outcomes. `tests/military.gd` covers44 assertions, including authentic C migration with a pending potion job. Twelve seeded legal1–20 campaigns pass. Formations change an identical company's real outcome: defensive9150ms/217HP versus assault7950ms/205HP in the retained comparison.

This completes the critical prerequisite available from the earlier campaign brief. It does not claim an unseen full D specification, cavalry, siege, permanent deaths or E frontier systems.
