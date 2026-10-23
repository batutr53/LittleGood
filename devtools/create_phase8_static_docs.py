from pathlib import Path
import json,subprocess
root=Path('D:/LittleGod');docs=root/'docs';out=root/'builds/phase8'
for name in ['STATUS','KNOWN_ISSUES','TEST_REPORT','ANDROID_TEST_REPORT','BETA_TEST_PLAN']:
 (docs/f'archive/phase7-{name}.md').write_bytes(subprocess.check_output(['git','show',f'littlegod-0.7:docs/{name}.md'],cwd=root))
def base(path):return subprocess.check_output(['git','show','littlegod-0.7:'+path.relative_to(root).as_posix()],cwd=root).decode('utf-8')
def write(name,text): (docs/name).write_text(text.strip()+'\n',encoding='utf-8')
items=json.loads((root/'assets/cosmetics/catalog.json').read_text(encoding='utf-8'))
lines=['# Cosmetic catalog — LittleGod 0.8','','24 original reusable SVG assets, 23 earnable cosmetics and one unavailable future store collection. Rarity describes collection value only. All items have English and Turkish names/descriptions in the shared `assets/cosmetics/catalog.json`; game and API use the same IDs.','','| ID | English / Türkçe | Category | Rarity | Stardust | Requirement |','|---|---|---|---|---:|---|']
for x in items:lines.append(f"| {x['id']} | {' / '.join(x['name'])} | {x['category']} | {x['rarity']} | {'Unavailable' if x['premium'] else x['price']} | {x['gate']} |")
lines+=['','`none`: no discovery gate; `species2`: two discovered species; `finding1`: one recorded story; `village1`: an existing community. Ownership remains after storing/unequipping. Village themes coordinate existing settlement palettes; banners, lanterns, statues and ruins are decorative, never functional population buildings.','', 'Enchanted Forest uses green atmosphere and moonlit vegetation; Crystal Paradise adds icy cyan/amethyst palette and floating prisms; Celestial Night uses indigo sky and orbiting stars; Ancient Kingdom adds amber light and gold motes. Terrain, water and settlement colors are coordinated while original painted biome/creature art remains. Sky ribbons/comets and the orbit frame are separately equipable.','', 'The 24 vector illustrations are generated reproducibly by `devtools/create_cosmetic_art.py`, rasterized by Godot at 128×128. World props share a 768×512 atlas to reduce GPU texture switches; UI previews retain the individual SVGs. Environment assets appear as real depth-sorted world props, not static concept art. Isometric facings mirror/foreshorten props rather than tilting upright trees sideways. Waterfalls require a boundary water tile. Creature colors, star accessory and harmless dreamer idle target real individual IDs.','', 'Premium collection `royal_pack` is metadata/preview only, excluded from valid local ownership and public appearance. No price, real-money purchase, fake completion or Stardust sale is enabled.']
write('COSMETIC_CATALOG.md','\n'.join(lines))
e=json.loads((out/'economy.json').read_text());active=[x for x in e['scenarios'] if x['ticks']==60 and x['interventions']];long=[x for x in e['scenarios'] if x['ticks']==450 and x['interventions']]
write('ECONOMY_DESIGN.md',f'''# Stardust — finite rewards for caring and discovering

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

Thirty deterministic simulations cover five seeds × 60/450/480 ticks × active/passive styles, real ecosystem/community rules, repeated reward/buy loops and atomic save/load. No failures. At normal 1×, 60 active ticks represent two minutes and 450 fifteen minutes; these are accelerated simulation scenarios, not timed human playtests. Active two-minute scenarios unlocked {min(x['owned'] for x in active)}–{max(x['owned'] for x in active)} cosmetics after the test's deterministic shopping pass. Fifteen-minute active scenarios owned {min(x['owned'] for x in long)}–{max(x['owned'] for x in long)}; this suggests generous early collection pacing, requiring human feedback. The 480-tick case also exercises the offline cap; offline ticks represent a different time scale.

Old saves receive the welcome wardrobe on migration, then only milestones still evidenced by stored world state. The actual tagged 0.7 fixture was produced with the original 0.7 scripts, not a newly generated 0.8 stand-in. Offline completion reconciles rewards once. Primary, backup and interrupted temporary-save recovery are tested. Forward compatibility with downgrading clients is not promised; keep a backup before downgrading.

Rewards stop when the finite objectives are exhausted. Reusable decoration remains unlimited within 32 concurrent placed pieces. Future catalog expansion needs a new explicit earn/spend budget rather than daily grind. Rare-condition clarity, two-minute generosity and long-term value are beta questions, not validated retention or willingness to pay.
''')
write('MONETIZATION_ARCHITECTURE.md','''# Purchase preparation — live payments disabled

Researched 2026-10-23. No store plugin, account, credential, SDK billing session or real purchase is active. The shop's future Astral Heirloom preview explicitly says unavailable; Restore reports unavailable. All four shipped themes are earnable. Premium appearance cannot be forged by adding a local ownership boolean or importing showcase data.

## Current boundary

`scripts/purchase_provider.gd` defines product/purchase/restore results, unavailable by default. `tests/mock_purchase_provider.gd` is an isolated automated-test double, marked test-only and excluded from client exports. It exercises pending, cancelled, failed, completed, idempotent repeated completion and revoked states; simulated grants never enter the production inventory.

ASP.NET `IStoreVerifier` returns trusted store/account/transaction/product/state data; production registration only uses `DisabledStoreVerifier`. There is no configuration switch that treats a client receipt or boolean as verified. `PurchaseService` checks the fixed product, bounds proof size, verifies through that interface, binds receipt ownership to the authenticated account, uses a database transaction and globally unique `(Store,Transaction)` key, and persists only trusted receipt metadata. Raw proofs are not logged/stored. State is an EF concurrency token. Completed ownership cannot be downgraded by stale pending/cancelled/failed callbacks; verified revocation is terminal. Conflicting concurrent writes require a deliberate retry. Account deletion cascades receipt rows.

| Endpoint under /api/v1, authenticated | Prepared behavior |
|---|---|
| GET /purchases/products | Versioned catalog, enabled=false |
| POST /purchases/verify | Bounded store/product/proof; disabled verifier returns 503, never a grant |
| GET /me/entitlements | Only this account's verified completed ledger rows |
| POST /purchases/restore | Returns own ledger plus storeReconciliation=unavailable; does not claim a store refresh |

Earned soft cosmetics stay local. No cloud save/inventory synchronization is implemented. Future server entitlements are a separate ledger, never merged with Stardust ownership. Royal pack equipment is intentionally blocked until a real provider and authenticated entitlement consumer are implemented. No refund webhook, store-side restore, acknowledgement job or native adapter is currently implemented.

## Store adapters still required

[Godot's Android documentation](https://docs.godotengine.org/en/stable/tutorials/platform/android/android_in_app_purchases.html) describes the first-party GodotGooglePlayBilling plugin for Godot 4.2+ and requires Gradle builds. The present debug export uses standard non-Gradle templates. A future adapter must query store-localized product prices, handle connection/results and send proof to the verifier. Google requires backend verification before entitlement grants; pending purchases must not grant ownership, and acknowledgement/voided purchase processing must be implemented. Follow the [official billing security guidance](https://developer.android.com/google/play/billing/security).

The Godot SDK integrations [StoreKit 2 plugin](https://github.com/godot-sdk-integrations/godot-storekit2) targets Apple's StoreKit 2 API; its upstream maturity/version compatibility must be checked and pinned before integration. Existing Godot iOS InAppStore plugins are another integration surface, not a substitute for platform verification. A future Apple adapter must verify signed transactions/account binding and reconcile current entitlements and refunds, with [App Store Server Notifications](https://developer.apple.com/documentation/appstoreservernotifications). These are implementation prerequisites, not completed integrations.

External prerequisites: owner-authorized Google Play Console/App Store Connect developer accounts, configured non-consumable product IDs, app ownership/bundle IDs, Android signing key and test track/license testers, macOS/Xcode and Apple signing/provisioning, sandbox testers, server-side store credentials and trusted verification libraries, authorized HTTPS hosting and authenticated notification processing, acknowledgement/reconciliation jobs and independent security review. None were purchased/requested/created here. Product ID reserved: `org.littlegod.cosmetics.astral_heirloom.v1`.

## Verification limits

The game mock/disabled-provider checks pass. Backend source compiles and contains 42 test cases (21 prior, 21 additions). A final Release test attempt was blocked by Windows App Control loading LittleGod.Tests.dll; native API startup was also blocked. Do not treat its exit-0/no-tests output as a passing run. The new HTTP endpoints, EF concurrency flow and real store adapters have no final live HTTP/store verification. PostgreSQL migration/idempotency and database constraints were tested separately through the existing verified PostgreSQL tools; that is not an HTTP purchase test. No security setting was changed or bypassed. The earlier 65 real 0.7 API checks were rerun before these backend changes; they remain baseline evidence only.
''')
write('CUSTOMIZATION_FEEDBACK.md','''# Optional 0.8 closed-beta feedback

Date / anonymous tester ID / device model / Android version / refresh rate / build hash / prior game experience:

Observe the first two minutes without coaching. Can the player create a planet, cast a gift, inspect a creature, find the atelier and explain Stardust? Note hesitation and unintended taps. Then offer optional tasks: place and rotate flowers; move/store/undo/redo; unlock one affordable item after reviewing its cost; equip a theme; personalize a named favorite creature; save/reopen; export a showcase or postcard and inspect it locally. Avoid suggesting a favorite theme before asking.

1. What did you enjoy changing, and what felt awkward?
2. What earns Stardust? Did the first reward or price surprise you?
3. Rate decoration touch comfort, preview accuracy, undo confidence, visual clarity and shop clarity separately from 1–5. Explain low scores.
4. Which of the four themes do you prefer, and why? Which would you never use?
5. Did any decoration obscure a creature, village or important action?
6. What does the unavailable premium label mean? Was anything mistaken for a working payment?
7. Would you choose to export/share this world? What would you hide before sharing?
8. Would you voluntarily pay for cosmetic content in a finished game? Why or why not? An answer is an opinion, not proven purchase demand. No payment is offered.
9. Would you choose to revisit tomorrow? What would you want to change next?
10. Record startup delay, visible hitches, battery/heat concerns, crashes and reproduction steps. Do not submit account passwords, tokens or private save files.

Consent to optional follow-up and permission to retain anonymous feedback must be obtained by the human organizer. Share feedback manually; diagnostics do not upload. Human participants and monetization demand measured so far: zero.
''')
old=(docs/'archive/phase7-BETA_TEST_PLAN.md').read_text(encoding='utf-8')
write('BETA_TEST_PLAN.md','''# Closed beta — LittleGod 0.8 customization candidate

Current package: `D:/LittleGod/builds/android/LittleGod-0.8-debug.apk`; source launcher `D:/LittleGod/Launch LittleGod.cmd`. Update the existing player package with install -r; never clear/uninstall it to test an update. Keep a private backup before a downgrade. No physical phone or human participant was available in this run.

Use CUSTOMIZATION_FEEDBACK.md for the optional 10–20-person test. Allocate two minutes for uncoached first use and 10–15 minutes for decorating, inventory/shop comprehension, creature attachment, theme preference and local sharing. Include portrait devices with different notches/scales, mid-range hardware, actual two-finger pinch, haptic/audio and accessibility checks. Record measured results, including criticism, without turning opinions into validated demand or retention statistics. No recruitment, notifications or sharing with others was performed.

The offline customization loop and export/visit fallback work without a server. Online v2 cosmetics and prepared purchase endpoints need a new live integration run on an authorized machine: Windows App Control blocked the updated API and .NET test assembly here. Do not bypass it. Preserve the last verified 0.7 evidence; do not expose local development services to external testers. Live payments remain disabled.

## Retained gameplay/online scenarios from 0.7

'''+old[old.index('Online testing'):])
p=docs/'ASSET_INVENTORY.md';p.write_text(base(p)+'''\n## Phase eight additions\n\n24 original 128×128 SVG assets, their shared 768×512 rendering atlas and the bilingual cosmetic catalog are in assets/cosmetics, reproducible with devtools/create_cosmetic_art.py. Four presentation palettes, stars/prisms/motes, sky ribbons and glints extend the existing shaders/procedural renderer. Original painted atlas, font licenses, simulation art and synthesized sound remain. No paid API, stock pack, copied commercial art or new raster service was used. Captures in docs/screenshots/phase8-* show actual rendered gameplay with a controlled QA collection, not player progression or concept art.\n''',encoding='utf-8')
p=docs/'API_DOCUMENTATION.md';s=base(p).replace("owner's exact public v1 document","owner's exact public v1 or v2 document");s+='''\n## 0.8 source extension and verification limit\n\nAPI envelope version remains 1. Snapshot version 2 adds exact `appearance={theme,sky,frame,placements,coats}`; limits are 32 unique cells/IDs and 100 creature looks, bounded indices, four facings and known non-premium catalog IDs. No economy/private inventory is accepted. Plain worlds still export v1. Old clients reject v2; there is no silent downgrade that discards decorations. The game validates/reconstructs local v2 visits; updated server validation compiles but final v2 HTTP publishing could not run because Windows App Control blocked the updated native API. API_SCHEMA.json is the retained generated Phase 7 schema, not newly generated endpoint evidence.\n\nPrepared authenticated purchase endpoints and exact limitations are in MONETIZATION_ARCHITECTURE.md. Products report disabled, verify fails closed, entitlements are owner-scoped and restore explicitly cannot reconcile a store. New database schema was applied twice and constraints tested with rolled-back fixtures. This is not live purchase validation.\n''';p.write_text(s,encoding='utf-8')
p=docs/'ONLINE_ARCHITECTURE.md';p.write_text(base(p)+'''\n## 0.8 compatibility\n\nShared assets/cosmetics/catalog.json is copied to the API output and publish directory. Docker build context is now the repository root so this shared contract is included; Compose remains unexecuted on this host. Snapshot v2 carries inert cosmetics while v1 remains supported. See API_DOCUMENTATION.md and MONETIZATION_ARCHITECTURE.md. Native updated API and final .NET test assembly are blocked by Windows App Control; no bypass was attempted. The previous real 0.7 flow and the 65-check pre-change baseline remain historical verification, not a new v2 end-to-end result. SQL migration/idempotency was separately verified on real PostgreSQL after a local backup.\n''',encoding='utf-8')
p=docs/'SECURITY_REVIEW.md';p.write_text(base(p)+'''\n## Phase 8 review scope\n\nPublic appearance uses bounded inert catalog IDs only; client and server reject unknown/premium IDs, paths and extra economy fields. Local earned currency is not a trusted premium entitlement. Production store verification is disabled with no mock opt-in; mock provider is excluded from client exports. The receipt schema enforces transaction uniqueness, owner FK/cascade and known states; EF State concurrency token and terminal revocation policy are included. SQL constraints were exercised against PostgreSQL with rollback. Final API/runtime and .NET execution were blocked by Windows App Control, so authorization/concurrency/new endpoint HTTP behavior remains pending execution on an approved host. No live store verification, webhooks, refunds feed or production security approval is claimed.\n''',encoding='utf-8')
p=root/'README.md';s=base(p).replace('LittleGod 0.7','LittleGod 0.8').replace('LittleGod-0.7-debug.apk','LittleGod-0.8-debug.apk').replace('No payment system, external analytics, public deployment or publishing is present.','Live payments are disabled. No external analytics, public deployment or store publication is configured.');s+='''\nOpen ☰ → Atelier & collection to browse earned Stardust cosmetics, previews, requirements and favorites. Flowers/stones are available immediately. Browse atelier unlocks with explicit confirmation; Decorate planet lets you preview, place, move, face, store and undo/redo up to 32 pieces. Drag/pinch still navigate. Creature profiles open individual wardrobes. Themes, skies and frames change presentation only. Future premium content is explicitly unavailable.\n\nThe updated API executable and final .NET test assembly were blocked by Windows App Control on this host. Do not bypass it. The game remains playable offline; current v2 online publishing requires verification on an authorized runtime. See docs/PHASE8_REPORT.md for exact tests, performance, screenshots and limitations.\n''';p.write_text(s,encoding='utf-8')
print('Static design, catalog, beta, asset, API and payment documents written; dynamic release report remains pending final evidence.')
