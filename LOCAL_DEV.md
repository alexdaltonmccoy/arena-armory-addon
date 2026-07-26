# Local addon testing (no CurseForge / Wago deploy)

You can iterate on `ArenaArmory/` and test in-game with `/reload`. Release
pipelines are only needed when shipping to players.

## Install from this repo

Point the game at your git checkout (junction = no copy, edits are live after
`/reload`):

```powershell
# Adjust the Classic Anniversary path if yours differs
$wowAddOns = "C:\Program Files (x86)\World of Warcraft\_classic_\Interface\AddOns"
$src = "C:\dev\wow-gladius\ArenaArmory"

# Remove a previous copy/junction if needed, then:
cmd /c mklink /J "$wowAddOns\ArenaArmory" "$src"
```

Or copy `ArenaArmory` into `Interface\AddOns` after each change.

Enable **Arena Armory** in the AddOns list (character select → AddOns).

## After each code change

1. Edit files under `C:\dev\wow-gladius\ArenaArmory`
2. In-game: `/reload`
3. Re-test (no git push / CurseForge required)

Syntax check from repo root (optional):

```powershell
node .tools/check-lua.js
```

## Diagnosing blank Rating / MMR columns

Wins/losses and comps can record while Rating/MMR stay `-` if personal rating
APIs return empty at finalize time (common after Blizzard Anniversary UI
hotfixes).

**On the end-of-match scoreboard of a RATED arena** (not skirmish), run:

```
/aa ratings
```

Chat will dump:

- `C_PvP.GetTeamInfo` / `GetBattlefieldTeamInfo`
- `GetBattlefieldScore` trailing returns (`bgRating`, `change`, `preMMR`, …)
- All keys from `C_PvP.GetScoreInfo` (so renamed fields are visible)
- Whether `RatingsFromScoreboard` would fill the stats panel

Paste that dump when filing a bug — it is the ground truth for the live client.

Also: `/aa stats` only shows ratings for matches that already stored a
`ratings` table. Old matches recorded before a fix stay blank until you play
new games (or we add a backfill).

## Reminder

SavedVariables flush on **logout** or **`/reload`**. The desktop app only sees
matches after that.
