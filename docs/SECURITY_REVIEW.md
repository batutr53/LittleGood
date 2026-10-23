# Local beta threat model — 0.7

This is an implementation review and automated boundary testing, not an independent penetration test or approval for public production. No public deployment, third-party telemetry, free-text chat or paid service was activated.

| Threat | Implemented control | Remaining limitation |
|---|---|---|
| Unauthorized planet access | Every profile/showcase/visit/reaction route checks actor, both visibility layers, friendships and reciprocal blocks; discovery filters independently; old versions have no endpoint | A recipient can retain a previously viewed snapshot or screenshot |
| Account takeover | Maintained Identity password hashing, lockout after five failures for ten minutes, protected short access/8h renewal tickets, security stamp validation each request, server-side logout/deletion revocation | Local beta has no recovery email, MFA UI, OAuth or device-session management; HTTPS termination is required before hosting |
| Enumeration/invitation abuse | Exact random GUID invitation codes, generic registration/login responses, dummy password hashing for unknown/duplicate identities, no username-search/list API, bounded friend relations | Timing equality is not formally proven; distributed abuse needs deployment-specific edge limits |
| Malicious snapshot | Exact public schema, byte/depth/count/range/reference limits, known event enums, safe strings, no resources/scripts/remote images, revalidation in Godot | Manually chosen public names still require content reporting/moderation before broad beta |
| Excessive traffic | 120 requests/minute per authenticated actor or unauthenticated IP; auth 20/IP/minute, writes 20/actor/minute, zero queued requests; password and response size bounds | Rate-limit state is process-local; suitable for one local instance, not a distributed deployment |
| Private data exposure | Explicit projection, no silent upload, public DTOs omit login names/internal IDs, profile and showcase visibility, no stored client tokens, no body/token logging, endpoint query credentials refused | Operators can access database; development backups need host protection and a retention policy |
| Account deletion | Identity deletion cascades profiles, connections, blocks, versions, reactions and actor/recipient activity; existing tokens fail | No hosted backup deletion policy exists because hosting is not configured |
| Local secret theft | Random ignored environment secret, current-user Windows ACL, DPAPI-protected API keys, loopback listeners; database has no Docker host port | Host administrators/debuggers can inspect memory; Docker key volume and development DB bootstrap role need hardening before hosting |
| Network failure | Optional asynchronous transport, timeout and one renewal retry, separate private saves, read-only visits, no launch/polling dependency | Previously viewed online planets require reauthorization rather than exposing private cached data offline |

CORS is not enabled: the native client does not need cross-origin browser access, and browsers receive no permissive origin policy. Do not enable wildcard credentialed CORS. The non-development API refuses HTTP; reverse proxies must terminate TLS and configure trusted forwarding explicitly before use. Request bodies are bounded before deserialization, with generic errors. EF sensitive-data logging is disabled. Do not enable HTTP body, Authorization header or raw request-query logging.

Local development HTTP is deliberately restricted to explicit loopback/emulator debug addresses. Do not point the debug client at an untrusted network, expose port 5087/55437, or use real reusable passwords for local QA. No Windows App Control or other security feature was disabled.

Future public-beta prerequisites: authorized hosting/domain/TLS, managed secrets and key protection, least-privilege runtime/migration roles, encrypted database backups with deletion retention, operational alerting, edge abuse protection, independent security review, user reporting/moderation, age/privacy/legal review, account recovery, and tested container execution. These are pending, not represented as functional public services.

## Phase 8 review scope

Public appearance uses bounded inert catalog IDs only; client and server reject unknown/premium IDs, paths and extra economy fields. Local earned currency is not a trusted premium entitlement. Production store verification is disabled with no mock opt-in; mock provider is excluded from client exports. The receipt schema enforces transaction uniqueness, owner FK/cascade and known states; EF State concurrency token and terminal revocation policy are included. SQL constraints were exercised against PostgreSQL with rollback. Final API/runtime and .NET execution were blocked by Windows App Control, so authorization/concurrency/new endpoint HTTP behavior remains pending execution on an approved host. No live store verification, webhooks, refunds feed or production security approval is claimed.
