# D critical and E1 optional save records

After C's fifteen claims, explicit Chapter IV opt-in adds bounded `kingdom.military.version=1`; after twenty claims Chapter V adds `kingdom.trade.version=1`. Kingdom version stays3; world version, canonical workers, hero gear, unique inventory IDs and pending forge jobs remain. Unopted C/D saves are unchanged. New code reads the retained A/B/C fixtures and the authentic D fixture; older binaries are not promised to read newer optional records.

The authentic C fixture was generated at `f1684d9` before military code existed. D's fixture was generated at `38c7f0d` before trade code existed, with a genuinely queued potion. Generator guards prohibit relabeling a new save as an old fixture. Tests compare resources, equipment, hero/company and queues across opt-in and exact persistence. Earlier migration details remain in SAVE_MIGRATION_MILESTONE_C.md.

Military actor positions/windups/HP and caravan cargo/escrow/merchant/escort/supply/progress/outcome persist. Validation rejects duplicate reservations and inconsistent outcomes. Active battle/adventure keeps home/offline travel paused; ordinary offline routes reach escrow or await a hazard choice. Exactly-once collection and rewards are tested through real process restart. Salvage frees unused inventory at a staffed forge before E1, preserving pending jobs and equipped/army/artifact records.

Pending E1 quotes are checked against the route table. Future price changes require tested migration or a retained contract table; never invalidate or discard existing cargo to rebalance prices. See TRADE_SYSTEM.md, tests/military.gd and tests/trade.gd. All tests use private slots; Android package updates byte-compare player planet/backups/settings. No primary data is cleared.
