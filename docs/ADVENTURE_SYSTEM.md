# Wildwood — Milestone C

Open First Kingdom → complete quests1–10 → Begin Chapter III → recruit/equip a Warrior → claim quest11 → World map → Enter Wildwood. Quest objectives link to the working Hero Hall or world map.

`scenes/adventure.tscn` is a separate playable960×1440 top-down environment, not a screenshot or menu battle. The camp leads north through a water basin, collidable trees/rocks, healing plants, Sunstone ruin and chest to the guardian grove. The northern root barrier opens after quest14; it is visibly labeled while closed. Godot CharacterBody2D movement uses actual StaticBody2D collisions. Model tests use bounded swept collision with the same geometry. Navigation uses a24px AStar grid for test travel; enemies use small chase/attack state machines rather than per-frame navigation rebuilds.

Controls: left touch stick plus right Attack/Strike/Dodge/Inspect/Heal buttons. Hold Attack to repeat. Desktop: WASD/arrows, Space attack, Q strike, Shift dodge, E inspect, F heal, Escape pause; click the field to aim an attack. Home safely retreats. Pause/Android Back stop combat and show Resume. Touch stick and right buttons track independent inputs; physical simultaneous multitouch has not been verified.

Home ecosystem dictionaries and their identities remain in memory while the adventure scene renders. Home simulation and offline advancement pause during an active adventure. Combat uses bounded50ms steps; away time never fights, kills or punishes the hero. Autosave runs every5 seconds and on interactions/return, preserving position, enemies, warnings, cooldowns, RNG state, chest/plants, taken drops and cargo. Resume restores that state rather than respawning rewards.

Home deposits collected material cargo into common stock, records the actual living-heart return, restores health and keeps equipment. Defeat freezes movement/attacks and explains recovery; Home provides a mild retry without losing the kingdom or collected loot. A fresh expedition is an explicit world-map action only after all enemies are dead and all drops are collected; the unique boss ingredient remains once-only across revisits.

The camera frames the playable area above touch controls with padded terrain behind the HUD. Cached terrain and props reuse original art; active enemy warnings, hits and loot stay dynamic. Portrait720×1280 desktop and720×1600 Android layouts were inspected. Other phone aspect ratios, cutouts and physical touch comfort still need device testing.
