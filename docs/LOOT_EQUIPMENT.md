# Loot and equipment — Milestone C

The existing32-item capacity includes queued work; the forge queue remains4 jobs. Unique equipment/potions use the original monotonic industry item IDs. Equipment references inventory instances; there is no parallel item store. Materials use integer thousandths in canonical kingdom stock. Adventure cargo stores whole units until an actual Home transfer; each material pickup checks the10000-unit common-stock limit. Save validation rejects unknown resources/recipes, incompatible owners, duplicate actors/drop IDs, negative balances and malformed records.

Enemy drops have deterministic persisted weighted tables plus a guaranteed useful material. Wolf supplies leather, Thorn Beast thornhide, Spider herbs; secondary tables include gold/iron/herbs. The chest has gold and a real shield. Opening it and harvesting the three-herb plant are once per expedition. Drops retain their unique ID and taken bit, so duplicate pickup calls and reloads cannot claim them again. Full inventory leaves equipment on the ground and explains the blocked pickup. Blue equipment/gold heart glows distinguish important drops.

| Recipe | Realm | Actual cost | Effect |
|---|---:|---|---|
| Iron Sword |11|2 iron,1 wood|+8 attack|
| Reinforced Shield |11|2 iron,2 wood|+3 defense|
| Trailguard Armor |13|2 leather,1 iron|+4 defense|
| Herbal Draught |13|1 herb,1 wood|35-health single-use potion|
| Thornhide Blade |14|2 thornhide,2 iron,1 leather|+16 attack|
| Heart of Wildwood |15|1 living heart,1 iron|+20 maximum health,+2 attack|

All recipes use the existing forge, paid inputs, finished-building conditions and assigned smith labor. Four labor ticks are required; menus/adventure pause kingdom work. The recipe screen previews cost/effect; Hero Hall compares effective stats. Materials and retained civilian tools remain usable. No durability, item sale, salvage, crafting cancellation or discard was added; finite inventory management is a known limitation.

The living heart has one meaningful artifact consumer. First victory creates one; collection plus Home records its real return. Quest15 cannot be completed using unrelated earlier loot pickups.
