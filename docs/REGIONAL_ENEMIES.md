# E2 regional enemies

The original Wildwood enemies/Thornheart remain unchanged. Mountains retain Stone Crawler (74HP/7armor, slow aimed1050ms heavy strike/1550ms recovery) and Cave Stalker (46HP/1armor,420ms locked lunge/850ms recovery with diagonal disengagement). Original artwork, death/loot identities and finite mountain state persist.

| Desert enemy | HP / armor | Behavior | Real reward |
|---|---|---|---|
|Sand Stalker|50 /1|165units/s pursuit;350ms short melee warning;1000ms recovery with350ms disengagement; no wolf-identical idle recovery|2 leather,36XP, weighted herb/gold|
|Dune Scorpion|80 /8|58units/s;1050ms aimed107-unit heavy sting;2000ms recovery with armor reduced to0; actual hit applies poison|2 crystals,42XP, weighted herb/iron|
|Ruin Sentinel|88 /5|72units/s;guards650,350; returns when hero leaves330-unit guard area;900ms locked65-radius ranged impact warning and1500ms recovery; terrain line-of-sight checks|2 crystals,48XP, weighted iron/gold|

Poison is non-stacking four-second status: four2HP ticks on authoritative simulation time. It persists across an active save/relaunch with no duplicate tick or offline damage, and clears on home return, defeat, purification tonic or the once-only oasis recovery. Actual damage requires a hit and can be dodged. Scorpion recovery opens a real armor window. Saved states drive visible telegraphs, HP bars, attack sway, hit numbers and defeat fade; no text-only combat or new boss is substituted for an encounter.

Each region has bounded canonical enemies, no reward reroll/respawn and exactly-once loot IDs per run. The desert enemies reuse shared hit/dodge/gear/collision/loot infrastructure but have separate state logic. Automated and rendered tests verify genuine warnings, damage, misses, poison timing, pursuit/recovery/guard behavior and legal victory with currently available gear.
