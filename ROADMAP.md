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

## Next up

- **Phase 3 — remaining toward Sep 1** (Anniversary dates from
  [Blizzard](https://news.blizzard.com/en-us/article/24291476/bcc-anniversary-edition-black-temple-arrives-august-27)):
  - **Aug 18** — Arena Season 2 ends (weekly restarts); leftover AP → honor (1:10).
  - **Aug 27, 3:00 pm PDT** — Phase 3 raids/hubs/Epic Gems (BT, Hyjal, Netherwing).
    (Not the same as Arena Season 3 — Google/AI blurbs often conflate these.)
  - **Sep 1** — Arena Season 3 starts (weekly restarts); Vengeful gear vendors.
  - **Done for PvP Priority 1:** BiS + costs + guide overlays (see Shipped).
  - **Next Priority:** S3 currency tracking (below), then `tbc-p3` **PvE**
    piece-by-piece BT/Hyjal BiS passes (lists already scaffolded). Per-piece
    gem suggestions + shopping totals live on guides + Upgrades.
- **S3 currency tracking (honor / marks / arena points → gear progress)** -
  addon snapshots per-character balances into SavedVariables, desktop app
  uploads them, site shows have/need affordability bars against the S3 cost
  data on Upgrades + character PvP tab, with a manual-input fallback on
  /account for claimed characters. Full 3-repo spec:
  `SEASON3_CURRENCY_TRACKING.md` (this repo). Priority 2 behind the tbc-p3
  content; target v1 by Sep 1 or first S3 week. Stretch (not Sep 1):
  enchanting-mats/gems inventory comparison — account-wide via SavedVariables
  but non-soulbound caveats apply (guild bank/mail invisible), see spec §4.
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

- **Announcer GSA parity polish** - extra voice clips + spell maps for Blade
  Flurry, Intervene, Bestial Wrath, Mass Dispel, Purge / Dispel Magic, Shield
  Bash, and high-signal racials (Arcane Torrent, Blood Fury, Berserking). Not
  needed for Season 3 launch.
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
