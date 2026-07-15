# Arena Armory (WoW TBC Classic Addon)

Arena frames + match recording addon for Burning Crusade Classic Anniversary (2.5.6), the companion addon for [arenaarmory.com](https://arenaarmory.com).

Competes with Gladdy / GladiusEx / sArena and adds GladiatorlosSA-style audio callouts, plus a structured match recorder whose data can be imported by the Arena Armory desktop app for statistical analysis.

## Features

- **Arena frames** (`arena1`–`arena5`): class-colored health bars, power bars, class icons, names, cast bars. Click to target (left) or focus (right).
- **Trinket tracker**: PvP trinket and Will of the Forsaken usage with cooldown swirl.
- **Diminishing returns tracker**: per-opponent DR icons with level (1/2, 1/4, immune) and reset timers, powered by DRList-1.0.
- **Cooldown tracker**: key enemy cooldowns appear as icons after first use.
- **CC/immunity overlay**: active crowd control or immunity shown over the class icon with duration.
- **Spec detection**: infers enemy specs from observed spells (no hostile inspect in TBC).
- **Audio announcer**: text-to-speech callouts for enemy trinkets, drinking, CC casts, resurrects, and low health.
- **Match recorder**: every arena match is saved to SavedVariables with map, bracket, comps (as/vs), result, rating changes, deaths, and scoreboard stats.

## Install (development)

Symlink or copy the `ArenaArmory` folder into your AddOns directory:

TBC Anniversary uses the `_anniversary_` flavor folder (`_classic_` is MoP Classic, `_classic_era_` is Vanilla/HC/SoD):

```powershell
New-Item -ItemType Junction `
  -Path "C:\Program Files (x86)\World of Warcraft\_anniversary_\Interface\AddOns\ArenaArmory" `
  -Target "C:\dev\wow-gladius\ArenaArmory"
```

## Slash commands

| Command | Effect |
|---|---|
| `/aa` | Open options |
| `/aa test` | Toggle test mode (fake opponents for layout work) |
| `/aa lock` | Lock/unlock the drag anchor |
| `/aa matches` | Print stored match count |

## Match data

Matches are appended to the `ArenaArmoryMatches` SavedVariable and written to disk on logout or `/reload`:

```
WTF\Account\<ACCOUNT>\SavedVariables\ArenaArmory.lua
```

Schema (v1), per match: `guid`, `startedAt`, `endedAt`, `durationSeconds`, `map`, `bracket`, `result` (`win`/`loss`/`draw`/`abandoned`), `player`, `team[]` (name/class/spec), `enemyTeam[]` (name/class/spec), `deaths[]` (time offset, side, name), `ratings` (per team old/new), `scoreboard[]` (damage/healing/killing blows per player).

The Arena Armory desktop app watches this file and uploads new matches to arenaarmory.com.

## Development

- Lua 5.1 / WoW addon API, Interface `20506` (TBC Anniversary).
- Bundled libraries in `ArenaArmory/Libs`: Ace3 (AceAddon, AceEvent, AceTimer, AceConsole, AceDB, AceDBOptions, AceGUI, AceConfig), LibStub, CallbackHandler-1.0, DRList-1.0.
- Syntax check all addon files: `node .tools/check-lua.js`
