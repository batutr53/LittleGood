# Combat animation timelines — current model audit

This slice deliberately preserves `adventure.gd` and the save schema.

| Action | Authoritative behavior | V4B presentation |
|---|---|---|
| Ordinary attack | Immediate range/direction check;500ms cooldown;200ms swing flag | Contact pose at swing200; follow-through/recovery at150/100/50; no false delayed anticipation |
| Heavy strike | Immediate circular105-unit check; skill cooldown4000ms | Same generic sword fallback; dedicated heavy choreography pending |
| Dodge |250ms dash,300ms invulnerability,1200ms cooldown | Six directional crouch/travel/recovery cells selected by remaining dash |
| Hurt | Model HP loss,250ms invulnerability |150ms reaction; never extends immunity |
| Defeat | Model prevents further actions at zero HP | Highest-priority six-frame kneeling sequence, final held pose |
| Walk | Real CharacterBody2D displacement at existing speed | Distance-driven foot cycle; blocked/zero movement uses idle |

Presentation priority: defeat → dodge → hurt → swing → actual movement → idle. The model's legal action rules still apply independently. Pause freezes the model and therefore animation clock. Scene exit destroys presentation nodes; no new hitbox or damage scheduler exists.

These are not final V4C timings. There is no added authoritative windup or active interval in this delivery. The old slash effect and its model-region mismatch remain an audited follow-up. F8 shows the actual pose's weapon segment and damage feedback coordinates, not proof of blade/target intersection.
