# Response: Ironforge.pro Competitive Brief — Review, Corrections, and Prioritized Plan

**Date:** 2026-08-08 · **Reviewed by:** Cowork session (code-verified against all 3 repos)
**Input:** `arena-armory-vs-ironforge-research-brief.md` (2026-08-07)
**Companion edits:** wow-gladius/ROADMAP.md ("Ironforge parity" block in Next up + revenue-plan amendment), C:\dev\PORTFOLIO_ROADMAP.md (Arena priorities, Key dates, THIS WEEK note)

## 1. Verdict

The brief's strategic read is right and matches the 2026-08-04 competitive research already in
wow-gladius/ROADMAP.md ("Competitive position & revenue plan"): don't chase the raid-census anchor;
copy the consumption-UX/habit playbook (leaderboards, archives, trend charts, omnipresent search,
snapshot pages); differentiate on match-level telemetry nobody else can capture. The 8 feature
candidates are the right list. What the brief gets wrong or misses — each verified against the
actual code, not assumed — changes the ordering and adds one hard date:

## 2. Where Ironforge's data actually comes from (the two-pipeline picture)

Ironforge runs on **two separate data pipelines**, and knowing which feature sits on which pipe
is the whole competitive map:

**Pipeline 1 — warcraftlogs.com (Warcraft Logs): the backbone of their anchor.** Their famous
population/census/demographics product — the thing that made them *the* citation for server-health
debates — is built on raid combat logs that players voluntarily upload to Warcraft Logs. Ironforge
counts unique characters appearing in those logs per weekly window (dedup roughly via first-boss
parses; a Blizzard-forum methodology thread confirms ~130K unique vs ~782K raw parses in one
example). For Anniversary they blend in characters seen on PvP leaderboards, per their own page
subtitle. What WCL gives them: realm/faction/class population, activity trends, the citation moat.
What WCL structurally CANNOT give them or anyone: arena ratings, arena matches, durations, comps,
or any player who neither raids-and-logs nor appears on the rated ladder.

**Pipeline 2 — Blizzard's PvP Leaderboard Game Data API: all of their arena product.** Ladders,
cutoffs, player rating histories, activity feeds, charts — everything under `/anniversary/` PvP
comes from snapshotting Blizzard's ladder endpoint and diffing over time (plus per-character
armory crawls for gear/talents/spec on player pages). WCL is not involved in their arena data.

**Why this matters for us:** the features we're competing on (§4's plan) all sit on Pipeline 2 —
which is public API + our own snapshot store, fully replicable. Pipeline 1 is their mature,
years-old moat, it's raid-centric, and the brief's §5 "don't chase the census" call stands.
**Should WE use warcraftlogs.com?** WCL has a public GraphQL API (v2, free tier, rate-limited) —
the same door Ironforge walked through — so a population product is *available* to us any time.
Deliberate call (unchanged from the brief): not this phase. It adds nothing to the PvP-destination
plan (WCL has no arena data), it's a second ingest pipeline to maintain solo, and our census would
be a me-too against their strongest, most-cited product. Revisit only if post-BlizzCon port
planning makes a population story strategic — logged in ROADMAP.md as an evaluated-and-parked
option, not an oversight.

## 3. Corrections & findings (code-verified 2026-08-08)

**(a) "We likely already hold the ratings data" — no, we don't.** There is zero leaderboard
ingestion anywhere in wow-classic-armory (`grep leaderboard` across api/lib/app/components/types:
no hits). Arena ratings come from Blizzard's per-character PvP summary, fetched on lookup
(`api/_lib/character.ts`), cached per character. A leaderboard needs a NEW ingest pipeline: verify
Blizzard's Game Data API pvp-leaderboard endpoint on the Anniversary dynamic namespace first
(~30-min spike; high confidence it exists — ironforge.pro and tbcpvpladder both serve this data),
fallback is a top-player crawl. This is the brief's #1 item but it is a pipeline build, not a UI
over data we hold.

**(b) HARD DATE THE BRIEF MISSED: Season 2 ends Aug 18.** Season archives (brief #5) start with
capturing S2 before it's gone — once the ladder resets for S3 (Sep 1 start), the S2 standings are
unrecoverable to us. The leaderboard ingest therefore has a deadline: built and snapshotting by
**Aug 17** at the latest. This slots exactly one day after the Aug 7–13 dev freeze lifts — it is
the first post-freeze task, not a freeze exception. If the ingest spike fails (no API endpoint),
decide fast on the crawl fallback; a partial S2 archive beats none.

**(c) Rating-over-time charts (brief #3) are partially shipped.** `components/RatingChart.tsx`
already draws rating trajectories from synced matches (custom react-native-svg — no charting
library needed, brief §8's question answered). The gap is only a 7d/30d/season range selector and
surfacing the chart on character/profile pages, not just /matches. Cheap, not a build.

**(d) Match detail pages (brief #8) are mostly shipped.** Public per-match pages with scoreboard,
event timeline, damage/healing charts, and death data exist; the addon already posts a post-match
chat link. Remaining gap is share polish: per-match OG/meta cards so links unfurl on
Discord/Reddit. Small.

**(e) Data-density reality check on the meta dashboard (brief #4).** KPI_LOG 8/7 baselines:
303 CurseForge downloads, 90 GA4 sessions/7d, 0 claimed web accounts, and the bulk of synced
matches are from one account (442). A public comp-winrate dashboard today would mostly be Alex's
own games wearing a trench coat — it would read as thin and hurt credibility, the opposite of the
"screenshotted on Reddit" goal. Split it: **spec/class representation at rating tiers is derivable
from the leaderboard ingest + top-N character lookups without any addon data** (this is how
Ironforge-class sites do it) and can ship credibly early; comp winrates / durations / first-death
patterns stay gated behind a minimum sample per cut (recommend n≥50 matches per comp/bracket cut,
tiles hidden below threshold, sample sizes always labeled). The moat framing stands — but the moat
compounds with install base, so the addon-data half of the dashboard is sequenced after the
traffic features that grow installs, not before.

**(f) Conflict with the standing AdSense pause — resolvable, needs one Alex click.** The
2026-08-04 revenue re-rank paused "public leaderboard pages" (revenue move #4) because more
templated pages would reinforce the "low value content" rejection before re-review. The brief
re-ranks leaderboards as the #1 parity gap. Both are right; reconcile with sequencing: **Alex
triggers the AdSense re-review now** (already unblocked since 8/5 — the 2 editorial /news pieces
were shipped exactly for this; it's a dashboard click), and leaderboard/archive pages ship
`noindex` until the re-review clears, then flip indexable. The product/habit value (return visits,
direct traffic — Ironforge's actual moat) doesn't depend on Google indexing; the SEO value arrives
when it's safe. Revenue move #4's blanket pause is superseded accordingly (amended in ROADMAP.md).

**(g) SEO/SSR state (brief §8): fine.** `app.json` has `"output": "static"` (pre-rendered pages),
per-page meta via `lib/seo.tsx`, sitemap generator + IndexNow submission scripts already in place.
Season-archive stable URLs will index properly. No framework work needed.

**(h) Persistent header search (brief #2): confirmed cheap.** Nav lives in `app/_layout.tsx`;
`lib/recentSearches.ts` + realm/character APIs already exist. A header search with typeahead is a
component + wiring, no new data.

**(i) Match data model (brief §8): fine at current volume, plan for aggregates later.** Matches
live in Firestore per character; all analytics today are client-computed (`lib/matchStats.ts`,
`matchupStats.ts`, etc.). That holds for per-character views at any realistic volume. The
sitewide meta dashboard should be a precomputed aggregate (scheduled job writing one summary doc
per bracket/period) rather than scanning matches at request time — a small job, not warehouse
work, at any volume we'll see this year.

**(j) Participation stats (brief #7) come nearly free.** Weekly ladder snapshots (needed anyway
for rank-change indicators and archives) directly yield "active rated participants per
realm/bracket/week" — the citable server-health-for-PvP stat and the backlink play. Ship it as a
small page once two snapshot weeks exist; no separate pipeline.

## 4. Prioritized plan

Respects the Aug 7–13 freeze (PORTFOLIO_REVIEW_2026-08.md): nothing here starts before **Aug 14**.
Arena is portfolio priority #1 through Sep 1; this is that Aug 14 – Sep 1 block, plus S3-window
follow-ons. Efforts are S (≤½ day), M (1–2 days), L (3+ days).

**P0 — Aug 14–17, hard deadline Aug 18 (S2 season end):**
1. **Leaderboard ingest + S2 snapshot** (M) — endpoint spike, then ingest 2s/3s/5s ladders per
   realm/region into Firestore with a dated-snapshot shape (design for diffs from day one:
   `{season, bracket, realm, capturedAt, entries[]}`). Snapshot daily through Aug 18; final
   pre-reset capture becomes the immutable **Season 2 archive** dataset. Everything else in this
   plan reads from this store.

**P1 — by Sep 1 (S3 launch day is the traffic spike; leaderboards live for the ladder race):**
2. **Leaderboard pages** (M) — /leaderboards: bracket tabs, realm/region/faction filters, sortable,
   rank-change vs previous snapshot. `noindex` until AdSense re-review clears (see 3f). From Sep 1,
   snapshot cadence continues, so trends exist from S3 day one — the aggregate-over-time view the
   community says Ironforge is weak on.
3. **Persistent header search** (S) — global nav typeahead on every page.
4. **Rating-chart time ranges + profile surfacing** (S) — 7d/30d/season selector on the existing
   RatingChart; render on character pages for claimed characters.

**P2 — early S3 (Sep):**
5. **Snapshot homepage** (M) — above the fold: search front and center, ladder top-5 per bracket,
   biggest movers this week, latest news; meta-comp-of-the-week slot added only when the density
   gate passes. Converts lookup tool → daily destination; do it once leaderboard data exists to
   feature.
6. **Season archive pages** (S–M) — /seasons/tbc-s2 (from the P0 capture) + auto-freeze S3 on
   future season ends; stable URLs, indexable post-re-review. Evergreen SEO + "I hit my rating in
   S2" proof pages.
7. **Spec representation at rating tiers** (M) — from ladder + top-N character crawls; no addon
   data needed; credible immediately. First half of the meta destination.
8. **Participation stats** (S) — active rated players per realm/bracket/week from snapshots; the
   citable stat (see 3j).

**P3 — when density gate passes (or gated per-cut from day one, clearly labeled):**
9. **Comp winrate / duration / meta dashboard** (M–L) — the true differentiator, from addon match
   data; precomputed aggregates; n≥50 per displayed cut, sample sizes shown. This is the
   Reddit-screenshot page — ship it when it can't be dismissed as one guy's match history.
10. **Match share polish** (S) — OG cards per match page; every shared match is addon acquisition.

**Explicitly NOT doing** (unchanged from existing strategy): raid-log census pipelines,
feature-chasing Ironforge into population dashboards, other game versions before the S3 read and
BlizzCon (Sep 12–13), Android, video training.

**Synergy note:** the paused premium tier's leading candidate ("population percentile
benchmarks") requires exactly this ladder ingest — P0 here is also the premium tier's data
prerequisite, so this plan advances revenue move #1 while it builds parity.

## 5. Answers to the brief's §8 questions (short form)

- **Ratings ingest today:** per-character on lookup only; no ladder pipeline (see 3a). Leaderboards need the new P0 ingest.
- **Match data model:** Firestore per-character docs; client-computed stats; fine per-character, add a precomputed-aggregate job for sitewide meta (3i).
- **Roadmap overlaps:** leaderboard pages = paused revenue move #4 (now superseded, 3f); meta pages relate to paused move #3 (the per-spec gear/talent programmatic pages stay paused — different thing from the comp dashboard); rating charts + match pages partially shipped (3c, 3d); archives/search/homepage/participation are net-new.
- **Install base / density:** 303 addon downloads, ~1 real uploading account — below any credible aggregate threshold; gate per 3e.
- **Charting & header search:** custom RN-SVG charts already exist, no library decision needed; header search is cheap (3h).
- **SEO state:** static output + sitemap + IndexNow already in place (3g); the archive play works.

## 6. Success metrics (adopting brief §9, with baselines)

Baselines 8/7 (KPI_LOG.md): 303 addon installs · 90 GA4 sessions/7d · 0 claimed accounts.
Track weekly in KPI_LOG.md: returning-visitor share on /leaderboards + /meta pages, addon installs
and weekly synced-match volume, organic landings on leaderboard/archive pages (post-index),
citations (Reddit/Discord links to our pages vs Ironforge's for Anniversary PvP topics).

## 7. Addendum — full Ironforge.pro surface review (2026-08-08, later, from Alex's links)

Alex's pushback, accepted: the first pass under-inventoried what Ironforge actually ships for
Anniversary. Their pages are a client-rendered app (unreadable to plain fetches), so this
inventory was first built from the URL surface plus forum sourcing, then **verified against
Alex's screenshots of all five pages (2026-08-08)**. One clarification first: §2a's "we don't
hold the data" was about OUR pipeline only, never a doubt that Ironforge has the data — they
clearly do.

**What Ironforge ships for Anniversary (screenshot-verified):**
- `/anniversary/leaderboards/{region}/{bracket}/` — full ladder (51 pages ≈ 2,500+ entries for US
  3v3): rank, rating, name, **class AND detected spec** ("Holy Priest", "Arms Warrior"), race,
  server + faction icon, colored W/L, win%. Filters: season selector (incl. past seasons), EU/US,
  bracket, server dropdown, per-class icon filter, player/guild search on-page. **Headline
  feature: title-cutoff cards** — Merciless Gladiator / Gladiator / Duelist / Rival / Challenger
  ratings with estimated rank placement ("Rank ~55", "Ranks ~2188–2196"), timestamped ("updated
  at Aug. 7 · 05:58"). Ladder itself timestamped same day 18:01 — **they update multiple times
  per day, not daily.**
- `/anniversary/activity/{region}/{bracket}/` — NOT aggregate trends: a **recent-movement feed**
  ("who's playing right now") — per character: class, server, W/L since last snapshot, rating,
  +/- change, "2 hours ago" freshness. A habit-loop page (check who's queuing tonight).
- `/anniversary/charts/{region}/{bracket}/` — three views: **class distribution by rating tier**
  (toggle Rank One/Gladiator/Duelist/Rival/Challenger/No title), **cutoff history** over the
  season (line per title), and **"Estimated tracked games"** per bracket per day — explicitly an
  estimate ("tracked games inbetween daily resets divided by players per match"), i.e. games
  inferred from ladder W/L diffs. They do NOT have real game counts, durations, or comps.
- `/anniversary/player/{realm}/{name}/` — **a full armory page, not just a rating page**: avatar,
  guild, spec/class/race, item level, complete gear list with stats, talent trees
  (active/secondary), per-bracket cards (current rating, W/L, all-time "record rating"),
  per-bracket rating chart with a dated table of **per-session W/L deltas** (e.g. "June 28 · 9-1
  → 2564"), season selector, "last update: 22 hours ago" + an **on-demand "update" button**.
  This overlaps our core character-page value prop more than the brief implied — and corrects
  the brief's "Ironforge can't do per-character trend depth": they chart it at ladder-snapshot
  granularity. Our real differentiation is the match-level layer (per-match detail, comps,
  durations, death timelines, damage/healing) — structurally impossible for them.
- `/population/anniversary/` — realm population with Alliance-vs-Horde split bars per realm,
  weekly window ("22–28 July"), version/region/realm-type filters. **Subtitle matters:** "Active
  characters according to raids uploaded to Warcraft Logs **and characters on PvP Leaderboards**"
  — their Anniversary census BLENDS raid logs with ladder characters (corrects this addendum's earlier
  "PvP players invisible to their census" claim — only unrated PvPers are invisible).
- Persistent character search on every page — **Alex directive 8/8: search bar on ALL pages of
  arenaarmory.com, treated as non-negotiable UX parity, not a nice-to-have.**

**Data sources, verified:**
- **Population/census: Warcraft Logs raid-upload data + PvP leaderboard characters** (per their
  own page subtitle). The WCL half is confirmed via a Blizzard-forum methodology thread: unique
  raiders per period, effectively deduped via first-boss parses (~130K unique vs ~782K total
  parses in the cited example). Structural limits that remain exploitable: unrated PvPers
  (BGs/skirmish/world) are invisible, per-realm log-upload culture skews the raid half, and
  their "games played" numbers are explicitly estimates from ladder W/L diffs — our addon
  records actual games with durations and comps.
- **Arena ladders: Blizzard's PvP Leaderboard Game Data API** — the endpoint family
  (`/data/wow/pvp-region/{id}/pvp-season/{id}/pvp-leaderboard/{bracket}`) has existed for Classic
  progression realms since BCC Season 1 (2021, Blizzard API-release announcement) and is what the
  ladder-site cluster (Ironforge, WarcraftGear, tbcpvpladder) builds on. Known history of
  staleness incidents (a 2022 thread documents the Classic ladder frozen for days with no fix) —
  one more reason to run OUR OWN snapshot store rather than pointing pages at the live API.
- **Our side, confirmed in-repo:** `blizzardClient.ts` already speaks the Anniversary namespace
  family (`classicann`) and supports `dynamic`-kind namespaces — the P0 spike is one authenticated
  call to the pvp-leaderboard endpoint with `namespace=dynamic-classicann-{region}`.

**Plan deltas from this review (roadmap updated to match):**
1. **P1 leaderboards must include title-cutoff cards** (current cutoff per title + estimated
   placement rank, timestamped). Cutoff-checking is THE daily habit loop in TBC arena — it's the
   most prominent element on their leaderboard page for a reason. Falls out of the same snapshot
   store (rank N's rating per title percentage). Cutoff-history chart follows in P2.
2. **P1: ladder-history layer on character pages for EVERY ladder character** — rating chart +
   per-session W/L deltas from our snapshot diffs, no addon required. Good news from the
   screenshots: their `/player/` page is a full armory (gear/talents/ilvl) — but ours already IS
   one, so this is adding their one missing layer to pages we already have, while synced
   characters additionally show the match-level layer nobody else has. Consider their on-demand
   "update" button pattern too (our character pages already fetch live — surface the freshness
   timestamp). Multiplies indexable character-page depth post-re-review and gives every
   Anniversary PvPer a reason to look themselves up.
3. **Snapshot cadence: intra-day, not daily, once S3 starts.** Their ladder updates multiple
   times per day and the 2-hourly activity feed is part of the habit loop. For the Aug 14–18 S2
   archive window daily is sufficient; for S3 run every 2–4h — it's the same job on a shorter
   timer and it powers movers/activity feeds.
4. **NEW P2 candidate: recent-movement activity feed** (their `/activity/` page) — "who's queuing
   right now," per-character W/L + rating change since last snapshot. Cheap off the intra-day
   snapshot diffs; folds naturally into the snapshot homepage's "biggest movers" module or a tab
   of the leaderboard page.
5. **Participation stats (#7) reframed: parity-plus, not uncontested.** Their census already
   blends ladder characters in, and their charts estimate games/day per bracket. Ours
   differentiates on what estimates can't do: actual recorded games (incl. unrated), real match
   durations, realm-level cuts, and honest "measured, not estimated" framing.
6. **Header search: emphasis raised** per Alex — every page, site-wide, in the P1 block. Theirs
   also searches guilds — ours should too (guild pages already exist).
7. Everything else (P0 Aug 18 snapshot deadline, Sep 1 leaderboards, noindex-until-re-review,
   density-gated comp dashboard) stands — this review confirmed rather than changed it.

## 8. Decisions needed from Alex

1. **Trigger the AdSense re-review** (dashboard click, already unblocked) — sequencing gate for
   indexing the new pages, not for building them.
2. **Confirm the P0 carve-in for Aug 14** — it's post-freeze by the calendar, but it claims the
   first Arena hours after freeze week; the Aug 18 deadline doesn't move.
3. **Density threshold sign-off** — n≥50 per displayed comp/bracket cut (recommendation), and
   whether the comp dashboard ships gated-but-visible ("early data" labeling) or hidden until the
   gate passes.
