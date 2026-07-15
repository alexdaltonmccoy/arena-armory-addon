# Development

Lua 5.1 / WoW addon API, Interface `20506` (TBC Anniversary). The addon lives
in `ArenaArmory/`; everything else in the repo (marketing assets, scripts,
packaging config) is excluded from shipped zips via `.pkgmeta`.

Bundled libraries in `ArenaArmory/Libs`: Ace3 (AceAddon, AceEvent, AceTimer,
AceConsole, AceDB, AceDBOptions, AceGUI, AceConfig), LibStub,
CallbackHandler-1.0, DRList-1.0.

Syntax check all addon files: `node .tools/check-lua.js`

## Local install

Symlink or copy the `ArenaArmory` folder into your AddOns directory.
TBC Anniversary uses the `_anniversary_` flavor folder (`_classic_` is MoP
Classic, `_classic_era_` is Vanilla/HC/SoD):

```powershell
New-Item -ItemType Junction `
  -Path "C:\Program Files (x86)\World of Warcraft\_anniversary_\Interface\AddOns\ArenaArmory" `
  -Target "C:\dev\wow-gladius\ArenaArmory"
```

A dev checkout shows version "dev" in-game; releases get their version stamped
from the git tag (see Releasing below).

## Slash commands

| Command | Effect |
|---|---|
| `/aa` | Open options |
| `/aa test` | Toggle test mode (fake opponents for layout work) |
| `/aa lock` | Lock/unlock the drag anchor |
| `/aa matches` | Print stored match count |

## Match data

Matches are appended to the `ArenaArmoryMatches` SavedVariable and written to
disk on logout or `/reload`:

```
WTF\Account\<ACCOUNT>\SavedVariables\ArenaArmory.lua
```

Schema (v2), per match:

- `guid`, `schemaVersion`, `startedAt`, `endedAt`, `durationSeconds`
- `map`, `bracket`, `result` (`win`/`loss`/`draw`/`abandoned`/`unknown`), `ourSide`, `winner`
- `player`, `team[]`, `enemyTeam[]` (name/class/spec)
- `deaths[]` — `{ t, side, name }` (t = seconds since match start)
- `events[]` (v2, capped at 400/match) — `{ t, e, side, name, spellId, spell, ... }`
  where `e` is one of:
  - `cd` — tracked cooldown cast (from `AA.COOLDOWN_SPELLS`)
  - `trinket` — PvP trinket / racial CC break
  - `int` — successful interrupt (`targetName`, `targetSpell`)
  - `cc` — crowd control applied (`cat` = DRList category); side is the victim's
- `ratings` (per team old/new), `scoreboard[]` (damage/healing/killing blows per player)

The Arena Armory desktop app watches this file and uploads new matches to
arenaarmory.com.

## Releasing

Releases are fully automated by `.github/workflows/release.yml` using the
[BigWigs packager](https://github.com/BigWigsMods/packager):

```powershell
git tag v1.2.0
git push origin v1.2.0
```

That packages the addon (per `.pkgmeta`), stamps `@project-version@` in the
TOC from the tag, and uploads to CurseForge (`X-Curse-Project-ID`), Wago
(`X-Wago-ID`), and GitHub Releases. Repo secrets required: `CF_API_KEY`,
`WAGO_API_TOKEN`.

For a manual local zip: `powershell -File scripts\package.ps1 -Version 1.2.0`
(outputs to `dist/`).
