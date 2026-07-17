-- Match recorder: structured per-match records persisted to the
-- ArenaArmoryMatches SavedVariable for the desktop companion app to ingest.
local _, AA = ...
local addon = AA.addon

local Recorder = addon:NewModule("Recorder", "AceEvent-3.0", "AceTimer-3.0")
AA.Recorder = Recorder

local DRList = LibStub("DRList-1.0")

-- v2 adds the per-match `events` timeline (cooldowns, trinkets, interrupts, CC).
-- v3 adds per-player rating fields on scoreboard rows (rating, ratingChange,
-- prematchMMR, postmatchMMR): TBC Anniversary has no arena teams, so ratings
-- are personal and only exposed per player via C_PvP.GetScoreInfo.
-- v4 adds `timeline`: bucketed damage/healing per side plus enemy focus
-- target per bucket (target-swap analysis on the website).
local SCHEMA_VERSION = 4

-- Bounds SavedVariables growth on very long/chaotic matches.
local MAX_EVENTS = 400

-- Damage/healing timeline resolution and cap (120 buckets = 20 minutes).
local TIMELINE_STEP = 10
local MAX_BUCKETS = 120

-- subevent -> which forwarded CLEU arg carries the damage amount:
-- SWING_* has no spell triplet, so its payload starts at arg12.
local DAMAGE_AMOUNT_ARG = {
    SWING_DAMAGE = 12,
    RANGE_DAMAGE = 15,
    SPELL_DAMAGE = 15,
    SPELL_PERIODIC_DAMAGE = 15,
    DAMAGE_SHIELD = 15,
}
local HEAL_EVENTS = {
    SPELL_HEAL = true,
    SPELL_PERIODIC_HEAL = true,
}

local current   -- in-progress match record
local finalized

local function NewMatchGUID()
    return ("AA-%d-%04x%04x"):format(time(), math.random(0, 0xffff), math.random(0, 0xffff))
end

-- GetTalentTabInfo differs across client flavors; find pointsSpent defensively.
local function PlayerSpec()
    if not GetTalentTabInfo or not GetNumTalentTabs then return nil end
    local bestName, bestPoints = nil, -1
    for tab = 1, GetNumTalentTabs() do
        local r1, r2, r3, r4, r5 = GetTalentTabInfo(tab)
        local name, points
        if type(r1) == "string" then
            name = r1
            points = (type(r3) == "number" and r3) or (type(r5) == "number" and r5) or 0
        else
            -- Modern signature: id, name, description, icon, pointsSpent
            name = r2
            points = r5 or 0
        end
        if type(points) == "number" and points > bestPoints then
            bestPoints, bestName = points, name
        end
    end
    return bestName
end

local function DetectBracket()
    if GetBattlefieldStatus then
        for i = 1, (GetMaxBattlefieldID and GetMaxBattlefieldID() or 3) do
            local status, _, _, _, _, teamSize = GetBattlefieldStatus(i)
            if status == "active" and teamSize and teamSize > 0 then
                return teamSize
            end
        end
    end
    -- Fallback: count our side.
    return math.max(GetNumGroupMembers and GetNumGroupMembers() or 1, 1)
end

-------------------------------------------------------------------------------
-- Match lifecycle
-------------------------------------------------------------------------------

function Recorder:OnArenaJoined()
    if not AA.db.profile.recorder.enabled then return end
    local mapName = GetInstanceInfo()
    finalized = false

    local playerName = AA.StripRealm(UnitName("player"))
    local _, playerClass = UnitClass("player")
    local realmName = GetRealmName and GetRealmName() or ""

    current = {
        guid = NewMatchGUID(),
        schemaVersion = SCHEMA_VERSION,
        startedAt = time(),
        startClock = GetTime(),
        map = mapName,
        bracket = DetectBracket(),
        player = { name = playerName, realm = realmName, class = playerClass, spec = PlayerSpec() },
        team = {},
        enemyTeam = {},
        deaths = {},
        events = {},
        result = nil,
    }
    self.lastTrinket = {}
    -- Timeline accumulators: [bucket] = total; focusDmg[bucket][victim] = dmg.
    self.tl = { dmgF = {}, dmgE = {}, healF = {}, healE = {}, focusDmg = {} }

    self:SnapshotFriendlyTeam()
    self:SnapshotEnemyTeam()
    self.pollTimer = self:ScheduleRepeatingTimer("PollWinner", 2)
end

function Recorder:SnapshotFriendlyTeam()
    if not current then return end
    wipe(current.team)
    table.insert(current.team, {
        name = current.player.name,
        class = current.player.class,
        spec = current.player.spec,
    })
    local n = GetNumGroupMembers and (GetNumGroupMembers() - 1) or GetNumPartyMembers()
    for i = 1, math.max(n or 0, 0) do
        local unit = "party" .. i
        if UnitExists(unit) then
            local _, classToken = UnitClass(unit)
            local name = AA.StripRealm(UnitName(unit))
            table.insert(current.team, {
                name = name,
                class = classToken,
                -- Teammate specs come from SpecDetection's friendly tracking
                -- (signature spells/buffs); re-snapshotted at match end.
                spec = name and AA.friendlySpecs and AA.friendlySpecs[name] or nil,
            })
        end
    end
end

function Recorder:SnapshotEnemyTeam()
    if not current then return end
    for i = 1, AA.MAX_ARENA_OPPONENTS do
        local unit = "arena" .. i
        local classToken = AA.unitClass[unit]
        if classToken or UnitExists(unit) then
            if not classToken then
                local _, ct = UnitClass(unit)
                classToken = ct
            end
            current.enemyTeam[i] = current.enemyTeam[i] or {}
            local e = current.enemyTeam[i]
            e.name = e.name or AA.StripRealm(UnitName(unit))
            e.class = e.class or classToken
            e.spec = AA.detectedSpecs[i] or e.spec
        end
    end
end

function Recorder:OnOpponentUpdate()
    self:SnapshotEnemyTeam()
end

function Recorder:OnSpecDetected(_, i, spec)
    if current and current.enemyTeam[i] then
        current.enemyTeam[i].spec = spec
    elseif current then
        current.enemyTeam[i] = { spec = spec }
    end
end

-- "enemy"/"friendly" for player units, nil for pets/NPCs/unflagged sources.
local function SideOfFlags(flags)
    if not flags or bit.band(flags, COMBATLOG_OBJECT_TYPE_PLAYER) == 0 then return nil end
    if bit.band(flags, COMBATLOG_OBJECT_REACTION_HOSTILE) > 0 then return "enemy" end
    if bit.band(flags, COMBATLOG_OBJECT_REACTION_FRIENDLY) > 0 then return "friendly" end
    return nil
end

-- Same, but pets/guardians count toward their owner's side: timeline damage
-- would badly undercount hunters/warlocks otherwise.
local UNIT_TYPE_MASK = bit.bor(
    COMBATLOG_OBJECT_TYPE_PLAYER,
    COMBATLOG_OBJECT_TYPE_PET,
    COMBATLOG_OBJECT_TYPE_GUARDIAN
)
local function SideIncludingPets(flags)
    if not flags or bit.band(flags, UNIT_TYPE_MASK) == 0 then return nil end
    if bit.band(flags, COMBATLOG_OBJECT_REACTION_HOSTILE) > 0 then return "enemy" end
    if bit.band(flags, COMBATLOG_OBJECT_REACTION_FRIENDLY) > 0 then return "friendly" end
    return nil
end

-- Appends a timeline event (schema v2), bounded so a marathon match can't
-- bloat SavedVariables.
local function AddEvent(ev)
    if not current or finalized or not current.startClock then return end
    if #current.events >= MAX_EVENTS then return end
    ev.t = math.floor(GetTime() - current.startClock)
    table.insert(current.events, ev)
end

-- Trinket events can arrive from both CLEU and the Trinket module's
-- UNIT_SPELLCAST_SUCCEEDED path (AA_TRINKET_USED); dedupe within 2s.
function Recorder:AddTrinketEvent(side, name, spellId)
    if not current then return end
    local key = (name or "?") .. "-" .. tostring(spellId)
    local now = GetTime()
    if self.lastTrinket[key] and now - self.lastTrinket[key] < 2 then return end
    self.lastTrinket[key] = now
    AddEvent({
        e = "trinket", side = side, name = name,
        spellId = spellId, spell = AA.GetSpellName(spellId),
    })
end

function Recorder:OnTrinketUsed(_, i, spellId)
    local name = current and current.enemyTeam[i] and current.enemyTeam[i].name
    if not name and UnitExists("arena" .. i) then
        name = AA.StripRealm(UnitName("arena" .. i))
    end
    self:AddTrinketEvent("enemy", name, spellId)
end

function Recorder:OnCLEU(_, _, subevent, sourceGUID, sourceName, sourceFlags,
                         destGUID, destName, destFlags, spellId, spellName, _, arg15, arg16)
    if not current then return end

    -- Damage/healing timeline (hot path: bail out with cheap checks first).
    local dmgArg = DAMAGE_AMOUNT_ARG[subevent]
    if dmgArg or HEAL_EVENTS[subevent] then
        if finalized or not current.startClock or not self.tl then return end
        local side = SideIncludingPets(sourceFlags)
        if not side then return end
        local idx = math.floor((GetTime() - current.startClock) / TIMELINE_STEP) + 1
        if idx < 1 or idx > MAX_BUCKETS then return end

        if dmgArg then
            -- For SWING_DAMAGE the amount sits where spellId usually is.
            local amount = (dmgArg == 12) and tonumber(spellId) or tonumber(arg15)
            if not amount or amount <= 0 then return end
            local t = (side == "friendly") and self.tl.dmgF or self.tl.dmgE
            t[idx] = (t[idx] or 0) + amount

            -- Focus tracking: enemy damage into friendly PLAYERS (not pets),
            -- to derive who they were training and when they swapped.
            if side == "enemy" and destFlags
                and bit.band(destFlags, COMBATLOG_OBJECT_TYPE_PLAYER) > 0
                and bit.band(destFlags, COMBATLOG_OBJECT_REACTION_FRIENDLY) > 0 then
                local victim = AA.StripRealm(destName)
                if victim then
                    local bucket = self.tl.focusDmg[idx]
                    if not bucket then
                        bucket = {}
                        self.tl.focusDmg[idx] = bucket
                    end
                    bucket[victim] = (bucket[victim] or 0) + amount
                end
            end
        else
            -- Effective healing only: amount minus overheal.
            local amount = (tonumber(arg15) or 0) - (tonumber(arg16) or 0)
            if amount <= 0 then return end
            local t = (side == "friendly") and self.tl.healF or self.tl.healE
            t[idx] = (t[idx] or 0) + amount
        end
        return
    end

    if subevent == "UNIT_DIED" then
        local side
        local enemyUnit = AA.UnitByGUID(destGUID)
        if enemyUnit then
            side = "enemy"
        elseif destGUID == UnitGUID("player") then
            side = "friendly"
        else
            for i = 1, 4 do
                if UnitExists("party" .. i) and destGUID == UnitGUID("party" .. i) then
                    side = "friendly"
                    break
                end
            end
        end
        if not side then return end

        table.insert(current.deaths, {
            t = math.floor(GetTime() - current.startClock),
            side = side,
            name = AA.StripRealm(destName),
        })
        return
    end

    if subevent == "SPELL_CAST_SUCCESS" then
        local side = SideOfFlags(sourceFlags)
        if not side then return end
        if AA.TRINKET_SPELLS[spellId] or AA.RACIAL_CC_BREAKS[spellId] then
            self:AddTrinketEvent(side, AA.StripRealm(sourceName), spellId)
        elseif AA.COOLDOWN_SPELLS[spellId] or AA.INTERRUPT_CAST_NAMES[spellName] then
            -- Interrupts are matched by NAME as well: players cast down-ranked
            -- Kick/Pummel/Counterspell, whose IDs aren't in the cooldown list,
            -- and the site derives juke rates from attempts vs. lands.
            AddEvent({
                e = "cd", side = side, name = AA.StripRealm(sourceName),
                spellId = spellId, spell = spellName,
            })
        end
    elseif subevent == "SPELL_INTERRUPT" then
        local side = SideOfFlags(sourceFlags)
        if not side then return end
        -- arg15 is the interrupted spell's ID for SPELL_INTERRUPT.
        AddEvent({
            e = "int", side = side, name = AA.StripRealm(sourceName),
            spellId = spellId, spell = spellName,
            targetName = AA.StripRealm(destName),
            targetSpell = arg15 and AA.GetSpellName(arg15) or nil,
        })
    elseif subevent == "SPELL_AURA_APPLIED" and arg15 == "DEBUFF" then
        -- Crowd control on players, tagged with its DRList category; side is
        -- the victim's side. DR level is derivable from the event sequence.
        local victimSide = SideOfFlags(destFlags)
        if not victimSide then return end
        local category = DRList:GetCategoryBySpellID(spellId)
        if category and category ~= "knockback" then
            AddEvent({
                e = "cc", side = victimSide, name = AA.StripRealm(destName),
                spellId = spellId, spell = spellName, cat = category,
            })
        end
    end
end

-------------------------------------------------------------------------------
-- Match end
-------------------------------------------------------------------------------

-- Densifies the timeline accumulators into the compact record shape:
-- arrays of per-bucket totals, the enemy's focus target per bucket (""
-- when no enemy damage landed), and the focus-swap count.
function Recorder:BuildTimeline()
    if not self.tl or not current then return nil end
    local duration = math.max(current.durationSeconds or 0, 1)
    local n = math.min(math.ceil(duration / TIMELINE_STEP), MAX_BUCKETS)
    if n < 1 then return nil end

    local any = false
    local function densify(src)
        local out = {}
        for i = 1, n do
            local v = src[i] or 0
            if v > 0 then any = true end
            out[i] = v
        end
        return out
    end
    local dmgF, dmgE = densify(self.tl.dmgF), densify(self.tl.dmgE)
    local healF, healE = densify(self.tl.healF), densify(self.tl.healE)
    if not any then return nil end

    local focus = {}
    local swaps, lastTarget = 0, nil
    for i = 1, n do
        local best, bestDmg = "", 0
        local bucket = self.tl.focusDmg[i]
        if bucket then
            for name, dmg in pairs(bucket) do
                if dmg > bestDmg then best, bestDmg = name, dmg end
            end
        end
        focus[i] = best
        if best ~= "" then
            if lastTarget and best ~= lastTarget then swaps = swaps + 1 end
            lastTarget = best
        end
    end

    return {
        step = TIMELINE_STEP,
        dmg = { f = dmgF, e = dmgE },
        heal = { f = healF, e = healE },
        focus = focus,
        swaps = swaps,
    }
end

function Recorder:PollWinner()
    if not current or finalized then return end
    local winner = GetBattlefieldWinner and GetBattlefieldWinner()
    if winner ~= nil then
        self:Finalize(winner)
    end
end

function Recorder:CollectScoreboard()
    if not GetNumBattlefieldScores then return nil end
    local rows = {}
    for i = 1, GetNumBattlefieldScores() do
        -- 2.5.6 signature (verified against live data): name, killingBlows,
        -- honorableKills, deaths, honorGained, faction, rank, race, class,
        -- classToken, damageDone, healingDone
        local name, killingBlows, _, deaths, _, faction, _, race, _,
            classToken, damageDone, healingDone = GetBattlefieldScore(i)
        if name then
            local row = {
                name = AA.StripRealm(name),
                team = faction, -- 0 = green, 1 = gold in arena
                race = race,
                class = classToken,
                killingBlows = killingBlows,
                deaths = deaths,
                damage = damageDone,
                healing = healingDone,
            }
            -- Anniversary rating is PERSONAL (arena teams are gone), exposed
            -- per player on the modern scoreboard API that 2.5.6 ships.
            if C_PvP and C_PvP.GetScoreInfo then
                local info = C_PvP.GetScoreInfo(i)
                if type(info) == "table" then
                    row.rating = info.rating
                    row.ratingChange = info.ratingChange
                    row.prematchMMR = info.prematchMMR
                    row.postmatchMMR = info.postmatchMMR
                    if info.faction ~= nil then row.team = info.faction end
                end
            end
            table.insert(rows, row)
        end
    end
    return rows
end

-- Builds the team-shaped `ratings` record from per-player scoreboard data.
-- Our side gets the player's own pre/post rating; both sides get an MMR
-- averaged from their players' prematchMMR (Blizzard's per-row rating is
-- prematch, with ratingChange applied after - mirrors PVPMatchResults).
function Recorder:RatingsFromScoreboard(rows)
    if type(rows) ~= "table" then return nil end
    local record = current or self.lastRecord
    local me = record and record.player and record.player.name
    if not me then return nil end

    local ratings
    local mmrSum, mmrCount = { [0] = 0, [1] = 0 }, { [0] = 0, [1] = 0 }
    local myRow
    for _, row in ipairs(rows) do
        if row.name == me then myRow = row end
        local side = row.team
        if (side == 0 or side == 1) and (row.prematchMMR or 0) > 0 then
            mmrSum[side] = mmrSum[side] + row.prematchMMR
            mmrCount[side] = mmrCount[side] + 1
        end
    end

    if myRow and (myRow.rating or 0) > 0 and (myRow.team == 0 or myRow.team == 1) then
        local ourSide = myRow.team
        local oldR = myRow.rating
        local newR = oldR + (myRow.ratingChange or 0)
        ratings = {}
        ratings[ourSide] = {
            oldRating = oldR,
            newRating = newR,
            rating = (myRow.postmatchMMR or 0) > 0 and myRow.postmatchMMR
                or (mmrCount[ourSide] > 0 and math.floor(mmrSum[ourSide] / mmrCount[ourSide] + 0.5) or nil),
        }
        local enemySide = 1 - ourSide
        if mmrCount[enemySide] > 0 then
            ratings[enemySide] = {
                rating = math.floor(mmrSum[enemySide] / mmrCount[enemySide] + 0.5),
            }
        end
    end
    return ratings
end

function Recorder:CollectRatings()
    local ratings
    for teamIndex = 0, 1 do
        local teamName, oldRating, newRating, mmr
        -- 2.5.6 ships modern UI code, so C_PvP.GetTeamInfo can EXIST yet
        -- return nothing for TBC arenas. Never let its presence block the
        -- legacy API: try modern first, then fall back whenever it yielded
        -- no usable numbers.
        if C_PvP and C_PvP.GetTeamInfo then
            local info = C_PvP.GetTeamInfo(teamIndex)
            if info then
                teamName, oldRating, newRating, mmr = info.name, info.rating, info.ratingNew, info.ratingMMR
            end
        end
        local haveNumbers = (oldRating and oldRating > 0) or (newRating and newRating > 0)
            or (mmr and mmr > 0)
        if not haveNumbers and GetBattlefieldTeamInfo then
            local lName, lOld, lNew, lRating = GetBattlefieldTeamInfo(teamIndex)
            local legacyNumbers = (lOld and lOld > 0) or (lNew and lNew > 0) or (lRating and lRating > 0)
            if legacyNumbers or not teamName or teamName == "" then
                teamName, oldRating, newRating, mmr = lName, lOld, lNew, lRating
            end
        end
        -- Skirmishes report zeros/empty across the board; store nothing so
        -- consumers can tell "unrated" apart from "rated at 0".
        local meaningful = (oldRating and oldRating > 0) or (newRating and newRating > 0)
            or (mmr and mmr > 0) or (teamName and teamName ~= "")
        if meaningful then
            ratings = ratings or {}
            ratings[teamIndex] = {
                name = teamName,
                oldRating = oldRating,
                newRating = newRating,
                rating = mmr,
            }
        end
    end
    return ratings
end

function Recorder:Finalize(winner)
    if not current or finalized then return end
    finalized = true
    if self.pollTimer then
        self:CancelTimer(self.pollTimer)
        self.pollTimer = nil
    end

    current.durationSeconds = math.floor(GetTime() - current.startClock)
    current.endedAt = time()

    if winner == nil then
        current.result = "abandoned"
    else
        local ourSide = GetBattlefieldArenaFaction and GetBattlefieldArenaFaction()
        current.ourSide = ourSide
        current.winner = winner
        if ourSide ~= nil then
            current.result = (winner == ourSide) and "win" or "loss"
        elseif winner == 255 then
            current.result = "draw"
        else
            current.result = "unknown"
        end
    end

    -- One last comp snapshot in case late info arrived.
    self:SnapshotFriendlyTeam()
    self:SnapshotEnemyTeam()

    current.scoreboard = self:CollectScoreboard()
    -- Team-info APIs first (they carry team names), then per-player
    -- scoreboard ratings (the only source on Anniversary, where arena
    -- teams don't exist and team info reports zeros).
    current.ratings = self:CollectRatings() or self:RatingsFromScoreboard(current.scoreboard)

    -- Compact enemyTeam sparse array into a list.
    local enemies = {}
    for i = 1, AA.MAX_ARENA_OPPONENTS do
        if current.enemyTeam[i] then table.insert(enemies, current.enemyTeam[i]) end
    end
    current.enemyTeam = enemies
    current.startClock = nil

    -- Empty Lua tables are ambiguous (array vs map) for the desktop parser.
    if current.events and #current.events == 0 then current.events = nil end

    current.timeline = self:BuildTimeline()
    self.tl = nil

    -- Battlefield status reports teamSize 0 for skirmishes; the actual team
    -- rosters are the reliable source, so trust whichever count is largest.
    current.bracket = math.max(current.bracket or 1, #current.team, #enemies)

    table.insert(ArenaArmoryMatches.matches, current)
    addon:Print(("Match recorded: %s (%s). %d matches stored. View your history at %s")
        :format(current.map or "?", current.result or "?", #ArenaArmoryMatches.matches,
            AA.MatchesChatLink and AA.MatchesChatLink() or "arenaarmory.com"))
    -- Analytics (and anything else) can react to the finished match while its
    -- data is fresh in memory - no /reload needed.
    self:SendMessage("AA_MATCH_RECORDED", current)

    -- Ratings (and final scoreboard numbers) aren't available until
    -- UPDATE_BATTLEFIELD_SCORE fires after the match ends - often a beat
    -- AFTER the winner is known, which is when we finalize. Keep patching
    -- the stored record while the scoreboard is still up.
    if not current.ratings then
        self.lastRecord = current
        self.ratingRetries = 0
        if not self.ratingTimer then
            self.ratingTimer = self:ScheduleRepeatingTimer("RetryRatings", 1)
        end
    end

    current = nil
end

function Recorder:RetryRatings()
    local record = self.lastRecord
    if not record then
        self:StopRatingRetries()
        return
    end
    self.ratingRetries = (self.ratingRetries or 0) + 1

    local ratings = self:CollectRatings()
    local rows
    if not ratings then
        rows = self:CollectScoreboard()
        ratings = self:RatingsFromScoreboard(rows)
    end
    if ratings then
        record.ratings = ratings
        -- Damage/healing totals also settle with the final score update.
        record.scoreboard = rows or self:CollectScoreboard() or record.scoreboard
        self:StopRatingRetries()
        self:SendMessage("AA_MATCH_UPDATED", record)
        return
    end
    -- Skirmish (never any ratings) or we left the map: stop after ~20s.
    if self.ratingRetries >= 20 then
        self:StopRatingRetries()
    end
end

function Recorder:StopRatingRetries()
    if self.ratingTimer then
        self:CancelTimer(self.ratingTimer)
        self.ratingTimer = nil
    end
    self.lastRecord = nil
end

-- /aa ratings: dump exactly what both rating APIs return right now. Run it
-- on the post-match scoreboard of a RATED game to diagnose missing ratings.
function Recorder:DebugRatings()
    addon:Print("Rating API dump (run this on the end-of-match scoreboard):")
    for teamIndex = 0, 1 do
        if C_PvP and C_PvP.GetTeamInfo then
            local info = C_PvP.GetTeamInfo(teamIndex)
            if info then
                addon:Print(("  C_PvP.GetTeamInfo(%d): name=%s rating=%s ratingNew=%s ratingMMR=%s"):format(
                    teamIndex, tostring(info.name), tostring(info.rating),
                    tostring(info.ratingNew), tostring(info.ratingMMR)))
            else
                addon:Print(("  C_PvP.GetTeamInfo(%d): nil"):format(teamIndex))
            end
        else
            addon:Print("  C_PvP.GetTeamInfo: API not present")
        end
        if GetBattlefieldTeamInfo then
            local name, oldR, newR, rating = GetBattlefieldTeamInfo(teamIndex)
            addon:Print(("  GetBattlefieldTeamInfo(%d): name=%s old=%s new=%s rating=%s"):format(
                teamIndex, tostring(name), tostring(oldR), tostring(newR), tostring(rating)))
        else
            addon:Print("  GetBattlefieldTeamInfo: API not present")
        end
    end
    addon:Print(("  winner=%s, scores=%s"):format(
        tostring(GetBattlefieldWinner and GetBattlefieldWinner()),
        tostring(GetNumBattlefieldScores and GetNumBattlefieldScores())))
    -- Per-player personal ratings (the Anniversary way).
    if C_PvP and C_PvP.GetScoreInfo and GetNumBattlefieldScores then
        for i = 1, GetNumBattlefieldScores() do
            local info = C_PvP.GetScoreInfo(i)
            if type(info) == "table" then
                addon:Print(("  GetScoreInfo(%d): %s team=%s rating=%s change=%s mmr=%s/%s"):format(
                    i, tostring(info.name), tostring(info.faction),
                    tostring(info.rating), tostring(info.ratingChange),
                    tostring(info.prematchMMR), tostring(info.postmatchMMR)))
            else
                addon:Print(("  GetScoreInfo(%d): %s"):format(i, tostring(info)))
            end
        end
    else
        addon:Print("  C_PvP.GetScoreInfo: API not present")
    end
end

function Recorder:OnArenaLeft()
    if current and not finalized then
        -- Left before a winner was determined (or winner missed): try once more.
        local winner = GetBattlefieldWinner and GetBattlefieldWinner()
        self:Finalize(winner)
    end
end

-------------------------------------------------------------------------------
-- Module lifecycle
-------------------------------------------------------------------------------

function Recorder:OnInitialize()
    ArenaArmoryMatches = ArenaArmoryMatches or {}
    ArenaArmoryMatches.schemaVersion = SCHEMA_VERSION
    ArenaArmoryMatches.matches = ArenaArmoryMatches.matches or {}
    ArenaArmoryMatches.character = ArenaArmoryMatches.character or {}
end

function Recorder:OnEnable()
    self:RegisterMessage("AA_ARENA_JOINED", "OnArenaJoined")
    self:RegisterMessage("AA_ARENA_LEFT", "OnArenaLeft")
    self:RegisterMessage("AA_OPPONENT_UPDATE", "OnOpponentUpdate")
    self:RegisterMessage("AA_SPEC_DETECTED", "OnSpecDetected")
    self:RegisterMessage("AA_CLEU", "OnCLEU")
    self:RegisterMessage("AA_TRINKET_USED", "OnTrinketUsed")
    self:RegisterEvent("UPDATE_BATTLEFIELD_STATUS", "PollWinner")
    self.lastTrinket = self.lastTrinket or {}

    -- Record character identity so the companion app can attribute matches.
    ArenaArmoryMatches.character = {
        name = AA.StripRealm(UnitName("player")),
        realm = GetRealmName and GetRealmName() or "",
        faction = UnitFactionGroup and UnitFactionGroup("player") or nil,
    }
end

function Recorder:GetMatchCount()
    return ArenaArmoryMatches and #ArenaArmoryMatches.matches or 0
end
