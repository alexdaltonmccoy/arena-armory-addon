-- ArenaArmory Core: addon bootstrap, arena state tracking, CLEU fan-out, compat helpers.
local ADDON_NAME, AA = ...

-- Version comes from the TOC, which the release packager stamps from the git
-- tag (@project-version@); an unpackaged dev checkout shows "dev" instead.
local GetAddOnMeta = (C_AddOns and C_AddOns.GetAddOnMetadata) or GetAddOnMetadata
local tocVersion = GetAddOnMeta and GetAddOnMeta("ArenaArmory", "Version")
AA.version = (tocVersion and not tocVersion:find("project%-version")) and tocVersion or "dev"
AA.MAX_ARENA_OPPONENTS = 5

local AceAddon = LibStub("AceAddon-3.0")
local addon = AceAddon:NewAddon("ArenaArmory", "AceEvent-3.0", "AceTimer-3.0", "AceConsole-3.0")
AA.addon = addon
_G.ArenaArmory = AA

AA.inArena = false
AA.testMode = false
AA.guidToUnit = {}   -- enemy GUID -> "arenaN"
AA.unitClass = {}    -- "arenaN" -> classToken (cached, survives unit blips)

-------------------------------------------------------------------------------
-- Compat helpers (2.5.6 shares modern UI code; some legacy APIs may be absent)
-------------------------------------------------------------------------------

-- Returns: name, icon, count, dispelType, duration, expirationTime, source, spellId
function AA.GetAuraByIndex(unit, index, filter)
    if C_UnitAuras and C_UnitAuras.GetAuraDataByIndex then
        local a = C_UnitAuras.GetAuraDataByIndex(unit, index, filter)
        if not a then return nil end
        return a.name, a.icon, a.applications, a.dispelName, a.duration, a.expirationTime, a.sourceUnit, a.spellId
    end
    local name, icon, count, dispelType, duration, expirationTime, source, _, _, spellId = UnitAura(unit, index, filter)
    return name, icon, count, dispelType, duration, expirationTime, source, spellId
end

function AA.GetSpellTexture(spellId)
    if C_Spell and C_Spell.GetSpellTexture then
        return C_Spell.GetSpellTexture(spellId)
    end
    return (select(3, GetSpellInfo(spellId)))
end

function AA.GetSpellName(spellId)
    if C_Spell and C_Spell.GetSpellName then
        return C_Spell.GetSpellName(spellId)
    end
    return (GetSpellInfo(spellId))
end

function AA.UnitCastingInfoCompat(unit)
    if UnitCastingInfo then return UnitCastingInfo(unit) end
    return nil
end

function AA.UnitChannelInfoCompat(unit)
    if UnitChannelInfo then return UnitChannelInfo(unit) end
    return nil
end

function AA.StripRealm(name)
    if not name then return nil end
    return name:match("^([^%-]+)") or name
end

-------------------------------------------------------------------------------
-- Lifecycle
-------------------------------------------------------------------------------

function addon:OnInitialize()
    AA.db = LibStub("AceDB-3.0"):New("ArenaArmoryDB", AA.defaults, true)
    self:Print(("Arena Armory v%s loaded. Type /aa for options, /aa test for test mode."):format(AA.version))
end

function addon:OnEnable()
    self:RegisterEvent("PLAYER_ENTERING_WORLD", "OnEnteringWorld")
    self:RegisterEvent("ARENA_OPPONENT_UPDATE", "OnArenaOpponentUpdate")
    self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED", "OnCLEU")
    -- Periodic GUID map refresh; arena units can appear without a discrete event.
    self.guidTimer = self:ScheduleRepeatingTimer("RefreshGuidMap", 1)
end

-- PLAYER_ENTERING_WORLD fires on every load screen, including arena->arena
-- when requeueing a skirmish from inside a finished match (possibly the same
-- map, so instance IDs can't distinguish games). Every non-reload zone-in to
-- an arena is therefore treated as a brand-new match with a full state reset.
function addon:OnEnteringWorld(_, _, isReloadingUi)
    local _, instanceType = IsInInstance()
    local nowInArena = (instanceType == "arena")

    if nowInArena then
        if isReloadingUi and AA.inArena then return end
        if AA.inArena then
            self:SendMessage("AA_ARENA_LEFT")
        end
        wipe(AA.guidToUnit)
        wipe(AA.unitClass)
        AA.inArena = true
        self:SendMessage("AA_ARENA_JOINED")
    elseif AA.inArena then
        AA.inArena = false
        self:SendMessage("AA_ARENA_LEFT")
        wipe(AA.guidToUnit)
        wipe(AA.unitClass)
    end
end

function addon:OnArenaOpponentUpdate(_, unit, reason)
    if unit and unit:match("^arena%d$") then
        self:RefreshGuidMap()
        self:SendMessage("AA_OPPONENT_UPDATE", unit, reason)
    end
end

function addon:RefreshGuidMap()
    if not AA.inArena then return end
    for i = 1, AA.MAX_ARENA_OPPONENTS do
        local unit = "arena" .. i
        if UnitExists(unit) then
            local guid = UnitGUID(unit)
            if guid and AA.guidToUnit[guid] ~= unit then
                AA.guidToUnit[guid] = unit
                local _, classToken = UnitClass(unit)
                if classToken then AA.unitClass[unit] = classToken end
                self:SendMessage("AA_OPPONENT_UPDATE", unit, "seen")
            end
        end
    end
end

function addon:OnCLEU()
    local timestamp, subevent, _, sourceGUID, sourceName, sourceFlags, _,
        destGUID, destName, destFlags, _,
        arg12, arg13, arg14, arg15 = CombatLogGetCurrentEventInfo()
    self:SendMessage("AA_CLEU", timestamp, subevent, sourceGUID, sourceName, sourceFlags,
        destGUID, destName, destFlags, arg12, arg13, arg14, arg15)
end

-- Returns "arenaN" for a hostile arena GUID, or nil.
function AA.UnitByGUID(guid)
    return guid and AA.guidToUnit[guid] or nil
end

-- Returns 1-5 for "arenaN" unit tokens.
function AA.ArenaIndex(unit)
    return unit and tonumber(unit:match("^arena(%d)$")) or nil
end

function AA.IsHostilePlayerFlag(flags)
    if not flags then return false end
    return bit.band(flags, COMBATLOG_OBJECT_REACTION_HOSTILE) > 0
        and bit.band(flags, COMBATLOG_OBJECT_TYPE_PLAYER) > 0
end
