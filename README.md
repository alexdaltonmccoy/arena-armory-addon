# Arena Armory

**Arena enemy frames, trinket & DR tracking, an audio announcer, and automatic match history recording — in one addon, built for TBC Classic (Anniversary).**

Arena Armory is a complete arena toolkit in the spirit of Gladdy and GladiusEx, rebuilt from scratch for the modern TBC Anniversary client — plus something no other arena addon does: it records every match you play so you can review your history, comps, and winrates on [arenaarmory.com](https://arenaarmory.com).

**Get it:** [CurseForge](https://www.curseforge.com/wow/addons/arena-armory) · [Wago](https://addons.wago.io/addons/b6XeJbKp) · [GitHub Releases](https://github.com/alexdaltonmccoy/arena-armory-addon/releases) — or install with the CurseForge app / WowUp.

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

Every arena match is saved automatically: map, bracket, both teams with classes and specs, result, duration, deaths timeline, an event timeline (cooldowns, trinkets, interrupts, CC), and the full scoreboard. Pair it with the **Arena Armory desktop app** to sync your history to [arenaarmory.com](https://arenaarmory.com) and get winrate breakdowns by comp, map, and bracket — your matches belong to your character, viewable by anyone, like an armory for arena.

## Quick Start

- `/aa` — options
- `/aa test` — test mode with fake opponents for positioning and styling
- `/aa lock` — lock/unlock frame position

## Feedback

Found a bug or want a feature? [Open an issue](https://github.com/alexdaltonmccoy/arena-armory-addon/issues) or leave a comment on the project page.

---

Building tools on top of the match data, or hacking on the addon itself? See [DEVELOPMENT.md](DEVELOPMENT.md) for the SavedVariables schema, local install, and release process.
