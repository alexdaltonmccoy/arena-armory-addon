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
- **Site UI consistency pass** - fonts, color/opacity, spacing, and text
  density across character/guides/matches (not just Upgrades). Upgrades
  wallet have/need strip shipped separately; this is the broader cleanup.
- **PvP Overview stat categories** - under coaching tips: bracket-scoped
  aggregates (e.g. DPS, trinket forced under 1 min) that change with Overall /
  2s / 3s / 5s. Later: per-match and key-matchup cards.
- **Profile / matchup stats (high-level)** - on public/claimed profile (and
  character PvP overview): rating and high-level performance summary by
  bracket (2s / 3s / 5s) and by matchup (vs RMP, etc.), built from the same
  scoreboard metrics — not per-ability deep dives.
- **Gamer profiles (richer)** - live-stream embeds, featured players, more
  profile depth on top of Profiles lite (pairs with profile/matchup stats
  above).
- **BlizzCon 2026 content play (added 2026-08-04 — see C:\dev\PORTFOLIO_ROADMAP.md
  Arena section + STRATEGY_ASSESSMENT_2026-08.md)** - Blizzard has officially
  committed to addressing "Classic's future" at BlizzCon (Sep 12–13); Classic+
  is rumored, not confirmed ("Project Camelot" datamine, ~29 encrypted "Classic
  1.60" builds since Oct 2025), WotLK progression is the other candidate. Either
  outcome answers this product's expansion-lifecycle risk. Three beats, all on
  the existing expo-router static SEO infra (same shape as the S3 transition
  guide — FAQ JSON-LD, Confirmed/Likely/Unknown fact tagging, internal links):
  **(1) late Aug–early Sep, AFTER Sep 1 work:** 2–3 speculation pieces
  ("Classic+ — everything we know", "WotLK Classic: what it means for arena
  PvP", "BlizzCon 2026 predictions") — builds the URL equity day-of searches
  land on. **(2) Sep 12–13:** live-updated announcement coverage + arena-player
  reaction. **(3) post:** evergreen "everything we know" hub for whatever was
  announced, updated as info drips — doubles as port-planning market research.
  This unblocks the "Blog / news (SEO)" item below (its stated precondition —
  S3 PvP lists shipped — is now met) with a concrete first content arc.

## Shipped recently

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

## Paused

- **Player discovery / LFG** - find teammates by bracket/rating/class; opt-in
  Btag sharing. Parked until profiles and claim volume are solid.

## Later

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
  decide after traffic grows.
- **Video/screenshot import for coaching** - desktop app records or ingests
  clips, syncs them to the match event timeline (the original long-term
  vision).
- **Code signing** - Azure Artifact Signing once the paid subscription is
  active, so the installer stops triggering SmartScreen.
