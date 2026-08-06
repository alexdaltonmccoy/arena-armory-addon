# Arena Armory Product Roadmap

One roadmap across the three apps: the WoW addon (this repo), the desktop
companion (`C:\dev\arena-armory-desktop`), and the web app / API
(`C:\dev\wow-classic-armory`, arenaarmory.com).

## Shipped

- **WoW addon v1** - enemy frames (trinkets, DRs, cooldowns, cast bars, spec
  detection), announcer, test mode, match recorder, auto-release to
  CurseForge/Wago via GitHub Actions.
- **Voice-pack announcer (addon v1.5.0)** - GladiatorlosSA-style callouts via
  shipped `Media/Voice/*.ogg` (90 Chirp3-HD clips at arena pace): trinket,
  drinking, low health, resurrects, CC, major cooldowns, optional interrupts.
  TTS is optional/off by default. Generator: `scripts/generate-voice-pack.py`.
  Coverage is solid for arena; optional parity polish (Blade Flurry, Intervene,
  Bestial Wrath, Mass Dispel, Purge/Dispel, Shield Bash, major racials) is
  Later, not a Sep 1 blocker.
- **Desktop app** - SavedVariables auto-discovery and watching, parse +
  dedupe + upload, self-provisioned tokens, addon-disabled diagnostics,
  system tray background sync, launch at startup, per-character armory links.
- **Website integration in the addon** - `/aa web`, `/aa lookup`,
  shift-click enemy frame lookup, post-match chat link.
- **Battle.net sign-in + character claiming** - OAuth, claimed badge,
  public/private match visibility, /account page, upload-token linking.
- **Match analytics v1** - winrate donut + summary stats, comp winrate
  tables with guide links, partner winrates, rating-over-time chart,
  per-match scoreboard and event timeline, per-character tabs on /matches.
- **In-game analytics** - computed live from the local match store, so records
  update the moment a game ends (no /reload or network needed): "You are 2-1
  vs Rogue/Priest" on arena entry, post-match record summary in chat, and a
  `/aa stats` panel with per-bracket records, recent matches with rating
  deltas, vs-comp and partner records.

## Shipped (continued)

- **Coaching insights v1** - threshold-gated tips computed from the event
  stream on the site (interrupt efficiency with juke detection, early trinket
  force conversion, CC pressure in wins vs losses, match length profile,
  first-blood conversion), plus per-match insight chips (trinket timing,
  kicks landed/juked, longest CC chain). Addon v1.3.8 records every rank of
  dedicated interrupt casts so attempts vs. lands is measurable.

- **Damage/healing timelines + target swaps** - addon v1.4.0 (schema v4)
  records bucketed per-side damage/healing (pets counted, overheal
  subtracted) and the enemy's focus target per 10s bucket; expanded match
  rows on the site chart both sides over time with a focus-target strip and
  a target-swap count chip.

- **Matchup drill-downs** - tap any vs-comp row for a per-comp breakdown:
  record + rating net, common enemy openers (anchored to the first hostile
  action), "what worked" wins-vs-losses observations, best partners for the
  matchup, and the comp's match list.

- **tbc-p3 PvP BiS + guide narratives** - 11/11 PvP BiS lists (Vengeful +
  Vindicator offsets), `pvpCosts.ts` S3 vendor costs, phase auto-flip to
  `tbc-p3` on Sep 1 (`SEASON_3_START_MS`), and Season 3 PvP guide-content
  overlays registered in `CONTENT_P3` (Season 3 / Vengeful / Vindicator’s
  copy; no more Merciless/Veteran’s fallback on P3 PvP guides).

- **Season 2 → Season 3 transition guide** - `/guides/season-3-transition`
  (arenaarmory.com): US/EU-paired dates, arena point conversion math, title
  cutoffs, S3 gear preview, FAQ with JSON-LD, every fact tagged
  Confirmed/Likely/Unknown per the verified source pack
  (`wow-classic-armory/S3_TRANSITION_GUIDE_CONTENT.md`). Linked from home,
  the guides index, the Upgrades wallet strip (when a character holds arena
  points), and every arena/PvP BiS guide page. Live.

## Next up

- **Phase 3 — remaining toward Sep 1** (Anniversary dates from
  [Blizzard](https://news.blizzard.com/en-us/article/24291476/bcc-anniversary-edition-black-temple-arrives-august-27)):
  - **Aug 18** — Arena Season 2 ends (weekly restarts); leftover AP → honor (1:10).
  - **Aug 27, 3:00 pm PDT** — Phase 3 raids/hubs/Epic Gems (BT, Hyjal, Netherwing).
    (Not the same as Arena Season 3 — Google/AI blurbs often conflate these.)
  - **Sep 1** — Arena Season 3 starts (weekly restarts); Vengeful gear vendors.
  - **Done for PvP Priority 1:** BiS + costs + guide overlays (see Shipped).
  - **Done:** S3 currency path (site + addon v1.6.0 + desktop v1.3.0).
  - **Done:** addon **v1.7.0** (party callouts + automark).
  - **Done:** `tbc-p3` **PvE** BT/Hyjal polish — boss-specific BiS sources
    + deeper PvE guides (races/professions). Site default still flips to
    `tbc-p3` on Sep 1 (not Aug 27).
- **Party chat callouts — majors only** - **Shipped** addon v1.7.1: no
  self-chat spam; party only for trinket / drinking / walls / lust /
  innervate / grounding / NS / mana tide / res. CC and noisy CDs stay
  voice + raid-warning. Automark unchanged.
- **S3 currency tracking** - **Shipped** (see SEASON3_CURRENCY_TRACKING.md).
  Stretch later: mats inventory (§4).
- **Upgrades tab UI overhaul (elevated priority 2026-08-04, from Alex: "genuinely
  feels ugly/cluttered") - Shipped 2026-08-04** (wow-classic-armory
  `components/UpgradesPanel.tsx`, `lib/currency.ts`, `lib/bis.ts`,
  `lib/statPriority.ts`, `lib/theme.ts`, `components/ui/ColorLegend.tsx`):
  - **Currency have/need, prominent** - balances and remaining need per
    currency merged into one row each ("X of Y — Z more"), moved out of the
    cramped score-header column into its own panel that renders first on the
    tab, ahead of the BiS score.
  - **Color legend** - named `stateColors` tokens (complete / in-progress /
    attention / optional) alias the existing palette instead of raw
    `colors.success`/`danger`/etc. scattered by context; a small legend
    renders once near the top of the tab. Also fixed a latent inconsistency:
    two different "Affordable" badges were using two different greens
    (`colors.success` vs. a hardcoded `#5fbf6e`) - both now use the same
    token.
  - **Gem/Enchant folded into gear per slot** - the four-section layout
    (Gear Upgrades / Enchants / Gems / Dialed In) is now one per-slot list;
    each slot shows gear + enchant + gem status together. "Dialed In" now
    requires all three to be clean, not just gear (previously a slot could
    show as done while still missing an enchant). `GemIssue` gained a
    `slot` key for reliable matching (labels weren't 1:1 between curated
    BiS data and Blizzard's own labels).
  - **Upgrade priority - lightweight hint, not the full engine.** Scope
    decision made with Alex: a real hit/expertise-cap-aware ranking needs a
    per-item stat database for BiS candidates and numeric cap tables, neither
    of which exist (only prose in guide text) - that's a separate,
    multi-day project. Shipped instead: the "Buy next" list now reorders by
    the spec's already-authored stat priority (`data/guide-content`
    `stats.items`, keyword-matched against each item's text) before falling
    back to cost, with a caption disclosing it's approximate and a link to
    the full guide.
  - **Font legibility - researched, not touched.** `UpgradesPanel.tsx`
    doesn't actually misapply the Cinzel display font to body/data text (it
    only reaches Cinzel via `SectionHeading`, which is chrome). The "unreadable
    in some places" complaint is a sitewide observation, not an Upgrades-tab
    bug - the broader Cinzel-on-data audit across character/guides/matches
    is still open, tracked below under Later.
  - Verified against live character data (real Blizzard API character with
    multiple gear/enchant/gem issues) in-browser; `tsc --noEmit` clean.
- **Gamer profiles — remaining scope (2026-08-04 scope-down, see Shipped
  recently for the Twitch embed piece already done):** "featured players"
  needs a real admin/curation surface built from scratch (nothing exists
  anywhere in the app - no admin route, no moderation queue, no curated-list
  mechanism; the Contributor form is inbound-only) and is more Alex's call
  (who gets featured, how) than an engineering one - not something to build
  blind. "More profile depth" was never defined past that one word. Both
  parked until Alex wants to scope them specifically.
  - **YouTube live embed, deferred separately:** the stored value for the
    common case is an `@handle` (`normalizeYoutube`), but YouTube's
    live-embed URL needs the numeric channel ID, which only survives when a
    user happens to paste a `/channel/{id}` URL. Needs a YouTube Data API
    key + quota + somewhere to cache the resolved ID - real new
    infrastructure, revisit if worth it.
- **BlizzCon 2026 content play (added 2026-08-04, first 2 pieces shipped +
  live 2026-08-05 — see C:\dev\PORTFOLIO_ROADMAP.md Arena section +
  STRATEGY_ASSESSMENT_2026-08.md)** - Blizzard has officially committed to
  addressing "Classic's future" at BlizzCon (Sep 12–13); Classic+ is
  rumored, not confirmed ("Project Camelot" datamine, Patch 1.60 build since
  Oct 2025), WotLK progression is the other candidate. Either outcome
  answers this product's expansion-lifecycle risk. **Shipped 2026-08-05, at
  arenaarmory.com/news:** a new dedicated `/news` section (kept separate
  from the class/spec guides — Alex's call, so neither clutters the other),
  with 2 of the planned 3 speculation pieces live: "WoW Classic+ (Project
  Camelot): Everything We Know" and "WotLK Classic Anniversary: What It
  Would Mean for Arena PvP" - both fact-tagged Confirmed/Likely/Unknown
  against real sources (Wowhead, the Jan 29 State of Azeroth stream, patch
  history), cross-linked, with WoW-icon-CDN visuals (hero icon + per-event
  timeline icons + confidence-tinted fact rows). The 3rd piece ("BlizzCon
  2026 predictions") is deliberately held until a real new leak surfaces
  rather than shipped as filler - Alex's call, agreed. Still open: **(2)
  Sep 12–13:** live-updated announcement coverage + arena-player reaction.
  **(3) post:** evergreen hub update for whatever was announced, updated as
  info drips - doubles as port-planning market research. This unblocks the
  "Blog / news (SEO)" item below (its stated precondition - S3 PvP lists
  shipped - is now met) with a concrete first content arc, now with its own
  home instead of a placeholder.
  **Added weight (2026-08-04): also the plan for the AdSense "low value
  content" rejection** — see "Competitive position & revenue plan" below.
  Real editorial writing is exactly what a re-review needs; **the 2 shipped
  pieces are enough to request review again whenever Alex wants to trigger
  it** (Google Search Console / AdSense dashboard - only-Alex action, not
  something this session can do).
- **"Classic+ Waiting Room" campaign via Rebbel + MerchMaxx (P1, added
  2026-08-05 from C:\dev\ROADMAP_ADDENDUM_2026-08-05.md)** — pre-BlizzCon
  timing (Sep 12–13), doubles as Rebbel dogfood campaign #2 (after
  MerchMaxx) and a MerchMaxx merch dogfood too. Ship before BlizzCon week —
  see C:\dev\PORTFOLIO_ROADMAP.md's dogfood-sequence note
  (MerchMaxx done → Arena pre-BlizzCon → Sobermaxx Sept → Faithmaxx Nov).
- **CurseForge: post a comment asking for feedback (P2, added 2026-08-05)**
  — **description pasted live by Alex 2026-08-06** (`marketing/curseforge-description.md`,
  now covering S3 currency tracking, party callouts/automark, and the
  ArenaAnalytics import feature). Still open: the feedback comment itself
  and the separate Summary-field one-liner (search-weighted, not stored
  in-repo) — quick manual dashboard items, ~5 min each.
- **Build Arena MCP (P3, parking lot, added 2026-08-05)** — park until
  after Sep 1; revisit during Season 3.
- **Premium tier ($3–5/mo) — scoping started 2026-08-06, paused mid-scope**
  at Alex's request to brainstorm further. Now the #1-ranked revenue move
  (ArenaAnalytics import, #2, shipped). Research already done and doesn't
  need repeating when resumed: Battle.net OAuth + Firebase auth model
  (`api/_lib/auth.ts`, `lib/authContext.tsx`), existing free coaching/stats
  code (`lib/matchStats.ts`, `matchInsights.ts`, `matchCoaching.ts`,
  `matchupStats.ts` — all client-computed, no gating infra exists yet,
  greenfield), and rebbel-v2's proven Stripe pattern to mirror
  (`billingAccounts/{uid}` doc, checkout/portal/webhook API routes). Open
  product decisions for when Alex resumes: what's actually premium (leading
  candidate: population percentile benchmarks + full match-history export,
  since free already ships rich per-user coaching — re-gating that would be
  user-hostile), exact price point, and whether annual pricing ships day one.

## Shipped recently

- **Session close-out, 2026-08-06: news polish, footer credit, site-side
  dedupe cleanup.** (1) The Season 3 transition guide is now cross-linked
  into `/news` as a third card ("Season 3 Watch") alongside the two
  BlizzCon pieces — Alex's call that it's genuinely time-sensitive event
  coverage, not evergreen guide content, but its URL/SEO/internal-link
  equity (home, guides index, Upgrades wallet strip, every PvP BiS guide)
  stayed untouched rather than moved. The page itself was also brought up
  to the same visual bar as the newer pieces: hero icon, per-timeline-event
  icons, confidence-tinted fact rows — all verified loading in-browser and
  live on production. (2) A one-line alexmccoy.dev credit was added to the
  site's home footer ("Built solo by Alex McCoy...") — a low-key inbound
  lead channel off Arena Armory's existing trusted user base, per
  `alexmccoy-dev/docs/PITCH_DRAFTS.md` §5's recommended copy, verified live.
  (3) The ArenaAnalytics-import duplicates created during live-testing were
  still on the site (local cleanup only fixed the desktop app) — wrote a
  reusable admin script (`wow-classic-armory/scripts/dedupe-arena-analytics-imports.ts`,
  same time-window dedup logic as the desktop fix) and ran it against
  production: found and removed 3 duplicate docs, verified 0 remain.
  Reusable for any real user who hits the same both-addons-enabled pattern,
  not just this account.
- **ArenaAnalytics one-time match-history importer (2026-08-05)**
  (arena-armory-desktop) - revenue-plan move #2 (see "Competitive position
  & revenue plan" below). Reverse-engineered the closed-source addon's
  SavedVariables format from its own shipped Lua (no public repo or
  documented schema exists) and mapped it into our own `ArenaMatch` shape:
  date/bracket/outcome/match-type/ratings/map/comps for all 3 TBC arenas,
  skipping Solo Shuffle (not a TBC Anniversary bracket) rather than
  mis-tagging it. Zero site changes needed - `/api/matches/import` already
  accepts sparse matches - so this is entirely a desktop-app feature reusing
  the existing addon sync/upload pipeline. Scan-then-confirm UI ("Check for
  ArenaAnalytics history" → "Import N matches"). Tested against a synthetic
  fixture built from the decoded schema (no real sample file available this
  session); `tsc --noEmit` + `electron-vite build` both clean. Scope
  decision: not building an ongoing service to track ArenaAnalytics releases
  and auto-regenerate the decode logic - it's a one-time backfill tool for a
  third-party dependency we don't control, not a live sync; revisit
  reactively if it stops finding matches for real users, not proactively.
  **Live-tested against Alex's real data the same day, 2 real bugs found and
  fixed**: (1) spec IDs ending in a 0 (e.g. 70) mean "class identified, spec
  never observed before the match ended" per the addon's own
  `Helpers:IsClassID`/`IsSpecID` convention - the original decode only
  handled fully-resolved specs, silently showing "?  ?" instead of at least
  the class. (2) Playing with both addons enabled produces two records of
  the same live match (native "AA-..." and imported "aa-import-..." guids
  never collide) - added time-window dedup (per character, 180s) wired into
  both scan and import so future double-recording is prevented, plus a
  "Remove duplicate imports" cleanup action for matches already
  double-imported before that fix existed (local store only - no delete
  endpoint exists on the site to retract already-uploaded dupes; not
  building one for 2 test records on one account, revisit if this becomes a
  real multi-user need). Both fixes covered by new test cases.
- **WoW addon "Unknown" teammate/opponent bug (addon v1.7.8, 2026-08-05)**
  - found via the ArenaAnalytics live-testing above, but a pre-existing bug
  in our own `Recorder.lua`, unrelated to the importer. `UnitName()` returns
  the literal string "Unknown" (not nil) when the client hasn't cached a
  unit's name yet - common right as a freshly-formed 3v3+ group loads in.
  Both `SnapshotFriendlyTeam` (dedupes by name, so "Unknown" permanently
  occupied that roster slot) and `SnapshotEnemyTeam` (`e.name = e.name or
  X` never re-evaluates once any truthy value is set, stickier - a bad
  first capture could never self-correct) recorded that placeholder as if
  it were real. Fix: skip the unit if the name is still "Unknown" rather
  than committing it; the existing repeated-snapshot / scoreboard-merge
  safety nets pick up the real name once it resolves. Verified with
  `node .tools/check-lua.js`, tagged and released - live on CurseForge/Wago.
- **BlizzCon news section + first 2 speculation pieces (2026-08-05)**
  (wow-classic-armory, live at arenaarmory.com/news) - new `/news` route
  (hub page + top-nav entry + sitemap generator registration) kept
  separate from `/guides` per Alex's IA feedback ("don't clutter the
  guides page"). Two fact-tagged pieces shipped: the Classic+/Project
  Camelot "everything we know" article (moved here from its original
  `/guides` location) and a new WotLK Classic Anniversary piece covering
  what a Wrath rerun would actually change for arena (Death Knight, Dual
  Talent Specialization, gear itemization) - grounded in the real
  2022–2023 WotLK Classic re-release's patch history rather than forum
  speculation, and explicitly hedged that a Wrath Anniversary may not even
  be the same BlizzCon announcement as Classic+ (Patch 1.60's vanilla-era
  signature argues against Camelot being Wrath content). Both pieces got a
  visual pass (Alex's ask): WoW icon CDN hero icons, per-timeline-event
  icons, and confidence-tinted left rails on every Confirmed/Likely/Unknown
  fact row. `tsc --noEmit` clean, real `npm run build:web` production
  build verified, all icons confirmed loading in-browser, pushed to
  master and deployed live via Vercel's GitHub integration - verified
  serving on the production domain.
- **Live Twitch embed on public profiles (web)** (wow-classic-armory) -
  scoped down from "Gamer profiles (richer)" to the one piece that was
  actually contained; "featured players" and "more profile depth" parked
  (see Next up - need real product scoping, not an engineering call). A
  profile's Twitch chip now plays inline (`player.twitch.tv`) instead of
  just linking out - the stored channel name is a clean fit for Twitch's
  embed URL. Web-only: split via the same Metro/TS platform-suffix
  precedent as `lib/analytics.web.ts`/`.native.ts`
  (`components/TwitchEmbed.web.tsx`/`.native.tsx`), since embedding on
  iOS/Android would need a new native WebView dependency + EAS rebuild for
  one card on one screen - native keeps the existing outbound link,
  unchanged. YouTube embedding turned out to need a YouTube Data API
  integration (not just an embed - see Next up), so it's untouched this
  pass. `parent` is read from `window.location.hostname` at render time, so
  it's automatically correct for dev and prod with no new env var.
- **Profile / matchup stats (high-level)** (wow-classic-armory) - public
  profile character cards now show CR pills per bracket
  (`bracketCrSummaries`, falling back to W-L when a bracket has games but no
  rated result) and top-3 matchups (`CompTable`, compact/read-only) for any
  claimed character with synced matches. The "character PvP overview" half
  of this item was already covered by existing work (bracket toggle, CR
  cards, vsComps tables, the new stat tiles) - the real gap was the profile
  page having zero performance data. No new backend/aggregation: reuses the
  same query hook, stat functions, and table component the character page
  already uses; per-character privacy was already enforced independently by
  both the profile and matches endpoints. Verified against a real public
  profile (Mindflayz) across a match-having character, a matchless one, and
  a private one correctly excluded from the roster entirely.
- **PvP Overview stat categories** (wow-classic-armory) - a small
  always-visible stat row (Avg DPS, Avg HPS, Trinket forced <60s, Interrupt
  efficiency) above the existing threshold-gated coaching tips on the PvP
  Overview tab, bracket-scoped through the same match array the tips/charts
  already use. No new data plumbing - derived from `computeMatchStats` and
  `matchInsights()`'s existing per-match building blocks. Verified against
  124+ real synced games (Overall/2v2/3v3 all update correctly, per-category
  sample-size gating drops tiles independently in the lower-sample 3v3
  bracket). Per-match and key-matchup cards stay Later, per the original
  scope note.
- **Marks of Honor reading as 0 (addon v1.7.7)** - Alex hit this on his own
  account: an immediate currency snapshot at login/zone-in (before bags are
  cached) could read all marks as 0 and overwrite the real count, with a
  quick `/reload` or relog inside the ~0.75s bag-refresh window persisting
  the bad value to SavedVariables and from there straight through the
  desktop app and site (both just trust newest-`updatedAt`, no regression
  check). Fixed at the source: a snapshot from one of the known-unsafe
  moments no longer overwrites real marks with an all-zero read. Self-heals
  on next login - no manual data fix needed.
- **CurseForge/Wago changelog was leaking internal commit detail** -
  `BigWigsMods/packager` defaults to auto-generating the public changelog
  from raw git commit messages since the last tag; since `ROADMAP.md` and
  other business docs live in this same repo, that included real
  competitive/product strategy (expansion sequencing, a CurseForge discovery
  plan, the BlizzCon content-play plan) on the live v1.7.7 changelog page.
  Fixed: `.pkgmeta` now points at a curated, player-facing `CHANGELOG.md`
  (added), and a CI guard fails the release if a tag has no matching
  changelog entry - closes the silent fallback-to-raw-git-log gap so this
  can't quietly reopen. v1.7.7's already-published changelog was manually
  corrected on both CurseForge and Wago; replacement text for the 7 other
  affected historical tags (v1.3.0, v1.3.9, v1.4.1, v1.4.2, v1.6.0, v1.7.0,
  v1.7.2 - all low-severity internal status notes, not strategic content)
  is drafted and ready whenever Alex wants to apply it.
- **Upgrades tab UI overhaul** - currency have/need panel moved first and
  merged into one row per currency, a named color-state legend, gear/enchant/
  gem consolidated per slot instead of four separate sections, and a
  lightweight spec-stat-priority hint on the "Buy next" list. Full detail and
  scope notes (font audit + real stat-cap engine deferred) under Next up.
- **Match result scoreboards (high-level)** - team totals (damage, healing,
  CC landed) as ours-vs-enemy comparison bars, above the existing per-player
  scoreboard rows on each match detail page. Same totals, averaged per game,
  on the vs-comp matchup drilldown (e.g. vs RMP). CC is team-level only: the
  addon's `cc` event records the victim but not the caster, so per-player CC
  done isn't derivable from current data — revisit if a future addon schema
  records the caster.
- **S3 currency tracking** - addon `ArenaArmoryCurrency` (honor/AP via
  `C_CurrencyInfo` 1901/1900 + BG marks), desktop v1.3.0 upload, site
  `/account` manual balances + Upgrades affordability bars.
- **Party chat callouts + automark** (addon `master`, pending Curse tag) -
  `[Arena Armory]` majors to PARTY; class raid icons in arena.
- **Profiles lite** - opt-in public `/profile/{battletag-slug}` with claimed
  characters and Twitch/YouTube links (edited on /account; Hidden by default;
  per-character Public/Private also gates profile listing).
- **Matches UX polish** - empty states, match-detail back links, Matches /
  Overview tabs, CR-first PvP cards, chart sort.
- **Mobile 1.1.0** - EAS production builds submitted to App Store Connect /
  Play internal.

## Competitive position & revenue plan (researched 2026-08-04 — sources in Cowork chat / STRATEGY_ASSESSMENT_2026-08.md changelog)

**The moat, verified:** nobody else in Classic closes the loop addon → desktop
uploader → web analytics on PRIVATE match data. The field splits into public-API
ladder sites (Ironforge.pro, XUNAMATE, WarcraftGear, classic-armory.org,
tbcpvpladder — rating/rank only, no match-level data, all donation/ad-funded)
and in-game-only trackers (ArenaAnalytics: 154K+ CurseForge downloads, supports
TBC Anniversary, data trapped in SavedVariables, no site). Per-match
damage/healing/comp data of private games is structurally unavailable to
API-scrapers — the moat is real, but it compounds with install base, so addon
adoption IS the business metric.

**The two models to steal from (Alex's hypothesis, amended):**
- **Skill-Capped** = the monetization benchmark, and MORE of a live threat than
  assumed: actively shipping TBC Anniversary tier lists + a premium UI package +
  a dedicated classic pricing page (~$13/mo per user reports; exact tiers need a
  browser check). But they have ZERO data products. Posture: don't compete on
  video training — borrow the paid-tier playbook, differentiate on data.
- **Murlok.io** = the traffic template, NOT a competitor: retail-only (no classic
  at all), solo dev, fully programmatic meta pages (top-50-per-spec
  gear/talents scraped every 8h) → ~1.4M visits/mo carried by ads. The classic
  version of this does not exist. That's the open square.
- Amendment: the free classic ladder-site cluster is the day-to-day attention
  competition (they hold leaderboard SEO terms), and ArenaAnalytics is the
  sleeping risk to the addon loop (one upload feature away from competing).

**Version expansion — when do we compete with Murlok? (sequenced 2026-08-04):**
Build the programmatic meta-page engine **version-agnostic from day one** (game
version + season as config, not hardcode) — then expansion is data work, not a
rebuild. Sequence: **(1) Now–Sep:** TBC Anniversary only; prove revenue-per-page
on the S3 spike before spreading. **(2) Oct, if S3 validates:** MoP Classic —
active arena scene, Blizzard API exposes its leaderboards (classic-armory.org
already shows MoP arena ratings), and Murlok isn't there either; config + data
if the engine was built right. **(3) BlizzCon decides the big one:** WotLK
Anniversary / Classic+ is where our existing users migrate — being live with
meta pages + addon support AT that version's launch is the land-grab that locks
the Murlok-of-Classic position; prep starts the day of the announcement.
**(4) Retail: last or never** — Murlok's 8h-refresh crawler + PvPQ + Drustvar
are entrenched, and our addon-loop moat matters least where Blizzard's APIs are
richest. The Classic family is where the model is uncontested; win it fully first.

**CurseForge discovery (checked 2026-08-04 — 262 downloads in 20 days, pre-season):**
Current listing is solid (5 screenshots, active updates, Gladdy comparison,
Classic TBC 2.5.6 flag) but thin on findability. Do NOT split the core suite —
the addon→site loop is the moat and multi-listing maintenance is real solo cost.
Plan: **(a) Listing optimization (cheap, before Sep 1):** add categories beyond
Arena/PvP — Unit Frames (where Gladdy-type addons get browsed) and Audio/Video
(announcer); work searched incumbent names into the description naturally
("Gladius/Gladdy-style enemy frames," "GladiatorlosSA-style voice announcer,"
"arena match history/analytics") — CurseForge search is title/summary-weighted
and people search the names they know; keep release cadence up ("recently
updated" surfaces addons). **(b) One satellite addon experiment (Sep):**
"Arena Armory Announcer" standalone — the voice pack is already modular
(Media/Voice/*.ogg + generator), GSA-style announcer searches are a proven
demand pool, and the listing funnels to the full suite. Measure 30 days before
any second satellite (a standalone recorder only if the ArenaAnalytics importer
doesn't already capture that crowd). **(c) The channels that actually move
classic addons:** Reddit (r/classicwow, r/worldofpvp) + class Discords +
streamers using the frames on stream — the S3 window and BlizzCon week are the
moments; fold into the Rebbel dogfood campaign rather than ad-hoc posting.

**AdSense reality check (2026-08-04): rejected for "low value content."**
Google's automated review flagged the site before requesting a re-review.
This is the known failure mode for armory/lookup-tool sites specifically —
thousands of near-identical Blizzard-API character pages can swamp the
crawl and read as thin/auto-generated even with real guide content sitting
alongside them. Two things follow from this, both reflected in the
re-ranked list below: **(a)** the #1-ranked revenue move as originally
written (programmatic meta pages) would add *more* templated pages right
now — reinforcing the exact signal that got the site rejected — so it's
paused until re-review, not built first. **(b)** the BlizzCon speculation
pieces (see Next up) are real editorial writing and get bumped up in
priority partly *because* they'd help a re-review, not just for the traffic
event. Plan: ship the BlizzCon pieces, request AdSense review again, then
resume the programmatic-pages work once either approved or the
content-quality signal is clearly stronger. AdSense isn't abandoned — it
was never the durable plan anyway (see the declining-search caveat above) —
just no longer sequenced first.

**Revenue moves, ROI-ranked (re-ranked 2026-08-04 for the AdSense hold):**
1. **Premium tier ($3–5/mo)** — moved up: doesn't need Google's approval or
   the S3 traffic-read gate it was originally waiting on, and is the more
   durable long-term bet regardless (rides the addon-loop moat directly,
   not the declining-search trade). Personal advanced analytics: deeper
   coaching insights, vs-comp prep sheets, trend reports — powered by the
   private match data competitors can't touch. Evidence base: ad-free-only
   premium fails at niche scale (Murlok Patreon ~$174/mo), but data-backed
   premium has precedent (PvPQ shipping AI coaching on retail; Icy Veins
   selling log reviews). Price like Icy Veins/Wowhead (cheap,
   annual-friendly), not like Skill-Capped — we're not selling a
   curriculum. Also: if ads exist at all, "ad-free" becomes part of the
   premium pitch — another reason not to abandon AdSense entirely.
2. **ArenaAnalytics import** — **shipped 2026-08-05** (arena-armory-desktop).
   Unaffected by the AdSense hold (importing existing users' match history
   isn't new templated content). One-time importer from ArenaAnalytics
   SavedVariables → instant match-history on our site. Turns the
   154K-download sleeping risk into a growth channel ("bring your history
   with you") and seeds the aggregate dataset #3 needs. Cheap, high-leverage,
   defensive. Build notes: ArenaAnalytics is closed-source (no public repo),
   so the format was reverse-engineered from its own shipped Lua source —
   a compact per-character table keyed by small negative integers, names/
   realms resolved via shared index arrays, specs via an addon-internal ID
   scheme. Needed zero site changes (`/api/matches/import` already accepts
   sparse matches). Scan-then-confirm flow in the desktop app UI ("Check for
   ArenaAnalytics history" → "Import N matches"), synthetic-fixture tested
   (no real sample file was available), `tsc`/build clean. Deliberately not
   building a service to track ArenaAnalytics releases and auto-regenerate
   this decode — one-time backfill tool for a dependency we don't control,
   not a live integration; fix reactively if it stops finding matches for
   real users.
3. **Programmatic meta pages (Murlok model for TBC Anniversary)** — **paused
   until AdSense re-review** (see above), not cancelled. Auto-generated
   per-spec gear/talent/comp pages from the Blizzard leaderboard API + our
   own uploaded-match aggregates (comp winrates by bracket — data nobody
   else has). Near-zero marginal cost per page, direct AdSense multiplier
   once approved.
4. **Public leaderboard + cutoff tracker pages** — same pause as #3 (also
   programmatic/templated). Commoditized (4 free sites do it) but cheap via
   the same API; bundle with #3's crawl once that resumes.
5. **What NOT to build:** video training (Skill-Capped's game — needs a content
   machine + YouTube funnel), coaching marketplace (no working precedent in the
   niche), donations (consistently fails: every free ladder site is coffee-money).

## Paused

- **Player discovery / LFG** - find teammates by bracket/rating/class; opt-in
  Btag sharing. Parked until profiles and claim volume are solid.

## Later

- **Party cooldown tracker (addon concept, added 2026-08-05 from Alex)** -
  mirror the existing enemy cooldown tracker (`Modules/Cooldowns.lua` -
  first-observed-use icons anchored under each frame) for your own party
  instead of just the enemy team. Same underlying constraint as enemy
  tracking applies: WoW doesn't expose other players' cooldowns directly,
  so party CDs would be inferred from observed casts the same way enemy
  CDs already are - the tracking technique is proven, just pointed at
  `party1`-`party4` instead of `arena1`-`arena5`. Real scoping question
  before building: there are no custom party frames today (only
  `PartyMark.lua` automark + `Announcer.lua` party chat callouts layer on
  top of Blizzard's default party frames) - decide whether to attach
  cooldown icons onto the default party frames (lighter, more like OmniCD)
  or build a custom party frame row to match the enemy-frame styling
  (bigger scope, more "complete arena toolkit" cohesive). OmniCD is the
  closest existing addon doing party-side CD tracking today, similar to
  how Gladius/Gladdy/GladiusEx are the enemy-frame precedents already named
  in the CurseForge listing - worth a quick look at what it does well/
  poorly before committing to an approach.
- **Sitewide Cinzel-on-data font audit** - carved out of the 2026-08-04
  Upgrades tab overhaul: Upgrades itself doesn't misuse the display font, so
  the "unreadable in some places" feedback points at other screens
  (character/guides/matches). Audit every `fonts.display*` usage (22 files as
  of 2026-08-04) for cases applying it to dense/data text instead of
  headings/chrome, and swap those to a legible body font.
- **Real stat-cap-aware upgrade priority engine** - carved out of the same
  overhaul (lightweight guide-text hint shipped instead, see Shipped). Needs
  two things that don't exist: a per-item stat database for BiS candidates
  (curated `BisItemRef` entries carry no structured stats today) and numeric
  hit/expertise/etc. cap tables per class/spec/phase (only prose in guide
  content currently). Multi-day scope - revisit if the lightweight hint
  proves insufficient in practice.
- **Announcer GSA parity polish** - extra voice clips + spell maps for Blade
  Flurry, Intervene, Bestial Wrath, Mass Dispel, Purge / Dispel Magic, Shield
  Bash, and high-signal racials (Arcane Torrent, Blood Fury, Berserking). Not
  needed for Season 3 launch.
- **Blog / news (SEO)** - lightweight `/blog` (or `/news`) for patch notes,
  Season 3 prep, gearing explainers, and internal links into guides/comps/
  character pages. Keep it simple (MD/JSON posts or CMS-lite). **Status
  update 2026-08-04: precondition met (S3 PvP lists shipped) — first content
  arc is the BlizzCon play in Next up; build the minimal /news route to host
  it.** Later, this becomes the dogfood surface for Rebbel's news-reactive
  blogPost engine (rebbel-v2/docs/ROADMAP.md) — agent-drafted, human-approved
  post-BlizzCon coverage cadence; the first pre-BlizzCon pieces are manual,
  not blocked on that engine. Watch Core Web Vitals as the content volume
  grows (RN-web ships more JS than a content-first stack); if the news hub
  becomes a real content business in 2027, the escape hatch is a dedicated
  content subdomain (e.g. news.arenaarmory.com on Next.js) — additive, not a
  refactor of the app.
- **Comp standards (optional / lower priority)** - "in this matchup this class
  typically does X damage" style baselines vs the field; only after per-match
  and vs-comp scoreboards exist and prove useful. Easy to overfit or feel
  noisy — keep high-level first.
- **Expanded class & comp strategies** - ability priorities, matchup deep
  dives, contributor-authored guides.
- **Contributor program** - expert players write/review guides, revenue share
  or perks. Application form lives at arenaarmory.com/contribute
  (Firestore `contributorApplications`).
- **Monetization** - ads vs. paid tier (advanced analytics, coaching tools);
  decide after traffic grows. **Superseded by the competitor-informed plan
  below (2026-08-04) — see "Competitive position & revenue plan."**
- **Video/screenshot import for coaching** - desktop app records or ingests
  clips, syncs them to the match event timeline (the original long-term
  vision).
- **Code signing** - Azure Artifact Signing once the paid subscription is
  active, so the installer stops triggering SmartScreen.
