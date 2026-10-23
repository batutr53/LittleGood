# Universe REST API v1

Local development base: `http://127.0.0.1:5087/api/v1`. Interactive clients may consume the generated OpenAPI document at `/openapi/v1.json` in Development; a captured schema is included with Phase 7 evidence. All bodies are JSON. Authenticated requests send `Authorization: Bearer <accessToken>`. No cookie authentication or CORS permission is needed by the native game.

## Identity

| Method and path | Body / behavior |
|---|---|
| POST /auth/register | `{account,password}`: private account name 4–64 ASCII letters/digits/`_.-`, password 12–128 characters. 202 has the same body for existing/new accounts; sign in separately. Invalid shape/length returns 400. No email recovery or OAuth claim. |
| POST /auth/login | `{account,password}` → maintained Identity `{tokenType,accessToken,expiresIn,refreshToken}`; generic 401 on failure/lockout. Access 15 minutes, renewal 8 hours. |
| POST /auth/refresh | `{refreshToken}` → fresh token response; protected ticket expiry and current security stamp required. |
| POST /auth/logout | Auth required, `{}`. 204 revokes the account's existing access and refresh tickets. |
| DELETE /me | Auth required. 204 deletes the identity and related online data; local save unaffected. |

Registration never returns tokens. The game stores tokens only in memory and clears the session on logout or restart. Renewal tickets follow ASP.NET Identity's built-in protected-ticket model; they are not a third-party OAuth or rotating device-session implementation. All-device stamp revocation applies on logout.

## Profiles and friendships

| Method and path | Behavior |
|---|---|
| GET /me | Own public profile DTO: `code,name,avatar,visibility`. |
| PUT /me/profile | `{name,avatar,visibility}`. Name 1–32 safe visible characters, avatar 0–5, visibility `private`, `friends`, or `public`. |
| GET /players/{code} | Visible public profile only; 404 for absent, private or blocked accounts. No private username/email/internal ID. |
| GET /friends?offset=0 | Up to 20 `{profile,state,incoming}` records and nullable `next` offset; maximum 100 relations per account. |
| POST /friends/{code} | `{}` sends an exact-code invitation. Idempotent if pair already exists. A known random invitation code intentionally allows requests to private profiles. |
| PUT /friends/{code}/accept | `{}` accepts an incoming pending request; sender cannot accept their own. |
| DELETE /friends/{code} | Reject/cancel/remove pair, idempotent. |
| PUT /blocks/{code} | `{}` blocks, removes pair/reactions/related activities, and denies access in both directions. |
| GET /blocks | Up to 100 own blocked profile code/name records. |
| DELETE /blocks/{code} | Unblock without restoring friendship. |

`code` is a random 32-lowercase-hex invitation identifier, deliberately public to recipients. There is no partial-name search or account listing. Private profiles remain private after accepting a friend; the owner must explicitly choose Friends visibility for profile visits.

## Planets, visits and reactions

| Method and path | Behavior |
|---|---|
| PUT /planets/showcase | `{snapshot,visibility}` publishes the authenticated owner's exact public v1 or v2 document; never accepts an owner field/private save. Returns `{version:1,status:"published"}`. |
| DELETE /planets/showcase | Deletes own showcase, retained versions and reactions. |
| GET /planets/{code}/showcase | Current accessible `{version:1,revision,updated,hash,snapshot}`. Both profile and showcase visibility apply, plus blocks. |
| POST /visits/{code} | `{}` rechecks visit authorization, 204; no fictitious engagement counter or real-time synchronization. |
| PUT /reactions/{code} | `{kind:0..3}` sets one real friend reaction: Beautiful World, Amazing Discovery, Lovely Creatures, Wonderful Civilization. Requires a visible published planet and current friendship. Repeated same value is idempotent. |
| GET /discovery?offset=0 | Up to 12 opted-in public profile/public showcase entries, nullable `next`, transparent `rule`. Each entry has profile name/avatar/code, planet name, revision/update/score and bounded `[x,y,biome]` terrain preview. |

See SOCIAL_ARCHITECTURE.md for the complete inert snapshot v1 schema and ONLINE_ARCHITECTURE.md for the dual server/client validation boundary. Requests cap at 540672 bytes; snapshots cap at 524288 bytes with depth 12 and bounded arrays. Identical content/visibility publishing does not advance the revision. Up to three versions are retained; no route exposes historical versions. Data is never loaded as a Godot resource or applied to a private save.

## Inbox and errors

GET `/notifications?before=<id>` returns up to 20 own activity records, newest first, with nullable `next`. Records contain id, predefined kind, read flag, creation time and actor's public name/code. PUT `/notifications/read` marks the authenticated recipient's inbox read. Real kinds: `friend_request`, `friend_accepted`, `planet_updated`, `planet_reaction`. At most one notification per actor/kind/hour and 200 retained per recipient. Fetches occur only on opening the inbox.

401: sign in/renew; 404: absent or inaccessible without distinguishing private existence; 400: invalid input; 409: conflicting concurrent update, refresh state before a deliberate retry; 413: body too large; 429: rate limit, wait for next minute window; 503: service/database unavailable. Some authorization failures have an empty body. Application validation errors use `{error:<stable_code>}` without exception or credential detail. The client uses status codes, generic localized feedback, a six-second timeout and one 401 renewal attempt, with no automatic write replay after network loss.

Limits: auth 20/IP/minute, writes 20/actor/minute, all routes 120/actor-or-unauthenticated-IP/minute. They are process-local for this single-instance development stack. Pagination validates offset bounds. No external push, user text comments, ranking based on fabricated activity, or public hosting is configured.

## 0.8 source extension and verification limit

API envelope version remains 1. Snapshot version 2 adds exact `appearance={theme,sky,frame,placements,coats}`; limits are 32 unique cells/IDs and 100 creature looks, bounded indices, four facings and known non-premium catalog IDs. No economy/private inventory is accepted. Plain worlds still export v1. Old clients reject v2; there is no silent downgrade that discards decorations. The game validates/reconstructs local v2 visits; updated server validation compiles but final v2 HTTP publishing could not run because Windows App Control blocked the updated native API. API_SCHEMA.json is the retained generated Phase 7 schema, not newly generated endpoint evidence.

Prepared authenticated purchase endpoints and exact limitations are in MONETIZATION_ARCHITECTURE.md. Products report disabled, verify fails closed, entitlements are owner-scoped and restore explicitly cannot reconcile a store. New database schema was applied twice and constraints tested with rolled-back fixtures. This is not live purchase validation.
