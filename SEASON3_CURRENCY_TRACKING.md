# SEASON3_CURRENCY_TRACKING — honor & marks as gear-progress currency

Feature spec spanning all three Arena Armory repos (addon: this repo · desktop: ../arena-armory-desktop · site/API: ../wow-classic-armory). Goal: a claimed character's **honor + marks (+ arena points)** flow into arenaarmory.com and power a "what can I afford / what do I still need" view against the S3 gear lists — shipping the automatic path (addon → desktop → site) AND a manual-input fallback. Written 2026-08-02; target: v1 before **Sep 1** (S3 start) if it fits without jeopardizing the tbc-p3 BiS/guide content (which stays Priority 1 per ROADMAP.md); otherwise ship in the first S3 week — demand peaks all month.

## Why

S3 (Vengeful) gear costs arena points; Veteran's offset/medallions cost honor + marks. The Upgrades page already shows costs (data/pvpCosts.ts, extended for S3 per ROADMAP.md Priority 1). What's missing is the player's *balance* — with it, the page turns from a price list into a progress tracker ("8,240 / 14,750 honor for your remaining list"), which is a daily-return-visit feature during a season, exactly when ad traffic matters. Note Aug 18: leftover S2 arena points convert to honor (1:10) — balances will jump; snapshot timestamps matter.

## 1. Addon (wow-gladius) — currency snapshot

- New SavedVariables table (schema-versioned alongside the match recorder's): `ArenaArmoryCurrency = { [charKey] = { honor, arenaPoints, marks = { av, wsg, ab, eots }, updatedAt } }`. charKey = same `<realm-slug>_<name>` convention as matches.
- Capture on PLAYER_LOGOUT and after each arena match (both already-hooked moments): honor via `GetHonorCurrency()`, arena points via `GetArenaCurrency()`, marks via `GetItemCount(itemId, true)` (include bank) for WSG 20558 / AB 20559 / AV 20560 / EotS 29024 — **verify these item IDs against the 2.5.x Anniversary client before shipping.**
- The SavedVariables file is account-wide, so every character the account logs plays in — alts accumulate for free.
- Bump the recorder schema version; mirror the type in the desktop app's shared types.

## 2. Desktop app (arena-armory-desktop) — parse + upload

- Extend the SavedVariables parser for the new table; dedupe per charKey by `updatedAt`.
- Upload `POST /api/currency/import` with the existing bearer token (same auth as match import; idempotent by charKey+updatedAt).
- Optional small UI: a per-character currency row in the match table sidebar — nice, not blocking.

## 3. Site/API (wow-classic-armory) — storage, display, manual fallback

- Firestore `currencySnapshots/{charKey}`: `{ honor, arenaPoints, marks, updatedAt, source: 'addon' | 'manual', uploaderUid }`. Public-readable like match history (it's armory data); write via token (addon path) or authed claimed-character owner (manual path).
- `POST /api/currency/import` (token) · manual editing on /account for **claimed characters**: four number fields + save, stored `source:'manual'`. Conflict rule: newest `updatedAt` wins regardless of source; show "as of <time> via <addon|manual>" on display so stale data is self-explaining.
- **Affordability view** (the payoff), on the Upgrades page + character PvP tab: for the character's remaining S3 list (from pvpCosts.ts + BiS data), render have/need bars per currency and per-piece "affordable now" badges, plus a simple suggested purchase order (cheapest-first or biggest-upgrade-first — start with cheapest-first, iterate later). Manual-input CTA when no snapshot exists: "Add your balances or sync automatically with the desktop app" — the feature markets the desktop app.

## 4. Stretch (v2, explicitly NOT part of the Sep 1 push): enchanting mats / gems inventory

Concept: snapshot counts of a whitelist of S3-relevant gem/enchant mats (item IDs from the per-piece gem/enchant suggestions already on guides/Upgrades) the same way marks are counted; site totals them **across all snapshotted characters on the account** and diffs against the needed-mats list for remaining gear. Honest caveats to design around (Alex already spotted them): mats are not soulbound — they sit on alts (covered: account-wide SavedVariables), in banks (covered only when bank data is readable — `GetItemCount(id, true)` needs the bank cached; snapshot on bank-open event to refresh), in guild banks and mailboxes (NOT covered — state this in the UI), and counts drift the moment the user trades/AHs. So the comparison ships as *indicative* ("you appear to have ~held mats for 3 of 7 remaining enchants — excludes guild bank/mail"), never as exact. Keep the whitelist small (S3 list only). Build only after currency v1 proves the pattern.

## Sequencing vs the S3 clock

Priority 1 stays the tbc-p3 PvP BiS/vendor-cost content (ROADMAP.md). This feature is Priority 2 and intentionally sliced so each repo's change is small: addon table (~half day), desktop parse+upload (~half day), site import+display (~1–2 days), manual input (~half day), affordability bars (~1 day against existing cost data). The stretch (mats) has no deadline.

**Status 2026-08-02:** Site slice implemented in `wow-classic-armory` (API + /account manual + Upgrades affordability). Next: addon snapshot + desktop upload.
