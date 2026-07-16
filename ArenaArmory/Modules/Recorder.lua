-- Match recorder: structured per-match records persisted to the
-- ArenaArmoryMatches SavedVariable for the desktop companion app to ingest.
local _, AA = ...
local addon = AA.addon

local Recorder = addon:NewModule("Recorder", "AceEvent-3.0", "AceTimer-3.0")
AA.Recorder = Recorder

local DRList = LibStub("DRList-1.0")

-- v2 adds the per-match `events` timeline (cooldowns, trinkets, interrupts, CC).
local SCHEMA_VERSION = 2

-- Bounds SavedVariables growth on very long/chaotic matches.
local MAX_EVENTS = 400

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
                         destGUID, destName, destFlags, spellId, spellName, _, arg15)
    if not current then return end

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
        elseif AA.COOLDOWN_SPELLS[spellId] then
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
            table.insert(rows, {
                name = AA.StripRealm(name),
                team = faction, -- 0 = green, 1 = gold in arena
                race = race,
                class = classToken,
                killingBlows = killingBlows,
                deaths = deaths,
                damage = damageDone,
                healing = healingDone,
            })
        end
    end
    return rows
end

function Recorder:CollectRatings()
    local ratings
    for teamIndex = 0, 1 do
        local teamName, oldRating, newRating, mmr
        -- 2.5.6 ships modern UI code; prefer the modern API when present.
        if C_PvP and C_PvP.GetTeamInfo then
            local info = C_PvP.GetTeamInfo(teamIndex)
            if info then
                teamName, oldRating, newRating, mmr = info.name, info.rating, info.ratingNew, info.ratingMMR
            end
        elseif GetBattlefieldTeamInfo then
            teamName, oldRating, newRating, mmr = GetBattlefieldTeamInfo(teamIndex)
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
    current.ratings = self:CollectRatings()

    -- Compact enemyTeam sparse array into a list.
    local enemies = {}
    for i = 1, AA.MAX_ARENA_OPPONENTS do
        if current.enemyTeam[i] then table.insert(enemies, current.enemyTeam[i]) end
    end
    current.enemyTeam = enemies
    current.startClock = nil

    -- Empty Lua tables are ambiguous (array vs map) for the desktop parser.
    if current.events and #current.events == 0 then current.events = nil end

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
    if ratings then
        record.ratings = ratings
        -- Damage/healing totals also settle with the final score update.
        record.scoreboard = self:CollectScoreboard() or record.scoreboard
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
