# Arena Armory Product Roadmap

One roadmap across the three apps: the WoW addon (this repo), the desktop
companion (`C:\dev\arena-armory-desktop`), and the web app / API
(`C:\dev\wow-classic-armory`, arenaarmory.com).

## Shipped

- **WoW addon v1** - enemy frames (trinkets, DRs, cooldowns, cast bars, spec
  detection), announcer, test mode, match recorder, auto-release to
  CurseForge/Wago via GitHub Actions.
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

## Next up

- **Phase 3 — PvP first, then PvE** (Anniversary dates from
  [Blizzard](https://news.blizzard.com/en-us/article/24291476/bcc-anniversary-edition-black-temple-arrives-august-27)):
  - **Aug 18** — Arena Season 2 ends (weekly restarts); leftover AP → honor (1:10).
  - **Aug 27, 3:00 pm PDT** — Phase 3 raids/hubs/Epic Gems (BT, Hyjal, Netherwing).
    (Not the same as Arena Season 3 — Google/AI blurbs often conflate these.)
  - **Sep 1** — Arena Season 3 starts (weekly restarts); Vengeful gear vendors.
  - **Priority 1 (before Sep 1):** `tbc-p3` **PvP** BiS + guide-content (Vengeful),
    extend `data/pvpCosts.ts` with S3 arena-point / honor vendor costs, update
    Upgrades + class guides. Default phase auto-flips to `tbc-p3` on **Sep 1**
    (Arena S3), not Aug 27 — via `SEASON_3_START_MS` / `getCurrentPhase()`
    (`EXPO_PUBLIC_FORCE_PHASE` override).
  - **Priority 2:** `tbc-p3` **PvE** lists scaffolded from P2 + epic gem catalog
    upgrades; gear still needs piece-by-piece BT/Hyjal BiS passes. Per-piece
    gem suggestions + shopping totals live on guides + Upgrades (PvP and PvE).
  Honor/marks costs for Veteran’s / medallions already show on **Upgrades** +
  class-guide Gearing.
- **Match result scoreboards (high-level)** - on each match detail page,
  alongside (or above) coaching narrative ("what went right / wrong / next"),
  show winner-vs-loser tables for high-level metrics: damage done, CC done,
  healing, etc. — team totals and per-player rows. Same view when drilling
  into a vs-comp (e.g. vs RMP): aggregate those high-level stats across games
  vs that composition, not only W/L and tips.
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

## Shipped recently

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

- **Blog / news (SEO)** - lightweight `/blog` (or `/news`) for patch notes,
  Season 3 prep, gearing explainers, and internal links into guides/comps/
  character pages. Keep it simple (MD/JSON posts or CMS-lite); prioritize
  after PvP S3 lists ship so launch content has somewhere to land.
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
