# AI-Powered Play-by-Play Match Review — Feasibility Spike (2026-08-17)

**Status:** Spike complete. No scope committed, no build started — this settles one input to the log-first / video-first / hybrid direction call, per Alex's 8/17 note in `PORTFOLIO_ROADMAP.md`. The Arena premium-tier build stays paused pending that direction decision; this memo doesn't unpause it on its own.

## Question

Does WoW Classic Anniversary's combat log carry unit position data, and does the addon's existing `Recorder` capture already log it? That determines whether "AI narrates what happened in your match" can be built purely from combat-log data, or requires video.

## Method

Read the addon's actual event-handling code rather than relying on general WoW-API memory:
- [`ArenaArmory/Core/Core.lua:184-191`](ArenaArmory/Core/Core.lua#L184) — how `COMBAT_LOG_EVENT_UNFILTERED` is unpacked via `CombatLogGetCurrentEventInfo()`.
- [`ArenaArmory/Modules/Recorder.lua`](ArenaArmory/Modules/Recorder.lua) — the full CLEU handler (`OnCLEU`) and everything currently persisted to `ArenaArmoryMatches`.
- Grepped the whole `ArenaArmory` tree for `position`/`UnitPosition`/`GetPlayerMapPosition` to check whether position is captured anywhere outside the combat log path.

## Findings

**1. The combat log carries no position data — confirmed from the addon's own arg unpacking, not assumption.**

`Core.lua` unpacks CLEU as `timestamp, subevent, hideCaster, sourceGUID, sourceName, sourceFlags, sourceRaidFlags, destGUID, destName, destFlags, destRaidFlags, ...subevent-specific args` — the standard, stable Blizzard shape. No coordinate field exists anywhere in it, for any subevent, on Classic Anniversary or any other WoW client. This has been true across every WoW version; it's why WarcraftLogs/Details never derive positional replay from the combat log file itself — where WCL *does* show movement trails on raid encounters, that data comes from a separate addon-side position poller merged in at upload time, not from the log.

**2. The addon captures no position today, and there's nothing to "turn on" — the source it would read from doesn't carry it.**

Grep of `ArenaArmory/` for position-related APIs returned zero hits outside library files (an AceGUI edit-box's text-cursor position, unrelated). `Recorder.lua`'s `OnCLEU` handler ([Recorder.lua:342](ArenaArmory/Modules/Recorder.lua#L342)) only ever sees the fields above.

**3. Second-order finding — live-polling position instead of relying on the log doesn't fix this either, for the side that matters most.**

`UnitPosition()` only resolves for the player and same-instance party/raid members; Blizzard blocks it for hostile arena opponents (a deliberate anti-radar-hack restriction). So there is no path — log-derived or live-poll-derived — to capturing **enemy** movement or positioning. A friendly-side trace is technically obtainable via live polling (not from the log), but opponent positioning — kiting, LoS breaks, peel angles — is usually the more valuable half of positional coaching, and it's unreachable either way.

*Confidence note: (1) and (2) are read directly from this addon's code and are certain. (3) is standard, long-documented WoW addon-API behavior but was not live-verified in-game this session (no client access from here). A 5-minute live check — `/dump UnitPosition("arena1")` during a real arena match — would close that gap before anyone treats it as final.*

## What this means for log-first vs. video-first vs. hybrid

- **Log-first is fully tractable for everything non-spatial**: ability sequencing, CD/trinket usage and timing, interrupts (attempt vs. land), CC chains and DR windows, target-swaps/focus-fire, damage/healing timeline. This isn't hypothetical capacity — `Recorder.lua`'s v4 schema is **already recording almost all of it** into `ArenaArmoryMatches`: `events` (cd/int/cc/trinket, [Recorder.lua:313](ArenaArmory/Modules/Recorder.lua#L313)) and `timeline` (bucketed dmg/heal + enemy focus-target per bucket, [Recorder.lua:458](ArenaArmory/Modules/Recorder.lua#L458)). An AI play-by-play narrator over log data is a synthesis/prompting problem against data that already exists, not a new capture build.
- **Log-first structurally cannot do positional/spatial commentary**, on either side, by design of Blizzard's API — not a gap that smarter capture or a client-side change can close. No "you were out of peel range," no kiting/pathing feedback, no LoS-break analysis.
- **Video-first** is the only path to positional coaching, but it's a materially different and larger build — capture/storage/upload/processing pipeline, none of which exists today. Worth treating as a separate product bet, not an extension of the current recording pipeline.
- **Hybrid** is the pragmatic default this finding points to: ship AI narration on the log data already being captured (cheap — mostly LLM synthesis over `events`/`timeline`), and treat positional/video coaching as a separate, later, materially more expensive bet rather than bundling both into a v1.

## Recommendation

Proceed with a log-first v1 scope (ability/CD/CC/focus-fire narration over existing `events`/`timeline` data) as the direction to size next. Do not fold positional/video coaching into that scope — it's a different build with a different cost profile, gated on its own decision later. Next step is Alex's call on the direction, then a real scoping pass (data sufficiency for narration quality, LLM cost per match, where the narration surfaces — desktop app vs. web).

## Open items

- Live-verify finding 3 (`UnitPosition` on `arenaN`) in a real match before it's load-bearing for any pitch deck or customer-facing claim.
- If hybrid is chosen: no engineering follow-up needed to *start* — the data already exists. The open question is narration quality/cost from an LLM prompted over `events`/`timeline`, which is a prototyping task, not a data-capture one.
