# Project Reforge — research and design, intermediate R1/R2

Latest verified pre-Reforge checkpoint: `2d44211` (LibreKO model adaptations),
following `dbca4eb` (sources/icons/FX). Source backup:
`D:/LittleGod/builds/backups/LittleGod-pre-reforge-2d44211.zip`.
Production APK and player saves are preserved. Exact runtime remains Godot
4.7.2, Compatibility renderer. New campaign content is frozen.

## Evidence versus interpretation

| Evidence | Design interpretation | Current implementation |
|---|---|---|
| [Sweetser & Wyeth, GameFlow, 2005](https://doi.org/10.1145/1077246.1077253) organizes enjoyment around goals, control, feedback, challenge, skills, concentration, immersion and social interaction. | Show a concrete next action and make world consequences visible. | Arin uses existing authoritative journey advice and real reward commands; target-goal coordinator uses existing contracts/drop definitions. Human comprehension is unverified. |
| [Korhonen & Koivisto, 2006](https://trepo.tuni.fi/bitstream/10024/99584/3/978-952-03-0205-4.pdf) separates mobile playability into usability, mobility and gameplay. | Test readable controls and interruption behavior separately from model correctness. | Dialogue rendered at six logical sizes in TR/EN; private Android force-stop/relaunch tested. Whole portrait HUD and simultaneous multitouch remain unverified. |
| [Przybylski, Rigby & Ryan, 2010](https://selfdeterminationtheory.org/SDT/documents/2010_PrzybylskiRigbyRyan_ROGP.pdf) discusses autonomy and mastery of controls in motivational engagement. | Offer relevant choices and explain progress without punitive absence mechanics. | Arin offers current next step, workers, equipment and hunts. Existing bounded offline economy retained. No engagement/retention or human-study claim. |
| [Android touch guidance](https://support.google.com/accessibility/android/answer/7101858?hl=en) recommends 48dp targets and spacing. | Dialogue gets readable text, 48 logical-pixel buttons and a fixed close control. | Logical layout checks pass. Game pixels have **not** been certified as dp on physical devices; density, safe areas and cutouts remain R5/R11 work. |
| [Metin2 official wiki quest list](https://en-wiki.metin2.gameforge.com/index.php?stable=1&title=List_of_Quests) describes NPC indicators, map marks and NPC/objective/return quest sequences. | Identify a real quest giver in the world and point to legitimate objectives. | Original Arin portrait/semantic marker at the original settlement. Full acceptance/navigation/return journey is not implemented by this slice. |
| [Knight Online official interface guide](https://www.nttgame.com/knight/en/guide/installation) describes status, minimap, target HP, quick slots and separate chat/inventory functions. | Give combat targets, resources and actions clear contexts. | Existing real HP/MP/targeting retained; explicit selected-target validation and target goals added. No fictitious party channels or multiplayer claims. |
| [Rise Online classes](https://www.riseonlineworld.com/en/classes) distinguishes class and specialization roles. | Keep Warrior/Priest/Mage/Rogue identities readable. | All 24 existing learned skill behaviors now have data definitions; numerical values remain LittleGod balance. No Rise assets or percentages copied. |

Silkroad-specific primary-source inspection remains pending. No borrowed game
art was added for Reforge. Arin's original LittleGod portrait is reused in the
world and dialogue; its modest portrait bob is not skeletal animation.

## Observed defects, not assumptions

Godot MCP baseline: opening Arin's old `journey` panel set `in_menu=true` while
`SceneTree.paused=false` and `game.paused=false`. Tick stayed at 386 across
observations while view time advanced from ~21.77 to ~93.44 seconds. The home
clock gate, not SceneTree pause, stopped the economy. Renderer interpolation
also explicitly excluded all menus. Old dialogue used compact panel typography.

After the change, the real main clock advanced from tick 386 to 402 while Arin
remained open and a gathering worker produced a 2-unit gold buffer. A later
observation reached the normal 6-unit buffer cap. No fake production animation
or separate economy timer was introduced. Native MCP world click opened Arin.

Chat/network, full audio listening audit, all first-session journeys, complete
portrait HUD and high-quality directional animation have not been audited or
completed here. See the release ledger; Reforge is **not** release complete.
