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

## Next up

- **Matchup drill-down pages** - dedicated per-comp pages aggregating your
  games vs that comp (winrate trend, common openers, what worked).

## Later

- **Player discovery** - find teammates by bracket/rating/class; opt-in
  Btag sharing.
- **Gamer profiles** - streamer links, live-stream embeds, featured players.
- **Expanded class & comp strategies** - ability priorities, matchup deep
  dives, contributor-authored guides.
- **Contributor program** - expert players write/review guides, revenue share
  or perks.
- **Monetization** - ads vs. paid tier (advanced analytics, coaching tools);
  decide after traffic grows.
- **Video/screenshot import for coaching** - desktop app records or ingests
  clips, syncs them to the match event timeline (the original long-term
  vision).
- **Code signing** - Azure Artifact Signing once the paid subscription is
  active, so the installer stops triggering SmartScreen.
