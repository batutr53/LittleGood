# Local planet universe — 0.6

The social layer has no network transport, account system or remote service. A `.lgplanet` file is an inert, versioned public snapshot. Import it from Local universe, inspect its profile, then visit. The simulation stays frozen while water, foliage, creatures and weather continue visual animation. Reactions are saved only on this device and are never delivered to an owner. Copy summary uses the clipboard. PNG/JSON saving opens an OS file picker; users share the resulting file with their chosen app. Direct Android ACTION_SEND integration is not implemented.

## Public schema v1

`format=littlegod.showcase`, `version=1`; exact root fields: planet, cells, creatures, settlements, memories, discoveries, secrets, findings. The implementation in scripts/planet_showcase.gd defines every required nested field and its range. Planet contains name, simulation tick, weather, theme and XP. Public creature IDs are contiguous remapped indexes; families are remapped groups. Relationships reference those indexes, not private identities. Cell coordinates and public place markers describe the real rendered world. Community records include culture, stage, landmark, allies, rivalry and the current trade window. The bounded Chronicle preserves actual simulation events.

Export whitelists visible names and world data. It excludes seed, RNG, save timestamp, device data, paths, diagnostics, favorites and identifiers from external services. Names are player-entered public content: the profile explicitly asks the player to review them before sharing. Path/URL-like names and control/markup-bearing text fall back to safe display names. This is privacy minimization, not anonymization of names the player intentionally writes.

Import accepts JSON only: maximum 512 KiB, pre-parser nesting limit 12, exact fields, finite/ranged numbers, integral indexes, unique map positions, known enums and event keys, bounded strings and references. Maximum 400 tiles, 100 creatures, 10 settlements, 64 memories, one canopy/reed landmark per kind. No script evaluation, resource loading, executable payload or embedded image download. Invalid/future-version documents fail before reconstruction. Filesystem/content-provider reads have a byte cap. File picker failures show a generic message without exposing paths.

A local library holds eight validated content-hash copies, deduplicates repeated imports and allows removal. Writes use a verified temporary file and rename. IDs are exactly 64 lowercase hexadecimal characters; traversal is rejected. Reactions use separate small private files. Original external documents are read, never rewritten. Sharing includes a snapshot, not a save-game continuation.

## Visit boundary

main.visit_planet validates and reconstructs a fresh dictionary before checkpointing the player's current world. It retains the original world reference, RNG, pause and camera state, then swaps the renderer to the read-only snapshot. The model, creature and settlement records are marked read-only. Tick, ecosystem, civilization, story, discovery, rename, favorite, powers, offline replay and save entry points reject writes. Menu options hide editing and power controls. Android background/resume cannot run offline events in a visit. Returning restores the original world and camera. A visit pauses personal simulation time; it does not fabricate activity in either world.

Tests exercise both model guards and the actual scene/lifecycle, including unchanged imported bytes and unchanged own save bytes *after the intentional entry checkpoint*. Read-only flags are an application boundary, not a sandbox for arbitrary third-party code; no third-party code is accepted.

## Future provider interface

The local provider exposes entries(), get_planet(id), import_text(text), remove(id), react(id,value), reaction(id), project(world) and world_from(data). Keep validation/projection outside future transport. A future asynchronous provider can implement list_public_profiles(cursor), fetch_snapshot(id,version), publish_snapshot(validated_data,explicit_consent), send_reaction(id,value,consent), and delete_own_snapshot(id). It must return inert schema documents to this same validation boundary; it must never accept a private save or permit remote simulation writes.

Online friends still require an authorized backend choice, authenticated ownership/access controls, consent and deletion/export flows, abuse moderation/reporting, block lists, rate limits, transport security, quotas, child/privacy review and operational support. Real-time co-simulation would require a separate authority/conflict model. None of this is silently enabled or represented as completed. No hosting or paid service was activated.

## Reproducible examples

`docs/examples/Lumi.lgplanet`: seed-2026 automated opening interactions followed by actual simulation to tick 450 (15-minute normal-speed equivalent), public export. `Nacre.lgplanet`: independently generated seed-42 world, 120 ticks. These are development examples, not human planets or evidence of player retention. Import either without replacing the player's world.
