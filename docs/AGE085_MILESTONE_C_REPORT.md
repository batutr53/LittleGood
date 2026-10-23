# Milestone C implementation log

Base: `age085-milestone-b`, commit6bb4100. Safe base `age085-c-base-b`. All459 baseline checks passed before changes. No0.9 work or military development.

## C1 — verified hero foundation

Explicit chapter migration preserves2200XP, earlier claims, original common balances, civilian IDs/equipment and pending forge queues. Campaignv3 adds private hero/adventure state and zero material balances. A named Warrior has separate hero XP/level, deterministic stats, compatible weapon/shield/armor/artifact slots and persistent health/cooldowns. Combat equipment is made in the existing paid-material, worker-driven forge queue; it cannot be equipped by civilians. Existing tools remain unchanged.

Twelve new hero checks pass, including an authentic tagged-B fixture with a pending job, migration idempotency, exact preservation, legal1–11 progression and an actual sword's attack effect. The real Godot profile was rendered/inspected. C1 checkpoint is `age085-c1-hero`; adventure movement/combat/loot/boss remain pending at this checkpoint. The final `age085-milestone-c` tag is reserved for complete C verification.

## C2 - verified Wildwood exploration
Separate playable scene, real CharacterBody2D/StaticBody2D collision, touch movement, AStar path checks, actual Sunstone interaction, safe return and quest12 pass. Nine model checks and rendered physics traversal pass. Home simulation/offline combat pause explicitly while away. C2 checkpoint: age085-c2-wildwood. Combat is next; no complete-C claim.

## C3 - verified real combat
Wolf bite/chase, armored slow Thorn Beast heavy warning and Spider locked-target leap use distinct real state machines. Equipment-derived attacks, cooldowns, dodge invulnerability, herb/potion healing, death and weighted persisted drops work. Legal1-13 model journey, exact loot/death restoration and actual rendered physics fight (enemy hit back, warning visible, enemy defeated and loot picked up) pass. Texture lifetime was fixed after visual inspection caught a white herb quad. C3 checkpoint: age085-c3-combat.

## C4 - verified blacksmith integration
A legal1-14 journey brings real leather/thornhide/herbs home, pays iron/material costs through the existing forge and equips the Thornhide Blade and reinforced shield. Attack/defense, material consumption, exact inventory restoration and explicit cleared-trail revisits pass six checks. C4 checkpoint: age085-c4-equipment. Boss is next.
