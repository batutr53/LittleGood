# Purchase preparation — live payments disabled

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
