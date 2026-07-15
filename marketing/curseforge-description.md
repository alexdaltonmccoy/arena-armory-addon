# Arena Armory

**Arena enemy frames, trinket & DR tracking, an audio announcer, and automatic match history recording — in one addon, built for TBC Classic (Anniversary).**

Arena Armory is a complete arena toolkit in the spirit of Gladdy and GladiusEx, rebuilt from scratch for the modern TBC Anniversary client — plus something no other arena addon does: it records every match you play so you can review your history, comps, and winrates on [arenaarmory.com](https://arenaarmory.com).

## Enemy Frames

- Class-colored health and power bars for up to 5 arena opponents, with cast bars and name/spec text
- **Frames persist through stealth, vanish, and death** — stealthed enemies dim instead of disappearing, so you never lose track of a rogue
- Placeholder rows for opponents that haven't been sighted yet, so you always see the full enemy comp
- Click to target, right-click to focus
- Two visual styles: **Modern** (flat, Midnight-inspired) and **Classic**
- Fully movable and scalable, with live-updating size and layout options — no /reload needed

## Trackers

- **PvP trinket** and racial CC-break tracking with faction medallion icons and cooldown timers
- **Diminishing returns** per opponent (DRList-1.0), with DR level and reset timers — position left or right of the frames
- **Enemy cooldowns** (Blind, Ice Block, NS, and more) shown after first use
- **Important auras** (CC, immunities) overlaid on the class icon
- **Spec detection** from buffs and observed spells — often identifies specs at the gates

## Announcer (GladiatorlosSA-style)

Audio alerts via text-to-speech for enemy trinkets, drinking, resurrects, big CC casts, and low health — no sound pack downloads needed. Pick a voice or let it choose automatically.

## Match Recorder

Every arena match is saved automatically: map, bracket, both teams with classes and specs, result, duration, deaths timeline, and the full scoreboard. Pair it with the **Arena Armory desktop app** to sync your history to [arenaarmory.com](https://arenaarmory.com) and get winrate breakdowns by comp, map, and bracket — your matches belong to your character, viewable by anyone, like an armory for arena.

## Quick Start

- `/aa` — options
- `/aa test` — test mode with fake opponents for positioning and styling
- `/aa lock` — lock/unlock frame position

## Feedback

Found a bug or want a feature? Report it on the project page. Match recording schema is documented in the README for anyone building tools on top of it.
