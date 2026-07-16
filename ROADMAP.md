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

## Next up

- **In-game analytics** - surface arenaarmory.com analytics inside the addon:
  winrate vs the comp you just queued into, partner winrates, rating trend,
  "you beat this team 2-1 before". The WoW sandbox has no network access, so
  the desktop app writes a stats digest into a SavedVariables file the addon
  reads on login//reload (reverse of the match-upload pipeline). Show it on
  arena entry (opponent comp winrate) and via a `/aa stats` panel.
- **Suggestions / coaching from analytics** - data-driven tips on the site,
  e.g. "your winrate vs RMP drops 20% when the first trinket is before 0:30".
- **Deeper per-match stats** - interrupt/juke accuracy, CC chains, target
  swaps, damage/healing timelines from the event stream.

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
