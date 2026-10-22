# Gameplay balance — LittleGod 0.5

Measured automated development, not human enjoyment or retention. Run `Godot_v4.7.2-stable_win64_console.exe --headless --path D:\LittleGod --script tests/balance.gd` from the bundled tools/godot directory (or use its full path). Raw evidence: `docs/benchmarks/phase5/balance.json`.

Five seeds (2026, 42, 7, 301, 99991), four durations and two conditions give **40 scenarios**. Interventions apply the existing blessing/rain powers and a deliberate neighboring mountain/forest experiment; controls evolve without gifts. Live 10-minute/hour scenarios run 300/1800 ticks at two simulated live seconds per tick. Offline 24-hour/seven-day cases run the existing 480-tick cap at one tick per real minute. No week-long human wait occurred.

| Scenario (10 cases each) | Creatures | People | Memories retained | Choir / silver fox / spring |
|---|---:|---:|---:|---|
| 10m | 16–24 | 38.8–44.8 | 28–38 | 4/10 · 0/10 · 5/10 |
| 1h | 46–58 | 320–320 | 64–64 | 9/10 · 9/10 · 5/10 |
| 24h_offline | 20–28 | 72.6–78.6 | 55–64 | 6/10 · 8/10 · 5/10 |
| 7d_offline | 20–28 | 72.6–78.6 | 55–64 | 6/10 · 8/10 · 5/10 |

All 40 worlds validate and survive transactional save/load with matching histories and population counts. No observed extinction; the core model preserves a six-creature floor and caps ordinary population at 70. Communities retain their 80-person cap and at most four settlements; cell resources and food are bounded at 100. These limits are deliberate guardrails, not evidence that every possible seed or intervention is balanced.

Tuning from evidence: the initial silver-fox threshold produced a discovery in all ten 10-minute cases. The final condition requires a patient fox with 360 cumulative healthy forest ticks, during a live lantern grove. Final 10-minute cases produce none; longer cases can develop the variant naturally. The choir requires an actual rain-to-clear transition, a well-watered bird location and at least tick 60. Springs are deterministic spatial experiments; all five intervention cases discover them and none of the untouched controls do. No unrelated XP payout was added for these secrets.

Two minutes: interactive first gift, a named creature and the early rain/observation loop. Five minutes: investigate a habitat, welcome wildlife, name/mark a subject and follow a clue. Fifteen minutes: combine terrain gifts, nurture a patient fox, inspect emerging landmarks or relationships, revisit the Chronicle and make a postcard. These are design opportunities exercised by automation, not measured human session lengths.

History stress checks rotate individual episodes at 64 cards/128 IDs and retain permanent firsts and rare/community memories. Offline highlights are filtered from actual newly recorded IDs and prioritize important changes. Twenty-four-hour and seven-day outcomes match because both reach the protective cap; the UI still reports the actual absence duration.

Remaining balance limits: food is generous, and hour-long cases reach four capped communities (320 people). The late economy/research tree is shallow; free creative interventions and new wildlife histories carry replay beyond that point. No grind or scarcity was added to conceal this limit. Human beta feedback should determine whether the early loop and later creative play are satisfying before adding content.
