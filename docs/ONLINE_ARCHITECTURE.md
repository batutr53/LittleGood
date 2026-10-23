# Optional online universe — 0.7

The existing Godot simulation and version-one private saves remain authoritative on the device. No network request runs at launch, in simulation ticks or during autosave. Opening an online identity does not upload a world. The separate sharing screen reviews the public projection and requires Publish. Offline guest creation remains the first path through the game.

## Local development

Prerequisites: .NET 10 SDK; Docker Desktop with a working Linux engine, or the supplied Windows portable PostgreSQL setup. No service, account, paid infrastructure or public deployment is created.

From `D:\LittleGod`:

```powershell
# Supported native fallback, actually exercised on this machine:
.\devtools\setup_postgres.ps1
.\devtools\start_online.ps1
# Alternatively, when Docker works:
.\devtools\start_online.ps1 -Docker
```

Setup downloads the official EDB PostgreSQL 17.11-4 archive into ignored tools, checks its vendor-published SHA256, and extracts it. The native cluster listens only on 127.0.0.1:55437 with SCRAM authentication; no Windows service is installed. The API listens only on 127.0.0.1:5087. `server/.env` is generated with a cryptographic random password, ignored by Git and restricted to the current Windows user. `server/.local` holds the database and development keys. Preserve those directories to preserve online test data. Never include them in a source release.

Docker Compose has two services: PostgreSQL 17 and the API, persistent database/key volumes, health checks, and a loopback-only API port. PostgreSQL has **no published host port**. Docker execution on this machine is blocked by Docker Desktop's Inference manager startup error; native PostgreSQL supplies the real integration evidence. Compose configuration is provided, but a successful container run is not claimed.

In the game, Online universe → Connection settings: `http://127.0.0.1:5087` on Windows; `http://10.0.2.2:5087` on the standard Android emulator. Cleartext is allowed only for those exact debug addresses. Other configured servers require HTTPS. A release build requires HTTPS everywhere. No public endpoint is preconfigured. Account names are private usernames, not email addresses; no email is collected and local beta has no email recovery or external OAuth. Passwords require 12–128 characters. Tokens stay in memory; sign in again after restarting.

## Modular monolith

`server/LittleGod.Api`: ASP.NET Core 10 LTS, ASP.NET Identity, EF Core 10 / Npgsql, PostgreSQL. Auth.cs handles Identity credential/token operations; SocialService.cs owns visibility, relationships, publishing and reactions; Endpoints.cs maps DTOs and routes; UniverseDb.cs owns persistence. There are no queues, microservices, Redis, third-party tracking or push notifications.

Identity's maintained password hasher and Data Protection bearer authentication issue 15-minute access and 8-hour refresh tickets. Every authenticated request validates the security stamp against the database, so logout revokes existing access and renewal tickets. Windows keys are protected with current-user DPAPI; the Docker key volume requires host protection. Tokens are not JWTs and this API is not an OAuth server. OAuth integration remains pending provider credentials and a separately reviewed public deployment.

The database contains Identity accounts, profiles, canonical friendship pairs (pending/accepted and original sender), blocks, showcases, at most three showcase versions, one reaction per actor/owner, and bounded activity inboxes. Foreign keys cascade account deletion. A unique pair key and check constraint reject opposing/self/invalid friendship states. Profiles have unique random GUID invitation codes. No public endpoint exposes internal account IDs or private login names. EF queries are parameterized. Historical versions have no alternate public endpoint.

`Migrations/InitialUniverse` and `server/migrate.sql` create the schema. The local launcher enables MigrateOnStart; repeat startup applies only missing migrations. For a future hosted service, run the idempotent SQL using a separate migration role before application startup, disable auto-migration, and use a runtime role without DDL privileges. Development currently uses the bootstrap database role and is not an approved public-hosting configuration.

## Snapshot and visit boundaries

The API accepts the same exact inert `littlegod.showcase` v1 document as 0.6, with the full validation port in Snapshot.cs. Root/nested whitelists reject private or extra fields; 512 KiB snapshot cap, 528 KiB request cap, JSON depth 12, tile/creature/community limits, safe strings, known enums, finite ranges and reference checks apply. No arbitrary image URLs, scripts, resources, saves or filesystem paths are accepted. Client validation runs again before reconstruction. The server computes a content hash, revision and update timestamp. Identical publishing is idempotent. The public discovery score is biome variety + 3×rare discoveries + 2×monuments; terrain previews derive from the actual published tile coordinates and biomes. Both profile and showcase must be public to enter discovery.

The client uses a threaded HTTPRequest with a 6-second timeout, response byte cap and one renewal attempt after 401. There is no background polling or unbounded retry. An epoch rejects responses from a replaced session. Private cache entries are validated and capped at eight in memory, erased on logout and revoked access. Every new online visit reauthorizes/downloads; a cached snapshot is never used to bypass an unavailable server or revoked visibility. Cache is not persisted to the local showcase library or a save slot.

The existing main.visit_planet path reconstructs a new read-only world, checkpoints the player's world, retains the exact home world/RNG/camera/pause reference, and restores it on return. Models reject simulation, powers, rename, favorites, offline replay and saves in visits. Visitors can pan, zoom and inspect living records; this is a published snapshot with visual animation, not synchronized multiplayer. Previously downloaded data cannot be remotely erased from a recipient's memory or screenshots; visibility revocation prevents subsequent API access.

Activity is persisted for real requests, acceptances, reactions and friend publication updates. Reads do not create fake activity. One event per actor/kind/hour and 200 inbox entries limit spam. The inbox fetches only when opened; no push infrastructure or presence status is fabricated.

## Verification entry points

```powershell
dotnet test server/LittleGod.Tests
python devtools/test_online.py
tools/godot/Godot_v4.7.2-stable_win64_console.exe --path . --script tests/online_integration.gd
python devtools/android_online_validate.py
```

Python means the verified runtime described in STATUS.md if not available on PATH. These tests create disposable, clearly named QA identities against **real HTTP and PostgreSQL**, then delete them. Allow a fresh one-minute auth rate-limit window between repeated full suites; rejected automation is not a reason to loosen abuse controls. Android QA writes only the disposable betaqa package and QA save slots. Do not clear the player's package.

## 0.8 compatibility

Shared assets/cosmetics/catalog.json is copied to the API output and publish directory. Docker build context is now the repository root so this shared contract is included; Compose remains unexecuted on this host. Snapshot v2 carries inert cosmetics while v1 remains supported. See API_DOCUMENTATION.md and MONETIZATION_ARCHITECTURE.md. Native updated API and final .NET test assembly are blocked by Windows App Control; no bypass was attempted. The previous real 0.7 flow and the 65-check pre-change baseline remain historical verification, not a new v2 end-to-end result. SQL migration/idempotency was separately verified on real PostgreSQL after a local backup.
