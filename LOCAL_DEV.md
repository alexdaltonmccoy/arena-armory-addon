# Local addon testing (no CurseForge / Wago deploy)

You can iterate on `ArenaArmory/` and test in-game with `/reload`. Release
pipelines are only needed when shipping to players.

## Install from this repo

Point the game at your git checkout (junction = no copy, edits are live after
`/reload`):

```powershell
# TBC Anniversary client (not _classic_ / _classic_era_)
$wowAddOns = "C:\Program Files (x86)\World of Warcraft\_anniversary_\Interface\AddOns"
$src = "C:\dev\wow-gladius\ArenaArmory"

# If a real folder already exists there, remove it first (junctions replace copies):
# Remove-Item -LiteralPath "$wowAddOns\ArenaArmory" -Recurse -Force
cmd /c mklink /J "$wowAddOns\ArenaArmory" "$src"
```

A normal copied folder will **not** pick up repo edits — confirm with
`(Get-Item $wowAddOns\ArenaArmory).LinkType` → should be `Junction`.

**Warning:** CurseForge / WowUp "Update" replaces the junction with a real
folder and can **delete the git checkout contents** through the old link.
After any Curse update: restore from git if needed (`git restore ArenaArmory`),
then re-run the `mklink /J` commands above. Prefer disabling auto-update for
Arena Armory while developing.

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

## Diagnosing announcer (voice clips)

Callouts play shipped `ArenaArmory/Media/Voice/*.ogg` via `PlaySoundFile`
(GladiatorlosSA-style). TTS is optional and off by default. Unpackaged
checkouts (version `dev`) turn chat tracing on automatically.

Regenerate clips (Google Chirp3-HD female, arena pace):

```powershell
$env:GOOGLE_CLOUD_PROJECT = "wow-classic-armory-production"
python scripts/generate-voice-pack.py --voice en-US-Chirp3-HD-Aoede --rate 1.35
```

In a skirmish (or any arena):

```
/aa announcer
/aa announcer debug
/aa announcer test
```

- **`/aa announcer`** — dumps flags, sound channel, `inArena`, build id.
- **`/aa announcer debug`** — traces CLEU/cast triggers and `PlaySoundFile`.
- **`/aa announcer test`** — plays `trinket.ogg` (confirm Master volume).
- **`/aa announcer off`** — stop the chat spam.

What to look for:

1. `build=voice1` missing after `/reload` → wrong AddOns folder / no junction.
2. `PlaySoundFile ... willPlay=nil` → bad path or Master volume muted.
3. `MISS: bubble from X not in guid map` → enemy not mapped to `arenaN` yet.
4. CLEU with `sound=nil` for Bubble/Blind → spell rank missing from
   `AA.ANNOUNCE_SPELLS` in `Data/Spells.lua`.
5. No CLEU lines when enemies cast → not in arena (`instanceType` should be
   `arena`) or CLEU fan-out issue.

Paste the dump + a few debug lines from a skirmish when filing a bug.

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
