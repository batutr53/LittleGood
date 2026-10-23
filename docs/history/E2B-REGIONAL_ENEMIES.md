# Iron Hills enemies — E2B

No desert archetypes or new bosses are claimed. The original Wildwood enemy behavior and Thornheart patterns remain.

| Enemy | HP / armor | Motion and attack | Reward |
|---|---|---|---|
| Stone Crawler |74 /7|Slow55 units/s;83-unit reach;1050ms heavy warning, aimed cone recheck,1550ms recovery|3 ore,36 heroXP; one weighted stone/iron drop|
| Cave Stalker |46 /1|150 units/s pursuit;420ms locked lunge warning; up to75-unit lunge;55-unit landing check;850ms recovery with a350ms diagonal disengagement|2 leather,34 heroXP; one weighted herb/ore drop|

Telegraphs are rendered from saved state/timers. The crawler's conservative warning circle bounds its aimed heavy swing; the stalker's warning marks its locked landing area. Dodge, armor, normal/strong attacks and healing use the original hero rules. Hits resolve at20Hz; recovery cannot attack again immediately. A zero-distance stalker landing now still chooses a bounded disengagement direction. Original SVG silhouettes have movement sway, windup feedback, health bars, hit numbers and defeat fade through the existing scene.

There is exactly one of each enemy in the finite mountain expedition. Returning or loading cannot reroll defeated enemies or their loot. Canonical IDs, HP/state, regional kind restrictions, duplicate IDs and loot ownership are validated. The legal regional journeys defeat both using actual movement/combat commands; dedicated combat tests check warning duration, no early heavy hit, actual damage, dodgeable miss, lunge and recovery motion. No test grants XP or quest flags to obtain the legal journey result.
