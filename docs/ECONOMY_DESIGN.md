# Stardust — finite rewards for caring and discovering

Stardust (Yıldıztozu) unlocks appearance only. Spirit, simulation, food, weather, species, community growth and power costs are unchanged. No login reward, click farming, paid currency, loot boxes, paid randomization, expiry, streak or missed-day penalty exists.

| Durable accomplishment | One-time reward | Maximum |
|---|---:|---:|
| Welcome | 35 | 35 |
| Discover each of six species | 20 | 120 |
| Each of four world stories | 25 | 100 |
| Each of three rare phenomena | 35 | 105 |
| Reach community stage 0, 1, 2 | 25 | 75 |
| First cultural landmark | 50 | 50 |
| Restoration: two successful gifts and three lush, moist cells | 40 | 40 |
| Total lifetime for this catalog | | 525 |

The catalog costs 450 in total, leaving a maximum reserve of 75. Starter flowers, stones and Enchanted Forest are owned immediately. Early decorations cost 10–30; advanced themes cost 40/50/65. Themes also require real observation/story/community progress. Placement is reusable and free after ownership; storing never consumes or refunds an item. Repeated community creation, events, offline reports or loading cannot claim the same reward key again.

`wardrobe.version=1` stores claimed keys, earned/spent totals, balance, owned IDs, favorites, equipment, bounded placements and individual coats. Validation checks exact totals against defined rewards and owned catalog prices, nonnegative balance and unique ownership. Confirmation is explicit; duplicate purchases return false without spending. All operations are serialized on the game thread. This local soft economy is not tamper-proof DRM or a server bank: editing a private save is outside the legitimate-flow guarantee. Public snapshots omit all economy data and never grant inventory.

Thirty deterministic simulations cover five seeds × 60/450/480 ticks × active/passive styles, real ecosystem/community rules, repeated reward/buy loops and atomic save/load. No failures. At normal 1×, 60 active ticks represent two minutes and 450 fifteen minutes; these are accelerated simulation scenarios, not timed human playtests. Active two-minute scenarios unlocked 16–16 cosmetics after the test's deterministic shopping pass. Fifteen-minute active scenarios owned 23–23; this suggests generous early collection pacing, requiring human feedback. The 480-tick case also exercises the offline cap; offline ticks represent a different time scale.

Old saves receive the welcome wardrobe on migration, then only milestones still evidenced by stored world state. The actual tagged 0.7 fixture was produced with the original 0.7 scripts, not a newly generated 0.8 stand-in. Offline completion reconciles rewards once. Primary, backup and interrupted temporary-save recovery are tested. Forward compatibility with downgrading clients is not promised; keep a backup before downgrading.

Rewards stop when the finite objectives are exhausted. Reusable decoration remains unlimited within 32 concurrent placed pieces. Future catalog expansion needs a new explicit earn/spend budget rather than daily grind. Rare-condition clarity, two-minute generosity and long-term value are beta questions, not validated retention or willingness to pay.
