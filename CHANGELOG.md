# Changelog

## v1.9.0 (2026-08-09)
- New: 13 more announcer callouts — Blade Flurry, Intervene, Bestial Wrath,
  Shield Bash (interrupt callouts, off by default like Kick/Pummel), Arcane
  Torrent, Blood Fury, Berserking, Dispel Magic, Purge, Ice Barrier, Shield
  Wall, Divine Favor, and Blessing of Sacrifice.

## v1.8.0 (2026-08-09)
- New: on first install, a brief one-time preview shows your enemy frames
  with sample data so you can see what the addon actually looks like
  before your first arena match. Previously the only thing visible on
  first login was the drag anchor bar until you found /aa test yourself.
- New: minimap icon. Left-click for options, right-click for the stats
  panel. Can be turned off in options if you'd rather not have it.
- New: 12 more announcer callouts — Charge, Intercept, Blink, Spellsteal,
  Feral Charge, Sprint, Premeditation, Stealth, Stoneform, Escape Artist,
  Spell Reflection, and Berserker Rage.

## v1.7.8 (2026-08-05)
- Fixed a teammate or opponent sometimes permanently showing as an unnamed
  "Unknown" entry in match history instead of their real name/class,
  usually in 3v3+ games where a group forms right as the match starts. WoW
  briefly returns a placeholder name for players it hasn't loaded info for
  yet, and that placeholder was being recorded as if it were real — now
  it's skipped so the real name gets captured once it's actually known.

## v1.7.7 (2026-08-04)
- Fixed Marks of Honor sometimes showing as 0 right after logging in or
  reloading. A timing issue could read your bags before they were fully
  loaded and overwrite your real mark count with zero — your correct count
  now re-syncs automatically the next time you log in.

## v1.7.6 (2026-08-02)
- Fixed arena Marks of Honor not registering correctly when a party
  converts to a raid mid-match.
- Announcer callouts now wait a beat so they don't overlap game sound
  effects.

## v1.7.5 (2026-08-02)
- Fixed duplicate/spammy Marks of Honor chat messages.
- Fixed an error sending party callouts while in a raid group.

## v1.7.3 (2026-08-02)
- Party chat callouts (trinket, drink, CC, cooldowns, etc.) are now
  configurable.
- More reliable class-icon automarking on enemies in arena.

## v1.7.2 (2026-08-02)
- Fixed Battleground Mark of Honor counts not syncing correctly to the
  currency tracker.

## v1.7.1 (2026-08-02)
- Party chat callouts are now limited to majors only (trinket, drink,
  walls, lust, res) — no more chat spam for minor abilities.

## v1.7.0 (2026-08-02)
- Added party chat callouts for major cooldowns.
- Added automatic class-icon marking on enemies in arena.

## v1.6.0 (2026-08-02)
- Added Honor / Arena Points / Battleground Marks tracking, synced to
  arenaarmory.com for gear-upgrade affordability.

## v1.5.0 (2026-07-26)
- Added a GladiatorlosSA-style voice pack announcer (optional, off by
  default).
- Fixed skirmish matches incorrectly affecting your rated CR.

---
Full version history: https://github.com/alexdaltonmccoy/arena-armory-addon/tags
