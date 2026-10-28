# Arin conversation — intermediate R2 implementation

The existing elder Arin is anchored next to the original settlement. His
original portrait is reused; the marker is `?` when the actual current chapter
is claimable, otherwise `!` for guidance. He is a functional adviser, not an
extra production worker. No new worker/hero identity or save field is created.

Tapping Arin opens the existing `journey` route as a readable bottom dialogue
surface. It shows his portrait/name, current authoritative advice, current
chapter when present, next action, workers/equipment/hunt routes and close.
Claimable chapter rewards call existing `Kingdom.claim` and checkpoint. The
claim command rejects stale/already claimed chapter IDs. Previously completed
quests are not reset or replayed.

Controls use 48 logical-pixel minimum heights and text at 15–20 logical pixels,
scaled by the existing accessibility preference. A fixed header close remains
reachable when content needs scrolling. Both TR/EN are rendered at 320×568,
360×800, 393×852, 412×915, 800×1280 and 1280×720. This validates this dialogue,
not the rest of the portrait game or physical dp sizing.

State currently covers opening, speaking, selecting a real route and closing.
It does not yet provide the full requested quest-acceptance conversation graph,
multiple NPC roles, hero approach radius or per-NPC minimap guidance. Home hero
movement remains a separate unfinished Reforge workstream. Normal dialogue uses
the existing home economy clock without granting unrelated world input.
