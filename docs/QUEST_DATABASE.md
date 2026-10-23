# Implemented quest database — First Flame

Canonical source: assets/kingdom/quests.json. **Five main quests, zero side quests in this slice**; the requested30+30 remains pending. Each has EN/TR title/description/objective labels, stable ID, level, chapter, prerequisite list, real objective predicates, navigation, explicit rewards and next link. Progress is realm-lifetime, so genuinely completed relevant work may satisfy later objectives. Only the current complete quest can be claimed, once; no menu or playtest assigns fake levels/currency.

| ID / realm | Quest | Actual objectives | Rewards | Next |
|---|---|---|---|---|
| main_01 / 1 | Awakening / Uyanış | Meet the settlers: 1; Gather wood: 6 | 40 xp, 12 wood, 3 gold | main_02 |
| main_02 / 2 | A Place to Live / Yaşanacak Bir Yer | Finish a Lumber Camp: 1; Produce wood with a lumberjack: 4 | 80 xp, 10 wood, 4 stone | main_03 |
| main_03 / 3 | Seeds of Civilization / Uygarlığın Tohumları | Finish a farm: 1; Harvest food with a farmer: 6 | 120 xp, 12 wood, 4 stone, 3 gold | main_04 |
| main_04 / 4 | The First Workers / İlk İşçiler | Recruit a paid citizen: 1; Build a Hearth House: 1 | 160 xp, 12 wood, 4 stone, 3 gold | main_05 |
| main_05 / 5 | Birth of a Village / Bir Köyün Doğuşu | Finish the Council Hall: 1; Reach development tier 2: 2 | 200 xp, 20 wood, 8 stone, 5 gold | Chapter I complete |


Building objectives require completed construction (previous levels remain valid during upgrade). Production means actual assigned work consuming local resources. Village tier2 derives from a completed hall/house/farm/camp, at least4citizens,6real residents,8food and0.6trust. Arin may be hidden/replayed; no campaign dialogue blocks repeated observation. UI clearly ends this chapter after quest5.
