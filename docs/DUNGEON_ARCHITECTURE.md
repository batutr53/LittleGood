# Sanctuary architecture

kingdom.version3 and adventure.version1 remain. The regional subrecord opts into version3 only after claimed22 at actual Sanctuary entry. It retains E2 quest proof and adds ancients plus three stock keys. At most three parked runs plus the current region retain unique IDs. Original industry items, workers, caravans, military and saves keep their owners.

sanctuary_map.gd owns960×1440 static room walls, four closed-door rectangles, plates, levers, relic and hazards. Headless movement substeps; the actual scene uses CharacterBody2D/static colliders. AStar is developer bot navigation only. It handles valid actor positions next to blocked grid centres by routing within interaction range. No player auto-pathfinding is added.

sanctuary.gd owns mechanisms/trap clocks/elite state/relic/research/validation. adventure.gd remains the authority for movement, health, attacks, pickup IDs, rewards and return banking. sanctuary_view.gd draws bounded warnings and toggles colliding doors from saved state. No extra crowd or particle system. Clock advancement stays20Hz. Active or defeated adventure freezes home/industry/caravans/offline; no absence damage. Re-entry never refills unique rewards.
