# Enemy animation audit — V4B checkpoint

The representative existing Wildwood enemies are Wolf, Thorn Beast and Spider, with later Iron Hills, desert and Sanctuary variants present in E3. Their authoritative movement, warning timers, HP, loot and region rules remain covered by retained tests.

This slice does not replace enemy art or animation. Wolf/thorn/spider still use existing SVGs and modest procedural rotation. Wolf closes to bite range before a warning; Thorn has a slower heavier strike; Spider locks a landing point but changes position at the end of its windup. An actual airborne visual/model phase is not implemented. Later enemies are not treated as new content.

The rendered Warrior hit test uses the real Wolf model and existing art. It verifies damage feedback, not a finished Wolf reaction animation. V4E requires three distinct animated enemy sets with chase/windup/execution/reaction/defeat evidence. That work remains pending.
