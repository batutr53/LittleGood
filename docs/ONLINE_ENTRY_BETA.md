# Account entry and live cooperative beta — 28 October 2026

## Live endpoint and player flow

**https://31.42.127.79:8443** is deployed and reachable from the internet. `/health` returns 200 with normal TLS validation. Android's default endpoint is this address; the app never asks players to create a planet in its main entry flow.

1. Open LittleGod: original fantasy artwork fills the boot/login screen immediately, with readable game tips.
2. Create an account or sign in using the existing Identity account API. Passwords and session tokens are not persisted by the game.
3. Choose **Hearth · İlk Krallık**. This is one real cooperative beta realm, with a configured cap of 32 connections, not a fabricated multi-server list.
4. Choose Warrior, Priest, Mage or Rogue and create a named first character. Character ownership, names and initial class are stored in PostgreSQL.
5. **Şehrime git** opens a private city save bound to the account and realm character. **Ortak ava katıl** joins the actual shared hunting clearing.
6. Movement, enemy HP, attack range/cooldowns, mana, damage, death/respawn, XP and essence are computed by the server. Clients transmit movement/action intent, never reward amounts or authoritative positions.
7. Complete three hunts and spend three earned essence to recruit another class. Repeating the same recruitment does not charge twice. Select an unlocked class as leader outside combat; the other recruited classes follow as companions. Companions provide small attacks and Priest healing while their leader fights. Changes/recruitment are rejected during an active shared hunt.

The starter city is created internally from the server's seed. Existing device saves retain a separate **Cihazdaki kayda devam** entry; they are not uploaded, overwritten or silently merged into the online economy. Existing offline characters remain accessible. Account cities get an additive `realm_entry` class-access extension; no legacy save loses already-open classes.

## Implemented server and transport

ASP.NET Core Identity and the existing friends/chat API are extended, not replaced. The new EF migration adds realm characters, one-use short-lived ticket hashes and a reward ledger. WebSocket `/play` authenticates its first frame with a 90-second single-use ticket; tokens are absent from the URL. Duplicate character sessions, oversized/malformed inputs, replayed sequences, impossible movement, unaffordable abilities and out-of-range hits are rejected. Intent traffic is limited per connection. Reward writes are transactional/idempotent; the world retries failed writes before respawning the killed enemy.

The current implementation runs one realm instance and 10 simulation ticks per second. All clients see the same monsters and other players. It has an original simple 2D clearing with selected-enemy rings, target HP, HP/MP, attack/cast rings, XP/essence notices, mouse/keyboard controls and mobile stick/buttons. This is a working first multiplayer slice, not a complete MMO remake.

Assigned city work continues locally during a connected shared hunt and checkpoints on return. The city economy is still device-local; shared combat XP/essence and class unlocks are server-owned. Local campaign equipment, skills and XP are not treated as trusted online combat inputs. A lost connection asks the player to leave and rejoin; no silent replay of purchases or rewards is performed.

## Deployment actually performed

Remote host: Windows Server 2025, directory `C:\LittleGodBeta`.

| Component | Address / task |
| --- | --- |
| Public HTTPS/WSS | `31.42.127.79:8443` |
| API | `127.0.0.1:5087` · `LittleGodBetaApi` startup task |
| PostgreSQL 17.11 | `127.0.0.1:55437` · started by the API runner |
| Caddy 2.11.7 | `LittleGodBetaTls` startup task |
| IP certificate renewal | `LittleGodBetaRenew` daily task |
| Verified database backups | `LittleGodBetaBackup` daily task, protected `data\backups` |

The host's existing 443 NAT mapping belongs to a Linux service environment; it was preserved. Existing IIS/other applications were preserved. Only `.well-known/acme-challenge` on the default IIS site was added for HTTP certificate validation; its own extensionless MIME configuration is scoped to that directory. The first attempt to bind host port 443 was rejected by the existing reservation; final deployment uses 8443.

Let's Encrypt issued a real IP SAN certificate, valid until **4 November 2026 08:37:22 UTC** at verification. TLS 1.3 and the public chain were verified without bypasses. Posh-ACME 4.35.0 obtains/renews the short-lived certificate; daily renewal/reload was run under SYSTEM and returned 0. The daily backup task also returned 0 and its pg_dump archive was checked with pg_restore --list. Renewal/check tasks use the server's configured timezone. API and TLS are running; a full machine reboot was not performed.

Deployment sources: `devtools/Deploy-WindowsBeta.ps1`, `Configure-BetaIpTls.ps1`, `Install-BetaBackup.ps1`. Upload the published API zip, official Caddy binary and Posh-ACME package to the scoped incoming folder, then run these scripts in order. Deployment secrets/private keys remain outside Git. No system security feature or certificate validation was disabled.

## Verification and artifacts

- Existing campaign chain: **822 checks**.
- Existing city/adventure migration, production and loot: **67 checks**.
- Existing native-mouse navigation: **61 checks**.
- .NET server unit tests: **63 checks**.
- Public internet HTTP/PostgreSQL plus two concurrent WSS peers: **26 checks**. Covers ownership, rewards, class recruitment, companions, replay/teleport rejection and malformed input.
- Real rendered desktop Godot with two authenticated connections to the public server: **40 checks**, native mouse login/realm/class/recruitment buttons, 960×540 and 1600×720 layouts. A movement/attack-intent bot earned three real hunts; no reward/XP injection.
- Android emulator against the public IP: **14 checks, seven external ADB taps**, plus **three fresh-process save checks**. Both production and QA packages' player files were preserved. Physical phone was absent.

Internet tests exposed fixed-delay and fixed-spawn assumptions in the test harness; it now waits for both named peers and compares rejected movement to the actual starting position. A previous desktop run also hit a creation failure; the harness now exits cleanly instead of dereferencing an absent character. Final public runs pass. Existing desktop ObjectDB/resource shutdown warnings remain; final Android logs have no script errors/fatal exceptions. No sustained FPS or load-capacity certification is claimed.

Evidence: `docs/benchmarks/online-entry`, `docs/screenshots/lobby` and `docs/screenshots/entry`. Public TLS metadata is in `tls-health.json`; live tests and APK hashes have separate JSON reports.

APK version code **111**:

- Main: `D:/LittleGod/builds/android/LittleGod-Online-debug.apk`
- Phone download: [LittleGod Android debug APK](https://31.42.127.79:8443/downloads/LittleGod-Online-debug.apk), HTTP 200, 81,989,599 bytes; server SHA256 equals the local artifact.
- Isolated tested QA: `D:/LittleGod/builds/android/LittleGod-Online-QA-debug.apk`
- Desktop launcher: `D:/LittleGod/Launch LittleGod.cmd`
- Server health: `https://31.42.127.79:8443/health`

The main APK was exported and manifest-checked; emulator installation/interaction used the isolated QA package. No physical-phone install was performed.

## Remaining work

This beta is not full online kingdom warfare: no PvP, trade, guilds, player party invitations/leadership, authoritative city economy, server inventory/equipment adaptation, persistent monster positions or cross-device city sync. Newly recruited classes are AI companions, not separately controlled local players. The shared clearing has two repeatable wolf spawns and a small beta reward rule; it does not yet host every campaign map/boss or the complete skill/item tables. Character artwork uses the existing class images with modest effect rings; full production animation remains incomplete. The 32-player limit is a bound, not a 32-user load-test result. Backups currently accumulate and require disk monitoring/retention planning. Tokens remain in memory, so players sign in after restarting. Public beta operations, moderation and recovery workflows need further work before a broad launch.

## Art and reference

New original bitmap: `assets/lobby/kingdom-dawn-v1.png`, generated with the built-in imagegen tool. Prompt: original landscape fantasy MMORPG backdrop; silver/gold warrior and crimson cloak, priest, rogue and mage overlooking a river kingdom at dawn; right third quiet dark navy for login; no text/logos/buttons or copied game insignia. Inspected in Godot and used for both boot and login.

Account → realm → hero creation flow was compared with [Knight Online's official character-creation guide](https://www.nttgame.com/knight/en/guide/installation). IP certificate deployment follows [Let's Encrypt's IP certificate availability](https://letsencrypt.org/2026/01/15/6day-and-ip-general-availability) and [Posh-ACME documentation](https://poshac.me/docs/v4/Functions/New-PACertificate/).
