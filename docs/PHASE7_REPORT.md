# Phase 7 delivery report

LittleGod 0.7 adds a real optional local online universe to the existing 0.6 game. The backend is ASP.NET Core 10 / Identity / EF Core / PostgreSQL; the game uses asynchronous HTTP and retains the original offline simulation, artwork and v1 saves. The 0.6 Git tag/source/APK were retained before major changes.

Completed: optional private-username accounts, protected access/renewal tickets, explicit public-profile edits and avatar choices, account deletion/logout, exact-code friendships and blocking, consent-based versioned planet publishing/unpublishing, real read-only friend visits, friendly delivered reactions, opt-in discovery/terrain previews and real persisted activity. No external push, free-text chat, fabricated players/activity or realtime multiplayer is implemented. Online worlds remain snapshots; own-world progress is independent. The small cache is memory-only and requires new authorization before each visit.

The local API ran against actual PostgreSQL 17.11 using vendor-verified portable binaries; Docker Desktop could not start its Inference manager. The supplied Compose/Dockerfile stack is not falsely reported as executed. Migrations actually ran in PostgreSQL, restart migration was safe, and idempotent SQL plus generated OpenAPI are delivered. Authentication uses maintained framework components, not custom cryptography. See SECURITY_REVIEW.md for threat model, tested controls and public-hosting gaps.

Validation: 295 game checks, 40 balance scenarios, 21 .NET tests, 65 real API checks, 6 security checks, 34 Windows client/server checks, 34 Android client/server checks, 5 actual-server-stopped Android checks, 26 existing Android checks and 3 native-file checks. APK update preserved all four player save/settings files. The native Android account/visit flow is exercised by the debug harness; broader human keyboard/accessibility testing remains. No physical phone, external beta or public hosting is claimed.

| Scenario | Average FPS | p95 frame ms | First engine frame ms |
|---|---:|---:|---:|
| Windows source, 15 s | 60.09 | 16.88 | 1564 |
| Android emulator normal, 30 s | 33.87 | 35.11 | 2392 |
| Android emulator saver, 20 s | 29.97 | 35.07 | 2440 |
| Android emulator 70 creatures, 20 s | 29.38 | 42.36 | 2340 |

Snapshot download 61520 bytes; emulator fetch 1014.3 ms versus Windows 80.8 ms. Local API median/p95 24.19/93.79 ms over all integration requests, including password hashing. Online calls do not block simulation or run in background. API-unreachable tests demonstrate continued play rather than treating a mock as proof. UI and rendering costs remain bounded; maximum-population 60 FPS, battery, thermal and mid-range-phone claims require physical testing. No causal performance improvement is inferred from different host workloads.

Visual inspection found and corrected a stale local-reaction label, repetitive portraits, short dropdown touch targets and off-center terrain previews. New art is the original online SVG and a procedural map of actual public terrain; existing painted assets remain. See screenshots/phase7-visit.png, phase7-friends.png, phase7-profile.png, phase7-creature.png, phase7-inbox.png, phase7-discovery.png, phase7-home-tr.png and phase7-android-world.png. All are rendered game captures; QA names identify temporary automated worlds.

Artifacts/launch paths and exact APK SHA256 are in STATUS.md. The source ZIP is generated from the verified littlegod-0.7 tag and excludes secrets/generated files. Known issues include Docker startup, no public endpoint/OAuth/recovery, process-local limits, development database/key operational hardening, no independent security/human review, hardware gaps and existing exit cleanup warnings. No paid services, security bypasses or publishing were performed.

Late repeated profiles slowed despite no active editor/test game. A preserved 0.6 APK installed with -r -d then measured 33.14 FPS / 35.32 ms p95; restoring the final 0.7 APK measured 33.87 / 35.11. Both benchmark runs preserve the player save, and the final 0.7 update preserves all four files. An earlier 0.7 candidate measured 57.61 FPS (21.995 ms p95), saver 30.00 and stress 47.09 before the final navigation guard; that earlier APK is not substituted for the release measurements. This matched late control does not show an online-feature FPS regression, and does not isolate the host/emulator slowdown. NVIDIA was observed in P8/210 MHz during the late control; no power/security setting was changed and no causal claim is made from that observation. Stable normal/max-population 60 FPS remains unresolved in this late host state. Battery saver stays near 30.
